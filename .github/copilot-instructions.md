# Universal Sync Manager (USM) Development Instructions

## Project Overview

Universal Sync Manager (USM) is a backend-agnostic, platform-independent synchronization framework for Flutter applications. The system enables offline-first operation with seamless backend synchronization using a pluggable adapter architecture that supports multiple backend services like Firebase, Supabase, PocketBase, and custom APIs.

## Core Architecture Patterns

### Adapter Pattern

All backend implementations use the adapter pattern through the `ISyncBackendAdapter` interface:

```dart
abstract class ISyncBackendAdapter {
  Future<bool> connect(SyncBackendConfiguration config);
  Future<void> disconnect();
  
  Future<SyncResult> create(String collection, Map<String, dynamic> data);
  Future<SyncResult> read(String collection, String id);
  Future<SyncResult> update(String collection, String id, Map<String, dynamic> data);
  Future<SyncResult> delete(String collection, String id);
  Future<List<SyncResult>> query(String collection, SyncQuery query);
  
  Stream<SyncEvent> subscribe(String collection, SyncSubscriptionOptions options);
  Future<void> unsubscribe(String subscriptionId);
}
```

### SyncableModel Pattern

All syncable entities implement the `SyncableModel` mixin:

```dart
mixin SyncableModel {
  String get id;
  String get organizationId;
  bool get isDirty;
  DateTime? get lastSyncedAt;
  int get syncVersion;
  DateTime? get updatedAt;
  bool get isDeleted;
  
  // Implement copyWith with model-specific return type
}
```

### Event-Driven Architecture

The system uses streams for real-time updates and progress tracking:

```dart
// In UniversalSyncManager
Stream<SyncProgress> get syncProgressStream;
Stream<SyncEvent> get syncEventStream;
Stream<ConflictEvent> get conflictStream;
```

## Naming Conventions

### Field Naming Standards

**ALWAYS use camelCase** for all database fields across all platforms:

✅ CORRECT: `organizationId`, `createdBy`, `updatedAt`, `isDirty`
❌ INCORRECT: `organization_id`, `created_by`, `updated_at`

This consistency eliminates the need for field mapping between backends.

### Table/Collection Naming Standards

**ALWAYS use snake_case** for table and collection names across all platforms:

✅ CORRECT: `audit_items`, `organization_profiles`, `user_sessions`
❌ INCORRECT: `AuditItems`, `organizationProfiles`

This consistency ensures compatibility across different backend systems.

### Code files Naming Standards

**ALWAYS use snake_case** for code file names across all platforms:
**ALWAYS prepend with usm_** for code file names across all platforms:

✅ CORRECT: `usm_user_profile.dart`, `usm_sync_manager.dart`
❌ INCORRECT: `UserProfile.dart`, `SyncManager.dart`

## Required Audit & Sync Fields

Every syncable entity MUST include these fields:

```dart
// Audit fields
String createdBy;
String updatedBy;
DateTime? createdAt;
DateTime? updatedAt;
DateTime? deletedAt;

// Sync fields
bool isDirty;
DateTime? lastSyncedAt;
int syncVersion;
bool isDeleted;
```

## Implementation Patterns

### Backend Adapter Implementation

```dart
class PocketBaseSyncAdapter implements ISyncBackendAdapter {
  final String baseUrl;
  final pb.PocketBase _pocketBase;
  
  PocketBaseSyncAdapter({required this.baseUrl})
      : _pocketBase = pb.PocketBase(baseUrl);
  
  @override
  Future<bool> connect(SyncBackendConfiguration config) async {
    // Implement PocketBase-specific connection logic
  }
  
  @override
  Future<SyncResult> create(String collection, Map<String, dynamic> data) async {
    try {
      final record = await _pocketBase.collection(collection).create(body: data);
      return SyncResult.success(
        data: record.toJson(),
        action: SyncAction.create,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return SyncResult.error(
        error: SyncError(message: e.toString()),
        action: SyncAction.create,
        timestamp: DateTime.now(),
      );
    }
  }
  
  // Implement other methods...
}
```

### Entity Registration

```dart
// Register a syncable entity
syncManager.registerEntity(
  'organization_profiles',
  SyncEntityConfig(
    tableName: 'organization_profiles',
    requiresAuthentication: true,
    conflictStrategy: ConflictResolutionStrategy.serverWins,
  ),
);
```

### Sync Operation

```dart
// Sync a specific entity
final result = await syncManager.syncEntity('organization_profiles');
if (result.isSuccess) {
  print('Sync completed successfully: ${result.affectedItems} items');
} else {
  print('Sync failed: ${result.error?.message}');
}

// Sync all entities
final allResults = await syncManager.syncAll();
```

### Conflict Resolution

```dart
// Define a custom conflict resolution strategy
class CustomConflictResolver implements ConflictResolver {
  @override
  SyncConflictResolution resolveConflict(SyncConflict conflict) {
    // Implement custom resolution logic
    if (conflict.fieldConflicts.containsKey('isActive')) {
      // Always take the server value for isActive field
      return SyncConflictResolution.useServer(['isActive']);
    }
    
    // Default to client data for other fields
    return SyncConflictResolution.useClient();
  }
}

// Register the custom resolver
syncManager.setConflictResolver(
  'organization_profiles',
  CustomConflictResolver(),
);
```

## Testing Patterns

### Mock Backend Adapter

```dart
class MockSyncBackendAdapter implements ISyncBackendAdapter {
  final Map<String, Map<String, Map<String, dynamic>>> _collections = {};
  
  @override
  Future<bool> connect(SyncBackendConfiguration config) async => true;
  
  @override
  Future<SyncResult> create(String collection, Map<String, dynamic> data) async {
    final id = data['id'] ?? 'mock-${DateTime.now().millisecondsSinceEpoch}';
    data['id'] = id;
    
    if (!_collections.containsKey(collection)) {
      _collections[collection] = {};
    }
    
    _collections[collection]![id] = Map.from(data);
    
    return SyncResult.success(
      data: Map.from(data),
      action: SyncAction.create,
      timestamp: DateTime.now(),
    );
  }
  
  // Implement other methods...
}
```

### Sync Testing

```dart
void main() {
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
  
  test('should sync created items', () async {
    // Arrange
    final testRepo = TestRepository();
    syncManager.registerEntity('test_items', SyncEntityConfig(
      tableName: 'test_items',
    ));
    
    final item = TestModel(
      id: 'test-1',
      name: 'Test Item',
      isDirty: true,
      syncVersion: 0,
    );
    
    await testRepo.create(item);
    
    // Act
    final result = await syncManager.syncEntity('test_items');
    
    // Assert
    expect(result.isSuccess, true);
    expect(result.affectedItems, 1);
    
    final syncedItem = await testRepo.getById('test-1');
    expect(syncedItem.isDirty, false);
    expect(syncedItem.syncVersion, 1);
    expect(syncedItem.lastSyncedAt, isNotNull);
  });
  
  // More tests...
}
```

## Database Structure

### SQLite Table Schema

```sql
CREATE TABLE IF NOT EXISTS organization_profiles (
  id TEXT PRIMARY KEY,
  organizationId TEXT NOT NULL,
  
  -- Feature-specific fields
  name TEXT NOT NULL,
  description TEXT,
  isActive INTEGER NOT NULL DEFAULT 1,
  
  -- Audit fields
  createdBy TEXT NOT NULL,
  updatedBy TEXT NOT NULL, 
  createdAt TEXT,
  updatedAt TEXT,
  deletedAt TEXT,
  
  -- Sync fields
  isDirty INTEGER NOT NULL DEFAULT 1,
  lastSyncedAt TEXT,
  syncVersion INTEGER NOT NULL DEFAULT 0,
  isDeleted INTEGER NOT NULL DEFAULT 0
);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_organization_profiles_organization_id 
  ON organization_profiles (organizationId);
CREATE INDEX IF NOT EXISTS idx_organization_profiles_is_dirty 
  ON organization_profiles (isDirty);
CREATE INDEX IF NOT EXISTS idx_organization_profiles_is_deleted 
  ON organization_profiles (isDeleted);
```

## Performance Considerations

1. **Batch Operations**: Use batch operations for bulk changes
2. **Delta Sync**: Only sync changed fields when possible
3. **Compression**: Compress large payloads
4. **Incremental Sync**: Use timestamps to sync only recent changes
5. **Intelligent Scheduling**: Adjust sync frequency based on usage patterns

## Error Handling

1. **Retry Mechanism**: Implement exponential backoff for failed operations
2. **Error Classification**: Distinguish between temporary and permanent errors
3. **Partial Success**: Handle partial success in batch operations
4. **Sync Recovery**: Provide mechanisms to recover from sync failures
5. **Conflict Resolution**: Handle conflicts gracefully with configurable strategies

## Project Structure

```
lib/
├── src/
│   ├── adapters/
│   │   ├── firebase_sync_adapter.dart
│   │   ├── pocketbase_sync_adapter.dart
│   │   └── supabase_sync_adapter.dart
│   ├── config/
│   │   ├── sync_config.dart
│   │   └── entity_config.dart
│   ├── core/
│   │   ├── sync_manager.dart
│   │   ├── sync_operation_service.dart
│   │   └── sync_result.dart
│   ├── models/
│   │   ├── syncable_model.dart
│   │   ├── sync_event.dart
│   │   └── sync_progress.dart
│   ├── platform/
│   │   ├── platform_service.dart
│   │   ├── mobile_platform_service.dart
│   │   └── desktop_platform_service.dart
│   ├── utils/
│   │   ├── conflict_resolver.dart
│   │   ├── sync_scheduler.dart
│   │   └── sync_analytics.dart
│   └── interfaces/
│       ├── sync_backend_adapter.dart
│       ├── sync_platform_service.dart
│       └── conflict_resolver.dart
├── universal_sync_manager.dart  # Main export file
└── adapters.dart  # Adapter exports
```

## Expected Outcomes

After implementing the Universal Sync Manager architecture, the system will deliver:

✅ **Support Multiple Backends** - Seamlessly switch between PocketBase, Firebase, Supabase, or custom APIs

✅ **Platform Independence** - Run on Windows, macOS, iOS, Android, Web without platform-specific code

✅ **Self-Contained API** - Expose clean public methods usable from anywhere without internal modifications

✅ **Extensible Architecture** - Add new backends or sync strategies without touching core code

✅ **Enhanced Performance** - Optimized sync with delta updates, compression, and intelligent scheduling

✅ **Robust Conflict Resolution** - Pluggable strategies with field-level conflict detection

✅ **Comprehensive Monitoring** - Built-in analytics, diagnostics, and recovery tools

✅ **Simplified Architecture** - No sync categories, universal audit fields, consistent naming

✅ **AI-Development Friendly** - Predictable patterns for easy code generation and maintenance

✅ **Solo Developer Optimized** - Reduced complexity, faster development, fewer edge cases

This architecture follows the principles of clean architecture with clear separation of concerns, allowing for maximum flexibility and extensibility.
