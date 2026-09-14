# Skill — Revisar una feature (Code Review)

Tags: [review] [calidad] [quality-gate]

## Objetivo
Revisar los cambios de una feature para asegurar fiabilidad, mantenibilidad, respeto de las
fronteras entre módulos y cumplimiento de las convenciones de `CONVENTIONS.md`.

> Las convenciones no se reproducen acá. `CONVENTIONS.md` es su fuente única: tiene el texto de
> cada una, si es **Blocker** y el comando que la verifica. Este checklist dice **en qué orden se
> recorren** y qué mirar además de ellas.

## Cuándo usarla
- Cualquier PR o conjunto de cambios que agregue o modifique:
  - features de backend o de frontend
  - módulos del backend o sus fronteras
  - modelos de base de datos
  - endpoints de la API
  - componentes o páginas
  - la integración con TwelveData o la caché de cotizaciones


## Lo esencial (leer antes de arrancar)

- La pregunta de este gate es **"¿está bien escrito?"**. La pregunta *"¿es lo que se acordó?"* es
  de `converge`, y son gates distintos.
- Recorrer `CONVENTIONS.md` → *Índice de Blockers*: **18 hallazgos sobre 34 convenciones**. Citar
  por identificador (`"esto viola PY-06"`), sin copiar el texto de la regla.
- Nueve convenciones ya las verifica un test que rompe el build (`GEN-02`, `PY-06`, `GEN-08`,
  `GEN-09`, `PY-08`, `TEST-03`, `TEST-05`, `UI-02`, `UI-03`): si la suite corrió y pasó, no se
  revisan a ojo. **Si no corrió, el review no arranca.** Las dos de interfaz están en la suite del
  frontend (`npm test`), así que "la suite" son las dos.
- Un Blocker frena el merge: se arregla, o el changeset no pasa. No hay excepción de agente.
- Terminar con un veredicto explícito —**aprobado** o **bloqueado**— y, si está bloqueado, la
  lista de Blockers por identificador.

Rol: `agents/roles/code_reviewer.md`. Sin argumento, se revisa la rama actual contra `main`.

## Precondiciones
- **La suite corrió y pasó**, la del backend y la del frontend. Nueve convenciones las verifica un
  test que rompe el build (`GEN-02`, `PY-06`, `GEN-08`, `GEN-09`, `PY-08`, `TEST-03`, `TEST-05`,
  `UI-02`, `UI-03`): si no corrió, el review no arranca.
- El `Tester` ya pasó: el reviewer verifica que existan tests, no los escribe.
- **La firma del Artículo VI existe**: `tasks.md` dice quién aprobó los tests y cuándo, y esa fecha
  es anterior a los commits de implementación. Un changeset sin esa firma está **bloqueado**, aunque
  la suite esté verde: el gate es que el contrato se acordó antes, no que el código funciona.

## Pasos (ORDEN OBLIGATORIO) — el checklist de revisión

### 0) Contexto de traspaso
- `docs/specs/<NNN-feature>/plan.md` tiene su sección **Contexto de traspaso**, y sigue siendo
  verdad después de la implementación. Si el código tomó un camino distinto al que el plan
  decidió, el plan se actualiza: un plan que ya no describe lo construido no sirve para el
  próximo que lo lea.
- Empezá el review por su subsección *"Qué necesita mirar el Reviewer"*: dice dónde está el
  riesgo real del cambio y qué invariantes hay que verificar. No reemplaza al checklist, lo
  ordena.

### 1) Fronteras entre módulos
- `GEN-02` — a un módulo se entra **por su paquete**, y su contrato es lo que declara `__all__` en
  el `__init__.py`. Son dos cláusulas y las dos son la regla:
  - **Afuera:** `from app.modules.stocks import get_stocks, StockInfo`. Cualquier ruta más profunda
    (`app.modules.stocks.service`, `app.modules.stocks.models`) es interior ajeno y para el resto
    del sistema no existe.
  - **Adentro:** los archivos del módulo se importan entre sí por ruta completa
    (`from app.modules.stocks.service import get_stocks`), **nunca** por `app.modules.stocks`: eso
    reentra al `__init__` a medio inicializar y revienta con un `ImportError` confuso.
  No hay excepción por nombre de archivo. `get_current_user` tampoco la tiene, y además no es de
  `auth`: es una primitiva de seguridad y vive en `app/security.py`. Una regla sin
  excepciones se verifica con `ast` y se explica en una línea. En el diff, mirado desde otro
  módulo, toma estas formas concretas, y las cuatro primeras son Blocker:
  - ❌ `from app.modules.stocks.repository import StockRepository`
  - ❌ `from app.modules.stocks.service import StockService`
  - ❌ `from app.modules.stocks.models import Stock`
  - ❌ `get_current_user` importado desde `app.modules.auth` — ahí ya no vive
  - ✅ `from app.modules.stocks import get_stocks, StockInfo`
  - ✅ `from app.security import get_current_user, CurrentUser`
  - ✅ `from app.db import get_session`
  Herramienta al lado del test: `no_implicit_reexport = true` hace que mypy (`PY-09`, Blocker)
  marque el nombre que se importa de un paquete que no lo exporta.
- El `__init__.py` de un módulo tiene **sólo** tres cosas: docstring, imports y un `__all__` que es
  una lista literal de strings. Nada de lógica —ni un `if`, ni una constante calculada, ni un
  registro de nada—: un contrato que se ejecuta deja de ser un contrato. Lo verifica un test.
- `PY-06` — adentro del módulo el flujo sigue siendo `router` → `service` → `repository`, en un
  solo sentido: nunca al revés y nunca salteado. En el diff toma dos formas concretas: un
  `select()` dentro de una ruta y un `HTTPException` dentro de un service. Comando y detalle en
  `CONVENTIONS.md`.
- `GEN-03` — nada por debajo de los módulos importa un módulo, y son dos capas. El kernel
  (`app/*.py`): `db.py` (engine async, `Base`, `get_session`), `errors.py` (`DomainError`) y
  `security.py` (Argon2, JWT, `get_current_user`, `CurrentUser`) — lo único que cualquier módulo
  puede importar. Y la infraestructura (`app/providers/`), que es la salida al mundo y la consumen
  dos módulos. Ninguna de las dos importa de `modules/`: se depende de ellas, no dependen. La
  excepción es `main.py`, el composition root. Un import de un módulo acá invierte la dependencia
  y arrastra medio backend a cada excepción de dominio.
- `GEN-05` — no hay ciclos entre módulos. Si `favorites` importa de `stocks` y `stocks` importa de
  `favorites`, son un módulo solo con dos nombres y el corte está mal hecho: eso se escala al
  `Backend-Architect`, no se resuelve agregando el segundo import.
- `GEN-08` — todo proveedor externo vive detrás de su interfaz en `app/providers/`. Se revisan
  **dos** cosas: que ningún archivo fuera de esa carpeta importe un cliente HTTP (`httpx`,
  `requests`, `aiohttp`, `urllib.request`), y que el nombre `twelvedata` aparezca sólo en
  `app/providers/twelvedata.py` y `app/settings.py`. La primera es la que importa: un service con
  `import httpx` ya salió al mundo por la ventana, y puede no nombrar al proveedor nunca. Un
  provider tampoco toca la base: trae datos de afuera y los devuelve como tipos del dominio.
- `GEN-02`, `PY-06`, `GEN-08`, `GEN-09` y `PY-08` las verifican los tests de
  `backend/tests/architecture/` (`test_module_boundaries.py` —lee los imports con `ast` y falla
  nombrando archivo y línea, y además chequea que cada `__init__.py` sea sólo docstring, imports y
  un `__all__` literal—, `test_provider_boundary.py`,
  `test_route_authorization.py`) y `backend/tests/integration/test_user_isolation.py`: si la suite
  pasó, están verificadas. Si no corrió, el review no arranca.
- `GEN-04` — el router del módulo nuevo está montado explícitamente en `app/main.py`, que es el
  *composition root*: monta el router de cada módulo, el CORS, y es el único lugar que traduce
  `DomainError` a códigos HTTP. Entra por la misma puerta que todos:
  `from app.modules.stocks import router`.
- El código está en la pieza que le corresponde: las rutas, los códigos y la autorización en
  `router.py`, los schemas de entrada y salida en `io.py`, las decisiones en `service.py`, el
  acceso a datos en `repository.py`, las tablas en `models.py`, y en el `__all__` del `__init__.py`
  **sólo** lo que otro módulo necesita — si nadie lo importa, no hay nada que exportar. Una
  capacidad nueva (`auth`, `stocks`, `favorites`, `quotes`) es un módulo entero: su router, su
  service y su repository — los tres, o ninguno (`ARCHITECTURE.md`).
- Cada pieza empieza como archivo y crece a carpeta cuando hace falta: `router.py` → `routers/`,
  `io.py` → `schemas/` (con `schemas/io.py` adentro y `schemas/<otros>.py` al lado), `service.py` →
  `services/`, `repository.py` → `repositories/`, `models.py` → `models/`. Lo que no puede quedar
  es la convivencia: si el diff agrega la carpeta, el archivo viejo se fue en el mismo commit.
- La lectura cruzada va en **batch**. La grilla de "Mis Acciones" necesita símbolo, nombre y
  moneda; `user_stocks` vive en `favorites/` y `stocks` en `stocks/`, así que se resuelve con
  `get_stocks(symbols: list[str]) -> list[StockInfo]`, que `stocks` exporta en su `__all__`: una
  sola consulta para toda la grilla. Una llamada por símbolo adentro de un `for` es N+1 y es
  hallazgo aunque respete la frontera. La otra es el gráfico del Detalle, que se sirve sólo por las
  acciones que el usuario tiene en su lista: `is_favorite(session, user_id, symbol) -> bool`, que
  `favorites` exporta y `quotes` consume — un símbolo por request, así que no hay N+1 posible. Ese
  es el inventario **completo** de lecturas cruzadas del backend: `auth` y `quotes` exportan sólo su
  `router`, `favorites` su `router` y `is_favorite`. Un `__all__` que crece en el diff se justifica
  o se saca.

---

### 2) Reglas del dominio (INVIOLABLES)
Las cinco reglas están en `AGENTS.md` → "Reglas del dominio (INVIOLABLES)". En el changeset se
verifican por sus convenciones:

- `GEN-06` — la API key vive sólo en el backend, ninguna consulta al proveedor ocurre si el dato
  está en la base, toda query de datos del usuario filtra por el token, y el proveedor se consume
  por `MarketDataProvider`. Los comandos (`grep` sobre `frontend/src` y `backend/app`) están en
  `CONVENTIONS.md`.
- `ERR-05` — una falla del proveedor se traduce a un `status` tipado y se responde con lo último
  conocido; un 429 de TwelveData nunca llega al navegador.
- `SEC-06` — toda password persistida va hasheada con Argon2id, el seed incluido. Texto plano o
  un hash de propósito general (`md5`, `sha*`, `hashlib`) es Blocker sin discusión: esas funciones
  son rápidas a propósito, que es lo contrario de lo que se quiere acá.
- `SEC-02` — la API key vive sólo en el entorno del backend y se lee en un único lugar,
  `app/settings.py`: no está en el código, ni en la base, ni en un log, ni en una variable `VITE_*`.

Violar cualquiera de estas reglas es **Blocker**.

---

### 3) Cumplimiento de skills
- Feature de backend o módulo nuevo → se siguió `add_backend_feature`.
- Feature de frontend → se siguió `add_frontend_feature`.
- Feature full-stack → se siguió `add_feature`.
- Cambios en modelos → se siguió `add_database_migration`.
- Integración con un sistema externo → se siguió `add_integration`.
- Se tocó el cliente de TwelveData → se siguió `add_integration`.
- Cambió la spec o el alcance → se siguieron `/specify` y `/clarify`.

---

### 4) Convenciones de código (`CONVENTIONS.md`)

Se recorre el documento **entero**, por área, y cada hallazgo se cita por su identificador
(`"esto viola PY-06"`). No hace falta copiar el texto de la regla en el comentario del review.

Primero, lo que ya está verificado y no se revisa a ojo:

```bash
cd backend && uv run ruff format --check app tests && uv run ruff check app tests  # GEN-01, PY-07
cd backend && uv run mypy app tests seed.py alembic                                             # PY-09
cd backend && uv run pytest   # GEN-02, PY-06, GEN-08, GEN-09, PY-08, TEST-03, TEST-05
cd frontend && npx tsc --noEmit                                                    # TS-01
cd frontend && npm run lint && npm run format:check                        # TS-02, TS-04
cd frontend && npm test                                                    # UI-02, UI-03
```

Si algo de eso está en rojo, el review se frena ahí: son Blockers que el `Developer` tenía que
resolver antes de pedirlo.

Después, área por área — el detalle y el comando de cada una están en `CONVENTIONS.md`:

| Área | Recorrer | Los Blockers del área |
|---|---|---|
| Python | `PY-01` … `PY-10` | `PY-01`, `PY-02`, `PY-04`, `PY-05`, `PY-06`, `PY-07`, `PY-08`, `PY-09` |
| TypeScript y frontend | `TS-01` … `TS-07` | `TS-01`, `TS-02`, `TS-04` |
| Diseño de interfaz | `UI-01` … `UI-06` | `UI-01`, `UI-02` |
| Manejo de errores | `ERR-01` … `ERR-07` | `ERR-01`, `ERR-03`, `ERR-04`, `ERR-05` |
| Configuración y secretos | `SEC-01` … `SEC-06` | `SEC-01`, `SEC-02`, `SEC-06` |
| Dependencias | `DEP-01` … `DEP-04` | `DEP-01`, `DEP-02`, `DEP-03` |
| Git y commits | `GIT-01` … `GIT-04` | `GIT-01`, `GIT-03` |

En el frontend, `UI-02` y `UI-03` las decide la suite; el resto de los `UI-*` se mira a ojo y son
justamente los que sostienen la pantalla: la estructura del wireframe (`UI-01`), la plata y las
fechas en mono tabular (`UI-04`), el aviso arriba del número que califica (`UI-05`) y un solo tema,
el claro (`UI-06`). **Si el changeset toca una pantalla, se abre `docs/design/` y se compara.**

`PY-10` es nueva y se mira en cada nombre que el diff agrega: `snake_case` para funciones, métodos,
variables y argumentos; `PascalCase` para clases; `UPPER_SNAKE_CASE` para las constantes de módulo,
siempre en mayúsculas; `_guion_bajo` adelante para lo privado del archivo —funciones, variables,
constantes (`_DEFAULT_TTL`), métodos y clases auxiliares que no se usan afuera del archivo donde
viven—; y nada de `__doble_guion_bajo` (name mangling) salvo que haya una razón escrita al lado.
El guión bajo y el `__all__` son **dos niveles de privacidad distintos**: el guión bajo marca lo
privado del ARCHIVO, el `__all__` marca lo público hacia OTROS MÓDULOS. Un nombre sin guión bajo
que no está en `__all__` es interno del módulo: lo ven sus hermanos, no lo ve el resto del sistema.

Los que más se escapan porque **ninguna herramienta los detecta**, y por eso hay que mirarlos a
mano: `SEC-04` (valores hardcodeados) y `ERR-02` (mensajes de error que no le sirven a quien los
lee). Los otros tres que solían estar en esta lista —`PY-03`, `PY-04` y `ERR-01`— pasaron a
verificarse solos: `PLC0415` y `BLE001` de Ruff, y `mypy` con `strict = true`. Lo que sí queda
para el ojo humano de `ERR-01` es el **`noqa: BLE001` sin razón escrita**, que la herramienta no
puede juzgar.

Testing y base de datos tienen sección propia más abajo.

---

### 5) Testing
- `TEST-01` y `TEST-02` — hay tests unitarios de la lógica (services, detección de huecos) y de
  integración de endpoints y repositorios.
- `TEST-03` — el proveedor se testea contra JSON fijado, **nunca** contra TwelveData en vivo; la
  suite corre sin red y sin API key.
- `TEST-04` — el alta de favoritas tiene test de idempotencia.
- `TEST-05` — la cobertura no bajó del 80% (`--cov-fail-under=80`: lo verifica la corrida).
- `TEST-06` — no se debilitó ningún test para pasar el gate. Mirá el diff de `tests/`, no sólo el
  resultado en verde.

---

### 6) Sincronización de base de datos
- `DB-01` y `DB-02` — los modelos están sincronizados con las tablas; no hay cambios en la base sin
  su migración de Alembic. Cada tabla vive en el `models.py` de su módulo y en uno solo: `users` en
  `auth/`, `stocks` en `stocks/`, `user_stocks` en `favorites/`, `quotes` en `quotes/`.
- `DB-03` — los modelos usan `Mapped[...]` + `mapped_column(...)` y las claves compuestas son
  reales: `user_stocks` por `(user_id, symbol)` y `quotes` por `(symbol, interval, ts)`, no un `id`
  autoincremental con un `UniqueConstraint` al lado.
- `DB-04` — la migración autogenerada fue leída antes de commitearse.

---

### 7) Fidelidad al enunciado
- Toda pantalla tocada reproduce su wireframe de `docs/design/wireframes/` (`UI-01`).
- Los textos visibles son los de `docs/design/COPY.md`, verbatim y sin "corregir" las faltas
  del enunciado (`UI-02`).
- La columna **Test** de la tabla de trazabilidad de `docs/PROJECT_BRIEF.md` está **asignada a
  `/ship`** para los requisitos que la feature cubre: nadie la completó antes de tiempo ni la dejó
  sin dueño. **No se verifica que esté completa**, porque no es de este paso: `docs/specs/README.md`
  → *Al entregar* la asigna a `ship_changes`, que la completa **en el commit de la feature** (el
  archivado de la spec es un changeset propio y posterior, después del deploy), y `AGENTS.md`
  → *Estructura de las specs* le delega a ese documento qué artefacto escribe cada rol — una skill
  no lo puede sobrescribir. Exigirla completa acá produce un hallazgo falso.

---

## Validación
- `CONVENTIONS.md` se recorrió entero y cada hallazgo cita su identificador.
- El revisor puede trazar el recorrido: request → `router.py` del módulo → `service.py` →
  `repository.py` → respuesta, y todo lo que el módulo necesitó de otro entrando por el paquete
  del otro y estando en su `__all__`.
- Un desarrollador nuevo puede entender la feature leyendo el código, correr los tests y
  desplegar sin sorpresas.
- No quedan Blockers sin resolver.

## Formato de salida (comentarios del review)
- Citar la convención por su identificador (`PY-06`, `ERR-04`, …). Es lo que hace el hallazgo
  discutible sin ambigüedad y verificable por el `Developer`.
- Clasificar los hallazgos con la severidad que `CONVENTIONS.md` le da a cada convención:
  - **Blocker**: frena el merge
  - **Major**: mantenibilidad, manejo de errores, nombres (`PY-10`), altas no idempotentes o
    falta de tests
  - **Minor**: formato, claridad
- Dar sugerencias de arreglo concretas y accionables.
- Si un hallazgo no corresponde a ninguna convención existente, decilo: o es una preferencia
  personal (y entonces no bloquea), o falta una convención y hay que agregarla a `CONVENTIONS.md`,
  con su identificador y su severidad.
