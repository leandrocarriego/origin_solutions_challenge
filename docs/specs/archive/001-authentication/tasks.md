# Autenticación y sesión — Tareas

<!--
  ARTEFACTO INTERNO. Cada tarea mapea a una skill de agents/skills/ y es lo bastante
  chica como para terminarse de una sentada. Si una tarea no tiene skill, o no
  corresponde al proyecto, o falta la skill: preguntá antes de inventarla.
-->

**Feature:** `001-authentication` · **Plan:** `plan.md`

**Tests aprobados por:** Leandro Carriego — **las tres historias** · **Fecha de aprobación:** 2026-09-13

| Historia | Tests | Firma | Fecha |
|---|---|---|---|
| H1 — Entrar a la aplicación | tareas 1 y 2 · 129 tests | ✍️ Leandro Carriego | 2026-09-13 |
| H2 — Seguir adentro y saber quién soy | tarea 8 · 37 tests | ✍️ Leandro Carriego | 2026-09-13 |
| H3 — Cerrar mi sesión | tarea 12 · 10 tests + la corrección de `copy.test.ts` | ✍️ Leandro Carriego | 2026-09-13 |

> **Qué habilita la firma de H1, y qué no.** Habilita las tareas 4 a 7 —el kernel, el módulo
> `auth`, el contrato tipado y la pantalla de ingreso—, y nada más.
>
> **Cuatro tests de H1 pasaban en verde al momento de la firma**, y se informó antes de
> registrarla: los dos de `tokens.test.ts` y el guard de la falta de ortografía de `copy.test.ts`,
> que son vacuos mientras `frontend/src/` no tenga componentes, y la auto-verificación del parser
> de `copy.test.ts`, que es verde legítimo. Los tres primeros empiezan a probar algo con la tarea 7.
>
> **Qué habilita la firma de H2.** Las tareas **10 y 11** —`GET /api/auth/me` protegida, y que la
> sesión sobreviva al F5 con su cabecera y el aviso de `RF-27`—. La **14 sigue bloqueada**: sus
> tests son la tarea 12 y no están escritos.
>
> **Dos de los 37 tests de H2 pasaban en verde al momento de la firma**, y también se informó
> antes: la auto-verificación del helper `fragmentsOf` de `copy.test.ts`, que es verde legítimo —
> existe para que un bug en el corte del placeholder no deje la fila de la cabecera pidiendo
> nada—, y `Login.test.tsx > …credential that does not work > does not say the server could not be
> reached`, que es **vacuo** mientras el texto de `RF-27` no exista en `frontend/src/`: empieza a
> probar algo con la tarea 11.
>
> **Qué habilita la firma de H3.** La tarea **14**, que es la última de construcción.
>
> **Uno de los 10 tests de H3 pasaba en verde al momento de la firma**, y se informó antes:
> `Header.test.tsx > the login screen, with nobody logged in > does not offer a way out of a
> session that was never opened`, **vacuo** mientras `Cerrar sesión` no exista en ninguna pantalla.
> Empieza a probar algo con la tarea 14.
>
> **Esta firma cubre además una corrección de `copy.test.ts`, que ya estaba firmado**, y es el
> Artículo VI funcionando como tiene que funcionar: la fila `Cierre de sesión` pasaba en verde
> porque el helper buscaba los literales en el **texto crudo** de `frontend/src/`, comentarios
> incluidos, y el docstring de `Header.tsx` mencionaba `Cerrar sesión` justamente para decir que
> todavía no se dibuja. La aserción se ponía verde con la oración que explicaba por qué lo que pedía
> no existía. `sourcesContaining()` ahora busca en el código: se midió antes de tocarlo que ninguna
> de las 11 filas firmadas se cae, y el endurecimiento tiene sus propios dos tests. Se corrigió y
> **se volvió a firmar** — no se dejó como deuda.
>
> **Un test firmado no se reescribe para que pase.** Si durante `/implement` alguno resulta
> equivocado, se corrige y **se vuelve a firmar** — no se ajusta al código que se acaba de escribir.

<!--
  Lo completa `/approve-tests`, nunca un agente por su cuenta (Artículo VI). Mientras diga "—",
  `/implement` no arranca: los tests de la historia todavía no son un contrato firmado.
-->

> **Esta feature no lleva migración, y es a propósito.** `users` y su modelo existen desde la fase
> 0 (`394dab64d255`), y el límite de intentos no persiste nada. El orden de `tasks.md` es
> *migración → tests → backend → frontend*: acá el primer escalón está vacío, no salteado
> (`plan.md` → *Datos*). Si alguien toca `auth/models.py`, esto dejó de ser verdad y falta una
> tarea.

> **Hay tres firmas, una por historia.** El gate del Artículo VI no es único al final: los tests de
> H1 se firman antes de implementar H1. Por eso `approve_tests` aparece tres veces, y por eso cada
> firma se anota con quién y cuándo en el encabezado de arriba.

## Orden

### H1 — Entrar a la aplicación *(prioridad más alta)*

Al terminar H1 el cliente puede abrir la aplicación, ingresar con un usuario de prueba y llegar a
`Mis Acciones`; con la clave equivocada ve `usuario o clave invalida`; y pasados diez intentos
fallidos ve `Demasiados intentos. Probá de nuevo en unos minutos.` Es entregable de verdad.

**La guarda de ruta se construye acá y no en H2, aunque `RF-09` sea de H2.** El corte por historia
agrupa valor para el cliente, no permisos: dejar `/` sin guarda hasta H2 abriría una ventana en la
que una pantalla interna se abre sin sesión, y no hay ninguna razón para tenerla — el contexto de
sesión ya existe en H1, porque el login tiene que guardar el token en algún lado para navegar. H2
no agrega la guarda: agrega que **sobreviva al F5** (`sessionStorage` + `/api/auth/me`) y que una
sesión vencida llegue al login con su aviso.

| # | Tarea | Skill | Rol | Cubre |
|---|-------|-------|-----|-------|
| 1 ✅ | **Tests de backend de H1, en rojo.** Unitarios del service (usuario inexistente y clave errónea indistinguibles, hash señuelo, usuario case-insensitive, clave case-sensitive) y del limitador (ventana deslizante, `retry_after`, reset, tope de claves); unitarios del token (firma, `alg: none` y otro algoritmo rechazados, secreto vacío o menor a 32 → `RuntimeError`); integración de `POST /api/auth/login` (200, 401 idéntico en los dos casos, 422, 429 con `Retry-After`, y que la respuesta no lleve la clave); que con el límite activo **no** se verifique la credencial; y que una `X-Forwarded-For` forjada no cambie la clave del contador. Suma `POST /api/auth/login` a `PUBLIC_ROUTES` con su motivo escrito. | `add_tests` | Tester | RF-03, RF-04, RF-06, RF-11, RF-14, RF-15, RF-21…RF-26 |
| 2 ✅ | **Tests de frontend de H1, en rojo.** Pantalla de ingreso contra el wireframe, clave enmascarada, el orden de los tres avisos (campo vacío → límite → credencial, nunca dos a la vez), que un campo vacío **no** llame a la API, y que el 401 y el 429 del login no disparen el interceptor de sesión. Que `/` abierta sin sesión caiga en `/login`, porque la guarda se construye en la tarea 7. Acá **nacen** `frontend/tests/copy.test.ts` (`UI-02`) y `frontend/tests/tokens.test.ts` (`UI-03`), que rompen el build y que hasta hoy no existían. | `add_tests` | Tester | RF-01, RF-02, RF-03, RF-04, RF-05, RF-09, RF-12, RF-13, RF-23 |
| 3 ✅ | 🚦 **Firma de los tests de H1.** Sin esto, la tarea 4 no arranca (Artículo VI). | `approve_tests` | Tester *(firma el humano)* | — |
| 4 ✅ | **Kernel.** `app/errors.py` (`DomainError`, `AuthenticationError`, `RateLimitedError` con `retry_after_seconds`), `app/ratelimit.py` (`SlidingWindowLimiter`, con tope de claves y evicción), `app/security.py` (`ACCESS_TOKEN_TTL`, `create_access_token` y el decode con `algorithms=["HS256"]` y claims requeridos), `app/settings.py` (`jwt_secret` + `secret_values()`), el contador `LOGIN_ATTEMPTS` en `app/observability.py`, y la variable nueva en `.env.example`, `docker-compose.yml`, `docker-compose.prod.yml` y el `env:` del CI. | `add_backend_feature` | Developer | RF-21, RF-22, RF-24 |
| 5 ✅ | **Módulo `auth`: el login.** `repository.py` (`find_by_username` con `func.lower`), `service.py` (`authenticate`, el orden límite → búsqueda → verificación → `hit`/`reset`, y los números de la política), `io.py` (`LoginRequest` con `extra="forbid"` y largos máximos, `LoginResponse`), `router.py` (`POST /api/auth/login` y el helper que lee la IP de `request.client.host` en un solo lugar), el `__all__ = ["router"]`, y en `main.py` el montaje del router más los dos handlers (`AuthenticationError` → 401, `RateLimitedError` → 429 con `Retry-After`). | `add_backend_feature` | Developer | RF-03, RF-04, RF-06, RF-11, RF-14, RF-15, RF-21…RF-26 |
| 6 ✅ | **El contrato tipado.** Instalar `openapi-typescript` con `npm install`, crear el target `make types` —que `TS-03` y `add_frontend_feature` ya nombran y que **todavía no existe**— y generar `frontend/src/api/schema.d.ts` desde el OpenAPI. | `add_frontend_feature` | Developer | — *(ver nota)* |
| 7 ✅ | **Ruteo, cliente HTTP y pantalla de ingreso.** Instalar `react-router`; `App.tsx` con `/login`, `/` y `/health` (`HealthPage` baja de la raíz, sin cambios por dentro); `api/client.ts` con el punto de enganche del 401; `api/auth.ts` con `login()`, que se saltea el interceptor; `pages/Login.tsx` contra `wireframes/01-login.png` y `COPY.md`; `pages/MyActions.tsx` mínima, con su título, para que el ingreso tenga a dónde llegar; y **`auth/RequireSession.tsx` ya protegiendo `/`** con la sesión en memoria que el login acaba de crear. | `add_frontend_feature` | Developer | RF-01, RF-02, RF-03, RF-04, RF-05, RF-09, RF-12, RF-13, RF-23 |

> **H1 está completa.** Las tareas 1 a 3 son sus tests y su firma; las 4 a 7, lo que las pone en
> verde.
>
> **4 y 5** (`Developer`, 2026-09-13). El kernel —`app/errors.py`, `app/ratelimit.py`, el
> token y `get_current_user` en `app/security.py`, `jwt_secret` en `settings.py`, `SessionDep` en
> `db.py`, `LOGIN_ATTEMPTS` en `observability.py`— y el módulo `auth` completo con
> `POST /api/auth/login` montado y sus dos handlers en `main.py`. `JWT_SECRET` entró a los cuatro
> archivos de infraestructura. Los 306 tests de backend pasan, cobertura 91,78 %; `ruff`, `mypy` y
> el chequeo de idioma de los comentarios, limpios.
>
> **6 y 7** (`Developer`, 2026-09-13). El target `make types` existe y genera
> `frontend/src/api/schema.d.ts` desde el OpenAPI importando `app.main` —sin base y sin secreto—;
> el ruteo vive en `main.tsx` alrededor de `<App />`; `api/client.ts` lleva la base `/api` y
> `setUnauthorizedHandler`; `api/auth.ts` tipa `login()` desde el schema generado y se saltea el
> interceptor; `auth/` tiene la sesión en memoria y `RequireSession`; `pages/Login.tsx` y
> `pages/MyActions.tsx` están contra sus wireframes, y `HealthPage` bajó a `/health` sin cambios
> por dentro. Los 42 tests de frontend pasan —los 18 de `Login.test.tsx`, los 2 de
> `session.test.tsx`, los 10 de `copy.test.ts`, los 2 de `tokens.test.ts` y los 10 de
> `HealthPage.test.tsx`—; `tsc`, `eslint` y `prettier`, limpios.
>
### H2 — Seguir adentro y saber quién soy

| # | Tarea | Skill | Rol | Cubre |
|---|-------|-------|-----|-------|
| 8 ✅ | **Tests de H2, en rojo.** Backend: `GET /api/auth/me` responde 200 con token válido y 401 sin token, con token alterado, mal formado o vencido —el vencido con un `exp` en el pasado, nunca esperando una hora—, y el `exp` emitido son 60 minutos; `TestRoutesEnforceAuthorization` deja de correr sobre una lista vacía. Frontend: el F5 sobrevive con la sesión puesta, un token vencido en el almacenamiento manda al login con su aviso, la cabecera muestra el nombre completo y no el usuario, y un intento que **no logra comunicarse** muestra `No pudimos conectarnos con el servidor. Intentá de nuevo en unos minutos.` y **no** `usuario o clave invalida` (`RF-27`). La guarda de ruta ya se testeó en la tarea 2: acá se testea que **persista**. | `add_tests` | Tester | RF-07, RF-08, RF-16, RF-17, RF-27 |
| 9 ✅ | 🚦 **Firma de los tests de H2.** | `approve_tests` | Tester *(firma el humano)* | — |
| 10 ✅ | **`GET /api/auth/me`, protegida.** `get_current_user` en `app/security.py` (`HTTPBearer(auto_error=False)`, 401 con `WWW-Authenticate` en los cuatro modos de falla) y la ruta en `auth/router.py`, que responde los claims y **no** consulta la base. | `add_backend_feature` | Developer | RF-07, RF-16 |
| 11 ✅ | **Que la sesión sobreviva, y la cabecera.** `auth/storage.ts` (`sessionStorage`), `auth/session.ts` + `SessionProvider.tsx` (con el estado `loading` para que el F5 no parpadee), la restauración contra `GET /api/auth/me`, el interceptor de 401 registrado desde `auth/`, `components/Header.tsx` con `Usuario: {nombre completo}`, y el aviso de `RF-27` en `Login.tsx` para el intento que no logra comunicarse —hoy ese caso cae en `usuario o clave invalida`, que culpa a la credencial de una falla que no es suya—. La guarda ya existe desde la tarea 7; acá deja de perderse al recargar. | `add_frontend_feature` | Developer | RF-07, RF-08, RF-17, RF-27 |

> **Hechas: 8 y 9.**
>
> **8** (`Tester`, 2026-09-13). 37 tests nuevos, 35 en rojo: `test_current_user.py` (16), la guarda
> que impide que `TestRoutesEnforceAuthorization` corra sobre una lista vacía (1),
> `session.test.tsx` (2 → 10), `Header.test.tsx` (3) y las filas de H2 de `Login.test.tsx`
> (18 → 23) y `copy.test.ts` (10 → 14). Backend **17 failed / 306 passed**, cobertura 91,78 %;
> frontend **18 failed / 44 passed**; `tsc`, `ruff`, `mypy` y `eslint` limpios. Las 16 fallas del
> backend son `404` —la ruta no existe— y la 17ª es la lista de rutas protegidas vacía: los dos
> rojos son por ausencia de implementación, no por un import roto.
>
> **9** — firmada por Leandro Carriego el 2026-09-13, registrada en el encabezado. Con eso quedan
> habilitadas la 10 y la 11.
>
> **Dos cosas que la firma deja dichas**, porque el Developer las va a encontrar: el `pytest-fast`
> del pre-commit corre `tests/architecture`, así que la guarda nueva lo deja rojo hasta que exista
> la ruta; y el matcher de `Usuario: Juan Perez` exige el texto en **un** elemento, así que partirlo
> en dos anidados lo hace fallar por forma y no por conducta.
>
> **El plan no fija las claves de `auth/storage.ts` ni la firma de `fetchMe()`**, y los tests no las
> inventaron: el F5 se simula ingresando por la pantalla y volviendo a montar la aplicación, que es
> un F5 de verdad porque la sesión vive en el `useState` del provider. La tarea 11 elige la forma.

> **Hechas: 10 y 11** — H2 completa.
>
> **10** (`Developer`, 2026-09-13). `CurrentUserResponse` en `auth/io.py` y `GET /api/auth/me` en
> `auth/router.py`, que declara `Depends(get_current_user)`, responde los claims y **no recibe
> ningún parámetro**: no hay id que pasar, así que no hay ninguno que sustituir (Artículo III).
> `get_current_user` no hubo que escribirlo —entró completo con la tarea 4—, así que la tarea
> resultó ser sólo la ruta. **323 tests pasan**, cobertura 91,86 %, y `TestRoutesEnforceAuthorization`
> dejó de correr sobre una lista vacía. Después, `make types` regeneró `schema.d.ts` con `/me`.
>
> **11** (`Developer`, 2026-09-13). `auth/storage.ts` (una sola clave, `origin-acciones.session`,
> con los tres campos en un JSON y toda lectura envuelta), el estado `loading` resuelto **en la
> primera render** —`useState(startupFromStorage)`, no en un efecto, así no hay un frame de
> `anonymous` antes de que `/me` conteste—, la restauración contra `GET /api/auth/me`, el
> interceptor de 401 registrado desde `auth/`, `components/Header.tsx` con `Usuario: {nombre
> completo}` y el cuarto aviso de `Login.tsx` para `RF-27`. **Los 62 tests del frontend pasan**;
> `tsc`, `eslint`, `prettier` y el build, limpios. Ningún test fue tocado.
>
> **Los cuatro avisos del login son excluyentes por estructura, no por una cadena de `if`**: el
> campo vacío corta antes de llamar a la API, y los otros tres son **un solo** estado que sale de
> `refusalFor(error)`. No hay forma de mostrar dos.
>
> **Un hallazgo que no es de esta tarea**, y queda acá para que no se pierda: un **5xx** del login
> cae hoy en `usuario o clave invalida`, porque el servidor contestó. Es lo que fijan los tests
> firmados y lo que permite `COPY.md`, que cierra la lista en cuatro avisos — pero un 500 no es
> culpa de la credencial. Un quinto texto es alcance del `Solution-Designer`, no del `Developer`.

> **Sigue bloqueada la 14**: sus tests son la tarea 12 y no están escritos, así que todavía no hay
> `Cerrar sesión`.

### H3 — Cerrar mi sesión

| # | Tarea | Skill | Rol | Cubre |
|---|-------|-------|-----|-------|
| 12 ✅ | **Tests de H3, en rojo.** `Cerrar sesión` está en la cabecera; al activarlo aparece el login; y volver a `/` ya no muestra la pantalla interna. Es frontend solo: sin revocación en el servidor, cerrar sesión es del cliente (`ADR-004`). | `add_tests` | Tester | RF-18, RF-19, RF-20 |
| 13 ✅ | 🚦 **Firma de los tests de H3.** | `approve_tests` | Tester *(firma el humano)* | — |
| 14 ✅ | **La salida.** `Cerrar sesión` en `components/Header.tsx` y `logOut()` limpiando memoria y `sessionStorage` y navegando a `/login`. | `add_frontend_feature` | Developer | RF-18, RF-19, RF-20 |

> **Hechas: 12 y 13.**
>
> **12** (`Tester`, 2026-09-13). 10 tests nuevos: `Header.test.tsx` suma 4 —`Cerrar sesión` presente
> y verbatim, dentro del `<header>` junto al nombre, activable y no una etiqueta, y el negativo en
> la pantalla de ingreso— y `session.test.tsx` suma 5 —aparece el login, **no** dice que la sesión
> venció, no le pide nada al servidor (`ADR-004`), volver a `/` no muestra la grilla, y el
> remontaje no encuentra nada guardado que restaurar—. `copy.test.ts` suma la fila `Cierre de
> sesión`. Frontend **9 failed / 65 passed (74)**; `tsc`, `eslint` y `prettier` limpios; backend
> 323 passed sin cambios. Las 9 fallas son `the header offers no button or link named "Cerrar
> sesión"`: ausencia de implementación.
>
> **13** — firmada por Leandro Carriego el 2026-09-13, registrada en el encabezado. Habilita la 14.
>
> **`RF-18` en el Detalle de Acción no se puede testear todavía**, porque el Detalle es `003` y no
> existe. Lo que lo va a hacer cierto es que las dos pantallas dibujan el mismo `Header` — que es
> por qué su título es una prop y no un literal.
>
> **El plan no fija si `Cerrar sesión` es un `<button>` o un `<a>`**: la spec lo llama "el enlace"
> en prosa cara al cliente y `COPY.md` fija el texto y el lugar. Los tests aceptan cualquiera de
> los dos. Lo que **no** aceptan es un `<span onClick>`, que queda inalcanzable por teclado y se
> anuncia como texto plano.

> **Hecha: 14** (`Developer`, 2026-09-13). `logOut()` en `auth/session.ts` y `SessionProvider.tsx`
> —olvida lo que el navegador guardó, lo que el provider sostiene y la dirección en pantalla— y
> `Cerrar sesión` en `components/Header.tsx`, al lado del nombre, como un `<button>` dibujado como
> el enlace del wireframe. **Los 74 tests del frontend pasan**; `tsc`, `eslint`, `prettier` y el
> build limpios; backend 323 passed sin cambios. Ningún test fue tocado.
>
> **`logOut()` es sincrónico y no le pide nada al servidor**, y las dos cosas son la misma decisión
> (`ADR-004`): no hay revocación, así que una salida que pudiera fallar sería una salida capaz de
> dejar a alguien adentro de la sesión de otro. Y pone `expired` en `false`: se cerró a propósito,
> nada venció, y el login no debe decir que la sesión se terminó.

### Cierre de la feature

| # | Tarea | Skill | Rol | Cubre |
|---|-------|-------|-----|-------|
| 15 ✅ | **`ARCHITECTURE.md` y `AGENTS.md` al día**: el árbol del kernel suma `errors.py` y `ratelimit.py`, y el inventario de contratos suma el `__all__` de `auth`. Los dos documentos listan hoy lo transversal como `db.py · errors.py · security.py`, así que los dos quedan viejos con el mismo cambio y se corrigen juntos. | `add_backend_feature` | Backend-Architect | — *(ver nota)* |

> **Hecha: 15** (`Backend-Architect`, 2026-09-13). `ARCHITECTURE.md` suma `ratelimit.py` al árbol
> del kernel —con lo que el limitador es y lo que deliberadamente no sabe— y `SessionDep` al renglón
> de `db.py`; el frontend suma el almacenamiento de la sesión al renglón de `auth/`. `AGENTS.md`
> suma `ratelimit.py` a *Dónde va el código*.
>
> Y el inventario de contratos suma `auth/__init__.py → __all__ = ["router"]`, que es el módulo del
> que **nadie lee**: queda escrito por qué `get_current_user` vive en `app/security.py` y no adentro
> de `auth`, porque es la pregunta que alguien va a volver a hacer.

### Las dos tareas que no cubren ningún `RF`, y por qué no es alcance de más

Las tareas **6** y **15** tienen la columna *Cubre* vacía, y eso normalmente es la señal de alcance
que el cliente no firmó. Acá no lo es, y conviene dejarlo escrito antes de que `/converge` lo
encuentre y lo lea como deriva:

- **La 6 es mecanismo, no funcionalidad.** No agrega nada que el usuario pueda ver: hace que los
  tipos del frontend salgan del OpenAPI en vez de escribirse a mano, que es lo que `TS-03` exige.
  Se paga en esta feature porque es la primera que consume un endpoint de dominio.
- **La 15 es documentación.** `ARCHITECTURE.md` y `AGENTS.md` describen un backend donde
  `ratelimit.py` no existe; si no se corrigen, el próximo que lea la arquitectura la va a leer mal.

Lo mismo vale para los cuatro puntos de endurecimiento OWASP del plan —dos ya aplicados, dos que
entran con la implementación—: ninguno cambia lo que el cliente ve, responden a `NFR-01`…`NFR-03` y
a `SEC-07`, y el `plan.md` ya lo declara en esos términos. **Si alguna de estas tareas terminara
cambiando una pantalla o un mensaje, deja de ser mecanismo y vuelve a la spec.**

<!--
  La columna Test de la tabla de trazabilidad de docs/PROJECT_BRIEF.md (REQ-01…REQ-04, NFR-01) NO
  es una tarea de acá: la completa `ship_changes` en el mismo commit que archiva la spec, que es
  lo que evita que la tabla quede vieja (docs/specs/README.md → Al entregar).
-->

## Cobertura de requisitos

<!--
  Todo requisito funcional de la spec tiene al menos una tarea que lo construye y
  al menos un test que lo verifica. Un RF sin fila acá es alcance firmado que nadie
  se comprometió a hacer — y es exactamente lo que /converge va a encontrar.
-->

Los nombres de archivo de la columna **Test** son la propuesta de este desglose; el `Tester` puede
reagruparlos, pero **ninguna fila puede quedar vacía**.

| Requisito | Tareas | Test |
|-----------|--------|------|
| RF-01 | 2, 7 | `frontend/tests/Login.test.tsx` · `frontend/tests/copy.test.ts` |
| RF-02 | 2, 7 | `frontend/tests/Login.test.tsx` |
| RF-03 | 1, 2, 5, 7 | `backend/tests/integration/test_login.py` · `frontend/tests/Login.test.tsx` |
| RF-04 | 1, 2, 5, 7 | `backend/tests/integration/test_login.py` · `frontend/tests/copy.test.ts` |
| RF-05 | 2, 7 | `frontend/tests/Login.test.tsx` |
| RF-06 | 1, 5 | `backend/tests/unit/test_auth_service.py` · `backend/tests/integration/test_login.py` |
| RF-07 | 8, 10, 11 | `backend/tests/integration/test_current_user.py` · `frontend/tests/session.test.tsx` |
| RF-08 | 8, 11 | `frontend/tests/Header.test.tsx` · `frontend/tests/copy.test.ts` |
| RF-09 | 2, 7, 11 | `frontend/tests/session.test.tsx` |
| RF-10 | 1, 5 | `backend/tests/integration/test_password_hashing.py` · `backend/tests/unit/test_auth_service.py` |
| RF-11 | 1, 5 | `backend/tests/integration/test_login.py` |
| RF-12 | 2, 7 | `frontend/tests/Login.test.tsx` · `frontend/tests/copy.test.ts` |
| RF-13 | 2, 7 | `frontend/tests/Login.test.tsx` |
| RF-14 | 1, 5 | `backend/tests/unit/test_auth_service.py` |
| RF-15 | 1, 5 | `backend/tests/unit/test_auth_service.py` |
| RF-16 | 4, 8, 10 | `backend/tests/unit/test_access_token.py` |
| RF-17 | 8, 11 | `frontend/tests/session.test.tsx` · `frontend/tests/copy.test.ts` |
| RF-18 | 12, 14 | `frontend/tests/Header.test.tsx` · `frontend/tests/copy.test.ts` |
| RF-19 | 12, 14 | `frontend/tests/session.test.tsx` |
| RF-20 | 12, 14 | `frontend/tests/session.test.tsx` |
| RF-21 | 1, 4, 5 | `backend/tests/integration/test_login_rate_limit.py` · `backend/tests/unit/test_rate_limiter.py` |
| RF-22 | 1, 4, 5 | `backend/tests/integration/test_login_rate_limit.py` · `backend/tests/unit/test_rate_limiter.py` |
| RF-23 | 1, 2, 5, 7 | `backend/tests/integration/test_login_rate_limit.py` · `frontend/tests/copy.test.ts` |
| RF-24 | 1, 4, 5 | `backend/tests/integration/test_login_rate_limit.py` |
| RF-25 | 1, 5 | `backend/tests/integration/test_login_rate_limit.py` |
| RF-26 | 1, 5 | `backend/tests/integration/test_login_rate_limit.py` |
| RF-27 | 8, 11 | `frontend/tests/Login.test.tsx` · `frontend/tests/copy.test.ts` |

**Ninguna fila quedó sin tarea.** La que estuvo a punto de quedar es `RF-10`, y vale explicar por
qué finalmente tiene dos: el **almacenamiento** hasheado con Argon2id ya es de la fase 0, y su test
—`test_password_hashing.py`— existe y pasa; nadie lo vuelve a construir. Pero `RF-10` dice que la
clave no se pueda leer ni recuperar, y esta feature escribe el **único código del proyecto que
manipula material de clave**: si `auth/service.py` comparara en texto plano, la guardara en una
variable que termina en un log, o la re-hasheara con otra cosa, `RF-10` se rompería sin que la
tabla `users` cambiara. Por eso lo cubren la tarea 5 —que sólo puede comparar con
`verify_password`, y no puede loguear la clave ni su largo— y la tarea 1, que lo fija con un test.

Es la diferencia entre *construir* un requisito y *sostenerlo*: el segundo también es trabajo, y
también se rompe.
