#!/usr/bin/env bash
#
# Despliega en el VPS, que comparte con otros proyectos en producción.
#
# Dos reglas que vienen de eso:
#   - La limpieza es SIEMPRE acotada a este proyecto. Un `docker system prune -a` borraría la
#     caché de build y las imágenes de los otros seis, y eso es tirar el VPS por otra puerta.
#   - Si algo falla, se aborta antes de tocar lo que está corriendo.
set -euo pipefail

HOST="${DEPLOY_HOST:-mendri}"
REMOTE_DIR="${DEPLOY_DIR:-/srv/projects/mendri/origin-solutions-challenge}"
PROJECT="origin-solutions-challenge"

# Un pull de varios cientos de MB deja la conexión sin tráfico el tiempo suficiente para que
# el sshd del otro lado la corte. Pasó una vez, con el deploy a medio terminar: sin health
# check y sin limpieza. El keepalive es lo que lo evita.
SSH_OPTS=(-o ServerAliveInterval=20 -o ServerAliveCountMax=15)
ssh() { command ssh "${SSH_OPTS[@]}" "$@"; }
LOCAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

VERSION="$(git -C "$LOCAL_DIR" rev-parse --short HEAD)"
DOMAIN="${DOMAIN:-origin-solutions-challenge.mendrisoftware.com}"

echo "==> Desplegando ${VERSION} en ${HOST}:${REMOTE_DIR}"

# --- 1. Sanidad local antes de subir nada ------------------------------------------------------
echo "==> Verificando el árbol local"
if [ -n "$(git -C "$LOCAL_DIR" status --porcelain)" ]; then
  echo "    aviso: hay cambios sin commitear; se despliega el árbol de trabajo, no el commit"
fi

# --- 2. Sincronizar el código ------------------------------------------------------------------
# --delete deja el destino igual al origen: sin esto cada deploy acumula archivos que ya no
# existen, que es exactamente la basura que hay que evitar.
echo "==> Sincronizando"
ssh "$HOST" "mkdir -p '${REMOTE_DIR}'"
rsync -az --delete \
  --exclude '.git/' \
  --exclude '.env' \
  --exclude 'node_modules/' \
  --exclude '.venv/' \
  --exclude 'dist/' \
  --exclude '__pycache__/' \
  --exclude '.pytest_cache/' \
  --exclude '.mypy_cache/' \
  --exclude '.ruff_cache/' \
  -e "ssh ${SSH_OPTS[*]}" \
  "${LOCAL_DIR}/" "${HOST}:${REMOTE_DIR}/"

# --- 3. Construir y levantar -------------------------------------------------------------------
echo "==> Bajando imágenes externas"
# Primero el pull, solo. Si se corta la red, se corta acá y no con los servicios a medio
# recrear: lo que está corriendo sigue corriendo.
ssh "$HOST" "cd '${REMOTE_DIR}' && \
  export VERSION='${VERSION}' DOMAIN='${DOMAIN}' && \
  docker compose -f docker-compose.prod.yml --env-file .env pull --quiet --ignore-buildable"

echo "==> Construyendo y levantando"
ssh "$HOST" "cd '${REMOTE_DIR}' && \
  export VERSION='${VERSION}' DOMAIN='${DOMAIN}' && \
  docker compose -f docker-compose.prod.yml --env-file .env up -d --build --remove-orphans"

# --- 4. Esperar a que esté sano ----------------------------------------------------------------
echo "==> Esperando health"
ssh "$HOST" "cd '${REMOTE_DIR}' && for i in \$(seq 1 30); do
  estado=\$(docker inspect --format '{{.State.Health.Status}}' ${PROJECT}-backend-1 2>/dev/null || echo starting)
  [ \"\$estado\" = healthy ] && echo '    backend healthy' && exit 0
  sleep 2
done; echo '    backend NO llegó a healthy'; docker compose -f docker-compose.prod.yml logs --tail 40 backend; exit 1"

# --- 5. Limpieza, sólo de lo nuestro -----------------------------------------------------------
# `--filter label=` limita el borrado a las imágenes de este proyecto. Las de los demás y la
# caché compartida quedan intactas.
echo "==> Limpiando imágenes viejas de este proyecto"
ssh "$HOST" "docker image prune -f --filter label=com.docker.compose.project=${PROJECT} 2>/dev/null || true; \
             docker images --filter 'reference=${PROJECT}-*' --filter 'dangling=true' -q | xargs -r docker rmi 2>/dev/null || true"

echo "==> Listo: https://${DOMAIN}"
