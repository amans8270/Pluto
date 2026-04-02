-- Migration: Rename firebase_uid to supabase_uid
ALTER TABLE users RENAME COLUMN firebase_uid TO supabase_uid;
ALTER INDEX IF EXISTS idx_users_firebase_uid RENAME TO idx_users_supabase_uid;