# Guía de Agentes — ORIGIN Acciones

**Este es el punto de entrada.**
Todo lo que un agente necesita para trabajar en este repositorio está acá, o se delega desde acá al documento que corresponda.

## El proyecto

**ORIGIN Acciones** es una aplicación web para seguir la cotización de acciones en tiempo real.
Los datos vienen de la API pública de **TwelveData**.

El desarrollo se dirige por **Spec-Driven Development (SDD)**, con comandos y plantillas propios **inspirados en GitHub Spec Kit**, que no está instalado ni es una dependencia.

## Orden de autoridad (OBLIGATORIO)

@CONSTITUTION.md

Cuando dos documentos se contradicen, gana el que está más arriba y se debe informar al usuario **human in the loop**.
Cuando un documento y un **test** se contradicen, gana el test: un test rompe el build, un documento no.

1. **`CONSTITUTION.md`** - los principios no-negociables. Autoridad número uno; todo `plan.md` se valida contra él (Constitution Check). **Leerlo siempre**, antes de proponer cambios.

2. **`AGENTS.md`** - este archivo: reglas del dominio, fronteras entre módulos, selección de rol, protocolo de skills, flujo de git, Definition of Done e idioma. Se carga solo en toda sesión.

3. **`ARCHITECTURE.md`** - estructura del repositorio. **No se importa siempre**: solo leerlo al tocar la estructura o mover código de lugar.

4. **`CONVENTIONS.md`** - las convenciones de código, fuente única: cada una con su identificador estable (`PY-04`, `TS-02`, `ERR-01`, …), su severidad y el comando que la verifica. Tampoco se importa: lo abre el `Developer` al escribir y el `Code-Reviewer` al revisar.

5. **`agents/roles/` y `agents/skills/`** - el rol bajo el que operás y los procedimientos paso a paso (`add_*`) que hay que seguir durante la implementación. Índice en `agents/skills/README.md`.

6. **`docs/PROJECT_BRIEF.md`** - el enunciado traducido a alcance verificable: los requisitos con su identificador (`REQ-01`…), la tabla de trazabilidad y las **ambigüedades declaradas** con su resolución (Artículo VII). Leerlo antes de definir o planificar una feature.

   **`docs/design/`** - la interfaz acordada: los **wireframes** (`wireframes/`) y los textos literales (`COPY.md`). Se abre antes de escribir o tocar cualquier pantalla.

7. **`docs/ROADMAP.md`** - cómo se corta el enunciado en features y en qué orden se construyen. Se lee al arrancar una feature nueva, para saber cuál toca y de qué depende.

8. **`docs/DECISIONS.md`** - las decisiones técnicas transversales (ADR-001…), las que valen para más de una feature: modelo de datos, caché de cotizaciones, autenticación, modos de falla. Una decisión que sólo afecta a una feature vive en su `plan.md`, no acá.

   **Nada entra a este archivo sin un acto explícito del humano** (Artículo X): un agente no agrega un ADR por iniciativa propia —ni siquiera en `Propuesta`— y nunca lo marca `Aceptada`. Un ADR en `Propuesta` **no es autoridad** y ningún `plan.md` lo puede citar.

## Reglas del dominio (INVIOLABLES)

Son los artículos **I, II, III, VII y X** de la constitución, que está importada arriba y por lo
tanto ya en contexto.
El enunciado completo y el *por qué es no negociable* de cada una viven en `CONSTITUTION.md`.

## Fronteras entre módulos (ESTRICTO)

El backend es un **monolito modular por dominios**: `auth`, `stocks`, `favorites`, `quotes`. Tres
fronteras, y las tres las verifica un test en `backend/tests/architecture/`:

> **1. El contrato de un módulo es su paquete: lo que declara `__all__` en su `__init__.py`.**
>
> **Afuera** se entra por el paquete. Cualquier ruta más profunda es interior ajeno y para el resto
> del sistema no existe.
>
> **Adentro** los archivos del módulo se importan entre sí por ruta completa, **nunca** por
> `app.modules.<modulo>`: eso reentra al `__init__` a medio inicializar y da un `ImportError`
> confuso.

```
❌ from app.modules.stocks.repository import StockRepository   # interior ajeno
❌ from app.modules.stocks.service import get_stocks           # interior ajeno
❌ from app.modules.stocks.models import Stock                 # interior ajeno
✅ from app.modules.stocks import get_stocks, StockInfo        # el paquete, lo que exporta
✅ from app.db import get_session

# adentro de stocks/, al revés:
✅ from app.modules.stocks.repository import StockRepository   # ruta completa entre hermanos
❌ from app.modules.stocks import get_stocks                   # reentra al __init__
```

El `__init__.py` de un módulo es **sólo** docstring, imports y un `__all__` que es una lista literal de strings.
Nada de lógica, y nada exportado que sea un modelo de SQLAlchemy: un contrato que devuelve el ORM no aisló nada.
Las dos cosas las verifica el test.

> **2. Adentro del módulo el flujo va `router` → `service` → `repository`**, en un solo sentido.
> Un router no importa SQLAlchemy; un service no importa `fastapi`.

> **3. Todo proveedor externo vive detrás de su interfaz, y la salida al mundo es `app/providers/`.**
> Ningún archivo de afuera importa un cliente HTTP (`httpx`, `requests`, `aiohttp`,
> `urllib.request`): un service que arma la URL a mano ya salió por la ventana, y puede no nombrar
> al proveedor nunca. El nombre `twelvedata` aparece sólo en `app/providers/twelvedata.py`.

Si este documento y un test se contradicen, **gana el test**: un test rompe el build, un documento
no. El porqué de cada una está en `CONSTITUTION.md` (Artículo IV); la anatomía del módulo y el
recorrido de una cotización, en `ARCHITECTURE.md`; el enunciado verificable con su severidad y su
comando, en `CONVENTIONS.md` (`GEN-02`, `GEN-03`, `GEN-05`, `GEN-08`, `PY-06`, `PY-10`).

### Dónde va el código

- el cliente de TwelveData y su protocolo → `app/providers/` (infraestructura: lo consumen `quotes` para las series y `stocks` para la ingesta del catálogo)
- transversal sin dominio (engine y sesión, `DomainError`, Argon2, JWT, `get_current_user`) → `app/` (`db.py` · `errors.py` · `security.py`)
- composición HTTP (registro de routers, handlers de error) → `app/main.py`

Y adentro del módulo: HTTP → `router.py` · schemas de entrada y salida → `io.py` · decisiones del
negocio → `service.py` · acceso a datos → `repository.py` · SQLAlchemy → `models.py` · lo que otros
módulos pueden usar → el `__all__` del `__init__.py`. **Cada uno de esos cinco archivos crece a
carpeta del mismo nombre** cuando el tamaño lo pide (`service.py` → `services/`, `io.py` →
`schemas/io.py` y los que hagan falta); el `__init__.py` no crece, porque es el contrato.

Un módulo nuevo se justifica cuando aparece **una capacidad del negocio con lenguaje propio**, no
cuando un archivo creció. Y antes de agregar un nombre al `__all__`: preguntarse si otro módulo lo
necesita de verdad — todo lo que entra ahí es superficie que hay que sostener.

### Estructura de las specs

Una carpeta por feature en `docs/specs/<NNN-feature>/`, numerada y correlativa.
El nombre es un identificador técnico **en inglés** (`001-authentication`) que la rama hereda tal cual; el contenido de los artefactos va en español.
Al entregarse, la carpeta pasa a `archive/` y su número no se reutiliza nunca.

Qué artefacto escribe cada rol, cuáles son opcionales y cómo se encadenan: **`docs/specs/README.md`**.

## Roles de agente (OBLIGATORIO)

Este repositorio define roles explícitos en `agents/roles/`.

### Rol por defecto

Si el usuario no especifica un rol, el agente DEBE asumir:
- **Lead**

Definido como alias en `agents/roles/default.md`.
Consecuencia deliberada: por defecto el agente **orquesta y delega**, no escribe código.
Para trabajar directamente sobre el código hay que asumir un rol que lo permita.

### Selección automática de rol

El agente DEBE disparar agentes en segundo plano con el rol que corresponda según la tarea y supervisarlos:

- Orquestar el trabajo, delegar a subagentes, verificar consistencia spec ↔ plan ↔ tasks y correspondencia código ↔ spec → `Lead`.

- Crear o actualizar la definición funcional de la solución (requerimientos, alcance, user stories) →  `Solution-Designer`.

- Arquitectura de backend, fronteras entre módulos o decisiones de FastAPI → `Backend-Architect`
- Arquitectura de frontend o decisiones de React/Vite → `Frontend-Architect`
- Escribir los tests de una feature **antes** de que exista su implementación, extender la suite, cobertura y casos borde. Ejecutar los tests y realizar pruebas manuales → `Tester`
- Poner en verde los tests ya aprobados, implementar features nuevas o cambios del cliente → `Developer`
- Revisar cambios / review de PR / quality gate → `Code-Reviewer`
- Commitear/pushear un cambio testeado y abrir un PR → `Release-Manager`

### Cadena de un feature

Los roles no son intercambiables: tienen un orden, y **tres** de sus pasos son gates.

```
                    ┌─────────────── Lead ───────────────┐
                    │   orquesta · delega · /analyze      │
                    └─────────────────┬──────────────────┘
  docs/PROJECT_BRIEF.md  ─── el enunciado traducido a alcance verificable
  Solution-Designer   ──►  /specify · /clarify              →  spec.md
                           ✍️  GATE: firma del cliente (/approve-spec)
  Architect (back/front) ──►  /plan · /tasks   →  plan.md (Constitution Check) · tasks.md
  Tester              ──►  los tests de la historia, en rojo: unitarios,
                           integración, E2E y casos borde
                           ✍️  GATE: aprobación humana (/approve-tests)
  Developer           ──►  /implement: pone en verde los tests aprobados
  Lead                ──►  /converge: ¿el código es lo que se firmó?
  Code-Reviewer       ──►  🚦 GATE de calidad (/review-feature)
  Release-Manager     ──►  /ship → PR contra `main`, y la spec pasa a archive/
```

Tres inversiones que son errores, no variantes:

- El **Solution-Designer va antes que el arquitecto**. La spec es el input del `/plan`; al revés se
  estaría resolviendo técnicamente un alcance que el cliente no firmó, y el gate deja de serlo.

- El **Tester va antes que el Developer**, y escribe **todos** los tests: también los unitarios de
  la lógica pura. Es el Artículo VI, y lo que compra es que el humano fije qué significa
  "terminado" **antes** de que exista una implementación que defender. Un test escrito después
  describe lo que el código hace; escrito antes, describe lo que tiene que hacer.

- El **Code-Reviewer va último**. Verifica que los tests aprobados sigan siendo los que corren: si
  llegara antes, el gate de calidad aprobaría código cuyo contrato todavía nadie firmó.

Consecuencia de la inversión, y hay que asumirla: **el `plan.md` pasa a ser load-bearing.** El
Tester escribe contra módulos, services, firmas y endpoints que todavía no existen, así que el plan
tiene que fijarlos. Si el plan no alcanza para escribir el test, se vuelve a `/plan` — no se
inventa la firma ni se espera a que el Developer la decida.

`debug` es transversal: se dispara en cualquier paso, bajo el rol del área afectada.

### Qué comandos existen hoy

| Paso de la cadena | Comandos |
|---|---|
| Definir el alcance | `/specify` · `/clarify` · `/approve-spec` |
| Planificar | `/plan` · `/tasks` · `/analyze` |
| Construir | `/approve-tests` · `/implement` |
| Cerrar | `/converge` · `/review-feature` · `/ship` |
| Transversales | `/status` (radiografía del proyecto) |

**Ningún comando contiene su procedimiento**: los doce son punteros de una línea a una skill, que
es donde vive el procedimiento y que cualquiera puede seguir a mano.
Consecuencia práctica: **una regla nueva va en la skill, nunca en el comando.**
El porqué, en `agents/skills/README.md`.

### Regla de invocación del rol

Antes de planificar o editar código, el agente DEBE:

1. Seleccionar el rol (por defecto o auto-seleccionado),
2. Seguir las prioridades y restricciones del rol,
3. Aplicar el protocolo de *Skills* de este documento.

## Gestión de dependencias (ESTRICTO)

Backend con **uv**, frontend con **npm**, sin excepciones.
Las reglas y sus comandos están en `CONVENTIONS.md` → `DEP-01` a `DEP-04`.
Violarlas es **Blocker** en el review.

## Skills (OBLIGATORIO)

Las skills están definidas en `agents/skills/` y se identifican por **nombre**, no por orden numérico.

Para cualquier tarea, el agente DEBE:

1. Identificar la categoría de la tarea.
2. Verificar si existe una skill que aplique: el índice de `agents/skills/README.md` es la fuente.
3. Seguir los pasos de la skill en orden.
4. Ejecutar la "Validación" de la skill antes de declararla completa.
5. Desviarse sólo si se lo indican explícitamente.

Si aplican varias skills, la prioridad es **safety/debug → fronteras → implementación**.

**Enforcement:** cuando se dispara una skill, sus pasos DEBEN seguirse en orden y su validación DEBE completarse antes de declarar el éxito.
Si un paso no se puede ejecutar, el agente se detiene y pide aclaración.
Saltearse una skill existente se considera un error.

### Dónde está el mapa

El índice completo (cada skill con su comando, su rol dueño y para qué sirve) está en **`agents/skills/README.md`**.
No se duplica acá: una skill nueva se registra en un solo lugar, y un índice que deriva de otro se desincroniza el día que alguien agregue una.

## Reglas de código (ESTRICTO)

Las convenciones de código viven en **`CONVENTIONS.md`**, que es su fuente única: ahí está cada regla con su identificador estable (`PY-04`, `TS-02`, `ERR-01`, …), su severidad y el comando que la verifica.

Si una convención no está ahí, no es una convención del proyecto.

Lo que gobierna este documento es el enforcement:

- Violar una convención marcada como **Blocker** frena el review: se arregla o el changeset no pasa (`agents/skills/review_feature.md`).

- Nueve convenciones no dependen de que alguien las lea, porque las verifica un test que rompe el
  build: `GEN-02` (la frontera entre módulos), `PY-06` (el flujo adentro del módulo), `GEN-08` (el
  proveedor detrás de la interfaz), `GEN-09` (aislamiento por usuario), `PY-08` (autorización de
  rutas), `TEST-03` (la suite sin red ni API key), `TEST-05` (cobertura), y `UI-02` y `UI-03` en el
  frontend.
  El detalle de cuál frena el pre-commit y cuál el CI está en `CONVENTIONS.md` → *Convenciones verificadas por un test que rompe el build*.
  El resto depende del `Developer` que las aplica y del `Code-Reviewer` que las recorre.

- Las reglas del dominio (INVIOLABLES) de más arriba y las fronteras entre módulos siguen siendo de este documento y de `ARCHITECTURE.md`; `CONVENTIONS.md` las referencia, no las reemplaza.

## Flujo de Git (ESTRICTO)

`main` es la rama estable y desplegable.
Rama por feature (`feat/<NNN-feature>`), quality gate antes del merge, y el PR lo abre `/ship`.

**NUNCA commitear directo a `main`.**

La convención de ramas y el formato de los mensajes están en `CONVENTIONS.md` → `GIT-01` a `GIT-04`.

## Definition of Done

- El código compila y pasa los chequeos de tipos (`PY-09`, `TS-01`).

- Los tests se escribieron **antes** de la implementación y el humano los aprobó, con quién y cuándo registrado en `tasks.md` (Artículo VI, `/approve-tests`). Los que corren son los que se firmaron: si alguno cambió después, volvió a firmarse.

- Existen tests unitarios de la lógica pura y de integración de endpoints y base de datos (`TEST-01`, `TEST-02`), y la cobertura no bajó (`TEST-05`).

- El proveedor se testea contra JSON fijado: **la suite corre sin red y sin API key** (`TEST-03`).

- No hay violaciones de las fronteras: ningún módulo importa el interior de otro (`GEN-02`), el flujo adentro del módulo va en un solo sentido (`PY-06`), todo proveedor externo se consume detrás de su interfaz en `app/providers/`, y ningún archivo de afuera importa un cliente HTTP (`GEN-08`) y ninguna query de datos del usuario confía en un id del request (`GEN-09`).

- Los modelos de base de datos están sincronizados con las tablas (`DB-01`).

- **Toda pantalla nueva o tocada reproduce su diseño** (`UI-01`) y usa los textos literales del enunciado (`UI-02`); los avisos de estado van arriba del dato que califican (`UI-05`).

- Los modos de falla del proveedor están cubiertos (`ERR-05`).

- El alta de favoritas es idempotente (`TEST-04`).

- Ninguna convención de `CONVENTIONS.md` marcada como **Blocker** quedó violada.

- `plan.md` tiene su sección de **Contexto de traspaso** y sigue siendo verdad.

- La columna **Test** de la tabla de trazabilidad de `docs/PROJECT_BRIEF.md` quedó completa para los requisitos que la feature cubre.

- Ningún ADR nuevo entró a `docs/DECISIONS.md` sin que el humano lo pidiera, y ninguno quedó marcado `Aceptada` por un agente (Artículo X).

- La documentación está actualizada si hacía falta.

## Comandos

La puesta en marcha y los comandos de backend, frontend e infraestructura están en `README.md`, y el `Makefile` es su fuente ejecutable (`make help`). No se duplican acá.

Los comandos que **verifican una convención** viven en `CONVENTIONS.md`, junto a la convención que verifican.

## Idioma (Artículo VIII)

Documentación y artefactos de spec en **español**; código, commits y docstrings en **inglés**.

Los strings que ve el usuario en español y **verbatim de `docs/design/COPY.md`**.
La excepción son los **nombres** de carpeta de spec y de rama, que son identificadores técnicos y van en inglés.
Las respuestas en el chat, en español.

`spec.md` es además el artefacto **cara al cliente**: no lleva decisiones técnicas (nada de stack,
APIs, schemas ni rutas de archivo). Eso va en `plan.md`.
