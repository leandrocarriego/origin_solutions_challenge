# Arquitectura — ORIGIN Acciones

Cómo está organizado el repositorio, dónde vive cada cosa.

No es autoridad: los principios están en `CONSTITUTION.md` y las reglas operativas en `AGENTS.md`.
Este documento explica **la forma**, y se abre al tocar la estructura o mover código de lugar.

## Las dos puntas

El repositorio incluye **dos proyectos**: un frontend y una API.

No es un monorepo con código compartido: son dos aplicaciones independientes, cada una con su `Dockerfile` y su gestor de dependencias, y el único contrato entre ellas es **OpenAPI**.

```
origin_solutions_challenge/
├── backend/              el backend (Python - FastAPI - uv)
├── frontend/             el frontend (TypeScript - React - npm)
├── scripts/              scripts para el seed de la db (pg_dump de la base sembrada), etc
├── docs/                 brief, decisiones, specs, diseño
├── agents/               roles y skills del proceso SDD
├── infra/                configuración de la observabilidad desplegada (ADR-009)
│   ├── prometheus/       qué se scrapea
│   └── grafana/          datasource, provisioning y los dashboards como código
├── docker-compose.yml
└── Makefile
```

El stack completo, está en `docs/PROJECT_BRIEF.md` → *Stack*.

**`infra/` no es un tercer proyecto.** No tiene código ni dependencias: es la configuración de
los servicios de observabilidad que se despliegan junto a los otros dos.

El criterio de qué entra es el **contexto de build**, no el tema: en `infra/` va lo que el host
**monta** en un contenedor de una imagen ajena (el `prometheus.yml`, el provisioning de Grafana);
junto a su proyecto va lo que se **hornea** en la imagen propia. Por eso `frontend/nginx.conf`
vive en `frontend/`: el build context de esa imagen es `./frontend`, así que un archivo en
`infra/` no sería copiable sin subir el contexto a la raíz del repo — y eso mandaría el
repositorio entero al daemon en cada build. Los dashboards viven
ahí como JSON versionado y no como algo que alguien clickeó, y un test
(`backend/tests/architecture/test_dashboard_metrics.py`) verifica que cada métrica que grafican
exista de verdad en el código — un contador renombrado deja los paneles en blanco sin romper
nada, que es peor que un error porque parece "no hubo tráfico".

**`frontend` nunca importa de `backend` y `backend` nunca sirve el frontend.**

Los tipos de TypeScript se generan desde el OpenAPI de FastAPI (`make types`), no se escriben a mano en las dos puntas.

## El backend es un monolito modular

```
backend/app/
├── main.py               composition root: el lifespan, los middlewares y el montaje de
│                         cada router. El único que puede importar un módulo (GEN-03)
├── error_handlers.py     la traducción de cada excepción de dominio a su respuesta HTTP
├── health.py             el router de /api/health: no es negocio, es el estado del proceso
├── settings.py           Pydantic Settings — las apikeys y secrets viven acá y sólo acá
│                         dentro de backend/app/ esta el kernel: lo que cualquier módulo puede importar
├── db.py                 engine async, Base declarativa, get_session · SessionDep
├── errors.py             DomainError, la base que error_handlers.py traduce
├── ratelimit.py          SlidingWindowLimiter — cuenta intentos y no sabe de qué
├── tasks.py              la otra mitad del composition root: qué corre de fondo,
│                         y el arranque y la frenada de esas corrutinas
├── security.py           Argon2 · JWT · get_current_user · CurrentUser
├── observability/        ADR-009 — el paquete exporta lo mismo que exportaba el archivo
│   ├── metrics.py        los contadores del Artículo II y el endpoint que Prometheus scrapea
│   ├── logs.py           logging estructurado: una línea JSON por evento
│   ├── middleware.py     el request id, atado mientras dura el request
│   └── sentry.py         qué se reporta y qué se tacha antes de salir
├── providers/            infraestructura de servicios externos
│   ├── base.py           MarketDataProvider (ABC) · StockRecord · QuotePoint · ProviderError
│   ├── twelvedata.py     ← el único archivo que nombra TwelveData, settings.py incluido
│   ├── fake.py           FakeProvider, determinístico: corre toda la suite sin red
│   └── registry.py       get_market_data_provider(): cuál de los dos, según settings
└── modules/
    ├── auth/             login, emisión del token          → tabla users
    ├── stocks/           catálogo, ingesta, autocomplete   → tabla stocks
    ├── favorites/        CRUD de favoritas                 → tabla user_stocks
    └── quotes/           EL NÚCLEO: vigencia, compuerta, status  → tabla quotes
```

Los cuatro módulos responden HTTP: `auth` (`/api/auth`), `stocks` (`/api/stocks`), `favorites`
(`/api/favorites`) y, desde `003-quote-chart`, `quotes` (`/api/quotes`).

Cuatro módulos porque hay cuatro capacidades con vocabulario propio.

Un módulo nuevo se justifica cuando aparece una capacidad que el negocio nombra distinto, nunca porque un archivo creció.

### Anatomía de un módulo

Los cinco archivos de abajo empiezan como **archivo** y crecen a **carpeta del mismo nombre** cuando lo pide el tamaño.

El `__init__.py` no crece: es el contrato, y es igual en todos los módulos.

```
modules/<modulo>/
├── __init__.py                        EL CONTRATO: docstring, imports y el `__all__`
├── router.py        → routers/        HTTP: rutas, códigos, autorización
├── schemas.py       → schemas/        los modelos Pydantic del módulo: los de entrada y
│                                      salida HTTP, y los que el service decide y la
│                                      respuesta lleva. Al crecer: schemas/<uno>.py por tema
├── service.py       → services/       las decisiones del negocio
├── repository.py    → repositories/   acceso a datos
└── models.py        → models/         SQLAlchemy
```

Los cuatro módulos tienen hoy los cinco archivos. Ninguno creció a carpeta: los cinco siguen
siendo archivos.

**`app/providers/` es infraestructura, y es a propósito.** El proveedor no es una capacidad del negocio: es la salida al mundo, y lo consumen `stocks` para la ingesta del catálogo y `quotes` para las series.

### La frontera, que es una sola regla con dos cláusulas

> **El contrato de un módulo es su paquete: lo que declara `__all__` en su `__init__.py`.**

**Afuera:** a un módulo se entra por su paquete.
Cualquier ruta más profunda (`app.modules.stocks.service`, `app.modules.stocks.models`) es interior ajeno y para el resto del sistema no existe.

**Adentro:** los archivos del módulo se importan entre sí por ruta completa, **nunca** por
`app.modules.<modulo>`, porque eso reentra al `__init__` a medio inicializar y da un `ImportError`
confuso. Es la cláusula que evita el error, así que vale tanto como la primera.

```
desde otro módulo
❌ from app.modules.stocks.repository import StockRepository
❌ from app.modules.stocks.service import StockService
❌ from app.modules.stocks.models import Stock
❌ from app.modules.auth import get_current_user          ← no es de `auth`
✅ from app.modules.stocks import get_stocks, StockInfo
✅ from app.security import get_current_user, CurrentUser
✅ from app.db import get_session

adentro del propio módulo
❌ from app.modules.stocks import get_stocks              ← reentra al __init__
✅ from app.modules.stocks.service import get_stocks
```

El `__init__.py` de un módulo tiene **sólo** docstring, imports y un `__all__` que es una lista
literal de strings; ninguna lógica adentro. `main.py` entra por la misma puerta que todos:
`from app.modules.stocks import router`, y por eso el `router` está en el `__all__`.

Está verificado en `backend/tests/architecture/test_module_boundaries.py`, que lee los imports con `ast` y falla nombrando archivo y línea (las dos cláusulas, y además que cada `__init__.py` sea
sólo docstring, imports y un `__all__` literal).

Si este documento y ese test se contradicen, gana el test (`CONSTITUTION.md`, Artículo IV).

### Adentro del módulo, el flujo va en un solo sentido

```
router  ──►  service  ──►  repository  ──►  PostgreSQL
                │
                └──────►  provider  ──►  RealProvider     (app/providers/)
```

- Un **router** no importa SQLAlchemy. No hay `select()` en una ruta.

- Un **service** no importa `fastapi`. No levanta `HTTPException`: levanta excepciones de dominio,
  y quien las traduce es `app/error_handlers.py`, enganchado desde `main.py`.

- Un **repository** no decide nada: recibe qué buscar y devuelve datos.

- Un **provider** no toca la base ni conoce ningún módulo.

Y hay una puerta trasera que el test de imports **no puede ver**: un `relationship()` de SQLAlchemy
que cruce módulos. `favorite.stock.name` no genera ningún import, y sin embargo acopla `favorites`
al modelo de `stocks`. Las `ForeignKey` entre tablas de módulos distintos son legítimas y
obligatorias —son una garantía del motor—; los `relationship()` que cruzan, no.

## Modelo de datos

Cuatro tablas, un solo esquema (`ADR-001`):

```
users ──┐
        ├──< user_stocks >── stocks
                                │
                             quotes
```

| Tabla | Dueño | Clave |
|---|---|---|
| `users` | `auth/` | `id` |
| `stocks` | `stocks/` | `symbol` — el catálogo, que la ingesta reconcilia contra la foto del proveedor (`ADR-002`); dos índices GIN de trigramas, por `symbol` y por `name`, que es lo único que puede indexar el `ILIKE '%texto%'` del autocomplete |
| `user_stocks` | `favorites/` | compuesta `(user_id, symbol)` |
| `quotes` | `quotes/` | compuesta `(symbol, interval, ts)`, índice por `(symbol, interval, ts DESC)` |

Las claves compuestas son reales, no un `UniqueConstraint` sobre un `id` que nadie usa: agregar dos veces la misma favorita es imposible por construcción, no por un `if` en el service.

Las migraciones de Alembic son del proyecto, no de cada módulo: viven en `backend/alembic/versions/` y una sola cadena las ordena.

## Las lecturas cruzadas

Hoy hay **dos**, y esa escasez es el dato: son los únicos lugares del sistema donde un módulo
necesita algo de otro, y por eso es donde se ve si la frontera es real.

La primera es la grilla de *Mis Acciones* (`002-favorite-stocks`):

```
favorites/service.py
    │  necesita símbolo, nombre y moneda para la grilla (REQ-08)
    │  user_stocks es suyo; stocks no
    ▼
stocks/__init__.py  →  __all__ = ["StockInfo", "get_stocks", "keep_the_catalogue_fresh", "router"]
    from app.modules.stocks import get_stocks
    get_stocks(session: AsyncSession, symbols: Sequence[str]) -> list[StockInfo]
```

La segunda es el gráfico del Detalle (`003-quote-chart`):

```
quotes/service.py
    │  el gráfico se sirve sólo para las acciones de quien pregunta (RF-35, Artículo III)
    │  quotes es suyo; user_stocks no
    ▼
favorites/__init__.py  →  __all__ = ["is_favorite", "router"]
    from app.modules.favorites import is_favorite
    is_favorite(session: AsyncSession, user_id: int, symbol: str) -> bool
```

Un booleano, una consulta y un símbolo por request: no hay lista que recorrer, así que no hay N+1
posible. El `user_id` sale de `get_current_user` y de ningún otro lado, y va como **primer
argumento** y en el `WHERE`: no hay forma de hacer esta pregunta sobre la lista de otro. Que
`quotes` mirara `user_stocks` por su cuenta es exactamente la frontera que el Artículo IV prohíbe.

**La sesión va adelante, y no es un detalle de firma.** La transacción es de la request y la abre
el router; una función que abriera la suya dejaría el alta de una favorita fuera de la transacción
de quien la llamó, y la lectura del catálogo vería un estado distinto del de la escritura que la
sigue. Es la misma forma que `authenticate(session, …)` en `auth`.

**En batch, una sola consulta para toda la grilla.** Nunca un `get_stock()` por fila: eso es N+1.

Y tres propiedades del contrato que están escritas porque no se deducen de la firma: la respuesta
es un **conjunto** —los repetidos colapsan y los símbolos que el catálogo no tiene simplemente no
aparecen, así que el largo de la salida no acompaña al de la entrada—, **el orden no se promete**
—lo decide quien consume: `favorites` reordena por `added_at DESC, symbol ASC`—, y **los símbolos
llegan en mayúsculas**, porque normalizar ya tiene un dueño (`add_favorite`) y dos lugares que
normalizan son dos lugares que un día lo hacen distinto. El porqué de cada una, en
`docs/specs/002-favorite-stocks/plan.md`.

De los otros tres `__all__`, dos son sólo el router y el tercero suma una pregunta:

```
auth/__init__.py       →  __all__ = ["router"]
favorites/__init__.py  →  __all__ = ["is_favorite", "router"]
quotes/__init__.py     →  __all__ = ["router"]
```

`favorites` exporta su router y **una** pregunta, `is_favorite(session, user_id, symbol) -> bool`,
que es la que `quotes` necesita para servir el gráfico sólo de las acciones de quien pregunta
(`RF-35`, Artículo III). La grilla, las decisiones que hay detrás y el acceso a `user_stocks`
siguen siendo interiores: lo que sale es un booleano, así que ningún otro módulo lee la fila de la
lista de nadie. `keep_the_catalogue_fresh` está en el `__all__` de `stocks` por la misma puerta y no por una
excepción: quien lo importa es `main.py`, que arranca la tarea de fondo en el `lifespan`, y el
composition root entra por el paquete como todos.

`quotes` exporta su router y nada más: la serie, la regla de vigencia, la compuerta y los cuatro
estados son interiores —ningún otro módulo necesita una serie de precios, y un nombre exportado
para nadie es superficie que hay que sostener—.

Las dos lecturas cruzadas no son una excepción a nada: se entra por el paquete, se pide lo que
el `__all__` declara, y el que pregunta no toca la tabla del otro.

Lo que **no** está en ningún `__all__` es igual de informativo: `search_stocks` —la consume sólo el
router de su propio módulo—, `list_favorites`, `add_favorite`, `remove_favorite`, `get_series`,
`QuoteSeries`, `MARKET_TIMEZONE`, `MAX_RANGE_DAYS`, la compuerta y los schemas de los `schemas.py`.
Son internos: visibles para sus hermanos, invisibles para el resto del sistema.

Y `auth` es además el módulo del que **nadie lee**: no exporta nada más que su router, y ningún
módulo lo importa. Lo que los demás necesitan de la sesión —`get_current_user` y `CurrentUser`— no
es lógica de `auth` sino una primitiva de seguridad, y por eso vive en `app/security.py`: si viviera
adentro del módulo, los routers de los otros módulos tendrían que importar un módulo de dominio para
poder autorizar, y la dependencia apuntaría justo al revés de lo que dice esta página. Es la razón de que el ❌ de más arriba sea un ❌.

## Por dónde pasa una cotización

El camino que más importa entender, porque es donde vive el Artículo II.

```
navegador
    │  GET /api/quotes/TSLA?interval=1min&from=…&to=…
    ▼
quotes/router.py ──► quotes/service.py
                          │
                          │ 1. ¿qué tramos del rango ya están en `quotes`?
                          ├──► quotes/repository.py ──► PostgreSQL
                          │
                          │ 2. ¿lo guardado sigue vigente para su intervalo? (TTL = el intervalo;
                          │    un tramo cerrado en el pasado no vence nunca)
                          │      sí ──► responde de la base                 ← el caso normal
                          │      no ──► 3. la compuerta por (símbolo, intervalo): candado, y
                          │                 adentro se vuelve a mirar la base
                          │              4. app/providers/twelvedata.py ──► TwelveData
                          │              5. persiste lo traído y responde de la base
                          ▼
                 { status: ok | stale | market_closed | no_data, series: [...] }
```

El frontend en modo Tiempo Real vuelve a pedir **a esta misma ruta** cada intervalo.
Casi todos esos pedidos se resuelven en el paso 2 sin salir a la red: por eso el consumo escala con símbolos observados y no con clientes conectados.

Los cuatro `status` y qué muestra la UI con cada uno están en `ADR-005` y `docs/design/COPY.md`.

## Anatomía del frontend

```
frontend/src/
├── App.tsx               las rutas; el Router lo pone main.tsx
├── pages/                Login · MyActions · ActionDetail  (una por wireframe)
│                         + HealthPage, que no es del enunciado (ver abajo)
├── components/           Header · Autocomplete · StockGrid · ConfirmDialog
│                         · QuoteChart (Highcharts) · Notice (el aviso de estado)
├── quotes/               market.ts: las dos zonas horarias y los formateadores que
│                         comparten la pantalla, el gráfico y los campos de fecha
├── api/                  cliente HTTP + tipos generados del OpenAPI
│   ├── client.ts         la única puerta: `/api`, el token y el interceptor de 401
│   ├── schema.d.ts       generado con `make types`; no se escribe a mano
│   ├── auth.ts           login
│   ├── stocks.ts         las sugerencias del autocomplete
│   ├── favorites.ts      listar, agregar y quitar favoritas
│   ├── quotes.ts         la serie que dibuja el gráfico
│   └── health.ts         el estado del proceso
├── auth/                 contexto de sesión, su almacenamiento, interceptor de 401
└── styles/tokens.css     Tailwind: el @theme con la paleta, y nada más
```

Tres páginas, tres wireframes: `docs/design/wireframes/` es la especificación de layout y `COPY.md` la de los textos. `HealthPage` es la excepción y no rompe la regla, porque no es una pantalla del producto: cuelga de su propia dirección y contesta "¿esto está vivo?".

**`ActionDetail` es el wireframe 03 completo** desde `003-quote-chart`: los dos modos, el intervalo,
`Graficar`, el gráfico y los avisos de estado.

**`src/quotes/` es una carpeta y no un componente**, con el mismo lugar que `src/auth/`: lo que no es
una pantalla, ni un componente, ni una llamada a la API, sino el poco dominio que las tres comparten
—las dos zonas horarias, el rango por defecto y los formateadores—. Meterlo adentro de `QuoteChart`
obligaría a la pantalla a importar del componente para llenar dos campos de fecha, que es la
dependencia al revés; y afuera del componente es además lo único que hace testeable el huso, porque
Highcharts dibuja adentro de un SVG que jsdom no mide.

**Un endpoint nuevo no crea un archivo nuevo en cada pantalla.** Cada recurso de nuestra API tiene
un módulo en `api/` y las pantallas lo llaman: ninguna hace `fetch` por su cuenta, y ninguna nombra
un token. Quién llama lo sabe la sesión —`src/auth/` registra el proveedor de token y el
interceptor de 401 en `client.ts`—, y por eso `client.ts` no importa nada de `auth/`: sería un
ciclo, y la sesión dejaría de tener un solo dueño.

**`ConfirmDialog` está en `components/` y no adentro de `MyActions`** porque es una pieza propia del
wireframe con sus textos literales (`Eliminar` · `Cancelar`), y porque `window.confirm()` no sirve:
el navegador rotula sus botones como quiere y `COPY.md` fija esos dos (`UI-02`). Es un `<dialog>`
nativo abierto con `showModal()` —top layer, foco atrapado, `Escape`—, tres cosas que jsdom no
implementa y que por eso se verifican a mano contra un navegador.

**Los estilos son utilidades de Tailwind y el único `.css` es `tokens.css`** (`CONVENTIONS.md` → `UI-07`). Tailwind no es un design system ni una librería de componentes: no trae ni un botón, así que las pantallas siguen saliendo del wireframe y no de los defaults de nadie. Lo que sí trae —y acá se usa— es una escala de espaciado y tipografía consistente, y un `@theme` donde la paleta del diseño se declara una vez. La paleta de fábrica se borra en ese mismo bloque, para que `bg-blue-500` no sea una alternativa silenciosa a los tokens.

## Agregar una feature

1. `/specify` → `docs/specs/<NNN-feature>/spec.md`, y se firma (`/approve-spec`).

2. `/plan` → Constitution Check primero; después módulos afectados y contrato entre módulos.

3. `/tasks` → el desglose, con su cobertura de requisitos.

4. `/implement` → el `Developer` sigue las skills `add_*`.

Antes de sumar un nombre al `__all__` de un `__init__.py`: preguntarse si otro módulo lo necesita
de verdad. Todo lo que entra ahí es superficie que hay que sostener.
