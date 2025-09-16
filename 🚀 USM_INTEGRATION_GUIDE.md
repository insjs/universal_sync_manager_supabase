# 🚀 Universal Sync Manager - Integration Guide

**Version**: 1.0.0  
**Date**: September 16, 2025  
**Status**: Production Ready

---

## 🎯 Quick Start

Get Universal Sync Manager running in your Flutter app in **5 minutes**:

### 1. Add Dependencies

```yaml
# pubspec.yaml
dependencies:
  universal_sync_manager: ^1.0.0
  
  # Backend adapters (choose one or more)
  supabase_flutter: ^2.5.6      # For Supabase
  firebase_core: ^2.24.2        # For Firebase
  # pocketbase: ^0.18.0         # For PocketBase (coming soon)
  
  # State management (recommended)
  flutter_riverpod: ^2.4.9
  
  # Utilities
  uuid: ^4.1.0
  sqflite: ^2.3.0               # For local storage
```

### 2. Basic Setup

```dart
// main.dart
import 'package:universal_sync_manager/universal_sync_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize your backend (Supabase example)
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Sync App',
      home: MyHomePage(),
    );
  }
}
```

### 3. Initialize Sync Manager

```dart
class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late UniversalSyncManager syncManager;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    initializeSyncManager();
  }

  Future<void> initializeSyncManager() async {
    // Initialize the sync manager
    syncManager = UniversalSyncManager();
    
    await syncManager.initialize(UniversalSyncConfig(
      projectId: 'my-app-project',
      syncMode: SyncMode.automatic,
      conflictStrategy: ConflictResolutionStrategy.timestampWins,
    ));

    // Set up Supabase adapter
    final adapter = SupabaseSyncAdapter();
    await adapter.connect(SyncBackendConfiguration(
      url: 'YOUR_SUPABASE_URL',
      apiKey: 'YOUR_SUPABASE_ANON_KEY',
    ));
    
    await syncManager.setBackend(adapter);

    // Register your entities
    syncManager.registerEntity('users', SyncEntityConfig(
      tableName: 'users',
      requiresAuthentication: true,
      conflictStrategy: ConflictResolutionStrategy.serverWins,
    ));

    setState(() {
      isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('My Sync App')),
      body: MySyncWidget(syncManager: syncManager),
    );
  }
}
```

### 4. Use Sync Operations

```dart
class MySyncWidget extends StatelessWidget {
  final UniversalSyncManager syncManager;

  MySyncWidget({required this.syncManager});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            // Sync all entities
            final results = await syncManager.syncAll();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Sync completed: ${results.length} entities')),
            );
          },
          child: Text('Sync All'),
        ),
        
        ElevatedButton(
          onPressed: () async {
            // Sync specific entity
            final result = await syncManager.syncEntity('users');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(
                result.isSuccess 
                  ? 'Users synced: ${result.affectedItems} items'
                  : 'Sync failed: ${result.error?.message}'
              )),
            );
          },
          child: Text('Sync Users'),
        ),
        
        // Real-time sync events
        StreamBuilder<SyncEvent>(
          stream: syncManager.syncEventStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return SizedBox();
            
            final event = snapshot.data!;
            return Container(
              padding: EdgeInsets.all(8),
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${event.type}: ${event.message}'),
            );
          },
        ),
      ],
    );
  }
}
```

**🎉 Congratulations!** You now have a working sync-enabled Flutter app!

---

## 🏗️ Architecture Overview

### Core Components

```
┌─────────────────────────────────────────┐
│              Your Flutter App           │
├─────────────────────────────────────────┤
│         UniversalSyncManager            │ ← Main API
├─────────────────────────────────────────┤
│    Backend Adapters (Pluggable)        │
│  ┌─────────────┬─────────────┬────────┐ │
│  │  Supabase   │  Firebase   │ Custom │ │ ← Adapters
│  │   Adapter   │   Adapter   │ Adapter│ │
│  └─────────────┴─────────────┴────────┘ │
├─────────────────────────────────────────┤
│        Local Storage (SQLite)           │ ← Offline Storage
└─────────────────────────────────────────┘
```

### Data Flow

```
Local Data ←→ UniversalSyncManager ←→ Backend Adapter ←→ Remote Database
     ↓                ↓                      ↓
  SQLite       Event System           Supabase/Firebase
     ↓                ↓                      ↓
   Offline       Real-time UI         Authentication
   Storage         Updates              & Security
```

---

## 🛠️ Detailed Integration

### Database Schema Setup

#### Required Fields for Syncable Tables

Every table you want to sync must include these fields:

```sql
-- PostgreSQL/Supabase example
CREATE TABLE your_table (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL,
  
  -- Your business fields here
  name TEXT NOT NULL,
  description TEXT,
  
  -- Required audit fields (camelCase in your Dart models)
  created_by UUID NOT NULL,
  updated_by UUID NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  
  -- Required sync fields (camelCase in your Dart models)
  is_dirty BOOLEAN DEFAULT true,
  last_synced_at TIMESTAMPTZ,
  sync_version INTEGER DEFAULT 0,
  is_deleted BOOLEAN DEFAULT false
);

-- Performance indexes
CREATE INDEX idx_your_table_organization_id ON your_table (organization_id);
CREATE INDEX idx_your_table_is_dirty ON your_table (is_dirty);
CREATE INDEX idx_your_table_last_synced_at ON your_table (last_synced_at);
```

#### Row Level Security (RLS) Setup

```sql
-- Enable RLS
ALTER TABLE your_table ENABLE ROW LEVEL SECURITY;

-- Create policy for organization isolation
CREATE POLICY "Users can only access their organization data" 
ON your_table FOR ALL 
USING (organization_id = (auth.jwt() ->> 'organization_id')::UUID);
```

### Model Implementation

#### 1. Create Your Data Model

```dart
// models/user_profile.dart
import 'package:universal_sync_manager/universal_sync_manager.dart';

class UserProfile with SyncableModel {
  @override
  final String id;
  
  @override
  final String organizationId;
  
  // Business fields
  final String name;
  final String email;
  final bool isActive;
  
  // Required audit fields
  final String createdBy;
  final String updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  
  // Required sync fields
  @override
  final bool isDirty;
  @override
  final DateTime? lastSyncedAt;
  @override
  final int syncVersion;
  @override
  final bool isDeleted;

  UserProfile({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.email,
    required this.isActive,
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

  // Required copyWith method
  UserProfile copyWith({
    String? id,
    String? organizationId,
    String? name,
    String? email,
    bool? isActive,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool? isDirty,
    DateTime? lastSyncedAt,
    int? syncVersion,
    bool? isDeleted,
  }) {
    return UserProfile(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isDirty: isDirty ?? this.isDirty,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncVersion: syncVersion ?? this.syncVersion,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizationId': organizationId,
      'name': name,
      'email': email,
      'isActive': isActive,
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
      organizationId: json['organizationId'],
      name: json['name'],
      email: json['email'],
      isActive: json['isActive'] ?? true,
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

#### 2. Create Repository

```dart
// repositories/user_profile_repository.dart
import 'package:sqflite/sqflite.dart';
import '../models/user_profile.dart';

class UserProfileRepository {
  final Database database;

  UserProfileRepository(this.database);

  Future<List<UserProfile>> getAll() async {
    final results = await database.query(
      'user_profiles',
      where: 'isDeleted = ? AND organizationId = ?',
      whereArgs: [0, currentOrganizationId],
    );
    
    return results.map((json) => UserProfile.fromJson(json)).toList();
  }

  Future<UserProfile?> getById(String id) async {
    final results = await database.query(
      'user_profiles',
      where: 'id = ? AND isDeleted = ?',
      whereArgs: [id, 0],
      limit: 1,
    );
    
    if (results.isEmpty) return null;
    return UserProfile.fromJson(results.first);
  }

  Future<void> insert(UserProfile profile) async {
    await database.insert(
      'user_profiles',
      profile.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(UserProfile profile) async {
    await database.update(
      'user_profiles',
      profile.copyWith(
        isDirty: true,
        syncVersion: profile.syncVersion + 1,
        updatedAt: DateTime.now(),
      ).toJson(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  Future<void> delete(String id) async {
    await database.update(
      'user_profiles',
      {
        'isDeleted': 1,
        'isDirty': 1,
        'deletedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<UserProfile>> getDirtyRecords() async {
    final results = await database.query(
      'user_profiles',
      where: 'isDirty = ?',
      whereArgs: [1],
    );
    
    return results.map((json) => UserProfile.fromJson(json)).toList();
  }
}
```

### Advanced Configuration

#### 1. Custom Conflict Resolution

```dart
class CustomConflictResolver implements ConflictResolver {
  @override
  SyncConflictResolution resolveConflict(SyncConflict conflict) {
    // Custom logic for your business needs
    
    // Example: Always prefer server data for certain fields
    if (conflict.fieldConflicts.containsKey('isActive')) {
      return SyncConflictResolution.useServer(['isActive']);
    }
    
    // Example: Prefer client data for user-modified fields
    if (conflict.fieldConflicts.containsKey('name') || 
        conflict.fieldConflicts.containsKey('email')) {
      return SyncConflictResolution.useClient(['name', 'email']);
    }
    
    // Example: Intelligent merge for specific scenarios
    if (conflict.entity == 'user_profiles') {
      return SyncConflictResolution.merge({
        'name': conflict.clientData['name'], // Keep client name
        'isActive': conflict.serverData['isActive'], // Keep server status
        'updatedAt': DateTime.now().toIso8601String(), // Update timestamp
      });
    }
    
    // Default: Use timestamp strategy
    return SyncConflictResolution.useTimestamp();
  }
}

// Register custom resolver
syncManager.setConflictResolver('user_profiles', CustomConflictResolver());
```

#### 2. Event Handling

```dart
class SyncEventHandler {
  final UniversalSyncManager syncManager;

  SyncEventHandler(this.syncManager) {
    _setupEventListeners();
  }

  void _setupEventListeners() {
    // Listen to all sync events
    syncManager.syncEventStream.listen((event) {
      switch (event.type) {
        case SyncEventType.syncStarted:
          print('🔄 Sync started for ${event.entity}');
          break;
        case SyncEventType.syncProgress:
          print('📊 Sync progress: ${event.progress}% (${event.entity})');
          break;
        case SyncEventType.syncCompleted:
          print('✅ Sync completed for ${event.entity}');
          break;
        case SyncEventType.syncError:
          print('❌ Sync error: ${event.error} (${event.entity})');
          break;
        case SyncEventType.dataCreated:
          print('📝 Data created: ${event.entity}');
          break;
        case SyncEventType.dataUpdated:
          print('✏️ Data updated: ${event.entity}');
          break;
        case SyncEventType.dataDeleted:
          print('🗑️ Data deleted: ${event.entity}');
          break;
      }
    });

    // Listen to conflict events
    syncManager.conflictStream.listen((conflict) {
      print('⚠️ Conflict detected: ${conflict.entity} - ${conflict.recordId}');
      print('   Fields: ${conflict.fieldConflicts.keys.join(', ')}');
      
      // You can implement custom UI for conflict resolution here
      _showConflictDialog(conflict);
    });

    // Listen to connection events
    syncManager.connectionEventStream.listen((event) {
      switch (event.status) {
        case ConnectionStatus.connected:
          print('🌐 Connected to backend');
          break;
        case ConnectionStatus.disconnected:
          print('📡 Disconnected from backend');
          break;
        case ConnectionStatus.reconnecting:
          print('🔄 Reconnecting to backend...');
          break;
      }
    });
  }

  void _showConflictDialog(SyncConflict conflict) {
    // Implement your conflict resolution UI
    // This could be a dialog, bottom sheet, or dedicated screen
  }
}
```

#### 3. State Management Integration (Riverpod)

```dart
// providers/sync_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';

// Sync manager provider
final syncManagerProvider = Provider<UniversalSyncManager>((ref) {
  throw UnimplementedError('SyncManager must be overridden');
});

// Sync state provider
final syncStateProvider = StateNotifierProvider<SyncStateNotifier, SyncState>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  return SyncStateNotifier(syncManager);
});

// Sync events stream provider
final syncEventsProvider = StreamProvider<SyncEvent>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  return syncManager.syncEventStream;
});

// User profiles provider
final userProfilesProvider = StateNotifierProvider<UserProfilesNotifier, AsyncValue<List<UserProfile>>>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  return UserProfilesNotifier(syncManager);
});

class SyncStateNotifier extends StateNotifier<SyncState> {
  final UniversalSyncManager _syncManager;

  SyncStateNotifier(this._syncManager) : super(SyncState.idle) {
    _setupListeners();
  }

  void _setupListeners() {
    _syncManager.syncEventStream.listen((event) {
      switch (event.type) {
        case SyncEventType.syncStarted:
          state = SyncState.syncing;
          break;
        case SyncEventType.syncCompleted:
          state = SyncState.completed;
          break;
        case SyncEventType.syncError:
          state = SyncState.error;
          break;
      }
    });
  }

  Future<void> syncAll() async {
    state = SyncState.syncing;
    try {
      await _syncManager.syncAll();
      state = SyncState.completed;
    } catch (e) {
      state = SyncState.error;
    }
  }
}

enum SyncState { idle, syncing, completed, error }

class UserProfilesNotifier extends StateNotifier<AsyncValue<List<UserProfile>>> {
  final UniversalSyncManager _syncManager;

  UserProfilesNotifier(this._syncManager) : super(const AsyncValue.loading()) {
    _loadUserProfiles();
    _setupSyncListener();
  }

  Future<void> _loadUserProfiles() async {
    try {
      // Load from local database
      final profiles = await _getUserProfilesFromLocal();
      state = AsyncValue.data(profiles);
      
      // Trigger sync
      await _syncManager.syncEntity('user_profiles');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void _setupSyncListener() {
    _syncManager.syncEventStream
        .where((event) => event.entity == 'user_profiles')
        .listen((event) {
      if (event.type == SyncEventType.syncCompleted) {
        _loadUserProfiles(); // Reload data after sync
      }
    });
  }

  Future<List<UserProfile>> _getUserProfilesFromLocal() async {
    // Implement local data loading
    throw UnimplementedError();
  }
}
```

#### 4. UI Integration

```dart
// widgets/sync_aware_user_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SyncAwareUserList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfilesAsync = ref.watch(userProfilesProvider);
    final syncState = ref.watch(syncStateProvider);
    final syncEvents = ref.watch(syncEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Users'),
        actions: [
          // Sync status indicator
          syncEvents.when(
            data: (event) => _buildSyncStatusIcon(event),
            loading: () => CircularProgressIndicator(),
            error: (_, __) => Icon(Icons.error, color: Colors.red),
          ),
          
          // Manual sync button
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: syncState == SyncState.syncing 
                ? null 
                : () => ref.read(syncStateProvider.notifier).syncAll(),
          ),
        ],
      ),
      body: userProfilesAsync.when(
        data: (profiles) => ListView.builder(
          itemCount: profiles.length,
          itemBuilder: (context, index) {
            final profile = profiles[index];
            return ListTile(
              title: Text(profile.name),
              subtitle: Text(profile.email),
              trailing: profile.isDirty 
                  ? Icon(Icons.cloud_upload, color: Colors.orange)
                  : Icon(Icons.cloud_done, color: Colors.green),
              onTap: () => _editProfile(context, profile),
            );
          },
        ),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Error loading users: $error'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(userProfilesProvider),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createProfile(context),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildSyncStatusIcon(SyncEvent event) {
    switch (event.type) {
      case SyncEventType.syncStarted:
        return Icon(Icons.sync, color: Colors.blue);
      case SyncEventType.syncCompleted:
        return Icon(Icons.cloud_done, color: Colors.green);
      case SyncEventType.syncError:
        return Icon(Icons.cloud_off, color: Colors.red);
      default:
        return Icon(Icons.cloud, color: Colors.grey);
    }
  }

  void _editProfile(BuildContext context, UserProfile profile) {
    // Navigate to edit screen
  }

  void _createProfile(BuildContext context) {
    // Navigate to create screen
  }
}
```

---

## 🔧 Backend-Specific Setup

### Supabase Setup

#### 1. Project Configuration

```dart
// Initialize Supabase
await Supabase.initialize(
  url: 'https://your-project.supabase.co',
  anonKey: 'your-anon-key',
);

// Create adapter
final adapter = SupabaseSyncAdapter();
await adapter.connect(SyncBackendConfiguration(
  url: 'https://your-project.supabase.co',
  apiKey: 'your-anon-key',
));
```

#### 2. Authentication Integration

```dart
// Setup auth integration
final authIntegration = SupabaseAuthIntegration();
await syncManager.setAuthProvider(authIntegration);

// Handle auth events
authIntegration.authEventStream.listen((event) {
  switch (event.type) {
    case AuthEventType.signedIn:
      // User signed in - start auto sync
      syncManager.enableAutoSync();
      break;
    case AuthEventType.signedOut:
      // User signed out - stop sync and clear local data
      syncManager.disableAutoSync();
      break;
  }
});
```

### Firebase Setup

#### 1. Project Configuration

```dart
// Initialize Firebase
await Firebase.initializeApp();

// Create adapter
final adapter = FirebaseSyncAdapter();
await adapter.connect(SyncBackendConfiguration(
  projectId: 'your-project-id',
  apiKey: 'your-api-key',
));
```

#### 2. Firestore Rules

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Organization-based access control
    match /{collection}/{document} {
      allow read, write: if request.auth != null 
        && request.auth.token.organizationId == resource.data.organizationId;
    }
  }
}
```

---

## 🚀 Performance Optimization

### 1. Sync Strategy Configuration

```dart
// Configure sync for optimal performance
await syncManager.initialize(UniversalSyncConfig(
  projectId: 'your-project',
  syncMode: SyncMode.automatic,
  
  // Performance settings
  batchSize: 100,              // Sync in batches of 100
  syncInterval: Duration(minutes: 5),  // Auto-sync every 5 minutes
  maxRetries: 3,               // Retry failed operations 3 times
  retryDelay: Duration(seconds: 2),    // Wait 2 seconds between retries
  
  // Memory settings
  maxCacheSize: 1000,          // Cache up to 1000 records
  enableCompression: true,     // Compress network payloads
  
  // Network settings
  connectionTimeout: Duration(seconds: 30),
  requestTimeout: Duration(seconds: 60),
));
```

### 2. Database Optimization

```sql
-- Create indexes for better query performance
CREATE INDEX idx_table_organization_dirty ON your_table (organization_id, is_dirty);
CREATE INDEX idx_table_last_synced ON your_table (last_synced_at) WHERE is_dirty = true;
CREATE INDEX idx_table_updated_at ON your_table (updated_at) WHERE is_deleted = false;

-- Optimize for large datasets
CREATE INDEX idx_table_partial_sync ON your_table (organization_id, last_synced_at, is_dirty) 
WHERE is_deleted = false;
```

### 3. Memory Management

```dart
class MemoryOptimizedSyncManager {
  final UniversalSyncManager _syncManager;
  Timer? _memoryCleanupTimer;

  MemoryOptimizedSyncManager(this._syncManager) {
    _setupMemoryManagement();
  }

  void _setupMemoryManagement() {
    // Periodic memory cleanup
    _memoryCleanupTimer = Timer.periodic(Duration(minutes: 10), (_) {
      _syncManager.clearCache();
      _syncManager.compactDatabase();
    });

    // Monitor memory usage
    _syncManager.memoryUsageStream.listen((usage) {
      if (usage.currentUsage > 100 * 1024 * 1024) { // 100MB
        print('⚠️ High memory usage detected: ${usage.currentUsage ~/ 1024 ~/ 1024}MB');
        _syncManager.clearCache();
      }
    });
  }

  void dispose() {
    _memoryCleanupTimer?.cancel();
  }
}
```

---

## 🔍 Monitoring & Debugging

### 1. Comprehensive Logging

```dart
class SyncLogger {
  static void setupLogging(UniversalSyncManager syncManager) {
    // Event logging
    syncManager.syncEventStream.listen((event) {
      final timestamp = DateTime.now().toIso8601String();
      print('[$timestamp] SYNC_EVENT: ${event.type} - ${event.entity} - ${event.message}');
    });

    // Error logging
    syncManager.syncEventStream
        .where((event) => event.type == SyncEventType.syncError)
        .listen((event) {
      final timestamp = DateTime.now().toIso8601String();
      print('[$timestamp] SYNC_ERROR: ${event.entity} - ${event.error}');
      
      // Log to crash reporting service
      // FirebaseCrashlytics.instance.recordError(event.error, null);
    });

    // Performance logging
    syncManager.syncProgressStream.listen((progress) {
      if (progress.isCompleted) {
        final duration = progress.endTime!.difference(progress.startTime);
        print('SYNC_PERFORMANCE: ${progress.entity} completed in ${duration.inMilliseconds}ms');
      }
    });

    // Conflict logging
    syncManager.conflictStream.listen((conflict) {
      print('SYNC_CONFLICT: ${conflict.entity}/${conflict.recordId} - Fields: ${conflict.fieldConflicts.keys}');
    });
  }
}
```

### 2. Health Monitoring

```dart
class SyncHealthMonitor {
  final UniversalSyncManager _syncManager;
  final List<SyncHealthMetric> _metrics = [];

  SyncHealthMonitor(this._syncManager) {
    _setupMonitoring();
  }

  void _setupMonitoring() {
    Timer.periodic(Duration(minutes: 1), (_) => _collectMetrics());
  }

  void _collectMetrics() {
    final metric = SyncHealthMetric(
      timestamp: DateTime.now(),
      successRate: _calculateSuccessRate(),
      averageResponseTime: _calculateAverageResponseTime(),
      queueLength: _syncManager.getQueueLength(),
      memoryUsage: _syncManager.getCurrentMemoryUsage(),
    );

    _metrics.add(metric);

    // Keep only last 60 minutes of metrics
    _metrics.removeWhere((m) => 
        DateTime.now().difference(m.timestamp) > Duration(hours: 1));

    // Alert on issues
    if (metric.successRate < 0.95) {
      print('⚠️ Low sync success rate: ${(metric.successRate * 100).toStringAsFixed(1)}%');
    }

    if (metric.averageResponseTime > Duration(seconds: 10)) {
      print('⚠️ High response time: ${metric.averageResponseTime.inMilliseconds}ms');
    }
  }

  double _calculateSuccessRate() {
    // Implement success rate calculation based on recent sync attempts
    return 1.0;
  }

  Duration _calculateAverageResponseTime() {
    // Implement average response time calculation
    return Duration(milliseconds: 500);
  }

  SyncHealthReport generateReport() {
    return SyncHealthReport(
      metrics: List.from(_metrics),
      overallHealth: _assessOverallHealth(),
      recommendations: _generateRecommendations(),
    );
  }

  SyncHealthStatus _assessOverallHealth() {
    if (_metrics.isEmpty) return SyncHealthStatus.unknown;

    final recentMetrics = _metrics.where((m) => 
        DateTime.now().difference(m.timestamp) < Duration(minutes: 5));

    final avgSuccessRate = recentMetrics
        .map((m) => m.successRate)
        .reduce((a, b) => a + b) / recentMetrics.length;

    if (avgSuccessRate > 0.98) return SyncHealthStatus.excellent;
    if (avgSuccessRate > 0.95) return SyncHealthStatus.good;
    if (avgSuccessRate > 0.90) return SyncHealthStatus.fair;
    return SyncHealthStatus.poor;
  }

  List<String> _generateRecommendations() {
    final recommendations = <String>[];

    if (_calculateSuccessRate() < 0.95) {
      recommendations.add('Consider increasing retry count or delay');
    }

    if (_calculateAverageResponseTime() > Duration(seconds: 5)) {
      recommendations.add('Consider optimizing database queries or network configuration');
    }

    if (_syncManager.getQueueLength() > 100) {
      recommendations.add('Consider increasing batch size or sync frequency');
    }

    return recommendations;
  }
}

class SyncHealthMetric {
  final DateTime timestamp;
  final double successRate;
  final Duration averageResponseTime;
  final int queueLength;
  final int memoryUsage;

  SyncHealthMetric({
    required this.timestamp,
    required this.successRate,
    required this.averageResponseTime,
    required this.queueLength,
    required this.memoryUsage,
  });
}

enum SyncHealthStatus { excellent, good, fair, poor, unknown }

class SyncHealthReport {
  final List<SyncHealthMetric> metrics;
  final SyncHealthStatus overallHealth;
  final List<String> recommendations;

  SyncHealthReport({
    required this.metrics,
    required this.overallHealth,
    required this.recommendations,
  });
}
```

---

## 🧪 Testing Your Integration

### 1. Unit Testing

```dart
// test/sync_integration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';

void main() {
  group('Sync Integration Tests', () {
    late UniversalSyncManager syncManager;
    late MockSyncBackendAdapter mockAdapter;

    setUp(() async {
      mockAdapter = MockSyncBackendAdapter();
      syncManager = UniversalSyncManager();
      
      await syncManager.initialize(UniversalSyncConfig(
        projectId: 'test-project',
        syncMode: SyncMode.manual,
      ));
      
      await syncManager.setBackend(mockAdapter);
    });

    test('should sync local changes to remote', () async {
      // Arrange
      syncManager.registerEntity('users', SyncEntityConfig(
        tableName: 'users',
      ));

      // Create local data
      final user = UserProfile(
        id: 'test-1',
        organizationId: 'org-1',
        name: 'Test User',
        email: 'test@example.com',
        isActive: true,
        createdBy: 'user-1',
        updatedBy: 'user-1',
        isDirty: true,
      );

      // Act
      final result = await syncManager.syncEntity('users');

      // Assert
      expect(result.isSuccess, true);
      expect(result.affectedItems, 1);
    });

    test('should handle conflicts correctly', () async {
      // Test conflict resolution scenarios
    });

    test('should handle network errors gracefully', () async {
      // Test error handling
    });
  });
}
```

### 2. Integration Testing

```dart
// integration_test/sync_e2e_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Sync Tests', () {
    testWidgets('complete sync workflow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test sync button tap
      await tester.tap(find.byIcon(Icons.sync));
      await tester.pumpAndSettle();

      // Verify sync completion
      expect(find.text('Sync completed'), findsOneWidget);
    });

    testWidgets('offline to online sync', (WidgetTester tester) async {
      // Test offline mode, make changes, go online, verify sync
    });
  });
}
```

---

## 🚨 Troubleshooting

### Common Issues

#### 1. Sync Not Working

**Problem**: Data isn't syncing between local and remote.

**Solutions**:
```dart
// Check sync manager initialization
if (!syncManager.isInitialized) {
  await syncManager.initialize(config);
}

// Verify entity registration
if (!syncManager.isEntityRegistered('your_table')) {
  syncManager.registerEntity('your_table', entityConfig);
}

// Check authentication
if (!syncManager.isAuthenticated) {
  await syncManager.authenticate(credentials);
}

// Manual sync to test
final result = await syncManager.syncEntity('your_table');
print('Sync result: ${result.isSuccess ? 'SUCCESS' : 'FAILED'}');
```

#### 2. RLS Policy Violations

**Problem**: Getting permission denied errors.

**Solutions**:
```sql
-- Check your RLS policies
SELECT * FROM pg_policies WHERE tablename = 'your_table';

-- Ensure user has organization_id in JWT
SELECT auth.jwt() ->> 'organization_id';

-- Test policy manually
SELECT * FROM your_table WHERE organization_id = (auth.jwt() ->> 'organization_id')::UUID;
```

#### 3. Performance Issues

**Problem**: Sync is slow or uses too much memory.

**Solutions**:
```dart
// Optimize batch size
await syncManager.updateConfig(UniversalSyncConfig(
  batchSize: 50, // Reduce batch size
  enableCompression: true,
  maxCacheSize: 500,
));

// Enable selective sync
syncManager.registerEntity('your_table', SyncEntityConfig(
  syncDirection: SyncDirection.uploadOnly, // If you only need to upload
  enableIncrementalSync: true,
));

// Monitor performance
syncManager.memoryUsageStream.listen((usage) {
  print('Memory usage: ${usage.currentUsage}');
});
```

#### 4. Conflict Resolution Issues

**Problem**: Conflicts aren't resolving as expected.

**Solutions**:
```dart
// Implement custom conflict resolver
class DebugConflictResolver implements ConflictResolver {
  @override
  SyncConflictResolution resolveConflict(SyncConflict conflict) {
    print('Conflict detected:');
    print('  Entity: ${conflict.entity}');
    print('  Record ID: ${conflict.recordId}');
    print('  Field conflicts: ${conflict.fieldConflicts}');
    
    // Your resolution logic here
    return SyncConflictResolution.useTimestamp();
  }
}

syncManager.setConflictResolver('your_table', DebugConflictResolver());

// Listen to conflict events
syncManager.conflictStream.listen((conflict) {
  print('Conflict event: $conflict');
});
```

### Debug Mode

```dart
// Enable debug mode for verbose logging
await syncManager.initialize(UniversalSyncConfig(
  projectId: 'your-project',
  debugMode: true,
  logLevel: LogLevel.verbose,
));

// Monitor all events
syncManager.syncEventStream.listen((event) {
  print('DEBUG: ${event.type} - ${event.message}');
});
```

---

## 📚 Best Practices

### 1. Security

- ✅ Always enable RLS on your database tables
- ✅ Use proper authentication and organization isolation
- ✅ Validate data on both client and server sides
- ✅ Keep sensitive data encrypted in local storage
- ✅ Regularly rotate API keys and tokens

### 2. Performance

- ✅ Use appropriate batch sizes (50-100 records)
- ✅ Implement database indexes for sync fields
- ✅ Enable compression for large payloads
- ✅ Use incremental sync for large datasets
- ✅ Monitor memory usage and clean up regularly

### 3. User Experience

- ✅ Provide visual feedback for sync operations
- ✅ Handle offline mode gracefully
- ✅ Show conflict resolution options to users
- ✅ Implement retry mechanisms for failed operations
- ✅ Cache frequently accessed data locally

### 4. Maintenance

- ✅ Implement comprehensive logging
- ✅ Monitor sync health and performance
- ✅ Plan for schema migrations
- ✅ Regular cleanup of old data
- ✅ Keep documentation updated

---

## 🎯 Next Steps

### After Basic Integration

1. **Test Thoroughly**: Run comprehensive tests with your data
2. **Monitor Performance**: Set up performance monitoring
3. **Plan for Scale**: Consider how your sync needs will grow
4. **Add Custom Features**: Implement business-specific sync logic
5. **Optimize for Production**: Fine-tune performance settings

### Advanced Features to Explore

- **Multi-Backend Support**: Use different backends for different data types
- **Custom Adapters**: Create adapters for proprietary backend systems
- **Advanced Conflict Resolution**: Implement sophisticated merge strategies
- **Real-Time Collaboration**: Enable live collaborative editing
- **Data Compression**: Optimize network usage with custom compression

---

## 📞 Support

### Resources

- **📖 API Documentation**: Complete API reference with examples
- **🎥 Video Tutorials**: Step-by-step integration guides
- **💬 Community Forum**: Get help from other developers
- **🐛 Issue Tracker**: Report bugs and request features

### Getting Help

1. **Check the Documentation**: Most common issues are covered
2. **Search the Forum**: Someone might have asked the same question
3. **Create a Minimal Example**: Isolate the issue in a simple project
4. **Provide Context**: Include error messages, logs, and configuration

---

**🚀 Happy Syncing!** Your Flutter app is now ready for the future with Universal Sync Manager!