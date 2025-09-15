-- MINIMAL SUPABASE SCHEMA FIX
-- Only add the missing fields that your test code expects
-- 1. Add missing 'action' field to audit_items table
ALTER TABLE public.audit_items
ADD COLUMN IF NOT EXISTS action TEXT NOT NULL DEFAULT 'unknown';
-- 2. Add missing fields that your test code expects
ALTER TABLE public.audit_items
ADD COLUMN IF NOT EXISTS details TEXT,
    ADD COLUMN IF NOT EXISTS entity_type TEXT,
    ADD COLUMN IF NOT EXISTS entity_id TEXT,
    ADD COLUMN IF NOT EXISTS changes JSONB DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS user_id UUID,
    ADD COLUMN IF NOT EXISTS "timestamp" TIMESTAMPTZ DEFAULT NOW();
-- 3. Add missing 'preferences' field to organization_profiles if needed
ALTER TABLE public.organization_profiles
ADD COLUMN IF NOT EXISTS preferences JSONB DEFAULT '{}';
-- 4. Ensure UUID columns can accept client-provided values (no DEFAULT)
-- Your tables already don't have DEFAULT for id, so this is already correct!
-- 5. Update app_settings to match expected field names
ALTER TABLE public.app_settings
    RENAME COLUMN setting_key TO key;
ALTER TABLE public.app_settings
    RENAME COLUMN setting_value TO value;
-- 6. Add missing is_public field to app_settings
ALTER TABLE public.app_settings
ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT true;
-- =============================================================================
-- SUMMARY OF FIXES:
-- ✅ audit_items: Added missing action, details, entity_type, entity_id, changes, user_id, timestamp fields
-- ✅ organization_profiles: Added missing preferences field  
-- ✅ app_settings: Renamed setting_key/setting_value to key/value, added is_public
-- ✅ All tables already have snake_case field names
-- ✅ All tables already accept client-provided UUIDs (no DEFAULT on id)
-- =============================================================================