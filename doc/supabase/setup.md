# Supabase Setup & Configuration

Complete database setup and configuration guide for Universal Sync Manager with Supabase.

## 📋 Prerequisites

- Supabase project ([supabase.com](https://supabase.com))
- Flutter project with Universal Sync Manager dependency
- Basic understanding of SQL and database design

## 🗄️ Database Schema Setup

### 1. Create Required Tables

Run these SQL commands in your Supabase SQL Editor:

#### User Profiles Table (Authenticated)
```sql
-- Main user profiles table
CREATE TABLE user_profiles (
  -- Primary key
  id TEXT PRIMARY KEY,

  -- Organization isolation
  organization_id TEXT NOT NULL,

  -- Business fields
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,

  -- Audit fields (required)
  created_by TEXT NOT NULL,
  updated_by TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE,

  -- Sync fields (required)
  is_dirty BOOLEAN NOT NULL DEFAULT true,
  last_synced_at TIMESTAMP WITH TIME ZONE,
  sync_version INTEGER NOT NULL DEFAULT 0,
  is_deleted BOOLEAN NOT NULL DEFAULT false
);

-- Performance indexes
CREATE INDEX idx_user_profiles_organization_id ON user_profiles(organization_id);
CREATE INDEX idx_user_profiles_is_dirty ON user_profiles(is_dirty);
CREATE INDEX idx_user_profiles_is_deleted ON user_profiles(is_deleted);
CREATE INDEX idx_user_profiles_email ON user_profiles(email);
```

#### App Settings Table (Public)
```sql
-- Public configuration table
CREATE TABLE app_settings (
  -- Primary key
  id TEXT PRIMARY KEY,

  -- Configuration fields
  key TEXT NOT NULL UNIQUE,
  value JSONB,
  description TEXT,

  -- Audit fields
  created_by TEXT NOT NULL,
  updated_by TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Sync fields (not used for public data)
  is_dirty BOOLEAN NOT NULL DEFAULT false,
  last_synced_at TIMESTAMP WITH TIME ZONE,
  sync_version INTEGER NOT NULL DEFAULT 0,
  is_deleted BOOLEAN NOT NULL DEFAULT false
);

-- Index for fast lookups
CREATE INDEX idx_app_settings_key ON app_settings(key);
```

#### Organizations Table (Optional)
```sql
-- Organization management
CREATE TABLE organizations (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,

  -- Audit fields
  created_by TEXT NOT NULL,
  updated_by TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE,

  -- Sync fields
  is_dirty BOOLEAN NOT NULL DEFAULT true,
  last_synced_at TIMESTAMP WITH TIME ZONE,
  sync_version INTEGER NOT NULL DEFAULT 0,
  is_deleted BOOLEAN NOT NULL DEFAULT false
);

-- Indexes
CREATE INDEX idx_organizations_is_active ON organizations(is_active);
```

### 2. Enable Row Level Security (RLS)

```sql
-- Enable RLS on all tables
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
```

### 3. Create Security Policies

#### User Profiles Policies
```sql
-- Users can view profiles in their organization
CREATE POLICY "Users can view their organization's profiles"
  ON user_profiles FOR SELECT
  USING (auth.jwt() ->> 'organization_id' = organization_id);

-- Users can insert profiles in their organization
CREATE POLICY "Users can insert their organization's profiles"
  ON user_profiles FOR INSERT
  WITH CHECK (auth.jwt() ->> 'organization_id' = organization_id);

-- Users can update profiles in their organization
CREATE POLICY "Users can update their organization's profiles"
  ON user_profiles FOR UPDATE
  USING (auth.jwt() ->> 'organization_id' = organization_id)
  WITH CHECK (auth.jwt() ->> 'organization_id' = organization_id);

-- Users can delete profiles in their organization (soft delete)
CREATE POLICY "Users can soft delete their organization's profiles"
  ON user_profiles FOR UPDATE
  USING (auth.jwt() ->> 'organization_id' = organization_id)
  WITH CHECK (auth.jwt() ->> 'organization_id' = organization_id);
```

#### App Settings Policies (Public Read)
```sql
-- Anyone can read app settings (public data)
CREATE POLICY "Anyone can read app settings"
  ON app_settings FOR SELECT
  USING (true);

-- Only authenticated users can modify settings
CREATE POLICY "Authenticated users can manage app settings"
  ON app_settings FOR ALL
  USING (auth.role() = 'authenticated');
```

#### Organizations Policies
```sql
-- Users can view their organization
CREATE POLICY "Users can view their organization"
  ON organizations FOR SELECT
  USING (auth.jwt() ->> 'organization_id' = id);

-- Organization admins can manage their organization
CREATE POLICY "Organization admins can manage their organization"
  ON organizations FOR ALL
  USING (auth.jwt() ->> 'organization_id' = id AND
         auth.jwt() ->> 'role' = 'admin');
```

## 🔧 Flutter Configuration

### 1. Environment Variables

Create a `.env` file in your Flutter project:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here
```

### 2. Supabase Initialization

```dart
// lib/config/supabase_config.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }

  static String get url => dotenv.env['SUPABASE_URL']!;
  static String get anonKey => dotenv.env['SUPABASE_ANON_KEY']!;
  static String get serviceRoleKey => dotenv.env['SUPABASE_SERVICE_ROLE_KEY']!;
}
```

### 3. Universal Sync Manager Setup

```dart
// lib/config/sync_config.dart
import 'package:universal_sync_manager/universal_sync_manager.dart';
import 'supabase_config.dart';

class SyncConfig {
  static Future<UniversalSyncManager> initialize() async {
    final syncManager = UniversalSyncManager();

    await syncManager.initialize(
      UniversalSyncConfig(
        projectId: 'your-project-id',
        syncMode: SyncMode.automatic,
        syncInterval: Duration(minutes: 15),
        enableConflictResolution: true,
        enableRealTimeSync: true,
      ),
    );

    // Create Supabase adapter
    final supabaseAdapter = SupabaseSyncAdapter(
      supabaseUrl: SupabaseConfig.url,
      supabaseAnonKey: SupabaseConfig.anonKey,
      connectionTimeout: Duration(seconds: 30),
      requestTimeout: Duration(seconds: 15),
    );

    await syncManager.setBackend(supabaseAdapter);

    // Register entities
    _registerEntities(syncManager);

    return syncManager;
  }

  static void _registerEntities(UniversalSyncManager syncManager) {
    // User profiles
    syncManager.registerEntity(
      'user_profiles',
      SyncEntityConfig(
        tableName: 'user_profiles',
        requiresAuthentication: true,
        conflictStrategy: ConflictResolutionStrategy.serverWins,
        enableRealTimeSync: true,
      ),
    );

    // App settings (public)
    syncManager.registerEntity(
      'app_settings',
      SyncEntityConfig(
        tableName: 'app_settings',
        requiresAuthentication: false,
        conflictStrategy: ConflictResolutionStrategy.clientWins,
        enableRealTimeSync: false, // Public data doesn't need real-time
      ),
    );

    // Organizations
    syncManager.registerEntity(
      'organizations',
      SyncEntityConfig(
        tableName: 'organizations',
        requiresAuthentication: true,
        conflictStrategy: ConflictResolutionStrategy.serverWins,
        enableRealTimeSync: true,
      ),
    );
  }
}
```

### 4. App Initialization

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'config/supabase_config.dart';
import 'config/sync_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseConfig.initialize();

  // Initialize Sync Manager
  final syncManager = await SyncConfig.initialize();

  runApp(MyApp(syncManager: syncManager));
}

class MyApp extends StatelessWidget {
  final UniversalSyncManager syncManager;

  const MyApp({super.key, required this.syncManager});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(syncManager: syncManager),
    );
  }
}
```

## 🧪 Testing Configuration

### 1. Test User Setup

Create a test user in Supabase Auth:

```sql
-- Insert test user (password: '123456789')
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  invited_at,
  confirmation_token,
  confirmation_sent_at,
  recovery_token,
  recovery_sent_at,
  email_change_token_new,
  email_change,
  email_change_sent_at,
  last_sign_in_at,
  raw_app_meta_data,
  raw_user_meta_data,
  is_super_admin,
  created_at,
  updated_at,
  phone,
  phone_confirmed_at,
  phone_change,
  phone_change_token,
  phone_change_sent_at,
  email_change_token_current,
  email_change_confirm_status,
  banned_until,
  reauthentication_token,
  reauthentication_sent_at
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  '550e8400-e29b-41d4-a716-446655440000',
  'authenticated',
  'authenticated',
  'admin@has.com',
  crypt('123456789', gen_salt('bf')),
  NOW(),
  NULL,
  '',
  NULL,
  '',
  NULL,
  '',
  '',
  NULL,
  NULL,
  '{"provider": "email", "providers": ["email"]}',
  '{"organization_id": "org-test-123"}',
  FALSE,
  NOW(),
  NOW(),
  NULL,
  NULL,
  '',
  '',
  NULL,
  '',
  0,
  NULL,
  '',
  NULL
);
```

### 2. Test Data Setup

```sql
-- Insert test organization
INSERT INTO organizations (
  id, name, description, is_active,
  created_by, updated_by, is_dirty, sync_version, is_deleted
) VALUES (
  'org-test-123',
  'Test Organization',
  'Organization for testing USM',
  true,
  'system',
  'system',
  false,
  1,
  false
);

-- Insert test app settings
INSERT INTO app_settings (
  id, key, value, description,
  created_by, updated_by, is_dirty, sync_version, is_deleted
) VALUES (
  'settings-app-version',
  'app_version',
  '"1.0.0"',
  'Current application version',
  'system',
  'system',
  false,
  1,
  false
);
```

## 🔍 Verification Steps

### 1. Database Verification

```sql
-- Check table creation
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('user_profiles', 'app_settings', 'organizations');

-- Check RLS status
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('user_profiles', 'app_settings', 'organizations');

-- Check policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE schemaname = 'public';
```

### 2. Flutter App Verification

```dart
// Test connection
final adapter = SupabaseSyncAdapter(
  supabaseUrl: SupabaseConfig.url,
  supabaseAnonKey: SupabaseConfig.anonKey,
);

final connected = await adapter.connect(SyncBackendConfiguration(
  configId: 'test',
  displayName: 'Test Connection',
  backendType: 'supabase',
  baseUrl: SupabaseConfig.url,
  projectId: 'test-project',
));

print('Supabase connection: $connected');
```

## 🚀 Next Steps

Once your database is configured:

1. **[Authentication Guide](../authentication.md)** - Set up user authentication
2. **[CRUD Operations](../crud_operations.md)** - Start working with data
3. **[Testing Guide](../testing.md)** - Test your complete setup

## 🆘 Troubleshooting

**Connection Issues:**
- Verify Supabase URL and keys in `.env`
- Check Supabase project status
- Ensure RLS policies allow your operations

**Authentication Issues:**
- Confirm test user exists in Supabase Auth
- Check JWT token contains `organization_id`
- Verify RLS policies match your user claims

**Sync Issues:**
- Check table schemas match the requirements
- Verify indexes are created for performance
- Ensure sync fields are properly initialized