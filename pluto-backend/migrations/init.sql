-- ============================================================
-- Pluto Database — Initial Migration (AlloyDB / PostgreSQL 15)
-- ============================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ── Users ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    supabase_uid    VARCHAR(128) UNIQUE NOT NULL,
    email           VARCHAR(255) UNIQUE,
    phone           VARCHAR(20)  UNIQUE,
    username        VARCHAR(50)  UNIQUE,
    is_verified     BOOLEAN DEFAULT FALSE,
    is_active       BOOLEAN DEFAULT TRUE,
    is_premium      BOOLEAN DEFAULT FALSE,
    fcm_token       TEXT,
    last_seen       TIMESTAMPTZ DEFAULT NOW(),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_users_supabase_uid ON users(supabase_uid);
CREATE INDEX IF NOT EXISTS idx_users_username     ON users(username);

-- ── Profiles ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS profiles (
    id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id              UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    display_name         VARCHAR(60)  NOT NULL,
    bio                  TEXT,
    age                  SMALLINT NOT NULL CHECK (age >= 18 AND age <= 100),
    gender               VARCHAR(20) NOT NULL,
    active_mode          VARCHAR(15) DEFAULT 'DATE',
    date_visible         BOOLEAN DEFAULT TRUE,
    travel_visible       BOOLEAN DEFAULT TRUE,
    bff_visible          BOOLEAN DEFAULT TRUE,
    education            VARCHAR(120),
    occupation           VARCHAR(120),
    languages            TEXT[],
    height_cm            SMALLINT,
    is_profile_complete  BOOLEAN DEFAULT FALSE,
    updated_at           TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_profiles_user_id  ON profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_age      ON profiles(age);
CREATE INDEX IF NOT EXISTS idx_profiles_gender   ON profiles(gender);

-- ── Photos ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS photos (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    gcs_url       TEXT NOT NULL,
    thumbnail_url TEXT,
    display_order SMALLINT DEFAULT 0,
    is_verified   BOOLEAN DEFAULT FALSE,
    created_at    TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_photos_user_id ON photos(user_id, display_order);

-- ── Interests ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS interests (
    id       SMALLSERIAL PRIMARY KEY,
    name     VARCHAR(50) UNIQUE NOT NULL,
    category VARCHAR(50),
    icon     VARCHAR(10)
);

CREATE TABLE IF NOT EXISTS user_interests (
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    interest_id SMALLINT NOT NULL REFERENCES interests(id),
    PRIMARY KEY (user_id, interest_id)
);
CREATE INDEX IF NOT EXISTS idx_user_interests_user ON user_interests(user_id);

-- ── Locations (PostGIS) ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS locations (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id    UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    geom       GEOGRAPHY(POINT, 4326) NOT NULL,
    city       VARCHAR(100),
    state      VARCHAR(100),
    country    VARCHAR(100) DEFAULT 'India',
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_locations_geom    ON locations USING GIST(geom);
CREATE INDEX IF NOT EXISTS idx_locations_user_id ON locations(user_id);

-- ── Swipes ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS swipes (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    swiper_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    swiped_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    mode       VARCHAR(15) NOT NULL,
    action     VARCHAR(10) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (swiper_id, swiped_id, mode)
);
CREATE INDEX IF NOT EXISTS idx_swipes_swiper ON swipes(swiper_id, mode, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_swipes_swiped ON swipes(swiped_id, action, mode);

-- ── Matches ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS matches (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_a_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_b_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    mode       VARCHAR(15) NOT NULL,
    status     VARCHAR(15) DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_a_id, user_b_id, mode),
    CHECK (user_a_id < user_b_id)
);
CREATE INDEX IF NOT EXISTS idx_matches_user_a ON matches(user_a_id, status);
CREATE INDEX IF NOT EXISTS idx_matches_user_b ON matches(user_b_id, status);

-- ── Trips ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS trips (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title            VARCHAR(150) NOT NULL,
    description      TEXT,
    destination      VARCHAR(200) NOT NULL,
    destination_geom GEOGRAPHY(POINT, 4326),
    category         VARCHAR(60),
    difficulty       VARCHAR(30),
    start_date       DATE NOT NULL,
    end_date         DATE NOT NULL,
    max_members      SMALLINT NOT NULL DEFAULT 12,
    entry_fee_inr    NUMERIC(10,2) DEFAULT 0,
    cover_image_url  TEXT,
    status           VARCHAR(15) DEFAULT 'OPEN',
    meeting_point    TEXT,
    meeting_geom     GEOGRAPHY(POINT, 4326),
    temperature      VARCHAR(20),
    created_at       TIMESTAMPTZ DEFAULT NOW(),
    updated_at       TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_trips_creator   ON trips(creator_id);
CREATE INDEX IF NOT EXISTS idx_trips_status    ON trips(status, start_date);
CREATE INDEX IF NOT EXISTS idx_trips_dest_geom ON trips USING GIST(destination_geom);
CREATE INDEX IF NOT EXISTS idx_trips_fts       ON trips USING GIN(
    to_tsvector('english', title || ' ' || destination)
);

-- ── Trip Members ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS trip_members (
    trip_id     UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    joined_at   TIMESTAMPTZ DEFAULT NOW(),
    payment_ref VARCHAR(100),
    PRIMARY KEY (trip_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_trip_members_trip ON trip_members(trip_id);
CREATE INDEX IF NOT EXISTS idx_trip_members_user ON trip_members(user_id);

-- ── Chats ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS chats (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id        UUID REFERENCES matches(id) ON DELETE SET NULL,
    trip_id         UUID REFERENCES trips(id)   ON DELETE CASCADE,
    is_group        BOOLEAN DEFAULT FALSE,
    name            VARCHAR(100),
    last_message    TEXT,
    last_message_at TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_chats_match_id ON chats(match_id);
CREATE INDEX IF NOT EXISTS idx_chats_trip_id  ON chats(trip_id);

-- ── Chat Members ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS chat_members (
    chat_id   UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    user_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    last_read TIMESTAMPTZ,
    PRIMARY KEY (chat_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_chat_members_user ON chat_members(user_id);

-- ── Messages ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS messages (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chat_id    UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    sender_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content    TEXT,
    media_url  TEXT,
    msg_type   VARCHAR(10) DEFAULT 'TEXT',
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON messages(chat_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_sender  ON messages(sender_id);

-- ── Notifications ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type       VARCHAR(25) NOT NULL,
    title      VARCHAR(100),
    body       TEXT,
    data       JSONB,
    is_read    BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_notifs_user ON notifications(user_id, is_read, created_at DESC);

-- ── Blocks ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS blocks (
    blocker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (blocker_id, blocked_id)
);

-- ── Reports ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS reports (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID NOT NULL REFERENCES users(id),
    reported_id UUID NOT NULL REFERENCES users(id),
    reason      VARCHAR(30) NOT NULL,
    description TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── Seed Interests ──────────────────────────────────────────
INSERT INTO interests (name, category, icon) VALUES
  ('Live Music', 'Music & Entertainment', '🎵'),
  ('Movies', 'Music & Entertainment', '🎬'),
  ('Podcasts', 'Music & Entertainment', '🎙️'),
  ('Comedy', 'Music & Entertainment', '😂'),
  ('Travel', 'Lifestyle & Travel', '✈️'),
  ('Hiking', 'Lifestyle & Travel', '🥾'),
  ('Foodie', 'Lifestyle & Travel', '🍜'),
  ('Photography', 'Lifestyle & Travel', '📷'),
  ('Cycling', 'Lifestyle & Travel', '🚴'),
  ('Gaming', 'Creative & Tech', '🎮'),
  ('Coding', 'Creative & Tech', '💻'),
  ('Art & Design', 'Creative & Tech', '🎨'),
  ('Gym', 'Fitness & Health', '💪'),
  ('Yoga', 'Fitness & Health', '🧘'),
  ('Swimming', 'Fitness & Health', '🏊'),
  ('Meditation', 'Fitness & Health', '🧠'),
  ('Reading', 'Other', '📚'),
  ('Volunteering', 'Other', '🤝'),
  ('Specialty Coffee', 'Lifestyle & Travel', '☕'),
  ('Road Trips', 'Lifestyle & Travel', '🚗'),
  ('Backpacking', 'Lifestyle & Travel', '🎒'),
  ('Cricket', 'Fitness & Health', '🏏'),
  ('Badminton', 'Fitness & Health', '🏸'),
  ('Astrology', 'Other', '♈'),
  ('Languages', 'Other', '🌐')
ON CONFLICT (name) DO NOTHING;
