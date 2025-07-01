#!/usr/bin/env sh

load_env() {
    f="$1"
    [ -f "$f" ] || return 0
    while IFS= read -r line || [ -n "$line" ]; do
        line=${line%$'\r'}
        case "$line" in ''|'#'*) continue;; esac
        key=${line%%=*}
        val=${line#*=}
        key=$(printf '%s' "$key" | tr -d '[:space:]')
        export "$key=$val"
    done < "$f"
}