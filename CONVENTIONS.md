# Convenciones de código - ORIGIN Acciones

Este documento es la **fuente única** de las convenciones de código del proyecto.

Lo usan dos roles, con dos lecturas distintas:

- el **Developer**, mientras escribe: qué se puede y qué no, con el comando que lo verifica antes de pedir el review;

- el **Code-Reviewer**, mientras revisa: la lista que recorre entera, citando el identificador de cada hallazgo (`"esto viola PY-06"`) en lugar de reescribir la regla.

**Si una convención no está acá, no es una convención del proyecto.**

No hay ni debe haber reglas de código en `AGENTS.md`, en `ARCHITECTURE.md`, en los roles ni en las skills: ahí hay punteros a este archivo.

## Cómo leer una entrada

Cada convención tiene tres cosas:

1. **Un identificador estable** (`PY-04`, `TS-02`, `ERR-01`, …). No cambia cuando el documento se reordena, y **no se reutiliza** si la convención se elimina: el retirado queda listado al final y su número queda como hueco.

2. **Su severidad**: `Blocker` frena el review; `Major` y `Minor` se anotan y vuelven al rol dueño. Un Blocker no se negocia en el review: se arregla o el changeset no pasa.

3. **Su verificación**, cuando existe: el comando que la prueba.

## Convenciones verificadas por un test que rompe el build

Esta es la distinción más importante del documento.

Estas nueve convenciones **no dependen de que alguien las lea**: hay un test que falla, y la suite no pasa.

**Dónde se verifican.** El hook `pytest-fast` del pre-commit corre `tests/unit` y `tests/architecture`, así que `GEN-02`, `PY-06`, `PY-08`, `GEN-08` y `GEN-09` frenan el commit antes de que salga de la máquina.

`TEST-03` y `TEST-05` miden la suite completa y por eso se verifican en CI (`.github/workflows/ci.yml`), junto con integración y `alembic check`. `UI-02` y `UI-03` son del frontend: las corre `npm test` (vitest), también en CI.

| Convención | Verificada por | Qué pasa si se viola |
|---|---|---|
| `GEN-02` | `backend/tests/architecture/test_module_boundaries.py` | La suite falla nombrando archivo y línea: del import que entra a otro módulo por debajo de su paquete, del que reentra al propio paquete en vez de usar la ruta completa, y del `__init__.py` que tiene algo más que docstring, imports y un `__all__` literal. |
| `PY-06` | `backend/tests/architecture/test_module_boundaries.py` | La suite falla nombrando archivo y línea del import que cruza las capas adentro del módulo. |
| `GEN-08` | `backend/tests/architecture/test_provider_boundary.py` | La suite falla por dos motivos: un cliente HTTP importado fuera de `app/providers/`, o el nombre del proveedor —sin distinguir mayúsculas— fuera de `app/providers/twelvedata.py` y `app/settings.py`. |
| `GEN-09` | `backend/tests/integration/test_user_isolation.py` | La suite falla si un usuario alcanza datos de otro. |
| `PY-08` | `backend/tests/architecture/test_route_authorization.py` (`TestRoutesDeclareAuthorization` + `TestRoutesEnforceAuthorization`) | La suite falla por cada endpoint que responde sin decidir quién lo llama. |
| `TEST-03` | La suite corre en CI con `TWELVEDATA_API_KEY` vacía | Cualquier test que salga a la red falla por credencial ausente. |
| `TEST-05` | `--cov-fail-under=80` en `backend/pyproject.toml` | `pytest` termina en rojo aunque todos los tests pasen. |
| `UI-02` | `frontend/tests/copy.test.ts` | La suite falla y nombra el texto que no coincide con `docs/design/COPY.md`. |
| `UI-03` | `frontend/tests/tokens.test.ts` | La suite falla y lista archivo, línea y el color escrito a mano. |

Cuatro detalles que importan al revisarlas:

- `test_module_boundaries.py` y `test_provider_boundary.py` son chequeos **estáticos** (leen los imports con `ast`), así que detectan violaciones en código que todavía no ejercita ningún test. Además se testean a sí mismos (`test_the_check_catches_a_real_violation`).

- `test_user_isolation.py` **no** es estático y no puede serlo. Crea dos usuarios con favoritas distintas y verifica que ninguno alcance las del otro, por cada endpoint de datos del usuario. Un endpoint nuevo sin su fila acá pasa el pre-commit y es un IDOR.

- `TEST-03` se verifica **por ausencia**: la corrida de CI no tiene API key, así que un test que intente salir a la red falla solo. Es la forma más barata de proteger la cuota del Artículo II.

- `test_route_authorization.py` verifica dos cosas distintas: que el árbol de dependencias de la ruta **declare** autenticación, y que un request anónimo real **reciba 401**. Una ruta pública nueva se agrega a `PUBLIC_ROUTES` con el motivo escrito.

**Todo lo demás depende de que el Developer lo aplique y el Code-Reviewer lo recorra.**

Cuando una convención de esa clase se rompe seguido, la respuesta correcta no es repetirla en otro documento: es escribirle un test o un grep.

## Verificación mecánica (la corrida completa)

```
# Backend
cd backend
uv run ruff format --check app tests && uv run ruff check app tests   # GEN-01, PY-07
uv run mypy app tests                                                 # PY-09
uv run pytest                                                         # GEN-02, PY-06, PY-08, TEST-*

# Frontend
cd frontend
npx tsc --noEmit        # TS-01  (equivale a `npm run type-check`)
npm run lint            # TS-02, TS-04
npm run format:check    # TS-04
npm test                # UI-02, UI-03 (y el resto de la suite de pantalla)

# Todo junto, desde la raíz
make lint && make test
pre-commit run --all-files
```

---

## General (`GEN-*`)

### `GEN-01` - Minor: Se siguen las convenciones del proyecto: nombres, espaciado, imports, formato.


No se discuten a mano: las resuelven el formateador y el linter.

```
cd backend && uv run ruff format --check app tests && uv run ruff check app tests

cd frontend && npm run lint && npm run format:check
```

### `GEN-02` - Blocker: El contrato de un módulo es su paquete: lo que declara `__all__` en su `__init__.py`.


Son **dos cláusulas** y las dos son la regla.

- **Afuera:** a un módulo se entra por su paquete. Cualquier ruta más profunda (`app.modules.stocks.service`, `app.modules.stocks.models`) es interior ajeno y para el resto del sistema no existe. Lo que está en `__all__` es lo único que el módulo promete sostener; todo lo demás (`router.py`, `io.py`, `service.py`, `repository.py`, `models.py`) se cambia sin avisarle a nadie. Un import que entra por el costado convierte un detalle interno en API pública sin que su dueño se entere, y ata los dos módulos para siempre.

- **Adentro:** los archivos del módulo se importan entre sí **por ruta completa**, nunca por `app.modules.<modulo>`: eso reentra al `__init__` a medio inicializar y da un `ImportError` confuso. Es la cláusula que evita el error, así que vale tanto como la primera.

Desde otro módulo:

- ❌ `from app.modules.stocks.repository import StockRepository`
- ❌ `from app.modules.stocks.service import StockService`
- ❌ `from app.modules.stocks.models import Stock`
- ❌ `from app.modules.auth import get_current_user` — no es de `auth` (ver abajo)
- ✅ `from app.modules.stocks import get_stocks, StockInfo`
- ✅ `from app.security import get_current_user, CurrentUser`
- ✅ `from app.db import get_session`

Adentro del propio módulo:

- ❌ `from app.modules.stocks import get_stocks`
- ✅ `from app.modules.stocks.service import get_stocks`

El `__init__.py` de un módulo tiene **sólo** tres cosas: docstring, imports y un `__all__` que es una lista literal de strings. Nada de lógica (ni un `if`, ni una constante calculada, ni un registro de nada).

`main.py` entra por la misma puerta que todos (`from app.modules.stocks import router`), y por eso el `router` está en el `__all__`.

`get_current_user` es primitiva de seguridad que consumen los routers de todos los módulos, así que vive en `app/security.py` junto con Argon2 y JWT (`GEN-03`).

La lectura cruzada real del proyecto es la grilla de *Mis Acciones*: `user_stocks` vive en `favorites/` y necesita símbolo, nombre y moneda, que viven en `stocks/`.
Se resuelve con `get_stocks(symbols: list[str]) -> list[StockInfo]`, que `stocks` declara en su `__all__`, **en batch**: una sola consulta para toda la grilla. Nunca N+1, nunca importando el repository ajeno. Ese es el inventario **completo** de lecturas cruzadas del backend.

Y hay una puerta trasera que el chequeo de imports **no puede ver**: un `relationship()` de SQLAlchemy que cruce módulos.
`favorite.stock.name` no genera ningún import y sin embargo acopla `favorites` al modelo de `stocks`.
Las `ForeignKey` entre tablas de módulos distintos son legítimas (son una garantía del motor, y los módulos separan código, no esquema) los `relationship()` que cruzan, no.

```
cd backend && grep -rn "relationship(" app/modules
```

Cada resultado debe apuntar a un modelo del **propio** módulo.

El chequeo definitivo lo hace `test_module_boundaries.py`, que lee los imports con `ast` y falla nombrando archivo y línea.

Al lado, `no_implicit_reexport = true` hace que `mypy` (`PY-09`, Blocker) marque el nombre que se importa de un paquete que no lo declara en su `__all__`.

El porqué, en `ARCHITECTURE.md`.

### `GEN-03` - Blocker: Nada por debajo de los módulos importa un módulo.

Son dos capas y la regla es la misma para las dos: el **kernel** (`app/*.py`) y la **infraestructura** (`app/providers/`) no importan nada de `app/modules/`.

Los archivos sueltos en `app/` son lo único que cualquier módulo puede importar. `app/providers/` es la salida al mundo, y la consumen dos módulos: no puede conocer a ninguno.

Un import de `modules/` acá ata todos los módulos entre sí por abajo y deja de ser posible extraer uno solo. Y en `providers/` invierte la dependencia: la infraestructura pasaría a depender del dominio, que es exactamente al revés de lo que hace extraíble a `quotes`.

La excepción es `main.py`, que es el composition root: monta los routers, así que importa de todos los módulos por definición. Por eso el chequeo lo excluye por nombre.

`errors.py` además no importa `fastapi`: si lo hiciera, las excepciones de dominio arrastrarían media aplicación y dejarían de poder levantarse desde cualquier módulo.

```
cd backend && grep -nE "^from app\.modules|^import app\.modules" app/*.py | grep -v "^app/main.py:"
cd backend && grep -rnE "^from app\.modules|^import app\.modules" app/providers
cd backend && grep -n "fastapi" app/errors.py
```

### `GEN-04` - Major: El router de un módulo nuevo se monta explícitamente en `app/main.py`.

`main.py` es el *composition root*: es el único lugar que conoce todos los módulos, monta el router de cada uno, configura CORS y traduce las excepciones de dominio a códigos HTTP.
Un módulo que existe y cuyo router no está montado es código muerto que aparenta ser una feature.

### `GEN-05` - Blocker: No hay ciclos entre módulos.

Si `A` entra al paquete de `B`, `B` no entra al de `A`.

Dos módulos que se llaman de ida y de vuelta son uno solo con dos nombres: no se testean por separado, no se despliegan por separado y el día que haya que extraer uno hay que extraer los dos.

Lo que dos módulos comparten y no es de ninguno baja a `app/`, lo que uno necesita del otro va en una sola dirección, declarada en el `__all__` del que provee.

Adentro del módulo vale lo mismo entre services: un service no importa otro service, porque el ciclo aparece en cuanto el segundo necesite algo del primero: lo que comparten baja a un repository y lo que uno necesita del otro lo compone el router.

Si eso resulta incómodo, el corte está mal hecho: escalá al `Backend-Architect`.

### `GEN-06` - Blocker: Se respetan las reglas del dominio (INVIOLABLES) de `AGENTS.md`.

No se reproducen acá para que exista un solo lugar donde cambiarlas.

```
cd frontend && grep -rniE "twelvedata|apikey|api_key" src            # debe no devolver nada
cd backend && grep -rni "twelvedata" app --include=*.py | grep -v "app/providers/"  # idem
cd backend && uv run pytest tests/architecture/
```
Ver también `SEC-02` (la API key) y `ERR-05` (modos de fallo), que son sus manifestaciones en código.

### `GEN-07` - Minor: Idioma, el código va en inglés, la documentación en español.

Nombres, comentarios, docstrings y mensajes de commit en inglés.

Los strings que ve el usuario en la UI, en español (`TS-07`).

Los términos del dominio se traducen (`stock`, `quote`, `favorite`) salvo los que no tienen equivalente limpio, que se dejan como están y se documentan.

**Los archivos de configuración cuentan como código**: YAML, `Makefile`, `Dockerfile`, scripts de shell y `.env.example` llevan sus **comentarios en inglés**.

Van intercalados con palabras clave en inglés (`repos`, `hooks`, `services`, `RUN`, `.PHONY`) y una mezcla se lee peor que cualquiera de las dos opciones puras.

La excepción es la misma que en la UI: **lo que la terminal le muestra al equipo va en español**.

Las descripciones de `make help`, los `name:` de los hooks de pre-commit y los nombres de los pasos de CI son salida para quien corre el comando, no comentarios para quien edita el archivo.

Es el Artículo VIII aplicado igual que siempre: un idioma para cada audiencia.

```
grep -rnE '^\s*#.*\b(que|para|los|las|del|con|una|sin)\b' \
  .pre-commit-config.yaml docker-compose.yml Makefile .github/ scripts/ .env.example
```

### `GEN-08` - Blocker: Todo proveedor externo se consume detrás de su interfaz, y la salida al mundo vive en `app/providers/`.

El protocolo vive en `app/providers/base.py` —hoy `MarketDataProvider`— y la implementación al lado. Lo que el service conoce es el protocolo, y lo recibe inyectado. El protocolo devuelve tipos propios, nunca el JSON del proveedor.

**Ningún archivo fuera de `app/providers/` importa un cliente HTTP.** No es una regla sobre TwelveData: un service que hace `import httpx` y arma una URL ya salió al mundo por la ventana, y ese es el modo de falla real — el nombre del proveedor puede no aparecer nunca.

El nombre `twelvedata`, su URL y su API key aparecen en **un** archivo: `app/providers/twelvedata.py`, que la lee de `app/settings.py`.

```
cd backend && grep -rnE "^\s*(import|from)\s+(httpx|requests|aiohttp|urllib\.request)\b" app | grep -v "^app/providers/"
cd backend && grep -rni "twelvedata" app --include=*.py | grep -vE "^app/(providers/twelvedata\.py|settings\.py)"
```

El segundo va con `-i` a propósito: sin él, `TwelveDataClient` y `TWELVEDATA_API_KEY` pasan limpio.

### `GEN-09` - Blocker: Toda query de datos del usuario filtra por el `sub` del token.

Nunca por un id que venga del path, del query string o del body.

El repositorio recibe el `user_id` del usuario autenticado y no tiene forma de recibir otro: la firma lo exige, y el test de aislamiento lo verifica con dos usuarios (Artículo III).

### `GEN-10` - Major: SOLID, DRY y KISS, con su modo de falla escrito al lado.

Los tres se aplican, y los tres se sobreaplican. Esta convención sirve en el review sólo si se cita junto con **cuál** y **por qué**: "esto viola DRY" sin argumento no es un hallazgo, es una opinión.

**KISS gana por defecto.** Agregar estructura necesita una razón escrita; no agregarla, no. Una interfaz con una sola implementación que nadie va a reemplazar es más difícil de leer que la clase concreta que oculta.

**SOLID.** El que más rinde acá es responsabilidad única, y ya está en la arquitectura: `router` traduce HTTP, `service` decide, `repository` accede a datos (`PY-06`). Inversión de dependencias también: el service conoce el protocolo del proveedor, no su implementación (`GEN-08`). *Modo de falla:* una interfaz por clase y una fábrica por interfaz, en un proyecto de cuatro módulos.

**DRY.** Se aplica a **conocimiento duplicado**, no a texto parecido. Dos funciones con la misma forma y razones distintas para cambiar no son duplicación: unirlas crea un acoplamiento que se paga cuando una evoluciona. *Regla práctica:* a la tercera aparición se extrae, no a la segunda. *Modo de falla:* el helper con cinco parámetros booleanos que nació de unir dos casos que no eran el mismo.

**KISS.** La solución más simple que resuelve el problema **de hoy**. *Modo de falla:* confundir simple con corto — un one-liner denso no es simple.

**Cuando chocan**, el orden es: que funcione y esté testeado, después KISS, después DRY, después SOLID. SOLID es el que más estructura agrega y el más caro si se aplica antes de tiempo.

### `GEN-11` - Major: Un patrón de diseño se nombra sólo cuando se gana el lugar.

Antes de introducir uno, la pregunta es qué problema concreto resuelve **en este proyecto**, no si es conocido. Un patrón bien elegido se justifica en una línea; uno mal elegido necesita un párrafo.

Cuando un `plan.md` introduce uno, lo declara con su alternativa descartada: es una decisión de diseño de la feature, y ahí es donde va (`docs/DECISIONS.md` es para lo transversal).

Los que este proyecto ya usa:

| Patrón | Dónde | Qué resuelve |
|---|---|---|
| **Strategy** (`Protocol`) | `MarketDataProvider` | Habilita el `FakeProvider` que hace correr la suite sin red (`TEST-03`) y deja el proveedor reemplazable (`NFR-07`) |
| **Repository** | `repository.py` de cada módulo | Aísla SQLAlchemy del service, que así se testea sin base |
| **Composition Root** | `app/main.py` | Un solo lugar donde se arma el grafo de dependencias |
| **Test Double** | `FakeProvider` | Determinístico y sin gastar cuota (Artículo II) |

Y los que **no**, porque acá no pagan: Factory (no hay familias de objetos que elegir en runtime), Observer o event bus (`ADR-009` lo descarta: un solo servicio), Unit of Work (la sesión de SQLAlchemy ya lo es), CQRS y Mediator (no hay complejidad de lectura/escritura que separar).

---

## Python (`PY-*`)

### `PY-01` - Blocker: No se importan tipos desde `typing`.

**Prohibidos**: `List`, `Dict`, `Tuple`, `Set`, `Optional`, `Union`.

**Permitidos**, porque no tienen equivalente built-in: `Any`, `Callable`, `TypeVar`, `Generic`, `Annotated` (lo exige `Depends()` de FastAPI) y `TYPE_CHECKING`.

```
cd backend && grep -rnE "from typing import .*\b(List|Dict|Tuple|Set|Optional|Union)\b" app
```

### `PY-02` - Blocker: Se usan genéricos built-in y sintaxis moderna de uniones.

`list[str]`, `dict[str, int]`, `str | None`. `target-version = "py312"`, así que `UP` de Ruff marca buena parte de esto solo.

### `PY-03` - Major: Todos los imports van a nivel de módulo.

Sin imports dentro de funciones o métodos. Lo verifica **`PLC0415` de Ruff**, que está en el `select` de `backend/pyproject.toml` para eso.

```
cd backend && grep -rnE "^\s+(import |from .+ import )" app | grep -v "TYPE_CHECKING"
```

### `PY-04` - Blocker: Toda función y todo método tienen entradas y retorno tipados.

Sin `Any` implícito.

`mypy` corre con `strict = true` (`backend/pyproject.toml`), que activa `disallow_untyped_defs`: una función sin anotar falla con `no-untyped-def`. Lo verifica la herramienta, no el review.

`PY-09` cubre lo demás.

### `PY-05` - Blocker : El acceso a datos es async (SQLAlchemy 2.0 + asyncpg).

Una `Session` sincrónica o un engine sincrónico es Blocker.

```
cd backend && grep -rnE "\bcreate_engine\(|sessionmaker\(|\bSession\(" app
```

### `PY-06` - Blocker : Adentro del módulo el flujo va `router` → `service` → `repository`, en un solo sentido.

Un router no importa SQLAlchemy, un service no importa `fastapi`.

Un `select()` dentro de `router.py` saltea la capa donde viven las decisiones.

Un `HTTPException` dentro de `service.py` amarra la decisión de negocio al transporte (el service comunica fallas con excepciones de dominio y
el router las traduce).

Las capas son reales y están verificadas por un test de arquitectura, no por disciplina (`CONSTITUTION.md`, Artículo IV).

- ❌ `quotes/router.py` → `from app.modules.quotes.repository import QuoteRepository`
- ❌ `quotes/repository.py` → `from app.modules.quotes.service import QuoteService`
- ✅ `quotes/router.py` → `from app.modules.quotes.service import QuoteService`
- ✅ `quotes/service.py` → `from app.modules.quotes.repository import QuoteRepository`

Vale igual cuando la pieza creció de archivo a carpeta del mismo nombre (`router.py` → `routers/`, `service.py` → `services/`, `repository.py` → `repositories/`, `io.py` → `schemas/`, `models.py` → `models/`): cambia la forma, no la dirección.

```
cd backend && uv run pytest tests/architecture/test_module_boundaries.py
```

### `PY-07` - Blocker: Formato y lint con Ruff (`line-length = 100`).

Rompe el pre-commit y el `make lint`, así que no llega al review como opinión.

```
cd backend && uv run ruff format --check app tests && uv run ruff check app tests
```

### `PY-08` - Blocker: Toda ruta declara su autorización.

O el endpoint declara su dependencia de autenticación (`get_current_user`, importada de `app.security`, directa o vía `require_roles(...)`), o está listado en `PUBLIC_ROUTES` de `backend/tests/architecture/test_route_authorization.py` **con el motivo escrito**.

Las rutas de escritura bajo `/users` necesitan además chequeo de rol.

Verificada por test (ver la tabla de arriba).

```
cd backend && uv run pytest tests/architecture/test_route_authorization.py
```

### `PY-09` - Blocker: `mypy` pasa limpio sobre `app/` y sobre `tests/`.

Corre con `no_implicit_reexport = true`, así que además del tipado hace cumplir la frontera: un nombre importado de `app.modules.<modulo>` que ese paquete no declara en su `__all__` es error de `mypy`, no sólo hallazgo de review (`GEN-02`).

Cubre `tests/` además de `app/`. Un test es código que se mantiene, y dejarlo afuera del chequeo permite que llame a una función con el tipo equivocado y siga verde: el test pasa, pero no está ejercitando la firma real.

```
cd backend && uv run mypy app tests
```

### `PY-10` - Major: Nombres, PEP 8, y el guión bajo marca lo privado del archivo.

`snake_case` para funciones, métodos, variables y argumentos.

`PascalCase` para clases.

`UPPER_SNAKE_CASE` para constantes de módulo, **siempre** en mayúsculas.

Guión bajo adelante para lo privado del archivo: funciones, variables, constantes (`_DEFAULT_TTL`), métodos y clases auxiliares que no se usan fuera del archivo donde viven.

Son **dos niveles de privacidad distintos y conviene no confundirlos**:

- El guión bajo marca lo privado del *archivo*.

- El `__all__` del `__init__.py` marca lo público hacia *otros módulos*

Un nombre sin guión bajo que no está en `__all__` es interno del módulo: visible para sus hermanos, invisible para el resto del sistema.

```
cd backend && uv run ruff check --select N app
```

### `PY-11` - Major: Toda función, método y clase lleva docstring, y es breve.

Incluye los tests, los `__init__.py` y los schemas de Pydantic. Una línea alcanza casi siempre: qué hace y, si no es obvio, por qué existe.

**Sin `Args`, sin `Returns`, sin tipos.** Eso ya está en la firma, tipado y verificado por `mypy` (`PY-09`): repetirlo en prosa crea una segunda fuente que se desincroniza en el primer refactor. El docstring dice lo que la firma **no** puede decir.

En un test, el docstring dice **qué comportamiento fija**, no qué hace el código. `"""Answers 200 while the process can serve."""` sirve; `"""Tests the health endpoint."""` es el nombre del test escrito de nuevo.

En inglés, como todo el código (`GEN-07`).

```
cd backend && uv run ruff check --select D app tests
```

---

## TypeScript y frontend (`TS-*`)

### `TS-01` - Blocker: Modo estricto de TypeScript activado, y el proyecto compila.

```
cd frontend && npx tsc --noEmit
```

### `TS-02` - Blocker: Sin tipos `any`; se usa `unknown` cuando hace falta.

```
cd frontend && grep -rnE ":\s*any\b|<any>|as any" src
```

### `TS-03` - Major: Los tipos de la API se generan desde el schema de OpenAPI.

No se escriben a mano ni se duplican los schemas del backend.

```
make types      # genera frontend/src/api/ desde el OpenAPI de FastAPI
```

### `TS-04` - Blocker: Formato con Prettier y lint con ESLint.**

```
cd frontend && npm run lint && npm run format:check
```

### `TS-05` - Minor: Cada cosa en su lugar.

- Una página por wireframe en `frontend/src/pages/`.

- Los componentes que comparten en `frontend/src/components/`.

- El cliente HTTP y los tipos generados del OpenAPI en `frontend/src/api/`.

- El contexto de sesión y el interceptor de 401 en `frontend/src/auth/`.

- La paleta en `frontend/src/styles/tokens.css` (`ARCHITECTURE.md` → Anatomía del frontend).

### `TS-06` - Major: Los estados de carga, error y vacío están manejados.

### `TS-07` - Minor: Los textos visibles por el usuario están en español.


---

## Interfaz (`UI-*`)

### `UI-01` - Blocker: Cada pantalla reproduce la estructura de su wireframe.

Mismo orden de elementos, mismas etiquetas, mismas columnas, mismos controles.

Los wireframes están en `docs/design/wireframes/` y cada spec referencia el suyo.

No esta permitido agregar una columna a la grilla, reordenar los controles del detalle o reemplazar un `select` por otra cosa, a menos que el humano lo pida explicitamente.

### `UI-02` - Blocker: Los textos visibles son los literales del copy.

Están fijados en `docs/design/COPY.md`.

Un texto que el wireframe no define lo define `COPY.md`, y ahí queda.

```
cd frontend && grep -rn "usuario o clave" src   # debe existir, exactamente así
```

### `UI-03` - Major: Paleta neutra, del wireframe.

Grises para superficie, borde y cabecera de tabla; azul de enlace sólo en lo que es enlace (el símbolo y `Eliminar`); una sola serie azul en el gráfico.

Ningún color literal en los componentes: salen de `src/styles/tokens.css`.

```
cd frontend && grep -rnE "#[0-9a-fA-F]{3,8}\b|rgb\(|hsl\(" src/components src/pages
```

### `UI-04` - Major: Cotizaciones, fechas y símbolos en mono tabular.

Una columna de números que no alinea se lee mal, y la grilla y el tooltip del gráfico son las dos pantallas donde el dato es el producto.

### `UI-05` - Major: Los avisos van arriba del dato que califican.

Los estados `stale`, `market_closed` y `no_data` (`ERR-05`) se muestran **sobre** el gráfico, nunca al pie ni en un toast que se va solo: califican lo que el usuario está mirando, y tienen que seguir ahí mientras lo mire.

El gráfico se dibuja igual con lo que haya: una pantalla en blanco sin explicación es el modo de falla que `ADR-005` existe para evitar.

### `UI-06` - Minor: Un solo tema, y es el claro.

Los wireframes son claros. No se lee la preferencia del sistema operativo ni se mantiene una segunda paleta.

---

## Manejo de errores (`ERR-*`)

### `ERR-01` - Blocker: Ninguna excepción se traga en silencio.

Un `except` que no loguea, no re-lanza y no decide nada es un hallazgo.

Lo verifica **`BLE001` de Ruff**, que marca todo `except Exception` (y `except BaseException`) capturado a ciegas. Deja de depender de que alguien lea el diff, y por eso sube a Blocker: una regla que una herramienta puede sostener no tiene por qué sostenerla una persona.

Se puede silenciar con `# noqa: BLE001`, y **el `noqa` obliga a escribir el porqué en la misma línea o en el docstring**. Hoy el repositorio tiene exactamente uno: la sonda `database_is_up` de `app/db.py`, que se traga la excepción porque quien pregunta quiere un sí o un no, y porque el texto de esa excepción lleva el DSN con la password (Artículo I). Un `noqa` sin justificación escrita es un hallazgo, igual que el `except` que evita.

```
cd backend && uv run ruff check --select BLE app tests
cd backend && grep -rn "noqa: BLE001" app tests   # cada uno tiene que tener su razón al lado
```

### `ERR-02` - Minor: Los mensajes de error tienen sentido para quien los lee.

### `ERR-03` - Blocker: Logging estructurado, nunca `print`.

La excepción son los **entry points de línea de comandos** (`if __name__ == "__main__"`): lo que un comando le contesta a quien lo corrió va a su terminal, no al log, donde esa persona no lo está mirando.

Acotada a la función `main()` del comando: todo lo que ese comando llama sigue logueando.

```
cd backend && grep -rnE "^\s*print\(" app | grep -v "bootstrap.py"
```

### `ERR-04` - Blocker: Los services no lanzan `HTTPException`.

Lanzan excepciones de dominio: las comunes en `app/errors.py` (`DomainError` y su familia : `NotFoundError`, `ConflictError`, `ValidationError`, `AuthenticationError`, `PermissionDeniedError`), y las propias de cada módulo en su propio código, heredando de `DomainError`.

`main.py` las traduce a códigos HTTP.

Una excepción de dominio se levanta desde cualquier módulo y no arrastra `fastapi` con ella.

```
cd backend && grep -rn "HTTPException" app/modules | grep -v "/router"
```

### `ERR-05` - Blocker: Una falla del proveedor externo no llega cruda al cliente.

Cuota agotada, timeout, mercado cerrado y símbolo sin serie se traducen a un `status` tipado (`ok` / `stale` / `market_closed` / `no_data`) y el endpoint responde 200 con lo último conocido más el aviso.

Un 429 de TwelveData reenviado tal cual al navegador es Blocker: el usuario no tiene cuenta en TwelveData.

Es `ADR-005` escrito como convención de código.

### `ERR-06` - Major: Hay manejo de errores en todas las capas, rutas, servicios, componentes.

### `ERR-07` - Major: Toda llamada al proveedor externo queda registrada y es auditable.

Símbolo, intervalo, rango, resultado y si fue cache hit.

---

## Configuración y secretos (`SEC-*`)

### `SEC-01` - Blocker: No se commitean secretos.

El hook `detect-private-key` de pre-commit cubre las claves privadas, el resto lo mira el review.

```
pre-commit run detect-private-key --all-files
```

### `SEC-02` - Blocker: La API key de los servicios externos viven sólo en el entorno del backend.

Nunca en la base, nunca en el repositorio, nunca en un log, y **nunca en una variable `VITE_*`**: todo lo que empieza con `VITE_` termina en el bundle que se descarga el navegador.

Es una regla del dominio (`GEN-06`).

### `SEC-03` - Major: La configuración es tipada (`Settings`) y está documentada en `.env.example`.

Una variable nueva que no está en `.env.example` rompe el deploy de otro.

### `SEC-04` - Major: Sin valores hardcodeados.

Van a `Settings` (si son de entorno) o a constantes con nombre del módulo dueño (si son de negocio): el TTL por intervalo es de `quotes`, no de una carpeta de configuración global.

### `SEC-05` - Minor: Los valores por defecto son seguros y explícitos.

### `SEC-06` - Blocker: Toda password persistida se guarda hasheada con Argon2id.

Nunca en texto plano, y nunca con un hash de propósito general (`md5`, `sha1`, `sha256`, `hashlib`): esas funciones están diseñadas para ser **rápidas**, que es exactamente lo que no se quiere cuando alguien se lleva la tabla `users`. Argon2id es la primera recomendación de OWASP para almacenamiento de contraseñas y es el único algoritmo aprobado acá.

Aplica también al **seed** (`REQ-19`), que es el primer código del proyecto y corre en la fase 0, antes de que exista cualquier feature con spec firmada: un seed que escribe la clave en texto plano deja la base sembrada mal desde el minuto uno, y es lo primero que abre quien evalúe seguridad.

La verificación es de dos puntas: que el hash entre bien, y que la password cruda nunca salga.

```
cd backend && grep -rnE "\b(md5|sha1|sha256|hashlib)\b" app --include=*.py
cd backend && uv run pytest tests/integration/test_password_hashing.py
```

Lo respalda `NFR-01` y lo detalla `ADR-004`.

### `SEC-07` - Blocker: Toda ruta se piensa contra la OWASP API Security Top 10 (2023).

No es una checklist de cierre: es la lista que se recorre **al diseñar el endpoint**, en el `plan.md`, cuando todavía es barato cambiarlo. La mitad de las diez no aplican a este proyecto, y decir cuáles y por qué es parte de la convención — una lista contestada con "no aplica" en silencio se lee igual que una no leída.

Las que **sí** aplican acá, cada una con la regla que ya la cubre:

| | Riesgo | Acá | Regla |
|---|---|---|---|
| **API1** | **BOLA** — autorización a nivel objeto rota | El riesgo principal del proyecto: favoritas de otro usuario | Artículo III, `GEN-09` |
| **API2** | Autenticación rota | Login, JWT, expiración, Argon2id | `ADR-004`, `SEC-06` |
| **API3** | BOPLA — exponer o aceptar campos de más | Los schemas de `io.py` son explícitos en las dos direcciones, nunca `model_config = {"extra": "allow"}` | `PY-01` |
| **API4** | Consumo de recursos sin límite | La cuota de 800/día **es** este riesgo | Artículo II, `ADR-003` |
| **API5** | Autorización a nivel función | Toda ruta declara su autenticación o está en `PUBLIC_ROUTES` con motivo | `PY-08` |
| **API8** | Mala configuración | CORS acotado al origen del frontend, nunca `*`; Sentry sin PII ni variables locales | `SEC-02`, `ADR-009` |

Las que **no** aplican, dicho de frente: **API6** (flujos de negocio sensibles: no hay pagos ni transferencias), **API7** (SSRF: la única URL saliente es la del proveedor, fija en `app/providers/`), **API9** (gestión de inventario: hay una sola versión y un solo ambiente público), **API10** (consumo inseguro de APIs de terceros — aplica parcialmente, y lo cubre `ERR-05`: la respuesta del proveedor se valida y se tipa, nunca se reenvía cruda).

**API1 y API5 son distintos y se confunden.** API1 pregunta *"¿este usuario puede tocar **este objeto**?"*; API5, *"¿este usuario puede llamar a **este endpoint**?"*. La primera la sostiene el filtro por `sub` del token, la segunda la declaración de autorización de la ruta. Un endpoint puede pasar API5 y fallar API1.

---

## Base de datos (`DB-*`)

### `DB-01` - Blocker: Los modelos están sincronizados con las tablas vía migraciones de Alembic.

Modificar un modelo de SQLAlchemy sin su migración es Blocker.

Flujo: modificar el modelo → crear la migración → aplicarla → verificar.

```
cd backend && uv run alembic revision --autogenerate -m "descripcion"
cd backend && uv run alembic upgrade head
```

### `DB-02` - Blocker: No hay cambios manuales en la base de datos sin migración.

### `DB-03` - Major: Los modelos usan `Mapped[...]` + `mapped_column(...)`.

Un solo esquema (el de por defecto) y tablas: `ARCHITECTURE.md` → *Modelo dendatos*.

Las claves compuestas se declaran en el modelo, no se emulan con un `UniqueConstraint` más un `id` autoincremental que nadie usa.

### `DB-04` - Major: Las migraciones se revisan antes de aplicarse.

`--autogenerate` propone, no decide.

Una migración autogenerada que se commitea sin leer es un hallazgo.

---

## Tests (`TEST-*`)

### `TEST-01` - Major: Hay tests unitarios de la lógica de negocio.

Servicios, parsers, normalización. Los escribe el `Developer` para su propia lógica, la suite como sistema es del `Tester`.

### `TEST-02` - Major: Hay tests de integración de endpoints y repositorios.

### `TEST-03` - Blocker: El proveedor se testea contra JSON fijado, nunca contra TwelveData en vivo.

Los fixtures van en `backend/tests/fixtures/twelvedata/`.

**La suite completa corre sin red y sin backend key**.

```
cd backend && SOME_API_KEY= uv run pytest
```

### `TEST-04` - Major: Toda alta de favorita tiene su test de idempotencia, agregar dos veces el mismo símbolo no duplica ni falla.

### `TEST-05` - Blocker: La cobertura no baja del 80%.

El umbral es `--cov-fail-under=80` en `backend/pyproject.toml`: es una condición de la corrida.

```
cd backend && uv run pytest --cov=app --cov-report=term-missing
```

### `TEST-06` - Blocker: No se debilitan los tests para pasar el gate.

Ni `skip`, ni asserts vaciados, ni umbral de cobertura bajado, ni un `xfail` del `Tester` tapado en vez de arreglado.

Un bug reportado con `xfail(strict=True)` se arregla y se saca el marcador.

```
cd backend && git diff --stat -- tests/ && grep -rn "skip\|xfail" tests | head -20
```

### `TEST-07` - Minor: Convenciones de la suite.

Patrón AAA (Arrange / Act / Assert) explícito, marcadores declarados en `pyproject.toml` (`--strict-markers`), tests async sin decorador (`asyncio_mode = "auto"`) y cobertura de los casos de error, no sólo del camino feliz.

Detalle en `backend/tests/README.md`.

---

## Dependencias (`DEP-*`)

### `DEP-01` - Blocker: Backend: las dependencias se gestionan sólo con `uv`.

Prohibidos `pip install`, `requirements.txt` y `poetry add`.

No se editan a mano las dependencias de `pyproject.toml`.

```
cd backend && uv add <package>        # o `uv add --dev <package>`
cd backend && uv lock
cd backend && uv sync
```

### `DEP-02` - Blocker: `pyproject.toml` y `uv.lock` se commitean juntos.

Evitando un lockfile desactualizado.

### `DEP-03` - Blocker: Frontend, las dependencias se gestionan con `npm`.

No se editan a mano los números de versión de `package.json`, `package-lock.json` se actualiza solo y se commitea.

```
cd frontend && npm install <package>
```

### `DEP-04` - Major: Una dependencia nueva del frontend pasa la auditoría.

```
scripts/npm-audit-gate.sh
```

---

## Git y commits (`GIT-*`)

### `GIT-01` - Blocker: Nunca se commitea directo a `main`.

Se trabaja en una rama de feature creada desde `main`, y el merge entra por PR después del gate de `/review-feature`.

```
git checkout -b feat/<NNN-feature>
```

### `GIT-02` - Minor: Convención de ramas.

**Los nombres de rama van en inglés**, como los mensajes de commit. `feat/<NNN-feature>` para features, donde `<NNN-feature>` es exactamente el nombre de la carpeta de la spec (`feat/001-authentication`): un solo slug para la feature, no uno por herramienta.

`fix/<description>` para correcciones, `test/<description>` para cambios o agregados relacionados sólo a tests, y `chore/<description>` para mantenimiento, dependencias y tooling.

### `GIT-03` - Blocker: Los mensajes de commit son Conventional Commits, en inglés.

Tipos permitidos: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.

Lo verifica el hook `conventional-pre-commit` en `commit-msg`: un mensaje fuera de convención no llega a commitearse.

### `GIT-04` - Minor: Higiene de archivos.

Sin whitespace al final, con newline al final del archivo, sin conflictos de merge sin resolver y sin archivos de más de 1 MB. Todo lo verifica pre-commit.

```
pre-commit run --all-files
```

---

## Índice de Blockers

El `Code-Reviewer` marca estos hallazgos como **Blocker**, sin excepción.

Es la **lista completa**: las convenciones marcadas `Blocker` en este documento entran acá, sin un segundo grupo aparte.

Si una convención está marcada Blocker y no aparece en esta tabla, la tabla está incompleta.

| # | Hallazgo | Convención |
|---|---|---|
| 1 | Violación de frontera entre módulos (import que entra a otro módulo por debajo de su paquete, import que reentra al propio paquete en vez de usar la ruta completa, `__init__.py` con algo más que docstring + imports + `__all__` literal, ciclo entre módulos, `app/` importando de `app/modules/`) | `GEN-02`, `GEN-03`, `GEN-05` |
| 2 | `HTTPException` dentro de un service | `ERR-04` |
| 3 | Sesiones sincrónicas de base de datos | `PY-05` |
| 4 | Capas cruzadas adentro del módulo: `select()` en un router, `HTTPException` en un service, repository que importa un service | `PY-06` |
| 5 | Modelos desincronizados de las tablas | `DB-01`, `DB-02` |
| 6 | Violación de una regla del dominio (API key, cuota, aislamiento) | `GEN-06`, `ERR-05`, `SEC-02` |
| 7 | Type safety roto (tipos de `typing`, funciones sin tipar, `any`) | `PY-01`, `PY-02`, `PY-04`, `PY-09`, `TS-01`, `TS-02` |
| 8 | Gestión de dependencias fuera de `uv` / `npm` | `DEP-01`, `DEP-02`, `DEP-03` |
| 9 | Ruta sin autorización declarada | `PY-08` |
| 10 | Tests debilitados para pasar el gate | `TEST-06`, `TEST-05` |
| 11 | Cliente HTTP importado fuera de `app/providers/`, o el nombre del proveedor fuera de su archivo | `GEN-08` |
| 12 | Query de datos de usuario que no filtra por el `sub` del token | `GEN-09` |
| 13 | `print` en lugar de logging estructurado | `ERR-03` |
| 14 | Formato o lint rotos : rompen el pre-commit | `PY-07`, `TS-04` |
| 15 | Secretos commiteados | `SEC-01` |
| 16 | Password guardada en texto plano, o hasheada con `md5`/`sha*` en vez de Argon2id | `SEC-06` |
| 17 | Endpoint nuevo cuyo `plan.md` no recorrió la OWASP API Top 10 | `SEC-07` |
| 18 | `except` a ciegas que no loguea, no re-lanza y no decide, o un `noqa: BLE001` sin razón escrita | `ERR-01` |
| 19 | Tests que salen a la red en vez de usar JSON fijado | `TEST-03` |
| 20 | Commit directo a `main`, o mensaje fuera de Conventional Commits | `GIT-01`, `GIT-03` |
| 21 | Pantalla que se aparta del wireframe, o texto cambiado respecto del enunciado | `UI-01`, `UI-02` |

## Identificadores retirados

Está vacía a propósito, y a partir de acá deja de estarlo.

Esta es la primera versión del documento: los identificadores nacen correlativos, sin huecos. Las convenciones que se descartaron al armarlo venían de otro proyecto y nunca rigieron acá, así que su numeración no dejó rastro en ningún review ni en ningún commit y se compactó sin costo.

De ahora en adelante **un identificador retirado no se reutiliza**: se lista acá con su fecha y su motivo, y su número queda como hueco. La razón es que desde el primer review un ID empieza a aparecer en hallazgos, mensajes de commit y PRs; reasignarlo después haría que el historial diga una cosa y el documento otra.

| ID | Retirado | Motivo |
|---|---|---|
