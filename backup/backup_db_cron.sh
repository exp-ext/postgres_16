#!/bin/sh
set -e

set -a
. /etc/cron.env
set +a

exec /usr/local/bin/backup.sh
