# Universal Sync Manager Migration Guide - Phase 3

## Overview

This guide helps you migrate your existing synchronization implementation to the Universal Sync Manager (USM) Phase 3: App Integration Framework. Phase 3 provides a simplified, high-level API through `MyAppSyncManager` that handles authentication, sync, and state management automatically with minimal configuration.

## Table of Contents

- [Migration Scenarios](#migration-scenarios)
- [Pre-Migration Assessment](#pre-migration-assessment)
- [Step-by-Step Migration](#step-by-step-migration)
- [Database Schema Migration](#database-schema-migration)
- [Code Migration](#code-migration)
- [Authentication Integration](#authentication-integration)
- [State Management Integration](#state-management-integration)
- [Testing Migration](#testing-migration)
- [Common Issues and Solutions](#common-issues-and-solutions)
- [Post-Migration Verification](#post-migration-verification)

## Migration Scenarios

### Scenario 1: PocketBase-Only to MyAppSyncManager
**Current**: Direct PocketBase SDK usage  
**Target**: MyAppSyncManager with automatic PocketBase integration  
**Complexity**: Very Low  
**Estimated Time**: 1-2 hours

### Scenario 2: Firebase-Only to MyAppSyncManager
**Current**: Direct Firebase SDK usage  
**Target**: MyAppSyncManager with automatic Firebase integration  
**Complexity**: Low  
**Estimated Time**: 2-3 hours

### Scenario 3: Supabase-Only to MyAppSyncManager
**Current**: Direct Supabase SDK usage  
**Target**: MyAppSyncManager with automatic Supabase integration  
**Complexity**: Low  
**Estimated Time**: 2-3 hours

### Scenario 4: Custom Backend to MyAppSyncManager
**Current**: Custom sync implementation  
**Target**: MyAppSyncManager with custom adapter  
**Complexity**: Medium  
**Estimated Time**: 4-8 hours

### Scenario 5: Multiple Backends to MyAppSyncManager
**Current**: Different backends for different features  
**Target**: Unified MyAppSyncManager with automatic backend switching  
**Complexity**: Medium  
**Estimated Time**: 1-2 days

## Pre-Migration Assessment - Phase 3

### 1. Data Model Analysis

Before migrating, analyze your current data models:

```dart
// ❌ Before - Manual audit field management
class UserProfile {
  final String id;
  final String organizationId;
  final String name;
  final String email;
  
  // Manual audit fields - complex to manage
  final String createdBy;
  final String updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final bool isDirty;
  final DateTime? lastSyncedAt;
  final int syncVersion;
  final bool isDeleted;
  
  // Complex copyWith method required
  UserProfile copyWith({/* many parameters */}) { /* complex logic */ }
}

// ✅ After - Phase 3 simplified (MyAppSyncManager handles audit fields)
class UserProfile implements SyncableModel {
  final String id;
  final String organizationId;
  final String name;
  final String email;
  
  UserProfile({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.email,
  });

  // Simple JSON serialization only
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'organizationId': organizationId,
    'name': name,
    'email': email,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'],
    organizationId: json['organizationId'],
    name: json['name'],
    email: json['email'],
  );
}

// Note: MyAppSyncManager automatically handles:
// - createdBy, updatedBy, createdAt, updatedAt, deletedAt
// - isDirty, lastSyncedAt, syncVersion, isDeleted
// - copyWith methods, conflict resolution, sync status
```

### 2. Backend Configuration Audit

Document your current backend configuration:

```yaml
# Phase 3 Configuration Assessment
backend_type: "pocketbase"  # firebase, supabase, custom
base_url: "https://your-pb-instance.com"
authentication:
  provider: "firebase"  # supabase, auth0, custom
  auto_login: true
collections:
  - name: "user_profiles"
    auto_detected: true  # MyAppSyncManager auto-detects models
  - name: "organization_data"
    auto_detected: true
sync_features:
  offline_first: true      # Built-in offline support
  real_time: true          # Automatic real-time updates
  conflict_resolution: "smart"  # Intelligent conflict resolution
  state_management: "auto"      # Auto-integrates with your state management
```

### 3. Current Architecture Assessment

List your current sync features to understand migration scope:

- [ ] Real-time updates
- [ ] Conflict resolution
- [ ] Offline support
- [ ] User authentication
- [ ] Multi-tenancy support
- [ ] Data validation
- [ ] Audit logging

## Step-by-Step Migration - Phase 3

### Step 1: Dependencies Migration

#### 1.1 Update pubspec.yaml

```yaml
dependencies:
  # Keep your current backend SDK for gradual migration
  pocketbase: ^0.18.0  # Keep if using PocketBase
  firebase_core: ^2.x.x  # Keep if using Firebase
  supabase_flutter: ^x.x.x  # Keep if using Supabase
  
  # Add MyAppSyncManager
  universal_sync_manager:
    path: ../universal_sync_manager  # During development
    # git: https://github.com/your-org/universal_sync_manager.git  # Production
```

#### 1.2 Import Migration

```dart
// ❌ Before - Direct backend imports
import 'package:pocketbase/pocketbase.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ✅ After - Phase 3 simplified imports
import 'package:universal_sync_manager/universal_sync_manager.dart';
// That's it! MyAppSyncManager handles everything
```

### Step 2: Data Model Migration (Simplified)

#### 2.1 Implement SyncableModel Interface

```dart
// ❌ Before - Complex model with manual audit fields
class UserProfile {
  final String id;
  final String name;
  final String organizationId;
  final DateTime? updatedAt;
  
  // Manual audit fields management
  final String createdBy;
  final String updatedBy;
  final DateTime? createdAt;
  final DateTime? deletedAt;
  final bool isDirty;
  final DateTime? lastSyncedAt;
  final int syncVersion;
  final bool isDeleted;
  
  UserProfile({
    required this.id,
    required this.name,
    required this.organizationId,
    this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
    this.createdAt,
    this.deletedAt,
    this.isDirty = true,
    this.lastSyncedAt,
    this.syncVersion = 0,
    this.isDeleted = false,
  });
  
  // Complex copyWith method
  UserProfile copyWith({
    String? name,
    String? updatedBy,
    DateTime? updatedAt,
    bool? isDirty,
    DateTime? lastSyncedAt,
    int? syncVersion,
    bool? isDeleted,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      organizationId: organizationId,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt,
      deletedAt: deletedAt,
      isDirty: isDirty ?? this.isDirty,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncVersion: syncVersion ?? this.syncVersion,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

// ✅ After - Phase 3 simplified (MyAppSyncManager handles complexity)
class UserProfile implements SyncableModel {
  final String id;
  final String name;
  final String organizationId;
  
  UserProfile({
    required this.id,
    required this.name,
    required this.organizationId,
  });
  
  // Only JSON serialization needed
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'organizationId': organizationId,
  };
  
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'],
    name: json['name'],
    organizationId: json['organizationId'],
  );
  
  // Optional: Simple copyWith for UI updates
  UserProfile copyWith({
    String? name,
  }) => UserProfile(
    id: id,
    name: name ?? this.name,
    organizationId: organizationId,
  );
}

// Note: MyAppSyncManager automatically manages:
// ✅ All audit fields (createdBy, updatedBy, timestamps)
// ✅ All sync fields (isDirty, syncVersion, lastSyncedAt)
// ✅ Conflict resolution and sync logic
// ✅ Offline-first data management
```

### Step 3: Authentication Migration (Simplified)

#### 3.1 Replace Direct Auth with MyAppSyncManager Auth

```dart
// ❌ Before - Manual auth management
class AuthService {
  final PocketBase pb;
  
  Future<bool> login(String email, String password) async {
    try {
      await pb.collection('users').authWithPassword(email, password);
      return pb.authStore.isValid;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> logout() async {
    pb.authStore.clear();
  }
  
  bool get isAuthenticated => pb.authStore.isValid;
}

// ✅ After - Phase 3 automatic auth integration
class AuthService {
  // MyAppSyncManager handles all authentication automatically
  
  Future<bool> login(String email, String password) async {
    return await MyAppSyncManager.login(
      email: email,
      password: password,
    );
  }
  
  Future<void> logout() async {
    await MyAppSyncManager.logout();
  }
  
  bool get isAuthenticated => MyAppSyncManager.isAuthenticated;
  
  // Bonus: Listen to auth state changes
  Stream<bool> get authStateStream => MyAppSyncManager.authStateStream;
```

### Step 4: Repository Migration (Simplified)

#### 4.1 Convert to Local-First Pattern

```dart
// ❌ Before - Direct backend repository
class UserRepository {
  final PocketBase pb;
  
  UserRepository(this.pb);
  
  Future<void> create(UserProfile user) async {
    await pb.collection('user_profiles').create(body: user.toJson());
  }
  
  Future<UserProfile?> getById(String id) async {
    final record = await pb.collection('user_profiles').getOne(id);
    return UserProfile.fromJson(record.toJson());
  }
  
  Future<List<UserProfile>> getAll() async {
    final records = await pb.collection('user_profiles').getFullList();
    return records.map((r) => UserProfile.fromJson(r.toJson())).toList();
  }
  
  Future<void> update(UserProfile user) async {
    await pb.collection('user_profiles').update(user.id, body: user.toJson());
  }
  
  Future<void> delete(String id) async {
    await pb.collection('user_profiles').delete(id);
  }
}

// ✅ After - Phase 3 local-first (MyAppSyncManager handles sync)
class UserRepository {
  static const String tableName = 'user_profiles';
  
  // Local operations only - MyAppSyncManager handles sync automatically
  
  Future<void> create(UserProfile user) async {
    final db = await DatabaseHelper.database;
    await db.insert(tableName, user.toJson());
    // MyAppSyncManager detects new data and syncs automatically
  }
  
  Future<UserProfile?> getById(String id) async {
    final db = await DatabaseHelper.database;
    final result = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (result.isEmpty) return null;
    return UserProfile.fromJson(result.first);
  }
  
  Future<List<UserProfile>> getAll() async {
    final db = await DatabaseHelper.database;
    final result = await db.query(
      tableName,
      orderBy: 'name ASC',
    );
    
    return result.map((json) => UserProfile.fromJson(json)).toList();
  }
  
  Future<void> update(UserProfile user) async {
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
    // MyAppSyncManager handles deletion sync automatically
  }
  
  // Bonus: Real-time stream with MyAppSyncManager
  Stream<List<UserProfile>> watchAll() {
    return MyAppSyncManager.watchCollection<UserProfile>('user_profiles');
  }
}
  final String updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final bool isDirty;
  final DateTime? lastSyncedAt;
  final int syncVersion;
  final bool isDeleted;
  
  UserProfile({
    required this.id,
    required this.name,
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
  UserProfile copyWith({
    String? name,
    String? updatedBy,
    DateTime? updatedAt,
    bool? isDirty,
    DateTime? lastSyncedAt,
    int? syncVersion,
    bool? isDeleted,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      organizationId: organizationId,
      createdBy: createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt,
      isDirty: isDirty ?? this.isDirty,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncVersion: syncVersion ?? this.syncVersion,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'organizationId': organizationId,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'isDirty': isDirty,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'syncVersion': syncVersion,
      'isDeleted': isDeleted,
    };
  }
  
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      organizationId: json['organizationId'],
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
      isDirty: json['isDirty'] ?? true,
      lastSyncedAt: json['lastSyncedAt'] != null ? DateTime.parse(json['lastSyncedAt']) : null,
      syncVersion: json['syncVersion'] ?? 0,
      isDeleted: json['isDeleted'] ?? false,
    );
  }
}
```

#### 2.2 Repository Migration

```dart
// ❌ Before - Direct backend repository
class UserProfileRepository {
  final PocketBase _pb;
  
  UserProfileRepository(this._pb);
  
  Future<void> create(UserProfile profile) async {
    await _pb.collection('user_profiles').create(body: profile.toJson());
  }
  
  Future<UserProfile?> getById(String id) async {
    final record = await _pb.collection('user_profiles').getOne(id);
    return UserProfile.fromJson(record.toJson());
  }
}

// ✅ After - USM-compatible repository
class UserProfileRepository {
  final String tableName = 'user_profiles';
  
  // Repository now only handles local operations
  // USM handles sync automatically
  
  Future<void> create(UserProfile profile) async {
    final db = await _getDatabase();
    await db.insert(tableName, profile.toJson());
    
    // USM will automatically detect the dirty record and sync it
  }
  
  Future<UserProfile?> getById(String id) async {
    final db = await _getDatabase();
    final result = await db.query(
      tableName,
      where: 'id = ? AND isDeleted = 0',
      whereArgs: [id],
    );
    
    if (result.isEmpty) return null;
    return UserProfile.fromJson(result.first);
  }
  
  Future<Database> _getDatabase() async {
    // Your existing database initialization
    throw UnimplementedError('Implement database access');
  }
}
```

### Step 5: App Initialization (Simplified)

#### 5.1 Replace Complex Setup with MyAppSyncManager

```dart
// ❌ Before - Complex multi-step initialization
class AppInitializer {
  late PocketBase _pb;
  late UniversalSyncManager _syncManager;
  
  Future<void> initialize() async {
    // Step 1: Initialize backend
    _pb = PocketBase('https://your-pb-instance.com');
    await _pb.authStore.loadFromPrefs();
    
    // Step 2: Initialize USM
    _syncManager = UniversalSyncManager();
    await _syncManager.initialize(UniversalSyncConfig(
      projectId: 'your-project-id',
      syncMode: SyncMode.automatic,
      conflictResolutionStrategy: ConflictResolutionStrategy.timestampWins,
      syncIntervalSeconds: 30,
      batchSize: 100,
      enableAnalytics: true,
    ));
    
    // Step 3: Configure adapter
    final adapter = PocketBaseSyncAdapter(baseUrl: 'https://your-pb-instance.com');
    await _syncManager.setBackend(adapter);
    
    // Step 4: Register entities
    _syncManager.registerEntity('user_profiles', SyncEntityConfig(
      tableName: 'user_profiles',
      requiresAuthentication: true,
      conflictStrategy: ConflictResolutionStrategy.timestampWins,
    ));
    
    _syncManager.registerEntity('organizations', SyncEntityConfig(
      tableName: 'organizations',
      requiresAuthentication: true,
      conflictStrategy: ConflictResolutionStrategy.serverWins,
    ));
    
    // Step 5: Start sync
    await _syncManager.startSync();
  }
}

// ✅ After - Phase 3 one-line initialization
class AppInitializer {
  Future<void> initialize() async {
    // That's it! MyAppSyncManager handles everything
    await MyAppSyncManager.initialize(
      backend: SyncBackend.pocketbase(
        url: 'https://your-pb-instance.com',
      ),
      authProvider: AuthProvider.firebase(), // or .supabase(), .auth0()
      options: SyncOptions(
        enableOfflineMode: true,
        syncInterval: Duration(seconds: 30),
        enableAnalytics: true,
        autoRegisterModels: true, // Automatically detects all models
      ),
    );
    
    print('App sync ready! Authentication: ${MyAppSyncManager.isAuthenticated}');
  }
}

// Usage in main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await AppInitializer().initialize();
  
  runApp(MyApp());
}
```

## Authentication Integration - Phase 3

### Automatic Auth Provider Integration

MyAppSyncManager automatically integrates with your chosen authentication provider:

```dart
// Firebase Auth Integration
await MyAppSyncManager.initialize(
  backend: SyncBackend.pocketbase(url: 'https://api.example.com'),
  authProvider: AuthProvider.firebase(),
);

// Supabase Auth Integration  
await MyAppSyncManager.initialize(
  backend: SyncBackend.supabase(url: 'https://project.supabase.co', anonKey: 'key'),
  authProvider: AuthProvider.supabase(),
);

// Auth0 Integration
await MyAppSyncManager.initialize(
  backend: SyncBackend.pocketbase(url: 'https://api.example.com'),
  authProvider: AuthProvider.auth0(domain: 'yourapp.auth0.com', clientId: 'client_id'),
);

// Custom Auth Integration
await MyAppSyncManager.initialize(
  backend: SyncBackend.custom(/* your adapter */),
  authProvider: AuthProvider.custom(/* your auth implementation */),
);
```

### Binary Auth State Management

Phase 3 uses a simplified binary authentication state:

```dart
// Simple auth state checking
if (MyAppSyncManager.isAuthenticated) {
  // User is authenticated - show main app
  return MainApp();
} else {
  // User is not authenticated - show login
  return LoginScreen();
}

// Listen to auth state changes
MyAppSyncManager.authStateStream.listen((isAuthenticated) {
  if (isAuthenticated) {
    Navigator.pushReplacementNamed(context, '/main');
  } else {
    Navigator.pushReplacementNamed(context, '/login');
  }
});
```

## State Management Integration - Phase 3

MyAppSyncManager automatically integrates with popular state management solutions:

### Bloc Integration

```dart
// UserBloc with automatic sync integration
class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc() : super(UserInitial()) {
    // MyAppSyncManager automatically provides real-time updates
    MyAppSyncManager.watchCollection<User>('users').listen((users) {
      add(UsersUpdated(users));
    });
  }
}
```

### Riverpod Integration

```dart
// Automatic provider with real-time updates
final usersProvider = StreamProvider<List<User>>((ref) {
  return MyAppSyncManager.watchCollection<User>('users');
});

// Usage in widgets
Consumer(
  builder: (context, ref, child) {
    final usersAsync = ref.watch(usersProvider);
    return usersAsync.when(
      data: (users) => UsersList(users: users),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error),
    );
  },
)
```

### GetX Integration

```dart
// GetX controller with automatic sync
class UserController extends GetxController {
  final users = <User>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    // MyAppSyncManager provides reactive updates
    MyAppSyncManager.watchCollection<User>('users').listen((userList) {
      users.value = userList;
    });
  }
}
```

### Provider Integration

```dart
// ChangeNotifierProvider with automatic sync
class UserProvider extends ChangeNotifier {
  List<User> _users = [];
  List<User> get users => _users;
  
  UserProvider() {
    MyAppSyncManager.watchCollection<User>('users').listen((userList) {
      _users = userList;
      notifyListeners(); // Automatic UI updates
    });
  }
}
    final adapter = PocketBaseSyncAdapter(
      baseUrl: 'https://your-pb-instance.com',
    );
    
    await _syncManager.setBackend(adapter);
    
    // Register entities
    _syncManager.registerEntity('user_profiles', SyncEntityConfig(
      tableName: 'user_profiles',
      requiresAuthentication: true,
      priority: SyncPriority.high,
      conflictStrategy: ConflictResolutionStrategy.timestampWins,
      enableRealTime: true,
    ));
  }
}
```

### Step 4: Event Handling Migration

```dart
// ❌ Before - Manual event handling
class DataService {
  StreamSubscription? _realtimeSubscription;
  
  void subscribeToUpdates() {
    _realtimeSubscription = _pb.collection('user_profiles')
        .subscribe('*', (e) {
      // Manual handling of real-time updates
      _handleRealtimeUpdate(e);
    });
  }
}

// ✅ After - USM event streams
class DataService {
  StreamSubscription? _syncEventSubscription;
  StreamSubscription? _progressSubscription;
  
  void subscribeToSyncEvents() {
    // Listen to sync events
    _syncEventSubscription = _syncManager.syncEventStream.listen((event) {
      switch (event.type) {
        case SyncEventType.dataChanged:
          _handleDataChange(event);
          break;
        case SyncEventType.conflictDetected:
          _handleConflict(event);
          break;
        case SyncEventType.syncCompleted:
          _handleSyncComplete(event);
          break;
      }
    });
    
    // Listen to sync progress
    _progressSubscription = _syncManager.syncProgressStream.listen((progress) {
      _updateSyncProgressUI(progress);
    });
  }
  
  void _handleDataChange(SyncEvent event) {
    // Refresh UI or update local cache
    notifyDataChanged(event.entityName, event.entityId);
  }
}
```

## Database Schema Migration

### SQLite Schema Update

```sql
-- Step 1: Backup existing data
CREATE TABLE user_profiles_backup AS SELECT * FROM user_profiles;

-- Step 2: Add required USM fields
ALTER TABLE user_profiles ADD COLUMN createdBy TEXT;
ALTER TABLE user_profiles ADD COLUMN updatedBy TEXT;
ALTER TABLE user_profiles ADD COLUMN createdAt TEXT;
ALTER TABLE user_profiles ADD COLUMN updatedAt TEXT;
ALTER TABLE user_profiles ADD COLUMN deletedAt TEXT;
ALTER TABLE user_profiles ADD COLUMN isDirty INTEGER NOT NULL DEFAULT 1;
ALTER TABLE user_profiles ADD COLUMN lastSyncedAt TEXT;
ALTER TABLE user_profiles ADD COLUMN syncVersion INTEGER NOT NULL DEFAULT 0;
ALTER TABLE user_profiles ADD COLUMN isDeleted INTEGER NOT NULL DEFAULT 0;

-- Step 3: Update existing records with default values
UPDATE user_profiles 
SET 
  createdBy = 'migration',
  updatedBy = 'migration',
  createdAt = datetime('now'),
  updatedAt = datetime('now'),
  isDirty = 1,
  syncVersion = 0,
  isDeleted = 0
WHERE createdBy IS NULL;

-- Step 4: Create performance indexes
CREATE INDEX IF NOT EXISTS idx_user_profiles_organization_id 
  ON user_profiles (organizationId);
CREATE INDEX IF NOT EXISTS idx_user_profiles_is_dirty 
  ON user_profiles (isDirty);
CREATE INDEX IF NOT EXISTS idx_user_profiles_is_deleted 
  ON user_profiles (isDeleted);
CREATE INDEX IF NOT EXISTS idx_user_profiles_sync_version 
  ON user_profiles (syncVersion);
```

### Backend Schema Update

#### PocketBase Collections

```javascript
// Update PocketBase collection schema
migrate((db) => {
  const collection = db.findCollectionByNameOrId("user_profiles");
  
  // Add new fields with camelCase naming
  collection.schema.addField(new SchemaField({
    name: "createdBy",
    type: "text",
    required: true
  }));
  
  collection.schema.addField(new SchemaField({
    name: "updatedBy", 
    type: "text",
    required: true
  }));
  
  collection.schema.addField(new SchemaField({
    name: "createdAt",
    type: "date"
  }));
  
  collection.schema.addField(new SchemaField({
    name: "updatedAt",
    type: "date"
  }));
  
  collection.schema.addField(new SchemaField({
    name: "deletedAt",
    type: "date"
  }));
  
  collection.schema.addField(new SchemaField({
    name: "isDirty",
    type: "bool",
    required: true
  }));
  
  collection.schema.addField(new SchemaField({
    name: "lastSyncedAt",
    type: "date"
  }));
  
  collection.schema.addField(new SchemaField({
    name: "syncVersion",
    type: "number",
    required: true
  }));
  
  collection.schema.addField(new SchemaField({
    name: "isDeleted",
    type: "bool",
    required: true
  }));
  
  return db.saveCollection(collection);
});
```

## Testing Migration

### 1. Create Migration Tests

```dart
// test/migration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';

void main() {
  group('Migration Tests', () {
    test('should migrate legacy data model', () async {
      // Arrange
      final legacyData = {
        'id': 'test-1',
        'name': 'Test User',
        'organization_id': 'org-1',  // snake_case
        'created_at': '2024-01-01T10:00:00Z',
      };
      
      // Act
      final migratedProfile = UserProfile.fromLegacyJson(legacyData);
      
      // Assert
      expect(migratedProfile.organizationId, 'org-1');
      expect(migratedProfile.createdAt, isNotNull);
      expect(migratedProfile.isDirty, true);
      expect(migratedProfile.syncVersion, 0);
    });
    
    test('should preserve data integrity during migration', () async {
      // Test data preservation during migration
    });
    
    test('should handle sync after migration', () async {
      // Test that sync works correctly after migration
    });
  });
}
```

### 2. Migration Validation Script

```dart
// scripts/validate_migration.dart
import 'dart:io';

Future<void> main() async {
  print('🔍 Validating USM Migration...');
  
  // 1. Check database schema
  await validateDatabaseSchema();
  
  // 2. Check data integrity
  await validateDataIntegrity();
  
  // 3. Check sync functionality
  await validateSyncFunctionality();
  
  print('✅ Migration validation completed successfully!');
}

Future<void> validateDatabaseSchema() async {
  print('Checking database schema...');
  
  // Check that all required USM fields exist
  final requiredFields = [
    'createdBy', 'updatedBy', 'createdAt', 'updatedAt', 'deletedAt',
    'isDirty', 'lastSyncedAt', 'syncVersion', 'isDeleted'
  ];
  
  // Implementation depends on your database access layer
  // This is a conceptual example
  
  print('✓ Database schema validation passed');
}

Future<void> validateDataIntegrity() async {
  print('Checking data integrity...');
  
  // Check that no data was lost during migration
  // Check that all records have required audit fields
  
  print('✓ Data integrity validation passed');
}

Future<void> validateSyncFunctionality() async {
  print('Checking sync functionality...');
  
  // Create test sync manager
  // Perform test sync operations
  // Verify sync events and progress
  
  print('✓ Sync functionality validation passed');
}
```

## Common Issues and Solutions

### Issue 1: Field Naming Conflicts

**Problem**: Backend uses snake_case but USM requires camelCase

**Solution**: Use field mapping configuration

```dart
_syncManager.registerEntity('user_profiles', SyncEntityConfig(
  tableName: 'user_profiles',
  fieldMappings: {
    'organizationId': 'organization_id',  // Local -> Remote
    'createdBy': 'created_by',
    'updatedBy': 'updated_by',
    'createdAt': 'created_at',
    'updatedAt': 'updated_at',
    'deletedAt': 'deleted_at',
    'isDirty': 'is_dirty',
    'lastSyncedAt': 'last_synced_at',
    'syncVersion': 'sync_version',
    'isDeleted': 'is_deleted',
  },
));
```

### Issue 2: Large Dataset Migration

**Problem**: Migrating large amounts of existing data

**Solution**: Implement batch migration

```dart
Future<void> migrateLargeDataset() async {
  const batchSize = 1000;
  int offset = 0;
  
  while (true) {
    final batch = await getLegacyDataBatch(offset, batchSize);
    if (batch.isEmpty) break;
    
    final migratedBatch = batch.map((item) => 
      UserProfile.fromLegacyJson(item)).toList();
    
    await saveMigratedBatch(migratedBatch);
    
    offset += batchSize;
    print('Migrated ${offset} records...');
  }
  
  print('Migration completed!');
}
```

### Issue 3: Conflict Resolution Strategy Changes

**Problem**: Different conflict resolution requirements

**Solution**: Configure custom conflict resolver

```dart
class MigrationConflictResolver implements ConflictResolver {
  @override
  SyncConflictResolution resolveConflict(SyncConflict conflict) {
    // During migration, prefer server data for audit fields
    if (conflict.fieldConflicts.keys.any((field) => 
        ['createdBy', 'updatedBy', 'createdAt'].contains(field))) {
      return SyncConflictResolution.useServer(conflict.fieldConflicts.keys);
    }
    
    // Use timestamp for business data
    return SyncConflictResolution.useNewer();
  }
}

// Register the custom resolver
_syncManager.setConflictResolver(
  'user_profiles',
  MigrationConflictResolver(),
);
```

## Post-Migration Verification

### 1. Data Verification Checklist

- [ ] All existing records have required audit fields
- [ ] No data loss during migration
- [ ] Field naming follows USM standards
- [ ] Indexes are properly created
- [ ] Performance is acceptable

### 2. Functionality Verification

```dart
Future<void> verifyMigration() async {
  // Test basic CRUD operations
  await testCrudOperations();
  
  // Test sync functionality
  await testSyncOperations();
  
  // Test conflict resolution
  await testConflictResolution();
  
  // Test real-time updates
  await testRealtimeUpdates();
  
  print('✅ All migration verification tests passed!');
}
```

### 3. Performance Verification

```dart
Future<void> measurePerformance() async {
  final stopwatch = Stopwatch()..start();
  
  // Measure sync performance
  final result = await _syncManager.syncEntity('user_profiles');
  
  stopwatch.stop();
  
  print('Sync completed in ${stopwatch.elapsedMilliseconds}ms');
  print('Synced ${result.affectedItems} items');
  
  // Compare with pre-migration benchmarks
}
```

## Migration Rollback Plan

### 1. Database Rollback

```sql
-- Rollback to pre-migration state
DROP TABLE user_profiles;
ALTER TABLE user_profiles_backup RENAME TO user_profiles;

-- Recreate original indexes
CREATE INDEX idx_user_profiles_org_id ON user_profiles (organization_id);
```

### 2. Code Rollback

1. Revert pubspec.yaml changes
2. Restore original model classes
3. Restore original repository implementations
4. Restore original sync service

### 3. Rollback Verification

```dart
Future<void> verifyRollback() async {
  // Verify original functionality works
  // Check data integrity
  // Test original sync mechanisms
}
```

## Next Steps

After successful migration:

1. **Monitor Performance**: Use USM analytics to monitor sync performance
2. **Optimize Configuration**: Fine-tune sync settings based on usage patterns
3. **Add Advanced Features**: Implement additional USM features like delta sync
4. **Training**: Train team on new USM patterns and best practices
5. **Documentation**: Update internal documentation to reflect new architecture

## Support and Resources

- **Documentation**: `/doc/guides/` directory
- **Examples**: `/doc/examples/` directory  
- **Test Suite**: Run `flutter test` for validation
- **Community**: [GitHub Issues](https://github.com/your-org/universal_sync_manager/issues)

---

**Migration Checklist Summary**

- [ ] Pre-migration assessment completed
- [ ] Dependencies updated
- [ ] Data models migrated to SyncableModel
- [ ] Repository pattern updated
- [ ] Sync manager initialized
- [ ] Database schema updated
- [ ] Backend schema updated (if needed)
- [ ] Event handling migrated
- [ ] Tests created and passing
- [ ] Performance verified
- [ ] Rollback plan documented
- [ ] Team trained on new patterns

**Estimated Migration Time**: 4-24 hours depending on complexity and dataset size.
