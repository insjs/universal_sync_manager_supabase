# Migration Guide

This guide helps you migrate to Universal Sync Manager from other sync solutions or upgrade between versions, including the new Phase 3: App Integration Framework.

## Phase 3: App Integration Framework Migration

### Upgrading to MyAppSyncManager (Recommended)

If you were using the low-level UniversalSyncManager API, consider migrating to the new high-level MyAppSyncManager for simplified integration.

**Before (Low-level API):**
```dart
final syncManager = UniversalSyncManager();
await syncManager.initialize(config);
await syncManager.setBackend(adapter);
syncManager.registerEntity('users', config);
// Manual auth handling...
```

**After (High-level API):**
```dart
await MyAppSyncManager.initialize(
  backendAdapter: PocketBaseSyncAdapter(baseUrl: 'https://your-backend.com'),
  publicCollections: ['public_data'],
);

// Simple auth integration
await MyAppSyncManager.instance.login(
  token: 'user-token',
  userId: 'user-id',
);
```

### Auth Provider Integration Migration

#### Firebase Auth Integration

**Before (Manual):**
```dart
FirebaseAuth.instance.authStateChanges().listen((user) {
  if (user != null) {
    // Manual token extraction and USM login
    user.getIdToken().then((token) {
      syncManager.authenticate(token, user.uid);
    });
  }
});
```

**After (Automatic):**
```dart
FirebaseAuth.instance.authStateChanges().listen((user) {
  if (user != null) {
    FirebaseAuthIntegration.syncWithUSM(user);
  } else {
    MyAppSyncManager.instance.logout();
  }
});
```

#### Supabase Auth Integration

**Before (Manual):**
```dart
supabase.auth.onAuthStateChange.listen((data) {
  final user = data.user;
  if (user != null) {
    // Manual token handling
    syncManager.authenticate(data.session?.accessToken, user.id);
  }
});
```

**After (Automatic):**
```dart
supabase.auth.onAuthStateChange.listen((data) {
  final user = data.user;
  if (user != null) {
    SupabaseAuthIntegration.syncWithUSM(user);
  }
});
```

### State Management Integration Migration

#### Migrating to Riverpod Integration

**Before (Manual State Management):**
```dart
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.initial());
  
  void login() async {
    state = state.copyWith(isLoading: true);
    // Manual USM integration
    await syncManager.authenticate(token, userId);
    state = state.copyWith(isAuthenticated: true, isLoading: false);
  }
}
```

**After (Built-in Integration):**
```dart
final authProvider = StateNotifierProvider<AuthSyncNotifier, RiverpodAuthSyncState>((ref) {
  final notifier = AuthSyncNotifier();
  notifier.initialize(); // Automatic USM integration
  return notifier;
});

// Usage in widget
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    // State automatically synced with USM
  }
}
```

#### Migrating to Bloc Integration

**Before (Manual Bloc Setup):**
```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    // Manual USM integration in each event handler
  }
}
```

**After (Mixin Integration):**
```dart
class MyAppBloc extends Bloc<AppEvent, AppState> with AuthSyncBlocMixin {
  MyAppBloc() : super(AppInitial()) {
    initializeAuthSync(); // Automatic USM integration
  }
  
  @override
  Future<void> close() {
    disposeAuthSync();
    return super.close();
  }
}
```

### Auth Lifecycle Management Migration

**Before (Manual Session Management):**
```dart
// Manual token refresh
Timer.periodic(Duration(minutes: 30), (timer) {
  if (needsRefresh()) {
    refreshToken();
  }
});

// Manual session timeout
Timer(Duration(hours: 8), () {
  logout();
});
```

**After (Automatic Lifecycle Management):**
```dart
final lifecycleManager = AuthLifecycleManager();
await lifecycleManager.initialize(
  sessionTimeoutDuration: Duration(hours: 8),
  refreshThreshold: Duration(minutes: 5),
);

// Automatic coordination
lifecycleManager.startTokenRefreshCoordination();
```

### Breaking Changes in Phase 3

1. **State Class Names**: To avoid conflicts, state management integrations use framework-specific names:
   - `BlocAuthSyncState` for Bloc/Provider
   - `RiverpodAuthSyncState` for Riverpod
   - `GetXAuthSyncState` for GetX

2. **MyAppSyncManager API**: The `login()` method now requires named parameters:
   ```dart
   // Old
   await MyAppSyncManager.login(token, userId);
   
   // New
   await MyAppSyncManager.instance.login(
     token: token,
     userId: userId,
   );
   ```

3. **Auth State Enum**: Simplified to binary state:
   ```dart
   // Old: Multiple states
   enum AuthState { initial, loading, authenticated, error }
   
   // New: Binary state
   enum AuthState { public, authenticated }
   ```


## Migrating from Custom Solutions

### 1. Replace Direct Backend Calls

**Before:**
```dart
// Direct PocketBase usage
final pb = PocketBase('https://your-pocketbase.com');
final records = await pb.collection('users').getFullList();
```

**After:**
```dart
// Universal Sync Manager
final syncManager = UniversalSyncManager();
await syncManager.initialize(config);
await syncManager.setBackend(PocketBaseSyncAdapter(baseUrl: 'https://your-pocketbase.com'));

// Automatic sync handling
syncManager.registerEntity('users', SyncEntityConfig(tableName: 'users'));
final result = await syncManager.syncEntity('users');
```

### 2. Replace Manual Conflict Resolution

**Before:**
```dart
// Manual conflict handling
if (localData.updatedAt.isAfter(remoteData.updatedAt)) {
  await updateRemote(localData);
} else {
  await updateLocal(remoteData);
}
```

**After:**
```dart
// Automatic conflict resolution
syncManager.setConflictResolver('users', ConflictResolver.timestampWins());
```

## Migrating Between Backends

### From Firebase to PocketBase

1. **Export your Firebase data**
2. **Set up PocketBase schema to match your Firebase structure**
3. **Initialize Universal Sync Manager with PocketBase adapter**
4. **Import your data using the migration tools**

```dart
// Migration helper
final migrationTool = SyncMigrationTool(syncManager);
await migrationTool.migrateFromFirebase(
  firebaseConfig: oldFirebaseConfig,
  pocketBaseConfig: newPocketBaseConfig,
  preserveTimestamps: true,
);
```

### From PocketBase to Supabase

```dart
await syncManager.switchBackend(
  SupabaseSyncAdapter(url: 'https://new-project.supabase.co', anonKey: 'key'),
  migrateData: true,
  syncBeforeSwitch: true,
);
```

## Version Upgrade Guide

### v1.0 to v2.0

**Breaking Changes:**
- `SyncConfig` renamed to `UniversalSyncConfig`
- `BackendAdapter` interface updated with new methods
- Conflict resolution strategies restructured

**Migration Steps:**

1. Update configuration:
```dart
// Old
final config = SyncConfig(projectId: 'test');

// New  
final config = UniversalSyncConfig(projectId: 'test');
```

2. Update adapter initialization:
```dart
// Old
final adapter = PocketBaseAdapter('https://url.com');

// New
final adapter = PocketBaseSyncAdapter(baseUrl: 'https://url.com');
```

3. Update conflict resolution:
```dart
// Old
syncManager.setConflictStrategy('users', ConflictStrategy.clientWins);

// New
syncManager.setConflictResolver('users', ConflictResolver.clientWins());
```

## Data Model Migration

### Adding Sync Fields to Existing Models

If you have existing data models, you'll need to add sync-related fields:

```dart
// Add these fields to your existing models
class UserProfile with SyncableModel {
  // Existing fields
  String id;
  String name;
  String email;
  
  // Required sync fields (add these)
  @override
  String get organizationId => 'default';
  
  @override
  bool isDirty = false;
  
  @override
  DateTime? lastSyncedAt;
  
  @override
  int syncVersion = 0;
  
  @override
  DateTime? updatedAt;
  
  @override
  bool isDeleted = false;
  
  // Required audit fields
  String createdBy = '';
  String updatedBy = '';
  DateTime? createdAt;
  DateTime? deletedAt;
}
```

### Database Schema Migration

For existing databases, run these SQL commands to add sync fields:

```sql
-- Add sync fields to existing tables
ALTER TABLE user_profiles ADD COLUMN isDirty INTEGER DEFAULT 1;
ALTER TABLE user_profiles ADD COLUMN lastSyncedAt TEXT;
ALTER TABLE user_profiles ADD COLUMN syncVersion INTEGER DEFAULT 0;
ALTER TABLE user_profiles ADD COLUMN isDeleted INTEGER DEFAULT 0;

-- Add audit fields
ALTER TABLE user_profiles ADD COLUMN createdBy TEXT;
ALTER TABLE user_profiles ADD COLUMN updatedBy TEXT;
ALTER TABLE user_profiles ADD COLUMN createdAt TEXT;
ALTER TABLE user_profiles ADD COLUMN updatedAt TEXT;
ALTER TABLE user_profiles ADD COLUMN deletedAt TEXT;

-- Add performance indexes
CREATE INDEX idx_user_profiles_is_dirty ON user_profiles (isDirty);
CREATE INDEX idx_user_profiles_is_deleted ON user_profiles (isDeleted);
```

## Testing Your Migration

After migration, use the testing tools to verify everything works:

```dart
import 'package:universal_sync_manager/testing.dart';

void main() async {
  final testSuite = UniversalSyncManagerTestSuite();
  await testSuite.initialize();
  
  // Run migration validation tests
  await testSuite.runTestCategory(TestCategory.integration);
  
  // Verify data integrity
  final results = await testSuite.runTestsWithTags(['migration', 'data-integrity']);
  
  print('Migration validation: ${results.every((r) => r.passed) ? "✅ Passed" : "❌ Failed"}');
}
```

## Troubleshooting Migration Issues

### Common Issues and Solutions

1. **Sync Fields Missing**
   - Ensure all models implement `SyncableModel`
   - Add required audit fields to database schema

2. **Authentication Errors**
   - Verify backend credentials are correct
   - Check authentication token expiration

3. **Performance Issues**
   - Enable sync optimization
   - Adjust batch sizes
   - Add database indexes

4. **Data Conflicts**
   - Review conflict resolution strategies
   - Check timestamp accuracy
   - Implement custom conflict resolvers

### Getting Help

If you encounter issues during migration:
1. Check the troubleshooting section in the main documentation
2. Review the test suite results for specific error details
3. Use the diagnostic tools to identify sync issues
4. Consult the API reference for detailed method documentation

Remember to backup your data before starting any migration!
