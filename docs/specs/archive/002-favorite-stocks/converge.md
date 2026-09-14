# Mis Acciones favoritas — Informe de convergencia

<!--
  ARTEFACTO INTERNO. Lo escribe el `Lead` con `agents/skills/converge.md`, y es lo único
  que esa skill produce: no toca código ni artefactos de otros roles.
-->

**Feature:** `002-favorite-stocks` · **Fecha:** 2026-09-14 · **Rol:** `Lead`

**Rama:** `feat/002-favorite-stocks` · **Suite al momento del informe:** 431 tests de backend
(cobertura 91.75%) y 149 de frontend, `make check` limpio.

---

## Veredicto

> ### ✅ Converge — con deriva menor, que no bloquea el gate.

Los 32 requisitos funcionales de `spec.md` tienen implementación con evidencia localizable. No se
encontró ninguna capacidad de negocio que ningún requisito pida. Las 22 tareas marcadas completas
están respaldadas por código que existe.

La deriva menor son **tres artefactos que quedaron desactualizados** y una línea del plan que
perdió un matiz. Ninguna cambia lo que el producto hace; las cuatro se listan en *Hallazgos* con
su rol dueño.

**Pasa al `Code-Reviewer`.**

---

## Tabla de trazabilidad

| Requisito | Qué promete la spec | Dónde está implementado | Evidencia | Estado |
|---|---|---|---|---|
| RF-01 | La grilla muestra las favoritas del usuario identificado | `favorites` | `service.py::list_favorites` · `GET /api/favorites` en `router.py::read_favorites` · `pages/MyActions.tsx` | Implementado |
| RF-02 | Columnas `Símbolo`, `Nombre`, `Moneda` + una cuarta sin encabezado | `StockGrid.tsx` | `COLUMNS` (3 literales) + el cuarto `<th>` vacío, `components/StockGrid.tsx:45-51` | Implementado |
| RF-03 | Cada fila con símbolo, nombre y moneda | `favorites` + `stocks` | `io.py::FavoriteItem` (3 campos) · `service.py::list_favorites` cruzando a `get_stocks` | Implementado |
| RF-04 | Sólo las favoritas del identificado | `favorites/repository.py` | `symbols_of` filtra por `user_id`, que llega de `CurrentUser.id` y de ningún otro lado | Implementado |
| RF-05 | Las favoritas persisten entre sesiones | `user_stocks` | Nada se guarda en el navegador; `tests/integration/test_favorites.py::TestTheListSurvivesTheSession` | Implementado |
| RF-06 | De la más reciente a la más vieja | `favorites/repository.py:28` | `ORDER BY added_at DESC, symbol ASC` | Implementado |
| RF-07 | Sin favoritas: encabezados + `Todavía no agregaste ninguna acción.` | `StockGrid.tsx` | `EMPTY_LIST` + `EmptyList()`, con la grilla y sus encabezados igual en pantalla | Implementado |
| RF-08 | Sugerir por símbolo | `stocks/repository.py::search_listed` | `ILIKE` sobre `Stock.symbol` | Implementado |
| RF-09 | Sugerir también por nombre | `stocks/repository.py::search_listed` | `or_(...)` con `ILIKE` sobre `Stock.name` | Implementado |
| RF-10 | Sin distinguir mayúsculas | `stocks/repository.py::search_listed` | `ILIKE` es case-insensitive y el service **no** cambia la caja del texto que baja | Implementado |
| RF-11 | Máximo 20 sugerencias | `stocks/service.py:267` | `SUGGESTION_LIMIT = 20`, aplicado **después** del orden por relevancia | Implementado |
| RF-12 | Excluir las que dejaron de cotizar | `stocks/repository.py:162` | `Stock.delisted_at.is_(None)` en el `WHERE` de la búsqueda | Implementado |
| RF-13 | Menos de 2 caracteres: sin sugerencias | Las tres puntas | `MIN_QUERY_LENGTH = 2` · `Query(min_length=...)` en `stocks/router.py` · la guarda de `search_stocks` tras el `strip()` · `MIN_QUERY_LENGTH` en `Autocomplete.tsx` | Implementado |
| RF-14 | Sin coincidencias: `No se encontró ninguna acción con ese texto.` | `Autocomplete.tsx` | `NO_MATCHES`, dibujado en lugar de las sugerencias | Implementado |
| RF-15 | Elegir sugerencia + `Agregar Símbolo` agrega | `favorites` | `service.py::add_favorite` · `POST /api/favorites` · `MyActions.tsx::add` | Implementado |
| RF-16 | La fila aparece sin recargar | `MyActions.tsx` | `reloadTheGrid()` después del alta — refetch, no parcheo del array | Implementado |
| RF-17 | Se guarda símbolo, nombre y moneda | `user_stocks` + `stocks` | La descripción vive en `stocks` y la lee `get_stocks`; `user_stocks` guarda la clave (ADR-001) | Implementado |
| RF-18 | Si ya está, la lista no cambia | `favorites/repository.py::add` | `ON CONFLICT DO NOTHING` sobre la PK compuesta | Implementado |
| RF-19 | Si ya está: `Esa acción ya está en tu lista.` | `MyActions.tsx` | `ALREADY_THERE`, disparado por el 200 que `addFavorite` distingue del 201 vía `send()` | Implementado |
| RF-20 | Sin selección no agrega nada | `MyActions.tsx::add` | `if (selected === null) return` antes de cualquier llamada | Implementado |
| RF-21 | Sin selección: `Elegí una acción de las sugerencias.` | `MyActions.tsx` | `NOTHING_CHOSEN` | Implementado |
| RF-22 | Agregar no toca las favoritas de otro | `favorites/repository.py::add` | La fila es `(user_id, symbol)` con el `user_id` del token; `tests/integration/test_user_isolation.py::TestAddingToTheGrid` | Implementado |
| RF-23 | Enlace `Eliminar` en cada fila | `StockGrid.tsx` | `REMOVE` en la cuarta columna, como `<button>` activable | Implementado |
| RF-24 | La baja persiste | `favorites` | `repository.py::remove` · `DELETE /api/favorites/{symbol}` · `tests/integration/test_favorites_remove.py::TestTheRemovalSurvivesTheSession` | Implementado |
| RF-25 | Confirmación nombrando el símbolo | `ConfirmDialog.tsx` | `questionFor(symbol)` → `¿Quitar {símbolo} de tus acciones?`; la fila sigue en la grilla hasta responder | Implementado |
| RF-26 | Confirmar la saca sin recargar | `MyActions.tsx::remove` | `removeFavorite` + `reloadTheGrid()` | Implementado |
| RF-27 | El símbolo sigue en el catálogo | `favorites/service.py::remove_favorite` | No toca `stocks`: sólo borra de `user_stocks` | Implementado |
| RF-28 | La baja no alcanza la fila de otro | `favorites/repository.py::remove` | `WHERE user_id = <el del token> AND symbol = ...`; `test_user_isolation.py::TestRemovingFromTheGrid` | Implementado |
| RF-29 | El símbolo se ve como enlace | `StockGrid.tsx` | `<Link to={/stocks/...}>` con el estilo de enlace del token `--color-link` | Implementado |
| RF-30 | Lleva al detalle de esa acción | `App.tsx` + `ActionDetail.tsx` | Ruta `/stocks/:symbol` protegida por `RequireSession`; el símbolo viaja en mayúsculas | Implementado |
| RF-31 | Sin selección, `Agregar Símbolo` deshabilitado | `MyActions.tsx:146` | `disabled={selected === null}` | Implementado |
| RF-32 | `Cancelar` deja la acción donde estaba | `MyActions.tsx` | `onCancel` sólo hace `setConfirming(null)`: no llama a la API | Implementado |

**Ninguna fila quedó `Parcial` ni `Ausente`.**

---

## Alcance no pedido (código → spec)

Se recorrió el inventario en sentido inverso: las tres rutas nuevas (`GET /api/stocks`,
`POST /api/favorites`, `DELETE /api/favorites/{symbol}`), los dos `__all__` que crecieron, los tres
componentes, los dos módulos de `api/`, la pantalla nueva y la migración.

**No se encontró ninguna capacidad de negocio que ningún requisito pida.** Cuatro piezas que
podrían leerse como alcance extra y no lo son, cada una con dónde está justificada:

- **La migración de `pg_trgm` y sus dos índices GIN.** Es rendimiento, no funcionalidad: nada de
  lo que el usuario ve cambia por ella. `plan.md` → *Alternativas descartadas* y `tasks.md` → *Las
  dos tareas que no cubren ningún `RF`*.
- **`send()` y `setAuthTokenProvider` en `api/client.ts`.** Andamiaje que `plan.md` → *Contratos*
  → *Frontend* justifica y cuya forma fija con una tabla de precedencia de tres casos.
- **`ActionDetail.tsx`.** Cascarón deliberado: `RF-30` necesita que el enlace llegue a algún lado.
  `plan.md` lo declara y dice que `003` la reemplaza entera.
- **El `warning` de `CANDIDATE_LIMIT`.** Instrumentación que `plan.md` → `GET /api/stocks`
  justifica: sin él, un tope que envejece degrada la relevancia en silencio.

**Y la favorita delistada que sigue en la grilla no es alcance sin requisito**, aunque no tenga
`RF`: es una regla de negocio firmada (`spec.md` → *Reglas de negocio*) y `tasks.md` ya deja
anotado por qué no está en la tabla de `RF`. Es la única justificación del cuarto campo de
`StockInfo`.

---

## Reglas del dominio

| Artículo | Verificado | Cómo |
|---|---|---|
| I — La credencial vive sólo en el backend | ✅ | `grep -rniE "twelvedata\|api_key\|apikey" frontend/src` → vacío. Ninguna variable `VITE_*` nueva. |
| II — La cuota es finita | ✅ | Ninguna de las tres rutas nuevas sale al proveedor: el autocomplete lee `stocks` (A3). Ningún `import` de un cliente HTTP fuera de `app/providers/`. |
| III — Los datos del usuario son suyos | ✅ | Ninguna ruta acepta `user_id` por path, query ni body. Las tres funciones de `favorites/repository.py` lo exigen como primer argumento. `test_user_isolation.py` lo verifica con dos usuarios reales en las tres operaciones. |
| IV — Las fronteras son reales | ✅ | Ningún import entra al interior de otro módulo (verificado con el recorrido por módulo, y por `tests/architecture/`). `favorites` entra a `stocks` por el paquete y en batch. Ningún `relationship()` cruza. |
| VII — El enunciado es el contrato | ✅ | A3 y A4 se respetan: el autocomplete consulta la base, y la ingesta sigue siendo NYSE **y** NASDAQ. Los textos son los literales de `COPY.md`, verificados por `copy.test.ts`. |
| X — Los ADR los decide un humano | ✅ | `git diff docs/DECISIONS.md` → vacío. Ningún ADR nuevo. |

---

## Hallazgos

| # | Tipo | Qué dice el artefacto | Qué hace el código | Rol dueño | Acción |
|---|---|---|---|---|---|
| 1 | Diagrama desactualizado | `ARCHITECTURE.md` describe un `stocks` que sólo ingesta, un `favorites` que es sólo una tabla, y `get_stocks(symbols)` sin sesión | `stocks` responde dos rutas, `favorites` nació completo, y la firma real lleva la sesión adelante | `Backend-Architect` · `Frontend-Architect` | Es la **tarea 22**, en curso al momento de este informe |
| 2 | Deriva del plan | `plan.md` → *Contratos* → `POST /api/favorites`: «el service normaliza a mayúsculas (`symbol.strip().upper()`)» | Literalmente cierto, pero el `.strip()` no puede recortar nada: el schema rechaza los espacios con 422 antes | `Backend-Architect` | Una aclaración de una línea, o dejarlo: la frase no es falsa |
| 3 | Deriva del plan | `plan.md` fija para el body `max_length=12` y el patrón, y no menciona `min_length` | `AddFavoriteRequest` lleva además `min_length=1` | `Developer` | Redundante con el patrón y sin efecto; sacarlo o anotarlo en el plan |
| 4 | Tarea sin respaldo *(anticipada)* | `tasks.md` → nota al pie: la columna **Test** de la tabla de trazabilidad de `docs/PROJECT_BRIEF.md` (REQ-05…REQ-11, NFR-03) la completa `ship_changes` | Hoy está vacía | `Release-Manager` | Se completa en `/ship`, en el mismo commit que archiva la spec. **No es un hallazgo abierto**: queda anotado para que el gate siguiente no lo pase por alto |

**Ninguno de los cuatro bloquea.** El 1 está en curso; el 2 y el 3 son de redacción y de un
argumento sin efecto; el 4 es trabajo del paso siguiente, ya previsto.

---

## Dos cosas que no son hallazgos y conviene que estén escritas

**Tres tests de la suite no prueban hoy lo que su nombre dice, y es sabido y aceptado.** Dos de
`stockDetail.test.tsx` —los del guard de `/stocks/:symbol` sin sesión— pasaban antes de que la
ruta existiera, porque el catch-all `path="*"` la mandaba a `/`, que ya estaba protegida. Hoy la
ruta existe y sí prueban lo suyo. Se declaró antes de la firma.

**El foco atrapado, `Escape` y el backdrop del `ConfirmDialog` no los verifica ningún test**, y no
pueden verificarse: jsdom no implementa el top layer. El componente llama `showModal()`, que es lo
que el plan pide, y `tests/setup.ts` lo emula con el motivo escrito. **Quedan a verificación
manual contra un navegador**, y es lo que el `Code-Reviewer` tendría que mirar a mano antes del
merge.
