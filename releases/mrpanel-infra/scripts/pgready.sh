set -e

pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE" -h localhost -p 5432 -t 15

grep "##PGINIT-SUCCESS##" "$PGINIT_LOG_PATH"