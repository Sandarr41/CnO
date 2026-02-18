#  Приложение почтового агента
##  Описание проекта

Данный проект представляет собой multi-service архитектуру, реализованную с помощью docker-compose.yml.

В состав входят:

db — PostgreSQL база данных

init-db — одноразовый init-сервис

app — основное приложение (Email Agent + Gradio UI)

Все сервисы работают в одной сети и взаимодействуют друг с другом.

## Состав docker-compose.yml

Файл включает:

- 3 сервиса

- автоматическую сборку образа

- жесткие имена контейнеров

- volume

- healthcheck

- depends_on

- прокидывание портов

- отдельный .env файл

- общую сеть

## Описание сервисов
### 1. Сервис db
```
db:
  image: postgres:16-alpine
  container_name: email_postgres_db
```

Назначение:

PostgreSQL база данных для хранения информации.

Особенности:

- Использует официальный образ PostgreSQL

- Переменные окружения загружаются из .env

- Используется volume:
```
volumes:
  - db_data:/var/lib/postgresql/data
```

Это обеспечивает сохранность данных при перезапуске контейнера.

Healthcheck:
```
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
```

Контейнер считается готовым только после успешной проверки.

### 2. Сервис init-db
```
init-db:
  build:
    context: .
    dockerfile: Dockerfile
  image: email-agent:latest
  container_name: email_agent_init
```
Назначение:

Одноразовый контейнер для инициализации базы данных.

Особенности:

- Использует тот же Dockerfile

- Автоматически собирает образ

- Имеет depends_on:
```
depends_on:
  db:
    condition: service_healthy
```

Выполняет команду через command
```
command: python init_script.py
```

После выполнения завершает работу.

### 3. Сервис app
```
app:
  build:
    context: .
  image: email-agent:latest
  container_name: email_agent_app
```
Назначение:

Основное приложение (Gradio UI + агенты).

Особенности:

- Жесткое имя контейнера

- Проброс порта:

```
ports:
  - "7860:7860"
```

Volume:
```
volumes:
  - email_data:/app/data
```

depends_on:
```
depends_on:
  db:
    condition: service_healthy
  init-db:
    condition: service_completed_successfully
```

Healthcheck:
```
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:7860"]
```
## Network
```
networks:
  email_network:
    driver: bridge
```

Все сервисы подключены к одной сети:
```
networks:
  - email_network
```

Это позволяет им обращаться друг к другу по имени сервиса (например, db).

## Volumes
```
volumes:
  db_data:
  email_data:
```

db_data — хранит данные PostgreSQL

email_data — хранит данные приложения

Volumes делают контейнеры stateless.

## .env

Все переменные окружения вынесены в отдельный файл:
```
# -> Docker envs
POSTGRES_USER=email_user
POSTGRES_PASSWORD=email_password
POSTGRES_DB=email_db
APP_ENV=production
```

Это улучшает безопасность и упрощает конфигурацию.


## Ответы на вопросы
### Вопрос 1
Можно ли ограничивать ресурсы (CPU, память) в docker-compose.yml?

 Да, можно.
```
app:
  ...
  mem_limit: 512m
  cpus: 0.5
```
### Вопрос 2

Как запустить только один сервис из docker-compose.yml?

Можно указать имя сервиса:
```
docker compose up app
```

Будет запущен только сервис app.

Если нужно запустить без зависимостей:

```
docker compose up --no-deps app
```

Это запустит только app, игнорируя depends_on.
