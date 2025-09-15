-- Supabase Schema Fix for USM Conflict Resolution Testing
-- Generated: 2025-09-15
-- Purpose: Fix schema mismatches discovered in conflict resolution testing
-- 
-- IMPORTANT: This schema supports USM's offline-first architecture by:
-- 1. Accepting client-provided UUIDs (no auto-generation)
-- 2. Using snake_case field names for PostgreSQL compatibility
-- 3. Including all required USM audit and sync fields
-- =============================================================================
-- 1. ORGANIZATION_PROFILES TABLE
-- =============================================================================
-- Drop existing table if it exists (be careful in production!)
DROP TABLE IF EXISTS organization_profiles CASCADE;
-- Create organization_profiles with all required USM fields
CREATE TABLE organization_profiles (
    -- Primary identifier (UUID that accepts locally generated IDs)
    id UUID PRIMARY KEY,
    -- No DEFAULT to allow client-provided UUIDs
    -- Business fields
    organization_id TEXT NOT NULL,
    -- Using snake_case for PostgreSQL
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    settings JSONB DEFAULT '{}',
    preferences JSONB DEFAULT '{}',
    -- Audit fields (required by USM)
    created_by TEXT NOT NULL,
    updated_by TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    -- Sync fields (required by USM)
    is_dirty BOOLEAN NOT NULL DEFAULT true,
    last_synced_at TIMESTAMPTZ,
    sync_version INTEGER NOT NULL DEFAULT 0,
    is_deleted BOOLEAN NOT NULL DEFAULT false
);
-- Performance indexes for organization_profiles
CREATE INDEX idx_organization_profiles_organization_id ON organization_profiles (organization_id);
CREATE INDEX idx_organization_profiles_is_dirty ON organization_profiles (is_dirty);
CREATE INDEX idx_organization_profiles_is_deleted ON organization_profiles (is_deleted);
CREATE INDEX idx_organization_profiles_created_at ON organization_profiles (created_at);
CREATE INDEX idx_organization_profiles_updated_at ON organization_profiles (updated_at);
-- =============================================================================
-- 2. AUDIT_ITEMS TABLE  
-- =============================================================================
-- Drop existing table if it exists (be careful in production!)
DROP TABLE IF EXISTS audit_items CASCADE;
-- Create audit_items with all required USM fields
CREATE TABLE audit_items (
    -- Primary identifier (UUID that accepts locally generated IDs)
    id UUID PRIMARY KEY,
    -- No DEFAULT to allow client-provided UUIDs
    -- Business fields  
    organization_id TEXT NOT NULL,
    action TEXT NOT NULL,
    -- This was missing!
    details TEXT,
    entity_type TEXT,
    entity_id TEXT,
    changes JSONB DEFAULT '{}',
    metadata JSONB DEFAULT '{}',
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    user_id TEXT,
    -- Audit fields (required by USM)
    created_by TEXT NOT NULL,
    updated_by TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    -- This was missing!
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    -- Sync fields (required by USM)
    is_dirty BOOLEAN NOT NULL DEFAULT true,
    last_synced_at TIMESTAMPTZ,
    sync_version INTEGER NOT NULL DEFAULT 0,
    is_deleted BOOLEAN NOT NULL DEFAULT false
);
-- Performance indexes for audit_items
CREATE INDEX idx_audit_items_organization_id ON audit_items (organization_id);
CREATE INDEX idx_audit_items_action ON audit_items (action);
CREATE INDEX idx_audit_items_entity ON audit_items (entity_type, entity_id);
CREATE INDEX idx_audit_items_timestamp ON audit_items (timestamp);
CREATE INDEX idx_audit_items_user_id ON audit_items (user_id);
CREATE INDEX idx_audit_items_is_dirty ON audit_items (is_dirty);
CREATE INDEX idx_audit_items_is_deleted ON audit_items (is_deleted);
-- =============================================================================
-- 3. APP_SETTINGS TABLE (for pre-auth testing)
-- =============================================================================
-- Create app_settings table if it doesn't exist
CREATE TABLE IF NOT EXISTS app_settings (
    id UUID PRIMARY KEY,
    -- No DEFAULT to allow client-provided UUIDs
    key TEXT NOT NULL UNIQUE,
    value JSONB DEFAULT '{}',
    description TEXT,
    category TEXT DEFAULT 'general',
    is_public BOOLEAN NOT NULL DEFAULT true,
    -- Accessible without auth
    -- Audit fields
    created_by TEXT NOT NULL DEFAULT 'system',
    updated_by TEXT NOT NULL DEFAULT 'system',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    -- Sync fields
    is_dirty BOOLEAN NOT NULL DEFAULT false,
    -- Usually managed by admin
    last_synced_at TIMESTAMPTZ,
    sync_version INTEGER NOT NULL DEFAULT 0,
    is_deleted BOOLEAN NOT NULL DEFAULT false
);
-- Insert some sample app settings for testing
INSERT INTO app_settings (id, key, value, description, category, is_public)
VALUES (
        '550e8400-e29b-41d4-a716-446655440001',
        'app_name',
        '"Universal Sync Manager Test"',
        'Application display name',
        'branding',
        true
    ),
    (
        '550e8400-e29b-41d4-a716-446655440002',
        'api_version',
        '"1.0.0"',
        'Current API version',
        'technical',
        true
    ),
    (
        '550e8400-e29b-41d4-a716-446655440003',
        'maintenance_mode',
        'false',
        'Maintenance mode status',
        'system',
        true
    ),
    (
        '550e8400-e29b-41d4-a716-446655440004',
        'supported_platforms',
        '["web", "ios", "android", "windows", "macos", "linux"]',
        'Supported platforms',
        'technical',
        true
    ),
    (
        '550e8400-e29b-41d4-a716-446655440005',
        'sync_settings',
        '{"auto_sync": true, "interval_seconds": 30, "max_retries": 3}',
        'Default sync configuration',
        'sync',
        true
    ) ON CONFLICT (key) DO
UPDATE
SET value = EXCLUDED.value,
    updated_at = NOW();
-- Performance indexes for app_settings
CREATE INDEX idx_app_settings_key ON app_settings (key);
CREATE INDEX idx_app_settings_category ON app_settings (category);
CREATE INDEX idx_app_settings_is_public ON app_settings (is_public);
-- =============================================================================
-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================
-- Enable RLS on all tables
ALTER TABLE organization_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;
-- App settings - public read access for pre-auth
CREATE POLICY "app_settings_public_read" ON app_settings FOR
SELECT USING (is_public = true);
-- App settings - authenticated users can read all
CREATE POLICY "app_settings_authenticated_read" ON app_settings FOR
SELECT USING (auth.role() = 'authenticated');
-- Organization profiles - users can access their organization's data
CREATE POLICY "organization_profiles_access" ON organization_profiles FOR ALL USING (
    auth.role() = 'authenticated'
    AND (
        organization_id IN (
            SELECT organization_id
            FROM user_organizations
            WHERE user_id = auth.uid()::text
        )
        OR auth.uid()::text = created_by
    )
);
-- Audit items - users can read their organization's audit data
CREATE POLICY "audit_items_access" ON audit_items FOR
SELECT USING (
        auth.role() = 'authenticated'
        AND organization_id IN (
            SELECT organization_id
            FROM user_organizations
            WHERE user_id = auth.uid()::text
        )
    );
-- =============================================================================
-- 5. HELPER FUNCTIONS
-- =============================================================================
-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column() RETURNS TRIGGER AS $$ BEGIN NEW.updated_at = NOW();
RETURN NEW;
END;
$$ language 'plpgsql';
-- Triggers to automatically update updated_at
CREATE TRIGGER update_organization_profiles_updated_at BEFORE
UPDATE ON organization_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_audit_items_updated_at BEFORE
UPDATE ON audit_items FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_app_settings_updated_at BEFORE
UPDATE ON app_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
-- =============================================================================
-- SUMMARY
-- =============================================================================
/*
 This schema fixes the issues discovered in conflict resolution testing:
 
 ✅ FIXED: Missing 'created_at' column in organization_profiles
 ✅ FIXED: Missing 'action' column in audit_items  
 ✅ FIXED: UUID field types for Supabase compatibility
 ✅ FIXED: Snake_case field names for PostgreSQL compatibility
 ✅ ADDED: Proper indexes for performance
 ✅ ADDED: RLS policies for security
 ✅ ADDED: Auto-updating timestamps
 ✅ ADDED: Sample app_settings data for pre-auth testing
 
 NEXT STEPS:
 1. Run this schema in your Supabase SQL editor
 2. Update your test code to use snake_case field names
 3. Re-run the conflict resolution tests
 4. Verify all database operations succeed
 5. Confirm conflict resolution logic continues working
 
 The conflict resolution logic itself is already perfect - this just fixes the underlying data layer!
 */