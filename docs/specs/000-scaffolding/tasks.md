# 000-scaffolding — Tareas

**Feature:** `000-scaffolding` · **Plan:** — (ver *Por qué esta carpeta es distinta*)

**Tests aprobados por:** [—] · **Fecha de aprobación:** [—]

<!--
  Lo completa `/approve-tests`, nunca un agente por su cuenta (Artículo VI). Acá la firma es
  **por lote**: se registra en la fila de la tarea, no sólo en este encabezado, porque las tareas
  pendientes no se testean juntas ni se firman el mismo día. Este encabezado queda en "—" hasta
  que estén firmadas todas.
-->

## Por qué esta carpeta es distinta

Las tres features (`001`, `002`, `003`) tienen un alcance que el cliente firma, y por eso tienen
`spec.md` y `plan.md`. La fase 0 no: es el andamiaje que ninguna feature debería tener que
resolver, y su alcance ya está fijado en tres lugares que son autoridad.

| Lo que en una feature sería… | Acá es |
|---|---|
| `spec.md` firmada | `docs/ROADMAP.md` → *Fase 0*, derivada de `REQ-18` a `REQ-25` |
| `plan.md` con Constitution Check | los ADR **aceptados** de `docs/DECISIONS.md` |
| `tasks.md` | este archivo |

**Por qué existe igual.** El Artículo VI no tiene excepciones: los tests se escriben antes, y el
humano los firma antes de que exista la implementación. Esa firma se registra en un `tasks.md`
(`agents/skills/approve_tests.md`, paso 7). Sin esta carpeta la fase 0 no tendría dónde
registrarla, y "el gate no aplica acá" es exactamente la excepción que el artículo no admite.

La alternativa era declarar la fase 0 fuera del gate en la constitución. Se descartó: le abre un
agujero a un artículo que dice "sin excepción" para ahorrarse una carpeta.

**Estado.** Este archivo es la única fuente del estado de la fase 0. `docs/ROADMAP.md` describe el
alcance y apunta acá; si los dos llevaran checkboxes, uno de los dos quedaría viejo.

Al cerrar la fase, la carpeta pasa a `archive/` como cualquier otra y el número `000` no se
reutiliza.

## Ya construido

Estas tareas se hicieron **antes de que existiera esta carpeta**, cuando todavía no había dónde
registrar una firma.

**No se firman retroactivamente.** `approve_tests.md` lo prohíbe explícitamente: aprobar tests
contra código que ya existe no es cumplir el gate, es regularizarlo en el papel. Quedan
registradas como lo que son.

| # | Tarea | Cubre | Tests |
|---|-------|-------|-------|
| 1 | `git init`, estructura `backend/` y `frontend/` | REQ-23 | — |
| 2 | docker-compose local y de producción, con migraciones automáticas y seed sólo en local | ADR-007 | — |
| 3 | `.env.example` y `Settings` tipado | SEC-03 | — |
| 4 | Esqueleto FastAPI: `/api/health`, CORS acotado al origen del frontend, `DomainError` | — | `backend/tests/` |
| 5 | Esqueleto Vite + React 19 + TypeScript strict + Tailwind CSS 4 | REQ-25 | `frontend/tests/HealthPage.test.tsx` |
| 6 | Gobernanza: constitución, convenciones, roles, skills, plantillas de spec | — | — |
| 7 | CI, pre-commit y el chequeo de idioma de los comentarios | GEN-07 | `scripts/check_comment_language.py` |
| 8 | Observabilidad: métricas, Prometheus, Grafana y su dashboard del Artículo II | ADR-009 | `backend/tests/architecture/test_dashboard_metrics.py` |
| 9 | Deploy al VPS con Traefik y TLS | — | — |

La tarea 8 **sí** cumplió el gate en la práctica: el test del dashboard se escribió primero, se
verificó en rojo y recién después se construyó el dashboard. Se anota acá porque no hay firma
registrada, no porque el orden haya sido el otro.

## Pendiente

Cada una pasa por el gate: primero los tests, después la firma en su fila, y recién entonces la
implementación.

| # | Tarea | Skill | Rol | Cubre | Depende de | Firma |
|---|-------|-------|-----|-------|------------|-------|
| 10 | Tests de arquitectura: frontera entre módulos, capas del módulo, proveedor detrás de su interfaz, aislamiento por usuario | `add_tests` | Tester | Art. IV · GEN-02, GEN-03, GEN-05, GEN-08, GEN-09, PY-06 | — | — |
| 11 | Las cuatro tablas y su migración inicial | `add_database_migration` | Developer | REQ-18 · ADR-001 · DB-01 | ADR-001 ✅ | — |
| 12 | `MarketDataProvider`, `TwelveDataProvider` y `FakeProvider` contra JSON fijado | `add_integration` | Developer | ADR-006 · TEST-03 · ERR-05 | ADR-006 | — |
| 13 | Ingesta del catálogo NYSE + NASDAQ, idempotente y con el filtro de ADR-001 | `add_backend_feature` | Developer | ADR-002 · A4 | ADR-001 ✅ · ADR-002 · 11, 12 | — |
| 14 | Seed: 2 usuarios con Argon2 y favoritas demo (TSLA, AAPL, NFLX) | `add_backend_feature` | Developer | REQ-19 | ADR-004 · 11 | — |

### Bloqueos abiertos

Ninguna de estas cinco arranca sin resolver lo suyo, y las tres primeras son decisión humana:

- **`ADR-002`, `ADR-004`, `ADR-006` y `ADR-007` siguen en `Propuesta`.** Un ADR en `Propuesta` no
  es autoridad y ningún plan lo puede citar (Artículo X). Las tareas 12, 13 y 14 dependen de que
  se firmen.
- **Argon2 y la librería de JWT no son dependencias declaradas.** `SEC-06` las exige y hoy no
  están en `backend/pyproject.toml`. Entran con `uv add`, nunca a mano (Artículo IX).
- **La tarea 10 no depende de ningún ADR** y es la que más barato sale hacer primero: fija las
  fronteras antes de que haya código que las viole.

## Cobertura de requisitos

| Requisito | Tareas | Test |
|-----------|--------|------|
| REQ-18 — modelo de datos en PostgreSQL | 11 | |
| REQ-19 — seed mínimo para probar | 14 | |
| REQ-23 — repositorio con backend y frontend separados | 1 | |
| REQ-25 — frontend en React ≥ 18 | 5 | `frontend/tests/HealthPage.test.tsx` |
| Art. IV — fronteras entre módulos | 10 | |
| ADR-001 — clave natural y filtro de ingesta | 11, 13 | |
| ADR-002 — catálogo NYSE + NASDAQ | 13 | |
| ADR-006 — proveedor detrás de su interfaz | 12 | |
| ADR-007 — un comando para levantar todo | 2 | |
| ADR-009 — observabilidad | 8 | `backend/tests/architecture/test_dashboard_metrics.py` |

`REQ-20` (publicar el repositorio), `REQ-21` (backup) y `REQ-22` (README) no están acá: son del
cierre, no del andamiaje (`docs/ROADMAP.md` → *Cierre*).
