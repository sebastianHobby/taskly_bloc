#!/usr/bin/env bash
set -euo pipefail

SQL_PATH="${1:-supabase/truncate_pipeline.sql}"

if [ ! -f "$SQL_PATH" ]; then
  echo "SQL file not found: $SQL_PATH" >&2
  exit 1
fi

CONTAINER_ID=$(docker ps --filter "name=supabase_db" --format "{{.ID}}" | head -n 1)
if [ -z "$CONTAINER_ID" ]; then
  echo "Could not find running Supabase Postgres container (name filter: supabase_db)." >&2
  exit 1
fi

echo "Truncating app tables via container $CONTAINER_ID ..."
cat "$SQL_PATH" | docker exec -i "$CONTAINER_ID" psql -U postgres -d postgres -v ON_ERROR_STOP=1

echo "Truncate completed."
