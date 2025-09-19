# CRUD Operations Guide

Complete guide for implementing Create, Read, Update, Delete operations with Universal Sync Manager and Supabase.

## 📋 Overview

USM provides a unified API for CRUD operations that works seamlessly with Supabase, handling authentication, conflict resolution, and synchronization automatically.

## 🏗️ Data Model Setup

### 1. Syncable Model Implementation

```dart
import 'package:universal_sync_manager/universal_sync_manager.dart';

class UserProfile with SyncableModel {
  final String id;
  final String organizationId;
  final String name;
  final String email;
  final bool isActive;

  // Audit fields
  final String createdBy;
  final String updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  // Sync fields
  final bool isDirty;
  final DateTime? lastSyncedAt;
  final int syncVersion;
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
    required this.isDirty,
    this.lastSyncedAt,
    required this.syncVersion,
    required this.isDeleted,
  });

  factory UserProfile.create({
    required String organizationId,
    required String name,
    required String email,
    required String createdBy,
  }) {
    final id = const Uuid().v4();
    return UserProfile(
      id: id,
      organizationId: organizationId,
      name: name,
      email: email,
      isActive: true,
      createdBy: createdBy,
      updatedBy: createdBy,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDirty: true,
      syncVersion: 0,
      isDeleted: false,
    );
  }

  @override
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'name': name,
      'email': email,
      'is_active': isActive,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'is_dirty': isDirty,
      'last_synced_at': lastSyncedAt?.toIso8601String(),
      'sync_version': syncVersion,
      'is_deleted': isDeleted,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      organizationId: json['organization_id'],
      name: json['name'],
      email: json['email'],
      isActive: json['is_active'] ?? true,
      createdBy: json['created_by'],
      updatedBy: json['updated_by'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
      isDirty: json['is_dirty'] ?? false,
      lastSyncedAt: json['last_synced_at'] != null ? DateTime.parse(json['last_synced_at']) : null,
      syncVersion: json['sync_version'] ?? 0,
      isDeleted: json['is_deleted'] ?? false,
    );
  }
}
```

### 2. Repository Pattern Implementation

```dart
class UserProfileRepository {
  final UniversalSyncManager _syncManager;
  final String _tableName = 'user_profiles';

  UserProfileRepository(this._syncManager);

  // CREATE
  Future<UserProfile?> create(UserProfile profile) async {
    try {
      final data = profile.toJson();
      final result = await _syncManager.create(_tableName, data);

      if (result.isSuccess && result.data != null) {
        return UserProfile.fromJson(result.data!);
      } else {
        print('Create failed: ${result.error?.message}');
        return null;
      }
    } catch (e) {
      print('Create error: $e');
      return null;
    }
  }

  // READ by ID
  Future<UserProfile?> getById(String id) async {
    try {
      final result = await _syncManager.read(_tableName, id);

      if (result.isSuccess && result.data != null) {
        return UserProfile.fromJson(result.data!);
      } else {
        print('Read failed: ${result.error?.message}');
        return null;
      }
    } catch (e) {
      print('Read error: $e');
      return null;
    }
  }

  // READ all (with optional filters)
  Future<List<UserProfile>> getAll({
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
  }) async {
    try {
      final query = SyncQuery(
        filters: filters,
        limit: limit,
        offset: offset,
      );

      final result = await _syncManager.query(_tableName, query);

      if (result.isSuccess && result.data != null) {
        return result.data!
            .map((json) => UserProfile.fromJson(json))
            .where((profile) => !profile.isDeleted) // Exclude soft-deleted
            .toList();
      } else {
        print('Query failed: ${result.error?.message}');
        return [];
      }
    } catch (e) {
      print('Query error: $e');
      return [];
    }
  }

  // UPDATE
  Future<UserProfile?> update(UserProfile profile) async {
    try {
      final updatedProfile = profile.copyWith(
        updatedAt: DateTime.now(),
        isDirty: true,
        syncVersion: profile.syncVersion + 1,
      );

      final data = updatedProfile.toJson();
      final result = await _syncManager.update(_tableName, profile.id, data);

      if (result.isSuccess && result.data != null) {
        return UserProfile.fromJson(result.data!);
      } else {
        print('Update failed: ${result.error?.message}');
        return null;
      }
    } catch (e) {
      print('Update error: $e');
      return null;
    }
  }

  // DELETE (soft delete)
  Future<bool> delete(String id) async {
    try {
      // First get the current profile
      final profile = await getById(id);
      if (profile == null) {
        print('Profile not found for deletion: $id');
        return false;
      }

      // Soft delete by updating
      final deletedProfile = profile.copyWith(
        isDeleted: true,
        deletedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDirty: true,
        syncVersion: profile.syncVersion + 1,
      );

      final data = deletedProfile.toJson();
      final result = await _syncManager.update(_tableName, id, data);

      if (result.isSuccess) {
        print('Profile soft-deleted: $id');
        return true;
      } else {
        print('Delete failed: ${result.error?.message}');
        return false;
      }
    } catch (e) {
      print('Delete error: $e');
      return false;
    }
  }

  // HARD DELETE (use with caution)
  Future<bool> hardDelete(String id) async {
    try {
      final result = await _syncManager.delete(_tableName, id);

      if (result.isSuccess) {
        print('Profile hard-deleted: $id');
        return true;
      } else {
        print('Hard delete failed: ${result.error?.message}');
        return false;
      }
    } catch (e) {
      print('Hard delete error: $e');
      return false;
    }
  }
}
```

## 🔍 Query Operations

### 1. Basic Queries

```dart
class UserProfileQueries {
  final UserProfileRepository _repository;

  UserProfileQueries(this._repository);

  // Get active users only
  Future<List<UserProfile>> getActiveUsers() async {
    return await _repository.getAll(
      filters: {'is_active': true},
    );
  }

  // Get users by organization
  Future<List<UserProfile>> getUsersByOrganization(String organizationId) async {
    return await _repository.getAll(
      filters: {'organization_id': organizationId},
    );
  }

  // Search users by name
  Future<List<UserProfile>> searchUsers(String searchTerm) async {
    // Note: This is a basic implementation
    // For advanced search, consider using Supabase's full-text search
    final allUsers = await _repository.getAll();

    return allUsers.where((user) =>
      user.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
      user.email.toLowerCase().contains(searchTerm.toLowerCase())
    ).toList();
  }

  // Get users with pagination
  Future<List<UserProfile>> getUsersPaginated({
    required int page,
    required int pageSize,
  }) async {
    return await _repository.getAll(
      limit: pageSize,
      offset: (page - 1) * pageSize,
    );
  }

  // Get recently updated users
  Future<List<UserProfile>> getRecentlyUpdated({
    Duration within = const Duration(days: 7),
  }) async {
    final cutoffDate = DateTime.now().subtract(within);
    final allUsers = await _repository.getAll();

    return allUsers.where((user) =>
      user.updatedAt != null && user.updatedAt!.isAfter(cutoffDate)
    ).toList();
  }
}
```

### 2. Advanced Query Patterns

```dart
class AdvancedUserQueries {
  final UniversalSyncManager _syncManager;

  AdvancedUserQueries(this._syncManager);

  // Complex multi-field queries
  Future<List<UserProfile>> getUsersWithComplexFilter({
    String? organizationId,
    bool? isActive,
    String? nameContains,
    DateTime? updatedAfter,
  }) async {
    final filters = <String, dynamic>{};

    if (organizationId != null) {
      filters['organization_id'] = organizationId;
    }

    if (isActive != null) {
      filters['is_active'] = isActive;
    }

    // Note: For complex text search, you might want to use
    // Supabase's built-in search capabilities
    final users = await _syncManager.query(
      'user_profiles',
      SyncQuery(filters: filters),
    );

    if (!users.isSuccess || users.data == null) {
      return [];
    }

    var filteredUsers = users.data!
        .map((json) => UserProfile.fromJson(json))
        .toList();

    // Client-side filtering for complex conditions
    if (nameContains != null && nameContains.isNotEmpty) {
      filteredUsers = filteredUsers.where((user) =>
        user.name.toLowerCase().contains(nameContains.toLowerCase())
      ).toList();
    }

    if (updatedAfter != null) {
      filteredUsers = filteredUsers.where((user) =>
        user.updatedAt != null && user.updatedAt!.isAfter(updatedAfter)
      ).toList();
    }

    return filteredUsers;
  }

  // Batch operations
  Future<List<UserProfile>> getMultipleUsers(List<String> userIds) async {
    if (userIds.isEmpty) return [];

    // For small lists, we can query individually
    // For larger lists, consider implementing batch read in your adapter
    final futures = userIds.map((id) =>
      _syncManager.read('user_profiles', id)
    );

    final results = await Future.wait(futures);

    return results
        .where((result) => result.isSuccess && result.data != null)
        .map((result) => UserProfile.fromJson(result.data!))
        .toList();
  }
}
```

## 🧪 CRUD Testing Suite

### 1. Complete CRUD Test Implementation

```dart
class CrudTestSuite {
  final UserProfileRepository _repository;
  final UserProfileQueries _queries;

  CrudTestSuite(this._repository, this._queries);

  Future<void> runAllTests() async {
    print('🧪 Running CRUD Tests...');

    await testCreate();
    await testRead();
    await testQuery();
    await testUpdate();
    await testDelete();
    await testComplexQueries();

    print('✅ CRUD Tests Complete');
  }

  Future<void> testCreate() async {
    print('📝 Testing CREATE operations...');

    final testProfile = UserProfile.create(
      organizationId: 'org-test-123',
      name: 'Test User ${DateTime.now().millisecondsSinceEpoch}',
      email: 'test${DateTime.now().millisecondsSinceEpoch}@example.com',
      createdBy: 'test-user',
    );

    final created = await _repository.create(testProfile);
    if (created != null) {
      print('✅ Create successful: ${created.name}');
      _testProfileId = created.id; // Store for other tests
    } else {
      print('❌ Create failed');
    }
  }

  String? _testProfileId;

  Future<void> testRead() async {
    print('📖 Testing READ operations...');

    if (_testProfileId == null) {
      print('❌ No test profile ID available');
      return;
    }

    final profile = await _repository.getById(_testProfileId!);
    if (profile != null) {
      print('✅ Read successful: ${profile.name}');
    } else {
      print('❌ Read failed');
    }
  }

  Future<void> testQuery() async {
    print('🔍 Testing QUERY operations...');

    final allProfiles = await _repository.getAll();
    print('✅ Query all profiles: ${allProfiles.length} found');

    final activeProfiles = await _queries.getActiveUsers();
    print('✅ Query active profiles: ${activeProfiles.length} found');
  }

  Future<void> testUpdate() async {
    print('✏️ Testing UPDATE operations...');

    if (_testProfileId == null) {
      print('❌ No test profile ID available');
      return;
    }

    final profile = await _repository.getById(_testProfileId!);
    if (profile == null) {
      print('❌ Profile not found for update');
      return;
    }

    final updatedProfile = profile.copyWith(
      name: '${profile.name} (Updated)',
      updatedBy: 'test-user-updated',
    );

    final updated = await _repository.update(updatedProfile);
    if (updated != null) {
      print('✅ Update successful: ${updated.name}');
    } else {
      print('❌ Update failed');
    }
  }

  Future<void> testDelete() async {
    print('🗑️ Testing DELETE operations...');

    if (_testProfileId == null) {
      print('❌ No test profile ID available');
      return;
    }

    final deleted = await _repository.delete(_testProfileId!);
    if (deleted) {
      print('✅ Soft delete successful');

      // Verify it's soft deleted
      final profile = await _repository.getById(_testProfileId!);
      if (profile != null && profile.isDeleted) {
        print('✅ Soft delete verified');
      } else {
        print('❌ Soft delete verification failed');
      }
    } else {
      print('❌ Delete failed');
    }
  }

  Future<void> testComplexQueries() async {
    print('🔍 Testing COMPLEX QUERY operations...');

    final recentUsers = await _queries.getRecentlyUpdated();
    print('✅ Recent users query: ${recentUsers.length} found');

    final paginatedUsers = await _queries.getUsersPaginated(page: 1, pageSize: 10);
    print('✅ Paginated users query: ${paginatedUsers.length} found');
  }
}
```

### 2. Integration Test

```dart
void main() {
  late UserProfileRepository repository;
  late UserProfileQueries queries;
  late CrudTestSuite testSuite;

  setUp(() async {
    final syncManager = await initializeSyncManager();
    repository = UserProfileRepository(syncManager);
    queries = UserProfileQueries(repository);
    testSuite = CrudTestSuite(repository, queries);
  });

  test('Complete CRUD operations', () async {
    await testSuite.runAllTests();
  });
}
```

## 🔄 Batch Operations

### 1. Bulk Create

```dart
class BatchOperations {
  final UniversalSyncManager _syncManager;

  BatchOperations(this._syncManager);

  Future<List<UserProfile>> createMultiple(List<UserProfile> profiles) async {
    final createdProfiles = <UserProfile>[];

    for (final profile in profiles) {
      final created = await _syncManager.create('user_profiles', profile.toJson());
      if (created.isSuccess && created.data != null) {
        createdProfiles.add(UserProfile.fromJson(created.data!));
      }
    }

    return createdProfiles;
  }

  Future<List<UserProfile>> updateMultiple(List<UserProfile> profiles) async {
    final updatedProfiles = <UserProfile>[];

    for (final profile in profiles) {
      final updated = await _syncManager.update('user_profiles', profile.id, profile.toJson());
      if (updated.isSuccess && updated.data != null) {
        updatedProfiles.add(UserProfile.fromJson(updated.data!));
      }
    }

    return updatedProfiles;
  }
}
```

## 📊 Performance Considerations

### 1. Query Optimization

```dart
class OptimizedQueries {
  final UniversalSyncManager _syncManager;

  // Use specific filters to reduce data transfer
  Future<List<UserProfile>> getActiveUsersInOrganization(String organizationId) async {
    return await _syncManager.query(
      'user_profiles',
      SyncQuery(
        filters: {
          'organization_id': organizationId,
          'is_active': true,
          'is_deleted': false,
        },
        // Limit results for better performance
        limit: 100,
      ),
    ).then((result) =>
      result.isSuccess && result.data != null
        ? result.data!.map((json) => UserProfile.fromJson(json)).toList()
        : []
    );
  }

  // Cache frequently accessed data
  UserProfile? _cachedCurrentUser;
  DateTime? _cacheTimestamp;

  Future<UserProfile?> getCurrentUser(String userId) async {
    // Return cached data if recent
    if (_cachedCurrentUser != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < Duration(minutes: 5)) {
      return _cachedCurrentUser;
    }

    final profile = await _syncManager.read('user_profiles', userId);
    if (profile.isSuccess && profile.data != null) {
      _cachedCurrentUser = UserProfile.fromJson(profile.data!);
      _cacheTimestamp = DateTime.now();
      return _cachedCurrentUser;
    }

    return null;
  }
}
```

## 🚨 Error Handling

### 1. Comprehensive Error Handling

```dart
class CrudErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is SyncError) {
      switch (error.type) {
        case SyncErrorType.network:
          return 'Network connection error. Please check your internet connection.';
        case SyncErrorType.authentication:
          return 'Authentication failed. Please sign in again.';
        case SyncErrorType.authorization:
          return 'You do not have permission to perform this action.';
        case SyncErrorType.notFound:
          return 'The requested item was not found.';
        case SyncErrorType.conflict:
          return 'This item was modified by someone else. Please refresh and try again.';
        case SyncErrorType.validation:
          return 'Invalid data provided. Please check your input.';
        default:
          return 'An unexpected error occurred: ${error.message}';
      }
    }

    return 'An unexpected error occurred';
  }

  static void handleCrudError(String operation, dynamic error, StackTrace stackTrace) {
    final message = getErrorMessage(error);
    print('CRUD Error in $operation: $message');
    print('Stack trace: $stackTrace');

    // Log to analytics or error reporting service
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
}
```

## 📋 Next Steps

1. **[Sync Features](../sync_features.md)** - Understand automatic synchronization
2. **[Conflict Resolution](../sync_features.md#conflict-resolution)** - Handle conflicting changes
3. **[Advanced Features](../advanced_features.md)** - Performance optimization and state management

## 🆘 Troubleshooting

**Create Failures:**
- Check authentication status
- Verify organization_id in user metadata
- Ensure required fields are provided

**Read Failures:**
- Confirm record exists and isn't soft-deleted
- Check RLS policies allow access
- Verify correct ID format

**Update Failures:**
- Ensure you have permission to update the record
- Check for concurrent modifications
- Verify data validation rules

**Delete Failures:**
- Confirm you have delete permissions
- Check if record exists
- Verify soft delete vs hard delete requirements