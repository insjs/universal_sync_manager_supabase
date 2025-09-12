# Quick Migration Guide - Phase 3

## 🚀 2-Minute Migration for Simple Projects with MyAppSyncManager

### From PocketBase Direct Usage to Phase 3

#### Before (PocketBase Direct)
```dart
// Old way - Direct PocketBase usage
final pb = PocketBase('https://your-pb-instance.com');

// Create record
await pb.collection('users').create(body: {
  'name': 'John Doe',
  'email': 'john@example.com',
});

// Get record
final record = await pb.collection('users').getOne('record-id');
```

#### After (Phase 3 with MyAppSyncManager)
```dart
// New way - Phase 3 MyAppSyncManager
// One-time setup in main()
await MyAppSyncManager.initialize(
  backendAdapter: PocketBaseSyncAdapter(
    baseUrl: 'https://your-pocketbase.com',
    connectionTimeout: Duration(seconds: 30),
    requestTimeout: Duration(seconds: 15),
  ),
  publicCollections: ['announcements', 'public_data'],
  autoSync: true,
  syncInterval: Duration(seconds: 30),
);

// Authentication
await MyAppSyncManager.instance.login(
  token: 'pocketbase-auth-token',
  userId: 'user-id',
  organizationId: 'org-id',
);

// Local operations - automatically synced by MyAppSyncManager
final userRepo = UserRepository(); // Your local repo
await userRepo.create(user); // Automatically synced to PocketBase
```

### From Firebase Direct Usage to Phase 3

#### Before (Firebase Direct)
```dart
// Old way - Direct Firebase usage
final firestore = FirebaseFirestore.instance;

// Create document
await firestore.collection('users').add({
  'name': 'John Doe',
  'email': 'john@example.com',
});

// Get document
final doc = await firestore.collection('users').doc('user-id').get();
```

#### After (Phase 3 with Firebase Auth Integration)
```dart
// New way - Phase 3 with Firebase Auth integration
await MyAppSyncManager.initialize(
  backendAdapter: FirebaseSyncAdapter(
    configuration: SyncBackendConfiguration(
      configId: 'firebase-main',
      backendType: 'firebase',
      projectId: 'your-firebase-project-id',
      environment: 'production',
    ),
  ),
  publicCollections: ['public_posts'],
  autoSync: true,
);

// Automatic Firebase Auth integration
FirebaseAuth.instance.authStateChanges().listen((user) {
  if (user != null) {
    FirebaseAuthIntegration.syncWithUSM(user); // Automatic sync integration
  } else {
    MyAppSyncManager.instance.logout();
  }
});

// Local operations - automatically synced to Firebase
final userRepo = UserRepository();
await userRepo.create(user); // Synced to Firebase automatically
```

## 🔄 Model Migration Templates - Phase 3

### Simplified Model Migration

```dart
// ❌ Before - Basic model
class User {
  final String id;
  final String name;
  final String email;
  
  User({required this.id, required this.name, required this.email});
}

// ✅ After - Phase 3 Simplified Model (no manual audit fields!)
class User implements SyncableModel {
  @override
  final String id;
  @override  
  final String organizationId;
  
  final String name;
  final String email;
  
  // Optional: Add business-specific fields
  final String? profileImageUrl;
  final bool isActive;
  final DateTime? lastLoginAt;

  User({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.email,
    this.profileImageUrl,
    this.isActive = true,
    this.lastLoginAt,
  });

  // Required: JSON serialization
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'organizationId': organizationId,
    'name': name,
    'email': email,
    'profileImageUrl': profileImageUrl,
    'isActive': isActive,
    'lastLoginAt': lastLoginAt?.toIso8601String(),
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    organizationId: json['organizationId'],
    name: json['name'],
    email: json['email'],
    profileImageUrl: json['profileImageUrl'],
    isActive: json['isActive'] ?? true,
    lastLoginAt: json['lastLoginAt'] != null 
        ? DateTime.parse(json['lastLoginAt']) 
        : null,
  );

  // Optional: Convenience copyWith method
  User copyWith({
    String? name,
    String? email,
    String? profileImageUrl,
    bool? isActive,
    DateTime? lastLoginAt,
  }) => User(
    id: id,
    organizationId: organizationId,
    name: name ?? this.name,
    email: email ?? this.email,
    profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    isActive: isActive ?? this.isActive,
    lastLoginAt: lastLoginAt ?? this.lastLoginAt,
  );
}

// Note: MyAppSyncManager handles all audit fields automatically:
// - createdBy, updatedBy, createdAt, updatedAt, deletedAt
// - isDirty, lastSyncedAt, syncVersion, isDeleted
// You don't need to manage these manually!
## 📱 Repository Migration Templates - Phase 3

### From Direct Backend to Local-First (Simplified)

```dart
// ❌ Before - Direct backend repository
class UserRepository {
  final PocketBase pb;
  
  UserRepository(this.pb);
  
  Future<void> create(User user) async {
    await pb.collection('users').create(body: user.toJson());
  }
  
  Future<User?> getById(String id) async {
    final record = await pb.collection('users').getOne(id);
    return User.fromJson(record.toJson());
  }
  
  Future<List<User>> getAll() async {
    final records = await pb.collection('users').getFullList();
    return records.map((r) => User.fromJson(r.toJson())).toList();
  }
}

// ✅ After - Phase 3 Local-first (MyAppSyncManager handles sync automatically)
class UserRepository {
  static const String tableName = 'users';
  
  // Local operations only - MyAppSyncManager handles sync automatically
  
  Future<void> create(User user) async {
    final db = await DatabaseHelper.database;
    await db.insert(tableName, user.toJson());
    // MyAppSyncManager detects new data and syncs automatically
  }
  
  Future<User?> getById(String id) async {
    final db = await DatabaseHelper.database;
    final result = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (result.isEmpty) return null;
    return User.fromJson(result.first);
  }
  
  Future<List<User>> getAll() async {
    final db = await DatabaseHelper.database;
    final result = await db.query(
      tableName,
      orderBy: 'name ASC',
    );
    
    return result.map((json) => User.fromJson(json)).toList();
  }
  
  Future<void> update(User user) async {
    final db = await DatabaseHelper.database;
    await db.update(
      tableName,
      user.toJson(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
    // MyAppSyncManager detects changes and syncs automatically
  }
  
  Future<void> delete(String id) async {
    final db = await DatabaseHelper.database;
    await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    // MyAppSyncManager detects deletion and syncs automatically
  }
  
  // Phase 3 bonus: Easy filtering
  Future<List<User>> getByOrganization(String organizationId) async {
    final db = await DatabaseHelper.database;
    final result = await db.query(
      tableName,
      where: 'organizationId = ?',
      whereArgs: [organizationId],
      orderBy: 'name ASC',
    );
    
    return result.map((json) => User.fromJson(json)).toList();
  }
}
```
```

## 🗄️ Database Migration Scripts

### SQLite Schema Migration

```sql
-- Quick migration script for existing SQLite database

-- 1. Add USM required columns to existing table
ALTER TABLE users ADD COLUMN createdBy TEXT DEFAULT 'migration';
ALTER TABLE users ADD COLUMN updatedBy TEXT DEFAULT 'migration';
ALTER TABLE users ADD COLUMN createdAt TEXT;
ALTER TABLE users ADD COLUMN updatedAt TEXT;
ALTER TABLE users ADD COLUMN deletedAt TEXT;
ALTER TABLE users ADD COLUMN isDirty INTEGER NOT NULL DEFAULT 1;
ALTER TABLE users ADD COLUMN lastSyncedAt TEXT;
ALTER TABLE users ADD COLUMN syncVersion INTEGER NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN isDeleted INTEGER NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN organizationId TEXT DEFAULT 'default-org';

-- 2. Update existing records with timestamps
UPDATE users 
SET 
  createdAt = datetime('now'),
  updatedAt = datetime('now')
WHERE createdAt IS NULL;

-- 3. Create performance indexes
CREATE INDEX IF NOT EXISTS idx_users_organization_id ON users (organizationId);
CREATE INDEX IF NOT EXISTS idx_users_is_dirty ON users (isDirty);
CREATE INDEX IF NOT EXISTS idx_users_is_deleted ON users (isDeleted);
CREATE INDEX IF NOT EXISTS idx_users_sync_version ON users (syncVersion);
```

## ⚡ Quick Setup Scripts - Phase 3

### Complete Setup Script

```dart
// setup_sync.dart - Quick setup script for Phase 3
import 'package:universal_sync_manager/universal_sync_manager.dart';

class MyAppQuickSetup {
  static Future<void> setupPocketBase({
    required String baseUrl,
    required String projectId,
  }) async {
    // Phase 3: Simple one-call setup
    await MyAppSyncManager.initialize(
      backend: SyncBackend.pocketbase(
        url: baseUrl,
        projectId: projectId,
      ),
      authProvider: AuthProvider.firebase(), // Choose your auth
      options: SyncOptions(
        enableOfflineMode: true,
        syncInterval: Duration(seconds: 30),
        enableAnalytics: true,
        autoRegisterModels: true, // Automatically detect models
      ),
    );
    
    print('MyAppSyncManager setup complete for PocketBase!');
  }
  
  static Future<void> setupFirebase({
    required String projectId,
  }) async {
    await MyAppSyncManager.initialize(
      backend: SyncBackend.firebase(
        projectId: projectId,
      ),
      authProvider: AuthProvider.firebase(),
      options: SyncOptions(
        enableOfflineMode: true,
        syncInterval: Duration(minutes: 2),
        enableAnalytics: true,
      ),
    );
    
    print('MyAppSyncManager setup complete for Firebase!');
  }
  
  static Future<void> setupSupabase({
    required String url,
    required String anonKey,
  }) async {
    await MyAppSyncManager.initialize(
      backend: SyncBackend.supabase(
        url: url,
        anonKey: anonKey,
      ),
      authProvider: AuthProvider.supabase(),
      options: SyncOptions(
        enableOfflineMode: true,
        syncInterval: Duration(minutes: 1),
      ),
    );
    
    print('MyAppSyncManager setup complete for Supabase!');
  }
}

// Usage in your app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Phase 3: Quick setup for PocketBase
  await MyAppQuickSetup.setupPocketBase(
    baseUrl: 'https://your-pb-instance.com',
    projectId: 'your-project',
  );
  
  // Your app is now sync-enabled with authentication!
  runApp(MyApp());
}

// Alternative: Direct setup
Future<void> directSetup() async {
  await MyAppSyncManager.initialize(
    backend: SyncBackend.pocketbase(url: 'https://api.example.com'),
    authProvider: AuthProvider.firebase(),
  );
  
  // That's it! Models are auto-registered, sync is automatic
}
```
```

## 🔥 Common Migration Patterns - Phase 3

### Pattern 1: Real-time Updates (Simplified)

```dart
// ❌ Before - Manual real-time subscription
StreamSubscription? realtimeSubscription;

void subscribeToUpdates() {
  realtimeSubscription = pb.collection('users').subscribe('*', (e) {
    // Handle update manually
    handleRealtimeUpdate(e);
  });
}

// ✅ After - Phase 3 automatic real-time (Built-in State Management)
class UserListProvider extends ChangeNotifier {
  List<User> users = [];
  
  UserListProvider() {
    // Phase 3: Subscribe to real-time updates automatically
    MyAppSyncManager.watchCollection<User>('users').listen((userList) {
      users = userList;
      notifyListeners(); // Automatic UI updates
    });
  }
}

// Alternative: Direct stream usage
StreamBuilder<List<User>>(
  stream: MyAppSyncManager.watchCollection<User>('users'),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return ListView(
        children: snapshot.data!.map((user) => 
          UserTile(user: user)
        ).toList(),
      );
    }
    return CircularProgressIndicator();
  },
)
```

### Pattern 2: Conflict Resolution (Automatic)

```dart
// ❌ Before - Manual conflict handling
Future<void> handleConflict(ConflictData conflict) async {
  // Manual comparison and resolution
  if (conflict.clientData['updatedAt'].compareTo(
      conflict.serverData['updatedAt']) > 0) {
    // Use client data
    await saveClientData(conflict.clientData);
  } else {
    // Use server data
    await saveServerData(conflict.serverData);
  }
}

// ✅ After - Phase 3 automatic conflict resolution
void setupConflictResolution() {
  // MyAppSyncManager handles conflicts automatically with smart strategies
  
  // Optional: Custom conflict strategy for specific models
  MyAppSyncManager.setConflictStrategy(
    'users',
    ConflictStrategy.timestampWins, // Built-in intelligent resolution
  );
  
  // Optional: Listen to conflict events for logging/notification
  MyAppSyncManager.conflictStream.listen((conflict) {
    // Log or show user notification about resolved conflict
    print('Conflict resolved: ${conflict.modelType} - ${conflict.resolution}');
    showConflictResolvedNotification(conflict);
  });
}
```

### Pattern 3: Offline Support (Built-in)

```dart
// ❌ Before - Manual offline handling
bool isOnline = true;
List<PendingOperation> pendingOperations = [];

Future<void> createUser(User user) async {
  if (isOnline) {
    await pb.collection('users').create(body: user.toJson());
  } else {
    // Queue for later
    pendingOperations.add(PendingOperation('create', user));
  }
}

Future<void> syncPendingOperations() async {
  for (final op in pendingOperations) {
    await executeOperation(op);
  }
  pendingOperations.clear();
}

// ✅ After - Phase 3 automatic offline support
Future<void> createUser(User user) async {
  final db = await DatabaseHelper.database;
  await db.insert('users', user.toJson());
  
  // MyAppSyncManager automatically:
  // - Saves locally (works offline)
  // - Syncs when back online
  // - Handles conflicts intelligently
  // - Maintains data consistency
  // - Provides connection status updates
  
  // Optional: Listen to sync status
  MyAppSyncManager.syncStatusStream.listen((status) {
    print('Sync status: ${status.isOnline ? "Online" : "Offline"}');
    print('Pending changes: ${status.pendingChanges}');
  });
}
```

## 🎯 Migration Checklist - Phase 3

### Quick Checklist for Small Projects (< 5 entities)

- [ ] Add Universal Sync Manager dependency to pubspec.yaml
- [ ] Update imports to use MyAppSyncManager
- [ ] Add SyncableModel interface to data models (simplified - no manual audit fields)
- [ ] Update database schema (MyAppSyncManager handles audit fields automatically)
- [ ] Convert repositories to local-first pattern
- [ ] Initialize MyAppSyncManager with backend and auth provider
- [ ] Test sync functionality with automatic model detection
- [ ] Update UI to use MyAppSyncManager.watchCollection() streams
- [ ] Verify offline-first functionality

**Estimated Time**: 1-2 hours (Phase 3 is much simpler!)

### Standard Checklist for Medium Projects (5-20 entities)

- [ ] All items from quick checklist
- [ ] Create migration scripts for existing data
- [ ] Configure custom conflict resolution strategies (if needed)
- [ ] Set up monitoring and analytics (built-in with MyAppSyncManager)
- [ ] Test state management integrations (Bloc/Riverpod/GetX/Provider)
- [ ] Verify authentication flow with chosen auth provider
- [ ] Create rollback plan
- [ ] Performance testing with larger datasets

**Estimated Time**: 2-4 hours (Phase 3 streamlines most complexity)
- [ ] Update documentation

**Estimated Time**: 1-2 days

### Complete Checklist for Large Projects (20+ entities)

- [ ] All items from standard checklist
- [ ] Performance analysis and optimization
- [ ] Batch migration for large datasets
- [ ] Custom adapter implementation if needed
- [ ] Advanced sync strategies (delta sync, etc.)
- [ ] Comprehensive testing suite
- [ ] Team training on new patterns
- [ ] Gradual rollout plan

**Estimated Time**: 3-5 days

---

## 🆘 Need Help?

- **Quick Questions**: Check `/doc/guides/FAQ.md`
- **Complex Issues**: Open an issue on GitHub
- **Migration Support**: See `/doc/migration/USM_MIGRATION_GUIDE.md` for detailed guide
