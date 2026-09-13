# Skill — Tocar la integración con el proveedor de datos

Tags: [integracion] [proveedor] [cuota]

Rol dueño: **Developer**.

## Objetivo
Traer datos de un sistema externo respetando las reglas del dominio. La integración de referencia
—y hoy la única— es **TwelveData**: una API REST pública, de **solo lectura**, con una cuota de
**800 requests por día** que es el recurso más escaso del proyecto.

## Cuándo usarla
- Agregar o cambiar un endpoint del proveedor que se consume.
- Tocar `MarketDataProvider` o su implementación `TwelveDataProvider`.
- Cambiar la lógica de caché o de detección de huecos del `QuoteService`
  (`backend/app/modules/quotes/service.py`).
- Integrar cualquier otro proveedor de datos de mercado (mismo procedimiento).

## Precondiciones
- El endpoint del proveedor está identificado: qué parámetros toma, qué devuelve, qué límites
  tiene en el plan gratuito.
- Hay una **respuesta JSON real capturada** como fixture para desarrollar y testear.
- La API key está en el entorno (`.env`), nunca en la base ni en el repositorio.
- Está claro a qué tabla va lo traído y con qué clave se deduplica.

## Reglas (ESTRICTO)
1. **La API key vive sólo en el backend** (Artículo I). Nunca en una variable `VITE_*`, nunca en
   una respuesta de la API, nunca en un log ni en un traceback.
2. **No se consulta al proveedor si el dato se puede servir de la base** (Artículo II). El
   consumo escala con símbolos observados, no con clientes conectados.
3. **Todo pasa por el protocolo, y la salida al mundo vive en `app/providers/`** (`GEN-08`).
   Ningún archivo de afuera importa un cliente HTTP; el nombre `twelvedata`, su URL base y su key
   aparecen sólo en `app/providers/twelvedata.py`, que la lee de `app/settings.py`.
4. **El proveedor es interno al módulo `quotes`.** Ningún otro módulo lo importa: la frontera dice
   que a un módulo ajeno se entra por su paquete —`from app.modules.quotes import ...`, o sea lo
   que declara su `__all__`— y que cualquier ruta más profunda (`app.modules.quotes.service`, y con
   más razón `app/providers/`) es interior ajeno. Hoy `quotes` exporta sólo su `router`: si
   `favorites/` o cualquier otro necesita una cotización, se agrega esa función al `__all__` del
   paquete y se importa de ahí, nunca del provider ni del service.
5. **El protocolo devuelve tipos del dominio**, no el JSON del proveedor. Si ese shape se filtra
   hacia arriba, la interfaz no aisló nada y cambiar de proveedor vuelve a tocar todo.
6. **Una falla del proveedor no llega cruda al cliente** (`ERR-05`). Se traduce a un `status`
   tipado y se responde con lo último conocido.

## Pasos (ORDEN OBLIGATORIO)

### 1) Ubicar el cambio dentro del módulo `quotes`
- El cliente HTTP y el mapeo del JSON viven en `app/providers/twelvedata.py`.
- El protocolo, en `app/providers/base.py`.
- **Cuándo** llamar al proveedor no es del provider: es una decisión de negocio y vive en
  `backend/app/modules/quotes/service.py`. Un provider que decide si vale la pena llamar es un service
  disfrazado.
- Adentro del módulo el flujo sigue en un solo sentido: `router.py` → `service.py` →
  `repository.py`, y el provider cuelga del service. Cada pieza es un archivo hasta que crece a
  carpeta del mismo nombre (`service.py` → `services/`); `providers/` ya nació carpeta porque
  tiene protocolo e implementación.
- Los archivos del módulo se importan entre sí **por ruta completa**
  (`from app.modules.quotes.repository import save_quotes`), nunca por `app.modules.quotes`: eso
  reentra al `__init__` a medio inicializar y el ImportError que sale no dice eso.
- `app/providers/` es infraestructura al lado de `shared/`, no un módulo: no tiene `__init__` con
  contrato ni `__all__`, se importa por ruta —y sólo desde adentro de `quotes`.

### 2) Extender el protocolo primero
- Agregar el método a `MarketDataProvider` con sus tipos del dominio, antes de implementarlo.
- Si el método sólo tiene sentido para TwelveData, no va en el protocolo: es una señal de que el
  dato pedido está mal modelado.
- Actualizar también el `FakeProvider` de los tests: un protocolo con una implementación sin la
  otra rompe la suite, y así tiene que ser.

### 3) Implementar el cliente
- Timeouts, URL base, key y límite de reintentos salen de `Settings` (`backend/app/settings.py`);
  nada hardcodeado.
- La salida de esta capa son **tipos del dominio**, ya normalizados: `Decimal` para precios,
  `datetime` con timezone para las marcas de tiempo.
- TwelveData devuelve **200 con un cuerpo de error** en varios casos: se verifica el contenido,
  no sólo el código HTTP.
- Nombres según `PY-10`: `snake_case` para funciones, variables y argumentos; `PascalCase` para
  clases; `UPPER_SNAKE_CASE` para las constantes de módulo (`DEFAULT_TIMEOUT_SECONDS`), siempre en
  mayúsculas; y `_` adelante para lo privado del archivo —helpers de mapeo, constantes internas
  (`_RETRY_BACKOFF`), clases auxiliares—. Sin `__doble_guion_bajo` salvo razón escrita.
- Son dos niveles de privacidad distintos: el guión bajo marca lo privado del **archivo**; el
  `__all__` del paquete marca lo público hacia **otros módulos**. En `app/providers/`, que no tiene
  `__all__`, el guión bajo es el único marcador que hay.

### 4) Decidir cuándo llamar (la parte que importa)
En `QuoteService`, y no en otro lado:
- Resolver primero contra `quotes`: qué tramos del rango pedido ya están.
- Llamar al proveedor **sólo por el hueco**, nunca por el rango entero.
- TTL por intervalo: un punto de `5min` no está vencido hasta que pasaron 5 minutos.
- Persistir lo traído **antes** de responder: si no se guarda, la próxima consulta vuelve a
  gastar cuota por el mismo dato.

### 5) Configurar
- Agregar a `Settings` (`backend/app/settings.py`, pydantic-settings) y a `.env.example`: URL base,
  API key, timeouts, límite de reintentos. `TWELVEDATA_API_KEY` se lee ahí y sólo ahí: el provider
  recibe la config, no la va a buscar al entorno.
- Nunca loguear la key. Si se loguea la URL, se enmascara el parámetro `apikey`.

### 6) Manejar los errores
- Cuota agotada (429 o el cuerpo de error correspondiente) → `status: stale` con lo último
  conocido. **Nunca** un 429 reenviado al navegador: el usuario no tiene cuenta en TwelveData.
- Timeout o error de red → `status: stale`, con logging estructurado.
- El día pedido no tiene rueda → `status: market_closed`, y se devuelve la última disponible.
- El símbolo no tiene serie para ese intervalo → `status: no_data`.
- Un error que no encaja en ninguno de los cuatro es un bug: se levanta como `DomainError` del
  módulo y lo traduce a HTTP `main.py`; no se disfraza de `stale`.

### 7) Agregar tests
- Contra **JSON fijado** en `backend/tests/fixtures/twelvedata/`. **Nunca contra la API en vivo.**
- Casos obligatorios: respuesta normal, rango con hueco parcial, respuesta vacía, cuota agotada,
  timeout, y cuerpo de error con HTTP 200.
- El test que demuestra el Artículo II: **N consultas sobre el mismo símbolo generan una sola
  llamada al proveedor.** Es el que hay que poder mostrar cuando pregunten por escalabilidad.

### 8) Documentar
- En la spec de la feature: qué endpoint se consume, con qué frecuencia y cuánta cuota implica.
- Guardar la fixture usada, con la fecha de captura.

## Validación
- La consulta corre de punta a punta contra las fixtures y deja filas en `quotes`.
- Repetir la consulta **no** vuelve a llamar al proveedor mientras el TTL no venció.
- Los cuatro `status` están cubiertos por un test cada uno.
- El frontend no conoce el proveedor:
  ```bash
  cd frontend && grep -rniE "twelvedata|apikey|api_key" src   # no debe devolver nada
  ```
- Nadie salió al mundo por fuera de `app/providers/`, ni importando un cliente HTTP ni nombrando
  al proveedor:
  ```bash
  cd backend && grep -rnE "^\s*(import|from)\s+(httpx|requests|aiohttp|urllib\.request)\b" app | grep -v "^app/providers/"
  cd backend && grep -rni "twelvedata" app --include=*.py | grep -vE "^app/(providers/twelvedata\.py|settings\.py)"
  ```
- Nadie cruzó la frontera para llegar al provider ni al interior de `quotes`:
  ```bash
  cd backend && uv run pytest tests/architecture/test_module_boundaries.py
  cd backend && grep -rn "app\.modules\.quotes\." app --include=*.py | grep -v "^app/modules/quotes/"
  ```
- No hay credenciales en el código ni en los logs; todo sale de `Settings`.
- La suite pasa sin red y sin API key:
  ```bash
  cd backend && TWELVEDATA_API_KEY= uv run pytest
  ```

## Errores comunes (evitar)
- Llamar al proveedor desde un router, o desde el frontend "para probar rápido".
- Importar `app/providers/twelvedata.py`, el service o el repository de `quotes` desde otro módulo
  en vez de entrar por el paquete (`from app.modules.quotes import ...`).
- Importar un hermano del propio módulo por `app.modules.quotes` en vez de por ruta completa.
- Meter lógica en el `__init__.py` de `quotes`: ahí van docstring, imports y `__all__`, nada más.
- Una constante del provider en minúsculas, o un helper interno del archivo sin `_` adelante
  (`PY-10`).
- Pedir el rango entero cuando falta un tramo.
- Devolver el JSON de TwelveData tal cual hacia arriba porque "ya tiene los campos".
- Reenviar el 429 del proveedor al navegador.
- Testear contra la API en vivo: gasta la cuota que la demo necesita.
- Cachear sin TTL, o con un TTL que no depende del intervalo.
- Hardcodear la URL, la key o los timeouts.

## Troubleshooting
- Respuestas vacías inesperadas → verificar si el mercado estaba cerrado antes de buscar el bug
  en el código; es `market_closed`, no una falla.
- La cuota se agota rápido → revisar que el autocomplete consulte la base y no al proveedor
  (`ADR-002`), y que el TTL esté funcionando: casi siempre es una caché que no persiste.
- Los tests fallan pidiendo la API key → algo está saliendo a la red; el `FakeProvider` no se
  está inyectando.
- Precios con errores de redondeo → se están mapeando a `float` en lugar de `Decimal`.
