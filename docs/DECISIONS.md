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

**Estado:** Aceptada · **Decidida por:** Leandro Carriego · **Fecha:** 2026-09-13

**Enmendada:** 2026-09-13 · Leandro Carriego — se agregan `stocks.delisted_at` y
`stocks.last_seen_at`, que `ADR-002` necesita para reconciliar el catálogo.

> Enmendar un ADR ya `Aceptada` **es una excepción a la regla de este archivo**, que dice que una
> decisión firmada no se edita en el fondo y que un cambio se escribe como ADR nuevo. Se hizo por
> decisión explícita del humano y por esta vez: escribir un ADR entero que reemplace a éste para
> agregar dos columnas habría dejado la definición de las cuatro tablas partida en dos lugares,
> que es peor para quien lo lea después. La regla sigue vigente para lo que venga.

**Contexto.** El enunciado pide persistir símbolo, nombre y moneda por acción favorita, por
usuario, y evalúa explícitamente el modelo de datos.

**Decisión.** Cuatro tablas:

- `users` — `id`, `username` (unique), `full_name`, `password_hash`, `created_at`
- `stocks` — catálogo de símbolos: `symbol` (PK natural), `name`, `currency`, `exchange`,
  `mic_code`, `country`, `type`, `last_seen_at`, `delisted_at` (nullable)
- `user_stocks` — favoritas: `user_id`, `symbol`, `added_at`, PK compuesta `(user_id, symbol)`
- `quotes` — caché de cotizaciones: `symbol`, `interval`, `ts`, `open`, `high`, `low`,
  `close`, `volume`, PK compuesta `(symbol, interval, ts)`

`user_stocks` referencia `stocks`, no duplica nombre ni moneda: el enunciado pide
*guardarlos*, y quedan guardados en el catálogo, normalizados. La PK compuesta hace que
agregar dos veces el mismo símbolo sea imposible por construcción, no por un `if` en el
service.

`quotes.symbol` **también** referencia `stocks`. En esta aplicación todo símbolo llega desde el
catálogo —se agrega una favorita eligiendo del autocomplete, y al gráfico se entra desde una
favorita—, así que la FK no debería dispararse nunca. Por eso vale: si se dispara, avisó de un
bug en vez de dejar acumular cotizaciones huérfanas de un símbolo inexistente.

`quotes.interval` es `String` con un `CHECK` acotado a los tres valores de `REQ-16` (`1min`,
`5min`, `15min`), espejado por un `StrEnum` en Python. No un `enum` nativo de Postgres: agregarle
un valor es una migración incómoda y quitarlo es peor, mientras que un `CHECK` se altera con una
línea.

**La PK natural obliga a una condición sobre la ingesta**, y es parte de esta decisión. La
ingesta de `ADR-002` descarta dos cosas:

1. `type = "Warrant"`. Un warrant es un derivado, no una acción, y es el único tipo que produce
   un símbolo duplicado en el catálogo.
2. Todo símbolo que no matchee `^[A-Z0-9][A-Z0-9.\-]{0,8}$`. El símbolo viaja en la URL
   (`REQ-11`), y punto y guión son legales en un segmento pero la barra no.

`last_seen_at` y `delisted_at` existen porque el catálogo se reconcilia contra una foto del
proveedor que no trae ningún campo de estado (`ADR-002`): la única señal de que un símbolo dejó de
cotizar es que ya no viene en la respuesta. `delisted_at` la registra sin borrar la fila —
`user_stocks` y `quotes` la referencian—, y el autocomplete filtra `delisted_at IS NULL`.

**Consecuencias.** Agregar una favorita no depende de la API externa: el símbolo ya está en
`stocks`. Índice en `quotes(symbol, interval, ts DESC)` para servir los tramos del gráfico.

La condición sobre la ingesta está medida, no supuesta. Sobre el catálogo real de TwelveData al
2026-09-13:

| | Filas | Símbolos duplicados | Símbolos no ruteables |
|---|---|---|---|
| NYSE + NASDAQ sin filtrar | 7.572 | 1 (`ARQQW`, warrant) | 1 (`!otc/FLZH`) |
| Sin warrants | 7.156 | 0 | 1 |
| **Sin warrants y con símbolo ruteable** | **7.155** | **0** | **0** |

Entre NYSE y NASDAQ hay **cero** símbolos en común: la colisión entre mercados que haría falsa a
esta clave no existe en los datos. Se descarta el 5,5% del catálogo y sobreviven los tres
símbolos del wireframe. Todo el catálogo es `USD`, pero `currency` se persiste igual porque
`REQ-08` lo pide y porque una constante de hoy no es una constante.

Es una foto. Si TwelveData listara mañana un símbolo repetido que no sea warrant, la ingesta no
puede romperse: por eso es un **upsert idempotente** —`ADR-002` ya la define re-ejecutable—, que
sobreescribe de forma determinista. El día que colisionen dos acciones comunes de verdad, esta
decisión se revisa con datos, no antes.

**Alternativas descartadas.**

- *Guardar `name` y `currency` en `user_stocks`.* Es la lectura literal de REQ-08: ahorra el
  join y congela el dato del alta. Pero `stocks` existe igual: el autocomplete se sirve del
  catálogo local (`ADR-002`). Denormalizar no ahorra una tabla, agrega una copia por usuario que
  puede divergir.
- *No persistir cotizaciones: caché en memoria o Redis.* Menos esquema, menos latencia, y Redis
  sirve rangos. Pero completar los huecos de la serie es una query, no un `GET`, y se pierde en
  cada reinicio: el evaluador arranca frío y cada símbolo vuelve a costar cuota. Redis
  persistente es un servicio más para lo que Postgres ya hace.
- *PK compuesta `(symbol, mic_code)` en `stocks`.* Es el modelo formalmente correcto: el mismo
  ticker puede existir en dos mercados. Se descarta porque en este catálogo no existe —cero
  colisiones sobre 7.155 filas medidas— y el par se propagaría a la URL, a cada favorita y a
  cada fila de `quotes` para resolver un caso que la aplicación nunca ve. El enunciado tampoco
  pide distinguirlos: `REQ-08` persiste símbolo, nombre y moneda, y el exchange no aparece.
- *Ingestar sólo `type = "Common Stock"`.* También deja el catálogo sin duplicados, y con 5.747
  filas en vez de 7.155. Se descarta porque tira 393 ADR (`ABEV`, `AMX`) y 214 REIT que no
  colisionan ni rompen el ruteo: son empresas que alguien puede buscar. Se prefiere el filtro
  más angosto que arregla el problema real (`GEN-10`, KISS).
- *PKs sustitutas `id` en todas las tablas.* Es el default del ORM, y sobrevive a un cambio de
  ticker sin tocar FK. Pero la unicidad de `(user_id, symbol)` hay que declararla igual, y el
  símbolo es lo que viaja en la URL: el `id` no identifica nada que la app use.

---

## ADR-002 — El catálogo de símbolos se ingesta, y la ingesta reconcilia

**Estado:** Aceptada · **Decidida por:** Leandro Carriego · **Fecha:** 2026-09-13

**Contexto.** El autocomplete dispara por cada tecla y la cuota es de 800 requests por día, así
que proxear el catálogo está descartado por el Artículo II. Eso no estaba en discusión.

Lo que sí: una ingesta que corre una vez y se re-ejecuta a mano deja un catálogo que **envejece en
silencio**, y el catálogo es de dónde sale todo símbolo que la aplicación conoce. Un símbolo que
falta se lee igual que uno que no existe.

Dos cosas medidas sobre la API real el 2026-09-13, porque las dos cambian el diseño:

| | |
|---|---|
| `GET /stocks?exchange=NYSE` | **1 crédito**, 843 KB, 3.070 filas |
| `GET /api_usage` | **0 créditos** |
| Campo que indique si el símbolo sigue listado | **ninguno** |

**Decisión.**

**1. El catálogo vive en `stocks` y el autocomplete consulta Postgres.** `GET
/api/stocks/search?q=` hace `ILIKE` sobre símbolo y nombre y devuelve como máximo 20 filas. Cuesta
cero cuota y responde en milisegundos.

**2. La ingesta reconcilia contra la foto, no acumula.** Es la corrección central de este ADR.
`/stocks` devuelve **lo que está listado hoy** y no trae ningún campo de estado: la única señal de
que un símbolo dejó de cotizar es que **ya no viene en la respuesta**. Un `upsert` no puede ver esa
señal —por construcción, no por descuido—, así que un catálogo mantenido a upserts sólo crece y
diverge de la realidad para siempre.

Por cada exchange, tres conjuntos:

| En la foto | En `stocks` | Acción |
|---|---|---|
| sí | no | insertar |
| sí | sí | actualizar `name`, `currency`, `type`, y limpiar `delisted_at` si estaba |
| no | sí | marcar `delisted_at = now()` |

**Nunca `DELETE`.** `user_stocks` y `quotes` referencian `stocks` (`ADR-001`): borrar una fila es
borrarle una favorita a alguien o tirar su histórico. Una acción que deja de cotizar sigue
existiendo, y el usuario que la tenía guardada tiene que seguir viendo su nombre.

El autocomplete filtra `delisted_at IS NULL`. Una favorita ya agregada resuelve igual.

**3. Se refresca solo, y el número dice que es gratis.** Dos créditos por refresco completo (NYSE +
NASDAQ) sobre 800 diarios: **0,25% de la cuota**. Al arrancar el proceso, si la última ingesta
exitosa tiene más de 24 horas; y después cada 24 horas. La condición de antigüedad es lo que evita
que un contenedor en ciclo de reinicio queme cuota: `restart: unless-stopped` puede intentarlo
muchas veces por minuto.

**4. Una foto a medias no reconcilia nada.** La reconciliación es **por exchange y sólo si la
descarga de ese exchange se completó**. Si falla la llamada de NASDAQ, marcar como deslistado todo
lo que "no vino" deslistaría NASDAQ entero. Es el modo de falla más caro de esta decisión y por eso
la atomicidad es parte de ella, no un detalle de implementación.

**5. La frescura se mide, no se supone.** Un gauge `catalog_last_success_timestamp_seconds` y su
panel en Grafana (`ADR-009`). "El catálogo está al día" pasa a ser algo que se mira, y no algo que
se asume porque la ingesta corrió alguna vez. `/api_usage` es gratis, así que alimentar también
`provider_quota_remaining` no cuesta cuota.

**Consecuencias.**

`stocks` necesita dos columnas que `ADR-001` no preveía: `last_seen_at` y `delisted_at`. Están
declaradas allá, donde vive la definición de las cuatro tablas: `ADR-001` se enmendó por decisión
explícita del humano el 2026-09-13, como excepción a la regla de que un ADR firmado no se edita.

El filtro de ingesta de `ADR-001` —sin warrants, símbolo ruteable— se aplica **antes** de
reconciliar: un símbolo descartado por el filtro no "desapareció", nunca entró.

La ingesta pasa a ser un proceso con estado observable, no un script de seed. Vive en el backend
detrás de `MarketDataProvider` (`ADR-006`), no en `scripts/`: gasta cuota, y todo lo que gasta
cuota pasa por el proveedor.

Un símbolo nuevo aparece en el autocomplete con **hasta 24 horas de retraso**. Es el costo que
queda, está acotado y es ajustable bajando el intervalo: cada refresco extra son 2 créditos.

**Alternativas descartadas.**

*Proxy directo a `/symbol_search`, con debounce.* Es lo que sugiere el enunciado y tiene algo real a
favor: catálogo siempre al día, cero código de ingesta, matching resuelto por el proveedor. Pero el
debounce baja el consumo sin acotarlo —crece con los usuarios— y el plan gratis corta en **8
requests por minuto por clave**, no por usuario: uno tipeando rápido le devuelve un 429 al gráfico
del de al lado. Artículo II.

*Cachear las búsquedas bajo demanda*, como `ADR-003` con las cotizaciones. A favor, la coherencia:
una sola estrategia de caché, y se paga sólo lo que alguien busca. Pero cada prefijo nuevo es un
miss, y ese miss lo paga el usuario mientras tipea. Peor: un catálogo a medio llenar miente, y un
símbolo que nadie buscó todavía se lee igual que uno que no existe. El hueco de una serie se
detecta; el de un catálogo, no.

*Ingesta por `upsert`, re-ejecutable a mano.* Era la decisión anterior de este ADR, y decía que un
catálogo desactualizado "es irrelevante para el challenge". Se descarta por dos motivos. El
primero es que no converge: sin campo de estado en la respuesta, el upsert no puede representar una
baja, así que el catálogo acumula símbolos muertos de manera monótona. El segundo es que "se
resuelve re-corriendo la ingesta" pone la corrección en manos de que alguien se acuerde, y lo que
depende de que alguien se acuerde no es una propiedad del sistema.

*Consultar `/symbol_search` cuando la búsqueda local no devuelve nada.* Taparía la ventana de 24
horas para un símbolo recién listado, con un costo acotado: sólo ante cero resultados. Se descarta
por el Artículo VII —el enunciado no lo pide— y porque reintroduce una llamada al proveedor
disparada por lo que el usuario tipea, que es exactamente lo que este ADR saca del medio. El
refresco programado cierra el mismo agujero sin esa puerta.

*`DELETE` de los símbolos que ya no vienen.* Deja la tabla limpia y es lo que "reconciliar" sugiere
a primera vista. Se descarta porque `user_stocks` y `quotes` tienen FK a `stocks`: el borrado o
falla, o cascadea y le saca al usuario una favorita que él guardó. Que una acción deje de cotizar
no es motivo para borrar su historia.

---

## ADR-003 — Caché de cotizaciones y polling compartido por símbolo

**Estado:** Aceptada · **Decidida por:** Leandro Carriego · **Fecha:** 2026-09-13

**Contexto.** Este es el problema de ingeniería central del challenge. Un solo usuario con
un gráfico en modo tiempo real a intervalo de 1min consume ~480 requests en 8 horas de
mercado. Dos usuarios y la cuota diaria de 800 se agota. La implementación ingenua
—el navegador pide, el backend reenvía a TwelveData— no sobrevive a la demo.

El intervalo lo elige el usuario entre los tres valores de `REQ-16`, y eso no se negocia por
cuota: el wireframe pone un `select` que arranca vacío y un botón `Graficar`. No hay intervalo
por defecto, y nada consume cuota hasta que el usuario elige.

**Decisión.** El frontend nunca dispara una llamada al upstream. Un `QuoteService` en el
backend resuelve cada pedido contra la tabla `quotes` y solo consulta TwelveData cuando el
tramo pedido tiene un hueco y el dato está vencido para su intervalo (TTL = duración del
intervalo). El resultado se persiste antes de responder. El refresco de tiempo real es
polling del frontend **contra la API propia**, que en el caso normal se sirve de la base.

**El polling corre sólo mientras el gráfico se está mirando.** Se corta cuando la pestaña deja de
estar visible (`document.visibilityState`) y se reanuda al volver. Sin eso, una pestaña olvidada
sigue renovando el TTL de su símbolo toda la rueda, y el Artículo II pasa a leerse "símbolos que
alguien abrió alguna vez" en vez de "símbolos que alguien está mirando".

**Consecuencias.** El consumo de la API externa escala con **símbolos distintos observados**,
no con clientes conectados (NFR-05): diez usuarios mirando TSLA cuestan lo mismo que uno.

El techo por rueda de 8 horas, con 798 créditos disponibles después del catálogo (`ADR-002`):

| Intervalo | Créditos por símbolo | Símbolos en tiempo real a la vez |
|---|---|---|
| `1min` | 480 | 1 |
| `5min` | 96 | 8 |
| `15min` | 32 | 24 |

Está escrito acá porque es el límite real del proyecto y conviene saberlo antes de la demo, no
durante: tres gráficos a 1min agotan el día.
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

*Forzar `5min` por defecto, o esconder `1min`.* Multiplicaría por cinco los símbolos que entran
en la cuota. Se descarta porque `REQ-16` da los tres valores al usuario y el enunciado se entrega
como lo pide (Artículo VII): la cuota se administra con la caché y con la visibilidad, no
recortándole opciones a la pantalla que el cliente especificó.

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

**Estado:** Aceptada · **Decidida por:** Leandro Carriego · **Fecha:** 2026-09-13

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

---

## ADR-009 — Observabilidad: logs, métricas, dashboard y errores

**Estado:** Aceptada · **Decidida por:** Leandro Carriego · **Fecha:** 2026-09-13

**Contexto.** El Artículo II es la afirmación central de ingeniería de este proyecto: el consumo
del proveedor escala con símbolos observados, no con clientes conectados. Hoy esa afirmación no se
puede verificar desde afuera — se lee en el README y se cree o no. `ERR-07` ya exige que toda
llamada al proveedor quede registrada con su símbolo, intervalo, rango, resultado y si fue cache
hit, precisamente porque *"con una cuota de 800 requests por día, no poder responder en qué se
gastó es no poder operar el sistema"*. Falta el mecanismo que convierta esa exigencia en algo
consultable.

**Decisión.** Cuatro capas, de la más barata a la más cara:

1. **Logs estructurados** en JSON con `structlog`, y un middleware que le asigna un `request_id`
   a cada pedido y lo propaga a todas sus líneas. Sin correlación, dos usuarios concurrentes
   producen logs entreverados que no se pueden leer.
2. **Métricas Prometheus** en `/metrics`: las estándar por ruta (rate, errores, duración) más tres
   propias que son las que importan acá — `provider_requests_total{symbol,interval,outcome}`,
   `quote_cache_hits_total` / `quote_cache_misses_total`, y `provider_quota_remaining`.
3. **Prometheus + Grafana** en el VPS, detrás de Traefik, con un dashboard: cuota consumida hoy,
   tasa de aciertos de caché, latencia p95 y tasa de error.
4. **Sentry** para excepciones, con `include_local_variables=False`, `send_default_pii=False` y un
   `before_send` que enmascara secretos.

**Consecuencias.** El Artículo II deja de ser una afirmación y pasa a ser un número graficado: se
puede mostrar que diez usuarios sobre un mismo símbolo cuestan una sola llamada. `NFR-05` gana su
evidencia.

Se paga con tres cosas. **RAM**: unos 350 MB en un VPS compartido con otros proyectos en
producción. **Una dependencia externa**: Sentry recibe trazas de nuestras excepciones, y eso
convierte al Artículo I en un requisito de configuración y no sólo de código — el SDK captura las
variables locales de cada frame por defecto, así que sin desactivarlo el DSN de Postgres y la URL
del proveedor con su `apikey` salen del servidor. Por eso `SEC-06` incluye el evento de Sentry
entre las salidas que audita. **Superficie**: `/metrics` no lleva autenticación y expone nombres de
símbolos; queda accesible sólo desde la red interna de Docker, nunca publicado por Traefik.

**La excepción al Artículo VII, dicha de frente.** Las capas 1 y 2 no son alcance nuevo: `ERR-03`
exige logging estructurado y `ERR-07` exige la auditoría de llamadas, así que implementarlas es
cumplir convenciones que ya existen. **Las capas 3 y 4 sí son alcance que el enunciado no pide.**
Se construyen igual, y la razón se escribe acá para que no se lea como descuido: la rúbrica evalúa
mantenibilidad y escalabilidad, y un `NFR` sobre consumo de cuota que nadie puede verificar es un
`NFR` sin cumplir. Es una excepción deliberada, no un olvido.

**Alternativas descartadas.**

*Sólo logs, sin métricas.* Es lo más barato y cubre `ERR-07` al pie de la letra. Se descarta porque
responder "cuánta cuota queda hoy" obligaría a parsear logs con `grep` y contar a mano: un contador
que ya está sumado cuesta 8 bytes y contesta en un scrape.

*OpenTelemetry con Tempo o Jaeger para trazas distribuidas.* Es el estándar de la industria y sería
la respuesta correcta en un sistema de varios servicios. Acá hay **uno**: la traza mostraría
`router → service → repository → postgres`, que es exactamente lo que ya dice una línea de log con
su duración. Se paga complejidad por una respuesta que ya se tiene. Si `quotes` se extrajera algún
día —que es lo que el Artículo IV deja abierto—, esta decisión se revisa.

*Loki para agregación de logs.* Paga a partir de varios servicios o varias réplicas. Con uno,
`docker compose logs` alcanza.

*Datadog o New Relic.* Costo desproporcionado para un proyecto de este tamaño, y meten un agente
propietario en el camino de una aplicación que se entrega para ser leída.
