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

# What gets deployed is a ref of the remote, never the working tree. The tree is where work in
# progress lives: deploying it means production can hold code that is on nobody's branch, that
# no CI run ever saw and that no reviewer read.
DEPLOY_REF="${DEPLOY_REF:-origin/main}"
DOMAIN="${DOMAIN:-origin-solutions-challenge.leandrocarriego.com}"

# --- 1. Resolve what is going out, before touching anything -----------------------------------
echo "==> Trayendo ${DEPLOY_REF}"
git -C "$LOCAL_DIR" fetch origin --quiet

if ! git -C "$LOCAL_DIR" rev-parse --verify --quiet "${DEPLOY_REF}^{commit}" >/dev/null; then
  echo "    error: ${DEPLOY_REF} no existe" >&2
  exit 1
fi

VERSION="$(git -C "$LOCAL_DIR" rev-parse --short "$DEPLOY_REF")"
SUBJECT="$(git -C "$LOCAL_DIR" log -1 --format=%s "$DEPLOY_REF")"

echo "==> Desplegando ${VERSION} en ${HOST}:${REMOTE_DIR}"
echo "    ${SUBJECT}"

if [ "$(git -C "$LOCAL_DIR" rev-parse HEAD)" != "$(git -C "$LOCAL_DIR" rev-parse "$DEPLOY_REF")" ]; then
  echo "    aviso: tu HEAD no es ${DEPLOY_REF}; lo que sale es ${DEPLOY_REF}, no lo que tenés acá"
fi

# --- 2. Sync the code --------------------------------------------------------------------------
# From a clean export of the ref and not from the working directory: `git archive` writes exactly
# what is committed, so an untracked file cannot reach production by accident.
#
# --delete leaves the destination identical to the source: without it every deploy piles up
# files that no longer exist, which is exactly the litter to avoid. `.env` is excluded, so the
# secrets that live only on the server survive it.
echo "==> Sincronizando"
SOURCE="$(mktemp -d)"
trap 'rm -rf "$SOURCE"' EXIT
git -C "$LOCAL_DIR" archive "$DEPLOY_REF" | tar -x -C "$SOURCE"

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
  "${SOURCE}/" "${HOST}:${REMOTE_DIR}/"

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
