# [Nombre de la feature] — Plan técnico

<!--
  ARTEFACTO INTERNO. Acá van las decisiones técnicas que spec.md no puede llevar.
  No se exporta al cliente.
-->

**Feature:** [NNN-feature-slug] · **Spec aprobada el:** [YYYY-MM-DD] · **Fecha:** [YYYY-MM-DD]

<!-- Si la spec no está Aprobada, este documento no debería existir todavía (Artículo V). -->

## Constitution Check

<!--
  Obligatorio antes de pasar a /tasks. Se declara explícitamente, artículo por
  artículo, que el enfoque elegido no viola ninguno. Un plan que no pasa este
  chequeo no avanza, aunque sea técnicamente correcto.
-->

| Artículo | Cumple | Cómo |
|---|---|---|
| I — La credencial del proveedor vive sólo en el backend | | |
| II — La cuota es finita, y eso es parte del diseño | | |
| III — Los datos de un usuario son de ese usuario | | |
| IV — Las fronteras entre módulos son reales | | |
| V — Spec primero, y con firma | | |
| VI — Lo que no está tipado y testeado no está terminado | | |
| VII — El enunciado es el contrato, y sus ambigüedades se declaran | | |
| VIII — Un idioma para cada audiencia | | |
| IX — Las dependencias entran por la puerta | | |
| X — Las decisiones de arquitectura las toma un humano | | |

**Excepciones solicitadas:** ninguna.

<!--
  Si alguna hace falta: cuál, por qué, y qué alternativa se descartó. Una excepción
  a la constitución NO la aprueba un agente — la aprueba el humano, y queda acá.
-->

## Enfoque

<!-- Cómo se resuelve, en tres o cuatro párrafos. Lo suficiente para que otro pueda implementarlo sin adivinar. -->

## Módulos afectados

| Módulo | Piezas tocadas | Qué cambia | Nuevo |
|---|---|---|---|
| `auth` | `backend/app/modules/auth/` | | |
| `stocks` | `backend/app/modules/stocks/` | | |
| `favorites` | `backend/app/modules/favorites/` | | |
| `quotes` | `backend/app/modules/quotes/` | | |
| composition root · shared · providers | `backend/app/main.py` · `backend/app/settings.py` · `backend/app/` (`db.py` · `errors.py` · `security.py`) · `backend/app/providers/` | | |
| web | `frontend/src/` | | |

<!--
  Los módulos del backend son `auth`, `stocks`, `favorites` y `quotes`: no hay más
  capacidades y una nueva se discute, no se agrega de costado. Un módulo nuevo nace
  completo —su router, su service y su repository: los tres, o ninguno. Un service sin
  router es lógica que nadie invoca, y un router sin service es una capa salteada
  (ARCHITECTURE.md → Agregar una feature).

  En "Piezas tocadas" se nombra el archivo, no la capa: `favorites/service.py`,
  `quotes/repository.py`, `stocks/__init__.py`. La anatomía de un módulo es `router.py` ·
  `io.py` · `service.py` · `repository.py` · `models.py`, y cada pieza empieza como ARCHIVO y
  crece a CARPETA del mismo nombre cuando lo pide el tamaño —`service.py` → `services/`,
  `io.py` → `schemas/io.py` + `schemas/<otros>.py`—: si esta feature dispara ese
  crecimiento, se declara acá, porque mueve archivos que otros agentes van a buscar.

  `TWELVEDATA_API_KEY` se lee en `app/settings.py` y en ningún otro lado (Artículo I), y
  el único archivo del repositorio que nombra TwelveData es
  `app/providers/twelvedata.py` (GEN-08).

  Tocar el `__all__` de un `__init__.py` —el propio o el de otro módulo— es un cambio de
  contrato: va en la sección siguiente. Las filas que esta feature no toca se borran.
-->

## Contrato entre módulos

<!--
  La frontera es una sola regla con dos cláusulas, y las dos importan. **Afuera:** a un módulo
  se entra por su paquete —`from app.modules.stocks import get_stocks, StockInfo`—, y el
  contrato es lo que declara `__all__` en su `__init__.py`; cualquier ruta más profunda
  (`app.modules.stocks.service`, `app.modules.stocks.models`) es interior ajeno y para el resto
  del sistema no existe. **Adentro:** los archivos del módulo se importan entre sí por ruta
  completa —`from app.modules.stocks.service import get_stocks`—, nunca por
  `app.modules.stocks`, porque eso reentra al `__init__` a medio inicializar y da un ImportError
  confuso. `main.py` entra por la misma puerta que todos: `from app.modules.stocks import router`.

  El `__init__.py` de un módulo contiene sólo docstring, imports y un `__all__` que es una lista
  literal de strings — nada de lógica. Nada de esto es una recomendación: lo verifica
  `backend/tests/architecture/test_module_boundaries.py`, que lee los imports con `ast`, falla
  nombrando archivo y línea, y rompe el build (Artículo IV).

  `get_current_user` no cruza ninguna frontera de dominio: no es lógica de `auth` sino una
  primitiva de seguridad que consumen los routers de todos los módulos, y vive en
  `app/security.py` junto con Argon2 y JWT — `from app.security import
  get_current_user, CurrentUser`.

  Adentro del módulo el flujo sigue yendo en un solo sentido —`router` → `service` →
  `repository`— y el service de `quotes` sale al mundo por `MarketDataProvider`. Nunca al
  revés, nunca salteado (GEN-02, PY-06).

  Acá se declara, para esta feature, qué se pide y qué se recibe en cada frontera: la firma
  del service, qué devuelve el repository (datos, nunca decisiones), qué trae el provider
  (tipos del dominio, nunca el JSON crudo del proveedor — GEN-08), qué le pide este módulo
  al `__all__` ajeno y qué agrega al propio.

  Lo que entra en un `__all__` se sostiene para siempre: se expone lo mínimo, con tipos
  propios del módulo, y en BATCH —`get_stocks(symbols)` para toda la grilla, nunca un
  `get_stock()` por fila, que es N+1 (ARCHITECTURE.md → La lectura cruzada). Hoy el inventario
  completo de lecturas cruzadas del backend es `get_stocks` y `StockInfo`, de `stocks`, que
  consume `favorites`: los `__init__.py` de `auth`, `favorites` y `quotes` exportan sólo su
  `router`. Un service no importa el service de otro módulo (GEN-05): le pide al paquete, o el
  corte entre módulos está mal hecho. Si esta feature no cruza alguna frontera, escribir
  "Ninguna" y no borrar la fila.

  Son dos niveles de privacidad distintos y no se mezclan: el guión bajo marca lo privado del
  ARCHIVO, `__all__` marca lo público hacia OTROS MÓDULOS (PY-10). Un nombre sin guión bajo que
  no está en `__all__` es interno del módulo: visible para sus hermanos, invisible para el resto
  del sistema.
-->

| Frontera | Qué se pide | Qué se devuelve |
|---|---|---|
| router → service | | |
| service → repository | | |
| service → provider | | |
| este módulo → `__all__` de otro | | |
| `__all__` de este módulo → el resto (qué se agrega) | | |

**Fallas** — [qué excepción de dominio —subclase de `DomainError`, en `app/errors.py` o en el propio módulo— levanta el service, y con qué código HTTP la traduce `app/main.py`]

<!-- Un service no importa `fastapi` ni levanta `HTTPException` (PY-06). Una falla nueva es un tipo nuevo que hereda de `DomainError` más su traducción registrada en `app/main.py`; el router de un módulo nuevo también se monta ahí, explícitamente (GEN-04). `app/main.py` es el composition root: el único archivo que conoce todos los módulos. -->

## Datos

<!-- Entidades, campos y estados nuevos o modificados. El detalle largo va en data-model.md. Toda tabla nueva necesita su migración (DB-01), y las migraciones son del proyecto: viven en `backend/alembic/versions/`, no adentro del módulo. Cada tabla tiene un módulo dueño —`users` es de `auth/`, `stocks` de `stocks/`, `user_stocks` (PK `user_id`+`symbol`) de `favorites/` y `quotes` (PK `symbol`+`interval`+`ts`) de `quotes/`— y sus modelos SQLAlchemy viven ahí. Las cuatro viven en un solo esquema, el de por defecto (ARCHITECTURE.md → Modelo de datos): una quinta se justifica, no se agrega. Las claves foráneas cruzan la frontera —`user_stocks.symbol` referencia `stocks.symbol`—: el aislamiento es de código, no de datos, y eso está asumido a propósito. -->

## Contratos

<!-- Endpoints y sus schemas, o el puntero a contracts/. Toda ruta declara su autorización (PY-08), y `get_current_user` se importa de `app/security.py`, nunca de un módulo. Los schemas de entrada y salida van en el `io.py` del módulo (→ `schemas/` al crecer), nunca en un cajón común; los tipos que consume el frontend se generan del OpenAPI (`make types`) y no se escriben a mano en las dos puntas. -->

## Alternativas descartadas

<!-- Qué más se consideró y por qué no. Evita que la próxima persona repita el análisis. El detalle largo va en research.md. -->

## Riesgos

| Riesgo | Impacto | Cómo se mitiga |
|---|---|---|
| | | |

## Contexto de traspaso

<!--
  OBLIGATORIO. Lo leen el Developer, el Tester y el Code-Reviewer. Si esta sección
  no existe o dejó de ser verdad, la feature no está lista (Definition of Done).
-->

**Para el Developer** — [por dónde empezar, qué NO tocar, qué decisión ya está tomada y no hay que rediscutir]

**Para el Tester** — [qué es lo que puede romperse de verdad, qué casos borde importan, qué se prueba con JSON fijado del proveedor]

**Para el Code-Reviewer** — [qué convenciones son las que están en juego acá, dónde mirar primero]

<!-- Dos están siempre en juego: la frontera (Artículo IV) y los nombres (PY-10) — `snake_case` para funciones, métodos, variables y argumentos; `PascalCase` para clases; `UPPER_SNAKE_CASE` para constantes de módulo, siempre en mayúsculas; `_guion_bajo` adelante para lo privado del archivo, incluidas constantes (`_DEFAULT_TTL`) y clases auxiliares; nada de `__doble_guion_bajo` salvo que haya una razón escrita. -->
