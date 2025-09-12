# Supabase Database Schema for Universal Sync Manager Testing

## Overview
This document details the complete database schema required for comprehensive Universal Sync Manager (USM) testing with Supabase. The schema includes both pre-authentication (public) and post-authentication (organization-scoped) tables to validate all sync scenarios.

## Schema Design Principles

### Field Naming Convention
- **Database Fields**: `snake_case` (organization_id, created_at, updated_at)
- **Dart Properties**: `camelCase` (organizationId, createdAt, updatedAt)
- **Field Mapping**: USM handles automatic conversion between conventions

### Access Control Strategy
- **Pre-Auth Tables**: Public access, no Row Level Security (RLS)
- **Post-Auth Tables**: Organization-scoped access with RLS policies
- **Authentication**: Supabase Auth with JWT-based organization isolation

### Sync Metadata Fields
All tables include standard USM sync metadata:
- `created_at`, `updated_at`: Timestamp tracking
- `created_by`, `updated_by`: User tracking
- `sync_version`: Conflict resolution versioning
- `is_dirty`: Local change tracking
- `last_synced_at`: Sync timestamp
- `is_deleted`: Soft delete flag
- `deleted_at`: Deletion timestamp

---

## Table Specifications

### 1. PRE-AUTH TABLES (Public Access)

#### 1.1 app_settings
**Purpose**: Application configuration and settings accessible without authentication
**Access**: Public read access, no RLS
**Sync Direction**: Download-only (read-only for clients)

```sql
CREATE TABLE app_settings (
  -- Primary identification
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Core fields
  setting_key TEXT NOT NULL UNIQUE,
  setting_value TEXT,
  category TEXT DEFAULT 'general',
  is_active BOOLEAN DEFAULT true,
  
  -- Audit fields (optional for public tables)
  created_by UUID,
  updated_by UUID,
  
  -- Timestamp fields
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  
  -- Sync metadata
  is_dirty BOOLEAN DEFAULT true,
  last_synced_at TIMESTAMPTZ,
  sync_version INTEGER DEFAULT 0,
  is_deleted BOOLEAN DEFAULT false
);

-- Indexes for performance
CREATE INDEX idx_app_settings_key ON app_settings(setting_key);
CREATE INDEX idx_app_settings_category ON app_settings(category);
CREATE INDEX idx_app_settings_active ON app_settings(is_active);
```

**Sample Data**:
```sql
INSERT INTO app_settings (setting_key, setting_value, category) VALUES 
('app_version', '1.0.0', 'general'),
('maintenance_mode', 'false', 'system'),
('max_file_size', '10485760', 'uploads'),
('api_rate_limit', '1000', 'api'),
('theme_default', 'light', 'ui');
```

#### 1.2 public_announcements
**Purpose**: Public announcements and notifications visible to all users
**Access**: Public read access, no RLS
**Sync Direction**: Download-only (read-only for clients)

```sql
CREATE TABLE public_announcements (
  -- Primary identification
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Core fields
  title TEXT NOT NULL,
  content TEXT,
  priority INTEGER DEFAULT 0,
  is_published BOOLEAN DEFAULT false,
  
  -- Audit fields (optional for public tables)
  created_by UUID,
  updated_by UUID,
  
  -- Timestamp fields
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  
  -- Sync metadata
  is_dirty BOOLEAN DEFAULT true,
  last_synced_at TIMESTAMPTZ,
  sync_version INTEGER DEFAULT 0,
  is_deleted BOOLEAN DEFAULT false
);

-- Indexes for performance
CREATE INDEX idx_public_announcements_published ON public_announcements(is_published);
CREATE INDEX idx_public_announcements_priority ON public_announcements(priority);
CREATE INDEX idx_public_announcements_created ON public_announcements(created_at);
```

**Sample Data**:
```sql
INSERT INTO public_announcements (title, content, priority, is_published) VALUES 
('Welcome Message', 'Welcome to our application! We''re excited to have you.', 1, true),
('Maintenance Notice', 'Scheduled maintenance on Sunday from 2-4 AM UTC.', 2, true),
('New Features', 'Check out our latest features in the settings panel.', 0, true),
('Holiday Hours', 'Support will have limited hours during holidays.', 1, false);
```

### 2. POST-AUTH TABLES (Organization-Scoped)

#### 2.1 organization_profiles
**Purpose**: Organization information and configuration
**Access**: Organization-scoped with RLS
**Sync Direction**: Bidirectional (full CRUD operations)

```sql
CREATE TABLE organization_profiles (
  -- Primary identification
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Organization context (required for RLS)
  organization_id UUID NOT NULL,
  
  -- Core fields
  name TEXT NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  settings JSONB DEFAULT '{}',
  
  -- Audit fields (required for authenticated tables)
  created_by UUID NOT NULL,
  updated_by UUID NOT NULL,
  
  -- Timestamp fields
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  
  -- Sync metadata
  is_dirty BOOLEAN DEFAULT true,
  last_synced_at TIMESTAMPTZ,
  sync_version INTEGER DEFAULT 0,
  is_deleted BOOLEAN DEFAULT false
);

-- Indexes for performance
CREATE INDEX idx_organization_profiles_org_id ON organization_profiles(organization_id);
CREATE INDEX idx_organization_profiles_active ON organization_profiles(is_active);
CREATE INDEX idx_organization_profiles_name ON organization_profiles(name);

-- Enable Row Level Security
ALTER TABLE organization_profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only access their organization's data
CREATE POLICY "organization_profiles_org_access" 
ON organization_profiles FOR ALL 
USING (organization_id::text = auth.jwt() ->> 'organization_id');
```

#### 2.2 audit_items
**Purpose**: Audit items and compliance tracking
**Access**: Organization-scoped with RLS
**Sync Direction**: Bidirectional (full CRUD operations)

```sql
CREATE TABLE audit_items (
  -- Primary identification
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Organization context (required for RLS)
  organization_id UUID NOT NULL,
  
  -- Core fields
  title TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'pending',
  priority INTEGER DEFAULT 0,
  due_date TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}',
  
  -- Audit fields (required for authenticated tables)
  created_by UUID NOT NULL,
  updated_by UUID NOT NULL,
  
  -- Timestamp fields
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  
  -- Sync metadata
  is_dirty BOOLEAN DEFAULT true,
  last_synced_at TIMESTAMPTZ,
  sync_version INTEGER DEFAULT 0,
  is_deleted BOOLEAN DEFAULT false
);

-- Indexes for performance
CREATE INDEX idx_audit_items_org_id ON audit_items(organization_id);
CREATE INDEX idx_audit_items_status ON audit_items(status);
CREATE INDEX idx_audit_items_priority ON audit_items(priority);
CREATE INDEX idx_audit_items_due_date ON audit_items(due_date);
CREATE INDEX idx_audit_items_created_by ON audit_items(created_by);

-- Enable Row Level Security
ALTER TABLE audit_items ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only access their organization's data
CREATE POLICY "audit_items_org_access" 
ON audit_items FOR ALL 
USING (organization_id::text = auth.jwt() ->> 'organization_id');
```

---

## Authentication & Security Setup

### Supabase Auth Configuration

```sql
-- Enable anonymous authentication (for testing)
-- This should be configured in Supabase Dashboard > Authentication > Settings

-- Custom claims function for organization context
CREATE OR REPLACE FUNCTION auth.organization_context()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- In production, this would fetch from user_organizations table
  -- For testing, return a default organization
  RETURN jsonb_build_object(
    'organization_id', 'test-org-uuid-here'
  );
END;
$$;
```

### RLS Policy Patterns

```sql
-- Pattern 1: Organization-scoped access
CREATE POLICY "table_name_org_access" 
ON table_name FOR ALL 
USING (organization_id::text = auth.jwt() ->> 'organization_id');

-- Pattern 2: User-specific access (if needed)
CREATE POLICY "table_name_user_access" 
ON table_name FOR ALL 
USING (created_by = auth.uid());

-- Pattern 3: Combined organization and user access
CREATE POLICY "table_name_combined_access" 
ON table_name FOR ALL 
USING (
  organization_id::text = auth.jwt() ->> 'organization_id' 
  AND created_by = auth.uid()
);
```

---

## Database Functions & Triggers

### Auto-update timestamp trigger

```sql
-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to all tables
CREATE TRIGGER update_app_settings_updated_at 
  BEFORE UPDATE ON app_settings 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_public_announcements_updated_at 
  BEFORE UPDATE ON public_announcements 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_organization_profiles_updated_at 
  BEFORE UPDATE ON organization_profiles 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_audit_items_updated_at 
  BEFORE UPDATE ON audit_items 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### Sync version increment trigger

```sql
-- Function to increment sync_version on updates
CREATE OR REPLACE FUNCTION increment_sync_version()
RETURNS TRIGGER AS $$
BEGIN
  NEW.sync_version = COALESCE(OLD.sync_version, 0) + 1;
  NEW.is_dirty = true;
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to sync-enabled tables
CREATE TRIGGER increment_organization_profiles_sync_version 
  BEFORE UPDATE ON organization_profiles 
  FOR EACH ROW EXECUTE FUNCTION increment_sync_version();

CREATE TRIGGER increment_audit_items_sync_version 
  BEFORE UPDATE ON audit_items 
  FOR EACH ROW EXECUTE FUNCTION increment_sync_version();
```

---

## Testing Data Sets

### Minimal Test Data

```sql
-- App settings for basic functionality
INSERT INTO app_settings (setting_key, setting_value, category) VALUES 
('app_version', '1.0.0', 'general'),
('maintenance_mode', 'false', 'system');

-- Public announcements for content sync
INSERT INTO public_announcements (title, content, priority, is_published) VALUES 
('Test Announcement', 'This is a test announcement.', 1, true);

-- Note: Organization data will be created through USM testing
-- to validate proper authentication and field mapping
```

### Extended Test Data (for comprehensive testing)

```sql
-- More comprehensive app settings
INSERT INTO app_settings (setting_key, setting_value, category) VALUES 
('max_file_size', '10485760', 'uploads'),
('api_rate_limit', '1000', 'api'),
('theme_default', 'light', 'ui'),
('feature_beta_enabled', 'true', 'features'),
('smtp_host', 'smtp.example.com', 'email'),
('backup_frequency', '24', 'system');

-- Multiple announcements with different priorities
INSERT INTO public_announcements (title, content, priority, is_published) VALUES 
('Welcome Message', 'Welcome to our application!', 1, true),
('Maintenance Notice', 'Scheduled maintenance Sunday 2-4 AM UTC.', 2, true),
('New Features', 'Check out our latest features.', 0, true),
('Holiday Hours', 'Limited support during holidays.', 1, false),
('Security Update', 'Important security update available.', 3, true);
```

---

## Field Mapping Reference

### USM Field Mapping (Database ↔ Dart)

| Database Field (snake_case) | Dart Property (camelCase) | Purpose |
|------------------------------|---------------------------|---------|
| `organization_id`            | `organizationId`          | Organization context |
| `created_at`                 | `createdAt`               | Creation timestamp |
| `updated_at`                 | `updatedAt`               | Last modification |
| `created_by`                 | `createdBy`               | Creating user |
| `updated_by`                 | `updatedBy`               | Last modifying user |
| `sync_version`               | `syncVersion`             | Conflict resolution |
| `last_synced_at`             | `lastSyncedAt`            | Last sync timestamp |
| `is_deleted`                 | `isDeleted`               | Soft delete flag |
| `deleted_at`                 | `deletedAt`               | Deletion timestamp |
| `is_dirty`                   | `isDirty`                 | Local change flag |

---

## Implementation Checklist

### Database Setup
- [ ] Create Supabase project
- [ ] Execute table creation scripts
- [ ] Set up RLS policies
- [ ] Create database functions and triggers
- [ ] Insert sample data
- [ ] Test RLS policies with test users

### USM Integration Testing
- [ ] Verify pre-auth table access without authentication
- [ ] Test authentication flow
- [ ] Validate post-auth table access with RLS
- [ ] Confirm field mapping accuracy (snake_case ↔ camelCase)
- [ ] Test CRUD operations with proper field transformation
- [ ] Validate conflict resolution with sync_version

### Performance Validation
- [ ] Verify index effectiveness
- [ ] Test query performance with larger datasets
- [ ] Monitor sync operation efficiency
- [ ] Validate memory usage during sync

This schema provides a comprehensive foundation for testing all Universal Sync Manager features with Supabase, ensuring both pre-auth and post-auth scenarios work correctly with the snake_case field migration.
