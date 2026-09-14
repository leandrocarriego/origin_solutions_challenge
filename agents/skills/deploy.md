# Skill — Desplegar a producción

Tags: [deploy] [release]

Rol dueño: **Release-Manager**.

## Objetivo
Llevar a producción lo que ya está mergeado en `main`, verificarlo contra el dominio real, y
dejar encadenado el archivado de la spec que el deploy habilita.

La fuente ejecutable es **`scripts/deploy.sh`** (`make deploy`). Esta skill no lo reimplementa:
dice cuándo se corre, qué se verifica antes y después, y qué hacer cuando falla. Si el script y
este documento se contradicen, gana el script — es lo que efectivamente corre.

## Cuándo usarla
- Después de que el PR de una feature se mergeó a `main`, para publicar el cambio.
- Antes de archivar una spec: `docs/specs/archive/` significa *"está en producción"*, así que el
  archivado es posterior al deploy y no al merge (`ship_changes.md` → paso 6).
- Cuando cambió la configuración del servidor (una variable nueva en `docker-compose.prod.yml`) o
  la imagen de un servicio, aunque el código de la aplicación no se haya tocado.
- NO para verificar un cambio propio antes del merge: para eso está `docker compose up --build`
  en local. Producción no es un entorno de prueba.

## Precondiciones (verificarlas antes de tocar el servidor)

- El cambio **está en `origin/main`**: mergeado por PR, con el gate del `Code-Reviewer` pasado.
  Un riesgo de deploy que marcó el review se resuelve antes, no después
  (`agents/roles/release_manager.md`).
- `git fetch origin` corrido, y `origin/main` es el commit que se quiere publicar.
- Acceso SSH al host (`mendri` por defecto, o `DEPLOY_HOST`), verificado con `ssh mendri true`.
- El `.env` **del servidor** tiene todas las variables obligatorias. Ver el paso 1: es el chequeo
  que más veces aborta un deploy, y el que más barato sale hacer antes.
- Confirmación explícita del usuario. El deploy es hacia afuera, como el push y el PR.

## Reglas (ESTRICTO)

- **Sale `origin/main`, nunca el working tree.** El script lo fija en `DEPLOY_REF` y sincroniza
  desde un `git archive` del ref, no desde el directorio: el árbol es donde vive el trabajo en
  curso, y deployarlo pone en producción código que no está en ninguna rama, que ningún CI vio y
  que ningún reviewer leyó. Si tu `HEAD` no es `origin/main`, el script avisa y sigue con
  `origin/main`: el aviso no es un error, es el recordatorio de que lo que estás mirando no es lo
  que sale.
- **El `.env` del servidor no se versiona ni se sobreescribe.** `rsync` corre con `--delete` y lo
  excluye a propósito: los secretos viven sólo ahí (Artículo I). Un secreto nuevo se genera **en
  el servidor**, no se escribe en una terminal local ni se pega en un chat.
- **La limpieza es siempre acotada a este proyecto.** El VPS está compartido con otros seis
  proyectos en producción: un `docker system prune -a` borra sus imágenes y su caché de build, que
  es tirar la máquina abajo por otra puerta. El script filtra por
  `label=com.docker.compose.project` y por `reference=origin-solutions-challenge-*`.
- **No hay seed en producción, y es deliberado.** `SEED_ON_START` no está en
  `docker-compose.prod.yml` y `backend/seed.py` se niega a correr cuando el entorno es
  `production`: las contraseñas que escribe están en el repositorio. Consecuencia que hay que
  asumir: **una base recién desplegada no tiene usuarios.**
- **Un hash de contraseña no se calcula a mano.** Crear un usuario en producción se hace con
  `hash_password` del propio proyecto (Argon2id, `backend/app/security.py`), ejecutado dentro del
  contenedor. Un hash traído de afuera es un formato que nadie verificó contra el verificador real.
- **Si algo falla, abortar antes de tocar lo que ya está corriendo.** El script corre con
  `set -euo pipefail` y hace el `pull` de las imágenes externas en su propio paso: si la red se
  cae, se cae ahí y lo que está levantado sigue levantado.

## Pasos (ORDEN OBLIGATORIO)

### 1) Pre-vuelo de las variables del servidor

Antes de sincronizar nada, comprobar que el `.env` **del servidor** tiene las cinco variables que
`docker-compose.prod.yml` exige o consume:

```bash
ssh mendri "grep -o '^[A-Z_]*' /srv/projects/mendri/origin-solutions-challenge/.env | sort"
```

Tres llevan `${VAR:?...}` en el compose y **el compose se niega a levantar sin ellas**, a
propósito: `POSTGRES_PASSWORD`, `JWT_SECRET` y `GRAFANA_ADMIN_PASSWORD`. `DOMAIN` y `VERSION` las
exporta el script. `TWELVEDATA_API_KEY` y `SENTRY_DSN` admiten vacío.

`JWT_SECRET` es el que más veces falta, porque es el que no tiene default en ningún entorno
(`ADR-007`, `SEC-05`) y el `.env` del servidor puede ser anterior a que se agregara. El `:?` está
ahí justamente para que el deploy aborte en vez de arrancar: el secreto se valida al usarse y no
al importarse, así que sin él el servicio levanta, contesta health en verde y recién revienta en
el primer login — el peor de los tres entornos donde enterarse.

Si falta, se genera **en el servidor**, con backup del `.env` previo:

```bash
ssh mendri "cd /srv/projects/mendri/origin-solutions-challenge && \
  cp .env .env.bak.\$(date +%Y%m%d%H%M%S) && \
  printf 'JWT_SECRET=%s\n' \"\$(openssl rand -base64 48)\" >> .env"
```

El valor no pasa por la terminal de nadie ni queda en un historial local: se genera donde se usa.

### 2) Confirmar qué sale

```bash
git fetch origin
git log -1 --oneline origin/main
```

Mostrarle al usuario ese commit y **pedir confirmación**. Es lo que va a producción.

### 3) Deployar

```bash
make deploy
```

Lo que hace `scripts/deploy.sh`, en orden:

1. **Resuelve el ref** (`origin/main`), saca `VERSION` (el short SHA, que etiqueta las imágenes) y
   el asunto del commit. Si el ref no existe, aborta sin tocar el servidor.
2. **Sincroniza** un `git archive` del ref por `rsync -az --delete`, excluyendo `.git/`, `.env`,
   `node_modules/`, `.venv/`, `dist/` y las cachés. Desde el export y no desde el directorio, así
   un archivo sin trackear no llega a producción por accidente; con `--delete`, así el destino
   queda idéntico al origen y no se acumula basura de deploys anteriores.
3. **Baja las imágenes externas** (`pull --ignore-buildable`) en un paso propio.
4. **Construye y levanta** con `up -d --build --remove-orphans`. El `--build` no es un detalle:
   reconstruye las imágenes con el código sincronizado. Sin él, el contenedor sigue corriendo la
   imagen vieja — es lo que pasó con las cabeceras de seguridad de `frontend/nginx.conf`, que
   estaban en el repositorio y **no** en el servidor. Un endurecimiento que no se rebuildeó no
   existe.
5. **Espera health**: hasta 30 intentos contra el healthcheck del contenedor `backend`. Si no
   llega, imprime las últimas 40 líneas de su log y sale con error.
6. **Limpia** las imágenes viejas **de este proyecto**, en tres pasadas: por label de compose, las
   dangling con `reference=`, y las etiquetadas con un commit anterior — que no son dangling, así
   que sin esa tercera pasada cada deploy dejaba atrás la versión anterior. `docker rmi` se niega
   a borrar una imagen que un contenedor está usando, que es la red de seguridad del filtro.

El backend corre `alembic upgrade head` en su entrypoint, así que el esquema nunca queda atrás del
código: no hay un paso de migración aparte.

### 4) Verificar contra el dominio real

**Contra el dominio, no contra el archivo del repositorio.** Lo que importa es qué contesta
producción, no qué dice el código que debería contestar.

```bash
# La versión desplegada tiene que ser el short SHA del paso 2.
curl -fsS https://origin-solutions-challenge.leandrocarriego.com/api/health

# Las cabeceras de seguridad, en la respuesta real.
curl -sI https://origin-solutions-challenge.leandrocarriego.com/ | \
  grep -i 'content-security-policy\|x-content-type-options\|x-frame-options\|referrer-policy'
```

`/api/health` contesta `{"status","database","version"}` — 200 si la base responde, 503 si no. Si
`version` no coincide con el `VERSION` del paso 2, lo que está corriendo no es lo que creés que
desplegaste: casi siempre es una imagen que no se reconstruyó.

Y el smoke test de autenticación, que son cuatro llamadas y cubren el camino feliz y los tres
rechazos:

```bash
BASE=https://origin-solutions-challenge.leandrocarriego.com

# 200 y un token, con una credencial válida.
curl -s -o /dev/null -w '%{http_code}\n' -X POST "$BASE/api/auth/login" \
  -H 'Content-Type: application/json' -d '{"username":"...","password":"..."}'

# 401 sin token.
curl -s -o /dev/null -w '%{http_code}\n' "$BASE/api/auth/me"

# 401 con la contraseña equivocada, y el MISMO 401 con un usuario inexistente:
# una respuesta distinta diría cuáles de los dos nombres existen.
```

### 5) Crear el primer usuario, si la base es nueva

Sólo cuando hace falta, y como acto explícito. Con `hash_password` del proyecto, adentro del
contenedor:

```bash
ssh mendri "cd /srv/projects/mendri/origin-solutions-challenge && \
  docker compose -f docker-compose.prod.yml exec -T backend \
  python -c \"from app.security import hash_password; print(hash_password('<clave>'))\""
```

y el `INSERT` con ese hash sobre la tabla de usuarios. Nunca un hash calculado con otra
herramienta: el formato lo define Argon2id como lo configuró este proyecto, y el único verificador
que cuenta es el suyo.

### 6) Archivar la spec

Con el cambio ya en producción y verificado, recién ahí se archiva la spec de la feature:
`ship_changes.md` → paso 6. Es un changeset propio, con su rama (`chore/archive-<NNN-feature>`),
su commit y su PR — nunca directo a `main` (`GIT-01`).

Este paso es la razón por la que el deploy tiene skill propia: sin él, `docs/specs/` deja de poder
leerse como "esto es lo que todavía no está desplegado".

## Validación

El deploy está terminado cuando las cinco cosas son verdad:

- [ ] `scripts/deploy.sh` terminó con `==> Listo: https://<dominio>` y sin error.
- [ ] `curl https://<dominio>/api/health` devuelve 200 con `"database":"ok"` y con `version` igual
      al short SHA de `origin/main`.
- [ ] Las cuatro cabeceras de seguridad aparecen en la respuesta real de `/`.
- [ ] El smoke test de autenticación da 200 en el login válido y 401 en los tres rechazos.
- [ ] La spec de la feature está archivada, o su changeset de archivado está abierto como PR.

## Errores comunes (evitar)

- **Deployar el working tree.** Es lo que el script impide por diseño; el error equivalente que sí
  se puede cometer es pasarle `DEPLOY_REF` apuntando a una rama local.
- **Deployar antes del merge.** El deploy es posterior al PR, no un atajo para ver algo andando.
- **Dar por bueno el deploy porque el script terminó.** El script verifica el healthcheck del
  contenedor; el dominio, las cabeceras y el login los verifica el paso 4.
- **Verificar una cabecera leyendo `frontend/nginx.conf`.** El archivo no es la respuesta: entre
  los dos está el rebuild de la imagen.
- **Correr `docker system prune -a`** o cualquier limpieza sin filtro en el host. Hay otros seis
  proyectos en esa máquina.
- **Correr el seed en producción**, o "arreglar" su negativa. La negativa es la protección.
- **Editar el `.env` del servidor desde local**, o mandar un secreto por el canal de trabajo.
- **Archivar la spec al mergear.** Se archiva al desplegar.

## Troubleshooting

**`error: origin/main no existe`** — falta el `git fetch origin`, o el remoto no se llama `origin`.

**El compose se niega a levantar y nombra una variable** (`set JWT_SECRET in .env, at least 32
chars`) — es el paso 1, que no se hizo. Generar la variable en el servidor, con backup del `.env`,
y volver a correr el deploy.

**`backend NO llegó a healthy`** — el script ya imprimió las últimas 40 líneas del log. Las causas
por frecuencia: una migración de Alembic que falló al arrancar, la base que no levantó (mirar
`docker compose -f docker-compose.prod.yml ps db`), o una variable de entorno que el proceso lee al
importar. Lo que estaba corriendo antes sigue corriendo: no hay apuro por forzar nada.

**El health contesta 200 pero con una `version` vieja** — la imagen no se reconstruyó. Revisar que
el paso `up -d --build` haya corrido completo y repetir el deploy; en el caso raro de que una
imagen quedara etiquetada a mano, borrarla con el filtro de este proyecto y volver a construir.

**Las cabeceras de seguridad no aparecen en la respuesta** — misma causa: imagen de `frontend`
vieja. Comprobar con
`ssh mendri "docker inspect --format '{{.Image}}' origin-solutions-challenge-frontend-1"` que la
imagen corresponde al `VERSION` desplegado.

**El login contesta 500 en vez de 401** — casi siempre `JWT_SECRET` vacío o demasiado corto. Si el
compose levantó es porque la variable existe; revisar su longitud.

**El login contesta 401 con credenciales que deberían ser válidas** — la base no tiene ese usuario.
Producción no se siembra: paso 5.

**La conexión SSH se corta en medio de un `pull` grande** — el script ya trae
`ServerAliveInterval=20` y `ServerAliveCountMax=15` por eso mismo. Si vuelve a pasar, el deploy es
idempotente: se corre de nuevo.

**Grafana o Prometheus reiniciándose** — límite de memoria (`ADR-009`). No frena el deploy de la
aplicación; se mira aparte, con `docker stats` acotado a los contenedores de este proyecto.
