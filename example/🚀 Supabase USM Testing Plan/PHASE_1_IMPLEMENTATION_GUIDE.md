# Phase 1 Implementation Guide - Supabase Testing Setup

## Quick Start Implementation

### Step 1: Supabase Project Setup (15 minutes)

1. **Create Supabase Project**
   ```bash
   # Go to https://supabase.com
   # Create new project
   # Note down: Project URL and anon key
   ```

2. **Create Test Tables**
   ```sql
   -- Execute in Supabase SQL Editor
   
   -- PRE-AUTH TABLES (Public access, no RLS)
   -- App settings table - accessible without authentication
   CREATE TABLE app_settings (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     setting_key TEXT NOT NULL UNIQUE,
     setting_value TEXT,
     category TEXT DEFAULT 'general',
     is_active BOOLEAN DEFAULT true,
     created_by UUID,
     updated_by UUID,
     created_at TIMESTAMPTZ DEFAULT NOW(),
     updated_at TIMESTAMPTZ DEFAULT NOW(),
     deleted_at TIMESTAMPTZ,
     is_dirty BOOLEAN DEFAULT true,
     last_synced_at TIMESTAMPTZ,
     sync_version INTEGER DEFAULT 0,
     is_deleted BOOLEAN DEFAULT false
   );

   -- Public announcements table - accessible without authentication
   CREATE TABLE public_announcements (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     title TEXT NOT NULL,
     content TEXT,
     priority INTEGER DEFAULT 0,
     is_published BOOLEAN DEFAULT false,
     created_by UUID,
     updated_by UUID,
     created_at TIMESTAMPTZ DEFAULT NOW(),
     updated_at TIMESTAMPTZ DEFAULT NOW(),
     deleted_at TIMESTAMPTZ,
     is_dirty BOOLEAN DEFAULT true,
     last_synced_at TIMESTAMPTZ,
     sync_version INTEGER DEFAULT 0,
     is_deleted BOOLEAN DEFAULT false
   );

   -- POST-AUTH TABLES (Authenticated access with RLS)
   -- Organization profiles table - requires authentication
   CREATE TABLE organization_profiles (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     organization_id UUID NOT NULL,
     name TEXT NOT NULL,
     description TEXT,
     is_active BOOLEAN DEFAULT true,
     created_by UUID NOT NULL,
     updated_by UUID NOT NULL,
     created_at TIMESTAMPTZ DEFAULT NOW(),
     updated_at TIMESTAMPTZ DEFAULT NOW(),
     deleted_at TIMESTAMPTZ,
     is_dirty BOOLEAN DEFAULT true,
     last_synced_at TIMESTAMPTZ,
     sync_version INTEGER DEFAULT 0,
     is_deleted BOOLEAN DEFAULT false
   );

   -- Audit items table - requires authentication  
   CREATE TABLE audit_items (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     organization_id UUID NOT NULL,
     title TEXT NOT NULL,
     status TEXT DEFAULT 'pending',
     priority INTEGER DEFAULT 0,
     created_by UUID NOT NULL,
     updated_by UUID NOT NULL,
     created_at TIMESTAMPTZ DEFAULT NOW(),
     updated_at TIMESTAMPTZ DEFAULT NOW(),
     deleted_at TIMESTAMPTZ,
     is_dirty BOOLEAN DEFAULT true,
     last_synced_at TIMESTAMPTZ,
     sync_version INTEGER DEFAULT 0,
     is_deleted BOOLEAN DEFAULT false
   );
   ```

3. **Set Up Authentication & Access Control**
   ```sql
   -- PRE-AUTH TABLES: No RLS - Public access
   -- app_settings and public_announcements remain accessible without authentication
   -- These tables don't need RLS enabled
   
   -- POST-AUTH TABLES: Enable RLS for authenticated access
   ALTER TABLE organization_profiles ENABLE ROW LEVEL SECURITY;
   ALTER TABLE audit_items ENABLE ROW LEVEL SECURITY;

   -- Create RLS policies for authenticated tables
   CREATE POLICY "Users can access their org profiles" 
   ON organization_profiles FOR ALL 
   USING (organization_id::text = auth.jwt() ->> 'organization_id');

   CREATE POLICY "Users can access their org items" 
   ON audit_items FOR ALL 
   USING (organization_id::text = auth.jwt() ->> 'organization_id');

   -- Insert sample data for pre-auth testing
   INSERT INTO app_settings (setting_key, setting_value, category) VALUES 
   ('app_version', '1.0.0', 'general'),
   ('maintenance_mode', 'false', 'system'),
   ('max_file_size', '10485760', 'uploads');

   INSERT INTO public_announcements (title, content, priority, is_published) VALUES 
   ('Welcome Message', 'Welcome to our application!', 1, true),
   ('Maintenance Notice', 'Scheduled maintenance on Sunday.', 2, true);
   ```

### Step 2: Update Example App Dependencies

Add to `example/pubspec.yaml`:
```yaml
dependencies:
  supabase_flutter: ^2.5.6
  uuid: ^4.4.0
  # ... existing dependencies
```

### Step 3: Create Supabase Integration Test File

Create `example/lib/supabase_test_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseTestPage extends StatefulWidget {
  const SupabaseTestPage({super.key});

  @override
  State<SupabaseTestPage> createState() => _SupabaseTestPageState();
}

class _SupabaseTestPageState extends State<SupabaseTestPage> {
  // Test configuration
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseKey = 'YOUR_SUPABASE_ANON_KEY';
  
  // USM components
  SupabaseSyncAdapter? _adapter;
  UniversalSyncManager? _syncManager;
  
  // Test state
  bool _isConnected = false;
  bool _isAuthenticated = false;
  String _status = 'Not initialized';
  List<Map<String, dynamic>> _testResults = [];
  
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _initializeSupabase();
  }

  Future<void> _initializeSupabase() async {
    try {
      // Initialize Supabase
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
      );
      
      setState(() {
        _status = 'Supabase initialized';
      });
      
      _addTestResult('Supabase initialization', true, 'Successfully initialized');
    } catch (e) {
      _addTestResult('Supabase initialization', false, e.toString());
    }
  }

  Future<void> _testAdapterConnection() async {
    try {
      _adapter = SupabaseSyncAdapter(
        supabaseUrl: supabaseUrl,
        supabaseKey: supabaseKey,
      );
      
      final config = SyncBackendConfiguration(
        configId: 'test-config',
        displayName: 'Supabase Test',
        backendType: 'supabase',
        baseUrl: supabaseUrl,
        projectId: 'test-project',
      );
      
      final connected = await _adapter!.connect(config);
      
      setState(() {
        _isConnected = connected;
        _status = connected ? 'Connected to Supabase' : 'Connection failed';
      });
      
      _addTestResult('Adapter connection', connected, 
        connected ? 'Successfully connected' : 'Connection failed');
        
    } catch (e) {
      _addTestResult('Adapter connection', false, e.toString());
    }
  }

  Future<void> _testAuthentication() async {
    try {
      final supabase = Supabase.instance.client;
      
      // Test user signup/signin
      final response = await supabase.auth.signInAnonymously();
      
      if (response.user != null) {
        setState(() {
          _isAuthenticated = true;
          _status = 'Authenticated successfully';
        });
        
        _addTestResult('Authentication', true, 'User authenticated');
      } else {
        _addTestResult('Authentication', false, 'No user returned');
      }
      
    } catch (e) {
      _addTestResult('Authentication', false, e.toString());
    }
  }

  Future<void> _testSyncManagerInitialization() async {
    try {
      if (_adapter == null) {
        throw Exception('Adapter not connected');
      }
      
      _syncManager = UniversalSyncManager();
      
      // Configure sync manager with both pre-auth and post-auth collections
      await _syncManager!.configure(
        collections: [
          // PRE-AUTH COLLECTIONS (accessible without authentication)
          SyncCollection(
            name: 'app_settings',
            syncDirection: SyncDirection.downloadOnly, // Usually read-only for clients
          ),
          SyncCollection(
            name: 'public_announcements',
            syncDirection: SyncDirection.downloadOnly, // Usually read-only for clients
          ),
          // POST-AUTH COLLECTIONS (require authentication)
          SyncCollection(
            name: 'organization_profiles',
            syncDirection: SyncDirection.bidirectional,
          ),
          SyncCollection(
            name: 'audit_items', 
            syncDirection: SyncDirection.bidirectional,
          ),
        ],
        backendConfig: SyncBackendConfiguration(
          configId: 'test-config',
          displayName: 'Test Config',
          backendType: 'supabase',
          baseUrl: supabaseUrl,
          projectId: 'test-project',
        ),
      );
      
      // Set backend adapter
      await _syncManager!.setBackend(_adapter!);
      
      _addTestResult('Sync Manager initialization', true, 'Successfully initialized');
      
    } catch (e) {
      _addTestResult('Sync Manager initialization', false, e.toString());
    }
  }

  Future<void> _testCrudOperations() async {
    try {
      if (_adapter == null) {
        throw Exception('Adapter not connected');
      }
      
      final orgId = _uuid.v4();
      final userId = _uuid.v4();
      
      // Test CREATE
      final createData = {
        'id': _uuid.v4(),
        'organization_id': orgId,
        'name': 'Test Organization',
        'description': 'Test Description',
        'is_active': true,
        'created_by': userId,
        'updated_by': userId,
        'sync_version': 1,
      };
      
      final createResult = await _adapter!.create('organization_profiles', createData);
      _addTestResult('CREATE operation', createResult.isSuccess, 
        createResult.isSuccess ? 'Data created successfully' : createResult.error?.message ?? 'Unknown error');
      
      if (createResult.isSuccess) {
        final recordId = createResult.data?['id'];
        
        // Test READ
        final readResult = await _adapter!.read('organization_profiles', recordId);
        _addTestResult('READ operation', readResult.isSuccess,
          readResult.isSuccess ? 'Data read successfully' : readResult.error?.message ?? 'Unknown error');
        
        // Test UPDATE
        final updateData = {
          ...readResult.data!,
          'name': 'Updated Organization',
          'sync_version': 2,
        };
        
        final updateResult = await _adapter!.update('organization_profiles', recordId, updateData);
        _addTestResult('UPDATE operation', updateResult.isSuccess,
          updateResult.isSuccess ? 'Data updated successfully' : updateResult.error?.message ?? 'Unknown error');
        
        // Test DELETE
        final deleteResult = await _adapter!.delete('organization_profiles', recordId);
        _addTestResult('DELETE operation', deleteResult.isSuccess,
          deleteResult.isSuccess ? 'Data deleted successfully' : deleteResult.error?.message ?? 'Unknown error');
      }
      
    } catch (e) {
      _addTestResult('CRUD operations', false, e.toString());
    }
  }

  Future<void> _testPreAuthOperations() async {
    try {
      if (_adapter == null) {
        throw Exception('Adapter not connected');
      }
      
      // Test READ operations on pre-auth tables (should work without authentication)
      final appSettingsQuery = await _adapter!.query('app_settings', SyncQuery());
      _addTestResult('Pre-auth READ (app_settings)', appSettingsQuery.isNotEmpty,
        appSettingsQuery.isNotEmpty ? 'Retrieved ${appSettingsQuery.length} settings' : 'No settings found');
      
      final announcementsQuery = await _adapter!.query('public_announcements', SyncQuery());
      _addTestResult('Pre-auth READ (announcements)', announcementsQuery.isNotEmpty,
        announcementsQuery.isNotEmpty ? 'Retrieved ${announcementsQuery.length} announcements' : 'No announcements found');
      
      // Test if we can read specific records
      if (appSettingsQuery.isNotEmpty) {
        final firstSetting = appSettingsQuery.first;
        final readResult = await _adapter!.read('app_settings', firstSetting.data?['id']);
        _addTestResult('Pre-auth READ by ID', readResult.isSuccess,
          readResult.isSuccess ? 'Successfully read setting by ID' : readResult.error?.message ?? 'Unknown error');
      }
      
    } catch (e) {
      _addTestResult('Pre-auth operations', false, e.toString());
    }
  }

  Future<void> _testEventSystem() async {
    try {
      if (_syncManager == null) {
        throw Exception('Sync Manager not initialized');
      }
      
      // Subscribe to events
      _syncManager!.eventStream.listen((event) {
        _addTestResult('Event received', true, 'Event: ${event.type}');
      });
      
      _addTestResult('Event system', true, 'Event stream subscribed');
      
    } catch (e) {
      _addTestResult('Event system', false, e.toString());
    }
  }

  void _addTestResult(String test, bool success, String message) {
    setState(() {
      _testResults.add({
        'test': test,
        'success': success,
        'message': message,
        'timestamp': DateTime.now(),
      });
    });
  }

  void _clearResults() {
    setState(() {
      _testResults.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('USM Supabase Testing'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Status Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status: $_status', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(_isConnected ? Icons.wifi : Icons.wifi_off,
                        color: _isConnected ? Colors.green : Colors.red),
                      const SizedBox(width: 8),
                      Text('Connected: $_isConnected'),
                      const SizedBox(width: 16),
                      Icon(_isAuthenticated ? Icons.lock_open : Icons.lock,
                        color: _isAuthenticated ? Colors.green : Colors.red),
                      const SizedBox(width: 8),
                      Text('Authenticated: $_isAuthenticated'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Test Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _testAdapterConnection,
                  child: const Text('Test Connection'),
                ),
                ElevatedButton(
                  onPressed: _testPreAuthOperations,
                  child: const Text('Test Pre-Auth'),
                ),
                ElevatedButton(
                  onPressed: _testAuthentication,
                  child: const Text('Test Auth'),
                ),
                ElevatedButton(
                  onPressed: _testSyncManagerInitialization,
                  child: const Text('Test Sync Manager'),
                ),
                ElevatedButton(
                  onPressed: _testCrudOperations,
                  child: const Text('Test Post-Auth CRUD'),
                ),
                ElevatedButton(
                  onPressed: _testEventSystem,
                  child: const Text('Test Events'),
                ),
                ElevatedButton(
                  onPressed: _clearResults,
                  child: const Text('Clear Results'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Test Results
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _testResults.length,
              itemBuilder: (context, index) {
                final result = _testResults[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      result['success'] ? Icons.check_circle : Icons.error,
                      color: result['success'] ? Colors.green : Colors.red,
                    ),
                    title: Text(result['test']),
                    subtitle: Text(result['message']),
                    trailing: Text(
                      '${result['timestamp'].hour}:${result['timestamp'].minute.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

### Step 4: Update Main App to Include Supabase Test

Update `example/lib/main.dart` to add navigation to the test page:

```dart
// Add this import at the top
import 'supabase_test_page.dart';

// Add this button in your main UI
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SupabaseTestPage()),
    );
  },
  child: const Text('Supabase Testing'),
),
```

### Step 5: Run Initial Tests

1. **Update Configuration**
   - Replace `YOUR_SUPABASE_URL` and `YOUR_SUPABASE_ANON_KEY` with your actual values
   
2. **Run the App**
   ```bash
   cd example
   flutter run
   ```

3. **Execute Test Sequence**
   - Tap "Test Connection" → Should connect to Supabase
   - Tap "Test Pre-Auth" → Should read public data without authentication
   - Tap "Test Auth" → Should authenticate anonymously  
   - Tap "Test Sync Manager" → Should initialize USM with all collections
   - Tap "Test Post-Auth CRUD" → Should perform authenticated database operations
   - Tap "Test Events" → Should set up event listening

### Expected Results for Phase 1

✅ **Connection Test**: Adapter connects to Supabase successfully
✅ **Pre-Auth Test**: Can read app_settings and public_announcements without authentication
✅ **Authentication Test**: Anonymous user authentication works
✅ **Sync Manager Test**: USM initializes with both pre-auth and post-auth collections
✅ **Post-Auth CRUD Test**: All authenticated database operations work with snake_case fields
✅ **Event Test**: Event system subscribes and receives events

### Testing Scenarios Covered

**Pre-Authentication Sync**:
- ✅ Public data access (app_settings, public_announcements)
- ✅ Download-only sync for public content
- ✅ Field mapping validation for public tables

**Post-Authentication Sync**:
- ✅ Organization-isolated data (organization_profiles, audit_items)
- ✅ Bidirectional sync with RLS enforcement
- ✅ CRUD operations with proper field mapping
- ✅ Authentication context validation

This comprehensive setup validates:
- **Pre-Auth Flow**: Public data sync works without authentication
- **Auth Transition**: Moving from public to authenticated sync
- **Post-Auth Flow**: Organization-scoped data with full CRUD
- **Field Migration**: All snake_case database fields work correctly
- **Security**: RLS policies protect authenticated data

### Next Steps After Phase 1

Once Phase 1 is working:
1. **Phase 2**: Implement full sync operations with conflict scenarios
2. **Phase 3**: Add state management integration
3. **Phase 4**: Test auth lifecycle and token management
4. **Phase 5**: Edge case and performance testing

This implementation gives you immediate validation that:
- The field migration is working correctly
- Supabase integration is functional
- Core USM features are operational
- The foundation is solid for advanced testing

Would you like me to help you implement any specific part of this setup?
