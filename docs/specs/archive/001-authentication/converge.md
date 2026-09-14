# Autenticación y sesión — Informe de convergencia

<!--
  ARTEFACTO DEL LEAD. Lo escribe `/converge` (`agents/skills/converge.md`) y no lo toca nadie más.
  No es un review de calidad: eso es `/review-feature`. Acá se compara el código contra lo que el
  cliente firmó.
-->

**Feature:** `001-authentication` · **Fecha:** 2026-09-13 · **Rol:** `Lead`

**Changeset:** el working tree de `feat/001-authentication`. La rama todavía no tiene commits sobre
`main` (`git diff main...HEAD --name-only` sale vacío), así que el changeset se armó con
`git status` y se completó con las búsquedas del paso 3 de la skill.

**Estado de la suite al correr este informe:** backend **323 passed**, cobertura **91,86 %**;
frontend **74 passed** (6 archivos). Las dos en verde, sin red y sin API key.

---

## Veredicto: **Deriva menor**

El código y la spec **describen el mismo producto**. Los 27 requisitos firmados tienen
implementación con evidencia localizable, no hay ninguna capacidad de negocio que ningún requisito
pida, y las quince tareas marcadas `[x]` están respaldadas por el archivo que nombran.

Lo que quedó desactualizado son **artefactos, no código**: `plan.md` no incorporó nunca `RF-27` —que
entró por la segunda enmienda de la spec, después de que el plan se escribiera—, describe el contrato
de `useSession()` con un miembro menos del que el código expone, y afirma dos cosas sobre el límite
de intentos y sobre el secreto de firma que el código resolvió de otra manera. Y `spec.md` se
contradice a sí misma en una línea sobre la firma del quinto aviso.

**No bloquea el gate.** La feature pasa al `Code-Reviewer`. Los cinco hallazgos se corrigen en su
artefacto de origen, con su rol dueño; ninguno pide cambiar comportamiento.

> **Las tres decisiones que necesitaban al humano se tomaron el 2026-09-13** (Leandro Carriego), y
> están registradas en su hallazgo: se acepta el default de desarrollo de `JWT_SECRET` (4), las tres
> aceptaciones de ADR son suyas y nada se revierte (5), y el comportamiento del límite de intentos
> es el que el código tiene, así que la spec no se reabre (3). Lo que queda de los cinco es edición
> de artefactos: `plan.md` en cuatro puntos, dos comentarios de código y una línea de `spec.md`.

---

## Tabla de trazabilidad

| Requisito | Qué promete la spec | Dónde está implementado | Evidencia | Estado |
|---|---|---|---|---|
| RF-01 | Pantalla de ingreso con `Usuario`, `Clave` e `Ingresar` | `frontend/src/pages/Login.tsx` | Los tres literales y el placeholder `Ingresar nombre de usuario`, sin título ni logo agregados (`UI-01`) · `frontend/tests/Login.test.tsx` · `copy.test.ts` | Implementado |
| RF-02 | La clave se escribe enmascarada | `frontend/src/pages/Login.tsx::Field` | `type="password"` en el campo `password` · `Login.test.tsx` | Implementado |
| RF-03 | Credenciales válidas llevan a `Mis Acciones` | `pages/Login.tsx::attempt` + `App.tsx` | `logIn()` y después `navigate('/', { replace: true })`; `/` es `MyActions` · `backend/tests/integration/test_login.py` · `Login.test.tsx` | Implementado |
| RF-04 | Credenciales inválidas muestran `usuario o clave invalida` | `pages/Login.tsx::REFUSAL_TEXT['bad-credential']` | El literal sin tilde, verbatim de `COPY.md`; sale del 401 vía `refusalFor()` · `copy.test.ts` | Implementado |
| RF-05 | El visitante queda en la pantalla de ingreso | `pages/Login.tsx::attempt` | Sólo se navega después de que `logIn` resuelve; el `catch` no navega · `Login.test.tsx` | Implementado |
| RF-06 | Usuario inexistente da el mismo mensaje que clave incorrecta | `backend/app/modules/auth/service.py::authenticate` · `app/errors.py::AuthenticationError` | Una sola excepción para los dos casos, y el hash señuelo `_ABSENT_USER_HASH` para que el tiempo tampoco distinga · `test_login.py::test_an_unknown_user_answers_exactly_like_a_wrong_password` | Implementado |
| RF-07 | Se reconoce al usuario en cada pantalla, sin volver a pedir credenciales | `auth/SessionProvider.tsx` + `api/auth.ts::fetchMe` + `modules/auth/router.py::read_current_user` | El arranque lee `sessionStorage` y confirma contra `GET /api/auth/me`, que responde los claims sin consultar la base · `test_current_user.py` · `session.test.tsx` | Implementado |
| RF-08 | `Usuario: {nombre completo}` en la cabecera | `frontend/src/components/Header.tsx` | `Usuario: {user.fullName}`, alimentado por el `full_name` del login y confirmado por `/me` · `Header.test.tsx` · `copy.test.ts` | Implementado |
| RF-09 | Una pantalla interna sin sesión lleva al ingreso | `frontend/src/auth/RequireSession.tsx` | `<Navigate to="/login" replace />`, y decide **antes** de renderizar · `session.test.tsx` | Implementado |
| RF-10 | Las claves no se pueden leer ni recuperar | `app/security.py::hash_password` / `verify_password` · columna `password_hash` (fase 0) | Argon2id, y `auth/service.py` sólo compara con `verify_password` — nunca en texto plano, y no loguea la clave ni su largo · `test_password_hashing.py` · `test_auth_service.py` | Implementado |
| RF-11 | El sistema nunca devuelve la clave | `modules/auth/io.py::LoginResponse` · `CurrentUserResponse` | Cuatro campos y dos campos; ninguno es la clave ni el hash · `test_login.py` (cuatro tests, incluido el de los logs) | Implementado |
| RF-12 | `Completá este campo.` debajo de cada campo vacío | `pages/Login.tsx::Field` | El aviso se dibuja dentro del `Field`, por campo, con `aria-describedby` · `Login.test.tsx` · `copy.test.ts` | Implementado |
| RF-13 | Con un campo vacío no se validan las credenciales | `pages/Login.tsx::attempt` | `if (empty.username \|\| empty.password) return;` antes de `logIn` · `Login.test.tsx` (el test afirma que no se llamó a la API) | Implementado |
| RF-14 | El usuario se reconoce sin distinguir mayúsculas | `modules/auth/service.py::authenticate` + `repository.py::find_by_username` | `username.lower()` y `func.lower(User.username) == username` · `test_auth_service.py` · `test_login.py::test_the_username_is_matched_whatever_the_case` | Implementado |
| RF-15 | La clave distingue mayúsculas | `modules/auth/service.py::authenticate` | La clave viaja sin normalizar a `verify_password` · `test_login.py::test_the_password_is_case_sensitive` | Implementado |
| RF-16 | 60 minutos dentro de la aplicación | `app/security.py::ACCESS_TOKEN_TTL` | `timedelta(minutes=60)`, y `exp` y `expires_in` los dos derivados de ella · `test_access_token.py` | Implementado |
| RF-17 | La sesión vencida lleva al ingreso con `Tu sesión expiró. Volvé a ingresar.` | `auth/SessionProvider.tsx` (interceptor + `startupFromStorage`) · `pages/Login.tsx::SESSION_EXPIRED` | El 401 de una llamada con sesión marca `expired` y navega a `/login`; un `expiresAt` ya pasado no gasta un round trip · `session.test.tsx` · `copy.test.ts` | Implementado |
| RF-18 | `Cerrar sesión` en la cabecera | `components/Header.tsx` | Un `<button>` al lado del nombre, condicionado a que haya usuario · `Header.test.tsx` · `copy.test.ts` | Implementado |
| RF-19 | `Cerrar sesión` termina la sesión | `auth/SessionProvider.tsx::logOut` | Limpia `sessionStorage`, el estado del provider y `expired` · `session.test.tsx` (volver a `/` ya no muestra la pantalla interna) | Implementado |
| RF-20 | `Cerrar sesión` lleva al ingreso | `auth/SessionProvider.tsx::logOut` | `navigate('/login', { replace: true })` · `session.test.tsx` | Implementado |
| RF-21 | 10 fallos en 5 minutos por dirección de red → rechazo | `app/ratelimit.py::SlidingWindowLimiter` + `modules/auth/service.py` (clave `login:ip:<addr>`) | `LOGIN_MAX_ATTEMPTS = 10`, `LOGIN_WINDOW = 5 min`; la IP la lee `router.py::_client_address` de `request.client.host` · `test_login_rate_limit.py` (incluidos los dos de `X-Forwarded-For` forjada) · `test_rate_limiter.py` | Implementado |
| RF-22 | 10 fallos en 5 minutos por nombre de usuario → rechazo | `modules/auth/service.py` (clave `login:user:<typed>`) | Se cuenta el nombre **tipeado**, exista o no · `test_login_rate_limit.py::test_the_eleventh_attempt_for_that_user_is_refused` | Implementado |
| RF-23 | `Demasiados intentos. Probá de nuevo en unos minutos.` | `app/main.py::too_many_attempts` (429) → `pages/Login.tsx::REFUSAL_TEXT['too-many-attempts']` | `refusalFor()` mapea el 429 a ese texto, verbatim de `COPY.md` · `test_login_rate_limit.py` · `copy.test.ts` | Implementado |
| RF-24 | Con el límite activo no se validan las credenciales | `modules/auth/service.py::authenticate` | `is_exceeded()` sobre las dos claves va **antes** de `find_by_username` y de `verify_password`, y corta con `raise` · `test_login_rate_limit.py::test_the_password_is_not_even_verified` y `test_the_right_password_does_not_get_in_either` | Implementado |
| RF-25 | Un ingreso válido reinicia el conteo del usuario | `modules/auth/service.py::authenticate` | `reset()` sobre las dos claves al verificar · `test_login_rate_limit.py::test_nine_failures_for_a_user_then_a_success_and_nine_more` | Implementado |
| RF-26 | Un ingreso válido reinicia el conteo de la dirección de red | `modules/auth/service.py::authenticate` | La misma llamada a `reset()`, sobre `login:ip:<addr>` · `test_login_rate_limit.py::test_nine_failures_from_an_address_then_a_success_and_nine_more` | Implementado |
| RF-27 | Si no se logra comunicar, `No pudimos conectarnos con el servidor. Intentá de nuevo en unos minutos.` en lugar de `usuario o clave invalida` | `pages/Login.tsx::refusalFor` + `REFUSAL_TEXT['unreachable']` | Sin `ApiError` no hubo respuesta que leer, así que el aviso es el de no haber podido conectarse · `Login.test.tsx` · `copy.test.ts` | Implementado |

Ninguna fila quedó `Parcial` ni `Ausente`.

**Dos alcances que la spec limita a propósito, y el código respeta.** `RF-08` y `RF-18` hablan de
"las pantallas internas": hoy existe una sola (`MyActions`), porque el Detalle de Acción es `003`. Y
`MyActions` es **sólo la cabecera** — sin grilla, sin autocomplete y sin alta—, que es exactamente
lo que `spec.md` → *Fuera de alcance* reserva para `002`.

---

## Alcance no pedido: ninguno

Se recorrió el inventario del código en sentido inverso.

| Lo que el código tiene | Qué lo pide |
|---|---|
| `POST /api/auth/login` | RF-03 a RF-06, RF-14, RF-15, RF-21 a RF-26 |
| `GET /api/auth/me` | RF-07, y `plan.md` → *Enfoque* (es lo que el F5 consulta) |
| `GET /api/health` · `GET /metrics` · `/health` en el frontend | Fase 0, ya en `main`. No los toca esta feature |
| `app/errors.py` · `app/ratelimit.py` · lo nuevo de `app/security.py` y `app/db.py::SessionDep` | Andamiaje que `plan.md` justifica pieza por pieza |
| `LOGIN_ATTEMPTS` en `app/observability.py` | `plan.md` → *Observabilidad* (OWASP A09, `ERR-03`) |
| `auth/__init__.py` → `__all__ = ["router"]` | `plan.md` → *Contrato entre módulos*. Es lo único que se exporta |
| `pages/MyActions.tsx` · `components/Header.tsx` · `auth/` · `api/client.ts` · `api/auth.ts` | RF-03, RF-07 a RF-09, RF-17 a RF-20 |
| `api/schema.d.ts` · el target `make types` | `TS-03`, y la tarea 6 lo declara como mecanismo sin `RF` |

No hay registro de usuarios, ni "recordarme", ni refresh token, ni recuperación de clave: los cuatro
están en *Fuera de alcance* y ninguno aparece en el código (`grep -rniE
"register|signup|refresh_token|remember"` sobre `backend/app` y `frontend/src`, limpio). Ninguna
tabla nueva y ninguna migración nueva, como el plan declara.

---

## Tareas declaradas completas: las quince, respaldadas

| Tarea | Lo que promete | Verificado en |
|---|---|---|
| 1, 2, 8, 12 (tests) | Las suites de cada historia | `test_auth_service.py`, `test_rate_limiter.py`, `test_access_token.py`, `test_login.py`, `test_login_rate_limit.py`, `test_current_user.py`, `Login.test.tsx`, `session.test.tsx`, `Header.test.tsx`, `copy.test.ts`, `tokens.test.ts` — todos existen y corren |
| 3, 9, 13 (firmas) | Quién y cuándo | Registradas en el encabezado de `tasks.md`, con nombre y fecha por historia |
| 4 (kernel) | `errors.py`, `ratelimit.py`, `security.py`, `settings.py`, `LOGIN_ATTEMPTS`, y la variable en cuatro archivos de infraestructura | Los tres archivos existen con las firmas del plan; `jwt_secret` está en `settings.py:26` y en `secret_values()`; `LOGIN_ATTEMPTS` en `observability.py:85` y en su `__all__`; `JWT_SECRET` en `.env.example`, `docker-compose.yml`, `docker-compose.prod.yml` y `ci.yml` |
| 5 (módulo `auth`) | Las cuatro piezas, el `__all__`, el montaje y los dos handlers | `repository.py`, `service.py`, `io.py`, `router.py`; `main.py:78` monta el router y `:85`/`:100` registran los handlers; `POST /api/auth/login` está en `PUBLIC_ROUTES` con su motivo escrito |
| 6 (contrato tipado) | `make types` y `schema.d.ts` | `Makefile:44-48`; `frontend/src/api/schema.d.ts` existe y `api/auth.ts` lo consume |
| 7 (ruteo y login) | `App.tsx`, `client.ts`, `auth.ts`, `Login.tsx`, `MyActions.tsx`, `RequireSession` | Los seis existen; el `Router` está en `main.tsx` alrededor de `<App />`, como el plan fija |
| 10 (`/me`) | La ruta protegida que no consulta la base | `router.py:39`, con `Depends(get_current_user)`, sin parámetros y sin sesión de base |
| 11 (sesión persistente) | `storage.ts`, `session.ts`, `SessionProvider.tsx`, `Header.tsx`, el aviso de `RF-27` | Los cinco; `loading` se resuelve en la primera render (`useState(startupFromStorage)`) |
| 14 (la salida) | `logOut()` y `Cerrar sesión` | `SessionProvider.tsx::logOut` y el `<button>` de `Header.tsx` |
| 15 (documentación) | `ARCHITECTURE.md` y `AGENTS.md` al día | `ARCHITECTURE.md:56-58` (con `SessionDep` y `ratelimit.py`) y `:210` (el `__all__` de `auth`); `AGENTS.md:92` |

---

## Reglas del dominio: ninguna contradicha

| | Regla | Cómo quedó |
|---|---|---|
| I | La credencial del proveedor vive sólo en el backend | La feature no toca el proveedor y no agrega ninguna `VITE_*`. `grep -rniE "twelvedata\|apikey\|api_key" frontend/src`, limpio; `api/client.ts` sale siempre a `/api` relativo |
| II | La cuota es finita | Ninguna ruta nueva sale al proveedor; `/me` no consulta ni la base. Ningún cliente HTTP fuera de `app/providers/` |
| III | Los datos de un usuario son de ese usuario | Ninguna de las dos rutas recibe un identificador de usuario: `/me` sale de los claims. `grep` de `user_id` desde path/query/body, limpio, y lo fija `TestNoRouteAcceptsAUserId` |
| IV | La frontera entre módulos | `auth` exporta sólo `router`; todos los imports por ruta profunda apuntan al **propio** módulo, ninguno cruza; el flujo es `router` → `service` → `repository`, y el router recibe `SessionDep` para no nombrar SQLAlchemy |
| VII | El enunciado es el contrato | Los once literales salen verbatim de `COPY.md`, `usuario o clave invalida` sin tilde incluido, y `copy.test.ts` lo rompe si alguien lo "corrige". Los cinco textos que el enunciado no da están declarados en la spec y en `COPY.md` |
| X | Las decisiones las toma un humano | **Ningún ADR nuevo** entró a `docs/DECISIONS.md`: los nueve preexisten. Tres pasaron de `Propuesta` a `Aceptada` firmados con nombre y fecha — ver el hallazgo 5 |

**Ambigüedad `A1` de `docs/PROJECT_BRIEF.md`** (no hay registro; los usuarios vienen del seed y las
claves se hashean con Argon2): el código hace eso y nada más. Las otras seis (`A2`…`A7`) son de
`002` y `003` y esta feature no las toca.

---

## Hallazgos

| # | Tipo | Qué dice el artefacto | Qué hace el código | Rol dueño | Acción |
|---|---|---|---|---|---|
| 1 | Deriva del plan | `plan.md` no menciona `RF-27` en ningún lado: dice que "la aprobación vigente cubre `RF-01` a `RF-26`" y su tabla *Dónde cae cada requisito* termina en `RF-26` | `RF-27` está implementado (`pages/Login.tsx::refusalFor`), testeado y cubierto por `tasks.md` | `Frontend-Architect` | Sumar `RF-27` al plan: la fila en *Dónde cae cada requisito*, el cuarto aviso en *El orden de la validación*, y corregir la línea de alcance firmado a `RF-01` a `RF-27` |
| 2 | Deriva del plan | `plan.md` → *Frontend* declara `useSession()` con cinco miembros: `status`, `user`, `expired`, `logIn`, `logOut` | `auth/session.ts::Session` expone un sexto, `token: string | null`, que hoy **ningún consumidor lee**: sólo lo escribe el provider | `Frontend-Architect` | Decidir y escribirlo: o el plan declara `token` y por qué (`002` lo va a necesitar para autorizar sus llamadas), o el campo espera a `002`. Superficie sin consumidor, aunque sea una línea, es superficie |
| 3 | Deriva del plan | `plan.md` → *El límite de intentos* dice que "la espera se cuenta desde el último intento fallido, que es lo que hace que insistir no acorte el castigo", y el docstring de `ratelimit.py::hit` dice que los eventos registrados con la clave ya agotada "cuentan también" | `service.py::authenticate` corta con `raise` **antes** de llamar a `hit()`, así que un intento rechazado por el límite no se registra: la espera se cuenta desde el más viejo de los diez fallos verificados, y insistir no la alarga. Es también lo que el plan describe dos párrafos antes, al definir `retry_after` | `Backend-Architect` · `Developer` | **Decidido por Leandro Carriego el 2026-09-13: el código está bien.** La espera son cinco minutos desde el décimo fallo verificado y un intento rechazado no la mueve, que es lo que el criterio firmado de `RF-21` describe (*"pasados cinco minutos sin intentar"*). No cambia comportamiento y no vuelve a la spec. Queda: corregir la frase del plan (`Backend-Architect`) y el docstring de `ratelimit.py::hit`, que hoy describe un caso que nunca ocurre (`Developer`) |
| 4 | Deriva del plan | `plan.md` → *El secreto de firma* dice que el vacío "no es un default, es una negativa", y su checklist para el `Code-Reviewer` pide verificar que **no haya default committeado**. `.env.example:9` lo repite: *"no hay usable default y none is committed"* | `docker-compose.yml:37` commitea uno para desarrollo: `JWT_SECRET: ${JWT_SECRET:-local-development-signing-key-not-a-secret}`, con su motivo escrito al lado (un clon fresco tiene que poder `make up` y entrar). `docker-compose.prod.yml:54` usa `${JWT_SECRET:?…}` y no tiene default | `Backend-Architect` · `Developer` | **Decidido por Leandro Carriego el 2026-09-13: se acepta el default de desarrollo.** El compose local queda como está; producción sigue sin default. Queda corregir los dos textos que hoy afirman lo contrario: `plan.md` → *El secreto de firma* y su checklist del `Code-Reviewer` (`Backend-Architect`), y el comentario de `.env.example:9` (`Developer`) — los dos pasan a decir "ningún default **en producción**" en vez de "ninguno" |
| 5 | Deriva del plan | `plan.md` → *Constitution Check*, Artículo X: "Este plan no agrega ni modifica ningún ADR" | El changeset modifica `docs/DECISIONS.md`: `ADR-005`, `ADR-007` y `ADR-008` pasan de `Propuesta` a `Aceptada` con *Decidida por: Leandro Carriego · 2026-09-13*, y el texto de `ADR-007` y `ADR-008` cambia. El de `ADR-007` es de esta feature: agrega que `JWT_SECRET` es la única variable obligatoria en todo entorno | `Backend-Architect` | **Confirmado por Leandro Carriego el 2026-09-13: las tres aceptaciones y los dos cambios de texto son suyos.** El Artículo X queda cumplido en la letra y en el acto: ningún ADR nuevo, y las aceptaciones las escribió la persona que tiene que defenderlas. Nada se revierte. Queda corregir la línea del Constitution Check del plan, que dice que no modifica ningún ADR y hoy no es verdad |

| 6 | Deriva del plan | `plan.md` → *Riesgos*: el riesgo de `JWT_SECRET` mal configurado se declara mitigado porque "el `lifespan` loguea `jwt_secret_missing` en warning al arrancar" | `main.py:52` loguea sólo con `if not settings.jwt_secret`. Un secreto **corto pero no vacío** —diez caracteres— arranca **sin ninguna advertencia** y revienta en el primer login, que es justo el escenario que el plan llama "el peor de los tres entornos para descubrirlo". En producción `${JWT_SECRET:?…}` tampoco lo atrapa: exige que la variable esté, no que mida | **Humano** → `Developer` | Lo encontró el `Backend-Architect` al corregir el hallazgo 4, y **no lo tocó**: el plan es literalmente correcto ("cuando está vacío"), así que no es una contradicción, pero el warning no cubre el caso que el mínimo de 32 caracteres introdujo. Es una línea en el `lifespan` (`if len(settings.jwt_secret) < 32`). **Decisión tuya:** cerrarlo ahora —código nuevo, y entonces el `Tester` va antes— o dejarlo anotado como riesgo aceptado en el plan. No bloquea el gate |

Ningún hallazgo es de tipo **Requisito sin implementar**, **Alcance no pedido**, **Tarea sin
respaldo** ni **Contradicción con una regla del dominio**.

### Lo que los agentes de la corrección encontraron y no tocaron

- **`backend/tests/unit/test_rate_limiter.py:145`** — el test `test_insisting_does_not_shorten_the_wait`
  lleva como docstring *"Hits made while the key is spent count too: keep guessing, stay out"*, que es
  la premisa que el hallazgo 3 declara inexistente en este sistema. **El test pasa y es correcto en el
  nivel del kernel** —llama a `hit()` directo, sin pasar por `authenticate()`, y ahí `hit` sí registra
  sin consultar el límite—, así que no contradice al código ni al docstring corregido. Lo que quedó
  viejo es su prosa, que sugiere el comportamiento de `auth` que el humano descartó. Es artefacto
  firmado del `Tester` (Artículo VI): si se corrige, va por `/approve-tests`, no de prepo.

- **El changeset arrastra un cambio que no es de esta feature.** El working tree renombra el dominio
  de despliegue —`mendrisoftware.com` → `leandrocarriego.com`— en `.env.example`, `README.md`,
  `docker-compose.prod.yml` y `scripts/deploy.sh`. Es coherente en los cuatro y es anterior a esta
  corrección, pero no lo pide ningún `RF` de `001` ni lo menciona `plan.md`. **No es alcance no
  pedido** —no es una capacidad de negocio, es infraestructura de despliegue—, y queda anotado para
  el `Release-Manager`: si entra en el commit de la feature, el PR de `001` va a incluir un renombre
  de dominio que nadie va a buscar ahí.

---

## Dos cosas que no son hallazgos y conviene dejar escritas

**La contradicción de una línea dentro de `spec.md`.** La sección *Lo que se aparta de los
wireframes* dice que el cliente "aprobó cuatro el 2026-09-13 y ese mismo día pidió la quinta […],
que está pendiente de firma", mientras la segunda enmienda de la cabecera dice que ese quinto texto
**fue firmado** ese mismo día y que la aprobación cubre `RF-01` a `RF-27`. Gana la cabecera —es donde
vive la firma—, y `RF-27` está construido y testeado sobre esa base. Es una línea que quedó vieja
dentro del artefacto del `Solution-Designer`; se corrige al pasar, sin reabrir ningún gate.

**La columna *Test* del brief sigue vacía para `REQ-01` a `REQ-04`.** No es deuda de esta feature:
`tasks.md` y `docs/specs/README.md` → *Al entregar* la asignan a `ship_changes`, en el mismo commit
que archiva la spec. Queda anotada acá para que `/ship` no se la saltee, porque está en la
*Definition of Done*.

---

## Estado de las correcciones (2026-09-13, después del veredicto)

Los cuatro roles corrigieron su artefacto y el `Lead` verificó cada cambio contra el código. **Los
seis hallazgos quedaron cerrados salvo el 6, que espera una decisión del humano y no bloquea.**

| # | Rol | Qué se corrigió | Verificado |
|---|---|---|---|
| 1 | `Frontend-Architect` | `RF-27` entró al plan en siete lugares: la nota de alcance firmado (`RF-01` a `RF-27`, con las dos enmiendas), los artículos V y VII del Constitution Check, *Enfoque*, la fila de *Dónde cae cada requisito*, *Módulos afectados* (de tres respuestas a cuatro avisos), *El orden de la validación* (los cuatro, en el orden del copy, más la aclaración de que el aviso de `RF-17` no es uno de ellos y les cede) y los tres destinatarios del *Contexto de traspaso* | Sí |
| 2 | `Frontend-Architect` | `token: string \| null` queda **declarado** en el contrato de `useSession()`, con su porqué: `api/client.ts::request` recibe la credencial por llamada, y la alternativa —que cada pantalla lea `sessionStorage`— crea una segunda fuente que no sabe si `/me` confirmó ese token ni si su `expiresAt` pasó. Se anota que hoy no tiene consumidor y que el primero es `002`. **Ningún cambio de código** | Sí |
| 3 | `Backend-Architect` · `Developer` | El plan dice ahora que la espera corre desde el décimo fallo **verificado** y que un intento rechazado no la mueve, con el argumento de por qué es la lectura del criterio firmado de `RF-21`. El docstring de `ratelimit.py::hit` describe el comportamiento real y sigue sin nombrar `login` ni `username` | Sí |
| 4 | `Backend-Architect` · `Developer` | *El secreto de firma* y la checklist del `Code-Reviewer` dicen "ningún default **en producción**", y declaran el valor local como deliberado y confinado al compose. El comentario de `.env.example` dice lo mismo. De paso se corrigió una afirmación falsa de la misma sección: el `RuntimeError` no es sólo con el secreto vacío, es con menos de 32 caracteres | Sí |
| 5 | `Backend-Architect` | La fila del Artículo X nombra las tres aceptaciones como actos del humano con nombre y fecha, y cierra listando los ADR que el plan cita —`ADR-001`, `ADR-004`, `ADR-009`—, los tres `Aceptada` | Sí |
| 6 | `Backend-Architect` | **Riesgo aceptado por Leandro Carriego el 2026-09-13: no se cambia código.** Quedó escrito en la tabla *Riesgos* del plan —en una fila propia, separada de la del secreto vacío, porque el estado difiere: una está mitigada y la otra aceptada— con el hueco exacto, por qué el warning no lo cubre, qué lo atrapa igual (el `RuntimeError` del primer login, que corta en vez de firmar débil) y la salida para el día que se quiera cerrar: `if len(settings.jwt_secret) < 32` en el `lifespan`, con el `Tester` primero. También en *OWASP* → *Lo que se acepta, dicho de frente* | Sí |
| spec | `Solution-Designer` | El párrafo de *Lo que se aparta de los wireframes* dice que los cinco textos están aprobados, el quinto por la segunda enmienda. La línea de aprobación, las dos enmiendas, los 27 requisitos y los 27 criterios quedaron intactos | Sí |

Los chequeos después de las correcciones: `ruff`, `ruff format`, `mypy` limpios, **323 tests de
backend** en verde con la misma cobertura de 91,86 %, y **74 del frontend**. Ningún test fue tocado.

### Tres cosas que se reportaron como contradicción y no lo son

Quedan escritas para que nadie las vuelva a perseguir:

- **Los criterios de aceptación de `spec.md` están todos en `- [ ]`, y así va.** No son el estado de
  la implementación: son lo que el cliente marca cuando lo ve andando. Los 27 están sin marcar, no
  sólo el de `RF-27`.
- **`RF-27` con origen `/clarify` en la columna *Enunciado* es correcto.** La leyenda de esa columna
  dice justamente eso: `/clarify` marca lo que **no** viene del enunciado y decidió el cliente el
  2026-09-13, que es exactamente lo que pasó con `RF-27`.
- **El comentario de `Login.tsx:24` —"Which of the three notices…"— es exacto.** Cuenta las tres
  refusals que devuelve `refusalFor()`, o sea las de un intento que **llegó** a la API; el cuarto
  aviso, el de campo vacío, corta antes de que haya intento. El docstring del archivo dice "four
  notices" porque cuenta los cuatro de la pantalla. Los dos números son distintos porque cuentan
  cosas distintas.

## Qué sigue

**Los seis hallazgos están cerrados** (tabla de arriba): cinco corregidos en su artefacto y el
sexto aceptado como riesgo, con fecha y nombre. Este converge no tiene nada abierto.

La feature **pasó al `Code-Reviewer`** el 2026-09-13: `/review-feature 001-authentication`. Dos
cosas que ese gate no tiene que reabrir, porque son decisiones del humano y están registradas acá:
el `JWT_SECRET` de desarrollo del compose local (hallazgo 4) y el hueco del warning con un secreto
corto (hallazgo 6).

Dos apuntes que sobreviven a este informe y no son de esta feature:

- **El docstring de `test_rate_limiter.py:145`**, si se corrige, va por `/approve-tests` — es un
  test firmado.
- **El renombre de dominio** que el working tree arrastra: el `Release-Manager` decide si entra en
  el commit de `001` o se separa.

Y para `/ship`: la columna *Test* de la tabla de trazabilidad del brief (`REQ-01`…`REQ-04`,
`NFR-01`) se completa en el mismo commit que archiva la spec.

---

## Gate de calidad: **Aprobado** (2026-09-13)

El `Code-Reviewer` cerró su gate el mismo día. Queda registrado acá porque el review no dejó
artefacto propio y la feature tiene que poder leerse de un solo lugar.

- **Un solo Blocker**, y por efecto y no por severidad: un comentario de
  `frontend/tests/Header.test.tsx:196` citaba el requisito en castellano, y
  `scripts/check_comment_language.py` —hook con `always_run: true` y paso del CI— salía con exit 1.
  Lo corrigió el `Tester` parafraseando la cita en inglés, sin tocar ninguna aserción, y lo
  re-verificaron el `Lead` y el `Code-Reviewer` por separado: `pre-commit` **15/15**, frontend **74
  passed**, backend **323 passed** con 91,86 %.
- **El hallazgo de la columna *Test* del brief se retractó.** El `Code-Reviewer` lo había marcado
  Major pendiente para aprobar; al confrontarlo con `docs/specs/README.md` → *Al entregar* y con el
  comentario de cierre de `tasks.md` lo reclasificó como pendiente de `/ship`, que es donde ya
  estaba anotado. El fundamento no es la costumbre: `AGENTS.md` → *Estructura de las specs* delega
  en `docs/specs/README.md` qué paso escribe cada artefacto, así que la asignación no la puede
  sobrescribir una skill.
- **Los cuatro puntos de endurecimiento OWASP se verificaron contra comportamiento real**, no
  contra el archivo: se levantó un nginx con la config del working tree y se comprobó que una
  `X-Forwarded-For` forjada se descarta, que `CF-Connecting-IP` gana en el supuesto de producción, y
  que las cuatro cabeceras de seguridad llegan en las siete rutas —incluido el 404 bajo `/assets/`—
  con un solo `add_header` en todo el archivo. Se leyó además el middleware de uvicorn instalado
  para confirmar que la confianza acotada a RFC1918 toma la IP del extremo correcto.

**Dos cosas que salieron del gate y no son de esta feature**, las dos para el humano:

1. **`GEN-07` está marcada `Minor` y su verificación rompe el build.** El índice de Blockers de
   `CONVENTIONS.md` (#14) describe la situación pero nombra sólo `PY-07` y `TS-04`. Severidad
   documentada y enforcement real no coinciden, y hoy quedó demostrado en la práctica.
2. **`agents/skills/review_feature.md` → paso 7 contradice a `docs/specs/README.md`**: le pide al
   `Code-Reviewer` verificar que la columna *Test* esté **completa**, cuando la convención la asigna
   a `ship_changes`. Es la contradicción que produjo el hallazgo retractado, y por `AGENTS.md` gana
   `docs/specs/README.md`. La línea de la skill tendría que pedir que esté **asignada** a `/ship`.

**Nota operativa para el deploy, que no es hallazgo:** el contenedor `frontend` que corre hoy tiene
la `nginx.conf` **vieja** —sin cabeceras de seguridad y con `proxy_add_x_forwarded_for`—. Hay que
reconstruir la imagen, o el endurecimiento queda en el repositorio y no en el servidor.
