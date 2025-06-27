#!/usr/bin/env sh
set -e

load_env() {
  f="$1"
  [ -f "$f" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    line=$(printf '%s' "$line" | tr -d '\r')
    case "$line" in
      ''|\#*) continue ;;
    esac
    key=${line%%=*}
    val=${line#*=}
    key=$(printf '%s' "$key" | tr -d '[:space:]')
    export "$key=$val"
  done < "$f"
}

# загрузить .env
load_env "$ENV_FILE"

# если указан кастомный endpoint — добавим флаг
ENDP_ARGS=""
if [ -n "$AWS_ENDPOINT" ]; then
  ENDP_ARGS="--endpoint-url ${AWS_ENDPOINT}"
fi

# параметры бэкапа
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
FILENAME="${POSTGRES_DB}-${TIMESTAMP}.sql.gz"
TMPFILE="/tmp/${FILENAME}"

echo "[$(date)] Начинаем дамп базы ${POSTGRES_DB}…"
export PGPASSWORD="${POSTGRES_PASSWORD}"

pg_dump \
  --host="${POSTGRES_HOST}" \
  --port="${POSTGRES_PORT}" \
  --username="${POSTGRES_USER}" \
  --format=custom \
  "${POSTGRES_DB}" \
| gzip > "${TMPFILE}"

echo "[$(date)] Дамп готов, заливаем s3://${BUCKET}/${FILENAME}"
aws ${ENDP_ARGS} s3 cp "${TMPFILE}" "s3://${BUCKET}/${FILENAME}"

# удалить локальный файл
rm -f "${TMPFILE}"

# — удалить объекты старше 7 дней
echo "[$(date)] Удаляем из бакета объекты старше 7 дней…"
EXPIRY_DATE=$(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ)

aws ${ENDP_ARGS} s3api list-objects-v2 \
  --bucket ${BUCKET} \
  --query "Contents[?LastModified<=\`$EXPIRY_DATE\`].Key" \
  --output text \
| while IFS= read -r KEY; do
    [ -n "$KEY" ] || continue
    echo "[$(date)] Удаляю: $KEY"
    aws ${ENDP_ARGS} s3api delete-object --bucket ${BUCKET} --key "$KEY"
  done

echo "[$(date)] Готово."