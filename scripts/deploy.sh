#!/usr/bin/env bash
#
# Deploys to the VPS, which is shared with other projects in production.
#
# Two rules follow from that:
#   - Cleanup is ALWAYS scoped to this project. A `docker system prune -a` would wipe the build
#     cache and the images of the other six, which is taking the VPS down through another door.
#   - If anything fails, abort before touching what is already running.
#
# The echoed messages are terminal output for the team, so they stay in Spanish (GEN-07).
set -euo pipefail

HOST="${DEPLOY_HOST:-mendri}"
REMOTE_DIR="${DEPLOY_DIR:-/srv/projects/mendri/origin-solutions-challenge}"
PROJECT="origin-solutions-challenge"

# A pull of several hundred MB leaves the connection idle long enough for the far side's sshd
# to drop it. That happened once, leaving the deploy half finished: no health check and no
# cleanup. The keepalive is what prevents it.
SSH_OPTS=(-o ServerAliveInterval=20 -o ServerAliveCountMax=15)
ssh() { command ssh "${SSH_OPTS[@]}" "$@"; }
LOCAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

VERSION="$(git -C "$LOCAL_DIR" rev-parse --short HEAD)"
DOMAIN="${DOMAIN:-origin-solutions-challenge.mendrisoftware.com}"

echo "==> Desplegando ${VERSION} en ${HOST}:${REMOTE_DIR}"

# --- 1. Local sanity before uploading anything -------------------------------------------------
echo "==> Verificando el árbol local"
if [ -n "$(git -C "$LOCAL_DIR" status --porcelain)" ]; then
  echo "    aviso: hay cambios sin commitear; se despliega el árbol de trabajo, no el commit"
fi

# --- 2. Sync the code --------------------------------------------------------------------------
# --delete leaves the destination identical to the source: without it every deploy piles up
# files that no longer exist, which is exactly the litter to avoid.
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

# --- 3. Build and start ------------------------------------------------------------------------
echo "==> Bajando imágenes externas"
# The pull first, on its own. If the network drops it drops here and not with the services
# half recreated: whatever is running keeps running.
ssh "$HOST" "cd '${REMOTE_DIR}' && \
  export VERSION='${VERSION}' DOMAIN='${DOMAIN}' && \
  docker compose -f docker-compose.prod.yml --env-file .env pull --quiet --ignore-buildable"

echo "==> Construyendo y levantando"
ssh "$HOST" "cd '${REMOTE_DIR}' && \
  export VERSION='${VERSION}' DOMAIN='${DOMAIN}' && \
  docker compose -f docker-compose.prod.yml --env-file .env up -d --build --remove-orphans"

# --- 4. Wait until it is healthy ---------------------------------------------------------------
echo "==> Esperando health"
ssh "$HOST" "cd '${REMOTE_DIR}' && for i in \$(seq 1 30); do
  estado=\$(docker inspect --format '{{.State.Health.Status}}' ${PROJECT}-backend-1 2>/dev/null || echo starting)
  [ \"\$estado\" = healthy ] && echo '    backend healthy' && exit 0
  sleep 2
done; echo '    backend NO llegó a healthy'; docker compose -f docker-compose.prod.yml logs --tail 40 backend; exit 1"

# --- 5. Cleanup, ours only ---------------------------------------------------------------------
# Three passes, and the third is the one that was missing. A dangling image loses its name, so
# a `reference=` filter never matches one; and an image tagged with a previous commit is not
# dangling at all, so nothing removed it and every deploy left the last version behind.
#
# `docker rmi` refuses to remove an image a container is using, which is the safety net here:
# the running tag cannot be deleted even if this filter were wrong.
echo "==> Limpiando imágenes viejas de este proyecto"
ssh "$HOST" "
  docker image prune -f --filter label=com.docker.compose.project=${PROJECT} 2>/dev/null || true

  docker images --filter 'reference=${PROJECT}-*' --filter 'dangling=true' -q \
    | xargs -r docker rmi 2>/dev/null || true

  docker images --filter 'reference=${PROJECT}-*' --format '{{.Repository}}:{{.Tag}}' \
    | grep -v ':${VERSION}\$' \
    | xargs -r docker rmi 2>/dev/null || true
"

echo "==> Listo: https://${DOMAIN}"
