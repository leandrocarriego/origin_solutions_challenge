# Skill — Depurar un fallo

Tags: [debug] [transversal] [calidad]

## Objetivo

Encontrar la causa raíz de un fallo y corregirla con el cambio mínimo, dejando un test que
demuestre que el caso quedó cubierto.

Es la única skill **transversal**: se puede disparar en cualquier punto de la cadena, sin
importar en qué paso del flujo SDD esté la feature.

## Cuándo usarla

- Un test falla, un endpoint devuelve algo que no corresponde, o el frontend rompe.
- Una cotización vuelve `stale` o `no_data` cuando debería tener serie, o la caché no sirve lo
  que ya trajo.
- Un comportamiento en producción no coincide con lo que la spec prometía.
- El build, el linter o el type-check fallan por una causa que no es obvia.

No la uses para agregar capacidades: eso es `add_backend_feature`, `add_frontend_feature` o
`add_feature`.

## Precondiciones

- Existe información real del fallo: un mensaje de error, un stack trace, un test rojo o una
  respuesta concreta del endpoint que no coincide con lo que la spec prometía.
- **Si no hay información del error, PARÁ y pedila.** Depurar sin evidencia es adivinar.

## Reglas (ESTRICTO)

- **Reproducir antes de arreglar.** Un fallo que no se pudo reproducir no se puede dar por
  corregido.
- **Leer el stack trace completo**, no su resumen. La causa raíz casi nunca está en la línea
  que se imprime primero.
- **Un fallo del proveedor y un mercado cerrado no son lo mismo**, aunque los dos devuelvan una
  serie vacía:
  - TwelveData no respondió, dio timeout o agotó la cuota → `status: stale`
  - el día pedido no tuvo rueda → `status: market_closed`, y **no es un bug**
  - Antes de buscar el error en el código: mirar si era sábado (ver `CONVENTIONS.md`, `ERR-05`)
- **Nunca "arreglar" la cuota subiendo el TTL sin entender por qué se gastó.** Casi siempre es una
  caché que no persiste, o el autocomplete pegándole al proveedor.
- El arreglo respeta las convenciones y las fronteras como cualquier otro cambio: un fix no es
  una excepción a `CONVENTIONS.md`.

## Pasos (ORDEN OBLIGATORIO)

### 1) Recolectar la evidencia
- Backend: `docker compose logs api`, o la salida de `uv run uvicorn` en desarrollo.
- Base: `docker compose logs db`.
- Llamadas al proveedor: el log estructurado de `app/providers/twelvedata.py`, que registra cada
  consulta y su resultado precisamente para este momento (`CONVENTIONS.md`, `ERR-07`).
- Frontend: consola del navegador y la salida de `npm run dev`.

### 2) Seleccionar el rol
La depuración se hace **bajo el rol del área afectada**, con sus restricciones:
- Backend, módulos, fronteras → `Backend-Architect`
- Frontend, React/Vite → `Frontend-Architect`
- Implementación dentro de un módulo → `Developer`
- Suite de tests, fixtures, cobertura → `Tester`

### 3) Reproducir
Escribí el caso mínimo que falla. Si es reproducible desde un test, **el test es el primer
entregable**: convierte el reporte en algo verificable y evita que el fallo vuelva.

### 4) Aislar la causa raíz
- ¿Las migraciones están aplicadas? `uv run alembic current` contra `uv run alembic heads`.
- ¿Los modelos están sincronizados con las tablas? `uv run alembic check`.
- ¿Las variables de entorno están donde el código las busca? El `.env` se lee desde la raíz del
  repositorio, no desde el directorio de trabajo.
- ¿El fallo cruza una frontera —entre módulos, o entre las capas de un módulo? Un import que no
  debería existir explica más bugs de los que parece.

### 5) Corregir con el cambio mínimo
Arreglá la causa, no el síntoma. Si el arreglo se está volviendo grande, es señal de que el
problema es de diseño: escalá al arquitecto en vez de seguir parchando.

### 6) Verificar
```bash
cd backend && uv run pytest -q && uv run ruff check app tests && uv run mypy app
cd ../web && npx tsc --noEmit && npm run lint
```

## Validación

- El fallo se reprodujo antes de tocar nada.
- Existe un test que falla sin el arreglo y pasa con él.
- La causa raíz está explicada, con la evidencia que la sostiene.
- La suite completa pasa; no se debilitó ningún test para lograrlo (`CONVENTIONS.md`, `TEST-06`).
- Si el fallo se originó en una expectativa equivocada de la spec o del plan, quedó reportado
  para el rol dueño de ese artefacto, no arreglado en silencio en el código.

## Errores comunes (evitar)

- **Arreglar el síntoma.** Silenciar una excepción o agregar un `if` defensivo sin entender por
  qué llegó ese valor.
- **Debilitar el test que descubrió el bug** (`skip`, `xfail` sin razón, assert relajado) en vez
  de corregir el código. Es Blocker en el review.
- **Confundir un mercado cerrado con un bug**, y "arreglar" código que estaba bien.
- **Depurar contra la API en vivo.** El proveedor se prueba contra JSON fijado: cada corrida
  gasta cuota que la demo va a necesitar.
- **Arreglar sin reproducir** y declarar el trabajo terminado.

## Troubleshooting

### El fallo no se reproduce localmente
Compará entorno: versión de Python, migraciones aplicadas, contenido del `.env`, y si la base
tiene los datos que el caso supone. Si sólo aparece a la segunda corrida, revisá si depende del
estado que dejó la primera — el alta de una favorita tiene que ser idempotente
(`CONVENTIONS.md`, `TEST-04`).

### El endpoint devuelve `stale` y no se entiende por qué
`stale` es la respuesta a una falla del proveedor —timeout, cuota agotada, error— servida con lo
último conocido de la base (`ADR-005`, `ERR-05`). El motivo está en el log de
`app/providers/twelvedata.py`; si ahí no hay nada, la llamada nunca salió y el hueco se calculó
mal en el service.

### La cuota se gastó y nadie sabe en qué
Las dos causas habituales: el autocomplete pegándole al proveedor en vez de a la tabla `stocks`,
que se ingesta una sola vez (`ADR-002`), o una caché que no persiste — `quotes` guarda lo traído
y el TTL es el intervalo (`ADR-003`), así que dos consultas seguidas al mismo rango no pueden
costar dos llamadas.
