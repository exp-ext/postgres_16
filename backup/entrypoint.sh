#!/usr/bin/env sh
set -e

# Безопасная загрузка .env
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

load_env "$ENV_FILE"

# Выбор действия по первому аргументу
case "$1" in
  backup_db)
    echo "[$(date)] Запуск backup_db..."
    exec /usr/local/bin/backup.sh
    ;;
  restore_db)
    echo "[$(date)] Запуск restore_db..."
    exec /usr/local/bin/restore.sh
    ;;
  *)
    echo "[$(date)] Запуск PostgreSQL..."
    exec docker-entrypoint.sh postgres
    ;;
esac