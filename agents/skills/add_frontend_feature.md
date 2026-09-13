# Skill — Agregar una feature de frontend

Tags: [frontend] [feature] [react]

## Objetivo
Implementar una feature de frontend respetando el árbol de `frontend/src/` (`ARCHITECTURE.md` →
Anatomía del frontend):
- las pantallas viven en `frontend/src/pages/`, **una por wireframe**
- los componentes que comparten esas pantallas viven en `frontend/src/components/`
- el cliente HTTP y los tipos generados del OpenAPI viven en `frontend/src/api/`
- el contexto de sesión y el interceptor de 401 viven en `frontend/src/auth/`
- **el aspecto no se elige: lo fija el wireframe** (`docs/design/wireframes/`) y los textos los
  fija `docs/design/COPY.md`

## Cuándo usarla
- Implementar una de las tres pantallas del enunciado, o extenderla dentro de lo que su wireframe
  ya dibuja.
- Conectar una pantalla existente a un endpoint nuevo del backend.

## Precondiciones
- Existe una `spec.md` aprobada para la feature y los requisitos de UI están claros.
- La pantalla tiene su wireframe en `docs/design/wireframes/` y sus textos en `docs/design/COPY.md`.
- Los endpoints del backend que la feature consume ya existen (o están especificados en
  `contracts/`).

## Reglas (ESTRICTO)
- Modo estricto de TypeScript; sin tipos `any` (usar `unknown` si hace falta) — `TS-01`, `TS-02`.
- Los tipos de la API se **generan** desde el schema de OpenAPI (`make types`), no se escriben a
  mano ni se duplican los schemas del backend (`TS-03`).
- Los strings que ve el usuario son los **literales del enunciado**, verbatim y con sus faltas,
  tomados de `docs/design/COPY.md` (`UI-02`). Lo verifica `frontend/tests/copy.test.ts`.
- **Ningún color escrito a mano** (`UI-03`): sale de un token de `frontend/src/styles/tokens.css`, y la
  paleta es la neutra del wireframe. Lo verifica `frontend/tests/tokens.test.ts`, que rompe el build.
- **Ningún componente conoce TwelveData** (Artículo I): el frontend le habla a nuestra API y sólo
  a nuestra API, y nunca ve la API key.
- La pantalla reproduce la estructura de su wireframe —mismo orden, mismas etiquetas, mismas
  columnas, mismos controles— y no la mejora (`UI-01`).

## Pasos (ORDEN OBLIGATORIO)

### 1) Generar los tipos del contrato
```bash
make types
```
Deja los tipos en `frontend/src/api/`. Son la fuente de verdad del contrato con el backend: si el
backend cambió, se regeneran en esta misma tarea.

### 2) Crear o ubicar la pantalla
Las pantallas son tres y son las del enunciado: `Login`, `MisAcciones` y `DetalleAccion`, en
`frontend/src/pages/`. Una cuarta no se agrega de costado: se discute con el `Solution-Designer`.

- Abrir el wireframe correspondiente **antes de escribir markup**.
- El chequeo de sesión y la redirección por 401 los resuelve `frontend/src/auth/`: no se repiten por
  pantalla.

### 3) Extraer los componentes que el wireframe dibuja
En `frontend/src/components/` van las piezas que más de una pantalla comparte o que el wireframe dibuja
como una unidad propia: `Header`, `Autocomplete`, `StockGrid`, `QuoteChart`, `Notice`.

Lo que existe sólo dentro de una pantalla se queda en su archivo de `frontend/src/pages/`: un componente
con un solo uso es una indirección, no una abstracción.

### 4) Conectar con el backend
- El cliente HTTP vive en `frontend/src/api/`, junto con los tipos generados. Nunca se llama al backend
  con una URL hardcodeada desde un componente.
- El estado de sesión y el interceptor de 401 viven en `frontend/src/auth/`.
- El autocomplete consulta **nuestro** endpoint de símbolos, que lee la tabla `stocks` ingestada
  (`ADR-002`): por eso no consume cuota. Pegarle al proveedor desde el frontend es Blocker.

### 5) Aplicar la paleta del wireframe

No hay design system, ni librería de componentes, ni framework de estilos (`docs/design/README.md`,
`ADR-008`): CSS plano y la paleta neutra tomada del propio mockup.

Las reglas completas son `CONVENTIONS.md` → `UI-*`. Lo que se usa todo el tiempo:

| Necesitás | Usás | Regla |
|---|---|---|
| Un color | un token de `frontend/src/styles/tokens.css` | `UI-03` |
| Un texto visible | el literal de `docs/design/COPY.md`, verbatim | `UI-02` |
| Una cotización, una fecha, un símbolo | mono tabular | `UI-04` |
| Avisar que el dato no es fresco | `<Notice>` **arriba** del dato que califica | `UI-05` |
| El layout de la pantalla | el wireframe, sin agregados | `UI-01` |

Si falta una señal —un estado que ningún token cubre— **no se improvisa en el componente**: se
agrega el token en `frontend/src/styles/tokens.css` y su significado en `docs/design/`, y eso lo decide
el `Frontend-Architect`.

---

### 6) Dibujar los cuatro estados de la cotización
La respuesta trae un `status` tipado y la UI lo muestra (`ADR-005`, `ERR-05`):

- `ok` — la serie, sin aviso.
- `stale` — la última serie conocida **más** el aviso arriba: primero se dice si se puede confiar
  en el dato, después se muestra.
- `market_closed` — no es un error y no se dibuja como tal.
- `no_data` — estado vacío, que tampoco es un error.

### 7) Manejar los estados de carga, error y vacío
Los tres están contemplados (`TS-06`), y el mensaje de error va **en español** y es el del
enunciado si el enunciado lo define.

### 8) Agregar tests
- Tests de componente para la lógica de UI no trivial.
- Test del flujo crítico de la pantalla.
- Ver `add_tests`.

### 9) Actualizar la navegación
Agregar el enlace donde el wireframe lo muestra, y en ningún otro lado. La autorización real está
en el endpoint del backend: ocultar un enlace no es un control de acceso (`GEN-09`).

## Validación
- Los componentes renderizan sin errores y la pantalla responde en su ruta.
- `npm test` pasa, con `frontend/tests/copy.test.ts` y `frontend/tests/tokens.test.ts` en verde (`UI-02`,
  `UI-03`).
- La pantalla se comparó contra su wireframe: mismo orden de elementos, mismas etiquetas, mismas
  columnas, mismos controles.
- Los textos visibles son los literales de `docs/design/COPY.md`, verbatim.
- Las cotizaciones, las fechas y los símbolos están en mono tabular.
- Los avisos de estado van arriba del dato que califican.
- `npm run build` compila sin errores de TypeScript.
- No hay tipos `any`.
- Los tipos de la API están regenerados y en uso.
- Los estados de carga, error y vacío están cubiertos, y los cuatro `status` se distinguen.

## Errores comunes (evitar)
- **Apartarse del wireframe para mejorarlo.** El enunciado dice que el diseño no se evalúa: una
  pantalla que se aparta del mockup es un hallazgo de review, no una mejora.
- Corregir los textos del enunciado —una tilde, una falta— en vez de copiarlos verbatim (`UI-02`).
- Poner lógica de negocio en los componentes: va en el backend, o en `frontend/src/api/` si es de
  presentación.
- Usar tipos `any` o escribir a mano tipos que genera el OpenAPI.
- Llamar al backend con una URL hardcodeada desde un componente, en vez de pasar por
  `frontend/src/api/`.
- Hacer que el autocomplete le pegue al proveedor: gasta la cuota que la demo va a necesitar
  (Artículo II, `ADR-002`).
- Escribir un color a mano "por esta vez": es exactamente lo que `frontend/tests/tokens.test.ts` frena.
- Poner el aviso al pie del número que califica. Va **arriba**.
- Dibujar `market_closed` o `no_data` como si fueran un error.

## Troubleshooting
- Los tipos no coinciden con la API → regenerar con `make types` (y verificar que el backend esté
  levantado).
- `copy.test.ts` falla → el texto no coincide con `docs/design/COPY.md`. Se corrige el componente,
  no el archivo de textos: `COPY.md` es la fuente.
- `tokens.test.ts` falla → hay un color escrito a mano; el test nombra archivo y línea.
- La pantalla queda accesible sin sesión → el gate va en `frontend/src/auth/` **y** en el endpoint del
  backend, nunca sólo en la UI.
