-- ============================================================
-- Pluto Database - Optimization Migrations
-- Phase 1: TOAST Compression, Soft Deletes, Indexes
-- ============================================================

-- Enable pg_stat_statements for query monitoring
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- ============================================================
-- TOAST Compression for TEXT columns
-- Reduces storage by 40-70% for large text fields
-- ============================================================

-- Profiles table - compress bio
ALTER TABLE profiles ALTER COLUMN bio SET STORAGE EXTENDED;

-- Trips table - compress description
ALTER TABLE trips ALTER COLUMN description SET STORAGE EXTENDED;

-- Messages table - compress content
ALTER TABLE messages ALTER COLUMN content SET STORAGE EXTENDED;

-- Chats table - compress last_message
ALTER TABLE chats ALTER COLUMN last_message SET STORAGE EXTENDED;

-- Reports table - compress description
ALTER TABLE reports ALTER COLUMN description SET STORAGE EXTENDED;

-- Notifications table - compress body
ALTER TABLE notifications ALTER COLUMN body SET STORAGE EXTENDED;

-- ============================================================
-- Soft Delete Support
-- Adds is_deleted flag without modifying existing records
-- ============================================================

-- Add is_deleted column to messages (if not exists)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'messages' AND column_name = 'is_deleted'
    ) THEN
        ALTER TABLE messages ADD COLUMN is_deleted BOOLEAN DEFAULT FALSE;
    END IF;
END $$;

-- Add is_archived column to chats
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'chats' AND column_name = 'is_archived'
    ) THEN
        ALTER TABLE chats ADD COLUMN is_archived BOOLEAN DEFAULT FALSE;
    END IF;
END $$;

-- Add is_active column to trips
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'trips' AND column_name = 'is_active'
    ) THEN
        ALTER TABLE trips ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
    END IF;
END $$;

-- ============================================================
-- Performance Indexes
-- Optimize common query patterns
-- ============================================================

-- Swipes: Discovery optimization (filter by LIKE action)
CREATE INDEX IF NOT EXISTS idx_swipes_discovery 
ON swipes(swiped_id, mode, created_at DESC) 
WHERE action = 'LIKE';

-- Messages: Recent messages (exclude deleted)
CREATE INDEX IF NOT EXISTS idx_messages_recent 
ON messages(chat_id, created_at DESC) 
WHERE is_deleted = FALSE;

-- Matches: Active matches optimization
CREATE INDEX IF NOT EXISTS idx_matches_active 
ON matches(user_a_id, status) 
WHERE status = 'ACTIVE';

CREATE INDEX IF NOT EXISTS idx_matches_active_b 
ON matches(user_b_id, status) 
WHERE status = 'ACTIVE';

-- Trips: Upcoming trips
CREATE INDEX IF NOT EXISTS idx_trips_upcoming 
ON trips(start_date DESC) 
WHERE status = 'OPEN' AND is_active = TRUE;

-- Users: Active users for discovery
CREATE INDEX IF NOT EXISTS idx_users_active 
ON users(last_seen DESC) 
WHERE is_active = TRUE;

-- Locations: Users by distance (PostGIS index already exists)
-- Add index on updated_at for location freshness
CREATE INDEX IF NOT EXISTS idx_locations_updated 
ON locations(updated_at DESC);

-- ============================================================
-- Optimized Fill Factor
-- Reduces page fragmentation for frequently updated tables
-- ============================================================

-- Messages table - high update frequency
ALTER TABLE messages SET (fillfactor = 70);

-- Swipes table - high insert frequency
ALTER TABLE swipes SET (fillfactor = 80);

-- ============================================================
-- Partial Indexes for Common Queries
-- ============================================================

-- Unread notifications
CREATE INDEX IF NOT EXISTS idx_notifications_unread 
ON notifications(user_id, created_at DESC) 
WHERE is_read = FALSE;

-- User interests for matching
CREATE INDEX IF NOT EXISTS idx_user_interests_interest 
ON user_interests(interest_id);

-- ============================================================
-- Composite Indexes for Complex Queries
-- ============================================================

-- Profile discovery: gender + age + active_mode
CREATE INDEX IF NOT EXISTS idx_profiles_discovery 
ON profiles(gender, age, active_mode) 
WHERE is_profile_complete = TRUE;

-- Trip search: status + start_date + category
CREATE INDEX IF NOT EXISTS idx_trips_search 
ON trips(status, start_date, category) 
WHERE is_active = TRUE;

-- ============================================================
-- Analyze tables to update statistics
-- ============================================================
ANALYZE users;
ANALYZE profiles;
ANALYZE messages;
ANALYZE chats;
ANALYZE trips;
ANALYZE swipes;
ANALYZE matches;
