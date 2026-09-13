# 000-scaffolding — Tareas

**Feature:** `000-scaffolding` · **Plan:** — (ver *Por qué esta carpeta es distinta*)

**Tests aprobados por:** Leandro Carriego · **Fecha de aprobación:** 2026-09-13 — *tareas 11 a 15.*

<!--
  Lo completa `/approve-tests`, nunca un agente por su cuenta (Artículo VI). Acá la firma es
  **por lote**: se registra también en la fila de la tarea, porque las tareas pendientes no se
  testean juntas ni se firman el mismo día.
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
| 10 | `argon2-cffi` y `pyjwt` declaradas con `uv add` | SEC-06 · ADR-004 · Art. IX | — |
| 11 | Tests de arquitectura: fronteras, capas, proveedor y autorización de rutas | Art. IV · GEN-02, GEN-03, GEN-05, GEN-08, PY-06, PY-08 | `tests/architecture/` — firmados 2026-09-13 |
| 12 | Las cuatro tablas y su migración inicial | REQ-18 · ADR-001 · DB-01 | `tests/architecture/test_data_model.py` — firmados 2026-09-13 |
| 13 | `MarketDataProvider`, `TwelveDataProvider` y `FakeProvider` contra JSON capturado | ADR-006 · TEST-03 · ERR-05 | `tests/unit/test_{market_data_provider,upstream_client,provider_wiring}.py` — firmados 2026-09-13 |
| 14 | Reconciliación del catálogo y el filtro de ingesta | ADR-002 · ADR-001 · A4 | `tests/unit/test_catalogue_filter.py` · `tests/integration/test_catalogue_ingestion.py` — firmados 2026-09-13 |
| 15 | Seed: 2 usuarios con Argon2 y favoritas demo, y `app/security.py` | REQ-19 · SEC-06 · ADR-004 | `tests/integration/test_password_hashing.py` · `tests/integration/test_seed.py` — firmados 2026-09-13 |

Las tareas **11 a 15 sí pasaron el gate**: sus tests se escribieron antes, se verificaron
en rojo y se firmaron el 2026-09-13 (encabezado de este archivo). Están en esta tabla porque ya
están hechas, no porque se hayan salteado nada.

De la 13 hay que registrar una cosa: **un test firmado resultó equivocado y se corrigió**
(`test_the_prices_are_decimals` afirmaba sobre `series[0]` cuando el precio que nombraba es el de
`series[-1]`, porque la serie vuelve de más vieja a más nueva). El Artículo VI dice que un test
así se corrige y se firma de nuevo, no que se deje pasar.

La tarea 8 lo cumplió en la práctica pero sin firma registrada: el test del dashboard se escribió
primero y se verificó en rojo, sólo que todavía no existía este archivo donde anotarlo.

## Pendiente

Queda una sola cosa de la fase, y es la parte de `ADR-002` que los tests firmados no cubren.

| # | Tarea | Skill | Rol | Cubre | Depende de | Firma |
|---|-------|-------|-----|-------|------------|-------|
| 16 | El refresco programado del catálogo y su métrica de frescura | `add_backend_feature` | Developer | ADR-002 (puntos 3 y 5) · ADR-009 | 14 ✅ | — |

**Qué falta exactamente.** La reconciliación existe y está testeada, pero hoy no la dispara
nadie: `ADR-002` decidió que corra al arrancar si la última ingesta exitosa tiene más de 24 horas
y cada 24 horas después, y que la frescura se publique como un gauge que Grafana grafica. Sin eso,
el catálogo vuelve a depender de que alguien se acuerde — que es exactamente lo que ese ADR se
reescribió para evitar.

Pasa por el gate como todas: primero los tests, después la firma, después el código.

### La tarea 11, en detalle

Son tres archivos en `backend/tests/architecture/`, más el lector de código que comparten:

| Archivo | Verifica |
|---|---|
| `source_tree.py` | No es un test: lee los `.py` con `ast` y resuelve los imports. Existe para que cada regla se pueda correr dos veces —contra `app/` y contra un árbol escrito a propósito para romperla—. |
| `test_module_boundaries.py` | `GEN-02` (las dos cláusulas, la forma del `__init__`, ningún modelo del ORM exportado, y el `relationship()` que cruza), `GEN-03`, `GEN-05`, `PY-06` |
| `test_provider_boundary.py` | `GEN-08`: ningún cliente HTTP fuera de `providers/`, y el nombre del proveedor en un solo archivo |
| `test_route_authorization.py` | `PY-08` (declarada **y** ejercida) y la mitad estática del Artículo III: ninguna ruta acepta la identidad del usuario por path, query o body |

Son **42 tests**, y se firmaron sabiendo esto: **la mitad hoy pasa en vacío**. La fase 0 no creó
ni un módulo, así que las aserciones contra `app/` corren sobre un conjunto vacío y seguirían en
verde aunque el chequeo estuviera roto. Es el modo de falla más probable de un test de
arquitectura y el más difícil de notar.

Por eso cada regla va emparejada con un test que la corre contra un árbol escrito para romperla,
bajo `tmp_path`. Esos 27 son los que hoy tienen filo.

Uno **no** es vacuo y encontró algo real en su primera corrida: el que verifica que el nombre del
proveedor viva en un solo archivo falló contra `app/observability.py:193`, que lo nombraba para
poder scrubear la key. Se arregló moviendo a `Settings` la pregunta de cuáles de sus valores son
secretos.

Tres decisiones tomadas al firmar:

- **Los ciclos se detectan siguiendo la cadena completa**, no comparando de a pares: `a → b → c →
  a` es un ciclo aunque ningún par se importe mutuamente, y `GEN-05` dice "no hay ciclos" sin
  calificar el largo.
- **Ningún test afirma sobre una constante del propio archivo.** Se sacaron tres que lo hacían
  (`COMPOSITION_ROOT == "main.py"`, la lista de clientes HTTP, `"user_id" in IDENTITY_PARAMETERS`):
  no dicen nada del sistema, y quien quiera achicar el alcance edita las dos líneas igual. Lo que
  protegían pasó al comentario que acompaña a cada constante.
- **`/docs`, `/redoc` y `/openapi.json` quedan públicas en producción**, listadas con su motivo en
  `PUBLIC_ROUTES`.

Lo que **no** está acá: `GEN-09` completo. La mitad conductual —dos usuarios, filas de verdad, uno
intentando leer las del otro— necesita endpoints y base, y va con la feature que los construye.

### Bloqueos abiertos

- **`ADR-004` sigue en `Propuesta`**, y la tarea 15 (el seed con Argon2) depende de él. Un ADR
  en `Propuesta` no es autoridad y ningún plan lo puede citar (Artículo X).
- Nada más. `ADR-006` se enmendó el 2026-09-13: `MarketDataProvider` es una clase abstracta y su
  método de catálogo es `list_stocks(exchange)`, no el `search_stocks()` que `ADR-002` descartó.
- **La tarea 11 espera la firma del Artículo VI**, no un ADR: los tests están escritos y el gate
  es que los leas.

## Cobertura de requisitos

| Requisito | Tareas | Test |
|-----------|--------|------|
| REQ-18 — modelo de datos en PostgreSQL | 12 | |
| REQ-19 — seed mínimo para probar | 15 | |
| REQ-23 — repositorio con backend y frontend separados | 1 | |
| REQ-25 — frontend en React ≥ 18 | 5 | `frontend/tests/HealthPage.test.tsx` |
| Art. IV — fronteras entre módulos | 11 | `backend/tests/architecture/test_module_boundaries.py` |
| ADR-001 — clave natural y filtro de ingesta | 12, 14 | |
| ADR-002 — catálogo NYSE + NASDAQ | 14 | |
| ADR-006 — proveedor detrás de su interfaz | 13 | `backend/tests/architecture/test_provider_boundary.py` |
| ADR-007 — un comando para levantar todo | 2 | |
| ADR-009 — observabilidad | 8 | `backend/tests/architecture/test_dashboard_metrics.py` |
| SEC-06 — Argon2id para toda password | 10, 15 | |
| PY-08 — toda ruta declara su autorización | 11 | `backend/tests/architecture/test_route_authorization.py` |

`REQ-20` (publicar el repositorio), `REQ-21` (backup) y `REQ-22` (README) no están acá: son del
cierre, no del andamiaje (`docs/ROADMAP.md` → *Cierre*).
