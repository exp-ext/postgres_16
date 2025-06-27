# PostgreSQL с интегрированным бэкапом и восстановлением в Docker

**Репозиторий** содержит всю конфигурацию и скрипты для запуска контейнера PostgreSQL с  

- автоматическим ежедневным бэкапом в S3-совместимый бакет (VK Cloud),  
- возможностью ручного бэкапа,  
- возможностью восстановления последнего дампа из бакета,  
- и безопасным хранением данных в Docker Volume.

---

## 🔍 Структура

├── backup/ # Контекст Docker-образа
│ ├── Dockerfile # Описание образа postgres:+awscli+cron
│ ├── entrypoint.sh # Запуск PostgreSQL + выбор действий
│ ├── backup.sh # Логика дампа и заливки в S3 + чистка старых
│ ├── restore.sh # Логика загрузки последнего дампа и восстановления
│ ├── backup_db # Обёртка для backup.sh
│ ├── restore_db # Обёртка для restore.sh
│ └── .dockerignore # Файлы, игнорируемые при docker build
│
├── docker-compose.yml # Описание сервисов: db + pgadmin
├── .env.example # Пример файла окружения с переменными
└── README.md # Этот файл

---

## ⚙️ Требования

- Docker ≥ 20.10  
- Docker Compose ≥ 1.27  
- Аккаунт в DockerHub (для CI/CD)  
- AWS S3-совместимый бакет (VK Cloud Storage)  
- Файл окружения `.env` в корне проекта  

---

## 📝 Переменные окружения

Скопируйте и заполните файл `.env` (см. `.env.example`):

| Переменная             | Описание                                                      |
|------------------------|---------------------------------------------------------------|
| `POSTGRES_DB`          | Имя БД внутри контейнера (например, `geocad`)                 |
| `POSTGRES_USER`        | Пользователь PostgreSQL                                       |
| `POSTGRES_PASSWORD`    | Пароль пользователя PostgreSQL                                |
| `AWS_ACCESS_KEY_ID`    | Ключ доступа к S3 (VK Cloud)                                  |
| `AWS_SECRET_ACCESS_KEY`| Секретный ключ S3                                             |
| `AWS_DEFAULT_REGION`   | Регион S3 (например, `ru-msk`)                                |
| `AWS_ENDPOINT`         | Endpoint VK Cloud (например, `https://hb.ru-msk.vkcs.cloud`)  |
| `BUCKET`               | Название бакета (без префикса `s3://`)                        |
| `PGADMIN_DEFAULT_EMAIL`    | Email для доступа к pgAdmin                                |
| `PGADMIN_DEFAULT_PASSWORD` | Пароль для pgAdmin                                         |

---

## 🚀 Быстрый старт

1. **Клонировать репозиторий**  

```bash
git clone https://github.com/exp-ext/postgres_16.git
# заполните .env
```

2. **Запустить контейнеры**

```bash
docker-compose up -d
```

## 🔧 Команды для ручного управления

Все ручные команды выполняются от имени сервиса db (или pg_main).

1. Ручной бэкап

```bash
docker-compose exec db backup_db
```

Или в отдельном контейнере:

```bash
docker-compose run --rm db backup_db
```

— создаст дамп текущей базы, загрузит его в S3 и удалит локальный файл.

2. Ручное восстановление последнего дампа

```bash
docker-compose exec db restore_db
```

Или:

```bash
docker-compose run --rm db restore_db
```

— скачает самый свежий дамп из бакета, удалит старую БД, создаст новую и восстановит из него все таблицы.
