#!/usr/bin/env bash
set -Eeuo pipefail

# Имя контейнера PostgreSQL — поправьте, если у вас другое
CONTAINER="pg_main"

# 1) обязательный аргумент — путь к dump-файлу
DUMP_FILE="${1:?Укажите dump-файл первым аргументом}"
# 2) опционально: имя БД (иначе попытаемся прочитать из env контейнера)
ARG_DB="${2:-}"
# 3) опционально: имя юзера (иначе из env контейнера)
ARG_USR="${3:-}"

# пробуем достать из переменных окружения контейнера
DB="${ARG_DB:-$(docker exec "$CONTAINER" printenv POSTGRES_DB 2>/dev/null || echo "")}"
USR="${ARG_USR:-$(docker exec "$CONTAINER" printenv POSTGRES_USER 2>/dev/null || echo "")}"

# проверяем, что всё есть
if [[ -z "$DB" ]]; then
  echo "❌ Не удалось определить имя БД. Передайте его вторым аргументом."
  exit 1
fi
if [[ -z "$USR" ]]; then
  echo "❌ Не удалось определить имя пользователя. Передайте его третьим аргументом."
  exit 1
fi
if [[ ! -f "$DUMP_FILE" ]]; then
  echo "❌ Файл дампа '$DUMP_FILE' не найден."
  exit 1
fi

echo "‣ Пересоздаю базу '$DB'…"
# 1) Удаляем старую
docker exec -i "$CONTAINER" psql \
  -U "$USR" \
  -d postgres \
  -c "DROP DATABASE IF EXISTS \"$DB\";"

# 2) Создаём новую
docker exec -i "$CONTAINER" psql \
  -U "$USR" \
  -d postgres \
  -c "CREATE DATABASE \"$DB\" OWNER \"$USR\";"

echo "‣ Восстанавливаю из '$DUMP_FILE'…"
docker exec -i "$CONTAINER" pg_restore \
  -U "$USR" \
  -d "$DB" \
  --no-owner \
  --no-acl < "$DUMP_FILE"

echo "✅  База '$DB' успешно восстановлена."