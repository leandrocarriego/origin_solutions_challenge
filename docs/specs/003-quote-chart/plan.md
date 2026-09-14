# Detalle de Acción y gráfico de cotizaciones — Plan técnico

<!--
  ARTEFACTO INTERNO. Acá van las decisiones técnicas que spec.md no puede llevar.
  No se exporta al cliente.
-->

**Feature:** `003-quote-chart` · **Spec aprobada el:** 2026-09-13 · **Fecha:** 2026-09-13

**Roles:** `Backend-Architect` + `Frontend-Architect` (feature full-stack, un solo plan).

> **Esta feature es la que el `ROADMAP` señala como la que concentra el riesgo**: la caché de
> cotizaciones y su TTL son la parte no trivial del backend y lo que demuestra los NFR. Depende de
> `002-favorite-stocks` —`UnknownSymbolError`, `GET /api/favorites`, el `Bearer` en `client.ts` y
> la ruta `/stocks/:symbol`— y de lo que todavía le falta a `001`. Qué asume y qué no, en *Riesgos*
> y en *Contexto de traspaso*. **No se adelanta nada de `001` ni de `002` acá.**

## Constitution Check

| Artículo | Cumple | Cómo |
|---|---|---|
| I — La credencial del proveedor vive sólo en el backend | ✅ | El frontend sigue hablando sólo con `/api`: el gráfico pide `GET /api/quotes/{symbol}` y nunca a `api.twelvedata.com`. Ninguna variable `VITE_*` nueva. El nombre del proveedor no aparece en ningún archivo nuevo, y los cuatro `status` viajan sin decir quién falló (`RF-26`). La credencial se sigue leyendo sólo en `app/settings.py`. |
| II — La cuota es finita, y eso es parte del diseño | ✅ | **Es el artículo que esta feature existe para cumplir.** El navegador no llama nunca al proveedor: hace polling contra **nuestra** API, que resuelve contra la tabla `quotes` y sólo sale al mundo cuando el dato pedido no está o venció (TTL = el intervalo, `ADR-003`). Una **compuerta por `(símbolo, intervalo)`** —candado más registro del último intento— hace que diez navegadores mirando `TSLA` a `5min` cuesten exactamente lo mismo que uno (`RF-25`), y que un día sin rueda no se pague dos veces. El polling se corta cuando la pestaña deja de verse y se reanuda al volver (`RF-21`, `RF-22`). Nada se consulta hasta que el usuario aprieta `Graficar` (`RF-12`), y una consulta inválida no sale al mundo (`RF-47`). |
| III — Los datos de un usuario son de ese usuario | ✅ | `GET /api/quotes/{symbol}` toma el id del usuario de `get_current_user` y le pregunta al paquete `favorites` si ese símbolo es suyo; si no lo es responde 404 y el frontend vuelve a `Mis Acciones` (`RF-35`). El símbolo viaja en el path, que es el objeto y no la identidad: ninguna ruta acepta `user_id` por path, query ni body. Las cotizaciones en sí no son dato de usuario —la caché es compartida y ahí vive el Artículo II—, pero **a quién se le sirven sí lo es**. |
| IV — Las fronteras entre módulos son reales | ✅ | `quotes` nace completo —`router`, `service`, `repository`— y es el único dueño de la tabla `quotes`. Entra a `favorites` **por el paquete** (`from app.modules.favorites import is_favorite`) y a `stocks` no entra: los datos de la cabecera se los da al frontend `GET /api/favorites`, que ya existe. El service sale al mundo sólo por `MarketDataProvider` y nunca ve el JSON del proveedor. Adentro, el flujo va `router` → `service` → `repository` y los hermanos se importan por ruta completa. Ningún `relationship()` cruza. |
| V — Spec primero, y con firma | ✅ | `spec.md` está en `Aprobado`, firmada por Leandro Carriego el 2026-09-13. Este plan cubre `RF-01` a `RF-48` y **no agrega** ningún requisito: lo que la spec deja fuera —velas, volumen, zoom, comparar dos acciones, elegir huso— no aparece en ningún archivo de este plan. |
| VI — Lo que no está tipado y testeado no está terminado | ✅ | Todo tipado (`PY-04`, `TS-01`). Los tests los escribe el `Tester` **antes** y se firman por historia (`/approve-tests`). La suite sigue corriendo sin red y sin API key: el proveedor se ejercita contra JSON fijado en `tests/fixtures/twelvedata/`, y los caminos de caché, `stale`, `market_closed` y `no_data` se prueban con dobles determinísticos (`TEST-03`). |
| VII — El enunciado es el contrato, y sus ambigüedades se declaran | ✅ | Los textos son los literales de `COPY.md`, verbatim, faltas incluidas (`opcion`, `segun`), y la tercera aclaración del wireframe no se muestra. `A2` (tiempo real = polling según el intervalo), `A5` (última rueda con aviso), `A6` (rango por defecto y validación) y `A7` (cabecera) están resueltos en el brief y este plan los respeta. Los cinco textos que el enunciado no da ya están en `COPY.md` con su porqué. Nada que el enunciado no pida. **La enmienda del 2026-09-14 agrega dos textos más** —`Hora del mercado:` y `Hora de Argentina:`, las etiquetas del tooltip de `RF-38`, que el enunciado no escribe y sin las cuales dos horas seguidas no dicen cuál es cuál—: las eligió el cliente ese mismo día, sobre dos alternativas descartadas, y **ya están registradas en `COPY.md`** con su porqué. `UI-02` queda cerrado. |
| VIII — Un idioma para cada audiencia | ✅ | Código, commits y docstrings en inglés; este artefacto en español; los strings de pantalla en español y verbatim de `COPY.md`. Los `status` y los `code` de error son identificadores técnicos en inglés y **nadie los muestra**: la pantalla decide qué se lee. |
| IX — Las dependencias entran por la puerta | ✅ | **Dos dependencias nuevas, las dos justificadas abajo** (*Alternativas descartadas*): `highcharts` en el frontend, que es la que el enunciado nombra (`REQ-17`) y el brief fija en su *Stack*, y `tzdata` en el backend, para que `zoneinfo` tenga base de datos horaria adentro de una imagen `slim`. Entran con `npm install` y `uv add`, con su lockfile en el mismo commit. Ninguna otra. |
| X — Las decisiones de arquitectura las toma un humano | ✅ | Este plan **no agrega ningún ADR** ni toca los que hay, y **no cita ninguno en `Propuesta`**: se apoya en `ADR-001`, `ADR-003` y `ADR-006`, y en `ADR-005`, que el humano firmó el 2026-09-13 y es el que define los cuatro `status`. `ADR-007` y `ADR-009` no se citan. **No agrega ninguna tabla**: las cuatro de `ADR-001` alcanzan, y una quinta la firmaría un humano. Las decisiones de alcance local —la compuerta, el TTL, la forma del endpoint, la zona horaria como constante— viven acá, que es su lugar. |

**Excepciones solicitadas:** ninguna. **Enmienda del 2026-09-14** *(decidida por el humano, a pedido del `Tester`)*: se fijan las firmas de `src/quotes/market.ts`, que este plan nombraba sin declarar, para que `RF-15`, `RF-36` y `RF-38` tengan un test unitario posible. No cambia el alcance, no toca la spec y no agrega ningún ADR (Artículo X). El único artículo que roza es el VII, y queda anotado arriba.

> **El inventario de lecturas cruzadas del backend crece en un nombre** (`is_favorite`), que es el
> primero que se agrega desde que `ARCHITECTURE.md` lo escribió. **Ya está corregido** —el 2026-09-13,
> a pedido del humano— en `ARCHITECTURE.md`, `CONVENTIONS.md` (`GEN-02`), el rol
> `Backend-Architect`, el rol `Tester`, las skills `add_backend_feature`, `add_feature`,
> `add_tests`, `review_feature`, `converge` y `plan`, y en `plan.template.md`: son los documentos
> que declaran ese inventario como **completo**, y uno viejo haría que el `Code-Reviewer` marcara
> como hallazgo algo que este plan decidió.

## Enfoque

La feature es **un módulo nuevo, una pantalla nueva y un arreglo en el proveedor**.

**`quotes` nace completo** —`router.py`, `io.py`, `service.py`, `repository.py`— sobre la tabla que
la fase 0 ya creó, y es el único núcleo de decisión del proyecto: qué se puede servir de la base,
cuándo se sale al mundo, y qué se muestra cuando lo que hay no es lo que se esperaba. Una sola ruta
—`GET /api/quotes/{symbol}`— sirve los dos modos: sin `from`/`to` es la rueda de hoy (`Tiempo
Real`), con `from`/`to` es el período pedido (`Histórico`). No son dos endpoints porque no son dos
preguntas: es la misma serie con otra ventana, y el que decide qué ventana es "hoy" es el backend,
que es el único de los dos lados que sabe en qué huso vive el mercado.

**La cuota se cuida con una regla y una compuerta, y las dos son verificables.** La regla: la base
contesta cuando tiene el tramo pedido y ese tramo sigue vigente —para una ventana que llega al
presente, vigente significa que la vela más nueva tiene menos de un intervalo de antigüedad
(TTL = el intervalo, `ADR-003`); para una ventana cerrada en el pasado, los precios de ayer no
vencen nunca—. La compuerta: cuando la base **no** puede contestar, el llamado al proveedor pasa
por un candado por `(símbolo, intervalo)` que además anota cuándo fue el último intento. Diez
pedidos simultáneos del mismo símbolo producen **una** llamada y nueve esperas que después releen
la base; y un símbolo que no tiene datos —un domingo, un feriado— no se vuelve a preguntar hasta
que pasó un intervalo, aunque el usuario apriete `Graficar` veinte veces. Sin la compuerta, `RF-25`
es una aspiración: el TTL solo no coordina a dos requests que llegan en el mismo segundo.

**Lo que hay siempre se muestra, y se dice qué es.** El service devuelve la serie con un `status`
tipado —`ok`, `stale`, `market_closed`, `no_data`— y el endpoint responde **200 en los cuatro
casos** (`ERR-05`): un 429 del proveedor reenviado al navegador culparía a un usuario que no tiene
cuenta en ningún proveedor. La precedencia entre los estados es explícita y no ambigua: si la
llamada al proveedor **falló**, es `stale` —no sabemos si el mercado está cerrado o si el
proveedor no contesta, y decir "el mercado está cerrado" sería inventar—; si el proveedor
contestó (o no hizo falta llamarlo) y hoy no tiene ruedas pero hay una anterior guardada, es
`market_closed` con su fecha; si no hay nada en ningún lado, es `no_data`; si no, `ok`.

**Los horarios son los del mercado, y eso se decide una vez de cada lado.** El catálogo del
proyecto son NYSE y NASDAQ (`A4`), los dos en `America/New_York`: la zona del mercado es por lo
tanto una **constante del producto** y no una columna. El backend la usa para decidir qué día es
"hoy" y cuál fue la última rueda; el frontend la usa para rotular el eje, para llenar los dos
campos de fecha y para el tooltip, que muestra además la hora de Argentina (`RF-38`). En la base y
en la respuesta los instantes son **UTC con offset**, que es lo único que no se puede malinterpretar;
en los campos `from`/`to` de la consulta viaja **la hora de mercado tal como el usuario la escribió**,
y el backend le pone la zona. Cada lado del cable lleva lo que significa.

**Hay un arreglo de infraestructura que esta feature no puede esquivar.** Hoy
`app/providers/twelvedata.py` parsea el `datetime` del proveedor y le estampa UTC, pero el
proveedor lo manda en la hora del mercado: el JSON fijado del repositorio tiene
`"datetime": "2026-09-11 15:59:00"` con `"exchange_timezone": "America/New_York"`, que son las
19:59 UTC. Tal como está, cada punto del gráfico caería cuatro horas corrido y `RF-15` sería falso
sin que nada se rompa. Se corrige pidiéndole al proveedor la serie en UTC —un parámetro más en la
llamada, que además hace que el `start_date`/`end_date` que mandamos se interpreten en el mismo
huso que lo que nos devuelve— y de paso se fija el `outputsize`, porque el valor por omisión del
proveedor son **30 velas** y una rueda a `1min` tiene 390. Esto obliga a **volver a capturar** el
JSON fijado con los parámetros nuevos (`TEST-03`: el fixture es la respuesta real, sin editar).

### Dónde cae cada requisito

| RF | Dónde se resuelve |
|---|---|
| `RF-01`, `RF-34`, `RF-37` | `components/Header.tsx` — la barra ya existe desde `001` y suma **dos props opcionales**: el enlace de vuelta (`RF-34`) y la línea de aclaración debajo del título (`RF-37`). `pages/ActionDetail.tsx` sólo declara qué va en cada lugar: el título es `{símbolo} - {nombre} - {moneda}` (`RF-01`), armado con lo que devuelve `GET /api/favorites`. La firma exacta, en *Frontend — estructura y contrato de pantalla* |
| `RF-02` | `RequireSession` en `App.tsx`, que ya protege `/stocks/:symbol` desde `002` |
| `RF-03`, `RF-04`, `RF-05` | `ActionDetail.tsx` — los dos radios, `Tiempo Real` marcado al abrir, la aclaración verbatim |
| `RF-06`, `RF-07`, `RF-08` | `ActionDetail.tsx` — el `select` con las tres opciones y su opción vacía inicial |
| `RF-09`, `RF-10` | `ActionDetail.tsx` + `quotes/market.ts` → `defaultHistoricRange()`, las últimas 24 horas en hora de mercado |
| `RF-11`, `RF-12`, `RF-17` | `ActionDetail.tsx` — `Graficar` y el estado `plotted: PlotRequest | null`; la `key` del gráfico cambia sólo al graficar |
| `RF-13`, `RF-16` | `GET /api/quotes/{symbol}` (sin y con `from`/`to`) + `quotes/service.py` |
| `RF-14`, `RF-15` | `components/QuoteChart.tsx` — título, ejes y eje horizontal temporal en hora de mercado, con `time.timezone = MARKET_TIME_ZONE` de `quotes/market.ts`. Que la conversión sea la del mercado y no la de la máquina se testea en unidad sobre `formatMarket()`, porque el SVG no se puede leer en jsdom |
| `RF-18`, `RF-19`, `RF-20` | `ActionDetail.tsx` — `setInterval` con la duración del intervalo; el gráfico se actualiza con `setData`, sin remontarse |
| `RF-21`, `RF-22` | `ActionDetail.tsx` — `visibilitychange`: se detiene y se reanuda con un pedido inmediato |
| `RF-23` | `ActionDetail.tsx` — en `Histórico` no se arma ningún intervalo |
| `RF-24`, `RF-25` | `quotes/service.py` — la regla de vigencia y la compuerta por `(símbolo, intervalo)` |
| `RF-26` | El cuerpo de la API no nombra al proveedor; los `status` son genéricos |
| `RF-27`, `RF-28` | `quotes/service.py` → `market_closed` + `session_date`; `components/Notice.tsx` |
| `RF-29`, `RF-30` | `quotes/service.py` → `stale` cuando `ProviderError`; `Notice.tsx` |
| `RF-31` | `quotes/service.py` → `no_data`; `Notice.tsx` |
| `RF-32`, `RF-33` | `ActionDetail.tsx` — `ok` no dibuja aviso; los otros tres siempre dibujan uno |
| `RF-35` | `ActionDetail.tsx` (redirección a `/` si el símbolo no está en la lista) + 404 del backend |
| `RF-36` | `quotes/market.ts` en el frontend (`MARKET_TIME_ZONE`, `formatMarket()`, `marketFieldValue()`), `MARKET_TIMEZONE` en `quotes/service.py` en el backend |
| `RF-38` | `quotes/market.ts` → `tooltipTimeLines()` arma las dos líneas y es lo que se testea; `QuoteChart.tsx` sólo las une y las dibuja en el `tooltip` |
| `RF-39`, `RF-40` | `ActionDetail.tsx` — validación de presencia, que no llega a ser un request |
| `RF-41`, `RF-42`, `RF-43`, `RF-44`, `RF-45` | `quotes/service.py` — `MAX_RANGE_DAYS`; la pantalla arma el texto con lo que devuelve el 422 |
| `RF-46`, `RF-47`, `RF-48` | `ActionDetail.tsx` — una consulta inválida no cambia `plotted`: el gráfico anterior queda como está y no sale ninguna llamada, ni a nuestra API ni al proveedor. Valen para **los cuatro** casos inválidos, así que aparecen en las dos historias: el intervalo sin elegir es H1 (`RF-39`), las tres fallas del rango son H3 (`RF-40`, `RF-41`, `RF-45`) |

## Módulos afectados

| Módulo | Piezas tocadas | Qué cambia | Nuevo |
|---|---|---|---|
| `favorites` | `backend/app/modules/favorites/service.py` · `repository.py` · `__init__.py` | Suma **una** función de lectura, `is_favorite`, y la exporta: es lo que le permite a `quotes` responder sólo por las acciones del que pregunta. `models.py`, `router.py` e `io.py` no se tocan | `is_favorite` en el `__all__` |
| `quotes` | `backend/app/modules/quotes/router.py` · `io.py` · `service.py` · `repository.py` · `__init__.py` | **El módulo nace completo**: la ruta, la regla de vigencia, la compuerta, los cuatro estados y el acceso a `quotes`. `models.py` ya existe desde la fase 0 y **no cambia** | `router.py`, `io.py`, `service.py`, `repository.py` |
| composition root · shared · providers | `backend/app/main.py` · `backend/app/errors.py` · `backend/app/providers/twelvedata.py` | `main.py` monta el router de `quotes` (`GEN-04`) y registra dos handlers más; `errors.py` suma las dos fallas de rango; `twelvedata.py` pide la serie en UTC y fija el `outputsize`. **No se tocan** `db.py`, `security.py`, `settings.py`, `ratelimit.py`, `observability.py` ni `providers/base.py` | `QuoteRangeInvalid`, `QuoteRangeTooLong` |
| web | `frontend/src/api/quotes.ts` · `api/schema.d.ts` · `quotes/market.ts` · `components/QuoteChart.tsx` · `components/Notice.tsx` · `components/Header.tsx` · `pages/ActionDetail.tsx` · `package.json` | `ActionDetail.tsx` deja de ser el cascarón de `002` y pasa a ser el wireframe 03 completo. `Header.tsx` —que existe desde `001`— suma **dos props opcionales** y sigue siendo el dueño del layout de la barra; `Mis Acciones` lo sigue llamando igual que hoy. `App.tsx` **no cambia**: la ruta ya existe | `api/quotes.ts`, `quotes/market.ts`, `QuoteChart.tsx`, `Notice.tsx` |

Ni `auth` ni `stocks` se tocan. `app/providers/base.py` tampoco: el contrato de `ADR-006` alcanza
tal como está firmado, y `get_time_series(symbol, interval, start, end) -> list[QuotePoint]` es
exactamente lo que esta feature necesita. `app/providers/fake.py` se deja como está.

**`api/schema.d.ts` se regenera con `make types`, no se edita a mano** (`TS-03`).

**`src/quotes/` es una carpeta nueva del frontend y hay que justificarla.** Tiene el mismo lugar
que `src/auth/`: lo que no es una pantalla, ni un componente, ni una llamada a la API, sino el
poco dominio que las tres comparten —las dos zonas horarias, el rango por defecto y los
formateadores—. Meterlo en `components/QuoteChart.tsx` obligaría a la pantalla a importar del
componente para llenar dos campos de fecha, que es la dependencia al revés. Al cerrar la feature
se registra en `ARCHITECTURE.md` → *Anatomía del frontend*.

## Contrato entre módulos

| Frontera | Qué se pide | Qué se devuelve |
|---|---|---|
| router → service (`quotes`) | `get_series(session, provider: MarketDataProvider, symbol: str, interval: QuoteInterval, user_id: int, start: datetime \| None = None, end: datetime \| None = None) -> QuoteSeries`. El `user_id` sale de `CurrentUser.id` y de ningún otro lado (Artículo III); `start`/`end` llegan **naive, en hora de mercado**, tal como el usuario los escribió, y el service les pone la zona | `QuoteSeries(status: QuoteStatus, points: tuple[QuoteCandle, ...], session_date: date \| None)`, dataclasses frozen del módulo. `QuoteCandle` es `(ts: datetime, price: Decimal)`: el gráfico dibuja un valor, no una vela (`RF-14`) |
| service → repository (`quotes`) | `candles_in(session, symbol, interval, start, end) -> list[Quote]` (ascendente) · `newest_ts(session, symbol, interval) -> datetime \| None` · `save(session, symbol, interval, points: Sequence[QuotePoint]) -> int` | Datos, nunca decisiones: las filas del tramo, el instante de la vela más nueva, y cuántas filas escribió el upsert. **El modelo no sale del módulo**: el service lo convierte en `QuoteCandle` |
| service → provider | `provider.get_time_series(symbol, interval, start, end)`, con instantes **aware en UTC**. La elección de la ventana es del service: `[última vela, ahora]` cuando ya hay rueda de hoy, `[ahora − REALTIME_LOOKBACK, ahora]` cuando la caché está fría o hoy no tiene nada, y el rango pedido en `Histórico` | `list[QuotePoint]` (`app/providers/base.py`), o una `ProviderError` que el service traduce a `stale`. **El JSON del proveedor no sube nunca de `app/providers/`** (`GEN-08`) |
| este módulo → `__all__` de otro | `quotes` consume `from app.modules.favorites import is_favorite`, **por el paquete**. Del kernel usa `app.db` (`SessionDep`), `app.errors` (`UnknownSymbolError`, `QuoteRangeInvalid`, `QuoteRangeTooLong`), `app.security` (`get_current_user`, `CurrentUser`), `app.providers` y `app.observability`, que no son módulos | `is_favorite(session, user_id: int, symbol: str) -> bool` |
| `__all__` de este módulo → el resto (qué se agrega) | `quotes`: pasa de `[]` a `["router"]`. `favorites`: pasa de `["router"]` a `["router", "is_favorite"]` | — |

**El inventario de lecturas cruzadas del backend crece en un nombre, y es el primero desde que
`ARCHITECTURE.md` lo escribió.** Pasa a ser `get_stocks` y `StockInfo` (de `stocks`, para
`favorites`) más `is_favorite` (de `favorites`, para `quotes`). Se justifica así: el Detalle es
sólo para las acciones que el usuario tiene en su lista —es regla de negocio de la spec firmada, y
además es lo que acota la cuota del Artículo II a los símbolos que alguien eligió mirar—, y quién
es dueño de una favorita lo sabe `favorites` y nadie más. La alternativa —que `quotes` mire
`user_stocks` por su cuenta— es exactamente la frontera que el Artículo IV prohíbe. Es **un
booleano, una consulta, un símbolo por request**: no hay N+1 posible porque no hay lista que
recorrer. El inventario **ya quedó actualizado** en los once documentos que lo declaran completo
—`ARCHITECTURE.md` (→ *Las lecturas cruzadas*), `CONVENTIONS.md`, los roles `Backend-Architect` y
`Tester`, las skills `add_backend_feature`, `add_feature`, `add_tests`, `review_feature`,
`converge` y `plan`, y `plan.template.md`—, así que el gate de calidad ya sabe que esta lectura
cruzada es legítima.

Lo que **no** entra a ningún `__all__`: `get_series`, `QuoteSeries`, `QuoteCandle`, `QuoteStatus`,
`MARKET_TIMEZONE`, `MAX_RANGE_DAYS`, la compuerta, el repositorio y los schemas de `io.py`. Ningún
otro módulo necesita una serie de cotizaciones: son internos, visibles para sus hermanos e
invisibles para el resto del sistema (`PY-10`). Y lo privado del archivo va con guión bajo:
`_GATES`, `_gate_for`, `_status_of`, `_REALTIME_LOOKBACK` si no se usa fuera de su archivo.

**Fallas** — el service de `quotes` levanta tres excepciones de dominio, todas hijas de
`DomainError` y todas en `app/errors.py` (kernel, sin `fastapi` adentro), por la misma razón que
`AuthenticationError` y `UnknownSymbolError`: `main.py` tiene que importarlas para registrar el
handler, y si vivieran adentro del módulo habría que exportarlas en su `__all__` —contrato público
para un consumidor que no es un módulo—.

| Excepción | HTTP que registra `main.py` | Cuerpo |
|---|---|---|
| `UnknownSymbolError` (de `002`, se **reutiliza**) | **404** | `{"detail": "unknown symbol"}` — el símbolo no está entre las favoritas de quien pregunta |
| `QuoteRangeInvalid` | **422** | `{"detail": {"code": "range_invalid"}}` — `from` igual o posterior a `to` (`RF-41`) |
| `QuoteRangeTooLong` | **422** | `{"detail": {"code": "range_too_long", "interval": "1min", "max_days": 7}}` (`RF-45`) |

404 y no 403 para el símbolo ajeno: un 403 confirma que el símbolo existe y que es de otro, y acá
no hay nada que confirmar. Es además la misma respuesta que da `002` para un símbolo que no se
puede agregar, así que el frontend tiene un solo caso que tratar.

**Ninguna falla del proveedor es una falla del endpoint.** `ProviderUnavailable`,
`ProviderQuotaExceeded`, `ProviderRejectedCredentials` y `SymbolNotFound` se atrapan en el service,
se registran (`ERR-07`) y se convierten en `stale` o en `no_data` con 200 (`ERR-05`). No hay
`except` mudo: todos loguean y todos deciden (`ERR-01`).

## Datos

**Ninguna tabla nueva, ninguna columna nueva, ningún índice nuevo: esta feature no lleva
migración.** La tabla y el índice que necesita existen desde la migración inicial de la fase 0
(`394dab64d255`):

- **`quotes`** — PK compuesta `(symbol, interval, ts)`, columnas `open`, `high`, `low`, `close`,
  `volume`, `CHECK` sobre `interval`, FK `symbol` → `stocks.symbol`, e índice
  `ix_quotes_symbol_interval_ts` sobre `(symbol, interval, ts DESC)`, que es exactamente la
  consulta que hace el gráfico: un símbolo, un intervalo, una ventana, del más nuevo al más viejo.

Cuatro consecuencias que la feature asume y conviene dejar escritas:

- **La PK compuesta es la caché.** Volver a traer el mismo punto escribe una fila, no dos, así que
  un refresco no puede duplicar la serie y la detección de vigencia puede preguntarle a la base qué
  tiene en vez de confiar en una tabla de contabilidad que habría que mantener.

- **El upsert es `ON CONFLICT DO UPDATE`, no `DO NOTHING`.** La última vela de una rueda abierta
  todavía se está formando: a las 10:05:30 la vela de las 10:05 no es la que va a quedar. Con
  `DO NOTHING` la caché se quedaría para siempre con la versión a medio hacer, que es un precio de
  cierre equivocado guardado con cara de definitivo.

- **`ts` es `timestamptz` y se guarda en UTC.** La hora del mercado es presentación y decisión de
  negocio, no almacenamiento: guardar hora local haría que la misma vela entre dos veces el día que
  cambia el horario de verano, que es justamente lo que una PK por instante tiene que impedir.

- **No hay quinta tabla, y es una decisión con costo.** Registrar qué ventanas se pidieron
  —un `quote_fetches`— haría exacta la detección de huecos; se descarta porque una tabla nueva es
  una decisión de arquitectura que firma un humano (Artículo X), y porque la regla de vigencia más
  la compuerta cubren los casos reales con estado que no hay que migrar. Qué se pierde y cómo se
  mitiga, en *Riesgos*.

`alembic check` tiene que seguir limpio después de la feature: si alguien toca `models.py` de
`quotes`, este plan dejó de ser verdad y falta una migración (`DB-01`).

## Contratos

### `GET /api/quotes/{symbol}` — protegida

Es **la única ruta nueva de la feature**. Declara `get_current_user` importado de `app.security`
(`PY-08`) y no entra a `PUBLIC_ROUTES`: sirve datos que cuestan cuota y sólo por las acciones del
que pregunta.

```
GET /api/quotes/TSLA?interval=5min
GET /api/quotes/TSLA?interval=15min&from=2026-09-10T09:30&to=2026-09-11T16:00
Authorization: Bearer <jwt>
```

| Parámetro | Dónde | Tipo | Reglas |
|---|---|---|---|
| `symbol` | path | `str` | El objeto, no la identidad. Tiene que estar entre las favoritas del usuario o es 404 |
| `interval` | query | enum `1min` \| `5min` \| `15min` | Obligatorio. Otro valor es 422 de FastAPI: la pantalla nunca manda uno, porque `RF-39` la frena antes |
| `from`, `to` | query | `datetime` naive, en **hora de mercado** | Opcionales, **los dos o ninguno**. Presentes = `Histórico`; ausentes = `Tiempo Real` |

Respuesta **200 en los cuatro estados** (`ERR-05`):

```json
{
  "symbol": "TSLA",
  "interval": "5min",
  "status": "ok",
  "session_date": null,
  "points": [
    { "ts": "2026-09-11T19:55:00Z", "price": "365.43839" },
    { "ts": "2026-09-11T20:00:00Z", "price": "365.47000" }
  ]
}
```

- **`status`** — `ok` · `stale` · `market_closed` · `no_data`. Es el contrato de `ERR-05`, y el
  frontend pinta un aviso por cada uno distinto de `ok` (`UI-05`).
- **`session_date`** — sólo viene con `market_closed`: es la fecha de la rueda que se está
  mostrando, en hora de mercado, y es el `{fecha}` del texto de `RF-28`.
- **`points[].ts`** — instante UTC con offset, orden ascendente. El eje lo rotula el frontend en
  hora de mercado.
- **`points[].price`** — el cierre de la vela, **como string**. Es lo que Pydantic hace con un
  `Decimal` en JSON, y se deja así a propósito: el precio cruza el cable con los decimales que
  mandó el proveedor y se convierte a número **una sola vez**, en el borde del gráfico, que es
  donde de todos modos hace falta un `number`. El tooltip lo muestra formateado desde el string
  (`UI-04`).
- **Ningún campo nombra al proveedor** (`RF-26`), ni en el camino feliz ni en los tres avisos.

Errores: `404` símbolo que no es del usuario · `422` rango inválido o demasiado largo, con el
`code` que la pantalla traduce a texto · `401` sin token o vencido, que el interceptor de `001` ya
convierte en "sesión vencida".

### La regla de vigencia y la compuerta (`quotes/service.py`)

Es el corazón de la feature, y se escribe acá para que el `Tester` pueda testearla antes de que
exista:

```
MARKET_TIMEZONE  = ZoneInfo("America/New_York")   # NYSE y NASDAQ (A4)
TTL              = la duración del intervalo elegido (ADR-003)
REALTIME_LOOKBACK = 7 días
MAX_RANGE_DAYS   = {"1min": 7, "5min": 30, "15min": 90}   # RF-42..RF-44
```

1. **Validar el rango** (sólo en `Histórico`): `from < to` o `QuoteRangeInvalid`; `to - from` menor
   o igual al tope del intervalo o `QuoteRangeTooLong`. **Antes de autorizar, antes de mirar la
   base y antes de cualquier llamada al proveedor** (`RF-47`).
2. **Autorizar.** `is_favorite(session, user_id, symbol)` o `UnknownSymbolError`.
3. **Resolver la ventana.** En `Tiempo Real`, el día de hoy en hora de mercado, de `00:00` a
   `ahora`. En `Histórico`, `from` y `to` localizados en `MARKET_TIMEZONE` y pasados a UTC.
4. **¿Puede contestar la base?** Ventana que llega al presente: sí, si la vela más nueva del tramo
   tiene menos de un TTL. Ventana cerrada en el pasado: sí, si el tramo tiene velas —un período
   pasado no vence—.
5. **Si no, la compuerta.** Candado por `(símbolo, intervalo)`; adentro se vuelve a mirar la base
   (el que esperó puede encontrar que otro ya trajo el dato) y se consulta al proveedor sólo si el
   último intento para esa clave es más viejo que un TTL. Se persiste lo traído y **se responde
   siempre desde la base**, que es la única fuente.
6. **Decidir el `status`**, en este orden: el proveedor falló → `stale`; la ventana quedó vacía y
   hay una rueda anterior guardada → `market_closed` con su `session_date`; no hay nada en ningún
   lado → `no_data`; si no → `ok`.

> **La validación va antes de autorizar, y es una decisión del humano** *(2026-09-14)*. `RF-47`
> dice que una consulta inválida no consulta la fuente de datos externa, y hasta acá este plan
> autorizaba primero: un rango imposible igual costaba una lectura de la base, la de `favorites`.
> Se invirtió para que *"no se ejecuta"* sea literal — un rango que no se puede pedir no toca nada.
>
> **La consecuencia hay que asumirla:** un símbolo que **no** es del usuario, pedido con un rango
> inválido, ahora responde **422** y no 404. No filtra nada: el 422 habla del rango, que lo escribió
> quien pregunta, y no dice si el símbolo existe ni de quién es. Con un rango válido, el símbolo
> ajeno sigue siendo 404 sin llamar al proveedor (`RF-35`, Artículo III).

**La ventana de la llamada al proveedor la elige el service, y son dos.** Con rueda de hoy ya
guardada, se pide `[última vela, ahora]`: barato y chico, que es el caso de cada refresco. Con la
caché fría o con hoy vacío, se pide `[ahora − REALTIME_LOOKBACK, ahora]`: **cuesta el mismo
crédito** —el proveedor cobra por request, no por vela— y trae de una vez la última rueda que
`RF-27` necesita cuando es domingo y la base está vacía, que es el escenario exacto que el
`ROADMAP` marca como riesgo de la demo. Los topes de `MAX_RANGE_DAYS` están elegidos para que
ninguna consulta pase las 5.000 velas del `outputsize` máximo: 7 días a `1min` son ~2.730.

**Lo que se registra en cada llamada** (`ERR-07`): símbolo, intervalo, ventana, resultado y si fue
cache hit. Y las métricas que ya existen en `app/observability.py` y que hasta hoy nadie
incrementaba: `QUOTE_CACHE_HITS`, `QUOTE_CACHE_MISSES`, `PROVIDER_REQUESTS` (por símbolo,
intervalo y resultado) y `PROVIDER_QUOTA_REMAINING`. El dashboard de `ADR-009` ya los grafica.

### `app/providers/twelvedata.py` — el arreglo

Dos cambios en la llamada de `get_time_series`, y nada más:

- **La serie se pide en UTC.** Sin eso el proveedor devuelve la hora del mercado y el cliente le
  estampa UTC, que es un corrimiento silencioso de cuatro o cinco horas según la época del año.
  Pedirla en UTC arregla además el otro lado: el `start_date`/`end_date` que mandamos se interpreta
  en el mismo huso en el que nos contestan.
- **`outputsize` explícito, al máximo del plan.** El valor por omisión son 30 velas, y una rueda a
  `1min` tiene 390: sin esto el gráfico del enunciado sale recortado al 8%.

**El JSON fijado hay que volver a capturarlo** con los parámetros nuevos
(`tests/fixtures/twelvedata/time_series_tsla_1min.json`), porque un fixture describe una respuesta
real y la respuesta cambia de huso. Es una llamada a mano, una sola vez, con la API key
(`TEST-03` → *Cómo se fija una respuesta*). Hasta que eso pase, el fixture viejo describe un
proveedor que ya no es el que se le pide.

### Frontend — estructura y contrato de pantalla

```
src/
├── api/
│   ├── quotes.ts              getQuotes(symbol, interval, range?) -> QuoteSeries
│   └── schema.d.ts            GENERADO por `make types` — no se edita a mano (TS-03)
├── quotes/
│   └── market.ts              MARKET_TIME_ZONE · LOCAL_TIME_ZONE · INTERVAL_MS ·
│                              formatMarket() · formatLocal() · marketFieldValue() ·
│                              defaultHistoricRange() · tooltipTimeLines()
├── components/
│   ├── Header.tsx             EXISTE desde 001 — suma dos props opcionales, no se reescribe
│   ├── QuoteChart.tsx         Highcharts: título, ejes, serie única, tooltip de dos horas
│   └── Notice.tsx             el aviso de estado, arriba del gráfico (UI-05)
└── pages/
    └── ActionDetail.tsx       wireframe 03 completo: cabecera, controles, validación y polling
```

**La cabecera no se construye de nuevo: es la de `001`, con dos props más.** `components/Header.tsx`
existe desde la tarea 11 de `001-authentication` y su docstring ya anticipa este uso —el título es
una prop porque la cabecera del Detalle es **la misma barra** con `{símbolo} - {nombre} - {moneda}`
a la izquierda—. Dibujar una segunda barra en `ActionDetail.tsx` duplicaría la mitad derecha
(`Usuario: {nombre completo}` y `Cerrar sesión`) o dejaría al Detalle sin ella, y esa mitad está
fuera de alcance de esta spec justamente porque ya la definió `001` para **todas** las pantallas
internas. Lo que el Detalle agrega son dos cosas que la barra de `Mis Acciones` no tiene, y entran
como props **opcionales**:

```ts
export function Header({
  title,
  back,
  note,
}: {
  title: string;                              // RF-01 en el Detalle: `{símbolo} - {nombre} - {moneda}`
  back?: { to: string; label: string };       // RF-34: el enlace, a la IZQUIERDA del título
  note?: string;                              // RF-37: la aclaración, DEBAJO del título
}): JSX.Element;
```

```tsx
<Header
  title={`${favorite.symbol} - ${favorite.name} - ${favorite.currency}`}
  back={{ to: '/', label: 'Mis Acciones' }}
  note="Horarios en hora del mercado."
/>
```

**El dueño del layout de la barra sigue siendo `Header.tsx`**: dónde cae el enlace respecto del
título y dónde la aclaración lo decide el componente, y la pantalla sólo dice **qué** va en cada
lugar. `back` es un objeto y no dos props sueltas porque el destino sin el texto —o al revés— no es
un estado que exista: o hay enlace de vuelta o no lo hay. El enlace se dibuja con el `Link` de
`react-router`, no con un `<a href>`, para que no recargue la aplicación entera.

**Las dos props son opcionales, y eso es un requisito y no una comodidad.** `pages/MyActions.tsx`
sigue llamando `<Header title="Mis Acciones" />` sin tocar una línea, y los tests de `001` sobre la
cabecera (`frontend/tests/Header.test.tsx`) —que están **firmados**— tienen que seguir verdes tal
como se firmaron. Un test firmado no se reescribe (Artículo VI): si esta feature lo obliga a
cambiar, la que está mal es esta feature.

**`Cerrar sesión` sigue siendo de `001`** (su tarea 14) y esta feature **no lo construye**, ni
siquiera si al llegar acá todavía no estuviera: aparece en el Detalle porque las dos pantallas
dibujan este mismo `Header`, que es exactamente la razón por la que el título es una prop.

**Los horarios no se formatean en la pantalla: se formatean en `quotes/market.ts`, y por eso se
pueden testear.** Highcharts dibuja adentro de un SVG y jsdom no calcula layout: de un gráfico sólo
se puede leer el texto que escribe y la identidad del nodo. `RF-15` (cada cotización en el momento
que le corresponde), `RF-36` (todo en hora del mercado) y `RF-38` (las dos horas en el tooltip) son
por lo tanto **inverificables desde la pantalla**, y la única forma de que no queden sin test es que
el cálculo viva afuera del componente, en funciones puras con firma fija. Esta sección las fija
*(enmienda del 2026-09-14, decidida por el humano después de que el `Tester` escribiera los tests de
la feature)*.

```ts
/**
 * Las dos zonas horarias del producto, y el poco dominio que la pantalla, el gráfico y los dos
 * campos de fecha comparten. Es todo función pura: no toca el DOM, no conoce Highcharts y no
 * importa nada de React.
 */

/** El mercado donde cotiza el catálogo: NYSE y NASDAQ, los dos acá (A4, RF-36). */
export const MARKET_TIME_ZONE = 'America/New_York';

/** La hora de Argentina, la segunda que muestra el tooltip (RF-38). */
export const LOCAL_TIME_ZONE = 'America/Argentina/Buenos_Aires';

/** Los tres intervalos del enunciado (RF-06). El `''` del selector vacío no es uno. */
export type QuoteInterval = '1min' | '5min' | '15min';

/** Cada cuánto se refresca `Tiempo Real`, en milisegundos (RF-18). */
export const INTERVAL_MS: Readonly<Record<QuoteInterval, number>> = {
  '1min': 60_000,
  '5min': 300_000,
  '15min': 900_000,
};

/**
 * Un instante, escrito para leer: `DD/MM/YYYY HH:MM`, en hora del mercado (RF-15, RF-36).
 *
 * Recibe un `Date` —el instante, sin ambigüedad— y no un string: lo que viaja por el cable es
 * `points[].ts` en UTC con offset, y pasarlo a instante (`new Date(ts)`) es una línea del borde del
 * gráfico, el mismo borde donde el precio se vuelve `number`.
 */
export function formatMarket(instant: Date): string;

/** El mismo instante, en hora de Argentina y con el mismo formato (RF-38). */
export function formatLocal(instant: Date): string;

/**
 * El mismo instante, en el formato que come un `<input type="datetime-local">` y que viaja tal cual
 * en `from`/`to`: `YYYY-MM-DDTHH:mm`, en hora del mercado y **sin zona** (`plan.md` → *Contratos*:
 * el backend es el que la localiza).
 */
export function marketFieldValue(instant: Date): string;

/**
 * Las últimas 24 horas, escritas en hora del mercado y listas para los dos campos (RF-10).
 *
 * `to` es `now`; `from` es `now` menos 24 horas exactas de reloj. No es "la última rueda": son 24
 * horas corridas, que es lo que dice `RF-10` y lo que el usuario puede cambiar a mano.
 *
 * `now` es un parámetro con valor por omisión para que un test pueda fijar el reloj sin tocar
 * globals; la pantalla la llama sin argumentos.
 */
export function defaultHistoricRange(now?: Date): { from: string; to: string };

/**
 * Las dos líneas del tooltip, ya armadas y en orden: primero el mercado, después Argentina
 * (RF-38). Quien las dibuja las une con un salto de línea y no agrega ni quita texto.
 */
export function tooltipTimeLines(instant: Date): readonly [string, string];
```

Y lo que devuelve cada una, fijado carácter por carácter sobre el mismo instante — las 15:55 del
mercado del 11 de septiembre de 2026, que es la vela que usan los tests de pantalla:

```ts
const instant = new Date('2026-09-11T19:55:00Z');

formatMarket(instant);        // '11/09/2026 15:55'
formatLocal(instant);         // '11/09/2026 16:55'
marketFieldValue(instant);    // '2026-09-11T15:55'

defaultHistoricRange(instant);
// { from: '2026-09-10T15:55', to: '2026-09-11T15:55' }

tooltipTimeLines(instant);
// ['Hora del mercado: 11/09/2026 15:55', 'Hora de Argentina: 11/09/2026 16:55']

// El mismo reloj en enero, que es el caso que distingue una conversión real de un offset
// escrito a mano: el mercado cambia de horario de verano y Argentina no.
const winter = new Date('2026-01-15T19:55:00Z');

formatMarket(winter);         // '15/01/2026 14:55'
formatLocal(winter);          // '15/01/2026 16:55'
```

**El formateo es `Intl.DateTimeFormat` y se arma con `formatToParts`, no con `format`.** La zona la
resuelve la plataforma —es exactamente para esto que existe— y no hace falta ninguna librería nueva.
Pero el string terminado **no** puede salir de `format()`: el orden de los campos, el separador entre
la fecha y la hora y el ciclo horario son datos de locale, cambian entre versiones de ICU y entre
máquinas, y un test que afirme carácter por carácter se pondría rojo por eso y no por un bug. Se
piden `year: 'numeric'`, `month: '2-digit'`, `day: '2-digit'`, `hour: '2-digit'`, `minute: '2-digit'`
y `hourCycle: 'h23'`, se leen las partes y **las arma este módulo**. Con eso el locale deja de ser
load-bearing: lo único que la plataforma decide es a qué hora de qué zona corresponde el instante.

**Ninguna de las cinco funciones mira el reloj de la máquina que las corre**, y eso es el requisito y
no una propiedad casual: `MARKET_TIME_ZONE` y `LOCAL_TIME_ZONE` son literales IANA y van siempre como
`timeZone`, nunca se omite el campo para "que tome el del sistema". `new Date()` sólo aparece como
valor por omisión de `defaultHistoricRange`, que es el único lugar donde *qué hora es* forma parte de
la pregunta. Un `getHours()`, un `toLocaleString()` sin `timeZone` o un `toISOString().slice(0, 16)`
son el bug que esta feature persigue: los tres devuelven la hora de la máquina y los tres "andan" en
la máquina de quien los escribe.

**El tooltip se arma acá y no adentro de `QuoteChart.tsx`, y es el punto de esta enmienda.** El
`formatter` de Highcharts corre adentro del SVG: en jsdom no se dispara y su resultado no se puede
leer, así que `RF-38` escrito ahí no tiene forma de tener un test. Partido así, lo que se verifica en
unidad es todo lo que el requisito promete —las dos horas, cuál es cuál y de qué instante salen— y lo
que queda en el componente es una línea sin decisiones: `tooltipTimeLines(new Date(this.x)).join('<br/>')`,
más el precio, en mono tabular (`UI-04`).

**Las dos etiquetas del tooltip —`Hora del mercado:` y `Hora de Argentina:`— son texto nuevo en
pantalla**, y las eligió el cliente el 2026-09-14 cuando fijar el contrato de `RF-38` dejó a la
vista que dos horas una debajo de la otra no dicen cuál es cuál. Ya están registradas en
`docs/design/COPY.md`, como dos filas de *Detalle: navegación, horarios y validación* —la sección
donde viven los textos que esta feature obligó a inventar—, con las dos alternativas descartadas y
el porqué. `COPY.md` es la fuente (`UI-02`): si alguna vez difieren, gana esa fila y no este bloque.

**El `session_date` de `market_closed` no pasa por acá.** Llega como fecha sola (`2026-09-11`), ya en
hora del mercado, y convertirla con una zona la correría un día —medianoche UTC en Nueva York es el
día anterior—. `Notice.tsx` la reescribe sin cambiarle la zona, y eso lo verifica
`quoteNotice.test.tsx`, que es una pantalla y no necesita que el cálculo salga del componente.

**El estado vive en `ActionDetail.tsx`**, y es poco:

```ts
favorite: FavoriteItem | null | undefined   // undefined = cargando; null = no es suya (RF-35)
mode: 'realtime' | 'historic'               // RF-03, RF-04
interval: '1min' | '5min' | '15min' | ''    // RF-07: arranca vacío
from: string; to: string                    // RF-10: las últimas 24 h de mercado, ya cargadas
plotted: PlotRequest | null                 // RF-12: null = todavía no hay gráfico
series: QuoteSeries | null                  // lo último que contestó la API
errors: { interval?: string; dates?: string }  // RF-39 a RF-41 y RF-45
```

**La cabecera y la pertenencia salen del mismo pedido.** `listFavorites()` de `002` ya devuelve
símbolo, nombre y moneda: con esa lista se arma `{símbolo} - {nombre} - {moneda}` (`RF-01`) y se
decide si el símbolo es del usuario (`RF-35`). Un endpoint nuevo para eso sería una segunda forma
de preguntar lo mismo. Mientras carga, no se dibuja ni la cabecera ni los controles (`TS-06`).

**El gráfico se remonta sólo cuando el usuario grafica.** `<QuoteChart key={plotKey} …/>`, donde
`plotKey` es `símbolo|modo|intervalo|desde|hasta` y cambia únicamente al apretar `Graficar`
(`RF-17`). Los refrescos del polling cambian `points` con la misma `key`: el componente llama a
`setData` sobre el gráfico que ya existe, sin recargar ni parpadear (`RF-19`), y como la respuesta
de `Tiempo Real` es la rueda entera, los puntos que ya estaban siguen ahí (`RF-20`).

**El polling** (`RF-18`, `RF-21`, `RF-22`, `RF-23`):

- `setInterval` con `INTERVAL_MS[interval]`, armado sólo en `Tiempo Real` y sólo con un gráfico a
  la vista. En `Histórico` no se arma ninguno: un período que ya terminó no cambia.
- `document.visibilityState`: al esconderse la pestaña se limpia el intervalo; al volver se hace
  **un pedido inmediato** y se vuelve a armar. Es `RF-21`/`RF-22` y es también el Artículo II —una
  pestaña olvidada renovando el TTL de su símbolo toda la rueda es cuota gastada por nadie—.
- Se limpia en el `unmount`, y cada pedido cancela al anterior con `AbortController`: al cambiar de
  intervalo, la respuesta vieja no puede pisar a la nueva.

**La validación está partida, y la partición tiene una regla.** Lo que es **presencia** lo resuelve
la pantalla, porque sin eso no hay ni request que armar: sin intervalo elegido (`RF-39`) y con un
campo de fecha vacío (`RF-40`). Lo que es **regla de negocio** —`desde < hasta` y el tope de días
por intervalo— la decide el backend y la pantalla sólo **dibuja** lo que el 422 le dice, mapeando
`code` al texto de `COPY.md` y rellenando `{intervalo}` y `{N}` con lo que viene en el cuerpo. Los
topes viven en un solo lugar (`MAX_RANGE_DAYS`, en el service) y no se copian al navegador: una
regla del negocio duplicada en las dos puntas es una regla que un día va a discrepar consigo misma.
En los cuatro casos no se toca `plotted`, así que el gráfico anterior queda como está (`RF-48`) y
no hay ninguna llamada al proveedor (`RF-47`): un 422 no llega ni a mirar la base.

**El gráfico** (`RF-14`, `RF-15`, `RF-38`): título `{símbolo}`, eje vertical `Cotización`, eje
horizontal `Intervalo`, una sola serie de línea, eje horizontal de tipo `datetime` con
`time.timezone = MARKET_TIME_ZONE` para que las etiquetas sean las del mercado (`RF-36`) y cada
punto en `[Date.parse(ts), Number(price)]`, que es dónde cae cada cotización (`RF-15`). El tooltip
muestra el precio y las dos líneas que devuelve `tooltipTimeLines()` (`RF-38`), en mono tabular
(`UI-04`). Sin zoom, sin selección de rango, sin exportar: la spec los deja fuera y Highcharts los
trae encendidos, así que hay que **apagarlos explícitamente**.

**Los textos**, todos verbatim de `COPY.md` (`UI-02`): `Tiempo Real`,
`( utiliza la fecha actual, al graficar esta opcion, se debe actualizar el gráfico en forma
automática segun el intervalo seleccionado)`, `Histórico`, `Fecha hora desde`, `Fecha hora hasta`,
`Intervalo`, `( opciones 1min / 5min / 15min)`, `Graficar`, `Cotización`, `Mis Acciones`,
`Horarios en hora del mercado.`, `Elegí un intervalo.`, `Completá este campo.`,
`La fecha desde tiene que ser anterior a la fecha hasta.`,
`El rango es demasiado largo para el intervalo {intervalo}. El máximo es {N} días.`, y los tres
avisos de estado. La aclaración `( utilizar highcharts o similar para graficar)` **no se muestra**:
es una instrucción para quien construye.

Sin colores literales: la serie y los avisos salen del `@theme` de `tokens.css` (`UI-03`), y si
falta un token se agrega ahí y se discute.

## Alternativas descartadas

**Un `quote_fetches` que registre qué ventanas se pidieron.** Es la respuesta exacta a la
detección de huecos: con él, "¿tengo este tramo?" deja de ser una inferencia. Se descarta por dos
razones y ninguna es que no sirva: una tabla nueva es una decisión de arquitectura que firma un
humano (Artículo X, y el rol lo repite), y el par regla-de-vigencia + compuerta resuelve los casos
que esta aplicación produce de verdad —una rueda de hoy que se refresca, y ventanas históricas que
se piden enteras— sin estado nuevo que migrar. Queda anotado como lo primero que hay que construir
si aparece un caso donde la inferencia falle de manera visible.

**Caché en memoria o Redis con TTL, en vez de la tabla.** Ya está descartado en `ADR-003` y se
repite acá porque es la tentación cuando se ve la compuerta: el histórico no es un valor con
vencimiento, es una serie que hay que guardar igual en la base relacional de `REQ-18` y en su
backup de `REQ-21`.

**Que el frontend mande `from`/`to` en UTC.** Obligaría al navegador a convertir hora de mercado a
instante, es decir a saber en qué huso vive el mercado y a resolver los dos días del año en que esa
conversión es ambigua. El usuario escribe una hora de mercado; que viaje tal cual y la localice el
único lado que conoce el huso es menos código y una fuente de verdad en vez de dos.

**Guardar la zona horaria del mercado en `stocks`.** Es lo correcto el día que entre un mercado que
no sea de Estados Unidos, y hoy sería una columna, una migración, un campo más en `StockRecord` y
una ingesta que lo llene, todo para guardar `America/New_York` 7.200 veces. El catálogo del
proyecto son NYSE y NASDAQ (`A4`). Queda anotado como el primer lugar donde mirar si el catálogo
suma un tercer mercado.

**Dos endpoints, `/api/quotes/{symbol}/realtime` y `/{symbol}/history`.** Dos rutas, dos schemas,
dos handlers y dos tests de autorización para la misma pregunta con otra ventana. La diferencia es
un par de parámetros opcionales, y el que decide qué ventana es "hoy" tiene que ser el backend en
los dos casos.

**Validar el rango en el frontend.** Evita un viaje a nuestra API y duplica una regla del negocio
en las dos puntas: el día que los topes cambien, uno de los dos lados se va a quedar viejo y el
navegador no es el que manda. El rol del `Frontend-Architect` lo prohíbe con todas las letras. El
viaje que se ahorra es a **nuestra** API y no gasta cuota de nadie (Artículo II).

**Devolver el precio como número.** Es lo que el gráfico necesita y lo que evita un `Number()`.
Se descarta porque el precio sale de un `Decimal` que existe justamente para no ser un float: la
conversión se hace una vez, en el borde donde Highcharts pide un `number`, y no en el contrato.

**Mandar sólo los puntos nuevos en cada refresco.** Ahorra kilobytes de **nuestra** API y no ahorra
un solo crédito de la del proveedor, que es la que es finita. A cambio pone en el navegador la
responsabilidad de mantener el orden y los bordes de la serie, que es exactamente el lugar donde un
gráfico "casi bien" es difícil de depurar.

**Usar el código HTTP como canal para los cuatro estados** (503 proveedor caído, 404 sin serie, 429
cuota). Está descartado en la discusión de `ERR-05`: mienten. El 429 culpa al cliente, que no tiene
cuenta en ningún proveedor; el 404 dice que el símbolo no existe, cuando está en nuestro catálogo y
sólo falta la serie.

**`highcharts-react-official` además de `highcharts`.** El wrapper oficial es chico y no hace nada
que un `useRef` más un `useEffect` no hagan en veinte líneas: lo que esta pantalla necesita es
crear un gráfico, cambiarle los datos y destruirlo. Es una dependencia más, con su versión de React
y su propia superficie (`DEP-04`). Se usa `highcharts` a secas.

**Recharts, Chart.js o `visx` en vez de Highcharts.** El enunciado nombra Highcharts en el
wireframe y el brief lo fija en su *Stack*; `REQ-17` dice "o similar", así que la puerta está
abierta, pero elegir otra cosa sería apartarse de lo que el cliente escribió para no ganar nada
(Artículo VII).

**Un calendario de mercado** (feriados, media rueda) para decidir si hoy hay rueda. Es una
dependencia más o una tabla más, y la pregunta que responde ya la responde el dato: si hoy no hay
velas, se muestra la última rueda que haya y se dice cuál es (`RF-27`, `RF-28`).

**Modelar la rueda de `09:30` a `16:00`** en vez de pedir el día entero. Agrega horarios de mercado
al código para recortar una ventana que el proveedor ya recorta solo, y se rompe el día de una
media rueda o de un pre-market.

## Riesgos

| Riesgo | Impacto | Cómo se mitiga |
|---|---|---|
| **El corrimiento de huso del proveedor**: hoy `_to_instant` estampa UTC sobre una hora de mercado | Alto y silencioso: el gráfico entero corrido 4 o 5 horas, sin que nada falle | Se pide la serie en UTC y se vuelve a capturar el JSON fijado. Un test del proveedor contra el fixture nuevo tiene que verificar el instante exacto de la primera vela, no sólo que haya velas |
| **`outputsize` por omisión = 30 velas** | Alto: una rueda a `1min` sale recortada al 8% y parece un problema del gráfico | Se fija explícito al máximo del plan, y los topes de `MAX_RANGE_DAYS` están elegidos para no pasarlo |
| **La detección de vigencia es una inferencia, no un registro.** Una ventana histórica que caiga en un hueco entre dos tramos ya traídos se sirve incompleta | Medio: un gráfico al que le falta la cola, sin aviso | La regla pide velas **dentro de la ventana** y, si no hay ninguna, sale al proveedor una vez por TTL. El caso que queda —velas adentro pero incompletas— se anota acá y se resuelve con `quote_fetches` si aparece |
| **La compuerta es estado del proceso.** Con más de un worker, el registro del último intento es por worker | Medio: el consumo se multiplica por la cantidad de workers en el peor caso | El despliegue es un solo proceso (`ADR-007`). Queda escrito acá, y la corrección —mover el registro a Redis o a una tabla— es una decisión de arquitectura, no una tarea de esta feature |
| **`002` tiene que estar entregada**: `UnknownSymbolError`, `GET /api/favorites`, el `Bearer` de `client.ts` y la ruta `/stocks/:symbol` | Alto: sin eso esta pantalla no tiene ni cabecera ni autorización | Es la dependencia que el `ROADMAP` ya declara. No se adelanta nada de `002` acá |
| **La cabecera es de `001` y esta feature le agrega props**: `components/Header.tsx` existe desde su tarea 11, y su tarea 14 —`Cerrar sesión`— es la única que `001` todavía puede deber | Bajo: la mitad derecha de la barra está explícitamente fuera de alcance de esta spec, y las props nuevas son **opcionales** | El Detalle **reusa** el `Header` y le pasa `back` y `note`; no dibuja una barra propia, que es lo que duplicaría `Usuario: {nombre completo}`. `Mis Acciones` no cambia y `Header.test.tsx` —firmado en `001`— tiene que seguir verde: si esta feature lo pone en rojo, la que está mal es esta feature |
| **Highcharts trae encendido lo que la spec deja fuera**: zoom, selección de rango, menú de exportar, el crédito del pie | Medio, y es `UI-01` Blocker: la pantalla haría cosas que nadie pidió | Se apagan explícitamente en las opciones del gráfico, y el test de estructura de la pantalla lo fija |
| **`zoneinfo` sin base de datos horaria** adentro de la imagen `slim` | Alto si pasa: `ZoneInfo("America/New_York")` levanta `ZoneInfoNotFoundError` al primer request | Entra `tzdata` como dependencia del backend, que es la base de datos horaria empaquetada y lo que `zoneinfo` usa cuando el sistema no la trae |
| **La zona del mercado queda escrita de los dos lados** (`quotes/service.py` y `quotes/market.ts`) | Bajo hoy, medio si entra un mercado no estadounidense | Cada lado la usa para algo distinto —el backend para decidir qué día es hoy, el frontend para rotular— y las dos apuntan al mismo hecho de `A4`. La corrección, si el catálogo crece, es la columna en `stocks` |
| **El gráfico se remonta en cada refresco** si la `key` se arma mal | Medio: rompe `RF-19` de la peor manera, porque "anda" y parpadea | La `key` sólo cambia al graficar; hay un test que refresca y verifica que el nodo del gráfico sea el mismo |
| Alguien "corrige" un texto de `COPY.md` al escribir la pantalla | Medio, `UI-02` es Blocker | `frontend/tests/copy.test.ts` suma las filas de esta pantalla y rompe el build |
| **Los cuatro estados se escriben en cuatro lugares** —`ADR-005`, la spec, `COPY.md` y `ERR-05`— y uno puede quedar viejo | Bajo hoy, medio si alguno cambia | Los cuatro dicen lo mismo y `ADR-005` quedó `Aceptada` el 2026-09-13, así que es el que manda. Un estado nuevo o renombrado entra por un ADR nuevo, no editando los otros tres |

## Contexto de traspaso

**Para el Developer** — Empezá por el proveedor, que es lo que hace que todo lo demás sea medible:
`app/providers/twelvedata.py` (serie en UTC y `outputsize`), y con eso el JSON fijado vuelto a
capturar. Después el backend de adentro hacia afuera: `favorites/repository.py` y
`favorites/service.py` (`is_favorite`, tres líneas cada uno) y su `__all__`; después `quotes`:
`repository.py` → `service.py` → `io.py` → `router.py` → `__all__`. Recién ahí `main.py`: el
`include_router` y los dos handlers nuevos. El frontend va último, cuando `make types` ya puede
generar el schema de la ruta.

**La cabecera del Detalle no se escribe: se le pasan props a la que ya existe.**
`components/Header.tsx` es de `001` y esta feature lo toca **sólo** para sumarle `back` y `note`,
las dos opcionales, con la firma que fija *Frontend — estructura y contrato de pantalla*. No se
cambia nada de lo que la barra ya hace ni de cómo la llama `pages/MyActions.tsx`, y `Cerrar sesión`
no se construye acá: es la tarea 14 de `001`.

**El router recibe `session: SessionDep`**, el alias de `app/db.py`, y **nunca**
`Annotated[AsyncSession, Depends(get_session)]` escrito a mano: eso importa SQLAlchemy en el router
y `test_module_boundaries.py` lo rechaza en el acto (`PY-06`). La identidad entra por
`current_user: Annotated[CurrentUser, Depends(get_current_user)]`, importado de `app.security` y
nunca de `auth`. El proveedor entra por dependencia (`get_market_data_provider`), no se construye
adentro del service: es lo que le permite a la suite correr sin red.

Adentro de `quotes` los archivos se importan **por ruta completa**
(`from app.modules.quotes.repository import candles_in`), nunca por `app.modules.quotes`. Hacia
`favorites`, al revés: `from app.modules.favorites import is_favorite`, el paquete, nunca
`app.modules.favorites.service`.

Lo que **no** se toca: `quotes/models.py` (no hay migración en esta feature), `providers/base.py`
(el contrato de `ADR-006` alcanza), `providers/fake.py`, `app/security.py`, `app/settings.py`,
`app/observability.py` (las métricas ya están declaradas: se incrementan, no se crean), `seed.py`
—no se siembran cotizaciones: inventar precios en una tabla de precios es peor que un gráfico
vacío—, y todo lo que le falta a `001`.

Decisiones ya tomadas, que no hay que rediscutir: una sola ruta para los dos modos; `from`/`to` en
hora de mercado y respuesta en UTC; 200 en los cuatro estados; el precio como string; el upsert es
`DO UPDATE`; los topes de rango viven sólo en el backend; la zona del mercado es una constante y no
una columna; no hay quinta tabla; el polling se corta con la pestaña escondida; `highcharts` sin
wrapper.

Y `make types` se corre **después** de tener la ruta montada.

**Para el Tester** — Lo que puede romperse de verdad, en orden:

1. **La cuota, que es el Artículo II y la razón de ser de la feature.** Dos pedidos del mismo
   símbolo e intervalo dentro de un TTL producen **una** llamada al proveedor (`RF-24`); N pedidos
   concurrentes —lanzados de verdad en paralelo, no en secuencia— también producen una sola
   (`RF-25`); y un símbolo sin datos no se vuelve a preguntar hasta que pasa un TTL, aunque se
   pidan diez veces seguidas. El doble contador va en el `FakeProvider` del test: cuántas veces lo
   llamaron y con qué ventana.
2. **Los cuatro estados y su precedencia**, que es donde un `if` mal ordenado miente en pantalla:
   proveedor que levanta `ProviderQuotaExceeded` con caché tibia → `stale` (nunca `market_closed`);
   hoy vacío con una rueda anterior guardada → `market_closed` con el `session_date` correcto **en
   hora de mercado** (el caso del sábado); nada en ningún lado → `no_data`; datos frescos → `ok`
   **sin aviso**. Los cuatro con 200 y ninguno nombrando al proveedor (`RF-26`).
3. **Los husos, que es el bug más caro y el más silencioso.** El test del proveedor contra el JSON
   fijado tiene que verificar el **instante exacto** de la primera y la última vela, no que haya
   velas. Y el de `session_date`: una rueda que en UTC cruza la medianoche tiene que seguir siendo
   **un** día en hora de mercado, no dos.
4. **El aislamiento**: el token de `ana` pidiendo el gráfico de un símbolo que sólo tiene `juan`
   responde 404 y **no llama al proveedor**. Es la continuación de `test_user_isolation.py`.
5. **La validación del rango**: `desde == hasta` y `desde > hasta` → 422 `range_invalid`; 7 días a
   `1min` grafica y 8 no; 30 a `5min` sí y 31 no; 90 a `15min` sí y 91 no (`RF-42`, `RF-43`,
   `RF-44`), con `max_days` e `interval` en el cuerpo. Y en los cuatro casos, **cero llamadas al
   proveedor** (`RF-47`).
6. **El upsert de la vela abierta**: traer dos veces el mismo instante con distinto cierre deja
   **una** fila y el cierre **nuevo**.
7. **`TestRoutesDeclareAuthorization`** suma una ruta y **`PUBLIC_ROUTES` no suma ninguna**.
8. **Frontend**: la cabecera, que es **una sola barra** —el `Header` de `001` con sus props nuevas,
   no una segunda dibujada por el Detalle—, con el enlace a la izquierda del título (`RF-34`) y la
   aclaración debajo (`RF-37`), y `Usuario: {nombre completo}` apareciendo **una** vez; el selector
   vacío al abrir (`RF-07`) y `Elegí un intervalo.` al graficar sin
   elegir (`RF-39`); los dos campos de fecha ya cargados con las últimas 24 h de mercado (`RF-10`);
   que no haya gráfico antes de `Graficar` (`RF-12`) y que una consulta inválida —las tres del
   rango y también la del intervalo sin elegir— no grafique nada nuevo (`RF-46`), no pida nada
   (`RF-47`) y deje el anterior intacto (`RF-48`); que graficar de nuevo reemplace el gráfico y no lo superponga (`RF-17`); que
   el refresco **no remonte** el nodo del gráfico (`RF-19`) y no pierda puntos (`RF-20`); que en
   `Histórico` no se arme ningún intervalo (`RF-23`); que esconder la pestaña detenga los pedidos y
   volver dispare uno inmediato (`RF-21`, `RF-22`); que el aviso esté **arriba** del gráfico
   (`UI-05`) y que `ok` no dibuje ninguno (`RF-32`); y que un símbolo ajeno lleve a `Mis Acciones`
   (`RF-35`).
9. **El tooltip con las dos horas** (`RF-38`) y el eje en hora de mercado (`RF-36`), que es lo que
   distingue "las 09:30 de la apertura" de "las 10:30 del reloj de la computadora".

**`frontend/tests/copy.test.ts` suma las filas de esta pantalla** a su lista `REQUIRED`, que es una
lista de pares *(sección, elemento)* y no de textos: las de la tabla *Detalle de Acción*
**menos las dos de la mitad derecha de la cabecera** —`Usuario (cabecera, derecha)` y `Cierre de
sesión (cabecera, derecha)`, que son de `001`, están fuera de alcance de esta spec y ya se piden
desde sus propias secciones—, las **tres** de *Avisos de estado* y las cinco de *Detalle:
navegación, horarios y validación*. Qué fila entra en qué tarea lo reparte `tasks.md`: una fila
pedida antes de que su pantalla la dibuje pone la suite en rojo por algo que nadie prometió
todavía.

**Son tres y no cuatro los avisos de estado con literal.** La tabla tiene cuatro filas, pero la de
`ok` dice *(sin aviso)* y no lleva ningún texto entre backticks: el parser de `copy.test.ts`
descarta las filas sin literal, y pedir esa fila hace que `textOf()` levante una excepción por una
fila que para el test no existe. Que `ok` no dibuje aviso se verifica en pantalla (`RF-32`), que es
donde se puede verificar.

Ojo con las dos aclaraciones entre paréntesis: llevan faltas de ortografía a propósito (`opcion`,
`segun`) y el test es lo que impide que alguien las "arregle".

Los tests del proveedor van **contra JSON fijado**, y el fixture nuevo se captura una vez a mano.
Ningún test sale a la red ni necesita API key (`TEST-03`).

**Para el Code-Reviewer** — Mirá en este orden:

1. **`GEN-08` y el Artículo I**: que `httpx` no aparezca fuera de `app/providers/`, que el nombre
   del proveedor siga estando en un solo archivo, y que ningún `status`, ningún log y ningún cuerpo
   de error lo nombren.
2. **`GEN-02` y `PY-06`**: que `quotes` entre a `favorites` por el paquete y a `stocks` no entre;
   que adentro de `quotes` los hermanos se importen por ruta completa; que el router no importe
   SQLAlchemy y el service no importe `fastapi` ni levante `HTTPException` (`ERR-04`).
3. **`GEN-09` y el Artículo III**: que el `user_id` venga de `get_current_user` y de ningún otro
   lado, y que `is_favorite` lo reciba como primer argumento.
4. **`ERR-05`**: que ninguna `ProviderError` escape del service, que los cuatro estados respondan
   200 y que ningún `except` sea mudo (`ERR-01`).
5. **`UI-01` y `UI-02`**: la pantalla contra `docs/design/wireframes/03-detalle-accion.png` —el
   orden de los controles, el `select` de intervalo vacío, el aviso arriba del gráfico— y cada
   string contra `COPY.md`, faltas incluidas. Que Highcharts no haya traído zoom, exportar ni su
   crédito.
6. **`PY-10`**: `MARKET_TIMEZONE` y `MAX_RANGE_DAYS` en mayúsculas; guión bajo para lo privado del
   archivo (`_GATES`); y que lo único agregado a un `__all__` sea `is_favorite` en `favorites` y
   `router` en `quotes`.
7. **`DEP-01` a `DEP-04`**: `highcharts` y `tzdata` entraron con su gestor y con el lockfile en el
   mismo commit, y no entró ninguna otra.
