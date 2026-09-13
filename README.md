# ORIGIN Acciones

Aplicación web para seguir la cotización de acciones en tiempo real. Los datos vienen de la API
pública de [TwelveData](https://twelvedata.com/).

Backend en **FastAPI** sobre PostgreSQL, frontend en **React + TypeScript + Tailwind**, y los dos detrás de
un `docker compose` que levanta el proyecto entero con un comando.

## Estado

**Fase 0 — andamiaje y observabilidad.** Lo que hay desplegado y funcionando hoy:

- `GET /api/health`, que responde `200` cuando la base contesta y `503` con `degraded` cuando no,
  sin filtrar jamás la cadena de conexión.
- La pantalla de estado que lo consume, en la raíz del sitio.
- Las cuatro capas de observabilidad del `ADR-009`: logs estructurados con correlación por
  request, métricas Prometheus, un dashboard de Grafana y reporte de errores a Sentry.

**Lo que todavía no existe:** autenticación, el catálogo de símbolos, las cotizaciones y las
favoritas. Son las fases 1 a 3 de `docs/ROADMAP.md`.

En producción: **https://origin-solutions-challenge.mendrisoftware.com**

## Puesta en marcha

Necesitás **Docker** y nada más.

```bash
git clone git@github.com:leandrocarriego/origin_solutions_challenge.git
cd origin_solutions_challenge
cp .env.example .env      # completá POSTGRES_PASSWORD; el resto puede quedar vacío en local
make up
```

Levanta la base, el backend y el frontend:

| | |
|---|---|
| Frontend | http://localhost:5173 |
| API | http://localhost:8000/api/health |
| OpenAPI | http://localhost:8000/docs |
| PostgreSQL | `localhost:5432` (`origin` / `origin`) |

`make down` baja todo y conserva el volumen de la base.

### Sin Docker, para desarrollar

Backend con [uv](https://docs.astral.sh/uv/), frontend con npm. **Sin excepciones**: es el
Artículo IX, y lo que compra es que el build sea reproducible.

```bash
make install      # uv sync --frozen  +  npm ci, los dos desde su lockfile
make hooks        # instala los hooks de pre-commit y commit-msg

make dev-backend  # http://localhost:8000
make dev-frontend # http://localhost:5173
```

El backend necesita una base corriendo: `docker compose up -d db` alcanza.

## Variables de entorno

Todas viven en `.env`, que **no se versiona**. `.env.example` es la plantilla con el porqué de
cada una al lado.

| Variable | Para qué | Si está vacía |
|---|---|---|
| `POSTGRES_PASSWORD` | Credencial de la base | El compose de producción se niega a arrancar |
| `TWELVEDATA_API_KEY` | La credencial del proveedor | El módulo `quotes` falla explícitamente al necesitarla |
| `SENTRY_DSN` | Reporte de errores | Sentry queda desactivado: sin eventos y sin red |
| `GRAFANA_ADMIN_PASSWORD` | Login de Grafana | El compose de producción se niega a arrancar |
| `DOMAIN` | Host que enruta Traefik | Sólo aplica en producción |

**La API key nunca sale del backend.** No va en una variable `VITE_*`, ni en una respuesta, ni en
un log, ni en un traceback: es el Artículo I. Una `VITE_*` no es configuración privada — Vite la
reemplaza por su valor literal en el bundle que descarga el navegador, así que configurarla y
publicarla son la misma operación.

## Comandos

`make help` los lista todos. Los que se usan a diario:

| Comando | Qué hace |
|---|---|
| `make check` | Lint, tipos y la suite completa de los dos proyectos |
| `make lint` | Formato y lint (`ruff`, `prettier`, `eslint`) |
| `make typecheck` | `mypy --strict` y `tsc --noEmit` |
| `make test` | Suite completa con cobertura |
| `make test-fast` | Sólo unidad y arquitectura: lo que corre el pre-commit |
| `make format` | Reescribe el código con el formateador de cada proyecto |
| `make up` / `make down` / `make logs` | Infraestructura local |
| `make deploy` | Despliega al VPS |

Los comandos que **verifican una convención** viven junto a la convención que verifican, en
`CONVENTIONS.md`. Acá no se duplican: un comando escrito en dos lugares diverge, y el día que
diverge nadie sabe cuál vale.

## Cómo está organizado

```
backend/     el backend (Python · FastAPI · uv)
frontend/    el frontend (TypeScript · React · npm)
infra/       configuración de Prometheus y Grafana
scripts/     el script de despliegue
docs/        brief, decisiones, specs y diseño
agents/      roles y skills del proceso de desarrollo
```

El backend es un **monolito modular por dominios** (`auth`, `stocks`, `favorites`, `quotes`).
Cada módulo es dueño de su router, sus schemas, su lógica, su acceso a datos y sus tablas, y
**ningún módulo importa el interior de otro**. La frontera no se sostiene con disciplina: la
verifica un test que rompe el build.

El detalle está en [`ARCHITECTURE.md`](ARCHITECTURE.md).

## Observabilidad

Cuatro capas, decididas en [`ADR-009`](docs/DECISIONS.md):

1. **Logs** en JSON, una línea por evento, con un `request_id` que atraviesa todas las líneas de
   un mismo pedido y vuelve en la respuesta. Un `X-Request-ID` entrante se respeta en vez de
   reemplazarse, así la cadena sobrevive al proxy.
2. **Métricas** Prometheus en `/metrics`, que no se publica hacia afuera.
3. **Dashboard** de Grafana, en `/grafana` detrás de su propio login.
4. **Sentry**, con las tres opciones que filtrarían credenciales apagadas y un `before_send` que
   enmascara secretos por valor y por forma.

El punto de las capas 2 y 3 es el **Artículo II**: el consumo del proveedor escala con símbolos
distintos observados, nunca con clientes conectados. Diez usuarios mirando un mismo símbolo
cuestan lo mismo que uno. Sin los contadores, eso es una afirmación en un documento; con ellos,
es un número graficado.

## Despliegue

```bash
make deploy
```

Sincroniza el árbol, construye, espera a que el backend esté sano y limpia **sólo** las imágenes
de este proyecto. El VPS está compartido con otros proyectos en producción, y de ahí salen las
reglas del `docker-compose.prod.yml`: ningún contenedor publica un puerto en una interfaz
pública, todos tienen límite de memoria, y el nombre del proyecto es distinto para que compose
nunca toque contenedores ajenos.

## Cómo se desarrolla esto

El proyecto se dirige por **Spec-Driven Development**, con un proceso propio inspirado en GitHub
Spec Kit. La cadena es `spec → plan → tasks → tests → implementación → review`, y tiene tres
puertas donde firma un humano: la spec, **los tests antes de que exista la implementación**, y el
review de calidad.

| Documento | Qué contiene |
|---|---|
| [`CONSTITUTION.md`](CONSTITUTION.md) | Los diez principios no negociables. Autoridad número uno |
| [`AGENTS.md`](AGENTS.md) | Punto de entrada: roles, fronteras, flujo de git, Definition of Done |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | La estructura del repositorio y el recorrido de una cotización |
| [`CONVENTIONS.md`](CONVENTIONS.md) | Cada convención con su identificador, su severidad y el comando que la verifica |
| [`docs/PROJECT_BRIEF.md`](docs/PROJECT_BRIEF.md) | El enunciado traducido a alcance verificable, con sus ambigüedades declaradas |
| [`docs/DECISIONS.md`](docs/DECISIONS.md) | Las decisiones técnicas transversales (ADR) |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | Cómo se corta el enunciado en features y en qué orden |

Que los tests vayan **antes** de la implementación no es una preferencia de estilo. Un test
escrito después describe lo que el código hace; escrito antes, describe lo que tiene que hacer.
La diferencia es quién define "terminado".
