#!/bin/sh
# Small Railway wrapper around the upstream start command (`task servem`:
# run database migrations, then serve the web UI).
set -e

# Listen on Railway's PORT unless PBW_LISTEN_PORT is set explicitly.
export PBW_LISTEN_HOST="${PBW_LISTEN_HOST:-0.0.0.0}"
export PBW_LISTEN_PORT="${PBW_LISTEN_PORT:-${PORT:-8085}}"
export TZ="${TZ:-UTC}"

if [ -z "$PBW_ENCRYPTION_KEY" ] || [ -z "$PBW_POSTGRES_CONN_STRING" ]; then
  echo "PBW_ENCRYPTION_KEY and PBW_POSTGRES_CONN_STRING must both be set." >&2
  exit 1
fi

# The metadata database is reached over Railway's private network. lib/pq would
# default to sslmode=require, which fails on Postgres servers without TLS, so add
# sslmode=disable unless the connection string already sets an sslmode.
case "$PBW_POSTGRES_CONN_STRING" in
  *sslmode=*) ;;
  *\?*) export PBW_POSTGRES_CONN_STRING="${PBW_POSTGRES_CONN_STRING}&sslmode=disable" ;;
  *)    export PBW_POSTGRES_CONN_STRING="${PBW_POSTGRES_CONN_STRING}?sslmode=disable" ;;
esac

mkdir -p /backups
cd /app

# Same as upstream `task servem` (migrate, then serve), but retry the migration
# while the database is still starting, e.g. on a fresh deploy.
tries=0
until task goose -- up; do
  tries=$((tries + 1))
  if [ "$tries" -ge 30 ]; then
    echo "Database not reachable after $tries attempts, giving up." >&2
    exit 1
  fi
  echo "Database not ready yet (attempt $tries/30), retrying in 3s..." >&2
  sleep 3
done

exec task serve
