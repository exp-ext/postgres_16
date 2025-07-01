FROM postgres:16

RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        cron awscli; \
    rm -rf /var/lib/apt/lists/*

COPY --chmod=755 env_loader.sh          /usr/local/bin/env_loader.sh
COPY --chmod=755 entrypoint.sh          /usr/local/bin/entrypoint.sh
COPY --chmod=755 backup.sh              /usr/local/bin/backup.sh
COPY --chmod=755 restore.sh             /usr/local/bin/restore.sh
COPY --chmod=755 backup_db              /usr/local/bin/backup_db
COPY --chmod=755 restore_db             /usr/local/bin/restore_db
COPY --chmod=755 backup_db_cron.sh /usr/local/bin/backup_db_cron.sh

COPY --chmod=644 pg_backup /etc/cron.d/pg_backup

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]