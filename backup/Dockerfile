FROM postgres:16

# Устанавливаем необходимые утилиты: awscli, cron
RUN apt-get update \
  && apt-get install -y awscli cron \
  && rm -rf /var/lib/apt/lists/*

# Копируем скрипты для бэкапов и восстановления
COPY entrypoint.sh  /usr/local/bin/entrypoint.sh
COPY backup.sh      /usr/local/bin/backup.sh
COPY restore.sh     /usr/local/bin/restore.sh
COPY backup_db      /usr/local/bin/backup_db
COPY restore_db     /usr/local/bin/restore_db

# Даем права на выполнение
RUN chmod +x /usr/local/bin/*.sh /usr/local/bin/backup_db /usr/local/bin/restore_db

# Крон-задача для автоматического бэкапа (ежедневно в 02:00)
RUN echo "0 2 * * * root /usr/local/bin/backup.sh >> /var/log/backup.log 2>&1" \
     > /etc/cron.d/pg_backup \
  && chmod 0644 /etc/cron.d/pg_backup \
  && crontab /etc/cron.d/pg_backup

# Запуск точки входа (если контейнер не в режиме cron)
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["cron", "-f"]