# Mis Acciones favoritas — Tareas

<!--
  ARTEFACTO INTERNO. Cada tarea mapea a una skill de agents/skills/ y es lo bastante
  chica como para terminarse de una sentada. Si una tarea no tiene skill, o no
  corresponde al proyecto, o falta la skill: preguntá antes de inventarla.
-->

**Feature:** `002-favorite-stocks` · **Plan:** `plan.md`

**Tests aprobados por:** — · **Fecha de aprobación:** —

| Historia | Tests | Firma | Fecha |
|---|---|---|---|
| H1 — Ver mis acciones | tareas 1 y 2 | — *(sin escribir)* | — |
| H2 — Agregar una acción a mi lista | tareas 8 y 9 | — *(sin escribir)* | — |
| H3 — Sacar una acción de mi lista | tareas 14 y 15 | — *(sin escribir)* | — |
| H4 — Llegar al detalle de una acción | tarea 19 | — *(sin escribir)* | — |

<!--
  Lo completa `/approve-tests`, nunca un agente por su cuenta (Artículo VI). Mientras diga "—",
  `/implement` no arranca: los tests de la historia todavía no son un contrato firmado.
-->

> **Hay cuatro firmas, una por historia.** El gate del Artículo VI no es único al final: los tests
> de H1 se firman antes de implementar H1. Por eso `approve_tests` aparece cuatro veces, y por eso
> cada firma se anota con quién y cuándo en el encabezado de arriba.
>
> **Un test firmado no se reescribe para que pase.** Si durante `/implement` alguno resulta
> equivocado, se corrige y **se vuelve a firmar** — no se ajusta al código que se acaba de escribir.

> **La migración es de H2, no de H1, y el plan no dice otra cosa.** *(Confirmado por el humano,
> 2026-09-13.)* El orden de este archivo es *migración → tests → backend → frontend* **dentro de
> cada historia**. H1 no cambia el esquema: `stocks` y `user_stocks` existen desde la fase 0
> (`394dab64d255`) y la grilla se pinta con las columnas que ya tienen. Lo que la migración trae
> —`pg_trgm` y los dos índices GIN— sólo lo necesita la búsqueda del autocomplete, así que es la
> tarea **7**, el primer escalón de H2. El *Contexto de traspaso* del plan («empezá por la
> migración») sigue siendo cierto ahí: es lo primero de la historia que la necesita, y de lo que
> dependen sus tests.

> **`make types` se corre en las tareas 6, 13 y 18**, una vez por historia que agrega rutas.
> *(Confirmado por el humano, 2026-09-13.)* No contradice al plan: lo que el plan prohíbe es generar
> el schema **a medias y no volver a generarlo**. Cada historia monta sus rutas primero y regenera
> después, así que `schema.d.ts` nunca tipa contra una API que ya cambió. Se regenera con
> `make types` y **no se edita a mano** (`TS-03`).

> ✅ **Precondición cumplida: `001` ya terminó H2, y esta feature arranca.** Verificado el
> 2026-09-13. El bloqueo existía porque **son cinco** los criterios de aceptación que dicen "se
> cierra sesión y se vuelve a entrar" —`RF-05`, `RF-17`, `RF-22`, `RF-24` y `RF-32`— y ninguno se
> podía verificar en pantalla mientras la sesión de `001` viviera en memoria y un F5 tirara al
> login. Lo que lo levanta son las **tareas 10, 11 y 14 de `001-authentication`**, las tres en ✅:
> `GET /api/auth/me`, `auth/storage.ts` con `sessionStorage`, la restauración de la sesión y
> `components/Header.tsx` con `Cerrar sesión`. Ya se pueden escribir los tests de `002`.
>
> **Lo que el bloqueo compró sigue siendo regla, y es lo importante de esta nota:** esos cinco
> criterios se verifican **en las dos puntas** —en backend, dos sesiones distintas del mismo
> usuario contra Postgres; en frontend, un **F5 real** con la sesión restaurada desde
> `sessionStorage`, y el F5 vale para los cinco—. **Nunca** un remontaje simulado de la
> aplicación: eso probaría el remontaje, no la persistencia. Gobierna las tareas **2, 9 y 15**, y
> `plan.md` lo dice igual (→ *Riesgos*, primera fila, y *Contexto de traspaso* → *Para el Tester*).
>
> **Lo que no cambia:** `001` fue una **precondición**, no alcance de `002`. Ninguna de las 22
> tareas de acá reescribe `001`: lo que entra son **tres puntos de extensión**, todos en la tarea 6
> y todos justificados en `plan.md` (→ *Contratos* → *Frontend*) —`api/client.ts`, que suma el
> provider del token y la regla de precedencia; `auth/SessionProvider.tsx`, que lo registra en el
> mismo efecto donde ya registra el interceptor del 401; y **una línea** de `api/auth.ts`, el
> `token: null` de `login()`—. Entran acá porque ésta es la primera pantalla que consume un
> endpoint protegido.

## Orden

<!-- Las tareas se agrupan por historia de usuario, en orden de prioridad, para que al terminar H1 haya algo entregable de verdad. -->

### H1 — Ver mis acciones *(prioridad más alta)*

Al terminar H1 el cliente ingresa con un usuario de prueba y ve en `Mis Acciones` la grilla del
wireframe con sus acciones —símbolo, nombre y moneda—, y con otro usuario ve otra lista. Es
entregable de verdad: la pantalla que hasta hoy era sólo un título.

| # | Tarea | Skill | Rol | Cubre |
|---|-------|-------|-----|-------|
| 1 | **Tests de backend de H1, en rojo.** Integración de `GET /api/favorites`: la lista del usuario del token (`RF-01`, `RF-03`), el orden `added_at DESC, symbol ASC` pedido **dos veces seguidas** con dos favoritas que comparten `added_at` (`RF-06`), sin favoritas `200 []` (`RF-07`), la persistencia entre dos sesiones distintas del mismo usuario (`RF-05`), y la favorita delistada que **sigue** en la grilla con su nombre y su moneda. Acá nace `test_user_isolation.py`: dos usuarios reales y el token de uno que no ve nada del otro (`RF-04`, Artículo III). Unitarios de `stocks`: `get_stocks` en batch devuelve `StockInfo` —nunca el modelo— con `is_listed`, y de `favorites`: `list_favorites` respeta el orden que le dio el repositorio. Suma a `tests/factories/` el hermano de `user_factory.py` para `stocks` y `user_stocks`. Ninguna ruta nueva entra a `PUBLIC_ROUTES`. | `add_tests` | Tester | RF-01, RF-03, RF-04, RF-05, RF-06, RF-07 |
| 2 | **Tests de frontend de H1, en rojo.** La grilla contra `wireframes/02-mis-acciones.png`: cuatro columnas, tres con encabezado y **la cuarta sin ninguno** (`RF-02`), y una fila por favorita con su símbolo, su nombre y su moneda (`RF-03`). El estado vacío con los encabezados a la vista y `Todavía no agregaste ninguna acción.` en lugar de las filas (`RF-07`). `frontend/tests/copy.test.ts` suma las filas de `Mis Acciones` que faltan —`Columnas de la grilla`, con sus **tres** literales en una celda, y `Lista vacía`—. Y `client.ts`, los **tres casos** de la precedencia del token, uno por test: con provider registrado y **sin** `token` en la llamada sale `Authorization: Bearer` con el token del provider; con `token` explícito sale **ése** y no el del provider; y con `token: null` —o sin provider registrado, o con uno que devuelve `null`— **no sale ninguna cabecera**. Ningún llamado de `001` cambia de comportamiento: `fetchMe(token)` sigue mandando su cabecera igual. **El F5**: con la sesión restaurada desde `sessionStorage` —disponible desde H2 de `001`—, recargar `Mis Acciones` vuelve a mostrar las mismas acciones, y no el login (`RF-05`). | `add_tests` | Tester | RF-01, RF-02, RF-03, RF-05, RF-07 |
| 3 | 🚦 **Firma de los tests de H1.** Sin esto, la tarea 4 no arranca (Artículo VI). | `approve_tests` | Tester *(firma el humano)* | — |
| 4 | **`stocks` empieza a responder: la lectura en batch.** `repository.py` → `find_many(session, symbols)`; `service.py` → `get_stocks(session, symbols) -> list[StockInfo]`, la dataclass frozen con sus cuatro campos (`symbol`, `name`, `currency`, `is_listed`) y la conversión que deja el modelo adentro del módulo; y el `__all__` suma `StockInfo` y `get_stocks` a `keep_the_catalogue_fresh`. | `add_backend_feature` | Developer | RF-01, RF-03 |
| 5 | **Nace `favorites`: la grilla.** `repository.py` → `symbols_of(session, user_id)` con `ORDER BY added_at DESC, symbol ASC` y el `user_id` como primer argumento; `service.py` → `list_favorites`, que pide los símbolos y las descripciones **al paquete `stocks` en una sola llamada** y las reordena; `io.py` → `FavoriteItem`; `router.py` → `GET /api/favorites` protegida, con `SessionDep` y `get_current_user` de `app.security`; `__all__ = ["router"]`; y en `main.py` el `include_router`. | `add_backend_feature` | Developer | RF-01, RF-03, RF-04, RF-05, RF-06 |
| 6 | **La pantalla: grilla y token.** `make types`; `api/client.ts` con `setAuthTokenProvider(() => string \| null)`, el campo que pasa de `token?: string` a `token?: string \| null` y la **precedencia**: lo explícito gana, `token: null` calla la cabecera, y ausente la pide al provider; `auth/SessionProvider.tsx` registrando de dónde sale el token, en el mismo efecto donde ya registra el interceptor del 401; **una línea en `api/auth.ts`**: `login()` declara `token: null`, al lado del `announcesLostSession: false` que ya declara; `api/favorites.ts` → `listFavorites()`; `components/StockGrid.tsx` con las cuatro columnas, la cuarta sin encabezado, y el estado vacío; y `pages/MyActions.tsx` pidiendo la lista al montar, con `favorites: FavoriteItem[] \| null`. | `add_frontend_feature` | Developer | RF-01, RF-02, RF-03, RF-05, RF-07 |

### H2 — Agregar una acción a mi lista

| # | Tarea | Skill | Rol | Cubre |
|---|-------|-------|-----|-------|
| 7 | **La migración del autocomplete.** `CREATE EXTENSION IF NOT EXISTS pg_trgm` y los dos índices GIN (`ix_stocks_symbol_trgm`, `ix_stocks_name_trgm`, con `gin_trgm_ops`), los mismos dos `Index(...)` al pie de `stocks/models.py`, y `downgrade()` que borra los índices y **deja** la extensión. `alembic check` tiene que quedar limpio **antes** de seguir: si el `opclass` reflejado no coincide, se ajusta la declaración, y excluirlo de autogenerate es el último recurso y va con su motivo escrito (`DB-01`, `DB-03`). | `add_database_migration` | Developer | — *(ver nota)* |
| 8 | **Tests de backend de H2, en rojo.** Integración de `GET /api/stocks`: por símbolo (`RF-08`), por nombre (`RF-09`), sin distinguir mayúsculas en las dos direcciones (`RF-10`), tope de 20 con un texto muy común (`RF-11`), una delistada que **no** aparece ni con su símbolo completo (`RF-12`), un carácter → 422 (`RF-13`), sin coincidencias `200 []`, y el de relevancia: `micro` trae `MSFT` entre las veinte. Unitario del orden por relevancia y de `SUGGESTION_LIMIT`. Integración de `POST /api/favorites`: **201** cuando crea, **200** cuando ya estaba, mismo cuerpo y una sola fila (`RF-18`, `TEST-04`), el doble `POST` concurrente que tampoco duplica, el símbolo desconocido y el delistado los dos **404** sin dejar fila, el nombre y la moneda que se leen del catálogo (`RF-17`), y que el **OpenAPI documente las dos respuestas**. En `test_user_isolation.py`, el alta de un usuario que no toca las favoritas del otro (`RF-22`). Y la migración: `upgrade` y `downgrade` contra una base limpia, los índices que existen después del primero y no del segundo, la extensión que sobrevive, correrla dos veces sin fallar, y `alembic check` limpio. | `add_tests` | Tester | RF-08…RF-13, RF-15, RF-17, RF-18, RF-22 |
| 9 | **Tests de frontend de H2, en rojo.** El autocomplete: con un carácter no pregunta ni despliega, con dos sí (`RF-13`); sin coincidencias muestra `No se encontró ninguna acción con ese texto.` en lugar de las sugerencias (`RF-14`); **la carrera**, con dos búsquedas en vuelo y la primera resolviendo después de la segunda, dejando en pantalla la segunda; y que volver a escribir limpia la selección. `Agregar Símbolo` deshabilitado mientras no haya sugerencia elegida (`RF-31`), la fila que aparece **sin recargar**: elegir la sugerencia y apretar `Agregar Símbolo` deja ese símbolo en la grilla (`RF-15`, `RF-16`), y los dos avisos que nunca conviven: `Esa acción ya está en tu lista.` (`RF-19`) y `Elegí una acción de las sugerencias.` cuando el alta se dispara igual por Enter, sin agregar nada (`RF-20`, `RF-21`). `copy.test.ts` suma `Etiqueta del autocomplete`, `Placeholder del autocomplete`, `Botón`, `Búsqueda sin resultados`, `Acción repetida` y `Alta sin selección`. Que la acción recién agregada **sobreviva al F5** con su nombre y su moneda, no sólo con su símbolo (`RF-17`). Y `client.ts`: `send()` devuelve el status, y `request()` sigue devolviendo el JSON pelado sin que ningún llamado de `001` cambie de forma. | `add_tests` | Tester | RF-13, RF-14, RF-15, RF-16, RF-17, RF-19, RF-20, RF-21, RF-31 |
| 10 | 🚦 **Firma de los tests de H2.** | `approve_tests` | Tester *(firma el humano)* | — |
| 11 | **La búsqueda del catálogo.** `stocks/repository.py` → `search_listed(session, text, limit)` con `ILIKE '%texto%'` sobre símbolo y nombre y `WHERE delisted_at IS NULL`; `service.py` → `search_stocks`, la constante `SUGGESTION_LIMIT = 20` y el orden por relevancia (símbolo exacto → símbolo que empieza → nombre que empieza → el resto, y `symbol ASC` adentro de cada grupo); `io.py` → `StockSuggestion` de **tres** campos; `router.py` → `GET /api/stocks` protegida con `q: str = Query(min_length=2, max_length=50)`; el `__all__` suma `router`; y el `include_router` en `main.py`. | `add_backend_feature` | Developer | RF-08, RF-09, RF-10, RF-11, RF-12, RF-13 |
| 12 | **El alta, idempotente.** `app/errors.py` → `UnknownSymbolError`, hija de `DomainError`; `favorites/repository.py` → `add(session, user_id, symbol) -> bool` con `ON CONFLICT DO NOTHING`; `service.py` → `add_favorite`, que normaliza a mayúsculas, **mira el catálogo antes de escribir** y devuelve `FavoriteAddition(created, favorite)`; `io.py` → el body con `extra="forbid"`, `max_length=12` y el patrón del símbolo; `router.py` → `POST /api/favorites` con `status_code=201`, el 200 sobre el `Response` cuando ya estaba y `responses={200: {"model": FavoriteItem}}`; y en `main.py` el handler de `UnknownSymbolError` → 404. | `add_backend_feature` | Developer | RF-15, RF-17, RF-18, RF-22 |
| 13 | **El campo `Símbolo` y su alta.** `make types`; `api/client.ts` → `send()` con el status a la vista y `request()` como su envoltorio de una línea; `api/stocks.ts` → `searchStocks(q)`; `api/favorites.ts` → `addFavorite(symbol)`; `components/Autocomplete.tsx` con debounce de 250 ms, mínimo dos caracteres, `AbortController` por búsqueda y el desplegable sin resultados; y en `pages/MyActions.tsx` el `SymbolPicker`: `selected`, el botón deshabilitado, `notice: 'already-there' \| 'no-selection' \| null` y el refetch de la grilla después de agregar. | `add_frontend_feature` | Developer | RF-13, RF-14, RF-15, RF-16, RF-17, RF-19, RF-20, RF-21, RF-31 |

### H3 — Sacar una acción de mi lista

| # | Tarea | Skill | Rol | Cubre |
|---|-------|-------|-----|-------|
| 14 | **Tests de backend de H3, en rojo.** `DELETE /api/favorites/{symbol}`: **204 siempre**, también cuando esa acción no estaba en la lista, y dos bajas seguidas del mismo símbolo que responden lo mismo (`RF-24`). **La baja persiste**: en una segunda sesión distinta del mismo usuario —la punta de backend del F5 que `RF-24` pide en pantalla— la acción quitada sigue sin estar. El símbolo que se quita **sigue en el catálogo** y la siguiente búsqueda lo vuelve a sugerir (`RF-27`). Y en `test_user_isolation.py` el test que importa: el `DELETE` del símbolo que **sí** está en la lista del otro usuario responde 204 y deja la fila ajena intacta (`RF-28`). | `add_tests` | Tester | RF-24, RF-27, RF-28 |
| 15 | **Tests de frontend de H3, en rojo.** El enlace `Eliminar` en cada fila (`RF-23`); al activarlo, la confirmación con el símbolo adentro del texto —`¿Quitar NFLX de tus acciones?`— y la fila todavía en la grilla hasta confirmar (`RF-25`); confirmar la saca **sin recargar** (`RF-26`); `Cancelar` la deja donde estaba (`RF-32`). **El F5**, con la sesión restaurada desde `sessionStorage` —disponible desde H2 de `001`—: la fila que se quitó sigue sin estar después de recargar (`RF-24`) y la que se canceló sigue estando (`RF-32`). `copy.test.ts` suma `Link de baja` y `Confirmación de baja` —que es una plantilla: se verifica contra la parte fija o contra el texto ya armado en el render, nunca pidiendo la plantilla entera en el fuente—. Y que un 204 no reviente `send()` al intentar parsear un cuerpo que no existe. | `add_tests` | Tester | RF-23, RF-24, RF-25, RF-26, RF-32 |
| 16 | 🚦 **Firma de los tests de H3.** | `approve_tests` | Tester *(firma el humano)* | — |
| 17 | **La baja.** `favorites/repository.py` → `remove(session, user_id, symbol)`, con el `user_id` en el `WHERE`; `service.py` → `remove_favorite`, con la misma normalización que el alta y **sin falla**; `router.py` → `DELETE /api/favorites/{symbol}` protegida, 204 siempre, con el símbolo validado por el mismo patrón que el alta. | `add_backend_feature` | Developer | RF-24, RF-27, RF-28 |
| 18 | **La confirmación.** `make types`; `api/client.ts` aprende `DELETE` y devuelve `undefined` en un 204; `api/favorites.ts` → `removeFavorite(symbol)`; `components/ConfirmDialog.tsx`, un `<dialog>` nativo con utilidades de Tailwind —foco atrapado, `Escape` que cierra— y los botones `Eliminar` y `Cancelar`, **nunca `window.confirm()`**; el enlace `Eliminar` en la cuarta columna de `StockGrid.tsx`; y en `MyActions.tsx` el estado `confirming` y el refetch después de quitar. | `add_frontend_feature` | Developer | RF-23, RF-25, RF-26, RF-32 |

### H4 — Llegar al detalle de una acción

| # | Tarea | Skill | Rol | Cubre |
|---|-------|-------|-----|-------|
| 19 | **Tests de frontend de H4, en rojo.** El símbolo de cada fila se comporta como un enlace, no como texto suelto (`RF-29`); activar `AAPL` lleva a `/stocks/AAPL` y no al detalle de otra fila de la lista (`RF-30`); y `/stocks/:symbol` abierta sin sesión cae en `/login`, como `/`. | `add_tests` | Tester | RF-29, RF-30 |
| 20 | 🚦 **Firma de los tests de H4.** | `approve_tests` | Tester *(firma el humano)* | — |
| 21 | **La salida al detalle.** El símbolo como enlace a `/stocks/:symbol` en mayúsculas en `StockGrid.tsx`; `pages/ActionDetail.tsx`, **cascarón**, que renderiza el símbolo que viene de la URL y ningún texto nuevo; y la ruta en `App.tsx`, protegida por `RequireSession`. | `add_frontend_feature` | Developer | RF-29, RF-30 |

### Cierre de la feature

| # | Tarea | Skill | Rol | Cubre |
|---|-------|-------|-----|-------|
| 22 | **`ARCHITECTURE.md` al día.** La firma real de `get_stocks` —`get_stocks(session, symbols)`, con la sesión adelante, como el plan anticipa—, el `__all__` de `stocks` (`StockInfo`, `get_stocks`, `keep_the_catalogue_fresh`, `router`) y el de `favorites` (`router`), los `router.py` e `io.py` nuevos de `stocks`, y en el árbol del frontend los tres componentes y los dos módulos de `api/`. | `add_backend_feature` | Backend-Arch · Frontend-Arch | — *(ver nota)* |

<!--
  La columna Test de la tabla de trazabilidad de docs/PROJECT_BRIEF.md (REQ-05…REQ-11, NFR-03) NO
  es una tarea de acá: la completa `ship_changes` en el mismo commit que archiva la spec, que es
  lo que evita que la tabla quede vieja (docs/specs/README.md → Al entregar).
-->

### Las dos tareas que no cubren ningún `RF`, y por qué no es alcance de más

- **La 7 es rendimiento, no funcionalidad.** La búsqueda de `RF-08`…`RF-12` anda sin los índices:
  son ~7.200 filas y el escaneo secuencial se mide en milisegundos. `pg_trgm` es lo único que puede
  indexar un `ILIKE '%texto%'`, y entra ahora porque una extensión y dos índices son más baratos de
  agregar con la tabla chica que el día que moleste. El plan lo declara en *Alternativas
  descartadas*; nada de lo que el usuario ve cambia por esta tarea.
- **La 22 es documentación.** `ARCHITECTURE.md` describe hoy un `stocks` que no responde y una
  firma de `get_stocks` sin sesión; si no se corrige, el próximo que lea la arquitectura la va a
  leer mal.

**Si alguna de estas dos terminara cambiando una pantalla o un mensaje, deja de ser mecanismo y
vuelve a la spec.**

## Cobertura de requisitos

<!--
  Todo requisito funcional de la spec tiene al menos una tarea que lo construye y
  al menos un test que lo verifica. Un RF sin fila acá es alcance firmado que nadie
  se comprometió a hacer — y es exactamente lo que /converge va a encontrar.
-->

Los nombres de archivo de la columna **Test** son la propuesta de este desglose; el `Tester` puede
reagruparlos, pero **ninguna fila puede quedar vacía**.

| Requisito | Tareas | Test |
|-----------|--------|------|
| RF-01 | 1, 2, 4, 5, 6 | `backend/tests/integration/test_favorites.py` · `frontend/tests/MyActions.test.tsx` |
| RF-02 | 2, 6 | `frontend/tests/StockGrid.test.tsx` |
| RF-03 | 1, 2, 4, 5, 6 | `backend/tests/integration/test_favorites.py` · `frontend/tests/StockGrid.test.tsx` |
| RF-04 | 1, 5 | `backend/tests/integration/test_user_isolation.py` |
| RF-05 | 1, 2, 5, 6 | `backend/tests/integration/test_favorites.py` · `frontend/tests/MyActions.test.tsx` |
| RF-06 | 1, 5 | `backend/tests/integration/test_favorites.py` |
| RF-07 | 1, 2, 6 | `backend/tests/integration/test_favorites.py` · `frontend/tests/StockGrid.test.tsx` · `frontend/tests/copy.test.ts` |
| RF-08 | 8, 11 | `backend/tests/integration/test_stock_search.py` |
| RF-09 | 8, 11 | `backend/tests/integration/test_stock_search.py` |
| RF-10 | 8, 11 | `backend/tests/integration/test_stock_search.py` |
| RF-11 | 8, 11 | `backend/tests/integration/test_stock_search.py` · `backend/tests/unit/test_stocks_service.py` |
| RF-12 | 8, 11 | `backend/tests/integration/test_stock_search.py` |
| RF-13 | 8, 9, 11, 13 | `backend/tests/integration/test_stock_search.py` · `frontend/tests/Autocomplete.test.tsx` |
| RF-14 | 9, 13 | `frontend/tests/Autocomplete.test.tsx` · `frontend/tests/copy.test.ts` |
| RF-15 | 8, 9, 12, 13 | `backend/tests/integration/test_favorites.py` · `frontend/tests/MyActions.test.tsx` |
| RF-16 | 9, 13 | `frontend/tests/MyActions.test.tsx` |
| RF-17 | 8, 9, 12, 13 | `backend/tests/integration/test_favorites.py` · `frontend/tests/MyActions.test.tsx` |
| RF-18 | 8, 12 | `backend/tests/integration/test_favorites.py` |
| RF-19 | 9, 13 | `frontend/tests/MyActions.test.tsx` · `frontend/tests/copy.test.ts` |
| RF-20 | 9, 13 | `frontend/tests/MyActions.test.tsx` |
| RF-21 | 9, 13 | `frontend/tests/MyActions.test.tsx` · `frontend/tests/copy.test.ts` |
| RF-22 | 8, 12 | `backend/tests/integration/test_user_isolation.py` |
| RF-23 | 15, 18 | `frontend/tests/StockGrid.test.tsx` · `frontend/tests/copy.test.ts` |
| RF-24 | 14, 15, 17 | `backend/tests/integration/test_favorites.py` · `frontend/tests/MyActions.test.tsx` |
| RF-25 | 15, 18 | `frontend/tests/MyActions.test.tsx` · `frontend/tests/copy.test.ts` |
| RF-26 | 15, 18 | `frontend/tests/MyActions.test.tsx` |
| RF-27 | 14, 17 | `backend/tests/integration/test_favorites.py` |
| RF-28 | 14, 17 | `backend/tests/integration/test_user_isolation.py` |
| RF-29 | 19, 21 | `frontend/tests/StockGrid.test.tsx` |
| RF-30 | 19, 21 | `frontend/tests/MyActions.test.tsx` |
| RF-31 | 9, 13 | `frontend/tests/MyActions.test.tsx` |
| RF-32 | 15, 18 | `frontend/tests/MyActions.test.tsx` |

**Ninguna fila quedó sin tarea y ninguna sin test.** Tres aclaraciones sobre filas que podrían
leerse como huecos:

- **Los cinco criterios que dicen "salir y volver a entrar" se verifican en las dos puntas**, que
  es la regla que dejó la precondición de `001` —ya cumplida, → la nota de arriba—: son `RF-05`,
  `RF-17`, `RF-22`, `RF-24` y `RF-32`. En backend, dos sesiones distintas contra Postgres, que es
  donde la persistencia vive de verdad: la lista que sigue igual con su nombre y su moneda (`RF-05`,
  `RF-17`), la lista ajena que no se movió (`RF-22`) y la acción quitada que no vuelve (`RF-24`).
  En frontend, un **F5 real** con la sesión restaurada desde `sessionStorage`: la grilla vuelve a
  mostrar las mismas acciones (`RF-05`, `RF-17`), la fila que se quitó sigue sin estar (`RF-24`) y
  la que se canceló sigue estando (`RF-32`). Sin H2 de `001` ninguno de esos tests de pantalla
  existiría —sólo se podría remontar la aplicación, y eso probaría el remontaje, no la
  persistencia—: por eso se esperó, y por eso el remontaje simulado sigue prohibido ahora que la
  sesión persiste.
- **`RF-22` y `RF-28` los verifica el mismo archivo que `RF-04`**, y no es repetición: son las tres
  operaciones —leer, agregar y quitar— del único requisito que es el Artículo III. El test que
  importa es el `DELETE` del símbolo que **sí** está en la lista del otro usuario: 204, y la fila
  ajena intacta.
- **La acción delistada que sigue en la lista de quien ya la tenía no tiene `RF`, y es a
  propósito** *(decisión del humano, 2026-09-13)*. Por eso no aparece en esta tabla: la tabla es de
  `RF`, no de reglas de negocio. **No es un hueco.** La regla está firmada —`spec.md` → *Reglas de
  negocio*: «una acción que deja de cotizar deja de sugerirse, pero no desaparece de la lista de
  quien ya la tenía»— y la **tarea 1** le escribe su test: la favorita delistada que **sigue** en
  la grilla con su nombre y su moneda. Su contracara sí es un `RF` —`RF-12`, que la delistada no se
  sugiera— y la cubre la tarea 8. Agregarle un `RF` obligaría a reabrir y volver a firmar una spec
  ya aprobada (Artículo V) por algo que ya está cubierto y testeado. Y es la **única justificación
  del cuarto campo de `StockInfo`**: sin esta regla, `get_stocks` podría filtrar las delistadas y
  `is_listed` no existiría —quien lea el plan y se pregunte por qué `StockInfo` tiene cuatro campos
  y no tres, la respuesta es ésta—. Queda anotado acá para que **`/converge` no lo levante como
  alcance firmado que nadie tomó**: `/converge` contrasta criterios de aceptación contra el código,
  y esta regla no tiene criterio numerado contra el cual contrastarse.
