#!/usr/bin/env bash
set -Eeuo pipefail

CONTAINER="pg_main"

# --- берём БД/юзера: приоритет аргументы → env контейнера --------------
ARG_DB="${1:-}"
ARG_USR="${2:-}"

DB=${ARG_DB:-$(docker exec "$CONTAINER" printenv POSTGRES_DB 2>/dev/null || echo "")}
USER=${ARG_USR:-$(docker exec "$CONTAINER" printenv POSTGRES_USER 2>/dev/null || echo "")}

[[ -z $DB   ]] && { echo "❌ не удалось определить DB";   exit 1; }
[[ -z $USER ]] && { echo "❌ не удалось определить USER"; exit 1; }

OUT="dump_${DB}_$(date +%F_%H-%M).dump"
echo "‣ Делаю дамп базы '$DB' от имени '$USER' → $OUT …"

docker exec -i "$CONTAINER" \
  pg_dump -U "$USER" -d "$DB" -Fc -Z9 > "$OUT"

echo "✅  Готово: $(du -h "$OUT" | cut -f1) — $OUT"