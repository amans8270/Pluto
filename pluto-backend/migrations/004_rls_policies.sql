-- ============================================================
-- Pluto — Row Level Security (RLS) Policies
-- Apply this in Supabase SQL Editor AFTER init.sql
-- ============================================================

-- ── Enable RLS on all tables ──────────────────────────────
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_interests ENABLE ROW LEVEL SECURITY;
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE swipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE trip_members ENABLE ROW LEVEL SECURITY;

-- ── Helper function: get internal user_id from auth.uid() ──
CREATE OR REPLACE FUNCTION auth_user_id()
RETURNS UUID AS $$
  SELECT id FROM users WHERE supabase_uid = auth.uid()::text LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- ── Users Table ───────────────────────────────────────────
DROP POLICY IF EXISTS "users_select_own" ON users;
CREATE POLICY "users_select_own" ON users
  FOR SELECT USING (supabase_uid = auth.uid()::text);

DROP POLICY IF EXISTS "users_update_own" ON users;
CREATE POLICY "users_update_own" ON users
  FOR UPDATE USING (supabase_uid = auth.uid()::text);

-- ── Profiles Table ────────────────────────────────────────
DROP POLICY IF EXISTS "profiles_select_all" ON profiles;
CREATE POLICY "profiles_select_all" ON profiles
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "profiles_insert_own" ON profiles;
CREATE POLICY "profiles_insert_own" ON profiles
  FOR INSERT WITH CHECK (user_id = auth_user_id());

DROP POLICY IF EXISTS "profiles_update_own" ON profiles;
CREATE POLICY "profiles_update_own" ON profiles
  FOR UPDATE USING (user_id = auth_user_id());

-- ── Photos Table ──────────────────────────────────────────
DROP POLICY IF EXISTS "photos_select_all" ON photos;
CREATE POLICY "photos_select_all" ON photos
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "photos_insert_own" ON photos;
CREATE POLICY "photos_insert_own" ON photos
  FOR INSERT WITH CHECK (user_id = auth_user_id());

DROP POLICY IF EXISTS "photos_delete_own" ON photos;
CREATE POLICY "photos_delete_own" ON photos
  FOR DELETE USING (user_id = auth_user_id());

-- ── User Interests ────────────────────────────────────────
DROP POLICY IF EXISTS "user_interests_select_all" ON user_interests;
CREATE POLICY "user_interests_select_all" ON user_interests
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "user_interests_insert_own" ON user_interests;
CREATE POLICY "user_interests_insert_own" ON user_interests
  FOR INSERT WITH CHECK (user_id = auth_user_id());

DROP POLICY IF EXISTS "user_interests_delete_own" ON user_interests;
CREATE POLICY "user_interests_delete_own" ON user_interests
  FOR DELETE USING (user_id = auth_user_id());

-- ── Locations Table (CRITICAL — GPS privacy) ─────────────
DROP POLICY IF EXISTS "locations_select_own" ON locations;
CREATE POLICY "locations_select_own" ON locations
  FOR SELECT USING (user_id = auth_user_id());

DROP POLICY IF EXISTS "locations_insert_own" ON locations;
CREATE POLICY "locations_insert_own" ON locations
  FOR INSERT WITH CHECK (user_id = auth_user_id());

DROP POLICY IF EXISTS "locations_update_own" ON locations;
CREATE POLICY "locations_update_own" ON locations
  FOR UPDATE USING (user_id = auth_user_id());

-- ── Swipes Table ──────────────────────────────────────────
DROP POLICY IF EXISTS "swipes_select_own" ON swipes;
CREATE POLICY "swipes_select_own" ON swipes
  FOR SELECT USING (swiper_id = auth_user_id());

DROP POLICY IF EXISTS "swipes_insert_own" ON swipes;
CREATE POLICY "swipes_insert_own" ON swipes
  FOR INSERT WITH CHECK (swiper_id = auth_user_id());

-- ── Matches Table ─────────────────────────────────────────
DROP POLICY IF EXISTS "matches_select_own" ON matches;
CREATE POLICY "matches_select_own" ON matches
  FOR SELECT USING (
    user_a_id = auth_user_id() OR user_b_id = auth_user_id()
  );

-- ── Chats Table ───────────────────────────────────────────
DROP POLICY IF EXISTS "chats_select_members" ON chats;
CREATE POLICY "chats_select_members" ON chats
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM chat_members cm
      WHERE cm.chat_id = chats.id
      AND cm.user_id = auth_user_id()
    )
  );

-- ── Chat Members ──────────────────────────────────────────
DROP POLICY IF EXISTS "chat_members_select_own" ON chat_members;
CREATE POLICY "chat_members_select_own" ON chat_members
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM chat_members cm
      WHERE cm.chat_id = chat_members.chat_id
      AND cm.user_id = auth_user_id()
    )
  );

-- ── Messages Table (CRITICAL — private chats) ────────────
DROP POLICY IF EXISTS "messages_select_members" ON messages;
CREATE POLICY "messages_select_members" ON messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM chat_members cm
      WHERE cm.chat_id = messages.chat_id
      AND cm.user_id = auth_user_id()
    )
  );

DROP POLICY IF EXISTS "messages_insert_members" ON messages;
CREATE POLICY "messages_insert_members" ON messages
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM chat_members cm
      WHERE cm.chat_id = messages.chat_id
      AND cm.user_id = auth_user_id()
    )
    AND sender_id = auth_user_id()
  );

-- ── Notifications Table ───────────────────────────────────
DROP POLICY IF EXISTS "notifications_select_own" ON notifications;
CREATE POLICY "notifications_select_own" ON notifications
  FOR SELECT USING (user_id = auth_user_id());

DROP POLICY IF EXISTS "notifications_update_own" ON notifications;
CREATE POLICY "notifications_update_own" ON notifications
  FOR UPDATE USING (user_id = auth_user_id());

-- ── Blocks Table ──────────────────────────────────────────
DROP POLICY IF EXISTS "blocks_select_own" ON blocks;
CREATE POLICY "blocks_select_own" ON blocks
  FOR SELECT USING (blocker_id = auth_user_id());

DROP POLICY IF EXISTS "blocks_insert_own" ON blocks;
CREATE POLICY "blocks_insert_own" ON blocks
  FOR INSERT WITH CHECK (blocker_id = auth_user_id());

-- ── Reports Table ─────────────────────────────────────────
DROP POLICY IF EXISTS "reports_insert_own" ON reports;
CREATE POLICY "reports_insert_own" ON reports
  FOR INSERT WITH CHECK (reporter_id = auth_user_id());

-- ── Trips Table ───────────────────────────────────────────
DROP POLICY IF EXISTS "trips_select_all" ON trips;
CREATE POLICY "trips_select_all" ON trips
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "trips_insert_own" ON trips;
CREATE POLICY "trips_insert_own" ON trips
  FOR INSERT WITH CHECK (creator_id = auth_user_id());

DROP POLICY IF EXISTS "trips_update_own" ON trips;
CREATE POLICY "trips_update_own" ON trips
  FOR UPDATE USING (creator_id = auth_user_id());

DROP POLICY IF EXISTS "trips_delete_own" ON trips;
CREATE POLICY "trips_delete_own" ON trips
  FOR DELETE USING (creator_id = auth_user_id());

-- ── Trip Members ──────────────────────────────────────────
DROP POLICY IF EXISTS "trip_members_select_all" ON trip_members;
CREATE POLICY "trip_members_select_all" ON trip_members
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "trip_members_insert_own" ON trip_members;
CREATE POLICY "trip_members_insert_own" ON trip_members
  FOR INSERT WITH CHECK (user_id = auth_user_id());

-- ── Missing Index for chat_members (performance) ──────────
CREATE INDEX IF NOT EXISTS idx_chat_members_chat_user 
  ON chat_members(chat_id, user_id);
