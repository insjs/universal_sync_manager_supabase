# Troubleshooting Guide

Common issues and solutions for Universal Sync Manager with Supabase integration.

## 🚨 Quick Issue Resolution

### App Won't Start

**Symptoms:**
- App crashes on startup
- White screen on launch
- Error: "Failed to initialize UniversalSyncManager"

**Solutions:**

1. **Check Supabase Configuration**
```dart
// Verify your Supabase setup
await Supabase.initialize(
  url: 'your-supabase-url', // Make sure this is correct
  anonKey: 'your-anon-key',  // Make sure this is correct
);
```

2. **Verify Project Configuration**
```dart
final config = UniversalSyncConfig(
  projectId: 'your-project-id', // Must be unique and consistent
  syncMode: SyncMode.automatic,
);
```

3. **Check Entity Registration**
```dart
// Ensure entities are registered before use
syncManager.registerEntity(
  'user_profiles',
  SyncEntityConfig(tableName: 'user_profiles'),
);
```

### Authentication Issues

**Symptoms:**
- Login fails
- "Invalid login credentials" error
- User profile not created automatically

**Solutions:**

1. **Verify User Credentials**
```dart
try {
  final response = await Supabase.instance.client.auth.signInWithPassword(
    email: email,
    password: password,
  );

  if (response.user != null) {
    print('Login successful: ${response.user!.id}');
  }
} catch (e) {
  print('Login failed: $e');
}
```

2. **Check User Profile Creation**
```dart
// After successful login, check if profile exists
final result = await syncManager.query(
  'user_profiles',
  SyncQuery(filters: {'id': userId}),
);

if (result.data?.isEmpty ?? true) {
  // Create profile if it doesn't exist
  final newProfile = UserProfile.create(
    id: userId,
    organizationId: 'your-org-id',
    name: email.split('@').first,
    email: email,
    createdBy: userId,
  );

  await syncManager.create('user_profiles', newProfile.toJson());
}
```

3. **Verify RLS Policies**
```sql
-- Ensure your RLS policies allow user access
CREATE POLICY "Users can view own profile" ON user_profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = id);
```

### Sync Issues

**Symptoms:**
- Data not syncing
- "Sync failed" errors
- Local changes not appearing on server

**Solutions:**

1. **Check Network Connectivity**
```dart
// Test basic connectivity
try {
  final result = await syncManager.query('app_settings', SyncQuery(limit: 1));
  if (result.isSuccess) {
    print('Network connection OK');
  }
} catch (e) {
  print('Network issue: $e');
}
```

2. **Manual Sync Test**
```dart
// Try manual sync
final result = await syncManager.syncEntity('user_profiles');
if (result.isSuccess) {
  print('Sync successful: ${result.affectedItems} items');
} else {
  print('Sync failed: ${result.error?.message}');
}
```

3. **Check Dirty Records**
```dart
// Find unsynced records
final result = await syncManager.query(
  'user_profiles',
  SyncQuery(filters: {'is_dirty': true}),
);

print('Found ${result.data?.length ?? 0} dirty records');
```

4. **Verify Backend Connection**
```dart
// Test backend connectivity
final backend = SupabaseSyncAdapter();
final connected = await backend.connect(SyncBackendConfiguration(
  url: 'your-supabase-url',
  apiKey: 'your-anon-key',
));

if (connected) {
  print('Backend connection OK');
} else {
  print('Backend connection failed');
}
```

### Real-time Update Issues

**Symptoms:**
- Changes not appearing in real-time
- Subscription not working
- No live updates

**Solutions:**

1. **Check Subscription Setup**
```dart
// Verify subscription is active
final subscription = syncManager.subscribe(
  'user_profiles',
  SyncSubscriptionOptions(),
);

subscription.listen((event) {
  print('Real-time event: ${event.type}');
});
```

2. **Test Real-time Permissions**
```sql
-- Ensure real-time is enabled for your tables
ALTER PUBLICATION supabase_realtime ADD TABLE user_profiles;
```

3. **Verify Real-time Policies**
```sql
-- Check RLS policies allow real-time access
CREATE POLICY "Users can receive real-time updates" ON user_profiles
  FOR SELECT USING (auth.uid() = id);
```

### Conflict Resolution Issues

**Symptoms:**
- Conflicts not being resolved
- Manual conflict resolution not working
- Data inconsistency

**Solutions:**

1. **Check Conflict Resolver**
```dart
// Set up conflict resolver
syncManager.setConflictResolver(
  'user_profiles',
  CustomConflictResolver(),
);

class CustomConflictResolver implements ConflictResolver {
  @override
  SyncConflictResolution resolveConflict(SyncConflict conflict) {
    print('Conflict detected: ${conflict.fieldConflicts}');
    return SyncConflictResolution.useServer(); // or useClient()
  }
}
```

2. **Verify Conflict Detection**
```dart
// Check for conflicts during sync
final result = await syncManager.syncEntity('user_profiles');
if (result.conflictsResolved > 0) {
  print('Resolved ${result.conflictsResolved} conflicts');
}
```

3. **Manual Conflict Resolution**
```dart
// Handle conflicts manually
syncManager.setConflictResolver(
  'user_profiles',
  ManualConflictResolver(),
);

class ManualConflictResolver implements ConflictResolver {
  @override
  SyncConflictResolution resolveConflict(SyncConflict conflict) {
    // Show conflict dialog to user
    showConflictDialog(conflict);
    return SyncConflictResolution.manual();
  }
}
```

## 🔍 Detailed Diagnostics

### Connection Diagnostics

```dart
class ConnectionDiagnostics {
  final UniversalSyncManager _syncManager;

  Future<Map<String, dynamic>> runDiagnostics() async {
    final results = <String, dynamic>{};

    // Test Supabase connection
    results['supabase_connection'] = await _testSupabaseConnection();

    // Test USM initialization
    results['usm_initialization'] = await _testUSMInitialization();

    // Test entity registration
    results['entity_registration'] = await _testEntityRegistration();

    // Test basic CRUD
    results['basic_crud'] = await _testBasicCRUD();

    // Test sync functionality
    results['sync_functionality'] = await _testSyncFunctionality();

    return results;
  }

  Future<bool> _testSupabaseConnection() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      return user != null;
    } catch (e) {
      print('Supabase connection test failed: $e');
      return false;
    }
  }

  Future<bool> _testUSMInitialization() async {
    try {
      // Try a simple query
      final result = await _syncManager.query('app_settings', SyncQuery(limit: 1));
      return result.isSuccess;
    } catch (e) {
      print('USM initialization test failed: $e');
      return false;
    }
  }

  Future<bool> _testEntityRegistration() async {
    try {
      final result = await _syncManager.query('user_profiles', SyncQuery(limit: 1));
      return true; // If no exception, entity is registered
    } catch (e) {
      print('Entity registration test failed: $e');
      return false;
    }
  }

  Future<Map<String, bool>> _testBasicCRUD() async {
    final results = <String, bool>{};

    try {
      // Test Create
      final testProfile = UserProfile.create(
        organizationId: 'diag-test-org',
        name: 'Diagnostic Test User',
        email: 'diag-test@example.com',
        createdBy: 'diagnostic-test',
      );

      final createResult = await _syncManager.create('user_profiles', testProfile.toJson());
      results['create'] = createResult.isSuccess;

      if (createResult.isSuccess) {
        final profileId = createResult.data!['id'];

        // Test Read
        final readResult = await _syncManager.query(
          'user_profiles',
          SyncQuery(filters: {'id': profileId}),
        );
        results['read'] = readResult.isSuccess && readResult.data!.isNotEmpty;

        // Test Update
        final updateData = testProfile.copyWith(name: 'Updated Diagnostic User').toJson();
        final updateResult = await _syncManager.update('user_profiles', profileId, updateData);
        results['update'] = updateResult.isSuccess;

        // Test Delete
        final deleteResult = await _syncManager.delete('user_profiles', profileId);
        results['delete'] = deleteResult.isSuccess;
      }
    } catch (e) {
      print('CRUD test failed: $e');
      results['create'] = false;
      results['read'] = false;
      results['update'] = false;
      results['delete'] = false;
    }

    return results;
  }

  Future<Map<String, dynamic>> _testSyncFunctionality() async {
    final results = <String, dynamic>{};

    try {
      // Create a test profile
      final testProfile = UserProfile.create(
        organizationId: 'sync-test-org',
        name: 'Sync Test User',
        email: 'sync-test@example.com',
        createdBy: 'sync-test',
      );

      await _syncManager.create('user_profiles', testProfile.toJson());

      // Test sync
      final syncResult = await _syncManager.syncEntity('user_profiles');
      results['sync_success'] = syncResult.isSuccess;
      results['items_synced'] = syncResult.affectedItems;

      // Verify sync
      final verifyResult = await _syncManager.query(
        'user_profiles',
        SyncQuery(filters: {'id': testProfile.id}),
      );

      if (verifyResult.isSuccess && verifyResult.data!.isNotEmpty) {
        final syncedProfile = UserProfile.fromJson(verifyResult.data!.first);
        results['sync_verified'] = !syncedProfile.isDirty;
        results['sync_version'] = syncedProfile.syncVersion;
      }

    } catch (e) {
      print('Sync test failed: $e');
      results['sync_success'] = false;
      results['error'] = e.toString();
    }

    return results;
  }
}
```

### Performance Diagnostics

```dart
class PerformanceDiagnostics {
  final UniversalSyncManager _syncManager;

  Future<Map<String, dynamic>> runPerformanceCheck() async {
    final results = <String, dynamic>{};

    // Test query performance
    results['query_performance'] = await _testQueryPerformance();

    // Test sync performance
    results['sync_performance'] = await _testSyncPerformance();

    // Test memory usage
    results['memory_usage'] = await _testMemoryUsage();

    // Test network latency
    results['network_latency'] = await _testNetworkLatency();

    return results;
  }

  Future<Map<String, dynamic>> _testQueryPerformance() async {
    final results = <String, dynamic>{};

    // Test different query sizes
    for (final limit in [10, 100, 1000]) {
      final start = DateTime.now();
      final result = await _syncManager.query(
        'user_profiles',
        SyncQuery(limit: limit),
      );
      final duration = DateTime.now().difference(start);

      results['query_${limit}_items'] = {
        'duration_ms': duration.inMilliseconds,
        'success': result.isSuccess,
        'items_returned': result.data?.length ?? 0,
      };
    }

    return results;
  }

  Future<Map<String, dynamic>> _testSyncPerformance() async {
    final results = <String, dynamic>{};

    // Create test data
    final testProfiles = List.generate(50, (i) => UserProfile.create(
      organizationId: 'perf-test-org',
      name: 'Performance User $i',
      email: 'perf$i@example.com',
      createdBy: 'perf-test',
    ));

    // Time creation
    final createStart = DateTime.now();
    for (final profile in testProfiles) {
      await _syncManager.create('user_profiles', profile.toJson());
    }
    final createDuration = DateTime.now().difference(createStart);

    // Time sync
    final syncStart = DateTime.now();
    final syncResult = await _syncManager.syncEntity('user_profiles');
    final syncDuration = DateTime.now().difference(syncStart);

    results['create_performance'] = {
      'items_created': testProfiles.length,
      'duration_ms': createDuration.inMilliseconds,
      'items_per_second': testProfiles.length / (createDuration.inMilliseconds / 1000),
    };

    results['sync_performance'] = {
      'items_synced': syncResult.affectedItems,
      'duration_ms': syncDuration.inMilliseconds,
      'success': syncResult.isSuccess,
    };

    return results;
  }

  Future<Map<String, dynamic>> _testMemoryUsage() async {
    // This would require platform-specific implementation
    // For now, return placeholder
    return {
      'memory_test': 'Not implemented on this platform',
      'note': 'Memory diagnostics require platform-specific APIs',
    };
  }

  Future<Map<String, dynamic>> _testNetworkLatency() async {
    final latencies = <int>[];

    for (int i = 0; i < 5; i++) {
      final start = DateTime.now();
      await _syncManager.query('user_profiles', SyncQuery(limit: 1));
      final latency = DateTime.now().difference(start).inMilliseconds;
      latencies.add(latency);
    }

    final avgLatency = latencies.reduce((a, b) => a + b) ~/ latencies.length;
    final minLatency = latencies.reduce(min);
    final maxLatency = latencies.reduce(max);

    return {
      'average_latency_ms': avgLatency,
      'min_latency_ms': minLatency,
      'max_latency_ms': maxLatency,
      'samples': latencies.length,
    };
  }
}
```

## 🛠️ Common Fixes

### Database Issues

**RLS Policy Problems:**
```sql
-- Fix RLS policies
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
CREATE POLICY "Users can view own profile" ON user_profiles
  FOR SELECT USING (auth.uid()::text = id);

-- Enable RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
```

**Index Performance:**
```sql
-- Add performance indexes
CREATE INDEX IF NOT EXISTS idx_user_profiles_organization_id
  ON user_profiles (organization_id);

CREATE INDEX IF NOT EXISTS idx_user_profiles_is_dirty
  ON user_profiles (is_dirty);

CREATE INDEX IF NOT EXISTS idx_user_profiles_updated_at
  ON user_profiles (updated_at DESC);
```

### Flutter Issues

**State Management Problems:**
```dart
// Fix Riverpod provider setup
final syncManagerProvider = Provider<UniversalSyncManager>((ref) {
  return UniversalSyncManager(); // Don't create new instance each time
});

// Use proper state management
final userProfilesProvider = StateNotifierProvider<UserProfilesNotifier, AsyncValue<List<UserProfile>>>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  final repository = ref.watch(userProfileRepositoryProvider);
  return UserProfilesNotifier(repository, syncManager);
});
```

**Build Issues:**
```yaml
# Ensure proper dependencies
dependencies:
  universal_sync_manager: ^2.0.0
  supabase_flutter: ^1.10.0
  flutter_riverpod: ^2.0.0

# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Platform-Specific Issues

**iOS Issues:**
- Ensure proper ATS configuration
- Check Info.plist for required permissions
- Verify iOS deployment target

**Android Issues:**
- Check AndroidManifest.xml permissions
- Verify ProGuard rules if using code obfuscation
- Ensure proper network security config

**Web Issues:**
- Check CORS configuration in Supabase
- Verify web build configuration
- Ensure proper service worker setup

## 📞 Getting Help

### Debug Information

When reporting issues, please include:

1. **USM Version:** `flutter pub deps | grep universal_sync_manager`
2. **Flutter Version:** `flutter --version`
3. **Platform:** iOS/Android/Web
4. **Error Logs:** Full stack trace
5. **Reproduction Steps:** Detailed steps to reproduce
6. **Expected vs Actual:** What should happen vs what happens

### Diagnostic Script

```dart
Future<void> runFullDiagnostics() async {
  print('🔍 Running Full Diagnostics...');

  final connectionDiag = ConnectionDiagnostics(syncManager);
  final performanceDiag = PerformanceDiagnostics(syncManager);

  final connectionResults = await connectionDiag.runDiagnostics();
  final performanceResults = await performanceDiag.runPerformanceCheck();

  print('📊 Connection Diagnostics:');
  connectionResults.forEach((key, value) {
    print('  $key: $value');
  });

  print('⚡ Performance Diagnostics:');
  performanceResults.forEach((key, value) {
    print('  $key: $value');
  });

  // Save to file for sharing
  final diagnosticData = {
    'timestamp': DateTime.now().toIso8601String(),
    'connection': connectionResults,
    'performance': performanceResults,
  };

  // Write to file
  final file = File('usm_diagnostics.json');
  await file.writeAsString(jsonEncode(diagnosticData));

  print('💾 Diagnostics saved to usm_diagnostics.json');
}
```

## 🚀 Advanced Troubleshooting

### Network Debugging

```dart
class NetworkDebugger {
  void enableNetworkLogging() {
    // Enable detailed network logging
    Supabase.instance.client.httpClient.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => print('🌐 $object'),
      ),
    );
  }

  Future<void> testNetworkEndpoints() async {
    final endpoints = [
      '/rest/v1/user_profiles',
      '/rest/v1/app_settings',
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await Supabase.instance.client
            .from(endpoint.split('/').last)
            .select()
            .limit(1);

        print('✅ $endpoint: OK');
      } catch (e) {
        print('❌ $endpoint: Failed - $e');
      }
    }
  }
}
```

### Database Debugging

```dart
class DatabaseDebugger {
  Future<void> inspectDatabaseState() async {
    // Check table structure
    final tables = ['user_profiles', 'app_settings'];

    for (final table in tables) {
      try {
        final result = await Supabase.instance.client
            .from(table)
            .select()
            .limit(1);

        print('📋 $table structure: OK');
        print('   Sample data: ${result.data}');
      } catch (e) {
        print('❌ $table inspection failed: $e');
      }
    }
  }

  Future<void> checkRLSPolicies() async {
    // This would require direct SQL access
    // For now, test through API calls
    try {
      final result = await Supabase.instance.client
          .from('user_profiles')
          .select()
          .limit(1);

      print('✅ RLS policies: OK');
    } catch (e) {
      print('❌ RLS policies: Failed - $e');
      print('   This might indicate RLS policy issues');
    }
  }
}
```

## 📋 Prevention Tips

1. **Regular Testing:** Run your test suite regularly
2. **Monitor Performance:** Keep an eye on sync performance
3. **Update Dependencies:** Keep USM and Supabase up to date
4. **Backup Data:** Regular backups of your Supabase data
5. **Monitor Logs:** Set up logging and monitoring
6. **User Feedback:** Listen to user reports about sync issues

## 🎯 Next Steps

1. **[Setup Guide](../setup.md)** - Initial configuration
2. **[Authentication Guide](../authentication.md)** - Auth setup
3. **[CRUD Operations](../crud_operations.md)** - Basic operations
4. **[Sync Features](../sync_features.md)** - Sync functionality
5. **[Advanced Features](../advanced_features.md)** - Performance optimization
6. **[Testing Guide](../testing.md)** - Comprehensive testing
7. **[Code Examples](../examples/)** - Copy-paste code