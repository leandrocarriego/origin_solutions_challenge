# Detalle de Acción y gráfico de cotizaciones — Tareas

<!--
  ARTEFACTO INTERNO. Cada tarea mapea a una skill de agents/skills/ y es lo bastante
  chica como para terminarse de una sentada. Si una tarea no tiene skill, o no
  corresponde al proyecto, o falta la skill: preguntá antes de inventarla.
-->

**Feature:** `003-quote-chart` · **Plan:** `plan.md`

**Tests aprobados por:** Leandro Carriego · **Fecha de aprobación:** 2026-09-14

| Historia | Tests | Firma | Fecha |
|---|---|---|---|
| H1 — Ver el gráfico de una acción | tareas 2, 3 y 3b | Leandro Carriego | 2026-09-14 |
| H2 — Que el gráfico se mantenga solo | tarea 10 | Leandro Carriego | 2026-09-14 |
| H3 — Consultar un período pasado | tareas 13 y 14 | Leandro Carriego | 2026-09-14 |
| H4 — Entender qué estoy viendo cuando no hay datos de hoy | tareas 18 y 19 | Leandro Carriego | 2026-09-14 |

> **Qué se firmó, y con qué salvedades.** 186 tests en 13 archivos, leídos en los archivos por
> quien firma. Verificado antes de la firma: todos fallan por ausencia de implementación, ninguno
> por un import roto ni por un fixture mal armado.
>
> Dos salvedades quedaron señaladas y aceptadas:
>
> - Los **dos tests de `RF-02`** de `session.test.tsx` pasan hoy en verde sin implementación,
>   porque la dirección del Detalle todavía cae sola en el guard de sesión. No prueban nada
>   todavía; lo que compran es que siga siendo cierto cuando la pantalla exista.
> - Los **21 casos de `market.test.ts`** salen *skipped* y no *failed*: el módulo se carga con un
>   `import()` dinámico para que su ausencia no voltee `tsc --noEmit` de toda la suite. El archivo
>   sí sale `FAIL`, así que el rojo llega a CI. Cuando el módulo exista, pasa a ser un import
>   normal y los 21 se cuentan como el resto.
>
> **La tarea 1 sigue sin hacer** (recapturar el JSON fijado en UTC): no hay `TWELVEDATA_API_KEY` en
> este entorno. El `xfail(strict=True)` de `test_upstream_client.py` marca el lugar y va a dar
> XPASS el día que se recapture.

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

> **Esta feature no lleva migración, y el plan lo dice con todas las letras.** *(Confirmado por el
> humano, 2026-09-13: la quinta tabla `quote_fetches` no entra.)* La tabla `quotes` —PK compuesta
> `(symbol, interval, ts)` e índice `ix_quotes_symbol_interval_ts`— existe desde la
> migración inicial de la fase 0 (`394dab64d255`), y `quotes/models.py` **no se toca**. El orden
> *migración → tests → backend → frontend* se sigue igual: es que el primer escalón está vacío.
> `alembic check` tiene que seguir limpio al cerrar la feature (`DB-01`): si dejó de estarlo, es
> que alguien tocó el modelo y este plan dejó de ser verdad.

> **La tarea 1 va antes de los tests, y no es una excepción al Artículo VI.** *(Confirmado por el
> humano, 2026-09-13: la serie se pide en UTC y el fixture se recaptura antes de escribir el test.)*
> Volver a capturar el JSON fijado de TwelveData no es implementación: es **el dato**, la respuesta
> real del proveedor con los parámetros nuevos. El test de la tarea 2 afirma el instante exacto de
> la primera y la última vela, así que necesita el fixture nuevo para poder escribirse — y va a quedar **en rojo**
> igual, porque `twelvedata.py` todavía le estampa UTC a una hora de mercado. Lo que pone en verde
> ese test es la tarea 5, después de la firma.
>
> La captura es **una llamada a mano, una sola vez, con la API key** (`TEST-03` → *Cómo se fija una
> respuesta*). El fixture se guarda sin editar: un fixture retocado describe un proveedor que no
> existe.

> **`make types` se corre en las tareas 8 y 16.** La 8 es la primera que necesita el tipo de
> `GET /api/quotes/{symbol}`, y para entonces el router ya está montado (tarea 7). La 16 agrega los
> dos 422 del rango al schema, y la pantalla del `Histórico` (tarea 17) los consume. Se regenera con
> `make types` y **no se edita a mano** (`TS-03`).

> 🚧 **Bloqueo: esta feature no arranca hasta que `002-favorite-stocks` esté entregada.** De ahí
> salen cuatro piezas que este plan consume y **no construye**: `UnknownSymbolError` en
> `app/errors.py`, `GET /api/favorites` con símbolo, nombre y moneda —que es de donde sale la
> cabecera (`RF-01`) y con lo que se decide si la acción es del usuario (`RF-35`)—, el `Bearer` de
> `api/client.ts`, y la ruta `/stocks/:symbol` protegida por `RequireSession` (`RF-02`). Es la
> dependencia que el `ROADMAP` ya declara.
>
> **La cabecera ya existe y no se construye de nuevo.** `frontend/src/components/Header.tsx` es de
> `001` —su tarea 11, entregada— y es la barra de **todas** las pantallas internas. El Detalle la
> **reusa**: le pasa el título (`{símbolo} - {nombre} - {moneda}`) y las dos props opcionales que
> esta feature le agrega, `back` (el enlace `Mis Acciones`, `RF-34`) y `note` (`Horarios en hora del
> mercado.`, `RF-37`). La firma exacta está en `plan.md` → *Frontend — estructura y contrato de
> pantalla*, y es contra ella que se escriben los tests de la tarea 3.
>
> **Lo que le falta a `001` no bloquea.** La mitad derecha de la barra —`Usuario: {nombre completo}`
> y `Cerrar sesión`— está **explícitamente fuera de alcance** de esta spec: la primera ya está
> dibujada y la segunda es la tarea 14 de `001`. Ninguna tarea de acá la construye; aparece en el
> Detalle sola, porque las dos pantallas dibujan el mismo `Header`.
>
> **Las props nuevas son opcionales, y eso es lo que mantiene verde a `001`.** `pages/MyActions.tsx`
> sigue llamando `<Header title="Mis Acciones" />` sin cambios, y `frontend/tests/Header.test.tsx`
> —firmado en `001`— tiene que seguir pasando tal como se firmó. Un test firmado no se reescribe
> (Artículo VI): si esta feature lo pone en rojo, la que está mal es esta feature.
>
> **Ninguna de las 23 tareas de acá construye alcance pendiente de `001` ni de `002`**, con dos
> excepciones declaradas, que son ampliaciones y no deudas ajenas: la tarea 6 agrega `is_favorite`
> al módulo `favorites` —la lectura cruzada que el plan justifica en *Contrato entre módulos*— y la
> tarea 9 le agrega a `components/Header.tsx` las dos props opcionales de arriba. Las dos son
> superficie nueva que esta feature necesita, no trabajo que otra spec dejó a medias.

## Orden

<!-- Las tareas se agrupan por historia de usuario, en orden de prioridad, para que al terminar H1 haya algo entregable de verdad. -->

### H1 — Ver el gráfico de una acción *(prioridad más alta)*

Al terminar H1 el cliente entra a `Mis Acciones`, activa `TSLA`, lee `TSLA - Tesla Inc - USD`,
elige `5min`, aprieta `Graficar` y ve el gráfico del día. Es la pantalla del enunciado andando: lo
que falta después es que se mantenga sola (H2), el período pasado (H3) y los avisos (H4).

| # | Tarea | Skill | Rol | Cubre |
|---|-------|-------|-----|-------|
| 1 | **Volver a capturar el JSON fijado de la serie temporal.** Una llamada a mano con la API key, con los parámetros que la tarea 5 va a mandar —la serie en UTC y el `outputsize` al máximo del plan—, guardada sin editar en `tests/fixtures/twelvedata/time_series_tsla_1min.json`. Se anota en `tests/fixtures/twelvedata/README.md` qué se pidió y cuándo, como el resto de los fixtures. El viejo describe un proveedor al que ya no se le pide lo mismo. | `add_integration` | Developer | — *(ver nota)* |
| 2 | **Tests de backend de H1, en rojo.** **El proveedor y el huso**, que es el bug más caro y el más silencioso: contra el fixture nuevo, el **instante exacto** de la primera y la última vela —no que haya velas—, y que la ventana que se le manda viaje en el mismo huso en el que contesta. Suma a `test_market_data_provider.py`. **La cuota** (`RF-24`, `RF-25`), con un `FakeProvider` que cuenta llamadas y ventanas: dos pedidos del mismo símbolo e intervalo dentro de un TTL → **una** llamada; N pedidos **lanzados en paralelo de verdad** → una sola; un símbolo sin datos que no se vuelve a preguntar hasta que pasa un TTL, aunque se pida diez veces. **El upsert de la vela abierta**: el mismo instante traído dos veces con distinto cierre deja **una** fila y el cierre **nuevo**. **La ventana que elige el service**: con rueda de hoy guardada pide `[última vela, ahora]`; con la caché fría, `[ahora − REALTIME_LOOKBACK, ahora]`. **`session_date` y la medianoche**: una rueda que en UTC cruza el día sigue siendo **un** día en hora de mercado (`RF-36`). **El aislamiento** (`RF-35`, Artículo III): el token de `ana` pidiendo el gráfico de un símbolo que sólo tiene `juan` responde **404** y **no llama al proveedor** — va en `test_user_isolation.py`. Y que ningún cuerpo, ningún `status` y ningún log nombren al proveedor (`RF-26`). `TestRoutesDeclareAuthorization` suma una ruta y **`PUBLIC_ROUTES` no suma ninguna**. | `add_tests` | Tester | RF-13, RF-15, RF-24, RF-25, RF-26, RF-35, RF-36 |
| 3 | **Tests de frontend de H1, en rojo.** La pantalla contra `wireframes/03-detalle-accion.png`. **La cabecera es el `Header` de `001` con sus props nuevas**, y los tests se escriben contra la firma que fija `plan.md` → *Frontend — estructura y contrato de pantalla*: **una sola barra**, con el enlace `Mis Acciones` a la izquierda del título (`RF-34`), `{símbolo} - {nombre} - {moneda}` armado con lo que devuelve `listFavorites()` (`RF-01`) y `Horarios en hora del mercado.` debajo del título (`RF-37`). El Detalle **no dibuja una segunda barra**: `Usuario: {nombre completo}` aparece **una** vez en la pantalla, y el enlace de vuelta es un `link` accesible por su rol, no un `<span>` con `onClick`. Los dos radios excluyentes con `Tiempo Real` marcado al abrir (`RF-03`, `RF-04`); el selector con **exactamente** `1min`, `5min` y `15min` y **vacío** al abrir (`RF-06`, `RF-07`); el botón `Graficar` (`RF-11`); y que antes de apretarlo **no haya ni gráfico ni un área de gráfico vacía** (`RF-12`). `Graficar` sin elegir intervalo muestra `Elegí un intervalo.` debajo del selector (`RF-39`), **no dispara ningún pedido** —ni a nuestra API y por lo tanto tampoco al proveedor (`RF-47`)—, **no dibuja ningún gráfico nuevo** (`RF-46`) y, con un gráfico ya a la vista, **lo deja intacto**: el mismo nodo y los mismos puntos (`RF-48`). Es el mismo invariante que la tarea 14 verifica para las tres fallas del rango; acá se verifica el cuarto caso inválido, el único que es de H1. Graficar dos veces con distinto intervalo deja **un** gráfico, el nuevo (`RF-17`). El gráfico: título `{símbolo}`, eje vertical `Cotización`, eje horizontal `Intervalo` (`RF-14`), los puntos en orden y en su hora **de mercado** (`RF-15`, `RF-36`), el tooltip con las **dos** horas (`RF-38`), y **apagados** el zoom, la selección de rango, el menú de exportar y el crédito del pie, que Highcharts trae encendidos y la spec deja fuera (`UI-01`). Un símbolo que no está en la lista propia lleva a `Mis Acciones` (`RF-35`); la ruta sin sesión cae en `/login`, en `session.test.tsx` (`RF-02`). `copy.test.ts` suma a su `REQUIRED` —que es una lista de pares *(sección, elemento)*, no de textos— nueve filas de *Detalle de Acción*: `Cabecera (izquierda)`, `Radio 1`, `Aclaración del radio 1`, `Radio 2`, `Etiqueta intervalo`, `Aclaración del intervalo`, `Botón`, `Eje Y` y `Eje X` —**ojo con las dos aclaraciones entre paréntesis: llevan `opcion` y `segun` sin tilde a propósito** (`RF-05`, `RF-08`)— y las **tres primeras** de *Detalle: navegación, horarios y validación*: `Volver a la lista`, `Aclaración de horarios` e `Intervalo sin elegir`. **No entran** `Usuario (cabecera, derecha)` ni `Cierre de sesión (cabecera, derecha)`: son de `001`, esta spec las deja fuera de alcance y `REQUIRED` ya las pide desde sus propias secciones —pedir el mismo literal dos veces falla dos tests por una sola palabra que falta—. Tampoco `Placeholder desde` ni `Placeholder hasta`, que son del `Histórico` y entran en la tarea 14, ni `Título del gráfico`, cuyo texto es sólo el placeholder `{símbolo}` y no deja ningún literal que buscar en el fuente. | `add_tests` | Tester | RF-01…RF-08, RF-11, RF-12, RF-14, RF-15, RF-17, RF-34, RF-35, RF-36, RF-37, RF-38, RF-39, RF-46, RF-47, RF-48 |
| 3b | **El unitario de `quotes/market.ts`, en rojo.** *(Agregada el 2026-09-14, por decisión del humano.)* Los tres requisitos del huso —cada cotización en el momento que le corresponde (`RF-15`), todas las horas de la pantalla en hora de mercado (`RF-36`) y el tooltip con las dos horas (`RF-38`)— **no se pueden testear desde la pantalla**: jsdom no calcula layout de SVG, así que de un gráfico de Highcharts sólo se lee texto e identidad de nodo, y el `formatter` del tooltip ni siquiera se dispara. Por eso la tarea 3 los dejó sin cubrir y por eso se volvió a `/plan`: la sección *Frontend — estructura y contrato de pantalla* ahora fija las firmas de `MARKET_TIME_ZONE`, `LOCAL_TIME_ZONE`, `INTERVAL_MS`, `formatMarket()`, `formatLocal()`, `marketFieldValue()`, `defaultHistoricRange()` y `tooltipTimeLines()` con sus valores esperados carácter por carácter. El test los afirma contra **dos** instantes, uno de septiembre y uno de enero: es el segundo el que distingue una conversión real de un `+ 4 horas` escrito a mano, que es la forma que este bug toma siempre. Y ningún caso puede depender de la zona de la máquina que corre la suite — se verifica corriéndola con dos `TZ` distintas. | `add_tests` | Tester | RF-15, RF-36, RF-38 |
| 4 | 🚦 **Firma de los tests de H1.** Sin esto, la tarea 5 no arranca (Artículo VI). | `approve_tests` | Tester *(firma el humano)* | — |
| 5 | **El proveedor, corregido.** En `app/providers/twelvedata.py`, dos cambios en la llamada de `get_time_series` y nada más: la serie **se pide en UTC** —lo que arregla de paso que el `start_date`/`end_date` que mandamos se interprete en el mismo huso que lo que nos devuelve— y el `outputsize` explícito al máximo del plan, porque el valor por omisión son 30 velas y una rueda a `1min` tiene 390. `providers/base.py` **no se toca**: el contrato de `ADR-006` alcanza tal como está firmado. `providers/fake.py` tampoco. | `add_integration` | Developer | RF-15, RF-36 |
| 6 | **`favorites` aprende a responder quién es dueño de qué.** `repository.py` → un `SELECT` de existencia con el `user_id` como **primer argumento** y en el `WHERE`; `service.py` → `is_favorite(session, user_id, symbol) -> bool`, con la misma normalización a mayúsculas que el alta; y el `__all__` pasa de `["router"]` a `["router", "is_favorite"]`. `models.py`, `router.py` e `io.py` **no se tocan**. Es la única lectura cruzada nueva de la feature, y el inventario de `ARCHITECTURE.md` ya la contempla. | `add_backend_feature` | Developer | RF-35 |
| 7 | **Nace `quotes`: la serie, la vigencia y la compuerta.** De adentro hacia afuera. `repository.py` → `candles_in`, `newest_ts` y `save` con `ON CONFLICT DO UPDATE` —datos, nunca decisiones—. `service.py` → `MARKET_TIMEZONE`, `REALTIME_LOOKBACK`, `get_series(...) -> QuoteSeries`, las dataclasses frozen `QuoteSeries` y `QuoteCandle`, la autorización con `is_favorite` **por el paquete**, la ventana de hoy en hora de mercado, la regla de vigencia (TTL = el intervalo) y la **compuerta por `(símbolo, intervalo)`** —candado más registro del último intento, con lo privado del archivo en `_GATES` y `_gate_for`—. Ninguna `ProviderError` escapa: se atrapa, se loguea y se contesta con lo que haya en la base (`ERR-01`, `ERR-05`). `io.py` → el schema de respuesta con los **cuatro** valores de `status` ya declarados y el precio como string. `router.py` → `GET /api/quotes/{symbol}` protegida, con `SessionDep` de `app.db`, `get_current_user` de `app.security` y el proveedor por dependencia. `__all__ = ["router"]`, y en `main.py` el `include_router`. Se incrementan las métricas que ya existen en `app/observability.py` —`QUOTE_CACHE_HITS`, `QUOTE_CACHE_MISSES`, `PROVIDER_REQUESTS`, `PROVIDER_QUOTA_REMAINING`—: se incrementan, **no se crean**. | `add_backend_feature` | Developer | RF-13, RF-15, RF-24, RF-25, RF-26, RF-35, RF-36 |
| 8 | **Highcharts y el gráfico.** `npm install highcharts` con su lockfile en el mismo commit (`DEP-01`), y **sin** `highcharts-react-official`: lo que esta pantalla necesita son veinte líneas de `useRef` más `useEffect`. `make types`. `src/quotes/market.ts` → `MARKET_TIME_ZONE`, `LOCAL_TIME_ZONE`, `INTERVAL_MS`, `formatMarket()` y `formatLocal()`. `api/quotes.ts` → `getQuotes(symbol, interval, range?)`. `components/QuoteChart.tsx` → título, los dos ejes, una sola serie de línea, eje horizontal `datetime` con `time.timezone = MARKET_TIME_ZONE`, el tooltip con las dos horas en mono tabular (`UI-04`), y **apagados explícitamente** el zoom, la selección de rango, el menú de exportar y el crédito. Sin colores literales: todo sale del `@theme` de `tokens.css` (`UI-03`). | `add_frontend_feature` | Developer | RF-14, RF-15, RF-36, RF-38 |
| 9 | **La pantalla del Detalle, y las props nuevas de la cabecera.** `components/Header.tsx` suma `back` y `note`, las **dos opcionales**, con la firma que fija `plan.md`: sigue siendo el dueño del layout de la barra —dónde cae el enlace respecto del título, dónde la aclaración— y `pages/MyActions.tsx` no se toca. `pages/ActionDetail.tsx` deja de ser el cascarón de `002` y sólo **declara qué va en cada lugar**: le pasa al `Header` el título `{símbolo} - {nombre} - {moneda}`, el `back` al enlace `Mis Acciones` y el `note` con `Horarios en hora del mercado.`; no dibuja ninguna barra propia. Después, los dos radios; el selector de intervalo vacío; `Graficar`; el estado (`favorite`, `mode`, `interval`, `plotted`, `series`, `errors`); la validación de **presencia** del intervalo, que no llega a ser un request (`RF-39`) y que por eso mismo no grafica nada nuevo (`RF-46`), no consulta nada afuera (`RF-47`) y deja el gráfico anterior como está (`RF-48`); y `<QuoteChart key={plotKey} …/>` con `plotKey` armado de `símbolo|modo|intervalo|desde|hasta`, que **cambia sólo al apretar `Graficar`** (`RF-17`). La cabecera y la pertenencia salen del **mismo** `listFavorites()`; si el símbolo no está, se vuelve a `Mis Acciones` (`RF-35`). Mientras carga no se dibuja ni cabecera ni controles (`TS-06`). `App.tsx` **no cambia**: la ruta ya existe desde `002`. `Cerrar sesión` **no se construye acá**: es la tarea 14 de `001`. | `add_frontend_feature` | Developer | RF-01…RF-08, RF-11, RF-12, RF-17, RF-34, RF-35, RF-37, RF-39, RF-46, RF-47, RF-48 |

### H2 — Que el gráfico se mantenga solo

H2 no toca el backend: la ventana barata del refresco —`[última vela, ahora]`— ya la decide el
service desde la tarea 7, y sus tests ya se firmaron en la tarea 2. Lo que falta es quién la pide.

| # | Tarea | Skill | Rol | Cubre |
|---|-------|-------|-----|-------|
| 10 | **Tests de frontend de H2, en rojo.** Con un gráfico de `Tiempo Real` a la vista y los temporizadores controlados por el test, pasado un intervalo sale **un** pedido y el gráfico suma el punto nuevo (`RF-18`). El que importa: el refresco **no remonta el nodo del gráfico** —se compara la referencia del nodo antes y después, que es lo que distingue un `setData` de un remontaje que "anda" y parpadea (`RF-19`)—, y los puntos que ya estaban **siguen ahí** (`RF-20`). Esconder la pestaña detiene los pedidos y no acumula puntos durante varios intervalos (`RF-21`); volver dispara **un pedido inmediato** y vuelve a armar el temporizador (`RF-22`). El `unmount` limpia el intervalo, y cambiar de intervalo con un pedido en vuelo no deja que la respuesta vieja pise a la nueva. | `add_tests` | Tester | RF-18, RF-19, RF-20, RF-21, RF-22 |
| 11 | 🚦 **Firma de los tests de H2.** | `approve_tests` | Tester *(firma el humano)* | — |
| 12 | **El polling.** En `ActionDetail.tsx`: `setInterval` con `INTERVAL_MS[interval]`, armado **sólo** en `Tiempo Real` y **sólo** con un gráfico a la vista; el refresco cambia `points` con la misma `key`, así que `QuoteChart.tsx` llama a `setData` sobre el gráfico que ya existe (`RF-19`); `visibilitychange` que limpia el temporizador al esconderse la pestaña y al volver hace un pedido inmediato antes de rearmarlo (`RF-21`, `RF-22` — y el Artículo II: una pestaña olvidada renovando el TTL de su símbolo toda la rueda es cuota gastada por nadie); limpieza en el `unmount` y un `AbortController` por pedido que cancela al anterior. | `add_frontend_feature` | Developer | RF-18, RF-19, RF-20, RF-21, RF-22 |

### H3 — Consultar un período pasado

| # | Tarea | Skill | Rol | Cubre |
|---|-------|-------|-----|-------|
| 13 | **Tests de backend de H3, en rojo.** `GET /api/quotes/{symbol}` con `from`/`to`: la serie devuelta cae **entera** adentro de la ventana pedida —el primer punto no anterior a `from` ni el último posterior a `to`— y `from`/`to` se interpretan en **hora de mercado**, no en la del servidor (`RF-16`, `RF-36`). La validación: `from == to` y `from > to` → **422** `range_invalid` (`RF-41`); 7 días a `1min` grafica y 8 no, 30 a `5min` sí y 31 no, 90 a `15min` sí y 91 no (`RF-42`…`RF-44`), con `interval` y `max_days` en el cuerpo del 422 (`RF-45`). **En los cuatro casos inválidos, cero llamadas al proveedor y ninguna lectura de la base** (`RF-47`): el 422 se decide antes de todo lo demás. Un `from`/`to` a medias —uno sí y el otro no— también se rechaza. Y una ventana cerrada en el pasado que ya está en la base **no vuelve a salir al proveedor**: los precios de ayer no vencen. | `add_tests` | Tester | RF-16, RF-36, RF-41, RF-42, RF-43, RF-44, RF-45, RF-47 |
| 14 | **Tests de frontend de H3, en rojo.** Los dos campos con los textos de ayuda `Fecha hora desde` y `Fecha hora hasta` (`RF-09`), ya cargados al abrir con las últimas 24 horas **de mercado**, sin escribir nada (`RF-10`). `Graficar` con un campo vacío muestra `Completá este campo.` debajo de **ese** campo (`RF-40`); con las fechas al revés, `La fecha desde tiene que ser anterior a la fecha hasta.` debajo de los campos, armado a partir del `code` del 422 (`RF-41`); con el rango pasado de largo, `El rango es demasiado largo para el intervalo 1min. El máximo es 7 días.`, con `{intervalo}` y `{N}` rellenados desde el cuerpo de la respuesta (`RF-45`). En los cuatro casos **no aparece ningún gráfico nuevo** (`RF-46`) y, si ya había uno, **queda intacto** (`RF-48`). Con un gráfico de `Histórico` a la vista, avanzar los temporizadores varios intervalos **no arma ningún pedido** (`RF-23`). `copy.test.ts` suma las **dos últimas** filas de *Detalle: navegación, horarios y validación* —`Fechas al revés` y `Rango excedido`— más `Placeholder desde` y `Placeholder hasta` de *Detalle de Acción*, que son los dos textos que esta historia pone en pantalla. Las tres primeras de esa sección ya las pidió la tarea 3, y `Completá este campo.` ya está en `REQUIRED` desde `001` (*Sesión y validación*): ninguna se pide dos veces. Las dos plantillas se verifican contra su parte fija —el `REQUIRED` las parte en los bordes de `{intervalo}` y `{N}`— o contra el texto ya armado en el render, nunca pidiendo la plantilla entera en el fuente. | `add_tests` | Tester | RF-09, RF-10, RF-23, RF-40, RF-41, RF-45, RF-46, RF-48 |
| 15 | 🚦 **Firma de los tests de H3.** | `approve_tests` | Tester *(firma el humano)* | — |
| 16 | **El `Histórico` en el backend.** `app/errors.py` → `QuoteRangeInvalid` y `QuoteRangeTooLong`, hijas de `DomainError` y **sin `fastapi` adentro**, por la misma razón que `UnknownSymbolError`: `main.py` las importa para registrar el handler. En `quotes/service.py` → `MAX_RANGE_DAYS = {"1min": 7, "5min": 30, "15min": 90}`, la validación **antes de mirar la base y antes de cualquier llamada al proveedor** (`RF-47`), y la ventana histórica localizada en `MARKET_TIMEZONE` y pasada a UTC; una ventana cerrada en el pasado con velas guardadas no vence. `io.py` y `router.py` → `from`/`to` como `datetime` naive opcionales, **los dos o ninguno**. En `main.py`, los dos handlers → **422** con `{"code": "range_invalid"}` y `{"code": "range_too_long", "interval": …, "max_days": …}`. Los topes viven **sólo acá**: no se copian al navegador. `make types`. | `add_backend_feature` | Developer | RF-16, RF-41, RF-42, RF-43, RF-44, RF-45, RF-46, RF-47 |
| 17 | **El modo `Histórico` en la pantalla.** `quotes/market.ts` → `defaultHistoricRange()`, las últimas 24 horas **en hora de mercado**. En `ActionDetail.tsx`: los dos campos con su estado `from`/`to` precargado (`RF-09`, `RF-10`), la validación de **presencia** en el navegador —un campo vacío no llega a ser un request (`RF-40`)—, el mapeo de `range_invalid` y `range_too_long` a los textos de `COPY.md` rellenando `{intervalo}` y `{N}` con lo que trae el cuerpo (`RF-41`, `RF-45`), y en los cuatro casos inválidos **no se toca `plotted`**, así que el gráfico anterior queda como está (`RF-46`, `RF-48`). En `Histórico` **no se arma ningún temporizador** (`RF-23`). `api/quotes.ts` acepta el rango opcional y lo manda tal como el usuario lo escribió: la zona se la pone el backend. | `add_frontend_feature` | Developer | RF-09, RF-10, RF-16, RF-23, RF-40, RF-41, RF-45, RF-46, RF-48 |

### H4 — Entender qué estoy viendo cuando no hay datos de hoy

*(Confirmado por el humano, 2026-09-13.)* La tarea 7 dejó el enum de `status` declarado en el
contrato y el service devolviendo `ok` cuando hay puntos y `no_data` cuando no hay ninguno —y ya atrapando toda `ProviderError`, porque `ERR-05`
es Blocker y no espera a H4—. Lo que falta acá es **la precedencia completa** y los dos estados que
todavía nadie devuelve.

| # | Tarea | Skill | Rol | Cubre |
|---|-------|-------|-----|-------|
| 18 | **Tests de backend de H4, en rojo.** Los cuatro estados y **su orden**, que es donde un `if` mal ordenado miente en pantalla: el proveedor levanta `ProviderQuotaExceeded` con caché tibia → `stale`, **nunca** `market_closed` (no sabemos si el mercado está cerrado o si el proveedor no contesta, y decir lo segundo sería inventar); hoy sin velas pero con una rueda anterior guardada → `market_closed`, y el gráfico trae **esa rueda** (`RF-27`) con su `session_date` **en hora de mercado** —el caso del sábado, y el de la rueda que en UTC cruza la medianoche—; nada en ningún lado → `no_data` (`RF-31`); datos frescos → `ok` **sin aviso** (`RF-32`). Los cuatro con **200** (`ERR-05`) y ninguno nombrando al proveedor (`RF-26`). `ProviderUnavailable`, `ProviderRejectedCredentials` y `SymbolNotFound` tampoco escapan, y **ninguna se atrapa en silencio** (`ERR-01`). | `add_tests` | Tester | RF-27, RF-28, RF-29, RF-30, RF-31, RF-32 |
| 19 | **Tests de frontend de H4, en rojo.** Los tres avisos, con el texto verbatim de `COPY.md` y **arriba** del gráfico, nunca al pie (`UI-05`): `market_closed` con la fecha de la rueda adentro del texto (`RF-28`), `stale` (`RF-30`) y `no_data` con el símbolo adentro (`RF-31`). `ok` **no dibuja ninguno** (`RF-32`). Y el invariante: en los cuatro estados la pantalla muestra un gráfico, un aviso, o los dos — **nunca ninguno de los dos** (`RF-33`). `copy.test.ts` suma las **tres** filas de *Avisos de estado* que tienen literal —`stale`, `market_closed` y `no_data`—, con las dos plantillas verificadas contra su parte fija o contra el texto ya armado. La cuarta fila, la de `ok`, dice *(sin aviso)* y **no lleva ningún texto entre backticks**: el parser de `copy.test.ts` descarta las filas sin literal, así que pedirla levanta una excepción por una fila que para el test no existe. Que `ok` no dibuje aviso se verifica en pantalla (`RF-32`), que es donde se puede verificar. | `add_tests` | Tester | RF-28, RF-30, RF-31, RF-32, RF-33 |
| 20 | 🚦 **Firma de los tests de H4.** | `approve_tests` | Tester *(firma el humano)* | — |
| 21 | **Los cuatro estados en el service.** En `quotes/service.py`, `_status_of` con la precedencia explícita —proveedor que falló → `stale`; ventana vacía con rueda anterior guardada → `market_closed` más su `session_date`; nada en ningún lado → `no_data`; si no → `ok`— y la caída a la última rueda disponible cuando hoy no tiene velas (`RF-27`), que es lo que la ventana de `[ahora − REALTIME_LOOKBACK, ahora]` ya trajo a la base. `session_date` se calcula en `MARKET_TIMEZONE` y viaja sólo con `market_closed`. Cada `except` loguea el símbolo, el intervalo, la ventana y el resultado (`ERR-07`) sin nombrar al proveedor hacia afuera (`RF-26`). | `add_backend_feature` | Developer | RF-27, RF-28, RF-29, RF-30, RF-31, RF-32 |
| 22 | **El aviso, arriba del gráfico.** `components/Notice.tsx` con los textos de `COPY.md` y sus dos plantillas —`{fecha}` en hora de mercado, `{símbolo}`—, montado **antes** que `QuoteChart` en el árbol (`UI-05`); `ok` no lo monta (`RF-32`). En `ActionDetail.tsx`, el `status` de la respuesta decide qué se dibuja, y ninguna combinación deja la pantalla sin gráfico **y** sin aviso (`RF-33`). Sin colores literales: el aviso sale del `@theme` de `tokens.css` (`UI-03`). | `add_frontend_feature` | Developer | RF-28, RF-30, RF-31, RF-32, RF-33 |

### Cierre de la feature

| # | Tarea | Skill | Rol | Cubre |
|---|-------|-------|-----|-------|
| 23 | **`ARCHITECTURE.md` al día.** `quotes` deja de ser un módulo con sólo `models.py`: se documenta su anatomía completa —`router.py`, `io.py`, `service.py`, `repository.py`— y su `__all__ = ["router"]`; el de `favorites` pasa a `["router", "is_favorite"]`; y en el árbol del frontend entran `src/quotes/` —con la justificación que el plan ya escribió: el poco dominio que comparten la pantalla, el componente y la llamada a la API— más `components/QuoteChart.tsx`, `components/Notice.tsx` y `api/quotes.ts`. El **inventario de lecturas cruzadas** ya quedó corregido el 2026-09-13 con `is_favorite`: sólo hay que verificar que siga diciendo la verdad. | `add_backend_feature` | Backend-Arch · Frontend-Arch | — *(ver nota)* |

<!--
  La columna Test de la tabla de trazabilidad de docs/PROJECT_BRIEF.md (REQ-12…REQ-17, NFR-02,
  NFR-04, NFR-05) NO es una tarea de acá: la completa `ship_changes` en el mismo commit que
  archiva la spec, que es lo que evita que la tabla quede vieja (docs/specs/README.md → Al entregar).
-->

### Las seis tareas que no cubren ningún `RF`, y por qué no es alcance de más

- **La 1 es un dato, no una funcionalidad.** Volver a capturar el JSON fijado no cambia nada de lo
  que el usuario ve: cambia lo que el repositorio cree que contesta el proveedor. Sin ella, el test
  del huso de la tarea 2 no se puede escribir contra nada real, y `TEST-03` prohíbe editar un
  fixture a mano.
- **Las cuatro firmas —la 4, la 11, la 15 y la 20— son el gate del Artículo VI**, no trabajo: son
  el momento en que el humano firma qué significa "terminado" para esa historia.
- **La 23 es documentación.** `ARCHITECTURE.md` describe hoy un `quotes` que sólo tiene tablas; si
  no se corrige, el próximo que lea la arquitectura la va a leer mal.

**Si alguna de estas terminara cambiando una pantalla o un mensaje, deja de ser mecanismo y vuelve
a la spec.**

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
| RF-01 | 3, 9 | `frontend/tests/ActionDetail.test.tsx` |
| RF-02 | 3, 9 | `frontend/tests/session.test.tsx` |
| RF-03 | 3, 9 | `frontend/tests/ActionDetail.test.tsx` |
| RF-04 | 3, 9 | `frontend/tests/ActionDetail.test.tsx` |
| RF-05 | 3, 9 | `frontend/tests/copy.test.ts` · `frontend/tests/ActionDetail.test.tsx` |
| RF-06 | 3, 9 | `frontend/tests/ActionDetail.test.tsx` |
| RF-07 | 3, 9 | `frontend/tests/ActionDetail.test.tsx` |
| RF-08 | 3, 9 | `frontend/tests/copy.test.ts` · `frontend/tests/ActionDetail.test.tsx` |
| RF-09 | 14, 17 | `frontend/tests/ActionDetail.test.tsx` · `frontend/tests/copy.test.ts` |
| RF-10 | 14, 17 | `frontend/tests/ActionDetail.test.tsx` |
| RF-11 | 3, 9 | `frontend/tests/copy.test.ts` · `frontend/tests/ActionDetail.test.tsx` |
| RF-12 | 3, 9 | `frontend/tests/ActionDetail.test.tsx` |
| RF-13 | 2, 7, 8, 9 | `backend/tests/integration/test_quotes.py` · `frontend/tests/ActionDetail.test.tsx` |
| RF-14 | 3, 8 | `frontend/tests/QuoteChart.test.tsx` · `frontend/tests/copy.test.ts` |
| RF-15 | 2, 3, 5, 8 | `backend/tests/unit/test_market_data_provider.py` · `frontend/tests/QuoteChart.test.tsx` |
| RF-16 | 13, 14, 16, 17 | `backend/tests/integration/test_quotes.py` · `frontend/tests/ActionDetail.test.tsx` |
| RF-17 | 3, 9 | `frontend/tests/ActionDetail.test.tsx` |
| RF-18 | 10, 12 | `frontend/tests/ActionDetail.test.tsx` |
| RF-19 | 10, 12 | `frontend/tests/ActionDetail.test.tsx` |
| RF-20 | 10, 12 | `frontend/tests/ActionDetail.test.tsx` |
| RF-21 | 10, 12 | `frontend/tests/ActionDetail.test.tsx` |
| RF-22 | 10, 12 | `frontend/tests/ActionDetail.test.tsx` |
| RF-23 | 14, 17 | `frontend/tests/ActionDetail.test.tsx` |
| RF-24 | 2, 7 | `backend/tests/unit/test_quotes_service.py` · `backend/tests/integration/test_quotes.py` |
| RF-25 | 2, 7 | `backend/tests/unit/test_quotes_service.py` · `backend/tests/integration/test_quotes.py` |
| RF-26 | 2, 7 | `backend/tests/integration/test_quotes.py` · `backend/tests/architecture/test_provider_boundary.py` |
| RF-27 | 18, 21 | `backend/tests/unit/test_quotes_service.py` |
| RF-28 | 18, 19, 21, 22 | `backend/tests/unit/test_quotes_service.py` · `frontend/tests/Notice.test.tsx` · `frontend/tests/copy.test.ts` |
| RF-29 | 18, 21 | `backend/tests/unit/test_quotes_service.py` |
| RF-30 | 19, 22 | `frontend/tests/Notice.test.tsx` · `frontend/tests/copy.test.ts` |
| RF-31 | 18, 19, 21, 22 | `backend/tests/unit/test_quotes_service.py` · `frontend/tests/Notice.test.tsx` · `frontend/tests/copy.test.ts` |
| RF-32 | 18, 19, 21, 22 | `backend/tests/unit/test_quotes_service.py` · `frontend/tests/Notice.test.tsx` |
| RF-33 | 19, 22 | `frontend/tests/Notice.test.tsx` |
| RF-34 | 3, 9 | `frontend/tests/ActionDetail.test.tsx` · `frontend/tests/copy.test.ts` |
| RF-35 | 2, 3, 6, 7, 9 | `backend/tests/integration/test_user_isolation.py` · `frontend/tests/ActionDetail.test.tsx` |
| RF-36 | 2, 3, 5, 7, 8, 13, 16 | `backend/tests/unit/test_quotes_service.py` · `backend/tests/unit/test_market_data_provider.py` · `frontend/tests/QuoteChart.test.tsx` |
| RF-37 | 3, 9 | `frontend/tests/ActionDetail.test.tsx` · `frontend/tests/copy.test.ts` |
| RF-38 | 3, 8 | `frontend/tests/QuoteChart.test.tsx` |
| RF-39 | 3, 9 | `frontend/tests/ActionDetail.test.tsx` · `frontend/tests/copy.test.ts` |
| RF-40 | 14, 17 | `frontend/tests/ActionDetail.test.tsx` · `frontend/tests/copy.test.ts` |
| RF-41 | 13, 14, 16, 17 | `backend/tests/integration/test_quotes.py` · `frontend/tests/ActionDetail.test.tsx` · `frontend/tests/copy.test.ts` |
| RF-42 | 13, 16 | `backend/tests/integration/test_quotes.py` |
| RF-43 | 13, 16 | `backend/tests/integration/test_quotes.py` |
| RF-44 | 13, 16 | `backend/tests/integration/test_quotes.py` |
| RF-45 | 13, 14, 16, 17 | `backend/tests/integration/test_quotes.py` · `frontend/tests/ActionDetail.test.tsx` · `frontend/tests/copy.test.ts` |
| RF-46 | 3, 9, 14, 16, 17 | `frontend/tests/ActionDetail.test.tsx` |
| RF-47 | 3, 9, 13, 16 | `backend/tests/integration/test_quotes.py` · `frontend/tests/ActionDetail.test.tsx` |
| RF-48 | 3, 9, 14, 17 | `frontend/tests/ActionDetail.test.tsx` |

**Ninguna fila quedó sin tarea y ninguna sin test.** Tres aclaraciones sobre filas que podrían
leerse como huecos:

- **`RF-15` y `RF-36` se verifican en las dos puntas, y a propósito.** El huso es el bug más caro
  de esta feature porque no rompe nada: el gráfico entero se corre cuatro o cinco horas y todo
  sigue "andando". En backend se verifica el **instante exacto** de la primera y la última vela
  contra el JSON fijado; en frontend, que el eje rotule en hora de mercado y no en la del reloj de
  la computadora. Ninguno de los dos prueba lo del otro.

- **`RF-24`, `RF-25` y `RF-47` son el Artículo II**, y son lo que esta feature existe para
  demostrar. Los tres se prueban contando llamadas en un `FakeProvider`, nunca saliendo a la red
  (`TEST-03`). `RF-25` es el único que exige concurrencia **de verdad** —N pedidos lanzados en
  paralelo, no en secuencia—: en secuencia lo aprueba hasta un TTL sin compuerta.

- **`RF-32` aparece en las dos historias de estados y no es repetición.** En backend se verifica
  que el service devuelva `ok`; en frontend, que `ok` **no dibuje ningún aviso**. Un `ok` que
  igual pinta un cartel es exactamente la clase de error que sólo se ve en pantalla.
