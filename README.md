# Pluto

Pluto is a multi-mode social app with Dating, TravelBuddy, and BFF flows built as a single repository.

Current stack:

- `pluto-flutter/`: Flutter mobile client
- `pluto-backend/`: FastAPI backend
- Supabase: auth and PostgreSQL database
- Cloudinary: image storage and delivery
- In-memory cache and rate limiting inside the FastAPI app

## Repository Structure

```text
dating app/
|-- pluto-backend/
|   |-- app/
|   |   |-- api/
|   |   |-- core/
|   |   |-- models/
|   |   |-- repositories/
|   |   |-- schemas/
|   |   `-- services/
|   |-- migrations/
|   |-- scripts/
|   |-- static/
|   `-- supabase/
`-- pluto-flutter/
    |-- lib/
    |-- assets/
    `-- test/
```

## Local Setup

### Backend

```bash
cd pluto-backend
cp .env.example .env
```

Set these values in `.env` before starting the API:

- `DATABASE_URL`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_KEY`
- `CLOUDINARY_CLOUD_NAME`
- `CLOUDINARY_API_KEY`
- `CLOUDINARY_API_SECRET`

Start the API:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8080
```

The backend serves:

- API base: `http://localhost:8080`
- OpenAPI docs: `http://localhost:8080/docs`

### Flutter

```bash
cd pluto-flutter
flutter pub get
flutter run --dart-define=ENV=dev
```

## Product Flow

The intended user flow is:

1. Onboarding
2. Login
3. Interest selection
4. Profile creation with photo upload
5. Discover and swiping
6. Matches and chat
7. Trips, applications, approvals, and group chat

## Deployment Notes

- The backend is designed around Supabase-backed Postgres.
- Media uploads should use Cloudinary in production.
- In-memory cache and rate limiting are suitable for a single app instance. If you scale horizontally, move these to a shared store.
- Do not commit `.env`, service account files, logs, or crash dumps.

## Status

This repo has been flattened into a single source of truth. The older `pluto-node-backend/` folder remains ignored and should be treated as legacy code unless you explicitly bring it back.
