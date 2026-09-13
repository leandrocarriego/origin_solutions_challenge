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
├── main.py               composition root: monta el router de cada módulo, CORS,
│                         y traduce las excepciones de dominio a HTTP
├── settings.py           Pydantic Settings — las apikeys y secrets viven acá y sólo acá
│                         dentro de backend/app/ esta el kernel: lo que cualquier módulo puede importar
├── db.py                 engine async, Base declarativa, get_session
├── errors.py             DomainError, la base que main.py traduce
├── security.py           Argon2 · JWT · get_current_user · CurrentUser
├── providers/            infraestructura de servicios externos
│   ├── base.py           MarketDataProvider (Protocol) · ProviderSymbol · ProviderCandle
│   ├── twelvedata.py     ← el único archivo del repo que nombra TwelveData
│   └── fake.py           FakeProvider, determinístico: corre toda la suite sin red
└── modules/
    ├── auth/             login, emisión del token          → tabla users
    ├── stocks/           catálogo, ingesta, autocomplete   → tabla stocks
    ├── favorites/        CRUD de favoritas                 → tabla user_stocks
    └── quotes/           ← EL NÚCLEO: huecos, TTL, status  → tabla quotes
```

Cuatro módulos porque hay cuatro capacidades con vocabulario propio.

Un módulo nuevo se justifica cuando aparece una capacidad que el negocio nombra distinto, nunca porque un archivo creció.

### Anatomía de un módulo

Los cinco archivos de abajo empiezan como **archivo** y crecen a **carpeta del mismo nombre** cuando lo pide el tamaño.

El `__init__.py` no crece: es el contrato, y es igual en todos los módulos.

```
modules/<modulo>/
├── __init__.py                        EL CONTRATO: docstring, imports y el `__all__`
├── router.py        → routers/        HTTP: rutas, códigos, autorización
├── io.py            → schemas/        schemas Pydantic de entrada y salida
│                                      al crecer: schemas/io.py + schemas/<otros>.py
├── service.py       → services/       las decisiones del negocio
├── repository.py    → repositories/   acceso a datos
└── models.py        → models/         SQLAlchemy
```

**`app/providers/` es infraestructura, y es a propósito.** El proveedor no es una capacidad del negocio: es la salida al mundo, y la consumen dos módulos.

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
  y el router las traduce en `main.py`.

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
| `stocks` | `stocks/` | `symbol` — el catálogo, que la ingesta reconcilia contra la foto del proveedor (`ADR-002`) |
| `user_stocks` | `favorites/` | compuesta `(user_id, symbol)` |
| `quotes` | `quotes/` | compuesta `(symbol, interval, ts)`, índice por `(symbol, interval, ts DESC)` |

Las claves compuestas son reales, no un `UniqueConstraint` sobre un `id` que nadie usa: agregar dos veces la misma favorita es imposible por construcción, no por un `if` en el service.

Las migraciones de Alembic son del proyecto, no de cada módulo: viven en `backend/alembic/versions/` y una sola cadena las ordena.

## La lectura cruzada

Es el único caso del sistema donde un módulo necesita algo de otro, y por eso define la frontera:

```
favorites/service.py
    │  necesita símbolo, nombre y moneda para la grilla (REQ-08)
    │  user_stocks es suyo; stocks no
    ▼
stocks/__init__.py  →  __all__ = ["StockInfo", "get_stocks", "router"]
    from app.modules.stocks import get_stocks
    get_stocks(symbols: list[str]) -> list[StockInfo]
```

**En batch, una sola consulta para toda la grilla.** Nunca un `get_stock()` por fila: eso es N+1.

## Por dónde pasa una cotización

El camino que más importa entender, porque es donde vive el Artículo II:

```
navegador
    │  GET /api/quotes/TSLA?interval=1min&from=…&to=…
    ▼
quotes/router.py ──► quotes/service.py
                          │
                          │ 1. ¿qué tramos del rango ya están en `quotes`?
                          ├──► quotes/repository.py ──► PostgreSQL
                          │
                          │ 2. ¿el hueco está vencido para su intervalo? (TTL = el intervalo)
                          │      no ──► responde de la base                 ← el caso normal
                          │      sí  ──► 3. app/providers/twelvedata.py ──► TwelveData
                          │              4. persiste lo traído
                          │              5. responde
                          ▼
                 { status: ok | stale | market_closed | no_data, series: [...] }
```

El frontend en modo Tiempo Real vuelve a pedir **a esta misma ruta** cada intervalo.
Casi todos esos pedidos se resuelven en el paso 2 sin salir a la red: por eso el consumo escala con símbolos observados y no con clientes conectados.

Los cuatro `status` y qué muestra la UI con cada uno están en `ADR-005` y `docs/design/COPY.md`.

## Anatomía del frontend

```
frontend/src/
├── pages/                Login · MyActions · ActionDetail  (una por wireframe)
├── components/           Header · Autocomplete · StockGrid · QuoteChart · Notice
├── api/                  cliente HTTP + tipos generados del OpenAPI
├── auth/                 contexto de sesión, interceptor de 401
└── styles/tokens.css     Tailwind: el @theme con la paleta, y nada más
```

Tres páginas, tres wireframes: `docs/design/wireframes/` es la especificación de layout y `COPY.md` la de los textos.

**Los estilos son utilidades de Tailwind y el único `.css` es `tokens.css`** (`CONVENTIONS.md` → `UI-07`). Tailwind no es un design system ni una librería de componentes: no trae ni un botón, así que las pantallas siguen saliendo del wireframe y no de los defaults de nadie. Lo que sí trae —y acá se usa— es una escala de espaciado y tipografía consistente, y un `@theme` donde la paleta del diseño se declara una vez. La paleta de fábrica se borra en ese mismo bloque, para que `bg-blue-500` no sea una alternativa silenciosa a los tokens.

## Agregar una feature

1. `/specify` → `docs/specs/<NNN-feature>/spec.md`, y se firma (`/approve-spec`).

2. `/plan` → Constitution Check primero; después módulos afectados y contrato entre módulos.

3. `/tasks` → el desglose, con su cobertura de requisitos.

4. `/implement` → el `Developer` sigue las skills `add_*`.

Antes de sumar un nombre al `__all__` de un `__init__.py`: preguntarse si otro módulo lo necesita
de verdad. Todo lo que entra ahí es superficie que hay que sostener.
