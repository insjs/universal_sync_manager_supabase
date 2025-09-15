-- Minimal Supabase Schema Update
-- Purpose: Allow client-provided UUIDs without recreating tables
-- Step 1: Check current schema of organization_profiles
-- Run this first to see what columns actually exist
SELECT column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'organization_profiles'
    AND table_schema = 'public'
ORDER BY ordinal_position;
-- Step 2: Check current schema of audit_items
SELECT column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'audit_items'
    AND table_schema = 'public'
ORDER BY ordinal_position;
-- Step 3: If you just need to allow client-provided UUIDs, run these:
-- (Only run if your tables already exist with correct field names)
-- Remove DEFAULT UUID generation to allow client-provided IDs
-- ALTER TABLE organization_profiles ALTER COLUMN id DROP DEFAULT;
-- ALTER TABLE audit_items ALTER COLUMN id DROP DEFAULT;
-- Step 4: If missing columns need to be added:
-- (Uncomment and run only the ones that are missing)
-- For organization_profiles:
-- ALTER TABLE organization_profiles ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
-- ALTER TABLE organization_profiles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
-- For audit_items:
-- ALTER TABLE audit_items ADD COLUMN IF NOT EXISTS action TEXT;
-- ALTER TABLE audit_items ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
-- ALTER TABLE audit_items ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
-- =============================================================================
-- DEBUGGING NOTES:
-- 
-- The error "Could not find the 'createdAt' column" suggests either:
-- 1. The database table has camelCase columns but expects snake_case
-- 2. The USM adapter is transforming field names incorrectly
-- 3. There's a schema cache issue in Supabase
--
-- Run the SELECT statements above first to see what columns actually exist!
-- =============================================================================