# 🪐 Pluto — Multi-Mode Social Platform

> **Date • Travel • Connect** — An India-first social platform combining Dating, TravelBuddy, and BFF modes in one app.

---

## 📦 Repository Structure

```
dating app/
├── pluto-backend/          # FastAPI Python backend
│   ├── app/
│   │   ├── api/v1/         # Route handlers (auth, users, swipes, matches, chats, trips, notifications)
│   │   ├── api/websocket.py # WebSocket + Redis Pub/Sub
│   │   ├── core/           # Config, DB, Redis, Firebase, logging, rate limiting
│   │   ├── models/         # SQLAlchemy ORM models (16 models)
│   │   ├── schemas/        # Pydantic v2 request/response models
│   │   ├── services/       # Business logic (MatchService, ChatService, TripService, UserService, FCM)
│   │   └── repositories/  # DB query layer
│   ├── migrations/init.sql # Full AlloyDB schema + seed data
│   ├── Dockerfile
│   ├── docker-compose.yml  # Local dev (Postgres + Redis)
│   └── cloudrun-service.yaml
│
├── pluto-flutter/          # Flutter mobile app
│   ├── lib/
│   │   ├── core/           # Theme, router, config, Dio client, WebSocket service
│   │   ├── features/
│   │   │   ├── auth/       # Splash, Login (OTP), Onboarding
│   │   │   ├── discover/   # Swipe deck, mode tabs
│   │   │   ├── trips/      # Feed, Detail, Create wizard
│   │   │   ├── chat/       # Chat list, Chat screen
│   │   │   └── profile/    # Profile, Settings
│   │   └── shared/         # SwipeCard, PlutoModeTabs, ShellScreen
│   └── pubspec.yaml
│
├── scripts/
│   ├── gcp_setup.sh        # One-time GCP infrastructure
│   └── run_migration.sh    # AlloyDB migration runner
└── cloudbuild.yaml         # Cloud Build CI/CD pipeline
```

---

## 🚀 Getting Started

### Prerequisites

| Tool | Install |
|------|---------|
| **Flutter** ≥ 3.19 | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| **Python** ≥ 3.12 | [python.org](https://python.org) |
| **Docker Desktop** | [docker.com](https://docker.com) |
| **gcloud CLI** | [cloud.google.com/sdk](https://cloud.google.com/sdk) |

---

### 1️⃣ Run Backend Locally (Docker)

```bash
cd pluto-backend

# Copy and fill environment variables
cp .env.example .env
# Edit .env with your Firebase credentials path

# Start Postgres + Redis + API
docker-compose up --build

# API will be live at: http://localhost:8080
# Swagger docs:       http://localhost:8080/docs
```

---

### 2️⃣ Run Database Migration

```bash
# After docker-compose is up:
docker exec -it pluto-db psql -U postgres -d pluto -f /docker-entrypoint-initdb.d/init.sql

# Or manually:
psql -h localhost -p 5432 -U postgres -d pluto -f migrations/init.sql
```

---

### 3️⃣ Flutter Setup

```bash
cd pluto-flutter

# Install Flutter SDK first (see prerequisite link above)
flutter pub get

# Add Firebase config files:
# Android: android/app/google-services.json
# iOS:     ios/Runner/GoogleService-Info.plist

# Run on emulator / device
flutter run --dart-define=ENV=dev
```

---

### 4️⃣ Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create project: **`pluto-app`**
3. Enable:
   - **Authentication** → Phone (and Google)
   - **Cloud Messaging** (FCM)
4. Download `google-services.json` → `pluto-flutter/android/app/`
5. Download `GoogleService-Info.plist` → `pluto-flutter/ios/Runner/`
6. Create **Service Account** key → save as `serviceAccountKey.json` in `pluto-backend/`
7. Set in `.env`:
   ```
   FIREBASE_CREDENTIALS_PATH=serviceAccountKey.json
   ```

---

### 5️⃣ Deploy to GCP (Production)

```bash
# 1. Authenticate
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# 2. One-time infrastructure setup (~10 min)
chmod +x scripts/gcp_setup.sh
bash scripts/gcp_setup.sh

# 3. Run DB migration on AlloyDB
bash scripts/run_migration.sh

# 4. Build & deploy to Cloud Run
gcloud builds submit --config cloudbuild.yaml

# 5. Get the API URL
gcloud run services describe pluto-backend \
  --region=asia-south1 \
  --format="value(status.url)"

# 6. Update Flutter AppConfig with the production API URL
# In lib/core/config/app_config.dart → 'prod' case
```

---

## 🏗️ Architecture

```
Flutter (iOS + Android)
       │  HTTPS/WSS
       ▼
Cloud Load Balancer
       │
Cloud Run (FastAPI, autoscale 1-20)
   ├── Auth      → Firebase Admin SDK
   ├── Users     → AlloyDB (PostGIS)
   ├── Discover  → AlloyDB + Redis cache
   ├── Swipe     → AlloyDB + match detection
   ├── Chat WS   → Redis Pub/Sub fan-out
   ├── Trips     → AlloyDB geo queries
   └── FCM       → Firebase Cloud Messaging
       │
   ┌───────────┐
   │ AlloyDB   │ PostgreSQL 15 + PostGIS
   │ Redis     │ Memorystore (cache + pub/sub)
   │ GCS       │ Media storage
   └───────────┘
```

---

## 🎨 App Modes & Colors

| Mode | Color | Use Case |
|------|-------|----------|
| **Date** ❤️ | `#FF4D6D` (Coral) | Dating swipe cards |
| **TravelBuddy** ✈️ | `#00BFA6` (Teal) | Group trip finder |
| **BFF** 🤝 | `#F5A623` (Amber) | Platonic friend finder |

---

## 🔑 Environment Variables

See `.env.example` in `pluto-backend/` for the complete list.

Key variables:

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | AlloyDB async connection URL |
| `REDIS_URL` | Memorystore Redis URL |
| `FIREBASE_CREDENTIALS_PATH` | Path to Firebase service account JSON |
| `GCS_BUCKET_NAME` | GCS bucket for user media |
| `CORS_ORIGINS` | Comma-separated allowed origins |

---

## 📱 Key Features

- **Swipe Deck** — Card swiper with Like/Dislike/Superlike across 3 modes
- **Geo-based Discovery** — PostGIS `ST_DWithin` with Redis-cached results
- **Trip Finder** — Search + join trips with optional entry fee (Razorpay)
- **Real-time Chat** — WebSocket + Redis Pub/Sub (scales across Cloud Run)
- **FCM Notifications** — Match alerts, messages, trip join notifications
- **Phone OTP Auth** — Firebase phone authentication

---

## 🛡️ Security

- Firebase JWT verification on every API request
- Redis sliding window rate limiting per endpoint
- Input validation via Pydantic v2
- Non-root Docker user
- Secrets via GCP Secret Manager (not in env files)

---

*Built with ❤️ using FastAPI + Flutter + Google Cloud*
