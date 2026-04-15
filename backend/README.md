# MedBook Backend

Отдельный backend для Flutter-проекта `MedBook`, написанный на Go. Сервис поднимает REST API, хранит данные в SQLite и при первом запуске заполняет базу из `../assets/mock/*.json`, чтобы данные совпадали с текущими моками фронтенда.

## Структура

- `cmd/api` - точка входа HTTP-сервера
- `internal/config` - конфигурация через env
- `internal/model` - модели и DTO запросов
- `internal/service` - бизнес-логика
- `internal/store` - SQLite, миграции и seed
- `internal/transport/http` - роуты, middleware и JSON-хендлеры

## Быстрый запуск

```bash
cd backend
go mod tidy
go run ./cmd/api
```

Сервер поднимется на `http://localhost:8080`.

## Переменные окружения

Смотри `.env.example`:

- `PORT` - порт HTTP-сервера
- `DATABASE_PATH` - путь к SQLite-файлу
- `SEED_DATA_DIR` - папка с начальными JSON-данными
- `SESSION_TTL_HOURS` - срок жизни токена
- `REQUEST_TIMEOUT_SECONDS` - таймаут запроса
- `SHUTDOWN_TIMEOUT_SECONDS` - таймаут graceful shutdown
- `ALLOWED_ORIGIN` - CORS origin

## REST API

### Auth

- `POST /api/v1/auth/login`
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/logout`

### Catalog

- `GET /api/v1/specializations`
- `GET /api/v1/doctors?specializationId=therapy&query=мария`
- `GET /api/v1/doctors/{doctorID}`
- `GET /api/v1/doctors/{doctorID}/slots?date=2026-04-18`

### Appointments

- `GET /api/v1/appointments`
- `POST /api/v1/appointments`
- `PATCH /api/v1/appointments/{appointmentID}/cancel`
- `PATCH /api/v1/appointments/{appointmentID}/reschedule`

### Profile

- `GET /api/v1/profile`
- `PUT /api/v1/profile`

Для защищённых маршрутов нужен заголовок:

```http
Authorization: Bearer <token>
```

## Примеры payload

```json
POST /api/v1/auth/login
{
  "identifier": "anna@example.com",
  "password": "password123"
}
```

```json
POST /api/v1/appointments
{
  "doctorId": "doctor-1",
  "scheduledAt": "2026-04-18T10:30:00+03:00"
}
```

## Проверка

```bash
go test ./...
go build ./cmd/api
```
