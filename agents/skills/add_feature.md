# Skill — Agregar una feature full-stack

Tags: [feature] [fullstack]

## Objetivo
Implementar una feature completa (backend + frontend) sobre los dos proyectos:
- backend en el módulo de dominio que le corresponde: `backend/app/modules/<módulo>/`, con el flujo
  interno `router.py` → `service.py` → `repository.py`
- páginas en `frontend/src/pages/`
- componentes en `frontend/src/components/`
- contrato conectado por los tipos generados desde OpenAPI

## Cuándo usarla
- Agregar una capacidad que necesita API y UI.
- Poner en marcha una capacidad nueva de punta a punta (auth, favoritas, cotizaciones).

## Precondiciones
- Existe `docs/specs/<NNN-feature>/spec.md` **aprobada** por el cliente y su `plan.md`.
- Está decidido a qué módulo pertenece la capacidad (`auth`, `stocks`, `favorites`, `quotes`): es
  la carpeta que se va a tocar, y adentro de ella cada pieza del módulo.
- Si la capacidad necesita datos de otro módulo, está decidido qué suma ese módulo al `__all__` de
  su `__init__.py` y con qué firma.
- Los modelos de base de datos y los requisitos de UI están identificados.

## Pasos (ORDEN OBLIGATORIO)

### 1) Construir el backend
Seguir `add_backend_feature`:
- ubicar la capacidad en un módulo existente o abrir uno nuevo en `backend/app/modules/<módulo>/`
- escribir las piezas del módulo: `router.py` (HTTP: rutas, códigos, autorización), `io.py`
  (schemas Pydantic de entrada y salida), `service.py` (las decisiones del negocio),
  `repository.py` (acceso a datos), `models.py` (SQLAlchemy)
- cada pieza arranca como archivo y crece a carpeta del mismo nombre cuando hace falta:
  `io.py` → `schemas/io.py` + `schemas/<otros>.py`, `service.py` → `services/`, y así. El nombre
  no cambia nunca, así el módulo se lee igual con 50 líneas que con 500
- las excepciones del dominio heredan de `DomainError` (`backend/app/errors.py`) y viven en el
  módulo que las levanta: el service no conoce `fastapi`
- registrar el router en `backend/app/main.py` —el composition root— y ahí mismo la traducción de
  `DomainError` a códigos HTTP
- si otro módulo necesita algo de éste, sumarlo al `__all__` de su `__init__.py`: el contrato del
  módulo es su paquete. **Afuera:** se entra por el paquete —`from app.modules.stocks import
  get_stocks, StockInfo`—; cualquier ruta más profunda (`app.modules.stocks.service`,
  `app.modules.stocks.models`) es interior ajeno y para el resto del sistema no existe. `main.py`
  entra por la misma puerta que todos: `from app.modules.stocks import router`. Un módulo con la
  frontera cerrada se extrae a microservicio sin arqueología
- **Adentro:** los archivos del módulo se importan entre sí por ruta completa
  (`from app.modules.stocks.service import get_stocks`), **nunca** por `app.modules.stocks`: eso
  reentra al `__init__` a medio inicializar y da un ImportError confuso
- el `__init__.py` del módulo tiene SÓLO docstring, imports y un `__all__` que es una lista literal
  de strings. Nada de lógica: hay un test que lo verifica, y mypy con `no_implicit_reexport = true`
  hace cumplir el `__all__` (`PY-09`, Blocker)
- los nombres siguen `PY-10`: `snake_case` para funciones, métodos, variables y argumentos;
  `PascalCase` para clases; `UPPER_SNAKE_CASE` para constantes de módulo, siempre en mayúsculas;
  `_guion_bajo` adelante para lo privado del archivo —funciones, variables, constantes
  (`_DEFAULT_TTL`), métodos y clases auxiliares que no se usan fuera del archivo donde viven—.
  Nada de `__doble_guion_bajo` (name mangling) salvo que haya una razón escrita
- la autorización del router no se importa de `auth`: `get_current_user` y `CurrentUser` son
  primitivas de seguridad y viven en `app/security.py`, al lado de Argon2 y JWT
  (`from app.security import get_current_user, CurrentUser`)

Router, service y repository van los tres o no va ninguno: un service sin router es lógica que
nadie invoca, un router sin service es una capa salteada. El `__all__` se mide con regla corta:
entra sólo lo que otro módulo consume de verdad. Hoy `auth`, `favorites` y `quotes` exportan nada
más que su `router`, y el inventario completo de lecturas cruzadas del backend son `get_stocks` y
`StockInfo`, de `stocks`, que consume `favorites` para la grilla.

El guión bajo y el `__all__` son dos niveles de privacidad distintos: el guión bajo marca lo privado
del ARCHIVO, el `__all__` marca lo público hacia OTROS MÓDULOS. Un nombre sin guión bajo que no está
en `__all__` es interno del módulo: visible para sus hermanos, invisible para el resto del sistema.

Si la feature cruza módulos, la función pública se diseña **en batch**. La grilla de "Mis Acciones"
vive en `favorites/` y necesita símbolo, nombre y moneda de `stocks/`: se resuelve con
`get_stocks(symbols: list[str]) -> list[StockInfo]`, una sola consulta para toda la grilla. Un
`get_stock(symbol)` en un `for` es un N+1 disfrazado de contrato.

### 2) Migrar la base de datos (si se tocaron modelos)
Seguir `add_database_migration`: generar la migración, revisarla, aplicarla y verificar la
sincronización. El backend tiene que estar funcionando antes de tocar el frontend.

### 3) Generar el contrato
```bash
make types
```
Los tipos del frontend salen del schema de OpenAPI del backend: no se escriben a mano.

### 4) Construir el frontend
Seguir `add_frontend_feature`:
- página en `frontend/src/pages/`
- componentes en `frontend/src/components/`
- acceso a datos en `frontend/src/api/` (cliente HTTP + tipos generados), sesión y 401 en `frontend/src/auth/`
- colores y tipografía desde `frontend/src/styles/tokens.css`, nunca escritos a mano

### 5) Agregar trabajo en background (si hace falta)
No hay trabajo en background en este proyecto: la caché de cotizaciones se refresca por demanda con TTL (`ADR-003`).

### 6) Agregar tests
- Backend: unitarios del servicio + integración de endpoints y repositorio.
- Frontend: tests de componente y del flujo crítico.
- Ver `add_tests`.

### 7) Actualizar diagramas y documentación
- Actualizar `ARCHITECTURE.md` / `AGENTS.md` si aparece un módulo nuevo, o si cambia lo que un
  módulo expone por el `__all__` de su `__init__.py`.

## Validación
- Los endpoints responden lo esperado y aparecen en `/docs`.
- Las páginas renderizan e interactúan correctamente contra el backend real.
- Los tipos de TypeScript están generados desde OpenAPI y en uso.
- Las migraciones están aplicadas y los modelos sincronizados.
- Los tests pasan (backend y frontend).
- `backend/tests/architecture/` pasa: `test_module_boundaries.py` lee los imports con `ast` y no
  encuentra ningún import a otro módulo que entre por debajo de su paquete (`GEN-02`); el
  `__init__.py` de cada módulo tiene sólo docstring, imports y un `__all__` literal; ningún router
  importa SQLAlchemy; ningún service importa `fastapi`; y nadie sale al mundo por fuera de
  `app/providers/` (`GEN-08`).
- Los diagramas de la feature siguen coincidiendo con la spec.

## Errores comunes (evitar)
- Construir backend y frontend por separado y recién al final intentar integrarlos.
- No regenerar los tipos desde OpenAPI después de cambiar los schemas.
- Saltear las migraciones.
- Saltear una capa "porque queda más cómodo": un `select()` en el router, o un service que levanta
  `HTTPException` en vez de una subclase de `DomainError`.
- Atravesar la frontera de un módulo: importar el `repository`, el `service` o los `models` de otro
  módulo en vez de entrar por su paquete. No hay excepción por nombre de archivo.
- Importar adentro del módulo por `app.modules.<módulo>` en vez de la ruta completa del archivo:
  reentra al `__init__` a medio inicializar y rompe con un ImportError que no dice nada.
- Buscar `get_current_user` en `auth`: no es lógica de dominio de `auth`, es una primitiva de
  seguridad que consumen los routers de todos los módulos.
  ✅ `from app.security import get_current_user, CurrentUser`
  ❌ importarlo desde el paquete `app.modules.auth` — no es de `auth`
- Bautizar mal (`PY-10`): una constante de módulo en minúsculas, un helper privado del archivo sin
  `_` adelante, o un `__doble_guion_bajo` sin razón escrita.
- Resolver una lectura cruzada de a un registro por vez en lugar de pedirla en batch.
- Llamar al proveedor externo desde un service: se consume sólo por `MarketDataProvider`.
- No manejar los estados de carga y error en el frontend.

## Troubleshooting
- Los tipos quedaron desfasados → regenerar desde el schema de OpenAPI.
- Los modelos quedaron desincronizados → `add_database_migration`.
- Problemas de integración → verificar el router registrado en `main.py`, el prefijo del
  endpoint y la configuración del cliente de API en `frontend/src/api/`.
- El test de arquitectura rompe el build → la frontera está mal trazada, no el test. Te nombra
  archivo y línea: si el import es a otro módulo, sumá lo que necesitás al `__all__` del
  `__init__.py` de ese módulo; si es adentro del módulo, movelo a la pieza que le corresponde
  (Artículo IV).
- `ImportError` raro al levantar el módulo → adentro estás importando por `app.modules.<módulo>`.
  Cambialo por la ruta completa del archivo (`app.modules.<módulo>.service`).
