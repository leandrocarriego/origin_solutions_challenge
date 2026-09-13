#!/bin/sh
#
# Runs before the application, in every environment.
#
# Migrations always: a container that starts against an out-of-date schema fails later, in the
# middle of a request, instead of here where the logs are being read (DB-01).
#
# The seed only when asked for. It creates demo users whose passwords are in the repository, so
# it must never be a default -- it is opt-in through SEED_ON_START, and it refuses outright in
# production even if the flag is set by accident.
set -eu

echo "==> alembic upgrade head"
alembic upgrade head

if [ "${SEED_ON_START:-false}" = "true" ]; then
  echo "==> seed"
  python seed.py
fi

exec "$@"
