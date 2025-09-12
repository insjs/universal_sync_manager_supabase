import 'package:universal_sync_manager/universal_sync_manager.dart';
// import 'package:pocketbase/pocketbase.dart';  // Old direct usage

/// PocketBase Migration Example
///
/// Problem: Migrating from direct PocketBase usage to Universal Sync Manager
///
/// This example shows:
/// 1. How to migrate from direct PocketBase SDK usage
/// 2. Converting PocketBase-specific code to USM patterns
/// 3. Maintaining data consistency during migration
/// 4. Leveraging USM benefits (offline-first, conflict resolution, etc.)

class PocketBaseMigrationExample {
  /// BEFORE: Direct PocketBase Usage
  /// This is how you might have been using PocketBase directly
  static void showOldPattern() {
    print('❌ OLD PATTERN - Direct PocketBase Usage:');
    print('');

    print('''
// Old way - Direct PocketBase usage
class UserService {
  final PocketBase pb = PocketBase('https://your-pb-instance.com');
  
  Future<void> createUser(Map<String, dynamic> userData) async {
    try {
      await pb.collection('users').create(body: userData);
      print('User created successfully');
    } catch (e) {
      print('Failed to create user: \$e');
      // Manual retry logic needed
      // No offline support
      // Manual conflict handling
    }
  }
  
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final records = await pb.collection('users').getFullList();
      return records.map((r) => r.toJson()).toList();
    } catch (e) {
      print('Failed to fetch users: \$e');
      // Returns empty list if offline
      return [];
    }
  }
  
  Future<void> updateUser(String id, Map<String, dynamic> updates) async {
    try {
      await pb.collection('users').update(id, body: updates);
    } catch (e) {
      // Lost changes if offline
      // No conflict detection
    }
  }
  
  void subscribeToUsers() {
    pb.collection('users').subscribe('*', (e) {
      // Manual handling of real-time updates
      switch (e.action) {
        case 'create':
          handleUserCreated(e.record!);
          break;
        case 'update':
          handleUserUpdated(e.record!);
          break;
        case 'delete':
          handleUserDeleted(e.record!);
          break;
      }
    });
  }
}

PROBLEMS WITH THIS APPROACH:
❌ No offline support - app breaks when no internet
❌ Manual error handling and retry logic
❌ No conflict resolution when multiple users edit same data
❌ Real-time updates require manual state management
❌ No data consistency guarantees
❌ Tightly coupled to PocketBase - hard to switch backends
❌ Manual cache invalidation and UI updates
❌ No automatic sync optimization
    ''');

    print('');
  }

  /// AFTER: USM Pattern
  /// This is how you'll use USM with PocketBase adapter
  static void showNewPattern() {
    print('✅ NEW PATTERN - USM with PocketBase Adapter:');
    print('');

    print('''
// New way - USM with PocketBase adapter
class UserService {
  // USM handles all backend complexity
  static late UniversalSyncManager _syncManager;
  
  // One-time setup
  static Future<void> initialize() async {
    _syncManager = UniversalSyncManager();
    
    await _syncManager.initialize(UniversalSyncConfig(
      projectId: 'my-app',
      syncMode: SyncMode.automatic,  // Auto-sync in background
      conflictResolutionStrategy: ConflictResolutionStrategy.timestampWins,
    ));
    
    // Configure PocketBase adapter
    final adapter = PocketBaseSyncAdapter(
      baseUrl: 'https://your-pb-instance.com',
    );
    await _syncManager.setBackend(adapter);
    
    // Register entities
    _syncManager.registerEntity('users', SyncEntityConfig(
      tableName: 'users',
      requiresAuthentication: true,
      priority: SyncPriority.high,
      enableRealTime: true,
    ));
    
    // Listen to sync events (optional)
    _syncManager.syncEventStream.listen((event) {
      if (event.type == SyncEventType.update && event.collection == 'users') {
        // UI automatically updates because repository returns fresh data
        notifyUI('Users updated');
      }
    });
  }
  
  // Now your service only deals with local data
  // USM handles all sync complexity automatically
  
  Future<void> createUser(User user) async {
    final userRepo = UserRepository();
    await userRepo.create(user);
    
    // That's it! USM automatically:
    // ✅ Saves locally immediately (offline support)
    // ✅ Queues for sync when online
    // ✅ Handles network failures with automatic retry
    // ✅ Syncs to PocketBase in background
    // ✅ Handles conflicts if data changed on server
    // ✅ Updates all connected clients via real-time
  }
  
  Future<List<User>> getUsers() async {
    final userRepo = UserRepository();
    final users = await userRepo.getAll();
    
    // Always returns data (from local SQLite)
    // USM keeps it synced with PocketBase automatically
    // Works perfectly offline
    return users;
  }
  
  Future<void> updateUser(User user) async {
    final userRepo = UserRepository();
    final updatedUser = user.copyWith(
      updatedAt: DateTime.now(),
      isDirty: true,  // Marks for sync
    );
    await userRepo.update(updatedUser);
    
    // USM detects the dirty record and syncs automatically
    // Handles conflicts using configured strategy
    // Updates all clients via real-time subscriptions
  }
  
  // Real-time updates are automatic!
  // No manual subscription needed - USM handles it
  // UI gets notified through repository/state management
}

BENEFITS OF USM APPROACH:
✅ Full offline support - app works without internet
✅ Automatic sync with intelligent retry and error handling
✅ Built-in conflict resolution with multiple strategies
✅ Real-time updates handled automatically
✅ Data consistency guarantees (ACID properties)
✅ Backend-agnostic - easy to switch from PocketBase to Firebase/Supabase
✅ Automatic cache management and UI updates
✅ Optimized sync (delta updates, batching, compression)
✅ Analytics and monitoring built-in
✅ Simple, predictable API
    ''');

    print('');
  }

  /// Step-by-step migration process
  static Future<void> showMigrationSteps() async {
    print('🔄 STEP-BY-STEP MIGRATION PROCESS:');
    print('');

    print('''
STEP 1: Update Dependencies
--------
pubspec.yaml:
  dependencies:
    # Remove or keep for gradual migration
    # pocketbase: ^0.18.0
    
    # Add USM
    universal_sync_manager:
      path: ../universal_sync_manager
      
STEP 2: Create USM-Compatible Models
--------
// Before: Basic model
class User {
  final String id;
  final String name;
  final String email;
}

// After: USM SyncableModel
class User with SyncableModel {
  final String id;
  final String name;
  final String email;
  final String organizationId;
  
  // Required USM audit fields
  final String createdBy;
  final String updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final bool isDirty;
  final DateTime? lastSyncedAt;
  final int syncVersion;
  final bool isDeleted;
  
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.organizationId,
    required this.createdBy,
    required this.updatedBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.isDirty = true,
    this.lastSyncedAt,
    this.syncVersion = 0,
    this.isDeleted = false,
  });
  
  @override
  User copyWith({...}) {
    // Implementation
  }
  
  Map<String, dynamic> toJson() => {...};
  factory User.fromJson(Map<String, dynamic> json) => User(...);
}

STEP 3: Update Database Schema
--------
-- Add USM required fields to existing SQLite tables
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

-- Update existing records
UPDATE users SET 
  createdAt = datetime('now'),
  updatedAt = datetime('now'),
  isDirty = 1
WHERE createdAt IS NULL;

-- Create performance indexes
CREATE INDEX idx_users_is_dirty ON users (isDirty);
CREATE INDEX idx_users_is_deleted ON users (isDeleted);
CREATE INDEX idx_users_organization_id ON users (organizationId);

STEP 4: Convert Repositories to Local-First
--------
// Before: Direct PocketBase repository
class UserRepository {
  final PocketBase pb;
  
  Future<void> create(User user) async {
    await pb.collection('users').create(body: user.toJson());
  }
}

// After: Local-first repository (USM handles sync)
class UserRepository {
  static const String tableName = 'users';
  
  Future<void> create(User user) async {
    final db = await DatabaseHelper.database;
    await db.insert(tableName, user.toJson());
    // USM automatically detects dirty record and syncs it
  }
  
  Future<List<User>> getAll() async {
    final db = await DatabaseHelper.database;
    final result = await db.query(
      tableName,
      where: 'isDeleted = 0',
      orderBy: 'updatedAt DESC',
    );
    return result.map((json) => User.fromJson(json)).toList();
  }
}

STEP 5: Initialize USM
--------
// Add to your app initialization
Future<void> initializeApp() async {
  await initializeUSM();
  // ... rest of app initialization
}

Future<void> initializeUSM() async {
  final syncManager = UniversalSyncManager();
  
  await syncManager.initialize(UniversalSyncConfig(
    projectId: 'your-app-id',
    syncMode: SyncMode.automatic,
  ));
  
  final adapter = PocketBaseSyncAdapter(
    baseUrl: 'https://your-pb-instance.com',
  );
  await syncManager.setBackend(adapter);
  
  // Register all your entities
  syncManager.registerEntity('users', SyncEntityConfig(
    tableName: 'users',
    requiresAuthentication: true,
  ));
  
  // Add more entities as needed
  syncManager.registerEntity('posts', SyncEntityConfig(
    tableName: 'posts',
    requiresAuthentication: true,
  ));
}

STEP 6: Update UI Layer
--------
// Before: Manual loading states and error handling
class UsersScreen extends StatefulWidget {
  @override
  _UsersScreenState createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<User> users = [];
  bool isLoading = true;
  String? error;
  
  @override
  void initState() {
    super.initState();
    loadUsers();
  }
  
  Future<void> loadUsers() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    
    try {
      final userService = UserService();
      final loadedUsers = await userService.getUsers();
      setState(() {
        users = loadedUsers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }
}

// After: Simplified with automatic sync
class UsersScreen extends StatefulWidget {
  @override
  _UsersScreenState createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<User> users = [];
  
  @override
  void initState() {
    super.initState();
    loadUsers();
    
    // Optional: Listen to sync events for UI feedback
    syncManager.syncEventStream.listen((event) {
      if (event.collection == 'users') {
        loadUsers(); // Refresh data when synced
      }
    });
  }
  
  Future<void> loadUsers() async {
    final userRepo = UserRepository();
    final loadedUsers = await userRepo.getAll();
    setState(() {
      users = loadedUsers;
    });
    
    // No loading states needed - data always available
    // No error handling needed - USM handles all errors
    // Sync happens automatically in background
  }
}

STEP 7: Remove Old PocketBase Code
--------
1. Remove direct PocketBase service classes
2. Remove manual error handling and retry logic
3. Remove manual real-time subscription code
4. Remove manual cache management
5. Update imports to use USM patterns

STEP 8: Test Migration
--------
1. Verify all existing data is preserved
2. Test offline functionality
3. Test conflict resolution
4. Test real-time updates
5. Verify sync performance
6. Test error scenarios
    ''');

    print('');
  }

  /// Common migration challenges and solutions
  static void showCommonChallenges() {
    print('⚠️ COMMON MIGRATION CHALLENGES & SOLUTIONS:');
    print('');

    print('''
CHALLENGE 1: Existing Data Loss
SOLUTION: Backup before migration, use migration scripts

-- Before migration: backup
CREATE TABLE users_backup AS SELECT * FROM users;

-- After successful migration and testing
DROP TABLE users_backup;

CHALLENGE 2: Field Naming Conflicts
SOLUTION: Use field mappings in USM config

syncManager.registerEntity('users', SyncEntityConfig(
  tableName: 'users',
  fieldMappings: {
    'organizationId': 'organization_id',  // Local -> Remote
    'createdBy': 'created_by',
    'updatedBy': 'updated_by',
    'createdAt': 'created_at',
    'updatedAt': 'updated_at',
  },
));

CHALLENGE 3: Large Existing Datasets
SOLUTION: Batch migration with progress tracking

Future<void> migrateLargeDataset() async {
  const batchSize = 1000;
  int offset = 0;
  
  while (true) {
    final batch = await getLegacyDataBatch(offset, batchSize);
    if (batch.isEmpty) break;
    
    final migratedBatch = batch.map((item) => 
      User.fromLegacyJson(item)).toList();
    
    await saveMigratedBatch(migratedBatch);
    
    offset += batchSize;
    print('Migrated \$offset records...');
  }
}

CHALLENGE 4: Different Conflict Resolution Needs
SOLUTION: Custom conflict resolver

class CustomConflictResolver implements ConflictResolver {
  @override
  SyncConflictResolution resolveConflict(SyncConflict conflict) {
    // Custom logic for your business rules
    if (conflict.entityName == 'users') {
      // Always prefer server data for user profiles
      return SyncConflictResolution.useServer();
    }
    
    // Use timestamp for other entities
    return SyncConflictResolution.useNewer();
  }
}

syncManager.setConflictResolver('users', CustomConflictResolver());

CHALLENGE 5: Performance During Migration
SOLUTION: Gradual migration and optimization

// Option 1: Gradual migration (run both systems temporarily)
class HybridUserService {
  final bool useUSM = true; // Feature flag
  
  Future<List<User>> getUsers() async {
    if (useUSM) {
      return await UserRepository().getAll();
    } else {
      return await LegacyUserService().getUsers();
    }
  }
}

// Option 2: Optimize USM settings for migration
await syncManager.initialize(UniversalSyncConfig(
  projectId: 'your-app',
  syncMode: SyncMode.manual,  // Control sync timing during migration
  batchSize: 50,              // Smaller batches during migration
  syncIntervalSeconds: 300,   // Less frequent auto-sync
));
    ''');

    print('');
  }

  /// Migration success validation
  static Future<void> validateMigration() async {
    print('✅ MIGRATION VALIDATION CHECKLIST:');
    print('');

    print('''
DATA INTEGRITY CHECKS:
□ All existing records preserved
□ No data corruption during migration
□ All required USM fields populated
□ Foreign key relationships maintained
□ Indexes created and performing well

FUNCTIONALITY CHECKS:
□ CRUD operations work correctly
□ Offline functionality works
□ Real-time updates work
□ Conflict resolution tested
□ Authentication flows work
□ File uploads work (if applicable)

PERFORMANCE CHECKS:
□ Sync performance acceptable
□ Database queries optimized
□ UI responsiveness maintained
□ Memory usage reasonable
□ Battery usage reasonable (mobile)

ROLLBACK PLAN READY:
□ Database backup available
□ Code rollback plan documented
□ Monitoring in place to detect issues
□ Team knows rollback procedure

MIGRATION SUCCESS INDICATORS:
✅ App works offline
✅ Real-time updates automatic
✅ No manual sync code needed
✅ Conflicts resolved automatically
✅ Performance equal or better
✅ Code simpler and more maintainable
✅ Easy to switch backends in future
    ''');

    print('');
    print('🎉 CONGRATULATIONS!');
    print('You have successfully migrated to Universal Sync Manager!');
    print('');
    print('Your app now has:');
    print('✅ Full offline support');
    print('✅ Automatic background sync');
    print('✅ Intelligent conflict resolution');
    print('✅ Real-time updates');
    print('✅ Backend flexibility');
    print('✅ Simplified codebase');
    print('');
  }
}

/// Run the complete migration example
Future<void> runPocketBaseMigrationExample() async {
  print('🚀 PocketBase to USM Migration Example');
  print('');

  PocketBaseMigrationExample.showOldPattern();
  PocketBaseMigrationExample.showNewPattern();
  await PocketBaseMigrationExample.showMigrationSteps();
  PocketBaseMigrationExample.showCommonChallenges();
  await PocketBaseMigrationExample.validateMigration();

  print('📚 Additional Resources:');
  print('- Full migration guide: /doc/migration/USM_MIGRATION_GUIDE.md');
  print('- Quick migration: /doc/migration/QUICK_MIGRATION_GUIDE.md');
  print('- Model examples: /doc/examples/model_creation_example.dart');
  print('- Repository patterns: /doc/examples/repository_pattern_example.dart');
}

/// Key Migration Benefits:
/// 
/// 1. **Simplified Code**: Remove 70%+ of sync-related code
/// 2. **Better UX**: Instant offline support and real-time updates
/// 3. **Reliability**: Built-in retry, error handling, and conflict resolution
/// 4. **Flexibility**: Easy to switch backends without code changes
/// 5. **Performance**: Optimized sync with delta updates and batching
/// 6. **Maintainability**: Standard patterns and less custom logic
/// 7. **Monitoring**: Built-in analytics and debugging tools
/// 
/// Migration Effort:
/// 
/// - **Small App** (1-5 entities): 2-4 hours
/// - **Medium App** (5-20 entities): 1-2 days  
/// - **Large App** (20+ entities): 3-5 days
/// 
/// The effort is front-loaded but pays dividends in reduced maintenance,
/// better reliability, and faster feature development going forward.
