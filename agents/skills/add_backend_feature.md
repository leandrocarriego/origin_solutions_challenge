# Skill — Agregar una feature de backend

Tags: [backend] [feature] [modulos]

## Objetivo
Implementar una capacidad nueva del backend respetando las fronteras entre módulos:
- la feature **vive adentro de un módulo**, no se reparte entre capas globales:
  `backend/app/modules/<módulo>/`
- si la capacidad no tiene dueño, se crea un **módulo nuevo** con su router, su service y su repository
- adentro del módulo sigue el flujo `router.py` → `service.py` → `repository.py` → `models.py`
- respeta la frontera: hacia adentro el flujo va en un solo sentido — nunca al revés, nunca salteado;
  hacia afuera, a un módulo se entra **sólo por su paquete** — lo que declara `__all__` en su
  `__init__.py`

## Cuándo usarla
- Agregar un endpoint o lógica de negocio nueva en el backend.
- Extender un módulo existente (`auth`, `stocks`, `favorites`, `quotes`).
- Crear un módulo nuevo: router + io + service + repository + models, con su `__init__.py`
  declarando el contrato.
- Exponer al resto del sistema algo que hoy es interno de un módulo (sumarlo al `__all__` de su
  `__init__.py`).

## Precondiciones
- Existe una `spec.md` aprobada en `docs/specs/<NNN-feature>/` y un `plan.md` con las decisiones técnicas.
- Está decidido a qué módulo pertenece la capacidad (ver *Dónde va el código* en `AGENTS.md`).
- El nombre del módulo está acordado y es `snake_case` (`PY-10`), en inglés, y nombra el dominio como
  lo nombra el negocio (`stocks`, `favorites`, `quotes`). Es **el mismo** en la carpeta, en el `prefix` del
  router y en el tag: `modules/favorites/` ↔ `/api/favorites` ↔ `tags=["favorites"]`.
- Están identificadas las tablas que el módulo va a ser dueño, los modelos y las integraciones que hagan falta.
- Si la feature necesita datos de otro módulo, está identificada **qué función de su `__all__`** los
  trae — o que hay que agregarla.

## Reglas (ESTRICTO)
- **Afuera: a un módulo se entra por su paquete. Nada más** (`GEN-02`). El contrato es lo que el
  `__init__.py` declara en `__all__`; cualquier ruta más profunda es interior ajeno y para el resto
  del sistema no existe. No hay excepción por nombre de archivo.
  - ✅ `from app.modules.stocks import get_stocks, StockInfo`
  - ✅ `from app.security import get_current_user, CurrentUser`
  - ✅ `from app.db import get_session`
  - ❌ `from app.modules.stocks.service import StockService` — cruza la frontera
  - ❌ `from app.modules.stocks.repository import StockRepository` — cruza la frontera
  - ❌ `from app.modules.stocks.models import Stock` — cruza la frontera

  `main.py` entra por la misma puerta que todos: `from app.modules.stocks import router`.

  Lo verifica `backend/tests/architecture/test_module_boundaries.py`, que lee los imports con `ast` y
  falla nombrando archivo y línea. Una regla sin excepciones se verifica más fácil y se explica en
  una línea.
- **Adentro: los archivos del módulo se importan entre sí por ruta completa** —
  `from app.modules.stocks.service import get_stocks`—, **nunca** por `app.modules.stocks`: eso
  reentra al `__init__` a medio inicializar y da un `ImportError` confuso.
- El `__init__.py` de un módulo contiene **sólo** docstring, imports y un `__all__` que es una lista
  literal de strings. Nada de lógica: hay un test que lo verifica. Y `no_implicit_reexport = true`
  en mypy hace cumplir el `__all__` (`PY-09`, Blocker).
- Adentro del módulo el flujo va en **un solo sentido**: `router` → `service` → `repository`.
  - ✅ `from app.modules.quotes.service import QuoteService` en `router.py`
  - ❌ `from app.modules.quotes.repository import QuoteRepository` en `router.py` — capa salteada
  - ❌ `from sqlalchemy import select` en `router.py` — la query es del repository
  - ❌ `from app.modules.quotes.service import QuoteService` en `repository.py` — dependencia invertida
- Cada pieza empieza como **archivo** y crece a **carpeta del mismo nombre** cuando molesta:
  `service.py` → `services/`, `repository.py` → `repositories/`, `router.py` → `routers/`,
  `models.py` → `models/`, `io.py` → `schemas/` (`schemas/io.py` + `schemas/<otros>.py`). El nombre
  no cambia, así que los imports de adentro no se enteran y la frontera sigue siendo la misma.
- Los nombres siguen `PY-10`: `snake_case` para funciones, métodos, variables y argumentos;
  `PascalCase` para clases; `UPPER_SNAKE_CASE` para constantes de módulo, siempre en mayúsculas;
  `_guion_bajo` adelante para lo privado del archivo —funciones, variables, constantes
  (`_DEFAULT_TTL`), métodos y clases auxiliares que no se usan fuera del archivo donde viven—. Nada
  de `__doble_guion_bajo` salvo que haya una razón escrita.
  Son **dos niveles de privacidad distintos**: el guión bajo marca lo privado del **archivo**;
  `__all__` marca lo público hacia **otros módulos**. Un nombre sin guión bajo que no está en
  `__all__` es interno del módulo: visible para sus hermanos, invisible para el resto del sistema.
- El módulo es **dueño de sus tablas**: ningún otro módulo las consulta, ni con `JOIN` ni importando
  sus modelos. Una lectura cruzada es una llamada a lo que el otro módulo exporta, en batch.
- El acceso a datos es **async** (SQLAlchemy 2.0 + asyncpg). No se abren sesiones sincrónicas.
- Los servicios **nunca** lanzan `HTTPException`: lanzan excepciones de dominio que derivan de
  `DomainError` (`app/errors.py`), y `app/main.py` las mapea a códigos HTTP.
- `app/` es sólo lo que cualquier módulo puede importar: `db.py`, `errors.py` y `security.py`
  (Argon2, JWT y `get_current_user`). No es un cajón de sastre: lo que usa un solo módulo vive
  adentro de ese módulo.
- Todo proveedor externo se consume detrás de su protocolo, y la salida al mundo vive en
  `app/providers/` (`GEN-08`): las dos cláusulas y sus comandos, en `CONVENTIONS.md`.
- Un módulo nuevo se justifica sólo cuando aparece un **dominio con vocabulario y tablas propias**, no
  cuando un módulo existente acumula funciones.

## Pasos (ORDEN OBLIGATORIO)

### 1) Decidir el módulo dueño de la capacidad
- Si el dominio ya tiene módulo → trabajar adentro de esa carpeta y saltar al paso 3.
- Si no lo tiene → crear el módulo nuevo (paso 2) y justificarlo en `plan.md`.
- Si lo que aparece es la excepción base, el acceso a la sesión o una primitiva de seguridad que
  consumen los routers de todos los módulos → va a `app/` (`errors.py`, `db.py`,
  `security.py`). Si es configuración → va a `app/settings.py`.
- Si la capacidad necesita datos de otro módulo, eso **no** la muda a ese módulo: se queda donde está
  y pide los datos entrando por el paquete del otro (paso 8).

### 2) Crear los archivos del módulo nuevo (sólo si hace falta)
```
app/modules/<módulo>/
├── __init__.py     — EL CONTRATO: docstring, imports y el `__all__` que otros módulos importan
├── router.py       — endpoints de FastAPI: rutas, códigos, autorización
├── io.py           — schemas de Pydantic de entrada y salida (el contrato HTTP)
├── service.py      — las decisiones del negocio · **no importa `fastapi`**
├── repository.py   — acceso a datos · **no decide nada**
└── models.py       — modelos de SQLAlchemy
```
Se empieza siempre con los archivos planos, con estos nombres y en `snake_case` (`PY-10`). Cada uno
crece a carpeta del mismo nombre recién cuando el archivo estorba — no antes, y nunca "por las
dudas".

El router, el service y el repository van juntos o no va ninguno: un service sin router es lógica
que nadie invoca, y un router sin service es una capa salteada (Artículo IV).

### 3) Definir los schemas (Pydantic)
- Escribir los modelos de request/response en `io.py` (o en `schemas/io.py`, si ya creció).
- Nombres descriptivos, tipos precisos y reglas de validación explícitas: los schemas son clases, o
  sea `PascalCase`, y sus campos `snake_case` (`PY-10`).
- Los schemas de `io.py` son el contrato **HTTP** y son internos del módulo: lo que viaja a otros
  módulos son los tipos que el `__init__.py` pone en `__all__`. Lo que el router recibe del service
  son schemas o tipos del dominio, nunca modelos de SQLAlchemy — un modelo que llega al borde HTTP
  arrastra la sesión y el acceso a datos con él.

### 4) Definir los modelos (SQLAlchemy 2.0, si hacen falta)
- Escribir los modelos en `models.py` con la sintaxis 2.0: `Mapped[...]` + `mapped_column(...)`. La
  clase es `PascalCase` en singular (`Stock`, `UserStock`); tabla y columnas, `snake_case` (`PY-10`).
- Las claves compuestas se declaran en `__table_args__` y son reales: `(user_id, symbol)` en
  favoritas, `(symbol, interval, ts)` en cotizaciones. Una restricción que el modelo no declara
  es una invariante que sólo existe en la cabeza de quien la escribió.
- Las tablas del módulo son del módulo. Si un modelo necesita apuntar a datos de otro, guarda la
  clave (`symbol`, `user_id`) y los datos se traen entrando por el paquete del otro, no con una
  relación cruzada.
- **CRÍTICO**: después de crear o modificar modelos, generar la migración de Alembic
  (ver `add_database_migration`).

### 5) Implementar el repositorio
- `repository.py` recibe una `AsyncSession` (`app.db`) y concentra todo el acceso a datos
  **del módulo**: consulta sus tablas y ninguna otra.
- Todos los métodos son `async` y están tipados. Los helpers que sólo usa este archivo van con guión
  bajo adelante (`_build_filters`), que es lo que marca lo privado del archivo (`PY-10`).
- El repositorio no aplica reglas de negocio ni conoce a FastAPI.

### 6) Implementar el servicio (lógica de negocio)
- `service.py` recibe su repositorio por inyección de dependencias.
- Lo que necesita de otro módulo lo pide entrando por el paquete de ese módulo
  (`from app.modules.stocks import get_stocks`), **en batch**: una llamada para toda la grilla, nunca
  una por fila. La grilla de "Mis Acciones" resuelve símbolo, nombre y moneda con
  `get_stocks(symbols)`; el mismo pedido adentro de un `for` es el N+1 que la frontera costó evitar.
- El proveedor externo llega inyectado como `MarketDataProvider`, nunca como un cliente HTTP
  propio: el service no sabe que del otro lado está TwelveData.
- Lanza excepciones de dominio (`NotFoundError`, `ConflictError`, `ValidationError`,
  `PermissionDeniedError`, …) que derivan de `DomainError`.
- Una falla del proveedor externo **no** se propaga cruda: se traduce a un `status` tipado
  (`stale`, `market_closed`, `no_data`) y se responde con lo último conocido (`ERR-05`).
- Los valores fijos del service son constantes en `UPPER_SNAKE_CASE`, con guión bajo adelante si no
  salen del archivo (`_DEFAULT_TTL = 60`) — nunca números sueltos adentro de una función (`PY-10`).

### 7) Implementar las rutas (endpoints)
- `router.py` define un `APIRouter` con `prefix` y `tags` propios del módulo.
- La sesión llega por dependencia: `Depends(get_session)` desde `app.db`.
- El usuario autenticado llega por `Depends(get_current_user)` desde `app.security`:
  `get_current_user` no es lógica de dominio de `auth`, es una primitiva de seguridad que consumen
  los routers de todos los módulos, y vive con Argon2 y JWT.
  - ✅ `from app.security import get_current_user, CurrentUser`
  - ❌ importar `get_current_user` desde `app.modules.auth`: no es de `auth`, y su paquete no lo
    exporta
- Las rutas sólo traducen HTTP ↔ servicio: sin lógica de negocio, sin consultas a la base.

### 8) Decidir qué exporta el módulo
- Primero la pregunta: ¿algún otro módulo necesita algo de esta feature? Si la respuesta es no, el
  `__init__.py` no se toca. Exportar de más es una frontera que ya empezó a filtrarse.
- Si la respuesta es sí, se exporta una **función** con tipos propios: se importa por ruta completa
  en el `__init__.py` y se la nombra en `__all__`.
  ```python
  # backend/app/modules/stocks/__init__.py
  """`stocks` — el catálogo de símbolos.

  Lo que está en `__all__` es el contrato: lo único que otros módulos pueden importar.
  Todo lo demás del paquete —io, service, repository, models, router— es interno.
  """
  from app.modules.stocks.io import StockInfo
  from app.modules.stocks.router import router
  from app.modules.stocks.service import get_stocks

  __all__ = ["StockInfo", "get_stocks", "router"]
  ```
  Nunca un modelo de SQLAlchemy, nunca el repository, nunca la sesión: eso es el interior del módulo
  con otro nombre.
- El `__init__.py` no hace nada más: docstring, imports y un `__all__` que es una lista literal de
  strings. Nada de lógica, y tampoco consulta la base — lo que exporta delega en el service o en el
  repository del módulo.
- La firma se piensa **en batch** desde el primer día. Una función que devuelve de a uno se termina
  llamando N veces y reintroduce el N+1.
- La vara para decidir qué va: `__all__` es la superficie que quedaría si mañana el módulo se
  extrajera a un servicio aparte. Lo que exportás hoy es el endpoint HTTP que tendrías que escribir
  entonces — si no lo escribirías, no lo exportes.
- Hoy el inventario completo de lecturas cruzadas del backend son **dos**: `get_stocks` y
  `StockInfo`, de `stocks`, que consume `favorites` para armar la grilla, e `is_favorite`, de
  `favorites`, que consume `quotes` para servir el gráfico sólo por las acciones de quien pregunta.
  Los `__init__.py` de `auth` y `quotes` exportan sólo su `router`; el de `favorites`, su `router` y
  `is_favorite`. Si tu módulo necesita exportar más, eso se justifica en `plan.md`.

### 9) Registrar el router en `main.py`
El registro es **explícito**: agregar en `backend/app/main.py`
```python
from app.modules.<módulo> import router as <módulo>_router

app.include_router(<módulo>_router)
```
`main.py` entra por el paquete, igual que cualquier otro módulo: por eso el `router` está en el
`__all__` del `__init__.py`. Un router nuevo no queda expuesto hasta que está registrado acá
(`GEN-04`). Y si la capacidad trae excepciones de dominio nuevas, su traducción a códigos HTTP va
también en `main.py`: es el *composition root*, el único lugar que conoce todos los módulos y todas
las excepciones.

### 10) Agregar tests
- Unitarios para la lógica del servicio (repositorio propio y funciones exportadas por otros módulos
  mockeados).
- De integración para endpoints y repositorio.
- Si la feature toca el provider, los tests van contra JSON fijado (fixtures), nunca contra
  TwelveData en vivo.
- Correr los tests de frontera: recorren `app/modules/` solos —incluido el que verifica que cada
  `__init__.py` sea sólo docstring, imports y un `__all__` literal—, así que un módulo nuevo entra
  sin configurarlos, pero tienen que pasar antes de dar la feature por hecha.
- Ver `add_tests`.

### 11) Actualizar la documentación
- Si aparece un módulo nuevo o se mueve la frontera entre módulos → actualizar la anatomía del
  backend en `ARCHITECTURE.md` y *Dónde va el código* en `AGENTS.md`.
- Si cambió el `__all__` de un módulo, documentar qué exporta y por qué: es contrato entre módulos,
  no detalle.
- Documentar los endpoints y el contrato en la spec de la feature.

## Validación
- El router está registrado en `app/main.py` y los endpoints responden lo esperado (`/docs` los
  muestra con su tag).
- Ningún import entra a otro módulo por debajo del paquete:
  ```bash
  cd backend && for m in app/modules/*/; do n=$(basename "$m")
    grep -rnE "from app\.modules\.[a-z_]+\." "$m" | grep -v "from app\.modules\.$n\."
  done
  ```
  (lo que aparezca entra al interior de otro módulo: se reemplaza por la entrada al paquete,
  `from app.modules.<otro> import <lo que exporta>`)
- Ningún archivo reentra a su propio paquete:
  ```bash
  cd backend && for m in app/modules/*/; do n=$(basename "$m")
    grep -rn "from app\.modules\.$n import" "$m"
  done
  ```
  (adentro del módulo se importa por ruta completa; entrar por el paquete carga un `__init__` a medio
  inicializar)
- No hay capas salteadas ni invertidas adentro del módulo. Verificar:
  ```bash
  cd backend && grep -rnE "from (sqlalchemy|app\.modules\.[a-z_]+\.repository)" app/modules/*/router.py app/modules/*/routers/ 2>/dev/null
  cd backend && grep -rn "fastapi" app/modules/*/service.py app/modules/*/services/ 2>/dev/null
  ```
  (lo primero caza un router que consulta la base o saltea el service; lo segundo, un service que
  conoce HTTP — ninguno de los dos debe devolver nada)
- Ningún servicio lanza `HTTPException`:
  ```bash
  cd backend && grep -rn "HTTPException" app/modules/*/service.py app/modules/*/services/ 2>/dev/null
  ```
- La salida al mundo no se escapó de `app/providers/` — el primer grep es el que importa: un
  service con `import httpx` arma la URL a mano y puede no nombrar al proveedor nunca:
  ```bash
  cd backend && grep -rnE "^\s*(import|from)\s+(httpx|requests|aiohttp|urllib\.request)\b" app | grep -v "^app/providers/"
  cd backend && grep -rni "twelvedata" app --include=*.py | grep -vE "^app/(providers/twelvedata\.py|settings\.py)"
  ```
- Los tests de arquitectura pasan: `cd backend && uv run pytest tests/architecture/`.
- Los tests unitarios y de integración pasan (`uv run pytest`).
- Hay migración creada y aplicada si se tocaron modelos.
- Los type hints están completos; `uv run ruff format app && uv run ruff check --fix app` sin errores
  y `uv run mypy app tests seed.py alembic` limpio (`PY-09`: `no_implicit_reexport` es lo que hace cumplir el `__all__`).
- Los nombres siguen `PY-10` (`snake_case`, `PascalCase`, `UPPER_SNAKE_CASE`, guión bajo adelante
  para lo privado del archivo): esto lo mira el review, no la herramienta.
- Sin dependencias circulares: ni entre las capas del módulo, ni entre módulos. Si A entra al paquete
  de B y B al de A, son un solo módulo con dos nombres.

## Errores comunes (evitar)
- Importar el `service`, el `repository`, los `models` o el `io` de otro módulo en vez de entrar por
  su paquete.
- Importar el propio módulo por su paquete (`from app.modules.stocks import ...` adentro de
  `stocks/`): adentro se importa por ruta completa.
- Hacer un `JOIN` contra la tabla de otro módulo, o mapearla con una relación cruzada.
- Poner lógica en el `__init__.py`, o armar `__all__` con algo que no sea una lista literal de
  strings.
- Exportar en `__all__` un modelo de SQLAlchemy, el repository o la sesión.
- Buscar `get_current_user` en `auth`: vive en `app.security`.
- Llamar adentro de un `for` a lo que exporta otro módulo: la firma se hace en batch.
- Poner lógica de negocio en el router (va en el service).
- Llamar al repository desde el router, salteando el service.
- Lanzar `HTTPException` desde un servicio.
- Instanciar un cliente HTTP del proveedor fuera de `app/providers/`.
- Convertir una pieza en carpeta antes de que el archivo moleste, o renombrarla al hacerlo
  (`service.py` crece a `services/`, no a `logic/`).
- Usar `app/` como cajón para lo que no se sabe dónde poner.
- Nombrar constantes en minúscula, clases en `snake_case`, o usar `__doble_guion_bajo` sin una razón
  escrita (`PY-10`).
- Abrir sesiones sincrónicas o usar la API vieja de SQLAlchemy (`Column`, `declarative_base`).
- Crear modelos sin migración de Alembic.
- Crear un módulo nuevo para algo que es una función más de un módulo existente.
- Olvidarse de registrar el router en `main.py`.
- Hardcodear valores (van a `Settings`, y toda variable nueva a `.env.example`).

## Troubleshooting
- Los modelos quedaron desincronizados → `add_database_migration`.
- Hace falta traer datos de TwelveData → `add_integration`.
- Un router necesita una query → **no**: la query va al repository y el router llama al service.
  Si eso resulta incómodo, el service está mal cortado: se corrige el corte, no la regla.
- Mi módulo necesita datos de otro → no importes su interior: usá lo que exporta su paquete, o
  agregalo a su `__all__` (paso 8), siempre en batch. Si ese `__all__` se llena de funciones que usa
  un solo módulo, la frontera está mal trazada: escalá al `Backend-Architect`.
- `ImportError` raro o un módulo "a medio inicializar" al arrancar → algún archivo del módulo se
  importó a sí mismo por el paquete. Pasalo a ruta completa:
  `from app.modules.<módulo>.service import ...`.
- Dos módulos se necesitan mutuamente → casi siempre son uno solo, o les falta un tercero del que
  ambos dependen. Escalá al `Backend-Architect`; no se rompe la frontera "por ahora".
