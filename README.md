# MedBook

MedBook is a medical appointment app with:

- a Flutter frontend in the repository root
- a Go backend in `backend/`
- SQLite storage on the backend side

At the moment, the backend is implemented and runnable as a separate service. The Flutter app is still wired to the local mock service in `lib/data/services/mock_api_service.dart`, so frontend and backend start independently unless you switch the frontend to real HTTP calls.

## Project Layout

- `lib/` - Flutter application
- `assets/mock/` - mock JSON data used by the frontend and backend seed
- `backend/` - Go REST API, SQLite, migrations, seed, HTTP handlers

## Requirements

Required:

- Flutter SDK
- Dart SDK
- Go `1.25.1` or newer

Optional:

- Android Studio or VS Code with Flutter plugins
- `curl` or Postman for backend API checks

## Run Frontend

From the project root:

```bash
flutter pub get
flutter run
```

Useful commands:

```bash
flutter test
flutter analyze
```

## Run Backend

Open a second terminal:

```bash
cd backend
go mod tidy
go run ./cmd/api
```

By default, backend starts at:

```text
http://localhost:8080
```

Useful backend commands:

```bash
cd backend
go test ./...
go build ./cmd/api
```

## Backend Configuration

Backend supports these environment variables:

- `PORT` - HTTP port, default `8080`
- `DATABASE_PATH` - SQLite file path, default `data/medbook.db`
- `SEED_DATA_DIR` - path to seed JSON files, default `../assets/mock`
- `SESSION_TTL_HOURS` - token lifetime in hours
- `REQUEST_TIMEOUT_SECONDS` - request timeout
- `SHUTDOWN_TIMEOUT_SECONDS` - graceful shutdown timeout
- `ALLOWED_ORIGIN` - CORS origin

Example:

```bash
cd backend
copy .env.example .env
go run ./cmd/api
```

## Backend API

Health check:

```http
GET /health
```

Main routes:

- `POST /api/v1/auth/login`
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/logout`
- `GET /api/v1/specializations`
- `GET /api/v1/doctors`
- `GET /api/v1/doctors/{doctorID}`
- `GET /api/v1/doctors/{doctorID}/slots?date=2026-04-18`
- `GET /api/v1/appointments`
- `POST /api/v1/appointments`
- `PATCH /api/v1/appointments/{appointmentID}/cancel`
- `PATCH /api/v1/appointments/{appointmentID}/reschedule`
- `GET /api/v1/profile`
- `PUT /api/v1/profile`

Protected routes require:

```http
Authorization: Bearer <token>
```

Example login request:

```json
{
  "identifier": "anna@example.com",
  "password": "password123"
}
```

## Seed Data

On first backend start, SQLite database is created and filled from:

- `assets/mock/users.json`
- `assets/mock/specializations.json`
- `assets/mock/doctors.json`
- `assets/mock/appointments.json`

## Current Integration State

Current state of the repository:

- backend is ready and runs separately
- frontend still uses mock data
- if you want, the next step is switching Flutter repositories/services from `MockApiService` to real HTTP requests

## Additional Docs

Detailed backend notes are available in:

- [backend/README.md](backend/README.md)
