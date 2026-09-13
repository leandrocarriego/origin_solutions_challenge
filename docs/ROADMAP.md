# Orden de construcción

Cómo se corta el enunciado en features y en qué orden se construyen. **No es autoridad**: el
alcance está en `docs/PROJECT_BRIEF.md` y cada feature define el suyo en su `spec.md`.

## Las tres features

El corte sigue las tres pantallas del enunciado, que además son tres capacidades con vocabulario
propio y entregables de forma independiente.

| # | Feature | Cubre | Depende de |
|---|---|---|---|
| `001-authentication` | Login, sesión y la cabecera con el usuario | REQ-01 a REQ-04 · NFR-01 | — |
| `002-favorite-stocks` | Catálogo, autocomplete, grilla, alta y baja | REQ-05 a REQ-11 · NFR-03 | 001 |
| `003-quote-chart` | Detalle, caché de cotizaciones y gráfico | REQ-12 a REQ-17 · NFR-04, NFR-05 | 002 |

Las dependencias son reales, no de conveniencia: sin sesión no hay favoritas de nadie, y sin
favoritas no hay desde dónde llegar al detalle.

`REQ-18` a `REQ-25` (base de datos, seed, repo, backup, README, arquitectura y stack) no son una
feature: son transversales, y se cumplen en la fase 0 y en el cierre.

## Fase 0 — Antes de la primera spec

Andamiaje que ninguna feature debería tener que resolver:

- `git init`, estructura `backend/` y `frontend/` · **REQ-23**
- docker-compose: postgres + api + web, con migraciones automáticas y seed sólo en local · **ADR-007**
- `.env.example` y `Settings` tipado · **SEC-03**
- Esqueleto FastAPI con `/api/health` y CORS acotado al origen del frontend
- Esqueleto Vite + React 19 + TS strict + Tailwind CSS · **REQ-25**
- Las cuatro tablas y su migración inicial · **REQ-18, ADR-001**
- `MarketDataProvider`, `TwelveDataProvider` y `FakeProvider` · **ADR-006**
- Tests de arquitectura que fijan la frontera entre módulos, las capas de cada módulo y el
  aislamiento por usuario · **Art. IV**
- Ingesta del catálogo NYSE + NASDAQ · **ADR-002, A4**
- Seed: 2 usuarios con Argon2 + favoritas demo (TSLA, AAPL, NFLX) · **REQ-19**

**El estado de cada uno vive en `docs/specs/000-scaffolding/tasks.md`, no acá.** Ese archivo es
además donde se registra la firma del Artículo VI sobre los tests de la fase: el gate no tiene
excepciones y necesitaba un `tasks.md` donde anotarse. Acá está el alcance; allá, qué está hecho.
Si los dos llevaran checkboxes, uno de los dos quedaría viejo.

El seed va en la fase 0 y no al final porque el enunciado pide **"insertar una cantidad mínima de
datos para poder probar la aplicación"**: sin él no se puede desarrollar contra nada.

## Fase 1 a 3 — Las features

Cada una sigue la cadena completa: `/specify` → `/clarify` → `/approve-spec` → `/plan` → `/tasks`
→ `/analyze` → tests del `Tester` → `/approve-tests` → `/implement` → `/converge` →
`/review-feature` → `/ship`.

`003-quote-chart` es la que concentra el riesgo: la detección de huecos y el TTL de `ADR-003` son
la parte no trivial del proyecto y la que demuestra los NFR. Va última porque depende de las otras
dos, pero es la que más tiempo necesita — conviene no llegar a ella con el presupuesto gastado.

## Cierre

- [ ] `make backup` → `db/backup.sql` desde la base ya sembrada · **REQ-21**
- [ ] README: qué es, cómo levantar, credenciales demo, decisiones, cómo correr los tests · **REQ-22**
- [ ] Tabla de trazabilidad del brief completa: ningún `REQ-NN` sin test
- [ ] Repaso de seguridad: sin secretos versionados, sin la API key en el bundle · **NFR-02**
- [ ] Publicar el repositorio · **REQ-20**

## Riesgos

| Riesgo | Mitigación |
|---|---|
| La cuota de 800/día se agota probando | `FakeProvider` en desarrollo y tests; el upstream real sólo en demo (Art. II) |
| Evaluación en fin de semana → gráficos vacíos | `ADR-005`: última rueda disponible con aviso |
| El plan gratuito limita endpoints o intervalos | Validar temprano con la API key real y ajustar el brief si aparece un límite |
| Llegar a `003` sin tiempo | Es la feature que más pesa en la rúbrica: si algo se recorta, se recorta antes, no acá |
| Sobre-ingeniería | El alcance está cerrado en `PROJECT_BRIEF.md` → *Fuera de alcance*, y `/converge` lo verifica |
