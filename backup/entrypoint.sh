#!/usr/bin/env sh
set -e

# Безопасная загрузка .env
. /usr/local/bin/env_loader.sh
load_env "$ENV_FILE"

ENV_SNAPSHOT=/etc/cron.env
printenv > "$ENV_SNAPSHOT"
chmod 600 "$ENV_SNAPSHOT"

LOG_FILE=/var/log/backup.log

# Выбор действия по первому аргументу
case "$1" in
  backup_db)
    echo "[$(date)] Ручной бэкап..."
    exec /usr/local/bin/backup.sh
    ;;
  restore_db)
    echo "[$(date)] Ручное восстановление..."
    exec /usr/local/bin/restore.sh
    ;;
  *)
    echo "[init] готовлю лог-файл…"
    mkdir -p /var/log
    : > "$LOG_FILE"

    echo "[logs] tail -F $LOG_FILE → stdout"
    tail -n0 -F "$LOG_FILE" &

    echo "[cron] запускаю cron…"
    cron -f -L 0 &

    echo "[postgres] запускаю Postgres…"
    exec docker-entrypoint.sh postgres
    ;;
esac
