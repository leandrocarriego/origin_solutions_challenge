# Detalle de Acción y gráfico de cotizaciones — Informe de convergencia

<!--
  ARTEFACTO INTERNO. Lo escribe el `Lead` con `agents/skills/converge.md`, y es lo único que esa
  skill produce: no toca código ni los artefactos de otros roles.

  `review_feature` pregunta "¿está bien escrito?". Esto pregunta "¿es lo que se acordó?".
-->

**Feature:** `003-quote-chart` · **Rama:** `feat/003-quote-chart` · **Fecha:** 2026-09-14
**Spec:** `Aprobado` — firmada por Leandro Carriego el 2026-09-13
**Changeset:** lo commiteado en la rama más el árbol de trabajo de `/implement` (23 tareas)

## Veredicto

> ## ⚠️ Deriva menor — **no bloquea el gate**
>
> El código y la spec describen **el mismo producto**: los 48 requisitos funcionales tienen
> implementación con evidencia localizable, no hay ninguna capacidad que ningún requisito pida, y
> las 23 tareas marcadas completas están respaldadas por código que existe.
>
> Lo que quedó fuera de lugar son **dos detalles de presentación frente al wireframe 03**, los dos
> visibles y ninguno de ellos cambia lo que la pantalla hace: las etiquetas del eje horizontal
> escriben la fecha completa donde el wireframe escribe sólo la hora, y los controles se apilan
> donde el wireframe los pone en fila. Son hallazgos H-01 y H-02, con rol dueño y acción concreta.
>
> La feature pasa al `Code-Reviewer`, que es además quien tiene `UI-01` en su lista.

## Cobertura de requisitos (spec → código)

Las 48 filas de `spec.md`, cada una con dónde está y con qué se verifica. Abreviaturas de la
columna *Dónde*: `quotes/*` es `backend/app/modules/quotes/`, `src/*` es `frontend/src/`.

### H1 — Ver el gráfico de una acción

| Requisito | Qué promete la spec | Dónde está implementado | Evidencia | Estado |
|---|---|---|---|---|
| RF-01 | Cabecera `{símbolo} - {nombre} - {moneda}` | `src/pages/ActionDetail.tsx` | `<Header title={…favorite.symbol - name - currency} />`, armado con `listFavorites()` · `ActionDetail.test.tsx` → *shows the symbol, the name and the currency* | Implementado |
| RF-02 | Sin sesión, a la pantalla de ingreso | `src/App.tsx` | `<RequireSession>` sobre `/stocks/:symbol` · `session.test.tsx` (dos casos sobre `/stocks/TSLA`) | Implementado |
| RF-03 | `Tiempo Real` e `Histórico`, excluyentes | `src/pages/ActionDetail.tsx` | dos `<input type="radio" name="mode">` · `ActionDetail.test.tsx` → *only one of them at a time* | Implementado |
| RF-04 | `Tiempo Real` elegido al abrir | `src/pages/ActionDetail.tsx` | `useState<Mode>('realtime')` · `ActionDetail.test.tsx` → *opens with Tiempo Real already marked* | Implementado |
| RF-05 | Aclaración del radio 1, verbatim | `src/pages/ActionDetail.tsx::ACLARACION_TIEMPO_REAL` | literal sin cortar (`prettier-ignore`) · `copy.test.ts` → *Aclaración del radio 1* · `ActionDetail.test.tsx` | Implementado |
| RF-06 | Selector con `1min`, `5min`, `15min` y nada más | `src/pages/ActionDetail.tsx::INTERVALS` | `ActionDetail.test.tsx` → *offers the three intervals of the brief, and nothing else* | Implementado |
| RF-07 | Selector vacío al abrir | `src/pages/ActionDetail.tsx` | `useState<QuoteInterval \| ''>('')` + `<option value="" />` · `ActionDetail.test.tsx` → *opens with nothing chosen* | Implementado |
| RF-08 | Aclaración del intervalo, verbatim | `src/pages/ActionDetail.tsx::ACLARACION_INTERVALO` | `copy.test.ts` · `ActionDetail.test.tsx` → *carries the note of the brief next to it* | Implementado |
| RF-11 | Botón `Graficar` | `src/pages/ActionDetail.tsx::GRAFICAR` | `copy.test.ts` → *Botón* · `ActionDetail.test.tsx` → *offers the button* | Implementado |
| RF-12 | Ningún gráfico antes de `Graficar` | `src/pages/ActionDetail.tsx` | `plotted === null` no monta `QuoteChart` · `ActionDetail.test.tsx` → *shows no chart, not even an empty one* y *asks our API for nothing* | Implementado |
| RF-13 | `Tiempo Real` grafica la rueda del día | `quotes/service.py::get_series` → `_today_began` · `src/api/quotes.ts::getQuotes` | ventana `[00:00 de hoy en mercado, ahora]` · `test_quotes.py::TestAskingForTodaysSession` · `ActionDetail.test.tsx` → *asks our API for the chosen interval, and for today* | Implementado |
| RF-14 | Título `{símbolo}`, ejes `Cotización` e `Intervalo` | `src/components/QuoteChart.tsx` | `title: { text: symbol }`, `EJE_Y`, `EJE_X` · `copy.test.ts` → *Eje Y* / *Eje X* · `ActionDetail.test.tsx` → *draws the chart the brief describes* | Implementado |
| RF-15 | Cada cotización en su momento | `src/components/QuoteChart.tsx::pointsFor` · `src/quotes/market.ts::formatMarket` | `[Date.parse(ts), Number(price)]` · `market.test.ts` → *puts every quote at the moment it belongs to* · `test_upstream_client.py` → *the first and the last candle are the instants they claim* | Implementado |
| RF-17 | Graficar de nuevo reemplaza el gráfico | `src/pages/ActionDetail.tsx` | `key={plotKey}` con `símbolo\|modo\|intervalo\|desde\|hasta` · `ActionDetail.test.tsx` → *replaces the chart … instead of stacking a second one* | Implementado |
| RF-34 | Enlace `Mis Acciones` a la izquierda del título | `src/components/Header.tsx` (prop `back`) | `<Link to={back.to}>` antes del `<h1>` · `ActionDetail.test.tsx` → *offers the way back to the list as a link, and it goes there* | Implementado |
| RF-35 | Acción ajena → a `Mis Acciones` | `quotes/service.py::get_series` (404) · `src/pages/ActionDetail.tsx` (`<Navigate to="/">`) | `is_favorite` o `UnknownSymbolError` · `test_user_isolation.py::TestReadingTheChart` (404 **y** cero llamadas) · `ActionDetail.test.tsx` → *leaves the person on Mis Acciones* | Implementado |
| RF-36 | Todas las fechas y horas, en hora del mercado | `src/quotes/market.ts` · `quotes/service.py::MARKET_TIMEZONE` | `formatMarket`, `marketFieldValue`, `defaultHistoricRange`; `session_date` en `_last_session` · `market.test.ts` (21 casos, dos estaciones, dos `TZ`) · `test_quotes_status.py` → *a session that crosses midnight in utc is still one day* | Implementado — ver H-01 |
| RF-37 | `Horarios en hora del mercado.` debajo del título | `src/components/Header.tsx` (prop `note`) | `<p>{note}</p>` dentro del bloque del título · `copy.test.ts` → *Aclaración de horarios* · `ActionDetail.test.tsx` | Implementado |
| RF-38 | Tooltip con hora de mercado y de Argentina | `src/quotes/market.ts::tooltipTimeLines` · `QuoteChart.tsx` (formatter) | `market.test.ts` → *the two lines of the tooltip* (3 casos) · `copy.test.ts` → *Hora del mercado (tooltip)* / *Hora de Argentina (tooltip)* | Implementado |

### H2 — Que el gráfico se mantenga solo

| Requisito | Qué promete la spec | Dónde está implementado | Evidencia | Estado |
|---|---|---|---|---|
| RF-18 | Refresco cada intervalo | `src/pages/ActionDetail.tsx` | `setInterval(…, INTERVAL_MS[plotted.interval])` · `quoteRefresh.test.tsx` → *asks our API again once the chosen interval has gone by* y *refreshes on the interval that was chosen* | Implementado |
| RF-19 | Sin recargar la pantalla | `src/components/QuoteChart.tsx` | efecto que llama `series[0].setData(...)` sin rehacer el gráfico · `quoteRefresh.test.tsx` → *draws the refresh into the chart that is already there* (identidad del nodo) | Implementado |
| RF-20 | Sin perder las cotizaciones ya graficadas | `src/pages/ActionDetail.tsx` (refresco sin `from`/`to`) | la respuesta es la rueda entera · `quoteRefresh.test.tsx` → *keeps asking for the whole session* | Implementado |
| RF-21 | Pestaña escondida suspende la actualización | `src/pages/ActionDetail.tsx` | `visibilitychange` → `stop()` · `quoteRefresh.test.tsx` → *stops asking while the tab is not being looked at* | Implementado |
| RF-22 | Al volver, se reanuda | `src/pages/ActionDetail.tsx` | `refresh()` inmediato + `arm()` · `quoteRefresh.test.tsx` → *catches up as soon as the tab is looked at again* | Implementado |
| RF-23 | `Histórico` no se actualiza solo | `src/pages/ActionDetail.tsx` | el efecto retorna si `plotted.mode !== 'realtime'` · `quoteHistoric.test.tsx` → *is never refreshed on its own* | Implementado |

### H3 — Consultar un período pasado

| Requisito | Qué promete la spec | Dónde está implementado | Evidencia | Estado |
|---|---|---|---|---|
| RF-09 | Campos `Fecha hora desde` / `hasta` | `src/pages/ActionDetail.tsx` | dos `<input type="datetime-local">` con `aria-label` y `placeholder` · `copy.test.ts` → *Placeholder desde* / *hasta* · `quoteHistoric.test.tsx` → *are both on screen* | Implementado |
| RF-10 | Cargados con las últimas 24 h de mercado | `src/quotes/market.ts::defaultHistoricRange` | `market.test.ts` → *is the last twenty-four hours, told in market time* · `quoteHistoric.test.tsx` → *come already filled …* (con el reloj fijado) | Implementado |
| RF-16 | Grafica lo comprendido entre desde y hasta | `quotes/service.py::_window_asked_for` · `quotes/repository.py::candles_in` | ventana localizada en `MARKET_TIMEZONE` · `test_quotes_range.py` → *from and to are read as market hours*, *… are not read as server hours*, *the series falls entirely inside the window* | Implementado |
| RF-40 | `Completá este campo.` debajo del campo vacío | `src/pages/ActionDetail.tsx::plot` | `errors.from` / `errors.to`, cada uno bajo su campo · `quoteHistoric.test.tsx` → *says what is missing under the field that is missing it* | Implementado |
| RF-41 | Fechas al revés → texto bajo los campos | `app/errors.py::QuoteRangeInvalid` · `main.py` (422) · `ActionDetail.tsx::refusalText` | `test_quotes_range.py` → *from not before to is 422* · `quoteHistoric.test.tsx` → *says the dates are the wrong way round* y *puts that notice underneath the two date fields* | Implementado |
| RF-42 | `1min`: máximo 7 días | `quotes/service.py::MAX_RANGE_DAYS` | `test_quotes_range.py` → *a range exactly at the cap is graphed* / *one day past the cap is 422* (`1min`, 7) | Implementado |
| RF-43 | `5min`: máximo 30 días | `quotes/service.py::MAX_RANGE_DAYS` | los mismos dos tests, parametrizados (`5min`, 30) | Implementado |
| RF-44 | `15min`: máximo 90 días | `quotes/service.py::MAX_RANGE_DAYS` | los mismos dos tests, parametrizados (`15min`, 90) | Implementado |
| RF-45 | Rango excedido → texto con `{intervalo}` y `{N}` | `app/errors.py::QuoteRangeTooLong` · `ActionDetail.tsx::RANGO_EXCEDIDO` | el 422 lleva `interval` y `max_days` (`test_quotes_range.py` → *carries the interval and its cap*) y la pantalla los rellena (`quoteHistoric.test.tsx` → *says the other interval and the other number*) | Implementado |

### Validación y consultas que no se ejecutan

| Requisito | Qué promete la spec | Dónde está implementado | Evidencia | Estado |
|---|---|---|---|---|
| RF-39 | `Elegí un intervalo.` debajo del selector | `src/pages/ActionDetail.tsx::plot` | `errors.interval`, dibujado después del `<select>` · `ActionDetail.test.tsx` → *says which choice is missing, right under the selector* | Implementado |
| RF-46 | Consulta inválida no grafica | `src/pages/ActionDetail.tsx` | las cuatro salidas no tocan `plotted` · `ActionDetail.test.tsx` → *draws no chart* · `quoteHistoric.test.tsx` → *draws no chart for either refusal* | Implementado |
| RF-47 | Consulta inválida no consulta la fuente externa | `ActionDetail.tsx` (presencia) · `quotes/service.py::get_series` (rango, paso 1) | `ActionDetail.test.tsx` / `quoteHistoric.test.tsx` → *asks our API for nothing* · `test_quotes_range.py::TestARefusedRangeCostsNothing` (cero llamadas, **y** ninguna lectura de `quotes` ni `user_stocks`) | Implementado |
| RF-48 | El gráfico anterior queda como está | `src/pages/ActionDetail.tsx` | `plotted` intacto en los cuatro casos · `ActionDetail.test.tsx` y `quoteHistoric.test.tsx` → *leaves the chart that was already there exactly as it was* (identidad del nodo) | Implementado |

### Consumo del proveedor (Artículo II)

| Requisito | Qué promete la spec | Dónde está implementado | Evidencia | Estado |
|---|---|---|---|---|
| RF-24 | No consultar si el dato vigente ya se conoce | `quotes/service.py::_answers_already` | TTL = el intervalo · `test_quotes_service.py` → *a cached candle inside the ttl is served without calling the provider*, *asking twice in a row reaches the provider once* · `test_quotes.py` → *a fresh cache answers without spending a credit* | Implementado |
| RF-25 | Varias personas cuestan lo que una | `quotes/service.py::_gate_for` + `_fill` (candado + último intento) | `test_quotes_service.py` → *ten requests launched in parallel reach the provider once* (con `asyncio.gather`) y *a symbol with no series is not asked again inside a ttl* | Implementado |
| RF-26 | No mostrar nombre ni dirección del proveedor | `quotes/service.py` (logs y estados genéricos) · `COPY.md` (`el proveedor`, nombre común) | `test_quotes_service.py` / `test_quotes_status.py` → *does not name the provider* (respuesta y log) · `test_quotes.py` → *the body does not name the provider* · `quoteNotice.test.tsx` → *never names who did not answer* · `test_provider_boundary.py` | Implementado |

### H4 — Entender qué se está viendo

| Requisito | Qué promete la spec | Dónde está implementado | Evidencia | Estado |
|---|---|---|---|---|
| RF-27 | Sin rueda hoy, graficar la última disponible | `quotes/service.py::_last_session` | `test_quotes_status.py` → *market closed charts that earlier session* · `test_quotes_status.py` (integración) → *it charts that earlier session* | Implementado |
| RF-28 | Aviso `El mercado está cerrado… {fecha}.` | `src/components/Notice.tsx::MARKET_CLOSED` · `service.py` (`session_date`) | `copy.test.ts` → *`market_closed`* · `quoteNotice.test.tsx` → *writes that date from the answer and not from the calendar of the machine* | Implementado |
| RF-29 | Sin datos nuevos, graficar lo último conocido | `quotes/service.py::_answer` (`failed` → `stale` con lo que haya) | `test_quotes_status.py` → *a stale answer still carries the last prices known* (y su par de integración) | Implementado — ver nota 2 |
| RF-30 | Aviso `Mostrando la última cotización disponible…` | `src/components/Notice.tsx::STALE` | `copy.test.ts` → *`stale`* · `quoteNotice.test.tsx` → *says the quotes are the last ones available* | Implementado |
| RF-31 | Aviso `No hay cotizaciones para {símbolo}…` | `src/components/Notice.tsx::NO_DATA` · `service.py` (`no_data`) | `copy.test.ts` → *`no_data`* · `quoteNotice.test.tsx` → *says which action has none, with the symbol inside* | Implementado |
| RF-32 | Al día, ningún aviso | `src/components/Notice.tsx::textFor` (devuelve `null` con `ok`) | `quoteNotice.test.tsx` → *shows no notice at all* · `test_quotes_status.py` → *fresh data is ok* | Implementado |
| RF-33 | Nunca sin gráfico y sin aviso | `src/pages/ActionDetail.tsx` (el `status` decide) | `quoteNotice.test.tsx` → *never leaves the screen with neither a chart nor a notice* (los cuatro estados, cada uno en su pantalla) | Implementado |

**Ninguna fila quedó `Parcial` ni `Ausente`.**

## Alcance no pedido (código → spec)

Recorrido el inventario en sentido inverso: **no hay hallazgos**.

| Lo que el código agrega | Qué requisito lo pide |
|---|---|
| `GET /api/quotes/{symbol}` — la única ruta nueva | RF-13, RF-16 |
| `is_favorite` en el `__all__` de `favorites` | RF-35 (Artículo III) |
| `QuoteRangeInvalid` / `QuoteRangeTooLong` en `app/errors.py` | RF-41, RF-42…RF-45 |
| `src/quotes/market.ts`, `api/quotes.ts`, `QuoteChart.tsx`, `Notice.tsx` | RF-14, RF-15, RF-36, RF-38 / RF-13 / RF-14 / RF-28, RF-30, RF-31 |
| Props `back` y `note` de `Header.tsx` | RF-34, RF-37 |
| `session_date` en la respuesta | RF-28 |

Andamiaje que `plan.md` justifica y que por eso **no** es alcance no pedido: `REALTIME_LOOKBACK`, la
compuerta `_GATES`/`_gate_for`, el upsert `DO UPDATE`, el `detail` de `ApiError` y el cierre del
parámetro `name` en `providers/registry.py` (los dos últimos, decididos por el humano el 2026-09-14
y registrados en `plan.md`). Lo privado del archivo —`_TTL`, `_answer`, `_points`, `_last_session`,
`_fetch`, `_fill`— no es superficie y no entra al inventario (`PY-10`).

**Ninguna tabla nueva, ninguna migración**, tal como el plan lo declara: `alembic check` sigue
limpio.

## Tareas declaradas completas

Las 23 se verificaron contra el archivo que nombran. Ninguna quedó sin respaldo. Las cuatro firmas
(4, 11, 15 y 20) están registradas en el encabezado de `tasks.md` con quién y cuándo.

## Deriva respecto del plan

| Decisión del plan | Qué hizo el código | Clasificación |
|---|---|---|
| `quotes` entra a `favorites` por el paquete | `from app.modules.favorites import is_favorite` | Sin deriva |
| Hermanos por ruta completa | los cinco archivos de `quotes` se importan así; ningún import cruza al interior ajeno | Sin deriva |
| `router` → `service` → `repository` | el router no importa SQLAlchemy, el service no importa `fastapi` | Sin deriva |
| Validar el rango antes de autorizar | `_window_asked_for` es la primera línea de `get_series` | Sin deriva |
| Dos ventanas para el proveedor | `[última vela, ahora]` y `[ahora − REALTIME_LOOKBACK, ahora]` | Sin deriva |
| `time.timezone = MARKET_TIME_ZONE` en el eje | etiquetas escritas por `market.ts`; el eje trabaja en UTC | **Deriva resuelta**: el humano decidió el 2026-09-14 y `plan.md` ya lo dice |
| `providers/registry.py` no se toca | se tocó, para que `name` no sea parámetro del request | **Deriva resuelta**: decidida el 2026-09-14 y registrada en `plan.md` |
| `api/client.ts` no figuraba | `ApiError` lleva el `detail` del 422 | **Deriva resuelta**: decidida el 2026-09-14 y registrada en `plan.md` |

## Ambigüedades declaradas (`docs/PROJECT_BRIEF.md`)

| # | Lo que declara | Lo que hace el código | Estado |
|---|---|---|---|
| A2 | "Tiempo real" es polling **del frontend contra nuestra API** | `getQuotes` sobre `/api/quotes`, con `INTERVAL_MS` | Sigue siendo verdad |
| A4 | NYSE y NASDAQ, mismo huso | `MARKET_TIMEZONE = America/New_York`, una constante y no una columna | Sigue siendo verdad |
| A5 | Sin rueda hoy, la última disponible con aviso arriba | `market_closed` + `Notice` montado antes del gráfico | Sigue siendo verdad |
| A6 | Últimas 24 h de mercado; `desde < hasta` y rango coherente con el intervalo | `defaultHistoricRange` + `QuoteRangeInvalid` / `MAX_RANGE_DAYS` | Sigue siendo verdad |
| A7 | Cabecera: símbolo, nombre y moneda | `{símbolo} - {nombre} - {moneda}` desde `listFavorites()` | Sigue siendo verdad |

## Reglas del dominio

| Regla | Verificación | Resultado |
|---|---|---|
| I — la credencial vive en el backend | `grep -rniE "twelvedata\|apikey\|api_key" frontend/src` | sin resultados |
| I / GEN-08 — el cliente HTTP vive en `providers/` | `grep` de `httpx\|requests\|aiohttp\|urllib.request` fuera de `app/providers/` | sin resultados |
| I — el nombre del proveedor, en un solo archivo | `grep -rni twelvedata backend/app` fuera de `providers/twelvedata.py` y `settings.py` | sin resultados |
| II — no se consulta si el dato está en la base | TTL + compuerta + los tests de RF-24/RF-25/RF-47 | cumplida |
| III — toda lectura filtra por el `sub` del token | `user_id` sale de `get_current_user`; `is_favorite` lo recibe como primer argumento y va en el `WHERE` | cumplida |
| IV — se entra por el paquete, el flujo va en un sentido | los dos únicos imports entre módulos son por el paquete | cumplida |
| VII — el enunciado literal, y lo no definido declarado | textos verbatim (`copy.test.ts`), faltas incluidas | cumplida |
| X — ningún ADR nuevo | `docs/DECISIONS.md` sin cambios en el changeset | cumplida |

## Hallazgos

| # | Tipo | Qué dice el artefacto | Qué hace el código | Rol dueño | Acción |
|---|---|---|---|---|---|
| H-01 | Deriva del diagrama | El wireframe 03 rotula el eje horizontal con la hora sola: `13:10  13:11  13:12 …` | Cada tick escribe `DD/MM/YYYY HH:MM`, porque el formateo pasó a `market.ts` y ahí la única lectura disponible es la completa | `Frontend-Architect` (fija la firma) → `Tester` → `Developer` | Agregar a `quotes/market.ts` una lectura de hora sola —`marketClockValue(instant)`, `'15:55'`— y usarla en el `formatter` del eje. Es superficie nueva del módulo, así que la firma la fija el plan y el test se firma antes de implementarla (Artículo VI) |
| H-02 | Deriva del diagrama | El wireframe pone la aclaración **a la derecha** de `Tiempo Real`, los dos campos de fecha **a la derecha** de `Histórico`, y `Intervalo` con su selector y su aclaración en una fila | La pantalla los apila verticalmente: cada control en su renglón | `Developer` | Acomodar el layout de `ActionDetail.tsx` en filas, sin tocar el orden de los controles ni ningún texto. No cambia ningún RF: RF-34, RF-37, RF-39, RF-40, RF-41, RF-45 y UI-05 fijan las posiciones relativas y las siete se siguen cumpliendo |

Ninguno de los dos bloquea: la pantalla hace lo que la spec firmó, y lo que difiere es cómo se ve.
Los dos caen además en la lista que el plan le dejó al `Code-Reviewer` (`UI-01`, punto 5), así que
si no se corrigen antes, los va a levantar el gate de calidad.

### Dos notas que no son hallazgos, y conviene que estén escritas

1. **Los campos de fecha se dibujan siempre, también en `Tiempo Real`.** `RF-09` los pide "para el
   modo `Histórico`" y el wireframe los dibuja en la fila de `Histórico`, sin decir que
   desaparezcan. Lo fijó el test firmado de la tarea 14, que los lee **antes** de tocar el radio
   (*"they are there from the moment the screen opens"*). Queda anotado porque es la clase de
   decisión que alguien vuelve a discutir dentro de seis meses.

2. **`RF-29` en modo `Histórico` responde `stale` sin puntos cuando la ventana pedida no tiene
   nada guardado.** "Las últimas cotizaciones que ya conocía" son las de la ventana que se pidió:
   caer a otra rueda sería contestar una pregunta distinta de la que se hizo. En `Tiempo Real`, que
   es donde `RF-27` lo pide explícitamente, sí cae a la última rueda disponible.

## Estado de la suite al cerrar el converge

- Backend: 557 tests en verde · cobertura 92.7% (mínimo 80) · `ruff format --check`, `ruff check` y
  `mypy` limpios · `alembic check` sin operaciones pendientes.
- Frontend: 256 tests en verde, también con `TZ=Asia/Tokyo` · `eslint`, `tsc --noEmit` y
  `prettier --check` limpios.

## Lo que queda para `/ship`

La columna **Test** de la tabla de trazabilidad de `docs/PROJECT_BRIEF.md` (`REQ-12`…`REQ-17`,
`NFR-02`, `NFR-04`, `NFR-05`) todavía está vacía. No es un hallazgo: `tasks.md` se la asigna
explícitamente a `ship_changes`, en el mismo commit de la feature y antes del merge
(`docs/specs/README.md` → *Al entregar*). La *Definition of Done* la exige completa, así que el
merge no pasa sin ella.
