# Autenticación y sesión — Plan técnico

<!--
  ARTEFACTO INTERNO. Acá van las decisiones técnicas que spec.md no puede llevar.
  No se exporta al cliente.
-->

**Feature:** `001-authentication` · **Spec aprobada el:** 2026-09-13 · **Fecha:** 2026-09-13

**Roles:** `Backend-Architect` + `Frontend-Architect` (feature full-stack, un solo plan).

> **Sobre alcance firmado.** El 2026-09-13, después de la primera firma, el cliente pidió
> incorporar el **límite de intentos de ingreso**, que la spec listaba en *Fuera de alcance*. No se
> agregó en este plan: volvió a la spec como enmienda (`RF-21` a `RF-26`) y se firmó ese mismo día
> (Artículo V).
>
> **Y ese mismo día entró una segunda enmienda, también firmada.** Al construir H1 se vio que un
> intento que no logra comunicarse con nuestra API terminaba mostrando `usuario o clave invalida`,
> porque era el único aviso de falla que existía: un texto que le echa la culpa a la credencial de
> la persona por algo que no es suyo. El cliente pidió incorporarlo y construirlo dentro de H2, y es
> `RF-27`. Tampoco lo decidió este plan: es alcance nuevo, firmado en la spec **antes** de
> construirse (Artículo V), y lo único que agrega este plan es dónde cae —*Frontend — estructura y
> contrato de pantalla*, más abajo—.
>
> La aprobación vigente cubre `RF-01` a `RF-27`.

## Constitution Check

| Artículo | Cumple | Cómo |
|---|---|---|
| I — La credencial del proveedor vive sólo en el backend | ✅ | La feature no toca el proveedor. No agrega ninguna variable `VITE_*`: el frontend sigue hablando sólo con `/api` por el proxy de Vite. El secreto nuevo (`JWT_SECRET`) se lee en `app/settings.py` y en ningún otro lado, igual que `TWELVEDATA_API_KEY`. |
| II — La cuota es finita, y eso es parte del diseño | ✅ | Ninguna ruta nueva sale al proveedor. `POST /api/auth/login` y `GET /api/auth/me` se resuelven con la base y con el token; el segundo ni siquiera consulta la base. |
| III — Los datos de un usuario son de ese usuario | ✅ | `get_current_user` resuelve la identidad **sólo** desde el `sub` del token. Ninguna ruta de esta feature acepta `user_id` por path, query o body, y `/api/auth/me` no recibe ningún parámetro: devuelve lo que el token afirma de quien lo presenta. La otra mitad del artículo —queries filtradas por el `sub`— aparece con `002`, que es la que tiene datos por usuario. |
| IV — Las fronteras entre módulos son reales | ✅ | Todo lo nuevo del dominio vive en `auth/`, que exporta **sólo** `router`. `get_current_user`, `CurrentUser`, Argon2 y JWT viven en `app/security.py` (kernel), que no importa ningún módulo. `main.py` entra por el paquete (`from app.modules.auth import router`). Adentro del módulo el flujo va `router` → `service` → `repository`, y el service comunica la falla con una excepción de dominio. |
| V — Spec primero, y con firma | ✅ | `spec.md` está en `Estado: Aprobado`, firmada por Leandro Carriego el 2026-09-13, y la firma cubre `RF-01` a `RF-27` — el límite de intentos y el aviso de no haber podido conectarse incluidos, que entraron como **enmiendas firmadas** y no como decisiones técnicas de este plan. El agente no amplió el alcance: frenó, lo dijo, y lo devolvió a la spec. |
| VI — Lo que no está tipado y testeado no está terminado | ✅ | `mypy --strict` cubre el código nuevo; los tests los escribe el `Tester` **antes** de la implementación y los firma el humano (`/approve-tests`). La suite sigue sin red y sin API key: esta feature no agrega ninguna llamada saliente. |
| VII — El enunciado es el contrato, y sus ambigüedades se declaran | ✅ | Los textos salen verbatim de `docs/design/COPY.md`, faltas incluidas (`usuario o clave invalida`). Los textos que el enunciado no da están declarados en `spec.md` → *Lo que se aparta de los wireframes* y en `COPY.md` → *Sesión y validación*; el cuarto —`Demasiados intentos. Probá de nuevo en unos minutos.`— y el quinto —`No pudimos conectarnos con el servidor. Intentá de nuevo en unos minutos.` (`RF-27`)— entran por la misma puerta y con el mismo registro. El límite de intentos **no lo pide el enunciado**: lo pidió el cliente, y por eso pasa por la spec y por su firma en vez de colarse como decisión técnica. Sigue sin construirse registro, "recordarme" ni renovación de sesión. |
| VIII — Un idioma para cada audiencia | ✅ | Código, nombres y docstrings en inglés; los strings de pantalla en español y verbatim del copy. Los mensajes que devuelve la API (`detail`) son en inglés y **no** se muestran: la pantalla decide qué texto va, porque `UI-02` exige que el literal viva en `frontend/src`. |
| IX — Las dependencias entran por la puerta | ✅ | Backend: `pyjwt` y `argon2-cffi` ya están en `backend/pyproject.toml` desde la fase 0, y el límite de intentos **tampoco agrega ninguna** —ni `slowapi`, ni `redis`, ni `limits`—: son sesenta líneas de contador en el kernel. Frontend: entran dos por `npm install`, con su justificación en *Alternativas descartadas* (`react-router`, `openapi-typescript`), y `package-lock.json` se commitea en el mismo commit. |
| X — Las decisiones de arquitectura las toma un humano | ✅ | Este plan no agrega **ningún ADR nuevo**, y se apoya en `ADR-004` y en `ADR-001`, las dos `Aceptada`. Lo que el changeset de esta rama sí toca es el estado de tres: `ADR-005`, `ADR-007` y `ADR-008` pasan de `Propuesta` a `Aceptada` con *Decidida por: Leandro Carriego · 2026-09-13*. Son actos del humano —confirmados el 2026-09-13, con nombre y fecha en el archivo—, que es exactamente lo que el artículo exige y lo único que un agente no puede escribir. El cambio de texto de `ADR-007` es de esta feature: registra que `JWT_SECRET` es la única variable obligatoria en **todo** entorno. El de `ADR-008` también es del humano y acompaña a las primeras pantallas reales del proyecto. Este plan no cita ningún ADR en `Propuesta`: los tres que menciona —`ADR-001`, `ADR-004` y `ADR-009`— están `Aceptada`. |

**Excepciones solicitadas:** ninguna.

## Enfoque

El backend emite un JWT y el frontend lo presenta. `POST /api/auth/login` valida usuario y clave
contra Argon2id y devuelve un token HS256 con `sub` (el id del usuario), `name` (el nombre
completo) y `exp` a 60 minutos (`ADR-004`, `RF-16`). Los tres archivos nuevos de `auth/` hacen lo
de siempre: el `router.py` traduce HTTP, el `service.py` decide y el `repository.py` busca la fila.
La falla viaja como excepción de dominio (`AuthenticationError`) y la traduce `main.py` a un 401,
con **el mismo cuerpo** para usuario inexistente y para clave equivocada (`RF-06`).

Las piezas transversales van al kernel, que es donde `ARCHITECTURE.md` ya las tenía anotadas:
`app/security.py` —que hoy sólo tiene Argon2— suma la emisión y la verificación del token y la
dependencia `get_current_user`, y nace `app/errors.py` con `DomainError` y `AuthenticationError`.
Ninguno de los dos conoce un módulo, y por eso los pueden importar todos (`GEN-03`).

La segunda ruta, `GET /api/auth/me`, existe por una razón puntual: es lo que el frontend llama al
**recargar** la pantalla para saber si el token que tiene guardado sigue vivo (`RF-07`, `RF-17`).
Responde con los claims del token y **no consulta la base**, así que no contradice a `ADR-004`
—"el nombre para la cabecera sale del token, sin request extra"—: después del login el nombre
viene en la propia respuesta del login, y en el F5 lo que hace falta no es el nombre sino saber si
la sesión vence. Es además la primera ruta protegida del proyecto, la que deja de ser vacuo a
`TestRoutesEnforceAuthorization`.

En el frontend aparecen las dos primeras pantallas de verdad, y con ellas el ruteo. `react-router`
entra acá porque `RF-09` se verifica pegando una dirección en el navegador: sin URLs reales ese
criterio de aceptación no se puede escribir. La sesión vive en `src/auth/` —el contexto, el
almacenamiento en `sessionStorage` y el interceptor de 401—, el acceso HTTP en `src/api/`, y las
pantallas en `src/pages/`, una por wireframe. De `Mis Acciones` esta feature construye **sólo la
cabecera** (`Mis Acciones` a la izquierda; `Usuario: {nombre completo}` y `Cerrar sesión` a la
derecha): la grilla, el autocomplete y el alta son de `002` y este plan no las toca.

El **límite de intentos** (`RF-21` a `RF-26`) es un contador de ventana deslizante en memoria del
proceso, en `app/ratelimit.py`: diez fallos en cinco minutos, contados **por dirección de red y por
nombre de usuario** a la vez. El router saca la IP —que es un dato del transporte— y el service
aplica la política: **consulta el límite antes de verificar la clave**, así que pasado el umbral ni
siquiera se gasta un Argon2. Un ingreso exitoso limpia los dos contadores. La falla viaja como
`RateLimitedError`, `main.py` la traduce a **429 con `Retry-After`**, y la pantalla muestra
`Demasiados intentos. Probá de nuevo en unos minutos.`

Que sea una espera y no un bloqueo de cuenta es deliberado: sin alta ni recuperación de clave
(`A1`), una cuenta bloqueada no tiene forma de volver, y cualquiera podría dejar afuera a otro
tipeando mal a propósito. La ventana se cierra sola, y ése es todo el diseño.

Lo que el usuario ve lo decide la pantalla, no la API. El backend responde 401 con un `detail` en
inglés que nadie muestra; `Login` traduce ese 401 a `usuario o clave invalida`, el 429 al texto de
arriba, y el campo vacío —que ni siquiera llega a la API (`RF-13`)— a `Completá este campo.`. Y el
caso en el que no hay respuesta que traducir —la llamada no llegó a nuestra API— tiene su propio
aviso, `No pudimos conectarnos con el servidor. Intentá de nuevo en unos minutos.` (`RF-27`): el
detalle, en *Frontend*.

### Dónde cae cada requisito

| RF | Dónde se resuelve |
|---|---|
| RF-01 · RF-02 | `pages/Login.tsx` contra `wireframes/01-login.png` y `COPY.md` → *Login*; la clave es `type="password"` |
| RF-03 | `logIn()` guarda la sesión y `Login` navega a `/`, que es `Mis Acciones` |
| RF-04 · RF-05 | El 401 de `POST /api/auth/login` se traduce en la pantalla a `usuario o clave invalida`; `Login` no navega, así que la pantalla no cambia |
| RF-06 | `auth/service.py`: misma `AuthenticationError` para usuario inexistente y clave equivocada, más el hash señuelo para que el tiempo tampoco distinga |
| RF-07 | `SessionProvider` restaura de `sessionStorage` y confirma con `GET /api/auth/me` |
| RF-08 | `components/Header.tsx` con el `full_name` que trae el login (y que `/me` confirma) |
| RF-09 | `auth/RequireSession.tsx` → `<Navigate to="/login" replace />` |
| RF-10 · RF-11 | Ya resueltos por la fase 0: columna `password_hash`, Argon2id, y ningún schema de salida la incluye |
| RF-12 · RF-13 | Validación local de `Login` antes del submit: `Completá este campo.` bajo cada vacío y sin llamada a la API |
| RF-14 · RF-15 | `auth/service.py` normaliza el usuario a minúsculas; la clave va tal cual a `verify_password` |
| RF-16 | `ACCESS_TOKEN_TTL = timedelta(minutes=60)` en `app/security.py`, reflejada en `exp` y en `expires_in` |
| RF-17 | El interceptor de 401 marca `expired` y `Login` muestra `Tu sesión expiró. Volvé a ingresar.` |
| RF-18 | `components/Header.tsx` |
| RF-19 · RF-20 | `logOut()` limpia memoria y `sessionStorage`, y navega a `/login` |
| RF-21 · RF-22 | `app/ratelimit.py` cuenta ventanas deslizantes; `auth/service.py` pone los números (`LOGIN_MAX_ATTEMPTS = 10`, `LOGIN_WINDOW = timedelta(minutes=5)`) y las dos claves: `ip:<addr>` y `user:<username>` |
| RF-23 | `main.py` traduce `RateLimitedError` a 429; `pages/Login.tsx` lo muestra como `Demasiados intentos. Probá de nuevo en unos minutos.` |
| RF-24 | El chequeo del límite va **antes** de `verify_password`: pasado el umbral no se llega a validar nada, ni siquiera a buscar el usuario |
| RF-25 · RF-26 | `authenticate()` limpia las dos claves —la del usuario y la de la IP— cuando la clave verifica |
| RF-27 | `pages/Login.tsx::refusalFor`: si lo que falló no es un `ApiError` no hubo respuesta que leer —la credencial nunca se validó—, así que el aviso es `No pudimos conectarnos con el servidor. Intentá de nuevo en unos minutos.` y no `usuario o clave invalida` |

## Módulos afectados

| Módulo | Piezas tocadas | Qué cambia | Nuevo |
|---|---|---|---|
| `auth` | `backend/app/modules/auth/router.py` · `io.py` · `service.py` · `repository.py` · `__init__.py` | Nace el módulo completo: router con las dos rutas, schemas de entrada y salida, la decisión de negocio (aplicar el límite de intentos, normalizar el usuario, verificar el hash, emitir el token) y el acceso a `users`. El módulo es dueño de los **números** de la política (`LOGIN_MAX_ATTEMPTS`, `LOGIN_WINDOW`), no del mecanismo de contar. `models.py` **no se toca**: la tabla ya existe desde la fase 0. El `__init__.py` pasa de `__all__ = []` a `__all__ = ["router"]`. | `router.py`, `io.py`, `service.py`, `repository.py` |
| `stocks` | — | No se toca. | — |
| `favorites` | — | No se toca. | — |
| `quotes` | — | No se toca. | — |
| composition root · shared · providers | `backend/app/main.py` · `backend/app/settings.py` · `backend/app/security.py` · `backend/app/errors.py` · `backend/app/ratelimit.py` · `backend/app/observability.py` · `backend/app/db.py` | `db.py` suma el alias `SessionDep`, sin el cual el router no puede recibir la sesión sin importar SQLAlchemy (`PY-06`). `main.py` monta el router de `auth` y registra los dos handlers que traducen `AuthenticationError` → 401 y `RateLimitedError` → 429; además loguea una advertencia en el arranque si `JWT_SECRET` está vacío. `settings.py` suma `jwt_secret` y lo lista en `secret_values()`. `security.py` suma `ACCESS_TOKEN_TTL`, `create_access_token`, `CurrentUser` y `get_current_user`. `observability.py` suma el contador `LOGIN_ATTEMPTS` (`outcome`), que es lo que hace detectable un ataque de fuerza bruta (OWASP A09). `providers/` no se toca. | `app/errors.py` (`DomainError`, `AuthenticationError`, `RateLimitedError`) · `app/ratelimit.py` (`SlidingWindowLimiter`) |
| web | `frontend/src/App.tsx` · `main.tsx` · `pages/Login.tsx` · `pages/MyActions.tsx` · `components/Header.tsx` · `auth/` · `api/client.ts` · `api/auth.ts` · `api/schema.d.ts` · `frontend/nginx.conf` | Nace el ruteo (`/login`, `/`, `/health`), la sesión y las dos pantallas. `Login` distingue **cuatro** avisos excluyentes, en el orden que fija `COPY.md`: campo vacío → `Completá este campo.`, 429 → `Demasiados intentos. Probá de nuevo en unos minutos.`, ninguna respuesta que leer → `No pudimos conectarnos con el servidor. Intentá de nuevo en unos minutos.` (`RF-27`), 401 → `usuario o clave invalida`. `nginx.conf` suma las cabeceras de seguridad (ver *OWASP*). `pages/HealthPage.tsx` se mueve de la raíz a `/health` y no cambia por dentro. `api/health.ts` **no se toca**. | `App.tsx`, `pages/Login.tsx`, `pages/MyActions.tsx`, `components/Header.tsx`, `auth/SessionProvider.tsx`, `auth/session.ts`, `auth/storage.ts`, `auth/RequireSession.tsx`, `api/client.ts`, `api/auth.ts`, `api/schema.d.ts` (generado) |

Fuera de los dos proyectos, **cuatro** archivos de infraestructura suman la variable nueva:
`.env.example` (`SEC-03`), `docker-compose.yml` (servicio `backend`), **`docker-compose.prod.yml`
(servicio `backend`)** y `.github/workflows/ci.yml` (el job que corre la suite). Y el `Makefile`
suma el target `types` que `TS-03` ya nombraba y que todavía no existía.

**El de producción es el que no se puede olvidar**, y por eso se nombra aparte: `jwt_secret` no
tiene default usable, la validación es al usar y no al importar, así que un deploy sin la variable
**arranca, responde el health en verde y recién revienta en el primer login**. Es el peor de los
tres entornos para descubrirlo. El `lifespan` loguea `jwt_secret_missing` al arrancar justamente
para esto, pero un warning en un log no reemplaza a la variable puesta.

Dos más los tocó el límite de intentos, y **ya están aplicados** (2026-09-13, en esta rama):
**`backend/Dockerfile`** (el `CMD` de uvicorn, que confiaba en `X-Forwarded-For` de cualquiera) y
**`frontend/nginx.conf`** (que *agregaba* a esa cabecera en vez de reescribirla, y no mandaba
ninguna cabecera de seguridad). Sin esos dos, el límite por dirección de red se salteaba escribiendo
una cabecera. El detalle, en *OWASP* más abajo.

**`docs/design/COPY.md`** suma el cuarto texto —`Demasiados intentos. Probá de nuevo en unos
minutos.`— a su sección *Sesión y validación*, y hoy dice "los tres textos". Se actualiza **junto
con la firma de la enmienda**, no antes: si la firma no llega, el copy no tiene por qué haber
cambiado. Con la **segunda** enmienda sumó además el quinto —`No pudimos conectarnos con el
servidor. Intentá de nuevo en unos minutos.` (`RF-27`)—, por esa misma regla y con su firma ya
dada.

## Contrato entre módulos

| Frontera | Qué se pide | Qué se devuelve |
|---|---|---|
| router → service | `authenticate(session: AsyncSession, username: str, password: str, client_ip: str) -> AuthenticatedUser` — el router pasa lo que llegó en el body sin normalizar nada, más la IP del cliente, que es un dato del transporte y por eso la saca él (`PY-06`) | `AuthenticatedUser` (dataclass frozen del módulo: `id: int`, `full_name: str`). Levanta `AuthenticationError` si el usuario no existe o la clave no verifica —**la misma excepción en los dos casos** (`RF-06`)— y `RateLimitedError` si la ventana ya está llena (`RF-21`, `RF-22`) |
| service → repository | `find_by_username(session: AsyncSession, username: str) -> User | None` — recibe el usuario ya normalizado a minúsculas; compara con `func.lower(User.username)` | El modelo `User` o `None`. El modelo **no sale del módulo**: el service lo convierte en `AuthenticatedUser` |
| service → provider | Ninguna. Esta feature no sale al mundo. | — |
| service → limitador | `hit(key: str) -> None` · `is_exceeded(key: str) -> bool` · `retry_after(key: str) -> int` · `reset(key: str) -> None`, sobre un `SlidingWindowLimiter` del kernel. El service arma las dos claves (`f"login:ip:{client_ip}"`, `f"login:user:{username}"`) y es dueño de los números | Cuántos intentos hay en la ventana, y nada más. El limitador **no sabe** qué es un login: cuenta eventos por clave |
| este módulo → `__all__` de otro | Ninguno. `auth` no consume el paquete de ningún módulo. Del kernel importa `app.db` (`get_session`), `app.errors` (`AuthenticationError`, `RateLimitedError`), `app.security` (`verify_password`, `create_access_token`, `ACCESS_TOKEN_TTL`), `app.ratelimit` (`SlidingWindowLimiter`) y `app.observability` (`LOGIN_ATTEMPTS`), que no son módulos | — |
| `__all__` de este módulo → el resto (qué se agrega) | `router`, y nada más. Es lo que `main.py` necesita para montarlo, y es la puerta por la que entra el composition root como cualquier otro | — |

Lo que **no** entra al `__all__` y merece decirse: ni `authenticate`, ni `AuthenticatedUser`, ni
`find_by_username`, ni los schemas de `io.py`. Ningún otro módulo necesita autenticar a nadie: los
routers de `002` y `003` van a pedir la identidad a `app.security`, que es donde vive la primitiva.
Exportar `authenticate` sería superficie que habría que sostener para un consumidor que no existe.

Y la razón por la que `get_current_user` **no** vive en `auth/`: si viviera, los routers de
`favorites` y `quotes` tendrían que importar `auth` para poder autorizar, y la primitiva de
seguridad de todo el sistema pasaría a ser dominio de un módulo. Vive en `app/security.py`
(`GEN-03`, `ARCHITECTURE.md`), y se importa `from app.security import get_current_user, CurrentUser`.

**Fallas** — el service levanta dos excepciones de dominio, las dos hijas de `DomainError` y las dos
en `app/errors.py` (kernel, sin `fastapi` adentro):

| Excepción | HTTP que registra `main.py` | Cuerpo |
|---|---|---|
| `AuthenticationError` | **401** + `WWW-Authenticate: Bearer` | `{"detail": "invalid credentials"}` |
| `RateLimitedError` | **429** + `Retry-After: <segundos>` | `{"detail": "too many attempts"}` |

`RateLimitedError` lleva un atributo `retry_after_seconds: int`, que es lo único que el handler
necesita para armar la cabecera. Viven en el kernel y no adentro de `auth` por una razón de
frontera: `main.py` tiene que importarlas para registrar los handlers, y si vivieran en el módulo
habría que exportarlas en su `__all__` — contrato público para algo que ningún otro módulo consume.

`get_current_user` es la excepción deliberada a esa forma, y hay que leerla como lo que es: **no es
un service**, es una dependencia de FastAPI que vive en el borde HTTP del kernel, así que levanta
`HTTPException(401)` directamente. `PY-06` y `ERR-04` prohíben `HTTPException` adentro de un
módulo —el grep de `ERR-04` es `grep -rn "HTTPException" app/modules | grep -v "/router"`—, y
`app/security.py` no está adentro de ninguno. Hacerla levantar un `AuthenticationError` para que
main lo tradujera agregaría una indirección que no cambia ni el código ni el cuerpo de la respuesta.

## Datos

**Ninguna tabla nueva y ninguna columna nueva: esta feature no lleva migración.**

`users` (`id`, `username` unique, `full_name`, `password_hash`, `created_at`) ya existe desde la
migración inicial de la fase 0 (`394dab64d255`), con su modelo en `app/modules/auth/models.py` y
sus dos filas cargadas por el seed (`juan` / `Juan Perez` y `ana` / `Ana Gomez`, con Argon2id).
`DB-01` se cumple por no tener nada que sincronizar, y `alembic check` tiene que seguir limpio
después del cambio: si alguien toca `models.py`, este plan dejó de ser verdad.

Dos consecuencias del modelo que la feature asume y conviene dejar escritas:

- **`RF-10` y `RF-11` ya están resueltos por la fase 0**: la columna es `password_hash`, la escribe
  `hash_password` (Argon2id, `SEC-06`) y `tests/integration/test_password_hashing.py` la verifica.
  Esta feature no vuelve a hashear nada: sólo verifica.
- **El case-insensitive de `RF-14` se resuelve en la consulta, no en el esquema.** La columna no es
  `citext` y el `unique` es sobre el valor crudo, así que la búsqueda va con
  `func.lower(User.username) == username` y toma la primera fila. Eso no usa el índice único, y
  está bien: la tabla tiene dos filas y el único escritor es el seed, que escribe minúsculas. Si
  algún día hubiera alta de usuarios, la normalización habría que moverla a la escritura — y eso
  sería otra feature, porque el alta está fuera de alcance (`A1`).

## Contratos

### `POST /api/auth/login` — pública

Entra en `PUBLIC_ROUTES` de `backend/tests/architecture/test_route_authorization.py`, con el motivo
escrito: *es la ruta por la que se obtiene la credencial; exigir una para pedirla no cierra.*

```
Request   LoginRequest   { username: str (1..50), password: str (1..128) }
                         model_config: extra="forbid"   ← API3/BOPLA

200       LoginResponse  { access_token: str, token_type: "bearer",
                           expires_in: int (segundos), full_name: str }

401       { "detail": "invalid credentials" }  +  WWW-Authenticate: Bearer
          Idéntico para usuario inexistente y para clave equivocada (RF-06)

422       Body inválido (campo ausente, vacío o de más). El frontend no llega acá:
          valida los vacíos antes de pedir (RF-12, RF-13). Es el backstop.

429       { "detail": "too many attempts" }  +  Retry-After: <segundos>
          La ventana de RF-21 o la de RF-22 está llena. No se verificó
          ninguna credencial para responder esto (RF-24).
```

`full_name` viaja en la respuesta para que la cabecera se pinte sin un request extra (`ADR-004`,
`RF-08`). Es el mismo valor que el claim `name` del token, no una segunda fuente.

### `GET /api/auth/me` — protegida

```
Depends   Annotated[CurrentUser, Depends(get_current_user)]

200       CurrentUserResponse  { id: int, full_name: str }
401       { "detail": "not authenticated" }  +  WWW-Authenticate: Bearer
          Token ausente, mal firmado, mal formado o vencido: los cuatro, el mismo 401.
```

No recibe **ningún** parámetro: ni path, ni query, ni body. Sale de los claims y no toca la base.

### El token (`ADR-004`)

```
alg   HS256, firmado con settings.jwt_secret
sub   str(user.id)        ← la identidad, y la única fuente de identidad del sistema
name  user.full_name      ← RF-08
iat   emisión
exp   iat + ACCESS_TOKEN_TTL  (60 minutos, RF-16)
```

`ACCESS_TOKEN_TTL = timedelta(minutes=60)` es constante de `app/security.py` (`SEC-04`: es una
decisión de seguridad, no configuración de un operador). `expires_in` de la respuesta se deriva de
ella, así que el frontend no lleva el número escrito en ningún lado.

### Firmas nuevas del kernel

```python
# app/errors.py  (nuevo; no importa fastapi — GEN-03)
class DomainError(Exception): ...
class AuthenticationError(DomainError): ...

# app/security.py
ACCESS_TOKEN_TTL: Final = timedelta(minutes=60)

@dataclass(frozen=True, slots=True)
class CurrentUser:
    id: int
    full_name: str

def create_access_token(user_id: int, full_name: str) -> str: ...
async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
) -> CurrentUser: ...
```

```python
# app/db.py  — se suma al engine, la Base y get_session que ya están
SessionDep = Annotated[AsyncSession, Depends(get_session)]
```

**Por qué existe `SessionDep`, y es una corrección a este plan.** La firma de arriba decía que el
router recibe la sesión y se la pasa al service. Escrito de la forma obvia
—`session: Annotated[AsyncSession, Depends(get_session)]`— el router **importa SQLAlchemy**, y eso
lo prohíbe `PY-06`: `FORBIDDEN_LIBRARIES["router"] = ("sqlalchemy",)` en
`test_module_boundaries.py`. No es una interpretación: el test falla nombrando archivo y línea, y
lo encontró el `Tester` al escribir los tests contra una implementación de referencia.

La corrección es el alias, no la excepción: el tipo se declara **una vez** en el kernel y el router
escribe `session: SessionDep`, sin nombrar SQLAlchemy nunca. La frontera queda literal —el router
no conoce el ORM— y el service sigue recibiendo una `AsyncSession` tipada. `app/db.py` ya es el
archivo que expone `get_session` para inyectar, así que el alias vive donde ya vivía su mitad.

Esto **no es sólo de `auth`**: `auth/router.py` es el primer router del proyecto, así que la
decisión la heredan los routers de `002` y `003`. Se arregla la frontera, no la regla (Artículo IV).

`_bearer = HTTPBearer(auto_error=False)` — privado del archivo (`PY-10`). `auto_error=False` a
propósito: con el automático, un `Authorization` ausente responde 403 y uno mal formado responde un
cuerpo que no elegimos. Con `False`, los cuatro modos de falla salen por el mismo 401 con la misma
cabecera, que es lo que `TestRoutesEnforceAuthorization` y el interceptor del frontend esperan.

### El límite de intentos (`RF-21` a `RF-26`)

```python
# app/ratelimit.py  (nuevo; kernel, no conoce ningún módulo y no sabe qué es un login)
class SlidingWindowLimiter:
    def __init__(self, limit: int, window: timedelta, max_keys: int = 10_000) -> None: ...
    def hit(self, key: str) -> None: ...            # registra un evento ahora
    def is_exceeded(self, key: str) -> bool: ...    # ¿la ventana ya está llena?
    def retry_after(self, key: str) -> int: ...     # segundos hasta que entre uno más
    def reset(self, key: str) -> None: ...          # borra la clave

# app/modules/auth/service.py  — el módulo pone los números (SEC-04)
LOGIN_MAX_ATTEMPTS = 10
LOGIN_WINDOW = timedelta(minutes=5)
_login_limiter = SlidingWindowLimiter(limit=LOGIN_MAX_ATTEMPTS, window=LOGIN_WINDOW)
```

**La ventana es deslizante y son los últimos 5 minutos**, no un balde que se vacía de golpe: cada
clave guarda los timestamps de sus fallos y los que ya salieron de la ventana se descartan al leer.
`retry_after(key)` es cuántos segundos faltan para que el más viejo de los que quedan se caiga —o
sea, cuándo vuelve a haber lugar para un intento. La enmienda de la spec dejó esto explícitamente
como decisión técnica y acá queda tomada: **la espera se cuenta desde el décimo fallo verificado**,
y un intento rechazado por el límite no la mueve —no la acorta **ni la alarga**—, porque no se
registra: `authenticate()` levanta `RateLimitedError` **antes** de llamar a `hit()`, así que lo
único que entra al contador es un fallo que llegó a verificar la clave. Son cinco minutos desde el
décimo, y golpear la puerta mientras tanto no cambia el reloj.

Es la lectura que describe el criterio de aceptación firmado de `RF-21` —*"pasados cinco minutos sin
intentar, la clave correcta vuelve a entrar"*— y es la misma que define `retry_after` dos párrafos
arriba, que cuenta desde el más viejo de los fallos que quedan adentro de la ventana. Si la espera
se contara desde el último intento, esos dos párrafos dirían cosas distintas y el criterio firmado
sería falso: insistir movería el vencimiento hacia adelante.

**El orden adentro de `authenticate()` importa y es parte del contrato:**

1. `is_exceeded()` sobre las dos claves — si alguna está llena, `RateLimitedError` y **fin**: no se
   busca el usuario, no se verifica ningún hash (`RF-24`). Es lo que evita que el límite se pague
   con CPU de Argon2, que es justo el recurso que un ataque de fuerza bruta quiere consumir.
2. Buscar el usuario, verificar la clave (con el hash señuelo si no existe).
3. Si falló: `hit()` sobre las dos claves, log, y `AuthenticationError`.
4. Si entró: `reset()` sobre las dos claves (`RF-25`, `RF-26`).

**Las dos claves son `login:ip:<addr>` y `login:user:<username normalizado>`.** La segunda se cuenta
por el nombre **tipeado**, exista o no ese usuario: contar sólo los que existen le diría a un
atacante cuáles son reales por la vía del comportamiento, que es la misma fuga que `RF-06` cierra
por la vía del mensaje.

**El diccionario tiene tope (`max_keys`) y evicción**, y no es un detalle de implementación: un
contador que crece con cada clave distinta es un agotamiento de memoria a pedido —diez mil IPs
inventadas, o diez mil nombres de usuario— o sea la misma categoría de falla que el límite viene a
resolver (OWASP API4). Al escribir se descartan las claves cuya ventana venció, y si aun así se
llega al tope se descarta la más vieja.

**Es un contador por proceso y en memoria.** Se pierde al reiniciar y no se comparte entre réplicas:
hoy `docker-compose.yml` levanta **un** `backend`, así que alcanza. El día que haya dos, el límite
efectivo pasa a ser el doble —degrada, no se rompe— y ahí se discute un contador compartido, que es
una decisión de arquitectura y la firma un humano (Artículo X). Queda escrito para que se lea como
decisión y no como descuido.

**Observabilidad** (OWASP A09, `ERR-03`): cada intento suma al contador `LOGIN_ATTEMPTS` con
`outcome` en `succeeded` / `failed` / `rate_limited`, y cada rechazo por límite deja una línea
`login_rate_limited` con la IP y el usuario tipeado. **Nunca la clave**, ni entera ni en parte.

### El secreto de firma

`JWT_SECRET` entra a `Settings` como `jwt_secret: str = ""` y se suma a `secret_values()`, para que
el scrubber de `app/observability.py` lo tape en logs y en Sentry el día que aparezca en un
traceback.

**El vacío no es un default, es una negativa**: firmar o verificar con un `jwt_secret` vacío o más
corto que 32 caracteres levanta `RuntimeError`. Y lo que no hay es **ningún default en producción**:
`docker-compose.prod.yml` pide la variable con `${JWT_SECRET:?…}`, así que un deploy sin ella no
arranca en vez de firmar con algo adivinable (`SEC-05`).

El compose **local** sí lleva un valor de desarrollo conocido
—`local-development-signing-key-not-a-secret`, escrito ahí y sólo ahí—, y es deliberado: un clon
fresco tiene que poder hacer `make up` y entrar. Es el mismo trato que ya toman las claves de demo
del seed: no vale nada justamente porque lo tiene todo el mundo, y no sale de ese archivo. Lo que
`SEC-05` previene es que un secreto "de desarrollo" termine firmando en producción el día que
alguien se olvida de cambiarlo, y lo que lo previene no es que el valor no exista en ningún lado:
es que producción no lo hereda. Allá no hay un default que olvidar, hay una variable que falta y
detiene el arranque.

La verificación es al **usar**, no al importar, por una razón concreta: `import app.main` tiene que
seguir funcionando sin secreto —lo hacen los tests de arquitectura y el `make types` que exporta el
OpenAPI—, y un request sin token responde 401 antes de necesitar ninguna clave. Para que un deploy
mal configurado no se entere recién en el primer login, el `lifespan` de `main.py` loguea
`jwt_secret_missing` en warning cuando está vacío.

Va a `.env.example`, a `docker-compose.yml` (servicio `backend`), a `docker-compose.prod.yml`
(servicio `backend`) y al `env:` del job de tests de CI.

### OWASP — la revisión completa (`SEC-07`)

Esta es la feature donde se decide la autenticación del sistema entero, así que la lista se recorre
entera y no se contesta con "no aplica" en silencio.

#### API Security Top 10 (2023)

| | Riesgo | Cómo queda acá |
|---|---|---|
| **API1** | BOLA | Ninguna de las dos rutas recibe un identificador de usuario. `/me` responde sobre el `sub` del token y `TestNoRouteAcceptsAUserId` lo verifica estáticamente. |
| **API2** | Autenticación rota | Argon2id para verificar (`SEC-06`); HS256 con `exp` de 60 min y **algoritmo fijado en el decode**; secreto fuera del repositorio; mismo error para usuario inexistente y clave errónea; hash señuelo para que el **tiempo** tampoco enumere usuarios; y ahora el límite de intentos (`RF-21`…`RF-26`), que es el control que le faltaba. Sin "recordarme", sin refresh y sin renovación silenciosa. |
| **API3** | BOPLA | `LoginRequest` con `extra="forbid"`; las respuestas son schemas explícitos y ninguna incluye `password_hash`. `/me` devuelve dos campos, y son los del token. |
| **API4** | Consumo sin límite | Lo cubre el límite de intentos, y de dos formas: corta la fuerza bruta y corta el **gasto de CPU de Argon2**, que es la forma barata de voltear este backend (cada verificación está diseñada para ser cara). Se suma el tope de `max_length` en los campos —un body de un megabyte no llega a hashearse— y el tope de claves del contador, para que el propio limitador no sea el agotamiento de memoria. |
| **API5** | Autorización a nivel función | `/me` declara `get_current_user`; `/login` entra a `PUBLIC_ROUTES` con su motivo escrito. Lo verifica `test_route_authorization.py` en las dos mitades: que lo declare y que un anónimo reciba 401. |
| **API6** | Flujos de negocio sensibles | No aplica: no hay pagos, transferencias ni nada que se pueda automatizar en contra del negocio. Lo más cercano era el login masivo, y eso ya es API2/API4. |
| **API7** | SSRF | No aplica: esta feature no hace ninguna llamada saliente, y la única URL del sistema sigue fija en `app/providers/`. |
| **API8** | Mala configuración | CORS acotado al origen del frontend, sin `*`. El secreto entra a `secret_values()`, así que el scrubber lo tapa. El `detail` de los 401 es genérico y en inglés. **Y acá entran las dos correcciones de infraestructura de abajo**: la confianza en `X-Forwarded-For` y las cabeceras de seguridad que `nginx.conf` no manda. |
| **API9** | Gestión de inventario | No aplica: una versión, un ambiente público. Lo que sí se agrega es lo que A09 del Top 10 web pide y no había: el contador y el log de intentos fallidos, sin los cuales un ataque de fuerza bruta es indistinguible del silencio. |
| **API10** | Consumo inseguro de APIs de terceros | No aplica acá: no se consume nada de terceros en esta feature. |

#### Lo que rompe OWASP si se implementa mal — y que por eso es contrato, no sugerencia

Los seis puntos de acá abajo **no tienen `RF-NN` y no deberían tenerlo**: ninguno cambia lo que el
cliente ve ni lo que la aplicación hace, así que no son alcance funcional sino la forma correcta de
construir lo que la spec ya pide. Responden a `NFR-01`…`NFR-03` del brief y a `SEC-07`, que dice
explícitamente que la lista se recorre **al diseñar el endpoint**, en el `plan.md`. Si alguno
cambiara una pantalla o un mensaje, volvería a la spec.

1. **El algoritmo del token se fija en el decode.** `jwt.decode(..., algorithms=["HS256"])`, siempre
   la lista explícita. Sin eso, un token con `alg: none` o con `alg: RS256` y la clave pública como
   secreto es la vulnerabilidad clásica de JWT, y convierte la autenticación en decoración. Se
   exigen además los claims (`require=["exp", "iat", "sub"]`) y se verifica `exp`: un token sin
   vencimiento no puede ser aceptado por omisión.
2. **El secreto de firma tiene largo mínimo.** Firmar HS256 con `"dev"` es no firmar: se levanta
   `RuntimeError` si `jwt_secret` está vacío **o mide menos de 32 caracteres**. Un secreto corto es
   fuerza bruta offline sobre cualquier token capturado.
3. **La IP del cliente tiene que ser la IP del cliente.** ✅ **La mitad de infraestructura ya está
   aplicada** (2026-09-13, en esta rama). Estaba rota en tres lugares a la vez: `backend/Dockerfile`
   corría uvicorn con `--forwarded-allow-ips "*"` —y con `*` uvicorn toma el elemento de **más a la
   izquierda** de `X-Forwarded-For`, que es exactamente el que escribe el cliente—, mientras
   `frontend/nginx.conf` usaba `proxy_add_x_forwarded_for`, que **agrega** a lo que el cliente mandó
   en vez de reescribirlo. Así las cosas, el límite por dirección de red se salteaba con una
   cabecera inventada, y los logs de `ADR-009` ya hoy atribuyen los pedidos a quien el atacante
   diga. Lo aplicado: nginx resuelve la IP real en un `map` —`CF-Connecting-IP` en producción, que
   es el mismo criterio que `docker-compose.prod.yml` ya usa para Grafana, y `$remote_addr` cuando
   no hay Cloudflare adelante— y **reescribe** `X-Forwarded-For` y `X-Real-IP` con ese único valor;
   el `CMD` acota la confianza a `127.0.0.1` más los rangos RFC1918. **Lo que falta es la mitad de
   aplicación**, y es de la implementación de esta feature: leer la IP en **un solo lugar** —un
   helper del router— desde `request.client.host`, ya normalizada por el middleware, y el test que
   fija que una `X-Forwarded-For` forjada no cambia la clave del contador.
4. **Cabeceras de seguridad en el servidor que sirve el formulario de login.** ✅ **Aplicado**
   (2026-09-13). `nginx.conf` no mandaba ninguna, y es el que sirve la pantalla de ingreso: sin
   `frame-ancestors 'none'` se la puede embeber en un iframe ajeno, que es clickjacking sobre un
   formulario de credenciales. Van `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`,
   `Referrer-Policy: no-referrer` y una CSP con `default-src 'self'`, `frame-ancestors 'none'`,
   `base-uri 'self'` y `form-action 'self'`. **La trampa de nginx se resolvió de raíz**: como un
   `add_header` adentro de un `location` descarta todos los del `server`, el `Cache-Control` de
   `/assets/` y de `index.html` pasó a un `map $uri $cache_control` y ahora hay **un solo
   `add_header` en todo el archivo**, a nivel `server` y con `always`. Verificado contra respuestas
   reales, no contra el archivo.

   Dos cosas para el review, que salieron de aplicarlo: `location /assets/` se conservó con
   `try_files $uri =404` —sacarlo hacía que un bundle faltante cayera en el fallback de la SPA y
   devolviera `index.html` con 200 en lugar de 404, o sea HTML servido como JavaScript—, y un 404
   bajo `/assets/` ahora sale con el `Cache-Control` inmutable, efecto lateral de `always` que se
   acepta porque esas URLs están hasheadas por contenido y no se vuelven a pedir.

   Y una nota para `003`: la CSP lleva `style-src 'self' 'unsafe-inline'` porque Highcharts inyecta
   estilos inline. Si esa feature no lo necesitara, se aprieta.
5. **El token no se loguea nunca.** Ni la cabecera `Authorization`, ni el `access_token` de la
   respuesta. `scrub_secrets` tapa lo que está en `secret_values()`, que son secretos de
   configuración: un token de sesión no pasa por ahí, así que esto es disciplina y es del review.
6. **La clave no se loguea nunca, ni siquiera su largo.** El log de un intento fallido lleva usuario
   e IP, y nada más.

#### Lo que se acepta, dicho de frente

- **El token en `sessionStorage` es alcanzable por un XSS.** Lo decidió `ADR-004` con su alternativa
  (cookie `HttpOnly`) escrita, y no se reabre en este plan. La CSP del punto 4 sube el costo de un
  XSS; el `exp` de 60 minutos acota la ventana.
- **El aviso de arranque no cubre un secreto corto.** El `lifespan` avisa cuando `JWT_SECRET` está
  vacío, no cuando mide menos de 32 caracteres: ese caso se descubre en el primer login, y lo
  descubre el `RuntimeError` que impide firmar, no un 200 con una firma débil. Aceptado el
  2026-09-13; el hueco exacto y cómo se cierra están en *Riesgos*.
- **No hay revocación**: un token robado sirve hasta que vence. Es la contracara conocida de un JWT
  sin estado, y está asumida en `ADR-004`.
- **El límite por usuario permite una molestia dirigida**: alguien puede quemar los diez intentos de
  `juan` y dejarlo cinco minutos afuera. Es el precio de que el control exista, es acotado y se
  levanta solo — a diferencia del bloqueo de cuenta, que en una aplicación sin recuperación de clave
  no se levanta nunca. Por eso el límite por IP es el control principal y el de usuario el
  secundario.

### Frontend — estructura y contrato de pantalla

```
src/
├── App.tsx                    las rutas y el SessionProvider alrededor
├── api/
│   ├── client.ts              fetch con base /api, Bearer, y el punto donde se engancha el 401
│   ├── auth.ts                login() y fetchMe(), tipados desde schema.d.ts
│   └── schema.d.ts            GENERADO por `make types` — no se edita a mano (TS-03)
├── auth/
│   ├── storage.ts             sessionStorage: { token, fullName, expiresAt }
│   ├── session.ts             el contexto y useSession()
│   ├── SessionProvider.tsx    restaura del storage, expone logIn/logOut, registra el interceptor
│   └── RequireSession.tsx     guarda de ruta → <Navigate to="/login" replace />  (RF-09)
├── components/
│   └── Header.tsx             `Mis Acciones` | `Usuario: {nombre}` · `Cerrar sesión`
└── pages/
    ├── Login.tsx              wireframe 01
    ├── MyActions.tsx          wireframe 02 — SÓLO la cabecera en esta feature
    └── HealthPage.tsx         ya existe; pasa de ser la raíz a colgar de /health
```

**El `Router` va en `main.tsx`, envolviendo a `<App />`, y no adentro de `App`.** Es lo que permite
abrir una URL en un test montando `App` dentro de un `MemoryRouter`; con el router adentro de `App`,
`RF-09` —cuyo criterio de aceptación es *pegar la dirección en el navegador*— no se puede verificar
sin levantar un navegador. Lo planteó el `Tester` al escribir los tests y queda ratificado acá.

Las rutas: `/login` pública, `/` protegida (es `Mis Acciones`), `/health` pública, y cualquier otra
redirige a `/`. `/` es la raíz a propósito: el enunciado no da direcciones, y traducir "Mis
Acciones" a un slug obliga a elegir entre un spanglish (`/mis-acciones`) y un nombre que no es el
de la pantalla. `003` cuelga el detalle de `/stocks/:symbol`, que sí tiene un nombre natural.

**El estado de la sesión**, en `useSession()`:

```ts
status: 'loading' | 'authenticated' | 'anonymous'
user: { fullName: string } | null
token: string | null        // la credencial con la que viaja toda llamada autenticada
expired: boolean            // RF-17: se llegó a /login por vencimiento
logIn(username, password): Promise<void>   // lanza si la credencial no sirve
logOut(): void                             // RF-19, RF-20
```

`loading` existe por el arranque: al montar, si hay token guardado se llama a `fetchMe()` y recién
entonces se decide. Sin ese estado, un F5 mostraría el login por un instante antes de volver a
`Mis Acciones` (`TS-06`).

**`token` está en el contrato aunque en esta feature ninguna pantalla lo lea**, y es una decisión,
no un descuido. Toda llamada autenticada viaja con `Authorization: Bearer`, y `api/client.ts` recibe
el token **por llamada** (`request(path, { token })`): alguien tiene que dárselo, y ese alguien es
el contexto. La alternativa —que la pantalla lo saque de `sessionStorage` por su cuenta— deja dos
fuentes de verdad, y no son equivalentes: el provider sabe si ese token lo confirmó `/me` o si su
`expiresAt` ya pasó, y el storage no sabe nada, así que una pantalla podría presentar un token que
el provider ya descartó. Declararlo acá fija que la credencial sale del único lugar que conoce el
estado de la sesión.

Hoy el único que lo escribe y el único que lo usa es `SessionProvider`, que se lo pasa a `fetchMe()`
desde su propio estado; el primer consumidor de afuera es `002`, la feature que tiene llamadas que
autorizar. Es superficie sin consumidor por una feature, y se paga igual porque es un campo de
lectura, sin comportamiento, y porque el día que `002` lo necesite el lugar donde buscarlo ya está
decidido. No sale del navegador salvo en la cabecera `Authorization` —nunca en una URL, que es lo
que `api/client.ts` ya tiene escrito—.

**El interceptor de 401** vive en `src/auth/` y `api/client.ts` sólo le da el punto de enganche
(`setUnauthorizedHandler`), porque la corrección es una sola para toda la aplicación: limpiar el
almacenamiento, marcar `expired` y mandar a `/login` (`RF-17`). **El login se exceptúa
explícitamente**: su 401 significa `usuario o clave invalida`, no sesión vencida, y si pasara por
el interceptor la pantalla se recargaría en vez de mostrar el error.

**Los textos**, los doce, todos verbatim de `docs/design/COPY.md` (`UI-02`): `Usuario`, `Ingresar
nombre de usuario`, `Clave`, `Ingresar`, `usuario o clave invalida`, `Completá este campo.`, `Tu
sesión expiró. Volvé a ingresar.`, `Demasiados intentos. Probá de nuevo en unos minutos.`, `No
pudimos conectarnos con el servidor. Intentá de nuevo en unos minutos.`, `Mis Acciones`, `Usuario:
{nombre completo}`, `Cerrar sesión`.

**El orden de la validación** (`RF-12`, `RF-13`, `RF-23`, `RF-27`, y `COPY.md` es explícito en que
los avisos no conviven): son **cuatro**, excluyentes, y al apretar `Ingresar` se resuelven en este
orden, que es el que fija el copy:

1. **Campo vacío** → `Completá este campo.` debajo de cada vacío, y **no se llama a la API**
   (`RF-13`).
2. **429** → `Demasiados intentos. Probá de nuevo en unos minutos.` (`RF-23`).
3. **No hubo respuesta que leer** —la llamada falló sin un error de nuestra API— → `No pudimos
   conectarnos con el servidor. Intentá de nuevo en unos minutos.` (`RF-27`).
4. **401** → `usuario o clave invalida` (`RF-04`).

El orden no es arbitrario, y es el argumento de `RF-27`: en los tres primeros la credencial **no
llegó a validarse** —el campo vacío nunca se envió, el límite se responde sin mirarla, y sin
respuesta no hay nada que haya sido evaluado—, así que ninguno puede afirmar nada sobre ella.
`usuario o clave invalida` queda último porque es el único que sí afirma algo sobre lo que la
persona tipeó, y decirlo cuando la falla es del sistema la manda a cambiar una clave que estaba
bien.

El aviso de sesión vencida (`RF-17`) no es uno de los cuatro: habla de la sesión anterior, no del
intento que se acaba de hacer, y por eso cede en cuanto aparece cualquiera de ellos.

El 429 **tampoco** pasa por el interceptor de sesión: no es una sesión vencida, es un intento
rechazado, y la pantalla tiene que quedarse donde está mostrando el aviso.

El wireframe 01 no tiene título de página ni logo, y no se agregan (`UI-01`). El campo de clave es
`type="password"` (`RF-02`).

## Alternativas descartadas

**`react-router` vs. un ruteo propio con estado.** Un `useState<'login' | 'stocks'>` no agrega
dependencias y alcanza para mostrar dos pantallas. Se descarta porque `RF-09` se verifica *pegando
la dirección de `Mis Acciones` en el navegador*, y `RF-20` y `RF-19` describen navegación: sin URLs
reales esos criterios de aceptación no son escribibles. Además `002` (`REQ-11`: el símbolo es un
link al detalle) y `003` necesitan lo mismo, así que el ruteo se paga una vez acá o dos veces
después.

**`openapi-typescript` + `make types` vs. escribir los tipos a mano.** Escribir
`interface LoginResponse` a mano cuesta cuatro líneas y cero dependencias. Se descarta porque
`TS-03` dice lo contrario —los tipos de la API se generan del OpenAPI— y porque el target `make
types` que la convención nombra todavía no existía: esta feature es la primera que consume un
endpoint de dominio, así que es donde el mecanismo se paga. `frontend/src/api/health.ts`, que es
anterior y está escrito a mano, **queda como está**: migrarlo es alcance de otra cosa.

**Y una excepción a `DEP-03`, decidida por el humano el 2026-09-13, que el review no tiene que
volver a discutir.** `openapi-typescript` declara peer `typescript@^5` y el proyecto está en TS 6,
así que `npm install` falla con `ERESOLVE`. Se resuelve con un bloque en `package.json`:

```json
"overrides": { "openapi-typescript": { "typescript": "$typescript" } }
```

`DEP-03` prohíbe editar a mano **los números de versión**, y esto no escribe ninguno: `$typescript`
referencia la versión que el propio proyecto ya declara, así que no hay un segundo lugar que se
desincronice. Se descartaron las dos alternativas: bajar TypeScript a 5.x —resignar la versión del
proyecto para acomodar a una herramienta que sólo genera tipos— y `legacy-peer-deps` en `.npmrc`,
que apaga la resolución de peers para **toda** dependencia futura y en silencio. Verificado que
`npm ci`, que es lo que corre el CI, funciona con esto.

**`sessionStorage` vs. `localStorage` vs. cookie `HttpOnly`.** Ya lo decidió `ADR-004` y no se
reabre acá: `sessionStorage` con el token en memoria, refrescado al montar. El plan sólo agrega
que junto al token se guardan `fullName` y `expiresAt`, para que un F5 pinte la cabecera sin
esperar la respuesta de `/me`.

**`GET /api/auth/me` vs. decodificar el JWT en el navegador.** Leer el payload con `atob` evita un
request por carga de página. Se descarta porque pone al cliente a interpretar un token que no puede
verificar: un `exp` leído del propio token dice cuándo *dice* vencer, no si la firma sigue siendo
válida ni si el secreto rotó. Un request barato contra nuestra propia API (no contra el proveedor:
el Artículo II no está en juego) lo resuelve con la autoridad correcta.

**Un handler genérico `DomainError` → HTTP en `main.py` vs. uno por tipo.** Un mapa
`{tipo: status}` escala solo, pero hoy tiene una entrada y esconde la traducción detrás de una
tabla. Se registra un handler por tipo, explícito, y `002` agrega el suyo (`GEN-10`: KISS gana por
defecto).

**Devolver el texto de pantalla desde la API.** Sería una sola fuente para `usuario o clave
invalida`. Se descarta por dos motivos: `UI-02` verifica el literal **en `frontend/src`** con un
test que rompe el build, y el Artículo VIII pone los mensajes de la API en inglés. La API dice qué
pasó; la pantalla dice cómo se cuenta.

**Para el límite de intentos: bloqueo de cuenta, contador en Postgres, o `slowapi`/Redis.**

*Bloqueo de cuenta tras N fallos* es lo que la spec original listaba fuera de alcance, y es lo que
pide el reflejo. Se descarta por dos razones que no son de estilo: la aplicación no tiene alta ni
recuperación de clave (`A1`), así que una cuenta bloqueada no tiene forma de volver sin que alguien
entre a la base; y convierte el control en un arma — cualquiera deja afuera a cualquiera tipeando
mal a propósito. Una espera que se levanta sola no tiene ninguno de los dos problemas.

*Contador en Postgres* (una tabla `login_attempts`) sobrevive reinicios y funciona con varias
réplicas. Se descarta porque es una tabla nueva —decisión de arquitectura que firma un humano,
Artículo X— y porque pone una escritura en la base **por cada intento fallido**: el ataque que el
control frena pasaría a ser un ataque de escritura contra la base. El modelo de datos son cuatro
tablas y una quinta se justifica, no se agrega (`ADR-001`).

*`slowapi`, `limits` o Redis* resuelven esto sin escribirlo. Se descartan por lo mismo que `ADR-001`
descartó Redis —un servicio más para lo que ya se puede hacer sin él— y porque las tres traen
dependencia nueva para sesenta líneas de contador. `slowapi` además es un middleware por ruta, y lo
que hace falta acá no es "N requests por minuto a este endpoint" sino contar **fallos** por dos
claves distintas y limpiarlas en el éxito: es política de negocio, y por eso vive en el service.

*Un middleware global de rate limiting para toda la API.* Es más prolijo de un lado y mentiroso del
otro: no distingue un intento fallido de uno exitoso, así que castigaría a quien entra bien. Cuando
`002` y `003` necesiten techo propio, el limitador del kernel ya está y sólo hay que darle claves.

## Riesgos

| Riesgo | Impacto | Cómo se mitiga |
|---|---|---|
| `JWT_SECRET` sin setear en un entorno: la app arranca sana y falla recién en el primer login | El health queda verde y el login responde 500 | El `lifespan` loguea `jwt_secret_missing` en warning al arrancar, y la variable entra a `.env.example`, a `docker-compose.yml` y al CI en la misma tarea. Un test fija que firmar con secreto vacío levanta `RuntimeError` y no firma con `""` |
| **`JWT_SECRET` no vacío pero más corto que 32 caracteres: arranca sin ninguna advertencia** | El login responde 500 en el entorno donde menos se lo espera, y `${JWT_SECRET:?…}` de producción no lo tapa: exige que la variable **esté**, no que **mida** | **Riesgo aceptado** — Leandro Carriego, 2026-09-13, y no se cambia código. El warning del `lifespan` sólo mira el vacío (`if not settings.jwt_secret`) porque se escribió antes de que existiera el mínimo de 32 caracteres, y nunca se lo extendió: por eso la fila de arriba dice "al arrancar" y en este caso no avisa nada. Lo que lo atrapa igual es el `RuntimeError` del primer login, que es ruidoso y no silencioso: no firma con un secreto débil, corta. **La salida, el día que se quiera cerrar:** cambiar esa condición del `lifespan` por `if len(settings.jwt_secret) < 32`, con el mismo evento `jwt_secret_missing`, y el `Tester` primero |
| El interceptor de 401 se traga el 401 del login y la pantalla se recarga en vez de mostrar el error | `RF-04` deja de andar de una forma que parece un bug del servidor | El `login()` se salta el interceptor explícitamente, y es un caso de test del `Tester` (401 en login → mensaje; 401 en `/me` → sesión vencida) |
| El nombre completo guardado en `sessionStorage` diverge del token | La cabecera muestra un nombre que no es (`RF-08`) | Sólo es una caché para pintar sin esperar: `/me` responde el claim del token al montar y es el que gana. Es el navegador del propio usuario: no hay escalada posible |
| `func.lower()` no usa el índice único de `username` | Ninguno hoy; sería un problema con muchos usuarios | Dos filas y un solo escritor (el seed). Anotado en *Datos*: el día que exista alta, la normalización se mueve a la escritura |
| El token vencido se detecta sólo al recargar o al primer request | Con `001` sola, alguien puede quedar mirando `Mis Acciones` con la sesión vencida | Es el alcance firmado: la spec descarta renovar sola y descarta cerrar sesión en otras ventanas. Con `002` toda pantalla interna hace requests y el interceptor se dispara |
| `make types` necesita levantar el OpenAPI y podría pedir configuración | Rompe el flujo del Developer | Por eso el secreto se valida al usar y no al importar: `import app.main` no necesita ni base ni secreto |
| **El límite por IP se saltea con una cabecera** (`--forwarded-allow-ips "*"` + `proxy_add_x_forwarded_for`) | El control existe y no controla nada, y los logs atribuyen mal | **Ya aplicado**: nginx reescribe con un único valor y uvicorn acota la confianza a RFC1918 (punto 3 de *OWASP*). Falta la mitad de aplicación: leer la IP en un solo lugar, y el test que fija que una `X-Forwarded-For` forjada no cambia la clave del contador |
| El contenedor `frontend` queda alcanzable sin pasar por Cloudflare | `CF-Connecting-IP` vuelve a ser falsificable, y con él la clave del límite por IP | Hoy sólo lo alcanza Traefik y el backend no publica puertos en producción. Es el mismo supuesto que `docker-compose.prod.yml` ya toma para el rate limit de Grafana: si deja de valer, deja de valer para los dos y se revisa junto |
| Quien evalúa el proyecto se come el límite probando la pantalla | Parece que la aplicación se rompió, en la demo | Diez intentos en cinco minutos es holgado para un tipeo malo; el aviso dice qué pasó y que se espere; la espera es de minutos y se levanta sola. El README lleva las credenciales demo, así que el camino feliz no requiere adivinar |
| El contador en memoria se pierde al reiniciar, y no se comparte entre réplicas | Un atacante con `restart` a mano, o dos réplicas, duplican el techo efectivo | Hoy compose levanta un solo `backend` y nadie reinicia desde afuera. Degrada, no se rompe. Un contador compartido sería una decisión de arquitectura y la firma un humano |
| Las cabeceras de seguridad se agregan en el `server` y los `location` con `add_header` las descartan | Se cree que están y no están; es el modo de falla clásico de nginx | Está escrito en el punto 4 de *OWASP*, y se verifica mirando la respuesta real de `/assets/` y de `/index.html`, no sólo el archivo |

## Contexto de traspaso

**Para el Developer** — Empezá por el kernel, que es de lo que cuelga todo: `app/errors.py` y
`app/ratelimit.py`, después `app/security.py` (constante, `create_access_token`, `CurrentUser`,
`get_current_user`) y `settings.py`. Recién ahí el módulo `auth`, de adentro hacia afuera:
`repository` → `service` → `io` → `router`, y último el `__all__` del `__init__.py` y el montaje en
`main.py`. Las correcciones de infraestructura (`nginx.conf`, el `CMD` del `Dockerfile`) son cuatro
líneas y conviene hacerlas temprano: mientras no estén, el límite por IP no es un límite.

`app/ratelimit.py` no sabe qué es un login. Si te encontrás escribiendo `username` ahí adentro, la
política se te fue de lugar: los números y las claves son del service.

Lo que **no** se toca: `app/modules/auth/models.py` (la tabla ya existe y no lleva migración),
`app/providers/` (esta feature no sale al mundo), `frontend/src/api/health.ts` y el interior de
`HealthPage.tsx` (sólo cambia de dónde cuelga). No agregues un endpoint de registro, ni "recordarme",
ni refresh token: está fuera de alcance y `/converge` lo va a mirar.

Y `COPY.md` suma un texto nuevo **recién cuando se firma la enmienda que lo pide**, no antes: el
cuarto con la primera y el quinto —el de `RF-27`— con la segunda, las dos ya firmadas.

**El router recibe `session: SessionDep`**, el alias de `app/db.py`, y **nunca**
`Annotated[AsyncSession, Depends(get_session)]` escrito a mano: eso importa SQLAlchemy en el router
y `test_module_boundaries.py` lo rechaza en el acto (`PY-06`). Lo mismo vale para el reloj del
limitador: `app/ratelimit.py` lee la hora por un `_now()` de módulo, porque es lo que los tests
reemplazan para dejar pasar la ventana sin un `sleep` de cinco minutos.

Decisiones ya tomadas, que no hay que rediscutir: el token es HS256 a 60 minutos con `sub` y `name`
(`ADR-004`); `get_current_user` vive en `app/security.py` y levanta `HTTPException(401)` porque es
una dependencia del borde HTTP y no un service; el service levanta `AuthenticationError` y `main.py`
la traduce; el mensaje que ve el usuario lo decide la pantalla, no la API; los textos salen verbatim
de `COPY.md`. Y adentro del módulo los archivos se importan por ruta completa
(`from app.modules.auth.service import authenticate`), nunca por `app.modules.auth`.

**Para el Tester** — Lo que puede romperse de verdad, en orden:

1. **La enumeración de usuarios.** Usuario inexistente y clave equivocada tienen que producir
   respuestas idénticas: mismo código, mismo cuerpo, mismas cabeceras (`RF-06`). Es el test que más
   fácil se rompe con un refactor bienintencionado.
2. **El case.** `JUAN`, `Juan` y `juan` entran con la clave correcta (`RF-14`); la clave en
   mayúsculas no entra (`RF-15`). Los dos, en el mismo test parametrizado si se puede.
3. **El token.** Firma válida, firma alterada, token mal formado, token vencido y `Authorization`
   ausente: los cinco responden 401 en `/me`. El vencido se prueba con un `exp` en el pasado, no
   esperando una hora. Y dos que son de seguridad y no de tipos: un token con **`alg: none`** y uno
   firmado con **otro algoritmo** se rechazan; un secreto vacío o más corto que 32 caracteres
   levanta `RuntimeError` al firmar.
4. **El límite de intentos**, que es la parte nueva y la que tiene más formas de salir mal:
   - Diez fallos desde la misma IP → el once responde 429 con `Retry-After` (`RF-21`); ídem por
     usuario (`RF-22`).
   - **Con el límite activo no se verifica la clave** (`RF-24`): el test tiene que probar que ni
     siquiera la clave **correcta** entra mientras la ventana está llena, y que no se llamó a
     `verify_password`.
   - Un ingreso exitoso limpia las dos claves (`RF-25`, `RF-26`): nueve fallos, un éxito, y vuelve
     a haber diez intentos disponibles.
   - Un **usuario inexistente** tipeado diez veces también cuenta: si no, el comportamiento
     enumera usuarios y `RF-06` queda inútil por el otro lado.
   - Pasada la ventana, la clave correcta vuelve a entrar. Con reloj inyectado o `monkeypatch`,
     **nunca** con un `sleep` de cinco minutos.
   - **Una `X-Forwarded-For` inventada no cambia la clave del contador.** Este es el test que
     convierte el punto 3 de *OWASP* en algo que no se puede desarmar sin que rompa.
   - El contador no crece sin techo: superado `max_keys`, la memoria no sigue subiendo.
5. **La ruta protegida.** `TestRoutesEnforceAuthorization` dejó de ser vacuo con `/api/auth/me`:
   si ese test sigue corriendo sobre una lista vacía, el router no quedó montado.
6. **`PUBLIC_ROUTES`** suma `POST /api/auth/login` con su motivo escrito. Sin eso,
   `test_route_authorization.py` falla, y ese es el comportamiento correcto.
7. **Frontend:** el orden de la validación, que son **cuatro** avisos y nunca dos a la vez (campo
   vacío → `Completá este campo.` y **sin** llamada a la API; límite activo → `Demasiados intentos.
   Probá de nuevo en unos minutos.`; sin respuesta que leer → `No pudimos conectarnos con el
   servidor. Intentá de nuevo en unos minutos.`, y **no** `usuario o clave invalida`, que es todo
   `RF-27`; credencial mala → `usuario o clave invalida`), el 401 y el 429 del login que
   **no** disparan el interceptor, el F5 que sobrevive, la ruta protegida abierta sin sesión que
   cae en `/login` (`RF-09`), y `Cerrar sesión` que deja `/` mostrando el login (`RF-19`,
   `RF-20`).

**Nada de esto sale a la red** (`TEST-03`): no hay proveedor en el camino, así que no hace falta
JSON fijado en esta feature. Lo que sí hace falta es base: los tests de `/login` usan la fixture
`session` de `tests/conftest.py`, que trunca las cuatro tablas y hace rollback.

Dos suites del frontend **nacen acá** porque `001` es la primera feature con pantallas de verdad, y
las dos rompen el build (`CONVENTIONS.md` → *Convenciones verificadas por un test*):
`frontend/tests/copy.test.ts` (`UI-02`, los literales contra `COPY.md`) y
`frontend/tests/tokens.test.ts` (`UI-03`, ningún color escrito a mano).

**Para el Code-Reviewer** — Dónde mirar primero:

- **`app/modules/auth/__init__.py`**: tiene que ser docstring, imports y `__all__ = ["router"]`
  literal. Nada más, y nada más exportado (`GEN-02`).
- **`app/errors.py`** y **`app/ratelimit.py`**: no importan `fastapi` ni nada de `app/modules/`
  (`GEN-03`). El limitador no nombra `login` ni `username` en ningún lado: si lo hace, la política
  se filtró al kernel.
- **El orden adentro de `authenticate()`**: el chequeo del límite va antes de tocar la base y antes
  de `verify_password` (`RF-24`). Si está después, el control no protege el recurso que tenía que
  proteger.
- **Los cuatro puntos de infraestructura de *OWASP***: `algorithms=["HS256"]` explícito en el
  decode, largo mínimo del secreto, `X-Forwarded-For` reescrito y la confianza de uvicorn acotada,
  y las cabeceras de seguridad efectivamente presentes en la respuesta —no sólo en el archivo—
  incluidos los `location` que ya usaban `add_header`.
- **Ningún log con la clave ni con el token**, y el `detail` de los 401 igual en los dos casos.
- **`app/modules/auth/service.py`**: no importa `fastapi` ni levanta `HTTPException`; no importa
  SQLAlchemy el router (`PY-06`, `ERR-04`).
- **`test_route_authorization.py`**: `POST /api/auth/login` en `PUBLIC_ROUTES` con motivo escrito, y
  ninguna ruta nueva aceptando `user_id` (`PY-08`, `GEN-09`, Artículo III).
- **El secreto**: `jwt_secret` aparece en `settings.py` y en `secret_values()`, y en ningún log;
  **producción no tiene default** —`docker-compose.prod.yml` lo pide con `${JWT_SECRET:?…}`— y el de
  desarrollo sigue siendo el valor conocido y confinado al compose local, sin copias en ningún otro
  archivo; está en `.env.example` (`SEC-02`, `SEC-03`, `SEC-05`).
- **Frontend**: los literales exactos contra `COPY.md`, incluida la falta de tilde en `usuario o
  clave invalida` (`UI-02`); los cuatro avisos del ingreso excluyentes y en el orden del copy, el de
  `RF-27` incluido; la pantalla contra `wireframes/01-login.png`, sin título ni logo
  agregados (`UI-01`); ningún color a mano y ningún `style={{}}` (`UI-03`, `UI-07`); ningún `any`
  (`TS-02`); `schema.d.ts` generado y no editado (`TS-03`).
- **Dependencias**: `package.json` y `package-lock.json` en el mismo commit, y `react-router` y
  `openapi-typescript` instalados con `npm install`, no escritos a mano (`DEP-03`).

Las dos de siempre siguen en juego: la frontera (Artículo IV) y los nombres (`PY-10`) — `_bearer` y
`_absent_user_hash` son privados del archivo, `ACCESS_TOKEN_TTL` es constante de módulo en
mayúsculas, y `CurrentUser` y `AuthenticatedUser` son dos clases distintas a propósito: la primera
es la identidad que sale del token y la ve todo el sistema, la segunda es el resultado interno de
autenticar y no sale del módulo.
