#!/usr/bin/env sh
set -e

# Загрузка .env
. /usr/local/bin/env_loader.sh
load_env "$ENV_FILE"

# Поддержка кастомного S3-endpoint (VK Cloud)
ENDP_ARGS=""
if [ -n "$AWS_ENDPOINT" ]; then
  ENDP_ARGS="--endpoint-url ${AWS_ENDPOINT}"
fi

# Находим последний (по LastModified) ключ в бакете
LATEST_KEY=$(aws ${ENDP_ARGS} s3api list-objects-v2 \
  --bucket ${BUCKET} \
  --query 'Contents | sort_by(@, &LastModified) | [-1].Key' \
  --output text)

if [ -z "$LATEST_KEY" ] || [ "$LATEST_KEY" = "None" ]; then
  echo "[$(date)] ОШИБКА: не найден ни один бэкап в бакете" >&2
  exit 1
fi

TMPFILE="/tmp/$(basename "$LATEST_KEY")"

echo "[$(date)] Скачиваем последний дамп: ${LATEST_KEY}"
aws ${ENDP_ARGS} s3 cp "s3://${BUCKET}/${LATEST_KEY}" "${TMPFILE}"

# Удаление текущей базы данных и создание новой
echo "[$(date)] Проверяем, существует ли база ${POSTGRES_DB}..."
export PGPASSWORD="${POSTGRES_PASSWORD}"

# Проверка, существует ли база данных
DB_EXISTS=$(psql --host="${POSTGRES_HOST}" --port="${POSTGRES_PORT}" --username="${POSTGRES_USER}" --dbname="postgres" \
  -tAc "SELECT 1 FROM pg_database WHERE datname='${POSTGRES_DB}';")

# Если база существует, завершаем все сессии и удаляем её
if [ "$DB_EXISTS" = "1" ]; then
  echo "[$(date)] База данных ${POSTGRES_DB} существует. Завершаем активные сессии..."
  
  # Завершаем все активные подключения к базе данных
  psql --host="${POSTGRES_HOST}" --port="${POSTGRES_PORT}" --username="${POSTGRES_USER}" --dbname="postgres" \
    -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${POSTGRES_DB}' AND pid <> pg_backend_pid();"
  
  echo "[$(date)] Удаляем базу данных ${POSTGRES_DB}..."
  psql --host="${POSTGRES_HOST}" --port="${POSTGRES_PORT}" --username="${POSTGRES_USER}" --dbname="postgres" \
    -c "DROP DATABASE IF EXISTS ${POSTGRES_DB};"
fi

# Создаём новую базу данных
echo "[$(date)] Создаем новую базу данных ${POSTGRES_DB}..."
psql --host="${POSTGRES_HOST}" --port="${POSTGRES_PORT}" --username="${POSTGRES_USER}" --dbname="postgres" \
  -c "CREATE DATABASE ${POSTGRES_DB};"

# Восстановление дампа в новую базу данных
echo "[$(date)] Восстанавливаем в БД ${POSTGRES_DB}…"
gunzip -c "${TMPFILE}" | pg_restore \
  --host="${POSTGRES_HOST}" \
  --port="${POSTGRES_PORT}" \
  --username="${POSTGRES_USER}" \
  --dbname="${POSTGRES_DB}" \
  --verbose

rm -f "${TMPFILE}"
echo "[$(date)] Восстановление завершено!"
