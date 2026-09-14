# Mis Acciones favoritas — Plan técnico

<!--
  ARTEFACTO INTERNO. Acá van las decisiones técnicas que spec.md no puede llevar.
  No se exporta al cliente.
-->

**Feature:** `002-favorite-stocks` · **Spec aprobada el:** 2026-09-13 · **Fecha:** 2026-09-13

**Roles:** `Backend-Architect` + `Frontend-Architect` (feature full-stack, un solo plan).

> **Esta feature se apoya en `001-authentication`, que ya está entregada.** La precondición que
> este plan declaraba como pendiente **está cumplida, verificada el 2026-09-13**: las quince tareas
> de `001` están hechas, y las tres que bloqueaban a `002` son las **10, 11 y 14** —
> `GET /api/auth/me` responde en `auth/router.py`; la sesión sobrevive a la recarga con
> `auth/storage.ts` (`sessionStorage`), `auth/session.ts` y `auth/SessionProvider.tsx`, que la
> restaura contra `/api/auth/me`; y `components/Header.tsx` muestra `Usuario: {nombre completo}` y
> `Cerrar sesión`—.
>
> Lo que ese bloqueo compró **sigue vigente y es una regla para el `Tester`**: los cinco criterios
> de `002` que dicen "se cierra sesión y se vuelve a entrar" (`RF-05`, `RF-17`, `RF-22`, `RF-24`,
> `RF-32`) se verifican **en las dos puntas** —en backend, dos sesiones distintas del mismo usuario
> contra Postgres; en frontend, un **F5 real** con la sesión restaurada desde `sessionStorage`—, y
> **nunca** remontando la aplicación, que probaría el remontaje y no la persistencia. El detalle, en
> *Riesgos* y en *Contexto de traspaso*.
>
> **Nada de `001` se rehace acá**: esta feature consume lo que `001` entregó sin modificarlo, salvo
> los dos puntos de extensión que *Contratos → Frontend* nombra y justifica.

## Constitution Check

| Artículo | Cumple | Cómo |
|---|---|---|
| I — La credencial del proveedor vive sólo en el backend | ✅ | La feature no toca el proveedor ni agrega ninguna variable `VITE_*`. El autocomplete consulta **nuestra** base, no TwelveData: el frontend sigue hablando sólo con `/api`, y el nombre del proveedor no aparece en ningún archivo nuevo (`GEN-08`). |
| II — La cuota es finita, y eso es parte del diseño | ✅ | **Ninguna de las cinco rutas sale al proveedor.** El autocomplete se sirve de la tabla `stocks`, que la ingesta de `ADR-002` mantiene al día por su cuenta (A3): tipear rápido no cuesta un request, y el consumo sigue sin escalar con clientes conectados. La grilla y el alta tampoco consultan cotizaciones: la grilla muestra símbolo, nombre y moneda, y el precio es de `003`. |
| III — Los datos de un usuario son de ese usuario | ✅ | **Es el artículo que esta feature pone a prueba.** Las tres rutas de `favorites` reciben el id del usuario de `get_current_user` —del `sub` del token— y de ningún otro lado: ninguna acepta `user_id` por path, query ni body. La firma del repositorio exige el `user_id` del autenticado y no tiene forma de recibir otro. Acá nace `tests/integration/test_user_isolation.py`, que es la mitad que `GEN-09` todavía no tenía corriendo. |
| IV — Las fronteras entre módulos son reales | ✅ | `favorites` entra a `stocks` **por el paquete** (`from app.modules.stocks import get_stocks, StockInfo`), que es exactamente la lectura cruzada que `ARCHITECTURE.md` ya había previsto, y en batch: una consulta para toda la grilla, nunca un `get_stock()` por fila. Adentro de cada módulo el flujo va `router` → `service` → `repository`, y los archivos hermanos se importan por ruta completa. Ningún `relationship()` cruza módulos. |
| V — Spec primero, y con firma | ✅ | `spec.md` está en `Aprobado`, firmada por Leandro Carriego el 2026-09-13, sin ningún `[NECESITA ACLARACIÓN]`. Este plan cubre `RF-01` a `RF-32` y **no agrega** ningún requisito. |
| VI — Lo que no está tipado y testeado no está terminado | ✅ | Todo tipado (`PY-04`, `TS-01`), con `mypy` y `tsc` limpios. Los tests los escribe el `Tester` **antes** de la implementación y se firman por historia (`/approve-tests`), como en `001`. La suite sigue corriendo sin red y sin API key: esta feature no agrega ni una llamada al proveedor, así que no necesita JSON fijado nuevo (`TEST-03`). |
| VII — El enunciado es el contrato, y sus ambigüedades se declaran | ✅ | Los textos son los literales de `COPY.md`, verbatim, y los cinco que el enunciado no da ya están registrados ahí y en la spec con su porqué. `A3` (el autocomplete sale de la base) y `A4` (NYSE **y** NASDAQ) están resueltos en el brief y este plan los respeta. Nada que el enunciado no pida: sin paginación, sin orden por columna, sin cotización en la grilla. |
| VIII — Un idioma para cada audiencia | ✅ | Código, commits y docstrings en inglés; artefactos en español; los strings de pantalla en español y verbatim de `COPY.md`. Las direcciones nuevas (`/stocks/:symbol`) son identificadores técnicos. |
| IX — Las dependencias entran por la puerta | ✅ | **Ningún paquete nuevo**, ni en el backend ni en el frontend: el autocomplete, el debounce y el diálogo de confirmación se escriben con lo que ya hay (React 19 y Tailwind). Si aparece uno, entra con `uv add` / `npm install` y su lockfile en el mismo commit. `pg_trgm` no es una dependencia del proyecto: es una extensión que el Postgres oficial ya trae, y entra por migración como cualquier otro cambio de esquema (`DB-02`). |
| X — Las decisiones de arquitectura las toma un humano | ✅ | Este plan **no agrega ningún ADR** a `docs/DECISIONS.md` ni toca los que hay. Se apoya sólo en ADR **aceptados** (`ADR-001`, `ADR-002`, `ADR-004`): ninguno en `Propuesta` se cita como autoridad. Las decisiones de alcance local —el orden de las sugerencias, la forma del alta idempotente, la dirección del detalle— viven acá, que es su lugar. |

**Excepciones solicitadas:** ninguna.

## Enfoque

La feature son **dos módulos y una pantalla**. `stocks` deja de ser sólo ingesta y empieza a
responder: gana `router.py`, `io.py` y dos funciones de lectura sobre el catálogo que ya se
reconcilia solo. `favorites`, que hasta hoy es una tabla y un `__init__` vacío, nace completo
—`router`, `service`, `repository`— y es el dueño de `user_stocks`. El frontend termina de armar
el wireframe 02: el campo `Símbolo` con sus sugerencias, `Agregar Símbolo`, y la grilla con su
baja y su enlace al detalle.

**El autocomplete consulta Postgres, no al proveedor.** Es `A3` y el Artículo II: la tabla
`stocks` tiene hoy los dos mercados de `A4` ingestados y la mantiene al día
`keep_the_catalogue_fresh`. Tipear en el campo no gasta un solo request de los 800 diarios, y por
eso el debounce del frontend es una cortesía con el servidor propio y no una defensa de la cuota.
La búsqueda es `ILIKE '%texto%'` sobre símbolo y nombre, y va **acelerada con trigramas**:
`pg_trgm` más un índice GIN por columna, que es lo único que puede indexar un patrón que empieza
con comodín (un B-tree ahí no sirve para nada). Entra con su migración, y con una limitación que
hay que saber de antemano: **el índice recién entra en juego a partir del tercer carácter**, porque
un patrón de dos letras no tiene ningún trigrama completo que buscar. La búsqueda de dos caracteres
de `RF-13` sigue siendo un escaneo secuencial de ~7.200 filas — milisegundos, y por eso alcanza.
Y el patrón lo arma el repositorio **escapando `%`, `_` y la propia barra**, con su `ESCAPE '\'`
declarado: si no, el usuario escribe el operador y dos caracteres dejan de acotar nada (el detalle
y el porqué de la barra, en `GET /api/stocks`).

**La lectura cruzada es la que `ARCHITECTURE.md` ya había dibujado, y esta feature la estrena.**
`favorites` es dueño de `user_stocks`, que guarda `(user_id, symbol, added_at)` y nada más: ni el
nombre ni la moneda se copian ahí, porque viven en `stocks`, una vez, donde la ingesta los
mantiene. Para pintar la grilla, `favorites/service.py` le pide sus símbolos al repositorio y
después le pide **al paquete `stocks`**, en una sola llamada, la descripción de todos ellos. Una
consulta para toda la grilla, nunca una por fila.

**El alta es idempotente por construcción, no por un `if`.** La clave primaria compuesta
`(user_id, symbol)` ya hace imposible la fila repetida; el repositorio inserta con
`ON CONFLICT DO NOTHING` y devuelve si insertó o no. Eso resuelve `RF-18` y `TEST-04` incluso para
el segundo request de un doble click que el primero todavía no terminó de servir, y es lo que
descarta el 409: agregar dos veces la misma acción no es un error, es una operación que ya estaba
hecha.

La diferencia viaja **en el status**: **201** cuando la fila se creó, **200** cuando ya estaba, con
el mismo cuerpo en los dos casos. Es la semántica correcta de HTTP y tiene un costo que se paga una
vez: `api/client.ts` hoy devuelve el JSON parseado y nada más, así que hay que exponer el status
—sin romper los llamados que ya existen— para que la pantalla pueda decidir si muestra
`Esa acción ya está en tu lista.` Cómo, en *Contratos* → *Frontend*.

**La identidad entra por el token y sólo por el token.** Las tres rutas de `favorites` toman el
`user_id` de `get_current_user` (`app/security.py`), ninguna lo acepta en la URL ni en el body, y
la firma del repositorio lo exige como primer argumento. El símbolo sí viaja en el path de la baja,
y eso no es una identidad: es el objeto, y el filtro por usuario es lo que lo acota a la lista de
quien pide. Acá nace el test de aislamiento con dos usuarios reales que `GEN-09` estaba esperando.

### Dónde cae cada requisito

| RF | Dónde se resuelve |
|---|---|
| `RF-01`, `RF-03` | `GET /api/favorites` + `StockGrid.tsx` |
| `RF-02`, `RF-23`, `RF-29` | `StockGrid.tsx` (cuatro columnas, la cuarta sin encabezado; `Eliminar` y el símbolo como enlaces) |
| `RF-04`, `RF-22`, `RF-28` | `favorites/repository.py`: toda query filtra por el `user_id` del token |
| `RF-05`, `RF-17` | `user_stocks` + `stocks` (persistencia; nada se guarda en el navegador) |
| `RF-06` | `favorites/repository.py` → `ORDER BY added_at DESC, symbol ASC` |
| `RF-07` | `StockGrid.tsx` (estado vacío con los encabezados a la vista) |
| `RF-08`, `RF-09`, `RF-10` | `stocks/repository.py` → `ILIKE` sobre `symbol` y `name` (trae candidatos, no sugerencias) |
| `RF-11` | `SUGGESTION_LIMIT = 20` en `stocks/service.py`, aplicado **después** del orden por relevancia |
| `RF-12` | `WHERE delisted_at IS NULL` en la búsqueda |
| `RF-13` | `Autocomplete.tsx` (mínimo 2 caracteres) + `Query(min_length=MIN_QUERY_LENGTH)` en el router + la guarda de `search_stocks`, que vuelve a medir después del `strip()` |
| `RF-14` | `Autocomplete.tsx` (respuesta vacía → el texto del desplegable) |
| `RF-15`, `RF-16` | `POST /api/favorites` + refetch de la grilla |
| `RF-18` | `ON CONFLICT DO NOTHING` sobre la PK compuesta |
| `RF-19`, `RF-20`, `RF-21`, `RF-31` | `SymbolPicker` en `MyActions.tsx` (los dos avisos excluyentes y el botón deshabilitado) |
| `RF-24`, `RF-26` | `DELETE /api/favorites/{symbol}` + refetch |
| `RF-25`, `RF-32` | `ConfirmDialog.tsx` |
| `RF-27` | La baja no toca `stocks`: el símbolo sigue en el catálogo y se vuelve a sugerir |
| `RF-30` | El enlace del símbolo → `/stocks/:symbol` |

## Módulos afectados

| Módulo | Piezas tocadas | Qué cambia | Nuevo |
|---|---|---|---|
| `stocks` | `backend/app/modules/stocks/router.py` · `io.py` · `service.py` · `repository.py` · `models.py` · `__init__.py` | El módulo deja de ser sólo ingesta: suma la búsqueda del autocomplete (`search_stocks`) y la lectura en batch que consume `favorites` (`get_stocks`), más su router. De `models.py` cambian **sólo los dos `Index(...)` de trigramas** al pie: ninguna columna, ninguna tabla. | `router.py`, `io.py` |
| `favorites` | `backend/app/modules/favorites/router.py` · `io.py` · `service.py` · `repository.py` · `__init__.py` | **El módulo nace completo**: las tres rutas, las decisiones del alta y de la baja, y el acceso a `user_stocks`. `models.py` ya existe desde la fase 0 y no cambia. | `router.py`, `io.py`, `service.py`, `repository.py` |
| composition root · shared | `backend/app/main.py` · `backend/app/errors.py` | `main.py` monta los dos routers nuevos (`GEN-04`) y registra un handler más; `errors.py` suma `UnknownSymbolError`. Nada más del kernel se toca: ni `db.py`, ni `security.py`, ni `settings.py`, ni `ratelimit.py`, ni `providers/`. | `UnknownSymbolError` |
| migraciones | `backend/alembic/versions/` | Una migración: `CREATE EXTENSION IF NOT EXISTS pg_trgm` y los dos índices GIN de `stocks`. Las migraciones son del proyecto, no del módulo. | la revisión nueva |
| web | `frontend/src/api/client.ts` · `api/stocks.ts` · `api/favorites.ts` · `api/schema.d.ts` · `api/auth.ts` · `auth/SessionProvider.tsx` · `components/Autocomplete.tsx` · `components/StockGrid.tsx` · `components/ConfirmDialog.tsx` · `pages/MyActions.tsx` · `pages/ActionDetail.tsx` · `App.tsx` | `client.ts` aprende a **resolver** el token de la sesión —el provider, con la regla de precedencia frente al `token` explícito que ya manda desde `001`—, a hablar `DELETE` y a dejar ver el status; `SessionProvider` registra de dónde sale el token, igual que ya registra el 401; de `api/auth.ts` cambia **una sola línea**, el `token: null` con el que `login()` declara que se hace sin sesión; `MyActions` pasa de un título a la pantalla del wireframe; `App.tsx` suma la ruta del detalle. | los tres componentes, los dos módulos de `api/`, `ActionDetail.tsx` |

Ni `auth` ni `quotes` se tocan. `app/providers/` tampoco: esta feature no sale al mundo.

**`api/schema.d.ts` se regenera con `make types`, no se edita a mano** (`TS-03`).

**La pantalla de detalle que entra acá es un cascarón**, y es deliberado: `H4` promete llegar a la
acción correcta, no lo que esa pantalla muestra. Es el mismo movimiento que hizo `001` con
`MyActions.tsx` —una pantalla mínima para que el ingreso tuviera a dónde llegar—, y `003` la
reemplaza entera. Lo que renderiza es el símbolo que viene de la URL: ningún texto nuevo, así que
`COPY.md` no cambia por esto.

## Contrato entre módulos

| Frontera | Qué se pide | Qué se devuelve |
|---|---|---|
| router → service (`stocks`) | `search_stocks(session: AsyncSession, text: str) -> list[StockInfo]` — el router pasa el texto tal como llegó; normalizar es una decisión y no se toma en la capa HTTP (`PY-06`). **Qué hace el service con ese texto —`strip()`, en qué caja compara y qué pasa si queda corto— está fijado en `GET /api/stocks`** | Hasta `SUGGESTION_LIMIT` (20) `StockInfo`, ya ordenadas por relevancia y sin las que dejaron de cotizar (`RF-11`, `RF-12`). **El service ordena primero y corta después**: el corte en 20 no baja al repositorio. Con menos de `MIN_QUERY_LENGTH` caracteres después del `strip()`, `[]` sin tocar la base |
| router → service (`favorites`) | `list_favorites(session, user_id: int) -> list[FavoriteStock]` · `add_favorite(session, user_id: int, symbol: str) -> FavoriteAddition` · `remove_favorite(session, user_id: int, symbol: str) -> None`. El `user_id` sale de `CurrentUser.id` y de ningún otro lado (Artículo III) | `FavoriteStock` (`symbol`, `name`, `currency`) y `FavoriteAddition` (`created: bool`, `favorite: FavoriteStock`), dataclasses frozen del módulo. `add_favorite` levanta `UnknownSymbolError` si el símbolo no está en el catálogo o dejó de cotizar |
| service → repository (`stocks`) | `search_listed(session, text: str, limit: int) -> list[Stock]` — `text` llega **ya normalizado** (`strip()` hecho, caja sin tocar: el `ILIKE` es case-insensitive por sí mismo) y nunca vacío, porque el service ya cortó; llega **sin escapar**, porque **escapar `\`, `%` y `_` y declarar el `ESCAPE '\'` es del repositorio**: armar el patrón es filtrar, y el service no conoce la sintaxis del operador (ver `GET /api/stocks`); `limit` es el **tope de candidatos** (`CANDIDATE_LIMIT`), **no** el tope de sugerencias: el repositorio filtra y trae, y ordenar por relevancia y cortar en `SUGGESTION_LIMIT` son decisiones del service (ver `GET /api/stocks`) · `find_many(session, symbols: Sequence[str]) -> list[Stock]` | Filas de `stocks`, **sin ordenar por relevancia**. **El modelo no sale del módulo**: el service lo convierte en `StockInfo` |
| service → repository (`favorites`) | `symbols_of(session, user_id: int) -> list[str]` (ordenados) · `add(session, user_id: int, symbol: str) -> bool` · `remove(session, user_id: int, symbol: str) -> None`. Las tres reciben el `user_id` como primer argumento y **no tienen forma de recibir otro** (`GEN-09`) | Datos, nunca decisiones: los símbolos en orden, y si el `INSERT` insertó o chocó con la clave |
| service → provider | Ninguna. Esta feature no sale al mundo: el catálogo ya está ingestado (`A3`, `ADR-002`) | — |
| este módulo → `__all__` de otro | `favorites` consume `from app.modules.stocks import get_stocks, StockInfo`, **por el paquete y en batch**. Del kernel usa `app.db` (`SessionDep`, `AsyncSession`), `app.errors` (`UnknownSymbolError`) y `app.security` (`get_current_user`, `CurrentUser`), que no son módulos | `get_stocks(session, symbols) -> list[StockInfo]`: una llamada para toda la grilla |
| `__all__` de este módulo → el resto (qué se agrega) | `stocks`: suma `router`, `get_stocks` y `StockInfo` a `keep_the_catalogue_fresh`. `favorites`: pasa de `[]` a `["router"]` | — |

Con esto, el inventario completo de lecturas cruzadas del backend sigue siendo el que
`ARCHITECTURE.md` declara —`get_stocks` y `StockInfo`, de `stocks`, que consume `favorites`— y no
crece ni un nombre.

**Una precisión sobre esa firma.** `ARCHITECTURE.md` la escribe como
`get_stocks(symbols: list[str]) -> list[StockInfo]`; la real lleva la sesión adelante,
`get_stocks(session: AsyncSession, symbols: Sequence[str]) -> list[StockInfo]`, igual que
`authenticate(session, ...)` en `auth`. La sesión es de la request y la abre el router: una función
que la abriera por su cuenta dejaría el alta fuera de la transacción de quien la llamó. Al cerrar
la feature, `ARCHITECTURE.md` se corrige con la firma que quedó.

**Con la lista vacía, `get_stocks` corta en el service y devuelve `[]` sin tocar la base.** Es el
caso del usuario sin favoritas (`RF-07`), y ocurre en el camino normal de `GET /api/favorites`, no
en un borde raro: el service de `favorites` pide sus símbolos al repositorio, no hay ninguno, y le
pasa esa lista a `get_stocks` igual. El `find_many` no llega a llamarse. Un `WHERE symbol IN ()` es
una consulta cuyo resultado ya se conoce antes de escribirla: un viaje a Postgres —con su conexión
del pool y su round trip— para que devuelva exactamente las cero filas que la lista vacía ya
garantiza. Además, `IN ()` no es SQL válido y cada dialecto lo emula a su manera, así que el
comportamiento de ese caso dependería de SQLAlchemy en vez de estar decidido acá.

La guarda va en `service.py` y **no** en `repository.py`, por la misma regla que ordena todo lo
demás del módulo: "si esta consulta vale la pena" es una decisión, y las decisiones son del service;
el repositorio trae datos y no razona sobre lo que le piden (`PY-06`). Y `[]` es un resultado, no
una falla: no se levanta ninguna excepción, igual que la búsqueda sin coincidencias.

**El orden de la lista que devuelve `get_stocks` no es contrato.** Quien la consume reordena: hoy
lo hace `favorites`, que ya tiene el suyo —`added_at DESC, symbol ASC`— y vuelve a poner las
descripciones en el orden en que pidió los símbolos. Escribirlo de este lado es lo que deja al
repositorio resolver el `IN` como le convenga —un `IN` de Postgres no promete devolver las filas en
el orden de la lista— sin que un día un `ORDER BY` que nadie pidió se convierta en una garantía de
la que alguien empezó a depender sin saberlo.

**Y los símbolos repetidos colapsan: `get_stocks(session, ["MSFT", "MSFT"])` devuelve una sola
`StockInfo`, no dos.** Es la semántica de conjunto que la palabra "conjunto" ya insinúa, hecha
explícita. El largo de la salida no acompaña al de la entrada, ni con los repetidos ni con los
desconocidos: un símbolo que no está en el catálogo simplemente no aparece, y eso tampoco es una
falla (ver `add_favorite`, que es quien decide qué significa esa ausencia).

Hoy los repetidos **no pueden ocurrir**: la lista sale de `symbols_of`, y del otro lado hay una PK
`(user_id, symbol)` que hace imposible la fila repetida. Es una precondición latente, no un caso
vivo — y por eso justamente conviene escribirla ahora: el día que un segundo consumidor arme la
lista de otra manera, "¿qué pasa si mando dos veces el mismo?" va a tener respuesta en el plan en
vez de en el comportamiento accidental de una query.

**`get_stocks` asume que los símbolos ya vienen en mayúsculas: no normaliza.** Se escribe como
**precondición del contrato público** —está en el `__all__` y lo consume otro módulo—, no como un
detalle de implementación que alguien pueda cambiar sin avisar. La razón es que la normalización ya
tiene un dueño y es el service que consume: `add_favorite` hace `symbol.strip().upper()` antes de
mirar el catálogo, y esa misma regla vale para el alta y para la baja (ver *Contratos* →
`POST /api/favorites`). Si `get_stocks` normalizara también, la regla viviría en dos lados, y dos
lugares que normalizan son dos lugares que un día lo hacen distinto.

**El filo de esa decisión, escrito y no descubierto:** un llamador que pase minúsculas no recibe un
error, recibe `[]` en silencio. Y desde `add_favorite` ese `[]` se traduce en `UnknownSymbolError` y
en un **404** para un símbolo que sí existe en el catálogo. Es el precio de mantener la
normalización en un solo lugar, y se paga barato mientras el único llamador sea el service que ya
normaliza. La defensa no es un `upper()` defensivo adentro de `get_stocks` —eso sería duplicar
exactamente la regla que se quiso no duplicar— sino un test que fije las dos puntas: que
`add_favorite("msft")` da de alta `MSFT`, y que `get_stocks` con minúsculas devuelve `[]`, que es
la precondición escrita en código ejecutable en vez de en prosa.

**Corrección del 2026-09-14, por decisión humana.** Este párrafo cerraba pidiendo como test que
`add_favorite("  msft ")` diera de alta `MSFT`, y ese ejemplo no podía ser cierto: el body de
`POST /api/favorites` lleva el patrón `^[A-Za-z0-9.\-]{1,12}$` con `extra="forbid"` (ver
*Contratos*), que **rechaza los espacios con un 422 antes de que exista ningún service**. Las dos
frases de este plan se contradecían y ninguna implementación podía satisfacer las dos. Ante la
contradicción —detectada durante el `/implement` de `H2`— el humano del proyecto (Leandro Carriego)
decidió que **gana *Contratos***: un símbolo con espacios alrededor es un **422**, porque el símbolo
es un identificador y no texto libre, y el mismo valor viaja después en el path de la baja.

**Lo que no cambia es el dueño de la normalización, que es el argumento de todo este párrafo:**
sigue siendo `add_favorite`, y sigue siendo uno solo. Lo que cambió es qué entrada le llega. De
`symbol.strip().upper()` el que trabaja en la práctica es el `.upper()` —la caja es lo único que el
schema deja pasar y el catálogo no acepta—; el `.strip()` queda como defensa y, sobre todo, como la
regla única que también vale para la baja, que es la razón por la que la normalización vive en el
service y no en el schema. Las dos puntas quedan fijadas en
`backend/tests/integration/test_favorites_add.py` —`{"symbol": "msft"}` → **201** con `MSFT`, y
`{"symbol": " msft "}` → **422** sin escribir ninguna fila— y en
`backend/tests/unit/test_stocks_service.py::TestTheSymbolsArriveInUpperCase`, que es la mitad de
`get_stocks` con minúsculas devolviendo `[]` y no se toca.

Lo que **no** entra a ningún `__all__`, y merece decirse: `search_stocks` (sólo la consume el
router de su propio módulo), `list_favorites`, `add_favorite`, `remove_favorite`, `FavoriteStock`,
`FavoriteAddition`, los repositorios y los schemas de los dos `io.py`. Ningún otro módulo necesita
buscar en el catálogo ni tocar la lista de nadie: son internos, visibles para sus hermanos e
invisibles para el resto del sistema (`PY-10`).

**`StockInfo` lleva cuatro campos y el cuarto hay que justificarlo**: `symbol`, `name`, `currency`
e `is_listed`. Los tres primeros son la grilla (`REQ-08`). El cuarto existe porque `favorites`
tiene que hacer dos cosas contradictorias con el mismo dato: **mostrar** una favorita que dejó de
cotizar —la regla de negocio lo pide expresamente— y **rechazar** el alta de una que ya no se
ofrece. Si `get_stocks` filtrara las delistadas, la grilla perdería filas que el usuario guardó; si
no dijera nada, el alta aceptaría lo que el autocomplete no puede sugerir. Un booleano es menos
superficie que una segunda función exportada.

**Fallas** — el service de `favorites` levanta una sola excepción de dominio, hija de `DomainError`
y en `app/errors.py` (kernel, sin `fastapi` adentro):

| Excepción | HTTP que registra `main.py` | Cuerpo |
|---|---|---|
| `UnknownSymbolError` | **404** | `{"detail": "unknown symbol"}` |

"Unknown" acá significa **no ofrecido hoy**: ausente del catálogo, o presente pero con
`delisted_at`. Las dos son la misma respuesta a propósito — el cliente sólo puede elegir de las
sugerencias, así que las dos significan "eso no se puede agregar", y separarlas serían dos
respuestas para una sola decisión de pantalla que no existe.

Vive en el kernel por la misma razón que `AuthenticationError`: `main.py` tiene que importarla para
registrar el handler, y si viviera adentro de `favorites` habría que exportarla en su `__all__`
—contrato público para un consumidor que no es un módulo—. El cuerpo está en inglés y **nadie lo
muestra**: lo que el usuario lee lo decide la pantalla (`UI-02`, Artículo VIII).

La baja **no tiene falla**: quitar algo que no está es 204 igual (ver *Contratos*). Y la búsqueda
tampoco: sin coincidencias devuelve una lista vacía, que es un resultado, no un error.

## Datos

**Ninguna tabla nueva y ninguna columna nueva. Sí hay migración, y es una sola cosa: la
extensión `pg_trgm` y los dos índices GIN del autocomplete.**

Las dos tablas que usa existen desde la migración inicial de la fase 0 (`394dab64d255`):

- **`stocks`** — `symbol` (PK), `name`, `currency`, `exchange`, `mic_code`, `country`, `type`,
  `last_seen_at`, `delisted_at`. La ingesta de `ADR-002` la reconcilia sola contra la foto del
  proveedor y marca `delisted_at` en vez de borrar, que es justamente lo que hace posible la regla
  de negocio "una acción que deja de cotizar deja de sugerirse pero no desaparece de la lista de
  quien ya la tenía".
- **`user_stocks`** — PK compuesta `(user_id, symbol)`, `added_at` con `server_default=now()`.
  `user_id` → `users.id` con `ON DELETE CASCADE`; `symbol` → `stocks.symbol`. **No copia ni el
  nombre ni la moneda**, y un test del modelo de datos lo verifica.

Tres consecuencias que la feature asume y conviene dejar escritas:

- **`RF-18` y `TEST-04` los resuelve el esquema.** La PK compuesta hace imposible la fila
  repetida; el `ON CONFLICT DO NOTHING` sólo convierte esa garantía en una respuesta amable.
- **`RF-06` necesita un desempate.** `added_at` tiene resolución de microsegundos, pero el seed
  inserta las tres favoritas en un solo statement y `now()` es el mismo para toda la transacción:
  sin desempate, el orden de la grilla del wireframe cambiaría entre dos recargas. El orden es
  `added_at DESC, symbol ASC`, y el segundo criterio es lo que hace que "recargar dos veces no
  cambia nada de lugar" sea cierto.
- **La búsqueda va por trigramas.** `ILIKE '%texto%'` no puede usar un B-tree —el comodín
  adelante lo descarta—, así que la aceleración es `pg_trgm` con un índice GIN por columna.

**La migración de esta feature**, en `backend/alembic/versions/`, con la extensión primero porque
el índice depende de ella:

```python
op.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm")
op.create_index(
    "ix_stocks_symbol_trgm", "stocks", ["symbol"],
    postgresql_using="gin", postgresql_ops={"symbol": "gin_trgm_ops"},
)
op.create_index(
    "ix_stocks_name_trgm", "stocks", ["name"],
    postgresql_using="gin", postgresql_ops={"name": "gin_trgm_ops"},
)
```

Y los dos índices se declaran también en `app/modules/stocks/models.py`, al pie y con `Index(...)`,
que es como ya está declarado el de `quotes`: si viven sólo en la migración, el modelo y la tabla
quedan desincronizados y `alembic check` los reporta como faltantes para siempre (`DB-01`, `DB-03`).
La extensión **no** se declara en el modelo: no es un objeto del `MetaData`, y su lugar es el
`op.execute` de la migración.

Tres cosas que hay que verificar al implementarla, no después:

- **`alembic check` queda limpio.** Un `opclass` reflejado distinto de como se declaró haría que
  autogenerate vea un diff eterno. Si eso pasa, la salida no es borrar el índice del modelo: es
  ajustar la declaración hasta que coincida, y recién como último recurso excluirlo de autogenerate
  con un `include_object` en `alembic/env.py`, escrito con su motivo al lado.
- **`CREATE EXTENSION` necesita privilegios.** En el compose y en el CI el usuario `origin` es el
  dueño del cluster y puede; en un Postgres gestionado puede no poder, y ahí la extensión la crea
  el operador antes del deploy. `IF NOT EXISTS` es lo que hace que la migración no falle en ese caso.
- **`downgrade()` borra los índices y deja la extensión.** Una extensión puede tener otros usuarios,
  y `DROP EXTENSION` en un downgrade es un efecto que nadie pidió.

Después de la feature, `alembic check` tiene que seguir limpio: si alguien toca `models.py` de
cualquiera de los dos módulos y no acompaña la migración, este plan dejó de ser verdad (`DB-01`).

## Contratos

Las cinco rutas **son todas protegidas**: ninguna entra a `PUBLIC_ROUTES`, y las cinco declaran
`get_current_user` importado de `app.security` (`PY-08`). El catálogo no es dato de usuario, pero
tampoco es público: un buscador abierto es scraping gratis del trabajo de la ingesta.

### `GET /api/stocks` — protegida

```
GET /api/stocks?q=micro
Authorization: Bearer <token>

200 [{"symbol": "MSFT", "name": "Microsoft Corp", "currency": "USD"}, ...]
```

- `q: str = Query(min_length=MIN_QUERY_LENGTH, max_length=50)`. El mínimo es `RF-13`, y está en las
  dos puntas a propósito: el frontend no pregunta con menos de dos caracteres, y el router lo
  rechaza igual con 422 si alguien pregunta de todas formas. El máximo es `API4` en una línea.
  **El router mide el texto crudo; el service vuelve a medirlo después del `strip()`** —`"  "` pasa
  los dos caracteres del router y no es ningún texto—, y ahí la respuesta es `200 []` y no un 422:
  el porqué, más abajo.
- Devuelve **a lo sumo 20** (`RF-11`), sin paginación ni cursor: veinte sugerencias son las que
  caben en un desplegable, y el resto no se ofrece. El límite es una constante del service
  (`SUGGESTION_LIMIT`), no un parámetro del cliente, y **se aplica después de ordenar por
  relevancia**, nunca en el `LIMIT` de la consulta.
- Excluye las que tienen `delisted_at` (`RF-12`).
- Sin coincidencias → `200 []`. La lista vacía es un resultado; el texto
  `No se encontró ninguna acción con ese texto.` lo pone la pantalla.
- **El orden es por relevancia, y hace falta.** Con `ILIKE '%micro%'` y veinte lugares, un orden
  alfabético dejaría `MSFT` afuera por culpa de veinte símbolos que empiezan con A: el criterio de
  aceptación de `RF-15` —escribir `micro` y encontrar `MSFT — Microsoft Corp`— se caería. El orden
  es: símbolo exacto → símbolo que empieza con el texto → nombre que empieza con el texto → el
  resto; y dentro de cada grupo, `symbol ASC`, que lo vuelve determinístico.
- El schema de salida (`StockSuggestion`) lleva **tres campos**. `is_listed` no viaja: en esta ruta
  siempre es verdadero, y un campo constante en el contrato es ruido que el frontend tipa.

**Corrección: el repositorio trae candidatos, el service ordena, y recién ahí se corta.** Este plan
fijaba dos cosas que por separado están bien y juntas se contradicen: que el `ILIKE` con su `limit`
vive en el repositorio, y que el orden por relevancia es del service. Encadenadas en ese orden, el
repositorio truncaba en 20 **antes** de que la relevancia existiera y el service ordenaba un
conjunto ya recortado: con `ILIKE '%micro%'`, `MSFT` puede no estar entre las veinte filas que
devolvió el repositorio, y entonces ningún orden posterior la promueve. Es exactamente el criterio
de aceptación de `RF-15` —escribir `micro` y encontrar `MSFT — Microsoft Corp`— que este mismo plan
usa un párrafo más arriba para justificar el orden por relevancia. El defecto no estaba en ninguna
de las dos frases: estaba en la unión, y por eso no se veía leyendo cualquiera de las dos.

Lo que queda fijado, en un solo sentido:

1. `search_listed` trae **todos los candidatos** que cumplen el `ILIKE` y no están delistados, hasta
   un tope de contención de `CANDIDATE_LIMIT` filas.
2. `search_stocks` los ordena por relevancia: símbolo exacto → símbolo que empieza con el texto →
   nombre que empieza con el texto → el resto, y `symbol ASC` adentro de cada grupo.
3. **Recién ahí** corta en `SUGGESTION_LIMIT` (20) y convierte a `StockInfo`.

**El `limit` de `search_listed` cambia de significado, y hay que decirlo con todas las letras: es un
tope de candidatos, no el tope de sugerencias.** Son dos números con dos propósitos distintos que
viven los dos en el service: `SUGGESTION_LIMIT = 20` es un requisito del producto (`RF-11`, lo que
entra en el desplegable) y `CANDIDATE_LIMIT` es una cota de la consulta. Nadie debería volver a leer
`search_listed(..., limit=20)` en este código; si aparece, es este bug otra vez.

**El valor es `CANDIDATE_LIMIT = 10_000`, y está elegido para que hoy no recorte nada.** El catálogo
son ~7.200 filas (NYSE y NASDAQ, `A4`), así que el peor caso concebible —un patrón de dos caracteres
que matchee el catálogo entero— entra completo, y sobra margen para que crezca un 40% sin que el
tope llegue a intervenir. Esa es la propiedad que importa: **mientras el tope sea mayor que el
catálogo, el truncado no puede ocurrir y la relevancia es exacta por construcción**, no por suerte.
Un tope chico —100, 200, 500— habría parecido prudente y habría reintroducido el mismo bug en su
versión difícil de ver: recortaría sólo con los textos más comunes, eligiendo las filas con un orden
que no tiene nada que ver con la relevancia, y el síntoma sería "a veces no aparece la que busco",
que es lo que nadie reproduce. El tope existe igual, porque una consulta sin techo es una consulta
cuyo costo lo fija quien la llama; pero es una red de contención, no un criterio de selección.

**Y el día que el catálogo pase las 10.000 filas, ese tope deja de ser inocuo.** Por eso el service
registra un **`warning` cuando el repositorio devuelve exactamente `CANDIDATE_LIMIT` filas**: hubo
truncado, la relevancia dejó de ser confiable, y esa es la única forma de que un tope que envejeció
deje rastro en vez de degradarse en silencio. La salida entonces no es subir el número una vez más,
sino mover la selección de candidatos a un criterio que **correlacione con la relevancia** —un orden
por `similarity()` de `pg_trgm`, que el índice GIN ya soporta—, y eso es una decisión de otra
feature, no un parche.

No truncar en SQL era la otra salida y se descarta por poco: hoy es equivalente, porque el catálogo
entero entra abajo del tope, y deja el endpoint sin ninguna cota escrita — la clase de omisión que
recién se nota cuando el catálogo ya creció.

Nada de esto mueve el `ILIKE` ni el filtro de delistadas fuera del repositorio, ni sube el orden a
SQL (`PY-06`): filtrar es traer datos y lo hace el repositorio; ordenar y cortar son decisiones, y
las decisiones son del service — la misma regla por la que la guarda de la lista vacía de
`get_stocks` vive en el service y no en el `find_many`.

**Qué hace `search_stocks` con el texto que recibe.** Hasta acá el plan decía dónde **no** se
normaliza —"el router pasa el texto tal como llegó"— y nunca la otra mitad, que es qué decide el
service. Son tres cosas y ninguna es implícita:

1. **`text.strip()`, una sola vez, al entrar.** Es la única normalización: no se colapsan los
   espacios internos, no se quita puntuación, no se recorta a un largo máximo (de eso ya se ocupa
   el `max_length` del router) y **no se cambia la caja del texto que viaja a la base**.
2. **El texto ya normalizado es el que viaja a `search_listed`**, no el crudo. Si viajara el crudo,
   el filtro buscaría `ILIKE '%  micro  %'` —que no matchea nada, porque el catálogo no guarda los
   espacios que tipeó el usuario— mientras la clasificación por relevancia razonaría sobre `micro`:
   las dos mitades de la misma búsqueda hablando de dos textos distintos, y el síntoma sería un
   desplegable vacío para un texto que sí tiene coincidencias. El repositorio recibe **el texto que
   se busca**, ya resuelto como texto; lo que todavía no recibe es un patrón, porque el patrón lo
   arma él — el escapado de `%` y `_` vive ahí, y está unos párrafos más abajo.
3. **En mayúsculas no viaja nada.** El `ILIKE` ya es case-insensitive por sí mismo, así que un
   `.upper()` sobre el patrón no cambiaría ni una fila y sería una segunda regla de normalización
   que alguien podría cambiar sin que ningún test se ponga rojo.

**La clasificación por relevancia compara plegando las dos puntas (`casefold()`), y hace falta
decirlo porque los dos campos no están en la misma caja.** Acá está el filo que no se ve leyendo el
orden de `RF-15`: "símbolo exacto" y "símbolo que empieza con el texto" salen bien poniendo el texto
en mayúsculas, porque el catálogo guarda `MSFT`; con ese mismo `upper()`, "nombre que empieza con el
texto" **no sale nunca**, porque el catálogo guarda `Microsoft Corp` y `"Microsoft Corp"` no empieza
con `MICRO`. Resolver cada campo en su caja serían dos reglas de comparación, y la segunda se
escribe mal el día que alguien copie la primera. Es una sola:

```python
needle = text.strip()
folded = needle.casefold()

exact    = stock.symbol.casefold() == folded
by_symbol = stock.symbol.casefold().startswith(folded)
by_name   = stock.name.casefold().startswith(folded)
```

`casefold()` y no `lower()` porque es la operación que Python define para comparar sin caja, y el
catálogo tiene nombres de emisoras de dos mercados: es gratis y no depende de que los nombres sean
ASCII. Y el plegado es **sólo de la clasificación**: lo que se le manda a Postgres sigue siendo
`needle` tal cual, porque el `ILIKE` ya no distingue. El orden de `symbol ASC` adentro de cada grupo
tampoco se pliega —los símbolos del catálogo son todos mayúsculas, así que no hay nada que plegar—.

**Y el texto que queda vacío después del `strip()` no llega a la base: corta en el service y
devuelve `[]`.** La regla es apenas más ancha que "vacío", porque el vacío es su versión extrema:
**menos de `MIN_QUERY_LENGTH` (2) caracteres después del `strip()` → `[]`, sin consultar nada.**

Es el mismo movimiento que **la lista vacía de `get_stocks`, que corta en el service y devuelve `[]`
sin tocar la base**, y por la misma razón: una consulta cuyo resultado ya se conoce antes de
escribirla no se hace, y "si esta consulta vale la pena" es una decisión, así que vive en el service
y no en el repositorio (`PY-06`). Lo que se evita es concreto: `q = "  "` —dos espacios— pasa el
`Query(min_length=2)` del router, y sin la guarda termina en `ILIKE '%%'`, que matchea el catálogo
entero — ~7.200 filas traídas de la base y ordenadas por relevancia contra un texto que no existe,
para devolver las veinte primeras alfabéticamente. `q = "a "` es la misma historia con un carácter:
`ILIKE '%a%'` es casi todo el catálogo, y es exactamente el costo que el mínimo de `RF-13` existe
para no pagar.

**No es un 422 y no es una excepción, y eso es deliberado.** Un service que levantara algo para que
el router lo tradujera a 422 estaría opinando sobre el transporte, que es lo que `PY-06` prohíbe
—la misma regla por la que el alta devuelve `created: bool` y no un status—. Y la respuesta ya está
fijada un poco más arriba: **sin coincidencias → `200 []`**. La pantalla no gana ninguna rama nueva,
porque la del desplegable vacío ya existe (`No se encontró ninguna acción con ese texto.`, `RF-14`).
`[]` es un resultado, no una falla.

**El filo, escrito y no descubierto:** el router y el service miden cosas distintas, así que la
validación del largo **no es simétrica**, y hay que saberlo antes de verlo. `q = "a"` —un carácter—
responde **422**, porque lo rechaza el `Query(min_length=...)` antes de que exista un service;
`q = "  "` y `q = "a "` responden **`200 []`**, porque pasan el router y los corta el service. Son
dos respuestas para lo que un cliente podría llamar el mismo error, y se aceptan: el 422 es el
contrato del transporte sobre lo que se recibió, el `[]` es el resultado del dominio sobre lo que se
preguntó, y unificarlas obligaría o a normalizar en la capa HTTP o a hablar HTTP desde el service.
El test de `RF-13` fija **las dos**, porque una asimetría que no está en un test es una asimetría
que alguien "arregla" la primera vez que la ve.

**El `2` se escribe una sola vez.** `MIN_QUERY_LENGTH = 2` es una constante de `stocks/service.py`,
al lado de `SUGGESTION_LIMIT` y `CANDIDATE_LIMIT`, y el router la importa por ruta completa
—`from app.modules.stocks.service import MIN_QUERY_LENGTH`, que es la dirección permitida
(`router` → `service`)— para declarar su `Query(min_length=MIN_QUERY_LENGTH, max_length=50)`. Así
`RF-13` no vive en dos literales que un día dicen números distintos. La constante **no** entra a
ningún `__all__`: es interna del módulo, igual que `search_stocks` (`PY-10`).

**Los comodines del `LIKE` los escapa el repositorio, y el service nunca los ve.** `%` y `_` no
son caracteres cualquiera adentro de un `ILIKE`: `%` es "cualquier cosa" y `_` es "cualquier
carácter". Sin escapar, el patrón `'%' || text || '%'` le deja al usuario escribir el operador:
`q = "%a"` termina en `ILIKE '%%a%'`, que matchea **todo lo que contenga una `a`**, y `q = "a_c"`
matchea `abc`. No es inyección —el texto viaja bindeado, nunca concatenado al SQL— y no toca la
cuota del Artículo II, porque el autocomplete no sale al proveedor. Es otra cosa, y son dos: un
desplegable que devuelve resultados que el usuario no puede explicar, y **un escaneo ancho
disparado por un texto corto que la guarda de `MIN_QUERY_LENGTH` no detiene** — `"%a"` tiene dos
caracteres y pasa. Eso último es lo que lo vuelve una corrección y no una prolijidad: la guarda de
dos caracteres existe porque se asume que dos caracteres **acotan** la búsqueda, y un comodín rompe
ese supuesto sin que la guarda se entere.

Lo que queda fijado:

1. **`search_listed` escapa `\`, `%` y `_` antes de armar el patrón**, y declara el escape:
   `ilike(f"%{escaped}%", escape="\\")`, que en SQL es `ILIKE :pattern ESCAPE '\'`.
2. **El orden del escapado es `\` primero, después `%` y `_`.** Al revés, el `\` que se agrega para
   escapar un `%` se vuelve a escapar y el patrón termina buscando barras que nadie escribió. Es el
   error clásico de esta función y por eso se escribe acá.
3. **El service no escapa nada.** `search_stocks` sigue trabajando con el texto del usuario tal
   cual: el `strip()`, la guarda del largo y la clasificación por relevancia miran `needle`, no un
   patrón.

**Por qué el repositorio y no el service, que es donde viven las otras decisiones del texto.** No es
conveniencia y no contradice el precedente: contradice la lectura fácil de ese precedente. El
`strip()` vive en el service porque `" micro "` no es lo que la persona quiso buscar **con
cualquier motor de búsqueda**: es una decisión sobre *qué* se busca. Escapar un `%` no es una
decisión sobre qué se busca — es sintaxis de un operador en particular. `%` sólo significa algo
porque el repositorio eligió `ILIKE`; el día que esa consulta pase a `similarity()` de `pg_trgm` o a
un `tsquery` —que es la salida que este mismo plan deja escrita para cuando el catálogo crezca—, el
escapado no se vuelve innecesario: se vuelve **incorrecto**, y estaría en el archivo que no se tocó.
La regla de `PY-06` sale igual que siempre: filtrar es traer datos y lo hace el repositorio, y armar
el patrón **es** filtrar. El service decide qué texto se busca; el repositorio decide cómo se lo
pregunta a Postgres.

**Y el filo que lo cierra: si el escapado subiera al service, la clasificación por relevancia se
rompe.** El service compara `needle` contra el catálogo (`casefold()`, `startswith`), y un service
que escapara tendría en la mano `s\_p`: `"S_P Global"` ya no empezaría con el texto, porque el
catálogo no guarda barras invertidas. Sería exactamente la falla que este plan ya describió una vez
—las dos mitades de la misma búsqueda hablando de dos textos distintos— sólo que al revés: el
filtro correcto y el orden ciego. Dos textos en el service es el bug; un texto en el service y un
patrón en el repositorio es la frontera.

**El carácter de escape es `\` y no uno cualquiera, y eso es el índice.** `pg_trgm` extrae los
trigramas de un patrón de `LIKE` parseándolo él mismo, y parsea asumiendo la barra invertida.
Declarar `ESCAPE '!'` —que en SQL es igual de válido— dejaría al índice leyendo un patrón distinto
del que Postgres evalúa, y esa divergencia sólo puede **perder** filas: el recheck contra el heap
filtra lo que el índice trajo de más, nunca recupera lo que no trajo. Un `ESCAPE` no declarado
tampoco es la respuesta: la barra ya es el default de Postgres, pero escribirlo hace visible que el
patrón tiene sintaxis, y lo deja inmune a que el default cambie o a que el motor deje de ser este.
Fuera de eso, el índice no se toca: un texto normal —`micro`, `msft`— no contiene ninguno de los
tres caracteres, así que el patrón y sus trigramas son byte por byte los de antes. El escapado no
cuesta nada en el caso que ocurre siempre.

**A `q` no se le pone un patrón en el router, y la asimetría con el símbolo es deliberada.** El
símbolo lleva `^[A-Za-z0-9.\-]{1,12}$` (`POST /api/favorites`) porque es un **identificador**: hay
un conjunto cerrado de lo que puede ser, y lo que cae afuera no existe en ningún catálogo. `q` es
**texto libre** que escribe una persona mirando un campo, y un patrón ahí es una lista blanca sobre
algo que no tiene forma: habría que enumerar el apóstrofo de `Macy's`, el `&` de `AT&T`, el punto,
la coma, la barra, el espacio y cualquier acento, y el día que falte uno el autocomplete responde
422 a un nombre que está en el catálogo. Rechazar con 422 lo que una persona puede escribir sin
ninguna mala intención es un costo real, y acá no compra nada que el escapado no dé mejor. Además
sería una **tercera forma de rechazar**, encima de las dos que este plan ya aceptó y escribió
(`q = "a"` → 422 desde el router, `q = "  "` → `200 []` desde el service): con el escapado no hay
ninguna forma nueva. `q = "%a"` cae en una rama que ya existe — busca el texto literal `%a`, no lo
encuentra, y devuelve **`200 []`**, `No se encontró ninguna acción con ese texto.` (`RF-14`). Un
comodín escrito a mano deja de ser un operador y pasa a ser lo que el usuario ve: dos caracteres que
no están en ningún nombre.

**Y la guarda del largo sigue midiendo el texto crudo, no el escapado.** `"%a"` son dos caracteres y
pasa, como pasaba antes; lo que cambió es que ahora eso es verdad: dos caracteres literales acotan
la búsqueda tanto como `ab`. Medir el escapado convertiría `"%a"` en un texto de tres —midiendo
sintaxis en vez de intención— y haría que el mínimo de `RF-13` dependa de qué caracteres tipeó la
persona. La guarda cuenta lo que el usuario escribió; el repositorio se ocupa de que eso sea texto.

**El símbolo del alta no entra acá.** `add_favorite` busca por igualdad sobre un símbolo que ya pasó
`^[A-Za-z0-9.\-]{1,12}$`: ni hay `LIKE` ni pueden llegar los caracteres. La función de escapado es
del repositorio de `stocks` y vive ahí, privada del archivo (`_escape_like`, guión bajo adelante,
`PY-10`): no es una utilidad transversal, porque sólo hay una consulta en todo el backend que arma
un patrón.

**Y el texto corto no deja log.** El truncado de `CANDIDATE_LIMIT` sí registra un `warning`
(`structlog`, `ERR-03`) porque significa que la relevancia dejó de ser confiable; un texto que no
alcanza el mínimo no significa nada parecido: es un resultado normal de una ruta que cualquier
autenticado puede llamar con el texto que se le ocurra, y loguearlo sería darle al cliente la
lapicera del archivo de logs.

### `GET /api/favorites` — protegida

```
200 [{"symbol": "MSFT", "name": "Microsoft Corp", "currency": "USD"}, ...]
```

La lista del usuario del token, ordenada de la más reciente a la más vieja (`RF-06`). Sin
favoritas → `200 []`; el texto `Todavía no agregaste ninguna acción.` es de la pantalla, y los
encabezados de la grilla se siguen viendo (`RF-07`).

El service pide los símbolos al repositorio (ya ordenados) y las descripciones **al paquete
`stocks`, en una sola llamada**; después las vuelve a poner en el orden en que las pidió, porque
`get_stocks` devuelve un conjunto y el orden es una decisión de `favorites`.

### `POST /api/favorites` — protegida

```
POST /api/favorites          {"symbol": "MSFT"}

201 {"symbol": "MSFT", "name": "Microsoft Corp", "currency": "USD"}   ← se agregó
200 {"symbol": "MSFT", "name": "Microsoft Corp", "currency": "USD"}   ← ya la tenía (RF-18, RF-19)
404 {"detail": "unknown symbol"}                                      ← no está, o dejó de cotizar
```

- **201 si creó la fila, 200 si ya estaba, y el mismo cuerpo en los dos casos** (`FavoriteItem`).
  Nunca 409: `TEST-04` pide que agregar dos veces no duplique **ni falle**.
- **Cómo se escribe eso en FastAPI.** La ruta se declara con `status_code=201` y el handler baja a
  200 por el objeto `Response` cuando el service dice que ya estaba — el mismo mecanismo que usa
  `/api/health` para su 503. Y declara `responses={200: {"model": FavoriteItem}}`, porque si no el
  OpenAPI documenta sólo el 201 y `schema.d.ts` queda con media respuesta.
- El service sigue devolviendo `FavoriteAddition(created: bool, favorite: FavoriteStock)`: el
  booleano es la decisión del negocio y el status es su traducción al transporte, que es trabajo
  del router (`PY-06`). Un service que devolviera 201 ya estaría hablando HTTP.
- El body es `{"symbol": str}` con `extra="forbid"` (`API3`), `max_length=12` y el patrón
  `^[A-Za-z0-9.\-]{1,12}$`: el símbolo viaja después en una URL, y lo que no puede ser un segmento
  de path no puede ser un símbolo.
- El service normaliza a mayúsculas (`symbol.strip().upper()`) antes de mirar el catálogo. El
  catálogo guarda mayúsculas, y normalizar en el service —no en el schema ni en el repositorio— es
  lo que hace que la misma regla valga para el alta y para la baja.
- Orden adentro de `add_favorite`: **primero el catálogo, después la escritura**. `get_stocks`
  decide si el símbolo existe y si sigue cotizando; recién si pasa, el `INSERT`. Al revés, la clave
  foránea rechazaría lo inexistente con un `IntegrityError` que hay que traducir, y lo delistado
  entraría igual.

### `DELETE /api/favorites/{symbol}` — protegida

```
DELETE /api/favorites/NFLX   →  204
```

- **204 siempre**, incluso si esa acción no estaba en la lista. La baja es idempotente: quien
  borra dos veces quiere lo mismo las dos veces, y un 404 sólo le contaría a un atacante si el
  símbolo estaba en la lista de alguien — y eso lo cubre igual el filtro por usuario.
- `symbol` en el path, validado con el mismo patrón que el alta. **No es una identidad**: el
  aislamiento lo da el `WHERE user_id = <el del token> AND symbol = ...`, y por eso `RF-28` es
  cierto sin ningún chequeo extra — el `DELETE` de un usuario no puede alcanzar la fila de otro.
- No toca `stocks`: el símbolo sigue en el catálogo y se vuelve a sugerir en la próxima búsqueda
  (`RF-27`).

### `GET /stocks/:symbol` — la dirección del detalle (frontend)

`RF-30` necesita que el enlace del símbolo lleve a algún lado. La dirección es `/stocks/:symbol`,
con el símbolo en mayúsculas, que es la que el `plan.md` de `001` ya había anticipado para `003`:
se respeta para no mover la URL de una feature a la otra. La ruta queda **protegida** por
`RequireSession`, como `/`.

### Frontend — estructura y contrato de pantalla

```
src/
├── App.tsx                    suma /stocks/:symbol, protegida
├── api/
│   ├── client.ts              + el token de la sesión, + DELETE, + 204 sin cuerpo, + el status
│   ├── auth.ts                una línea: `login()` declara `token: null` (se hace sin sesión)
│   ├── stocks.ts              searchStocks(q)
│   ├── favorites.ts           listFavorites() · addFavorite(symbol) · removeFavorite(symbol)
│   └── schema.d.ts            GENERADO por `make types` — no se edita a mano (TS-03)
├── auth/
│   └── SessionProvider.tsx    registra de dónde sale el token, igual que ya registra el 401
├── components/
│   ├── Autocomplete.tsx       el campo `Símbolo`, su desplegable y la selección
│   ├── StockGrid.tsx          la grilla: cuatro columnas, el estado vacío y los enlaces
│   └── ConfirmDialog.tsx      `¿Quitar {símbolo} de tus acciones?`
└── pages/
    ├── MyActions.tsx          wireframe 02 completo: compone las tres piezas y tiene el estado
    └── ActionDetail.tsx       cascarón: existe para que RF-30 llegue a algún lado (003 la escribe)
```

**El token viaja en `Authorization: Bearer`, y `client.ts` lo resuelve por el mismo mecanismo de
registro con el que ya resuelve qué hacer ante un 401**: un
`setAuthTokenProvider(() => string | null)` que registra `SessionProvider`, en el mismo efecto donde
ya registra el interceptor. El cliente no importa nada de `auth/` —sería un ciclo—, y la sesión
sigue siendo la única dueña del token.

**Ese provider convive con el `token` explícito de `RequestOptions`; no lo reemplaza.** Hay que
decirlo porque el camino explícito **ya existe y ya se usa**: `001` dejó `request(path, { token })`
—`client.ts` pone la cabecera cuando la llamada trae token— y `api/auth.ts` tiene hoy dos funciones,
`login()`, que se hace sin sesión, y `fetchMe(token)`, que se hace con un token explícito. Y
`fetchMe` es justamente el caso que vuelve la pregunta no retórica: es la llamada de la
**restauración**, la que pregunta si el token que el navegador guardó todavía vale, y ocurre
*antes* de que haya sesión registrada. Si el provider fuera el único camino, que esa llamada mande o
no la cabecera dependería del orden en que `SessionProvider` corre sus efectos: un acoplamiento
invisible, que funciona hasta el día que alguien reordena dos `useEffect`.

Así que la regla es de **precedencia**, tiene tres casos y ninguno es implícito:

| Qué declara la llamada | Qué cabecera sale |
|---|---|
| `token: '<algo>'` | `Authorization: Bearer <algo>`. **Lo explícito gana**, haya o no provider registrado |
| `token: null` | **Ninguna**, haya o no provider registrado: la llamada declara que se hace sin sesión |
| `token` ausente | La del provider, si hay uno registrado y devuelve un token. **Ninguna** si no hay provider, o si devuelve `null` |

El campo pasa de `token?: string` a `token?: string | null`, y ese `null` es lo que le da a una
llamada la forma de decir "yo no llevo credencial" sin depender de que en ese momento no haya
ninguna. `login()` lo declara —una línea en `api/auth.ts`, al lado del `announcesLostSession: false`
que ya declara por el mismo motivo: es la llamada que existe precisamente para cuando todavía no hay
sesión—. `fetchMe(token)` no cambia ni una línea: sigue pasando su token, y ahora está escrito por
qué gana.

Y las **cinco rutas nuevas no pasan `token`**: son llamadas de una pantalla interna, y quién las
hace lo sabe la sesión, no la pantalla. Por eso `listFavorites()` sin argumentos es la firma
correcta y no una comodidad — enhebrar el token por cada función de `api/` sería repartir la sesión
por toda la aplicación para que cada pantalla vuelva a olvidarse de pasarlo.

**Lo que el `Tester` verifica de esto son los tres casos de la tabla**, tal como están escritos: con
provider registrado y sin `token` en la llamada, sale la cabecera con el token del provider; con
`token` explícito, sale ese y no el del provider; con `token: null` o sin provider registrado, no
sale ninguna cabecera. Es la precisión que le faltaba a la tarea 2 de `tasks.md`: "cuando hay token
registrado" sola era ambigua mientras el `token` explícito siguiera en juego.

**El 401 de estas cinco rutas sí pasa por el interceptor** (`announcesLostSession` por defecto): en
una pantalla interna, un 401 es exactamente una sesión que dejó de valer.

**`client.ts` tiene que dejar ver el status**, porque el alta distingue 201 de 200. La forma es
agregar una función y **no** cambiar la que ya existe:

```ts
export async function send<T>(path, options): Promise<{ status: number; data: T }>
export async function request<T>(path, options): Promise<T>   // = (await send<T>(...)).data
```

`request()` queda como el envoltorio de una línea, así que ningún llamado de `001` cambia de forma
—la única línea que se le toca a `001` es el `token: null` de `login()`, que es la declaración de
arriba y no un cambio de firma—, y `addFavorite()` es el único que usa `send()`. Al revés —hacer que `request()` devuelva el par— sería
tocar todos los call sites por un caso.

Y el `DELETE` responde 204: `send()` tiene que devolver `undefined` en vez de intentar parsear un
cuerpo que no existe. Un `await response.json()` sobre 204 tira, y tiraría en el camino feliz.

**El estado vive en `MyActions.tsx`**, y es poco:

```ts
favorites: FavoriteItem[] | null     // null = todavía cargando (TS-06)
selected: StockSuggestion | null     // RF-31: sin esto, `Agregar Símbolo` está deshabilitado
notice: 'already-there' | 'no-selection' | null   // RF-19 y RF-21, excluyentes por el tipo
confirming: FavoriteItem | null      // RF-25: la fila que está por quitarse
```

Los dos avisos son **excluyentes por construcción**: un solo campo que no puede tener dos valores a
la vez, que es lo que `COPY.md` pide y lo que un test puede verificar.

**Después de agregar y de quitar, la grilla se vuelve a pedir** (`RF-16`, `RF-26`). Un refetch y no
un parcheo del array local: el orden de la grilla es una decisión del backend (`RF-06`), y dos
lugares que ordenan es un lugar que se equivoca. Cuesta un request a **nuestra** API, que no gasta
cuota de nadie (Artículo II), y deja la pantalla mostrando lo que la base dice.

**El autocomplete** (`RF-08` a `RF-14`, `RF-31`):

- Debounce de 250 ms y mínimo dos caracteres antes de preguntar. El mínimo es `RF-13`; el debounce
  es cortesía con el servidor propio, no una defensa de cuota.
- **Cada búsqueda cancela la anterior** con `AbortController`. Sin eso, escribir rápido deja al
  desplegable mostrando la respuesta de un texto que ya no está en el campo — una carrera que
  aparece siempre y se reproduce sólo a veces.
- Elegir una sugerencia deja `selected` puesto y escribe el símbolo en el campo. **Volver a
  escribir lo limpia**: el botón se deshabilita de nuevo, porque lo que hay en el campo ya no es lo
  que se eligió.
- Sin coincidencias → el desplegable muestra `No se encontró ninguna acción con ese texto.` en
  lugar de las sugerencias.
- El campo es un `input` con su desplegable propio, no un `<select>`: el wireframe dibuja un campo
  de texto con una flecha y el placeholder `(Autocomplete)`, y un `select` no se puede tipear
  (`UI-01`).

**La confirmación de la baja es nuestra, no `window.confirm()`.** El navegador rotula sus botones
`Aceptar` y `Cancelar` y no deja cambiarlos; `COPY.md` pide `Eliminar` y `Cancelar` (`UI-02`). Es
un `<dialog>` nativo vestido con utilidades de Tailwind: modal de verdad, con foco atrapado y
`Escape` que cierra, sin una dependencia nueva.

**Los textos**, todos verbatim de `COPY.md` (`UI-02`): `Símbolo`, `(Autocomplete)`,
`Agregar Símbolo`, `Nombre`, `Moneda`, `Eliminar`, `Todavía no agregaste ninguna acción.`,
`No se encontró ninguna acción con ese texto.`, `Esa acción ya está en tu lista.`,
`Elegí una acción de las sugerencias.`, `¿Quitar {símbolo} de tus acciones?`, `Cancelar`. La cuarta
columna **no lleva encabezado**, tal como está dibujada (`UI-01`).

Los símbolos y la moneda van en mono tabular (`UI-04`), y ningún color literal: todo sale del
`@theme` de `tokens.css` (`UI-03`). El azul de enlace es sólo para lo que es enlace — el símbolo y
`Eliminar`.

## Alternativas descartadas

**Dejar la búsqueda sin índice.** Con 7.200 filas el escaneo secuencial se mide en milisegundos y
no habría hecho falta ninguna migración. Se descarta porque el índice de trigramas es la solución
correcta para `ILIKE '%texto%'` y el costo es acotado y de una sola vez: una extensión que el
Postgres oficial trae, dos índices declarados en el modelo, y una migración. Lo que se compra es
que el autocomplete no sea el cuello de botella del día que el catálogo crezca — que es
exactamente el caso que un evaluador pregunta.

**Cortar en 20 en el repositorio (un `LIMIT 20` en el `ILIKE`).** Es lo que este plan decía antes y
es un defecto, no una variante: el service ordenaría por relevancia un conjunto que ya perdió las
filas relevantes, y `RF-15` se caería de forma intermitente. La versión "prudente" de la misma idea
—un tope de candidatos chico, 100 o 500— es peor, porque falla sólo con los textos más comunes y el
síntoma no se reproduce. El corte vive en el service, después del orden.

**Restringir `q` con un patrón en el router, como se hace con el símbolo.** Cerraría el agujero de
los comodines de una línea y sin tocar el repositorio. Se descarta porque `q` es texto libre y el
símbolo es un identificador: una lista blanca sobre texto libre es una lista negra por omisión, y el
día que falte el apóstrofo de `Macy's` o el `&` de `AT&T` el autocomplete responde 422 a un nombre
que sí está en el catálogo. Además agrega una tercera forma de rechazar a las dos que este plan ya
aceptó (422 del router, `200 []` del service), y para un caso que no es un error: quien escribe `%`
merece `No se encontró ninguna acción con ese texto.`, no un rechazo del transporte.

**Escapar los comodines en el service, junto al `strip()`.** Es donde ya viven las decisiones sobre
el texto, así que parece el lugar. Se descarta por dos razones y la segunda es fatal: el escapado es
sintaxis de `ILIKE` y no una decisión sobre qué se busca —se vuelve incorrecto el día que la
consulta pase a `similarity()`, en el archivo que nadie tocó—, y sobre todo el service compararía la
relevancia contra `s\_p` en vez de `S_P`, de modo que "el nombre empieza con el texto" no saldría
nunca para ningún texto escapado. Filtro correcto y orden ciego, que es el bug del `upper()` dado
vuelta.

**Un 409 para el alta repetida.** Es lo que pide el instinto REST, y `TEST-04` lo prohíbe: agregar
dos veces el mismo símbolo "no duplica **ni falla**". Además obligaría al frontend a tratar un
error para un caso que no lo es.

**Un `created: bool` en el cuerpo, con 200 siempre.** Evitaba tocar `api/client.ts`, que hoy
devuelve el JSON parseado y esconde el status. Se descarta porque inventa en el cuerpo una
distinción que el protocolo ya tiene: 201 significa "se creó un recurso" y 200 "acá está", y un
campo que duplica eso es una segunda fuente de verdad. El costo —una función más en el cliente— se
paga una vez y deja el status disponible para las features que vengan.

**Copiar `name` y `currency` en `user_stocks`.** Haría la grilla de una sola consulta y sin cruzar
la frontera. Se descarta por dos razones: `ADR-001` ya decidió que no —la descripción del símbolo
es de `stocks` y la ingesta la mantiene al día, así que copiarla es garantizar que un día diverja—,
y el test del modelo de datos lo verifica explícitamente.

**Un `relationship()` de `UserStock` a `Stock`.** Resolvería la grilla con `favorite.stock.name` y
acopla `favorites` al modelo de `stocks` sin dejar un import que el test pueda ver. Está prohibido
por el Artículo IV y verificado por `test_no_relationship_crosses_a_module`.

**Un `GET /api/favorites` que devuelva sólo símbolos y un `GET /api/stocks?symbols=…` desde el
frontend.** Dos llamadas para pintar una grilla, y la composición cruzando la red en vez de pasar
por el service. La lectura cruzada del backend existe justamente para no hacer esto.

**Filtrar las delistadas adentro de `get_stocks`.** Simplificaría la firma y rompería la regla de
negocio: la favorita de alguien que dejó de cotizar tiene que seguir viéndose con su nombre y su
moneda. Por eso el filtro vive en la búsqueda y `StockInfo` lleva `is_listed`.

**`window.confirm()` para la baja.** Una línea, cero componentes, y rótulos que no se pueden
cambiar: `COPY.md` pide `Eliminar` y `Cancelar` (`UI-02`).

**Una biblioteca de autocomplete (Downshift, Headless UI, `cmdk`).** Traen accesibilidad hecha, y
también una dependencia, su superficie de API y su versión de React. Lo que hace falta acá es un
input, una lista y un estado de selección; `DEP-04` y el Artículo IX piden que una dependencia se
justifique, y esta no se justifica sola.

**Paginación o scroll infinito en las sugerencias.** El límite de 20 es un requisito (`RF-11`), no
una primera página.

## Riesgos

| Riesgo | Impacto | Cómo se mitiga |
|---|---|---|
| ✅ **Mitigado (2026-09-13) — la sesión de `001` no sobrevivía a una recarga.** **Cinco** criterios de aceptación de `002` dicen "se cierra sesión y se vuelve a entrar" (`RF-05`, `RF-17`, `RF-22`, `RF-24`, `RF-32`), y con la sesión en memoria no se podían verificar como están escritos | Era Alto: un F5 tiraba al login. **Hoy, ninguno**: la precondición está cumplida | El bloqueo —**"esta feature no arranca hasta que `001` termine H2"**, decisión del humano del 2026-09-13— lo **levantaron las tareas 10, 11 y 14 de `001`**, ya implementadas y verificadas en el repositorio: `GET /api/auth/me` en `auth/router.py`, `auth/storage.ts` con `sessionStorage`, `auth/session.ts` y `auth/SessionProvider.tsx` con la restauración, y `components/Header.tsx` con `Cerrar sesión`. **Lo que el bloqueo compró queda como regla permanente para los tests** y no se afloja porque la precondición se haya cumplido: la persistencia se verifica **en las dos puntas** —en backend, dos sesiones distintas del mismo usuario contra Postgres, que es donde vive de verdad; en frontend, un **F5 real** con la sesión restaurada desde `sessionStorage`—, y el remontaje simulado que este plan llegó a proponer como sucedáneo **no vuelve**: probaba el remontaje, no la persistencia. Sigue siendo una **precondición y no alcance de `002`**: esas tareas se escribieron en `001` y acá se dan por hechas, sin tocarlas |
| **Dos caminos para la misma cabecera**: el `token` explícito de `RequestOptions`, que `001` ya dejó andando y que usa `fetchMe`, y el provider de la sesión que entra acá | Medio: si se pisaran, la restauración podría salir sin cabecera —o una llamada que se hace sin sesión podría salir con una—, y las dos fallas son silenciosas | El riesgo con el que nació esta fila —*"el `Bearer` que `client.ts` todavía no manda"*— **ya no existe**: `client.ts` pone `Authorization: Bearer` cuando la llamada trae `token`, y `api/auth.ts` lo usa para la restauración. Lo que queda es la convivencia, y la cierra la **regla de precedencia de tres casos** de *Contratos → Frontend* (explícito gana · `token: null` no manda nunca · ausente usa el provider), que son tres tests de la tarea 2 y no una convención que alguien tenga que recordar. Lo que **sí** sigue pendiente es que las cinco rutas nuevas lleven el token de la sesión sin que la pantalla lo enhebre: eso es el provider, entra en esta feature, y es acá o no es —es la primera pantalla que consume un endpoint protegido— |
| **Carrera del autocomplete**: respuestas que llegan fuera de orden y pintan sugerencias de un texto viejo | Medio, y se reproduce sólo a veces | `AbortController` por búsqueda, y un test que lo fuerza resolviendo dos promesas al revés |
| Doble click en `Agregar Símbolo` | Bajo | La PK compuesta lo hace imposible en la base; el segundo request responde 200 en vez de 201 |
| El orden de la grilla cambia entre recargas si dos favoritas comparten `added_at` (el seed las inserta juntas) | Medio: rompe `RF-06` de manera intermitente, que es la peor forma | Desempate por `symbol ASC` en el `ORDER BY`, y un test que pide la lista dos veces y compara |
| **`alembic check` que nunca queda limpio** porque el `opclass` del índice GIN no se refleja igual que como se declaró | Medio: `DB-01` es Blocker y el CI corre `alembic check` | Se verifica al escribir la migración, no al final. Si no coincide, se ajusta la declaración; excluirlo de autogenerate es el último recurso y va con su motivo escrito |
| **`CREATE EXTENSION` sin privilegios** en un Postgres gestionado | Bajo hoy (compose y CI usan el dueño del cluster), alto el día que se despliegue a uno gestionado | `IF NOT EXISTS`, para que la migración no falle si el operador ya la creó; y queda dicho en el README de despliegue |
| El índice **no se usa** con dos caracteres, que es el mínimo de `RF-13` | Bajo: son ~7.200 filas y el escaneo es de milisegundos | Se asume y se escribe. Si alguna vez molesta, la palanca es subir el mínimo a 3, y eso vuelve a la spec porque `RF-13` lo fija |
| **El escapado de `%` y `_` se "simplifica"**: alguien lo sube al service porque ahí están las otras reglas del texto, lo baja a un `replace()` sin el `ESCAPE` declarado, o cambia el carácter de escape | Medio: subirlo al service rompe la clasificación por relevancia de cualquier texto escapado (`S_P` deja de clasificar por nombre) y cambiar el carácter deja al índice de trigramas leyendo un patrón distinto del que Postgres evalúa — pérdida silenciosa de filas, no error | Los tres casos tienen su test en la tarea 8: `q = "%a"` no devuelve el catálogo entero, `q = "a_c"` no matchea `abc`, y el texto que llega al repositorio es el del usuario y no uno escapado. El porqué de cada uno está escrito en `GET /api/stocks`, con el orden del escapado (`\` primero) y el motivo de la barra |
| La cuarta columna de la grilla "se arregla" con un encabezado | Bajo, pero es `UI-01` Blocker | El wireframe la dibuja sin encabezado; el test de estructura lo fija |
| Alguien "corrige" un texto de `COPY.md` al escribir el componente | Medio | `frontend/tests/copy.test.ts` suma las filas de esta pantalla y rompe el build |

## Contexto de traspaso

**Para el Developer** — **Empezá por la migración**, que es el primer escalón del orden de
`tasks.md` (migración → tests → backend → frontend) y de lo que dependen los tests de la búsqueda:
`CREATE EXTENSION IF NOT EXISTS pg_trgm`, los dos índices GIN, los mismos dos `Index(...)` al pie de
`stocks/models.py`, y `alembic check` limpio **antes** de seguir. Después el resto del backend, de
adentro hacia afuera. Primero `stocks`:
`repository.py` (la búsqueda, que trae candidatos sin ordenar, y el batch; ahí va **`_escape_like`,
privado del archivo**, y el `ilike(..., escape="\\")` — `\` primero, después `%` y `_`), `service.py`
(`MIN_QUERY_LENGTH`, `CANDIDATE_LIMIT` y `SUGGESTION_LIMIT`, el `strip()` de entrada con su guarda,
el orden por relevancia con `casefold()` y el corte **después** de ordenar, `StockInfo`), `io.py`,
`router.py` —que importa `MIN_QUERY_LENGTH` del service para su `Query(...)`, y por eso el service
va antes—, y último el `__all__`. Después `favorites`, igual:
`repository` → `service` → `io` → `router` → `__all__`. Recién ahí `main.py`: los dos
`include_router` y el handler de `UnknownSymbolError`. El frontend va último, cuando `make types`
ya puede generar el schema de las cinco rutas.

**El router recibe `session: SessionDep`**, el alias de `app/db.py`, y **nunca**
`Annotated[AsyncSession, Depends(get_session)]` escrito a mano: eso importa SQLAlchemy en el router
y `test_module_boundaries.py` lo rechaza en el acto (`PY-06`). La identidad entra por
`current_user: Annotated[CurrentUser, Depends(get_current_user)]`, importado de `app.security` y
nunca de `auth`.

Adentro de cada módulo, los archivos se importan **por ruta completa**
(`from app.modules.favorites.repository import add`), nunca por `app.modules.favorites`. Hacia
`stocks`, al revés: `from app.modules.stocks import get_stocks, StockInfo`, el paquete, nunca
`app.modules.stocks.service`.

Lo que **no** se toca: `favorites/models.py` (la tabla no cambia) ni ninguna columna de
`stocks/models.py` —de ahí sólo se tocan los dos `Index(...)` nuevos—, `app/providers/` (esta feature no sale al mundo), `app/security.py`, `app/ratelimit.py`,
`app/settings.py`, `seed.py`, y **lo que `001` ya entregó y esta feature consume sin modificar**
—`GET /api/auth/me` y su handler en `auth/router.py`, `auth/storage.ts`, `auth/session.ts`,
`auth/RequireSession.tsx` y `components/Header.tsx` con su `Cerrar sesión`—: eso es alcance que el
cliente firmó en otra spec, y "mejorarlo" desde acá es cambiar algo que ya se entregó.

De `001` esta feature toca **dos archivos, y por una razón cada uno, las dos escritas en
*Contratos → Frontend***: `auth/SessionProvider.tsx`, que registra de dónde sale el token igual que
ya registra el 401, y una línea de `api/auth.ts`, el `token: null` con el que `login()` declara que
se hace sin sesión. Nada más de `auth/` se toca.

Decisiones ya tomadas, que no hay que rediscutir: el autocomplete sale de la base y no del
proveedor (`A3`); el límite de 20 es una constante del service y no un parámetro del cliente; el
alta responde 201 si creó y 200 si ya estaba, nunca 409; la baja responde 204 siempre; el orden de la
grilla es `added_at DESC, symbol ASC` y lo decide el backend; `get_stocks` es en batch; la
confirmación de la baja es un `<dialog>` propio y no `window.confirm()`; los textos salen verbatim
de `COPY.md`.

Y `make types` se corre **después** de tener las cinco rutas montadas: si el schema se genera a
medias, el frontend tipa contra una API que ya cambió.

**Para el Tester** — Lo que puede romperse de verdad, en orden:

1. **El aislamiento por usuario, que es el Artículo III y el riesgo principal del proyecto.** Acá
   nace `backend/tests/integration/test_user_isolation.py`, la mitad de `GEN-09` que todavía no
   corría: dos usuarios reales, con favoritas distintas, y el token de uno que **no** alcanza nada
   del otro — ni leyendo (`RF-04`), ni agregando (`RF-22`), ni borrando (`RF-28`). El `DELETE` del
   símbolo que **sí** está en la lista del otro usuario es el test que importa: tiene que responder
   204 y dejar la fila ajena intacta.
2. **La idempotencia del alta** (`TEST-04`, `RF-18`): agregar dos veces el mismo símbolo deja una
   sola fila, el primero responde **201** y el segundo **200**, con el mismo cuerpo. Y el doble
   click concurrente —dos `POST` sin esperar al primero— tampoco duplica ni levanta. Un test más,
   que es el que se olvida: **el OpenAPI documenta las dos respuestas**, porque si no `schema.d.ts`
   tipa media y el frontend no puede distinguirlas.
3. **El orden de la grilla** (`RF-06`): pedir la lista dos veces seguidas devuelve exactamente el
   mismo orden, incluso con dos favoritas que comparten `added_at` (que es el caso del seed). La
   recién agregada va primera.
4. **La búsqueda**: por símbolo (`RF-08`), por nombre (`RF-09`), sin distinguir mayúsculas en las
   dos direcciones (`RF-10`), tope de 20 con un texto muy común (`RF-11`), una delistada que **no**
   aparece ni escribiendo su símbolo completo (`RF-12`), un texto de un carácter rechazado con 422
   (`RF-13`), y sin coincidencias `200 []`. Y el de relevancia, que **sólo prueba algo si el
   catálogo del test tiene más de veinte coincidencias de `micro`** y `MSFT` no está entre las
   primeras por símbolo: es el test que distingue "el service ordena" de "el repositorio ya había
   cortado", y con un catálogo chico pasa igual estando roto.

   **Y el texto, que es la otra mitad de esa tarea** (tarea 8): `q = "  "` —dos espacios, que pasan
   el `min_length` del router— responde **`200 []`** y **no consulta la base**, igual que `q = "a "`;
   `q = "a"` sigue siendo **422**, que es la asimetría escrita en `GET /api/stocks` y que el test
   fija a propósito para que nadie la "arregle". El `strip()` también tiene su cara positiva:
   `q = " micro "` devuelve lo mismo que `q = "micro"`. Que no se consulte la base es parte del
   test, no un detalle: se verifica en el unitario del service con un repositorio espiado, porque
   un test de integración vería la lista vacía igual aunque el `ILIKE '%%'` se hubiera ejecutado.

   **Y los comodines del `LIKE`, en esa misma tarea 8.** Son tests de integración contra un
   catálogo real, porque lo que se verifica es el SQL: `q = "%a"` **no** devuelve las acciones que
   contienen una `a` —devuelve `200 []`, porque el catálogo no tiene ningún símbolo ni nombre con
   `%` adentro—, y `q = "a_c"` **no** matchea `abc`. Los dos fallan hoy sin el escapado y los dos
   pasan con él, que es lo que los hace tests y no decoración. Van con dos más: uno que fija que el
   escapado **no vive en el service** —el unitario con repositorio espiado verifica que a
   `search_listed` le llegue `"%a"` tal cual, sin barra, porque un escapado que suba de capa rompe
   la clasificación por relevancia—, y uno que fija que **el texto normal no cambió**: `q = "micro"`
   devuelve exactamente lo mismo que antes, que es el caso que ocurre siempre. Si el catálogo del
   test se siembra con un nombre que contenga un `_`, el test que corresponde es que buscarlo por su
   texto literal **lo encuentra**: escapar es que el `_` se busque, no que se ignore.

   El unitario del orden por relevancia suma la comparación sin caja **en los dos campos**: `msft`
   en minúsculas clasifica como símbolo exacto, y `micro` en minúsculas clasifica `Microsoft Corp`
   como "el nombre empieza con el texto" —que es el caso que se cae si alguien compara el nombre
   contra el texto en mayúsculas—. Es el test que distingue una regla de comparación de dos.
5. **El alta de lo que no se ofrece**: un símbolo que no está en el catálogo y uno delistado, los
   dos 404, y ninguno de los dos deja fila.
6. **La favorita delistada sigue en la grilla**, con su nombre y su moneda: es la contracara del
   punto 4 y es donde `is_listed` se gana el lugar.
7. **`TestRoutesDeclareAuthorization`** ahora tiene cinco rutas nuevas que cubrir, y
   **`PUBLIC_ROUTES` no suma ninguna**. Si alguna ruta nueva pasa sin declarar autorización, ese
   test tiene que ponerse rojo.
8. **Frontend**: el botón deshabilitado sin selección (`RF-31`) y el aviso cuando el alta se
   dispara igual por Enter (`RF-21`); los dos avisos que nunca conviven (`RF-19` vs `RF-21`); la
   grilla vacía con los encabezados a la vista (`RF-07`); la cuarta columna sin encabezado
   (`RF-02`); la confirmación con el símbolo adentro del texto (`RF-25`) y `Cancelar` que deja la
   fila donde estaba (`RF-32`); la fila que aparece y desaparece sin recargar (`RF-16`, `RF-26`); y
   el enlace del símbolo que lleva a `/stocks/AAPL` y no al de otra fila (`RF-30`).
9. **La carrera del autocomplete**: dos búsquedas en vuelo, la primera resolviendo después de la
   segunda, y el desplegable mostrando la segunda.
10. **La migración**: `alembic upgrade head` y `alembic downgrade` corren las dos contra una base
    limpia, los dos índices existen después del upgrade y no después del downgrade, la extensión
    sobrevive al downgrade, y **`alembic check` queda limpio** — que es lo que verifica que el
    modelo y la tabla no se separaron (`DB-01`). Correrla dos veces seguidas no falla, que es lo
    que compra el `IF NOT EXISTS`.
11. **`api/client.ts`**: `request()` sigue devolviendo el JSON pelado y ningún llamado de `001`
    cambió de forma; `send()` devuelve el status; y un 204 no revienta al intentar parsear un
    cuerpo que no existe. Y **la regla del `Bearer`, que son tres casos y no uno**: con provider
    registrado y sin `token` en la llamada sale la cabecera con el token del provider; con `token`
    explícito sale ese y **no** el del provider (es el caso de `fetchMe` durante la restauración);
    con `token: null` —el `login()`— o sin provider registrado no sale ninguna cabecera. Los tres,
    porque el `token` explícito de `001` sigue en juego y "manda el `Bearer` cuando hay token
    registrado" sería, solo, ambiguo.

**`frontend/tests/copy.test.ts` suma las filas de esta pantalla** a su lista `REQUIRED`: las
cinco de la tabla `Mis Acciones` que faltan —`Etiqueta del autocomplete`, `Placeholder del
autocomplete`, `Botón`, `Columnas de la grilla`, `Link de baja`— y las de *Lista de favoritas*. Es
el test que rompe el build si alguien "corrige" un texto (`UI-02`).

Dos de esas filas no entran como están y hay que resolverlo al escribir el test, no después:

- **`Columnas de la grilla`** lleva tres literales en una celda (`` `Símbolo` · `Nombre` ·
  `Moneda` ``) y el parser actual se queda con el primero. O el test cubre las tres, o `Nombre` y
  `Moneda` quedan sin verificar.
- **`Confirmación de baja`** es una plantilla (`¿Quitar {símbolo} de tus acciones?`): ese string
  literal no va a aparecer en `src/`, porque el símbolo se interpola. Se verifica contra la parte
  fija, o contra el texto ya armado en el render, nunca pidiendo la plantilla entera en el fuente.

**Nada de esto sale a la red** (`TEST-03`): no hay proveedor en el camino, así que esta feature no
agrega JSON fijado. Lo que sí necesita es base: los tests de integración usan la fixture `session`
de `tests/conftest.py`, que trunca las cuatro tablas y hace rollback, y **los datos los arma el
test**, no el seed — `tests/factories/` ya tiene `user_factory.py` y le falta el hermano para
`stocks` y `user_stocks`.

Y el detalle de `001` que gobierna los tests de frontend, que **no cambió porque `001` haya
terminado**: **"salir y volver a entrar" se prueba con un F5 real**, nunca remontando la aplicación
con una sesión nueva, que probaría el remontaje y no la persistencia. Son los cinco criterios que lo
piden —`RF-05`, `RF-17`, `RF-22`, `RF-24` y `RF-32`—, y hoy **se pueden probar así**: `001` está
entregada, y con `auth/storage.ts`, la sesión restaurada contra `GET /api/auth/me` y
`components/Header.tsx` —sus tareas 10, 11 y 14— una recarga ya no tira al login. En backend, la
otra punta del mismo criterio: dos sesiones distintas del mismo usuario contra Postgres, que es
donde la lista vive de verdad. Fue una **precondición y no alcance de `002`**: esas tareas se
escribieron en su feature, y los tests de acá las dan por hechas **sin volver a escribirlas**.

**Para el Code-Reviewer** — Dónde mirar primero:

- **`app/modules/favorites/repository.py`**: las tres funciones reciben `user_id` como primer
  argumento y **toda** query lo lleva en el `WHERE`. Una sola query sin ese filtro es API1:2023 y
  Blocker (`GEN-09`, Artículo III). Y ninguna ruta acepta un id de usuario por path, query o body.
- **Los dos `__init__.py`**: docstring, imports y un `__all__` literal. `stocks` exporta
  exactamente `StockInfo`, `get_stocks`, `keep_the_catalogue_fresh` y `router`; `favorites`,
  exactamente `router`. Nada más, y nada que sea un modelo de SQLAlchemy (`GEN-02`).
- **`favorites/service.py`**: entra a `stocks` por el paquete y **en batch**. Un `get_stocks` por
  fila adentro de un `for` es N+1 y es lo que la frontera existe para evitar; un
  `from app.modules.stocks.service import ...` es interior ajeno y lo caza el test.
- **Las capas** (`PY-06`): ningún `select()` en un `router.py`, ningún `fastapi` en un
  `service.py`, ningún `HTTPException` fuera de `app/security.py`. El grep de `ERR-04` es
  `grep -rn "HTTPException" app/modules | grep -v "/router"`.
- **`main.py`**: los dos routers montados explícitamente (`GEN-04`) y el handler de
  `UnknownSymbolError` registrado. El composition root sigue siendo el único archivo que conoce
  todos los módulos.
- **La migración y `stocks/models.py`**: los dos índices están declarados en los dos lados —modelo
  y revisión—, `alembic check` queda limpio, el `downgrade()` borra los índices y **no** la
  extensión, y la revisión no trae nada más que eso (`DB-01`, `DB-04`).
- **El router del alta**: `status_code=201` declarado y el 200 puesto sobre el `Response` cuando ya
  estaba, con `responses={200: ...}` para que el OpenAPI documente las dos. Y que el que decide sea
  el `created` del service: un service que hable de códigos HTTP es `PY-06` roto.
- **`stocks/service.py`**: el orden por relevancia y el corte en `SUGGESTION_LIMIT` están **después**
  de traer los candidatos, y ningún `limit=20` viaja a `search_listed` — si el repositorio corta en
  20, `RF-15` está roto aunque los tests de la búsqueda simple pasen. Y el texto: **un solo
  `strip()` al entrar**, la guarda de `MIN_QUERY_LENGTH` **antes** de llamar al repositorio, la
  clasificación con `casefold()` en las dos puntas de las tres comparaciones, y ningún `upper()`
  sobre lo que viaja al `ILIKE`. Un `casefold()` que aparezca de un solo lado de una comparación es
  el bug del nombre que nunca clasifica. **Y que el service no escape nada**: el escapado que
  aparezca ahí es el mismo bug con otra cara.
- **`stocks/repository.py`**: la búsqueda escapa `\`, `%` y `_` **en ese orden** y declara
  `escape="\\"`. Tres formas de estar mal: sin escapar (el usuario escribe el operador), escapando
  `%` antes que `\` (el patrón busca barras que nadie tipeó), o con un carácter de escape que no sea
  la barra (el índice de trigramas lee un patrón distinto del que Postgres evalúa y pierde filas en
  silencio). El grep es `grep -n "ilike" app/modules/stocks/repository.py`: si no tiene `escape=`,
  está mal.
- **Los nombres** (`PY-10`): `SUGGESTION_LIMIT` y `CANDIDATE_LIMIT` en mayúsculas por ser
  constantes de módulo, guión
  bajo adelante para lo privado del archivo, `PascalCase` para `StockInfo`, `FavoriteStock` y
  `FavoriteAddition`.
- **Frontend**: ningún color literal (`UI-03`), ningún `style={{ }}` ni `.css` nuevo (`UI-07`),
  ninguna clase de Tailwind armada por interpolación, los textos verbatim de `COPY.md` (`UI-02`),
  la cuarta columna sin encabezado y el orden de los controles del wireframe (`UI-01`), y
  `schema.d.ts` regenerado y no editado a mano (`TS-03`).
- **Y lo que no tiene que estar**: paginación, orden por columna, cotización en la grilla, edición
  de una fila, límite de favoritas, o un endpoint para administrar el catálogo. Todo eso está en
  *Fuera de alcance* de la spec, y `/converge` lo va a mirar.
