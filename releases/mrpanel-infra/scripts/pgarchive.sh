#!/usr/bin/env bash

readonly SOURCE="${1:?Missing source file}"
readonly FILE_NAME="${2:?Missing file name}"

readonly WAL_DIR="${BACKUP_DIR}/wal"
readonly DEST_FILE="${WAL_DIR}/${FILE_NAME}.zstd"

set -e
if [[ ! -f "$DEST_FILE"  ]]; then
  zstd "$SOURCE" --no-progress -v -o "$DEST_FILE"
else
  >&2 echo "$DEST_FILE" already exists
  exit 1
fi