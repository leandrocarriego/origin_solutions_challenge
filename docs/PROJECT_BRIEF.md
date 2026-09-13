# Alcance — ORIGIN Acciones

Este el documento que se lee antes de definir o planificar cualquier feature.

## Qué pide el cliente

Una interfaz web para graficar la cotización de una acción en tiempo real.

Tres pantallas: login, "Mis Acciones" (favoritas por usuario) y el detalle de una acción con su gráfico.

## La rúbrica

> **funcionalidad y la estabilidad** de la solución, el **modelo de datos**, la **atención a los requerimientos**, **seguridad**, **estructura del código** y la **actitud frente a los NFR:** (mantenibilidad, extensibilidad, escalabilidad).

## Stack

| Punta | Elección |
|---|---|
| API | Python 3.13 · FastAPI · SQLAlchemy 2.x · Alembic · Pydantic v2 |
| Frontend | React 19 · TypeScript · Vite |
| Base de datos | PostgreSQL 16 |
| Gráfico | Highcharts |
| Arquitectura | `frontend/` y `backend/` |

Datos: `api.twelvedata.com`, plan gratuito, **800 requests por día**.

---

## 1. Requisitos funcionales

Cada requisito es atómico y verificable.

La columna **Test** se completa a medida que se implementa (`AGENTS.md` → Definition of Done).

### Login

| ID | Requisito | Test |
|---|---|---|
| REQ-01 | Página de login con campos Usuario y Clave, y botón Ingresar | |
| REQ-02 | Credenciales inválidas muestran el mensaje literal `usuario o clave invalida` | |
| REQ-03 | Login exitoso redirige a la página "Mis Acciones" | |

### Mis Acciones

| ID | Requisito | Test |
|---|---|---|
| REQ-04 | La cabecera muestra el nombre del usuario logueado (`Usuario: Juan`) | |
| REQ-05 | Un autocomplete sugiere acciones que coinciden con el texto buscado | |
| REQ-06 | "Agregar Símbolo" añade la acción seleccionada a las favoritas del usuario | |
| REQ-07 | La grilla se refresca luego de agregar | |
| REQ-08 | De cada acción se persiste símbolo, nombre y moneda | |
| REQ-09 | Cada fila tiene un link "Eliminar" que borra la favorita del usuario | |
| REQ-10 | La grilla se refresca luego de eliminar | |
| REQ-11 | El símbolo es un link que navega al Detalle de Acción | |

### Detalle de Acción

| ID | Requisito | Test |
|---|---|---|
| REQ-12 | La cabecera muestra los datos de la acción (`TSLA - Tesla Inc - USD`) | |
| REQ-13 | Modo **Tiempo Real**: grafica la cotización con la fecha del día | |
| REQ-14 | En Tiempo Real el gráfico se auto-actualiza según el intervalo elegido, sin recargar la página | |
| REQ-15 | Modo **Histórico**: grafica entre fecha/hora desde y fecha/hora hasta | |
| REQ-16 | Selector de **Intervalo** con valores `1min`, `5min`, `15min` | |
| REQ-17 | El gráfico usa Highcharts (o similar), eje X = intervalo, eje Y = cotización | |

### Entregables

| ID | Requisito | Test |
|---|---|---|
| REQ-18 | Base de datos relacional con todos los objetos necesarios | |
| REQ-19 | Seed con datos mínimos para poder probar la aplicación | |
| REQ-20 | Repositorio público con control de versiones | |
| REQ-21 | Backup de la base de datos incluido en el repo | |
| REQ-22 | `README.md` con los pasos para levantar la aplicación | |
| REQ-23 | Arquitectura de dos proyectos: Frontend y Backend | |
| REQ-24 | API en Python + FastAPI | |
| REQ-25 | Frontend en React ≥ 18 | |

## 2. Requisitos no funcionales

Se prioriza: seguridad, mantenibilidad, extensibilidad y escalabilidad.

Cada uno tiene su artículo en la constitución y su convención verificable.

| ID | Requisito | Autoridad | Verificación |
|---|---|---|---|
| NFR-01 | Passwords almacenadas con Argon2, nunca en texto plano | `SEC-06` | |
| NFR-02 | La API key de TwelveData no es alcanzable desde el navegador | Art. I · `SEC-02` | |
| NFR-03 | Un usuario no puede leer ni borrar las favoritas de otro | Art. III · `GEN-09` | |
| NFR-04 | Cuota agotada, símbolo sin datos y mercado cerrado tienen manejo explícito | `ERR-05` | |
| NFR-05 | El consumo de la API externa no crece con la cantidad de clientes conectados | Art. II · `ADR-003` | |
| NFR-06 | Capas separadas y verificadas por test; la suite corre sin red | Art. IV · `PY-06`, `TEST-03` | |
| NFR-07 | El proveedor de datos es reemplazable sin tocar services ni routers | Art. IV · `GEN-08` | |

---

## 3. Ambigüedades declaradas (Artículo VII)

El enunciado deja puntos abiertos. Se resuelven acá, con su alternativa descartada, en vez de
silenciosamente en el código.

**A1 — No se pide registro de usuarios.**
El enunciado describe login pero nunca alta.
*Resolución:* los usuarios se crean por seed (REQ-19). No se implementa registro: sería alcance no
pedido. Las passwords igual se hashean con Argon2 (NFR-01).
*Descartado:* un endpoint de registro "porque queda mejor". Es alcance que nadie acordó.

**A2 — "Tiempo real" contra un plan gratuito que no tiene streaming.**
TwelveData free no ofrece WebSocket.
*Resolución:* se interpreta como el propio enunciado lo define — *"graficar la cotización en base a
la fecha del día"* con refresco automático según el intervalo. Es polling, y el enunciado lo dice
así. El polling es del frontend **contra nuestra API**, no contra TwelveData (`ADR-003`).
*Descartado:* WebSocket propio sobre un upstream que no lo provee. Sería una capa de complejidad
sin dato nuevo detrás.

**A3 — Origen de los datos del autocomplete.**
El enunciado sugiere consultar `/stocks?exchange=NYSE` en vivo.
*Resolución:* ese listado se ingesta una vez a una tabla local y el autocomplete consulta la base
(`ADR-002`). Proxear cada tecla tipeada agotaría los 800 requests diarios en minutos.
*Descartado:* proxy directo con debounce. Baja el consumo pero no lo acota: sigue creciendo con los
usuarios, y viola el Artículo II.

**A4 — El enunciado se contradice con su propio wireframe en el exchange.**
Sugiere `exchange=NYSE` para llenar el autocomplete, pero los tres símbolos de la grilla de ejemplo
—TSLA, AAPL, NFLX— cotizan en **NASDAQ**. Siguiendo el enunciado al pie no se puede reproducir su
propia pantalla.
*Resolución:* se ingestan NYSE **y** NASDAQ. Cubre las dos lecturas y hace la demo reproducible.
*Descartado:* seguir sólo NYSE. Es literal pero deja el wireframe sin poder armarse.

**A5 — Qué mostrar fuera del horario de mercado.**
Un gráfico vacío un domingo parece un bug.
*Resolución:* si el día actual no tiene datos, se grafica la última rueda disponible con un aviso
explícito arriba del gráfico (`ADR-005`, `UI-05`).
*Descartado:* gráfico vacío con un texto al pie. Es correcto y se lee como que la app no anda.

**A6 — Rango por defecto en modo Histórico.**
No está especificado.
*Resolución:* últimas 24 hs de mercado. Se valida que `desde < hasta` y que el rango sea coherente
con el intervalo elegido.

**A7 — Qué se muestra en la cabecera del detalle.**
El enunciado dice "los datos de la acción"; el wireframe muestra `TSLA - Tesla Inc - USD`.
*Resolución:* gana el wireframe — símbolo, nombre y moneda, que son además los tres campos que
REQ-08 obliga a persistir.

---

## 4. Fuera de alcance

Declarado para que no se lea como omisión:

- Registro de usuarios y recuperación de password (ver A1).
- Roles y permisos: hay un solo tipo de usuario.
- Paginación de la grilla: el volumen por usuario no lo justifica.
- i18n: la aplicación es en español.
- Responsive avanzado y trabajo de diseño: el enunciado descarta explícitamente evaluar UI, y los
  wireframes son la especificación (`docs/design/`).
- Despliegue a producción: el entregable es el repositorio y `docker compose up`.
