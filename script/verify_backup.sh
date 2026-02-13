#!/usr/bin/env bash
set -euo pipefail

: "${POSTGRES_USER:=postgres}"
: "${POSTGRES_PASSWORD:=postgres}"
: "${POSTGRES_HOST:=localhost}"
: "${POSTGRES_PORT:=5432}"

export PGPASSWORD="$POSTGRES_PASSWORD"

SOURCE_DB="backup_verify_source"
RESTORE_DB="backup_verify_restore"
DUMP_FILE="/tmp/backup_verify.dump"

cleanup() {
  dropdb --if-exists -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" "$SOURCE_DB" >/dev/null 2>&1 || true
  dropdb --if-exists -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" "$RESTORE_DB" >/dev/null 2>&1 || true
  rm -f "$DUMP_FILE"
}

trap cleanup EXIT

cleanup

createdb -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" "$SOURCE_DB"
psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" "$SOURCE_DB" <<'SQL'
CREATE TABLE backup_probe(id integer primary key, name text not null);
INSERT INTO backup_probe(id, name) VALUES (1, 'ok');
SQL

pg_dump -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -Fc "$SOURCE_DB" > "$DUMP_FILE"

createdb -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" "$RESTORE_DB"
pg_restore -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$RESTORE_DB" "$DUMP_FILE"

restored_rows=$(psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$RESTORE_DB" -Atc "SELECT COUNT(*) FROM backup_probe")
if [[ "$restored_rows" != "1" ]]; then
  echo "Backup verification failed: expected 1 row, got $restored_rows"
  exit 1
fi

echo "Backup verification passed"
