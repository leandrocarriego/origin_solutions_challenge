# Decisiones de arquitectura

El registro de las decisiones técnicas **transversales** del proyecto: las que valen para más de
una feature. Formato corto: contexto → decisión → consecuencias → alternativas descartadas.
Ordenadas por impacto en la rúbrica.

## Qué se registra acá, y qué no

- **Acá**: lo que da forma al sistema entero — el modelo de datos, la estrategia de caché, la
  autenticación, los modos de falla, cómo se levanta el proyecto.
- **En el `plan.md` de la feature**: lo que sólo afecta a esa feature. Una decisión de alcance
  local en este archivo es ruido para quien lo lea buscando la forma del sistema.

## Una decisión la toma una persona (Artículo X)

**Todo lo que entra a este archivo requiere un acto explícito de un humano.** Sin excepciones, y
sin inferirlo de un "dale" genérico sobre otra cosa.

Un ADR existe por uno de dos caminos, y no hay un tercero:

1. **El humano pide ese ADR**, específicamente. "Documentá la decisión de caché como ADR."
2. **El humano confirma una propuesta**, explícitamente, después de que el agente se la planteó
   **en la conversación**.

Un agente **nunca agrega un ADR por iniciativa propia**, ni siquiera en `Propuesta`. Si cree que
algo merece quedar registrado, lo dice y espera: escribir la entrada primero y pedir permiso
después convierte el pedido en un trámite, y el archivo deja de ser lo que dice ser.

Y **ningún agente escribe `Aceptada` ni completa *Decidida por***. Ese acto es de una persona, y es
lo que convierte un análisis en una decisión.

Mientras un ADR esté en `Propuesta` **no es autoridad**: nada se construye sobre él como si ya
estuviera resuelto, y `/plan` no lo puede citar para justificar un enfoque.

## Estados

| Estado | Qué significa |
|---|---|
| `Propuesta` | El humano pidió el ADR, pero todavía no lo decidió. Sin *Decidida por*, porque no lo decidió nadie. **No es autoridad.** |
| `Aceptada` | Una persona la tomó, y quedó registrado quién y cuándo. |
| `Reemplazada por ADR-NNN` | Sigue acá con su texto original. Una decisión que cambió no se reescribe: se reemplaza, y las dos quedan visibles. |

Un ADR **no se borra ni se edita en el fondo** una vez `Aceptada`. Si la decisión cambia, se
escribe un ADR nuevo y el viejo pasa a `Reemplazada por`. Así el archivo cuenta por qué el sistema
es como es, y no sólo cómo es hoy.

---

## ADR-001 — Modelo de datos

**Estado:** Propuesta · **Decidida por:** — · **Fecha:** —

**Contexto.** El enunciado pide persistir símbolo, nombre y moneda por acción favorita, por
usuario, y evalúa explícitamente el modelo de datos.

**Decisión.** Cuatro tablas:

- `users` — `id`, `username` (unique), `full_name`, `password_hash`, `created_at`
- `stocks` — catálogo de símbolos: `symbol` (PK natural), `name`, `currency`, `exchange`,
  `mic_code`, `country`, `type`
- `user_stocks` — favoritas: `user_id`, `symbol`, `added_at`, PK compuesta `(user_id, symbol)`
- `quotes` — caché de cotizaciones: `symbol`, `interval`, `ts`, `open`, `high`, `low`,
  `close`, `volume`, PK compuesta `(symbol, interval, ts)`

`user_stocks` referencia `stocks`, no duplica nombre ni moneda: el enunciado pide
*guardarlos*, y quedan guardados en el catálogo, normalizados. La PK compuesta hace que
agregar dos veces el mismo símbolo sea imposible por construcción, no por un `if` en el
service.

**Consecuencias.** Agregar una favorita no depende de la API externa: el símbolo ya está en
`stocks`. Índice en `quotes(symbol, interval, ts DESC)` para servir los tramos del gráfico.

**Alternativas descartadas.**

- *Guardar `name` y `currency` en `user_stocks`.* Es la lectura literal de REQ-08: ahorra el
  join y congela el dato del alta. Pero `stocks` existe igual: el autocomplete se sirve del
  catálogo local (`ADR-002`). Denormalizar no ahorra una tabla, agrega una copia por usuario que
  puede divergir.
- *No persistir cotizaciones: caché en memoria o Redis.* Menos esquema, menos latencia, y Redis
  sirve rangos. Pero completar los huecos de la serie es una query, no un `GET`, y se pierde en
  cada reinicio: el evaluador arranca frío y cada símbolo vuelve a costar cuota. Redis
  persistente es un servicio más para lo que Postgres ya hace.
- *PKs sustitutas `id` en todas las tablas.* Es el default del ORM, y sobrevive a un cambio de
  ticker sin tocar FK. Pero la unicidad de `(user_id, symbol)` hay que declararla igual, y el
  símbolo es lo que viaja en la URL: el `id` no identifica nada que la app use.

---

## ADR-002 — El catálogo de símbolos se ingesta, no se proxea

**Estado:** Propuesta · **Decidida por:** — · **Fecha:** —

**Contexto.** El autocomplete dispara por cada tecla. La cuota es de 800 requests por día.

**Decisión.** `/stocks?exchange=NYSE` y `?exchange=NASDAQ` se ingestan una sola vez a la
tabla `stocks` (comando de seed, re-ejecutable). El endpoint `GET /api/stocks/search?q=`
consulta Postgres con `ILIKE` sobre símbolo y nombre, y devuelve como máximo 20 filas.

**Consecuencias.** El autocomplete cuesta **cero** requests de cuota y responde en
milisegundos. El catálogo puede quedar desactualizado, lo que es irrelevante para el
challenge y se resuelve re-corriendo la ingesta. Ver A3 y A4 en `SPEC.md`.

**Alternativas descartadas.**

*Proxy directo a `/symbol_search`, con debounce.* Es lo que sugiere el enunciado y tiene algo
real a favor: catálogo siempre al día, cero código de ingesta, matching resuelto por el
proveedor. Pero el debounce baja el consumo sin acotarlo —crece con los usuarios— y el plan
gratis corta en **8 requests por minuto por clave**, no por usuario: uno tipeando rápido le
devuelve un 429 al gráfico del de al lado. Artículo II.

*Cachear las búsquedas bajo demanda*, como `ADR-003` con las cotizaciones. A favor, la
coherencia: una sola estrategia de caché, y se paga sólo lo que alguien busca. Pero cada prefijo
nuevo es un miss, y ese miss lo paga el usuario mientras tipea. Peor: un catálogo a medio llenar
miente, y un símbolo que nadie buscó todavía se lee igual que uno que no existe. El hueco de una
serie se detecta; el de un catálogo, no.

---

## ADR-003 — Caché de cotizaciones y polling compartido por símbolo

**Estado:** Propuesta · **Decidida por:** — · **Fecha:** —

**Contexto.** Este es el problema de ingeniería central del challenge. Un solo usuario con
un gráfico en modo tiempo real a intervalo de 1min consume ~480 requests en 8 horas de
mercado. Dos usuarios y la cuota diaria de 800 se agota. La implementación ingenua
—el navegador pide, el backend reenvía a TwelveData— no sobrevive a la demo.

**Decisión.** El frontend nunca dispara una llamada al upstream. Un `QuoteService` en el
backend resuelve cada pedido contra la tabla `quotes` y solo consulta TwelveData cuando el
tramo pedido tiene un hueco y el dato está vencido para su intervalo (TTL = duración del
intervalo). El resultado se persiste antes de responder. El refresco de tiempo real es
polling del frontend **contra la API propia**, que en el caso normal se sirve de la base.

**Consecuencias.** El consumo de la API externa escala con **símbolos distintos observados**,
no con clientes conectados (NFR-05): diez usuarios mirando TSLA cuestan lo mismo que uno.
La caché además da resiliencia — si el upstream falla, se sirve lo último conocido con un
aviso. Costo: la lógica de detección de huecos es la parte no trivial del backend y necesita
tests propios.

**Alternativas descartadas.**

*Caché en memoria del proceso, o Redis con TTL.* Es más simple: un diccionario con vencimiento
resuelve el fan-out de N clientes sobre un mismo símbolo, sin migraciones ni índices. Pero el
histórico (REQ-15) no es un valor con TTL: es una serie que hay que guardar igual, en la base
relacional de REQ-18 y en su backup (REQ-21). Un TTL aparte sería un segundo almacén, y un
servicio más en el compose, sobre lo que ya vive en `quotes`.

*Un worker que precarga en background las favoritas de todos los usuarios.* A favor tiene
latencia constante y consumo predecible: el gráfico siempre sale de la base. Pero gasta cuota
por símbolos que nadie está mirando — dos símbolos distintos a 1min ya son ~960 llamadas en una
rueda, contra los 800 del día. El pull perezoso paga sólo por lo que alguien abrió.

El WebSocket propio se descarta en A2: el plan gratuito no tiene streaming detrás.

---

## ADR-004 — Autenticación con JWT y Argon2

**Estado:** Propuesta · **Decidida por:** — · **Fecha:** —

**Contexto.** El enunciado evalúa seguridad y no especifica mecanismo.

**Decisión.** `POST /api/auth/login` valida contra Argon2 y devuelve un JWT firmado con
HS256 (exp. 60 min) que incluye `sub` (user id) y `name`. El frontend lo guarda en memoria
con refresco desde `sessionStorage`, y lo manda en `Authorization: Bearer`. Una dependencia
`get_current_user` de FastAPI resuelve el usuario en cada endpoint protegido.

**Consecuencias.** El nombre de usuario para la cabecera (REQ-04) sale del token, sin request
extra. **Toda** query de favoritas filtra por `current_user.id` y jamás por un id recibido
del cliente (NFR-03). El login devuelve el mismo error genérico para usuario inexistente y
password incorrecta: `usuario o clave invalida` (REQ-02), que además evita enumeración de
usuarios. `sessionStorage` es una concesión consciente de take-home; en producción iría
cookie `HttpOnly` + `SameSite` con refresh token rotativo.

**Alternativas descartadas.**

*Sesión en el servidor con cookie `HttpOnly`.* A favor real: un XSS no puede leer el token, y
revocar es borrar una fila — con un JWT de 60 minutos no hay revocación, y se acepta. Se
descartó por lo que arrastra: la cookie la manda el navegador sola, así que hay que defender
CSRF, más CORS con credenciales entre `web` y `api`, más una tabla de sesiones. `Authorization:
Bearer` no viaja solo.

*El JWT en `localStorage`.* Gana persistencia: sobrevive cerrar el navegador. Se descartó porque
el único caso real es el F5, y `sessionStorage` lo cubre atando la sesión a la pestaña. Ninguna
de las dos frena un XSS —el mismo script las lee igual—: el límite real es el `exp`.

*bcrypt en vez de Argon2.* A favor: nadie lo objeta en una review y no tiene parámetros de
memoria que elegir bien. Argon2id igual es la primera opción de OWASP, y bcrypt ignora todo byte
pasado el 72.

---

## ADR-005 — Modos de fallo explícitos

**Estado:** Propuesta · **Decidida por:** — · **Fecha:** —

**Contexto.** La rúbrica dice "estabilidad". Los tres escenarios que rompen una demo son
mercado cerrado, símbolo sin datos y cuota agotada — y los tres son *probables* durante la
evaluación, no casos borde.

**Decisión.** La API responde con un cuerpo tipado que incluye `status` además de la serie:

- `ok` — datos frescos
- `stale` — se sirve caché porque el upstream falló o la cuota se agotó (HTTP 200 + aviso)
- `market_closed` — no hay datos para hoy; se devuelve la última sesión disponible y se
  informa cuál (A5)
- `no_data` — el símbolo no tiene serie para ese intervalo/rango

El frontend renderiza un banner por cada estado distinto de `ok` y **siempre grafica lo que
haya**. Nunca una pantalla en blanco sin explicación.

**Consecuencias.** El 429 del upstream nunca llega crudo al navegador. Cada estado necesita
su test.

**Alternativas descartadas.** Usar el código HTTP como canal: 503 para el upstream caído, 404
para símbolo sin serie, 429 para la cuota. Es REST canónico y cualquier monitoreo lo lee sin
conocer el dominio. Se descartó porque mienten: 429 culpa al cliente, que no tiene cuenta en
TwelveData; 404 dice que el símbolo no existe, cuando está en nuestro catálogo y sólo falta la
serie. Para `stale` hay un 203 que nadie mira; para `market_closed`, nada. Y el 401 ya está
interceptado: el caso más probable de la demo caería por ese mismo camino.

Que el frontend infiera el estado mirando la serie sale gratis: cero backend, ningún contrato,
ningún test por estado. Pero una serie vacía es `no_data` o cuota agotada con caché fría, y un
último punto viejo es mercado cerrado o upstream muerto. Separarlos pide un calendario de
mercado en el cliente y saber por qué falló un proveedor que el frontend ni conoce (Artículo I).

---

## ADR-006 — El proveedor de datos detrás de una interfaz

**Estado:** Propuesta · **Decidida por:** — · **Fecha:** —

**Contexto.** La rúbrica evalúa extensibilidad, y TwelveData es un detalle de
implementación que el enunciado eligió por ser gratis.

**Decisión.** Un protocolo `MarketDataProvider` con `search_stocks()` y `get_time_series()`.
`TwelveDataProvider` lo implementa; se inyecta por dependencia de FastAPI.

**Consecuencias.** Los tests usan un `FakeProvider` determinístico y no tocan la red (NFR-06).
Cambiar de proveedor es una clase nueva y una línea de wiring. Es también la respuesta
concreta a "extensibilidad" cuando el evaluador pregunte por ella.

**Alternativas descartadas.** Llamar a TwelveData directo desde el `QuoteService` y aislar la
red en los tests con `respx`. Tiene algo real a favor: menos indirección, y la suite igual corre
sin red ni API key (NFR-06). Se descartó porque ata cada test de service al JSON del proveedor a
nivel HTTP —un cambio de formato rompe tests que no hablan de formato— y porque el Artículo IV
no la deja abierta: nombra a `MarketDataProvider` como lo que conocen los services.

La otra es más fina: un `TwelveDataClient` sin protocolo, sustituido en tests con
`dependency_overrides`. Con una sola implementación, una interfaz es abstracción especulativa.
Pero implementaciones hay dos desde el día uno —el `FakeProvider` corre toda la suite— y el
protocolo es el único lugar donde está escrito el contrato que las dos cumplen. Sin él, un
método nuevo en el cliente deja atrás al fake y la suite sigue verde contra una forma que el
proveedor ya no devuelve.

---

## ADR-007 — docker-compose como forma de levantar el proyecto

**Estado:** Propuesta · **Decidida por:** — · **Fecha:** —

**Contexto.** REQ-22 pide un README con los pasos para levantar. El evaluador tiene poco
tiempo y muchas entregas.

**Decisión.** `docker compose up --build` levanta Postgres, API y frontend, corre las
migraciones y el seed automáticamente. El `.env.example` documenta cada variable; la única
obligatoria es `TWELVEDATA_API_KEY`.

**Consecuencias.** El camino de "clonar a funcionando" es un comando. `db/backup.sql`
(REQ-21) se genera con `make backup` a partir de la base ya sembrada, así que el backup y
el seed nunca divergen.

**Alternativas descartadas.** Dos, ambas razonables.

*Postgres en compose, API y frontend a mano* — el setup de desarrollo. Gana el reload: uvicorn y
Vite recargan al instante, sin bind mounts ni rebuild de imagen. Se descarta porque no ahorra
Docker —hace falta igual para la base— y le suma Node y `uv` encima, dos terminales y acordarse
de migraciones y seed en ese orden. El Artículo IX pide builds reproducibles porque esto corre
en su máquina, no en la nuestra: media dockerización deja la otra mitad de su lado. Sin Docker,
además, la versión de Postgres y el 5432 libre.

*Inicializar la base desde `db/backup.sql`* montado en `docker-entrypoint-initdb.d`, sin correr
Alembic. Es más rápido y prueba el backup entregado (REQ-21) en cada arranque limpio. Se
descarta porque deja el esquema con dos fuentes de verdad: la primera migración que alguien no
vuelque al dump rompe la correspondencia. El dump es un artefacto derivado del esquema, nunca su
origen.

---

## ADR-008 — Los wireframes del enunciado son la especificación de la UI

**Estado:** Propuesta · **Decidida por:** — · **Fecha:** —

**Contexto.** El enunciado dice, textualmente, que **no se evalúa el diseño ni el conocimiento de
UI**. Y sin embargo incluye tres wireframes detallados: login, "Mis Acciones" y el detalle con su
gráfico, con etiquetas, columnas y textos concretos.

Las dos cosas juntas dicen lo mismo desde dos lados: la interfaz no es un espacio donde ganar
puntos, es un requisito a cumplir.

**Decisión.** No hay design system, ni librería de componentes, ni framework de estilos: CSS plano
y una paleta neutra tomada del propio mockup. Los tres wireframes se recortaron del PDF a
`docs/design/wireframes/` y son la fuente de layout; los textos visibles están fijados **verbatim**
en `docs/design/COPY.md`, faltas de ortografía incluidas.

Ante la duda entre reproducir el wireframe y mejorarlo, se reproduce.

**Consecuencias.** Una pantalla que se aparta del mockup es un hallazgo de review, no una mejora
(`CONVENTIONS.md` → `UI-01`, `UI-02`). Se ahorra el tiempo que un design system se llevaría, y se
gasta donde la rúbrica sí paga: modelo de datos, estabilidad y NFR.

Lo único que la UI agrega por encima del wireframe son los **avisos de estado** de `ADR-005`, que
van arriba del gráfico (`UI-05`): el mockup no los previó porque no contempla que el proveedor
falle, y una pantalla en blanco sin explicación es un modo de falla, no una decisión de diseño.

**Alternativas descartadas.** Una UI "linda" con Tailwind y componentes. Es trabajo que el enunciado
declara que no va a mirar, y cada pixel que se aleja del mockup es una diferencia que el evaluador
tiene que interpretar.
