# Skill — Agregar tests

Tags: [backend] [frontend] [testing] [calidad]

## Objetivo
Escribir los tests de una feature siguiendo las convenciones del proyecto:
- unitarios para services y lógica pura
- de integración para endpoints, repositorios y migraciones
- del proveedor de datos, contra **JSON fijado**
- cobertura que valide los criterios de aceptación de la spec (> 80%)

## Cuándo usarla
- **Antes de implementar una feature** (backend o frontend). Es el paso previo al gate del
  Artículo VI: se escriben, el humano los aprueba (`/approve-tests`) y recién ahí corre
  `implement`.
- Al agregar funcionalidad a un módulo existente (`auth`, `stocks`, `favorites`, `quotes`), con el
  mismo orden.
- Al corregir un bug: el test de regresión primero, reproduciendo la falla.
- Al refactorizar: acá sí el código ya existe, y los tests son la red que asegura que el
  comportamiento se preserva.

## Precondiciones
- **El `plan.md` fija la interfaz que los tests van a ejercitar**: módulos, services, firmas y
  endpoints. Los tests se escriben contra código que todavía no existe, así que si el plan no
  alcanza para nombrar lo que se va a llamar, se vuelve a `plan` — no se inventa la firma.
- Las migraciones están aplicadas (`uv run alembic upgrade head`): el esquema va primero, y por eso
  en `tasks.md` la migración precede a los tests.
- Las dependencias están instaladas (`uv sync`).

## Reglas (ESTRICTO)
- El acceso a datos es async: los tests que tocan la base usan `pytest-asyncio` y `AsyncSession`.
- El proveedor se testea **siempre** contra JSON fijado en `tests/fixtures/twelvedata/`, **nunca**
  contra TwelveData en vivo: además de higiene, la cuota es de 800 requests por día (Artículo II).
- El alta de favoritas lleva su test de **idempotencia**.
- Cada test es independiente y se puede correr aislado.

## Pasos (ORDEN OBLIGATORIO)

### 1) Identificar el alcance
Determinar qué hay que testear:

| Componente | Tipo de test | Ubicación |
|-----------|--------------|-----------|
| Lógica de servicio | Unitario | `tests/unit/services/` |
| Provider de TwelveData | Unitario (con fixtures JSON) | `tests/unit/providers/` |
| Caché y detección de huecos | Unitario | `tests/unit/services/` |
| Repositorio | Integración | `tests/integration/repositories/` |
| Endpoints de la API | Integración | `tests/integration/api/` |
| Feature completa | Integración | `tests/integration/features/` |
| Fronteras entre módulos | Arquitectura | `tests/architecture/test_module_boundaries.py` |
| Fronteras entre capas del módulo | Arquitectura | `tests/architecture/` |
| Flujos de usuario | E2E | `tests/e2e/` |

El backend es un monolito modular por dominios: cada módulo —`auth`, `stocks`, `favorites`,
`quotes`— tiene adentro `router.py` → `service.py` → `repository.py`, más `io.py` y `models.py`, y
su contrato es lo que declara el `__all__` de su `__init__.py` (Artículo IV). Cada pieza tiene su
tipo de test: un service se prueba con su repositorio mockeado, un router se prueba por HTTP, y las
fronteras —las de adentro del módulo y las que separan un módulo de otro— ya las verifica
`tests/architecture/`; no hace falta reescribir eso a mano en cada feature.

La frontera entre módulos son dos cláusulas y las dos importan. **Afuera:** a un módulo se entra
por su paquete —`from app.modules.stocks import get_stocks, StockInfo`—; cualquier ruta más profunda
(`app.modules.stocks.service`, `app.modules.stocks.models`) es interior ajeno y para el resto del
sistema no existe. **Adentro:** los archivos del módulo se importan entre sí por ruta completa
(`from app.modules.stocks.service import get_stocks`), nunca por `app.modules.stocks`, porque eso
reentra al `__init__` a medio inicializar y da un ImportError confuso.

`backend/tests/architecture/test_module_boundaries.py` lee los imports con `ast` y falla nombrando
archivo y línea, así que no se testea a mano; y hay otro test que verifica que cada `__init__.py`
tenga sólo docstring, imports y un `__all__` que sea lista literal de strings —nada de lógica—.

Los tests sí importan el interior del módulo que están probando —un test de `favorites` es parte de
`favorites`, y la regla corre entre módulos de `app/`— pero cuando necesitan algo de otro módulo
entran por el paquete, igual que el código.

Si una pieza creció de archivo a carpeta (`service.py` → `services/`), el test no cambia de lugar ni
de nombre: cambia el import.

### 2) Crear el archivo de test
Convención de nombres: `test_<módulo>_<pieza>.py`

```bash
# Ejemplo para el módulo de favoritas
touch backend/tests/unit/services/test_favorites_service.py
touch backend/tests/integration/api/test_favorites_routes.py
```

Los nombres de adentro del archivo siguen la misma convención que el código (`PY-10`): `snake_case`
para tests, fixtures, helpers y argumentos; `PascalCase` para la clase que los agrupa
(`TestFavoritesService`) y para los factories; `UPPER_SNAKE_CASE`, siempre en mayúsculas, para las
constantes del módulo. El guión bajo adelante marca lo **privado del archivo**: un helper que arma
un payload y no sale de ese test es `_build_payload`, una constante que sólo usa ese test es
`_FIXTURES_DIR`. Nada de `__doble_guion_bajo`.

Son dos niveles de privacidad distintos: el guión bajo esconde del **archivo**, el `__all__` esconde
de **otros módulos**. En un test sólo juega el primero.

### 3) Escribir la estructura del test
Organización por clase, con marcadores de pytest:

```python
"""Tests del servicio de <modulo>."""

import pytest

from app.modules.<modulo>.service import <Modulo>Service


@pytest.mark.unit
class Test<Modulo>Service:
    """<Descripción>."""

    @pytest.fixture
    def service(self, <dependencias>) -> <Modulo>Service:
        """Instancia del servicio con sus dependencias."""
        return <Modulo>Service(<dependencias>)

    async def test_<accion>_<resultado_esperado>(self, service) -> None:
        """<Qué verifica>."""
        # Arrange
        # Act
        # Assert
```

Los tests que tocan código async van marcados con `@pytest.mark.asyncio` (o con el modo
automático de `pytest-asyncio` configurado en el proyecto).

### 4) Seguir el patrón AAA
Todo test tiene sus tres secciones explícitas:

```python
async def test_add_favorite_success(self, client) -> None:
    """Alta de favorita exitosa."""
    # Arrange
    payload = {"symbol": "TSLA"}

    # Act
    response = await client.post("/api/stocks/favorites", json=payload)

    # Assert
    assert response.status_code == 201
    data = response.json()
    assert data["symbol"] == payload["symbol"]
```

### 5) Usar los fixtures apropiados

**Tests unitarios** — dependencias mockeadas, sin base de datos:
```python
@pytest.fixture
def repository(self) -> AsyncMock:
    """Repositorio mockeado."""
    return AsyncMock(spec=FavoriteRepository)
```
Un test unitario de servicio mockea **las dependencias que recibe inyectadas**: su repositorio y,
en `quotes`, el `MarketDataProvider`. Nada más. No hay services ajenos que mockear: un service nunca
importa otro service (`GEN-05`). Lo que necesita de otro módulo lo pide por el paquete de ese
módulo —lo que su `__all__` declara—, y en el test se parchea ahí donde se usa:

```python
# favorites/service.py hace: from app.modules.stocks import get_stocks
mocker.patch(
    "app.modules.favorites.service.get_stocks",
    return_value=[StockInfo(symbol="TSLA", name="Tesla Inc", currency="USD")],
)
```

Se parchea el nombre en el módulo que lo consume, no donde está definido: así el test queda atado al
contrato y no al interior ajeno. Este parche es además el único de su clase en toda la suite: el
inventario completo de lecturas cruzadas del backend es `get_stocks` y `StockInfo`, de `stocks`, que
consume `favorites` para la grilla. Los paquetes de `auth`, `favorites` y `quotes` exportan sólo su
`router`, así que no hay nada más de otro módulo que mockear.

Y el mock devuelve **la grilla entera de una vez**: si para que el test pase hubo que devolver un
símbolo por llamada, el código tiene un N+1 y este es el lugar donde se ve. El assert que lo fija
es uno solo —`get_stocks` llamado una vez con todos los símbolos—.

El provider se mockea por el **protocolo** (`AsyncMock(spec=MarketDataProvider)`), no por el cliente
HTTP: el service no sabe que TwelveData existe, y su test tampoco tiene por qué saberlo (`GEN-08`).
El único archivo que nombra TwelveData es `app/providers/twelvedata.py`.

**Tests de integración** — sesión async real de `conftest.py`:
```python
async def test_list_favorites(self, client, session) -> None:
    # `client` y `session` vienen de conftest.py; la transacción se revierte al final
    ...
```

### 6) Crear factories para los datos de prueba
Ubicación: `tests/factories/<entidad>_factory.py`

```python
"""Factory de <Entidad> para tests."""

from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.<modulo>.models import <Entidad>


class <Entidad>Factory:
    """Factory de <Entidad>."""

    @staticmethod
    async def create(session: AsyncSession, **kwargs: object) -> <Entidad>:
        """Crear una instancia."""
        defaults: dict[str, object] = {"field1": "valor_por_defecto", "field2": 123}
        defaults.update(kwargs)

        instance = <Entidad>(**defaults)
        session.add(instance)
        await session.flush()
        return instance

    @staticmethod
    async def create_batch(session: AsyncSession, count: int, **kwargs: object) -> list[<Entidad>]:
        """Crear varias instancias."""
        return [await <Entidad>Factory.create(session, **kwargs) for _ in range(count)]
```

Las dos tablas de clave compuesta —`user_stocks` (`user_id`, `symbol`) y `quotes` (`symbol`,
`interval`, `ts`)— no tienen `id` autoincremental: el factory recibe los valores de la clave. Un
`create_batch` que no los varía inserta la misma fila dos veces y rompe con un conflicto, que es
exactamente lo que la clave compuesta existe para provocar.

Cada factory vive del lado de su módulo y sólo arma filas de las tablas de ese módulo: el factory de
`favorites` no inserta `stocks` a mano, usa el de `stocks`. Un factory que escribe la tabla de otro
módulo es la misma violación de frontera que un import, con la diferencia de que el test de
arquitectura no la ve.

### 7) Fijar el JSON del proveedor (tests de cotizaciones)
- Guardar la respuesta capturada en `tests/fixtures/twelvedata/<endpoint>_<fecha>.json`.
- El mapeo se testea como función pura: JSON → tipos del dominio.
- Casos obligatorios:
  - serie con varias velas
  - serie vacía
  - rango con un hueco parcial → se pide al proveedor sólo el hueco, no el rango entero
  - el proveedor devuelve 429 → `status: stale` con lo último conocido, nunca un 429 al cliente
  - el día no tiene rueda → `status: market_closed` con la última disponible
  - el símbolo no tiene serie → `status: no_data`
- **Nunca** salir a la red dentro de la suite.

### 8) Testear los casos de error
Siempre incluir los casos negativos:

```python
async def test_get_quote_unknown_symbol(self, client) -> None:
    """Símbolo que no está en el catálogo."""
    response = await client.get("/api/quotes/ZZZZ?interval=1min")

    assert response.status_code == 404


async def test_add_favorite_invalid_symbol(self, client) -> None:
    """Símbolo vacío."""
    response = await client.post("/api/stocks/favorites", json={"symbol": ""})

    assert response.status_code == 422
```
Los servicios lanzan errores de dominio de su propio módulo (`NotFoundError`, `ConflictError`, …),
todos derivados de `DomainError` (`app/errors.py`): en los tests unitarios se verifica el
error de dominio; en los de integración, el código HTTP al que `main.py` lo mapea. Un service que
levanta `HTTPException` es Blocker, y el test unitario es donde eso se nota primero.

Ojo con el caso del proveedor: una falla suya **no** es un error HTTP. Cuota agotada, mercado
cerrado y símbolo sin serie responden 200 con su `status` (`ADR-005`), y el test afirma sobre el
`status`, no sobre un 4xx que no existe.

### 9) Testear la autorización y el aislamiento
Toda ruta declara su autorización (`PY-08`) y toda lectura de datos del usuario filtra por el `sub`
del token, nunca por un id que venga del request (Artículo III). Los dos tests van de a par:

```python
async def test_favorites_require_auth(self, client) -> None:
    """Sin token no se listan favoritas."""
    response = await client.get("/api/stocks/favorites")

    assert response.status_code == 401


async def test_user_cannot_see_other_users_favorites(self, client, session, other_user) -> None:
    """Las favoritas de otro usuario no existen para este."""
    # Arrange
    await UserStockFactory.create(session, user_id=other_user.id, symbol="TSLA")

    # Act — autenticado como el primer usuario
    response = await client.get("/api/stocks/favorites")

    # Assert
    assert "TSLA" not in [item["symbol"] for item in response.json()]
```

El `get_current_user` que declaran los routers no es dominio de `auth`: es una primitiva de
seguridad que consumen los routers de todos los módulos y vive en `app/security.py`, junto
con Argon2 y JWT. El fixture que autentica al cliente lo overridea desde ahí:

```python
from app.security import CurrentUser, get_current_user

app.dependency_overrides[get_current_user] = lambda: CurrentUser(id=user.id)
```

Pedirlo por el paquete de `auth` es buscarlo donde no está: `auth` no lo exporta.

### 10) Testear la idempotencia del alta de favoritas
Toda alta de favorita lleva este test (`TEST-04`):

```python
async def test_add_favorite_is_idempotent(self, service, session, user) -> None:
    """Agregar TSLA dos veces deja una sola fila y no falla."""
    await service.add_favorite(user_id=user.id, symbol="TSLA")
    await service.add_favorite(user_id=user.id, symbol="TSLA")

    assert await count_favorites(session, user_id=user.id) == 1
```
La PK compuesta `(user_id, symbol)` ya hace imposible el duplicado: lo que el test fija es que el
segundo llamado **no explota**, sino que responde como si ya estuviera — que es lo que el usuario
que hace doble clic espera.

### 11) Correr los tests
```bash
# Todos
cd backend && uv run pytest

# Un archivo
uv run pytest tests/unit/services/test_favorites_service.py

# Con coverage
uv run pytest --cov=app --cov-report=html

# Por marcador
uv run pytest -m unit
uv run pytest -m integration
```

### 12) Verificar la cobertura
Objetivo: > 80% sobre el código nuevo. El umbral vive en `backend/pyproject.toml`
(`--cov-fail-under=80`): no es una meta, es condición de la corrida.

```bash
# La corrida completa, que es la que decide
uv run pytest --cov=app --cov-report=term-missing

# Sólo el módulo que tocaste, que es la unidad que importa
uv run pytest --cov=app/modules/<modulo> --cov-report=term-missing

# O pieza por pieza
uv run pytest --cov=app/modules/<modulo>/service.py \
              --cov=app/modules/<modulo>/repository.py --cov-report=term-missing
```

Cuando una pieza creció a carpeta, la ruta es la carpeta: `--cov=app/modules/quotes/services/`.

## Validación
- [ ] Los tests nuevos **fallan, y fallan por ausencia de implementación** — no por un import roto
      ni un fixture mal armado. Un test en verde antes de que exista el código no prueba nada.
- [ ] Los tests de arquitectura siguen en verde: `uv run pytest tests/architecture/`
- [ ] Los tests siguen el patrón AAA (Arrange/Act/Assert)
- [ ] Están cubiertos los casos de éxito **y** los de error
- [ ] El proveedor se testea contra JSON fijado, con los cuatro `status` cubiertos
- [ ] El alta de favoritas tiene test de idempotencia
- [ ] Se usan fixtures y factories en lugar de datos hardcodeados
- [ ] Los tests son independientes y no comparten estado
- [ ] Cobertura > 80% sobre el código nuevo
- [ ] La suite corre sin red y sin API key (`TWELVEDATA_API_KEY=` vacía)
- [ ] **Se entregaron a aprobación humana (`/approve-tests`).** La skill no se declara completa
      sola: termina presentando los tests y esperando la firma (Artículo VI).

## Errores comunes (evitar)

### 1) Testear la implementación en lugar del comportamiento
```python
# Mal — testea el detalle interno
def test_uses_correct_query(self) -> None:
    assert "SELECT" in service.query

# Bien — testea el comportamiento
async def test_returns_only_favorites_of_the_user(self, service, user) -> None:
    result = await service.list_favorites(user_id=user.id)
    assert all(favorite.user_id == user.id for favorite in result)
```

### 2) Dejar datos en la base
```python
# Mal — inserta y no limpia
async def test_add(self, session, user) -> None:
    session.add(UserStock(user_id=user.id, symbol="TSLA"))
    await session.commit()

# Bien — el fixture de sesión revierte la transacción al terminar
@pytest.fixture
async def favorite(self, session, user):
    return await UserStockFactory.create(session, user_id=user.id, symbol="TSLA")
```

### 3) Testear el provider contra la API en vivo
El test se vuelve lento, frágil, depende de una credencial y **gasta cuota** que la demo necesita.
Siempre JSON fijado.

### 4) Saltear los casos de error
Siempre: no encontrado, error de validación, sin autenticar, dato de otro usuario, y los cuatro
`status` del proveedor.

### 5) Usar `print` para depurar
Usar `pytest -v` o `pytest --capture=no`.

### 6) Tests que dependen del orden de ejecución
Cada test debe poder correrse aislado.

## Troubleshooting

### Errores de import
- Verificar que existan los `__init__.py` en los directorios de tests.
- Verificar que el código sea importable (`uv run python -c "import app.modules.favorites.service"`).

### Fallan los tests de base de datos
- Aplicar las migraciones: `uv run alembic upgrade head`.
- Verificar que la base de test esté levantada y que `conftest.py` corra las migraciones.

### `RuntimeError: no running event loop` o corrutina sin await
- Falta el marcador async o el `await` sobre la llamada al servicio/repositorio.

### No se encuentra un fixture
- Verificar que esté en `conftest.py` o en el mismo archivo, y que el scope coincida.

### Falla un test de `tests/architecture/`
- Nombra el archivo y la línea del import que cruza la frontera: el arreglo va en `app/`, nunca en
  el test (Artículo IV, `TEST-06`). Un router que necesita `select()` es un service que falta; un
  módulo que necesita el `repository`, el `service` o los `models` de otro es una función que falta
  en el `__all__` del otro. Si lo que necesita es `get_current_user`, no es de ningún módulo: está
  en `app/security.py`.

### Los tests son lentos
- Marcar los lentos con `@pytest.mark.slow` y correr `pytest -m "not slow"` en el bucle corto.
- Revisar los fixtures: un fixture de scope `function` que podría ser `session` se paga en cada
  test.
- **No cambiar un test de integración por uno con mocks para ganar tiempo.** Si la conducta es la
  interacción con la base, el mock no la prueba: sólo prueba que el mock coincide con lo que
  suponés. Se marca lento y se corre en CI.
