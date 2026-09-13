# Skill — Agregar una migración de base de datos

Tags: [database] [migracion] [alembic]

## Objetivo
Crear y aplicar migraciones de Alembic cuando se modifican los modelos de SQLAlchemy.

**CRÍTICO**: los modelos DEBEN estar sincronizados con las tablas. Esta skill garantiza esa
sincronización.

## Cuándo usarla
- Agregar un modelo de SQLAlchemy nuevo.
- Modificar un modelo existente (agregar/quitar columnas, cambiar tipos, índices, constraints).
- Renombrar columnas o tablas.
- Cualquier cambio del esquema de base de datos.

## Precondiciones
- El modelo vive en el `models.py` de su módulo (`backend/app/modules/<modulo>/models.py`). El módulo
  es dueño de su tabla: nadie más la mapea.
- La base de desarrollo está levantada (`make dev`) y `alembic upgrade head` corre sin cambios
  pendientes antes de empezar.

## Reglas (ESTRICTO)
- **NUNCA** modificar modelos sin crear la migración correspondiente.
- **NUNCA** modificar la base a mano sin migración.
- **SIEMPRE** verificar la sincronización después de aplicar.
- Hay un solo esquema (el de por defecto) y cuatro tablas, una por módulo: `users` en `auth/`,
  `stocks` en `stocks/`, `user_stocks` en `favorites/`, `quotes` en `quotes/`.
  `ARCHITECTURE.md` → *Modelo de datos*.
- **NUNCA** importar el modelo de otro módulo: a un módulo ajeno se entra por su paquete y sólo
  se importa lo que declara su `__all__`. Si `favorites/` necesita nombre y moneda de una acción,
  los pide con `from app.modules.stocks import get_stocks` → `get_stocks(symbols)`, en batch.
  `app.modules.stocks.models` es interior ajeno: para el resto del sistema no existe. Un
  `ForeignKey("stocks.symbol")` se escribe como string y no rompe la regla: es SQL, no un import.
- Ningún modelo va en el `__all__` de su paquete: las tablas no cruzan la frontera. El `__init__.py`
  de un módulo tiene sólo docstring, imports y un `__all__` literal —nada de lógica— y hay un test
  que lo verifica.
- Adentro del módulo, `models.py` se importa por ruta completa (`from app.modules.favorites.models
  import UserStock`), **nunca** por `app.modules.favorites`: eso reentra al `__init__` a medio
  inicializar y da un ImportError confuso. El `env.py` de Alembic no es un módulo sino
  infraestructura de migraciones: importa `app.modules.<modulo>.models` por ruta completa para
  juntar el metadata, y es la única entrada legítima al interior de un módulo desde afuera.
- **Nombres (`PY-10`)**: la clase del modelo en `PascalCase` (`UserStock`); columnas, atributos y
  argumentos en `snake_case` (`user_id`, `created_at`); constantes de módulo en `UPPER_SNAKE_CASE`.
  El guión bajo adelante marca lo privado del ARCHIVO —helpers, constantes (`_DEFAULT_TTL`), clases
  auxiliares—; `__all__` marca lo público hacia OTROS MÓDULOS. Son dos niveles distintos: un nombre
  sin guión bajo que no está en `__all__` es interno del módulo, visible para sus hermanos,
  invisible para el resto del sistema. Nada de `__doble_guion_bajo` propio (name mangling); los
  dunder de Python —`__tablename__`, `__table_args__`— son otra cosa.
- Las claves compuestas —`(user_id, symbol)` y `(symbol, interval, ts)`— se declaran en
  `__table_args__`, no se emulan con un `UniqueConstraint` sobre un `id` autoincremental.
- El engine de Alembic es **async** (asyncpg), igual que el de la aplicación, y toma la `Base`
  declarativa de `app/db.py`: es la única que comparten todos los módulos.

## Pasos (ORDEN OBLIGATORIO)

### 1) Modificar el modelo
- Actualizar el modelo en `backend/app/modules/<modulo>/models.py`: el módulo es el dueño de la
  capacidad a la que pertenece la tabla (`auth`, `stocks`, `favorites`, `quotes`).
- Si el módulo ya tiene varios modelos y `models.py` se volvió incómodo, crecé el archivo a
  carpeta: `models/` con un archivo por tabla. Es la convención de todas las piezas del módulo,
  y para Alembic no cambia nada mientras `env.py` importe lo nuevo.
- Sintaxis de SQLAlchemy 2.0: `Mapped[...]` + `mapped_column(...)`.
- Type hints correctos y explícitos.
- Nombres según `PY-10`: clase en `PascalCase`, columnas en `snake_case`, y los helpers que sólo
  usa ese archivo con guión bajo adelante.
- Verificar que las claves e índices declarados en `__table_args__` sean los que el repository del
  módulo realmente consulta: un índice que ninguna query usa es escritura más lenta a cambio de
  nada.

### 2) Generar la migración
```bash
cd backend
uv run alembic revision --autogenerate -m "Descripción del cambio"
```

### 3) Revisar la migración generada
- Abrir el archivo nuevo en `backend/alembic/versions/`.
- Verificar que las altas/bajas de columnas sean las esperadas.
- Verificar los tipos de datos y las constraints.
- Verificar que ninguna operación lleve `schema=`: acá hay un solo esquema, el de por defecto.
  Una tabla creada en otro esquema es una tabla que la aplicación no encuentra.
- Descartar cambios inesperados: tablas que el autogenerate propone borrar porque no las conoce,
  índices que nadie pidió.

### 4) Editar la migración si hace falta
- Completar a mano lo que el autogenerate no detecta (renombres, cambios de tipo con `USING`,
  índices parciales).
- Agregar migraciones de datos si son necesarias (valores por defecto, backfill).
- Verificar que `downgrade()` sea coherente.

### 5) Aplicar la migración
```bash
cd backend
uv run alembic upgrade head
```

### 6) Verificar la sincronización
- Volver a correr `uv run alembic revision --autogenerate -m "check"`: si genera operaciones,
  el modelo y la base **no** están sincronizados. Corregir y **borrar** esa revisión de control.
- Correr los tests para confirmar que los modelos funcionan.
- Correr `backend/tests/architecture/test_module_boundaries.py`: si el modelo nuevo arrastró un import
  de otro módulo, o si terminó exportado en un `__init__.py`, el test falla nombrando archivo y
  línea.
- Revisar que no haya errores en los logs de la aplicación.

### 7) Commitear
Commitear juntos:
- los cambios de `backend/app/modules/<modulo>/models.py`
- el archivo de migración (`backend/alembic/versions/...`)

## Validación
- La migración está creada y revisada.
- `uv run alembic upgrade head` se aplicó sin errores.
- Un `--autogenerate` de control no detecta diferencias (modelos sincronizados).
- `uv run alembic downgrade -1` seguido de `upgrade head` funciona.
- Los tests pasan con el esquema nuevo, el de fronteras incluido.
- Las cuatro tablas siguen en el esquema por defecto, cada una mapeada en su módulo y con sus
  claves compuestas intactas.
- Ningún `__init__.py` cambió: los modelos siguen fuera de los `__all__`.

## Errores comunes (evitar)
- Modificar modelos sin migración.
- Modificar la base a mano.
- No revisar la migración generada.
- Mapear en un módulo una tabla que es de otro, o importar su modelo para hacer un join: eso
  disuelve la frontera y deja al módulo ajeno sin poder cambiar su tabla. Se pide por el paquete
  (`from app.modules.stocks import get_stocks`), nunca por `app.modules.stocks.models`.
- Agregar el modelo al `__all__` del módulo para que otro lo importe: eso hace pública la tabla y
  ata el esquema de un módulo al código de otro. Lo que cruza es una función y un tipo, no una fila.
- Olvidarse del índice por `(symbol, interval, ts DESC)`: es el que sirve todo gráfico.
- Aplicar la migración y no commitear el archivo.
- Escribir una migración que además corrija datos: los datos se arreglan con el seed, no con DDL.
- Dejar un `downgrade()` vacío o inconsistente.

## Troubleshooting
- La migración falla → revisar el estado de la base y hacer `alembic downgrade` si hace falta.
- Los modelos quedaron desincronizados → generar una migración de corrección.
- El autogenerate no detecta el cambio → editar la migración a mano (renombres y cambios de
  tipo casi nunca se detectan).
- El autogenerate propone borrar tablas que sí existen → falta importar el `models.py` de algún
  módulo en `backend/alembic/env.py`: lo que no está en el metadata de `app/db.py:Base`, para
  Alembic no existe. Módulo nuevo = import nuevo en `env.py`.
- `multiple heads` → hay dos ramas de migración: mergearlas con `alembic merge`.
