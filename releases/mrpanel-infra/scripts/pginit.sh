#!/usr/bin/env bash

set -e

export VERBOSITY=verbose

function log {
  current_timestamp="$(date +%Y%m%d%H%M%S%3N)"
  log_level="${2:-INFO}"

  log_text="$current_timestamp [$log_level]: $1"

  if [[ "$log_level" = "ERROR" ]]; then
    >&2 echo "$log_text"
  else
    echo "$log_text"
  fi
}

function exit_with_success {
  log "##PGINIT-SUCCESS##"
  exit 0
}

function exit_with_error {
  log "Removing backup directories" "ERROR"
  rm -rf "${BASE_BACKUP_PATH}"
  rm -rf "${WAL_PATH}"
  log "##PGINIT_ERROR##" "ERROR"
  exit 3
}

log "Env dump"

echo "PGDATA=${PGDATA:?Missing PGDATA}"

readonly TIMESTAMP="$(date +%Y%m%d%H%M%S)"
echo "TIMESTAMP=$TIMESTAMP"

echo "BACKUP_DIR=${BACKUP_DIR:?Missing BACKUP_DIR}"
chmod -R 744 "$BACKUP_DIR"

readonly BASE_BACKUP_PATH="${BACKUP_DIR}/base"
echo "BASE_BACKUP_PATH=$BASE_BACKUP_PATH"
mkdir -p "$BASE_BACKUP_PATH"

readonly WAL_PATH="$BACKUP_DIR/wal"
echo "WAL_PATH=$WAL_PATH"
mkdir -p "$WAL_PATH"
chown -R postgres "$WAL_PATH"
chmod -R 744 "$WAL_PATH"

set +e

declare pgInitExitCode
for i in $(seq 1 5); do
  log "Checking pg_isready. Attempt: $i"

  pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE" -h localhost -p 5432 -t 15
  pgInitExitCode=$?

  if [[ $pgInitExitCode -eq 0 ]]; then
    log "pg_isready succeeded"
    break
  fi

  sleep 5
done

if [[ $pgInitExitCode -ne 0 ]]; then
  log "Postgres did not load" "ERROR"

  case $? in
    1)
      log "Server rejected connection" "ERROR"
      ;;
    2)
      log "No response" "ERROR"
      ;;
    3)
      log "No connection attempt. Possibly due to wrong params" "ERROR"
      ;;
  esac

  exit_with_error
fi

chmod -R 744 "$PGDATA/pg_wal"

baseBackupPathExists="$(ls -A "${BASE_BACKUP_PATH}")"

if [[ "$baseBackupPathExists" ]]; then
  log "Found the base backup directory. Verifying backup...."
  pg_verifybackup -n "${BASE_BACKUP_PATH}"
  baseBackupExitCode=$?

  if [[ $baseBackupExitCode -eq 0 ]]; then
    log "The base backup is valid. Skipping..."
    exit_with_success
  else
    log "Could not verify backup in ${BASE_BACKUP_PATH}. Removing the directory and staring anew"
    rm -rf "${BASE_BACKUP_PATH}"
  fi
fi

log "Performing base backup"

pg_basebackup              \
  -D "${BASE_BACKUP_PATH}" \
  -F tar                   \
  -Z zstd                  \
  -X fetch                 \
  --no-password            \
  -U "$POSTGRES_USER"      \
  --verbose

if [[ $? -ne 0 ]]; then
  log "Could not perform base backup" "ERROR"
  exit_with_error
fi

log "Base backup performed"

log "Verifying backup"
pg_verifybackup -n "${BASE_BACKUP_PATH}"

if [[ $? -ne 0 ]]; then
  log "Could not verify base backup" "ERROR"
  exit_with_error
fi

exit_with_success