// lib/src/services/usm_sync_state_inspector.dart

import 'dart:async';

/// Sync entity state information
class SyncEntityState {
  final String entityType;
  final String collection;
  final int totalItems;
  final int dirtyItems;
  final int syncedItems;
  final int errorItems;
  final int deletedItems;
  final DateTime? lastSyncTime;
  final DateTime? lastModified;
  final int syncVersion;
  final List<String> pendingOperations;
  final Map<String, dynamic> metadata;

  const SyncEntityState({
    required this.entityType,
    required this.collection,
    required this.totalItems,
    required this.dirtyItems,
    required this.syncedItems,
    required this.errorItems,
    required this.deletedItems,
    this.lastSyncTime,
    this.lastModified,
    required this.syncVersion,
    required this.pendingOperations,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'entityType': entityType,
        'collection': collection,
        'totalItems': totalItems,
        'dirtyItems': dirtyItems,
        'syncedItems': syncedItems,
        'errorItems': errorItems,
        'deletedItems': deletedItems,
        'lastSyncTime': lastSyncTime?.toIso8601String(),
        'lastModified': lastModified?.toIso8601String(),
        'syncVersion': syncVersion,
        'pendingOperations': pendingOperations,
        'metadata': metadata,
      };

  /// Calculates sync health percentage
  double get syncHealthPercentage {
    if (totalItems == 0) return 100.0;
    return ((syncedItems / totalItems) * 100).clamp(0.0, 100.0);
  }

  /// Checks if entity is healthy
  bool get isHealthy => errorItems == 0 && dirtyItems == 0;

  /// Gets sync status description
  String get statusDescription {
    if (totalItems == 0) return 'No items';
    if (errorItems > 0) return 'Sync errors detected';
    if (dirtyItems > 0) return 'Pending sync';
    if (syncedItems == totalItems) return 'Fully synced';
    return 'Partially synced';
  }
}

/// Individual item sync state
class SyncItemState {
  final String id;
  final String entityType;
  final String collection;
  final bool isDirty;
  final bool isDeleted;
  final bool hasErrors;
  final DateTime? lastSyncedAt;
  final DateTime? updatedAt;
  final int syncVersion;
  final List<String> syncErrors;
  final Map<String, dynamic> localData;
  final Map<String, dynamic>? remoteData;
  final List<SyncConflictInfo> conflicts;

  const SyncItemState({
    required this.id,
    required this.entityType,
    required this.collection,
    required this.isDirty,
    required this.isDeleted,
    required this.hasErrors,
    this.lastSyncedAt,
    this.updatedAt,
    required this.syncVersion,
    required this.syncErrors,
    required this.localData,
    this.remoteData,
    required this.conflicts,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'entityType': entityType,
        'collection': collection,
        'isDirty': isDirty,
        'isDeleted': isDeleted,
        'hasErrors': hasErrors,
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'syncVersion': syncVersion,
        'syncErrors': syncErrors,
        'localData': localData,
        'remoteData': remoteData,
        'conflicts': conflicts.map((c) => c.toJson()).toList(),
      };

  /// Gets sync status
  String get syncStatus {
    if (hasErrors) return 'Error';
    if (conflicts.isNotEmpty) return 'Conflict';
    if (isDirty) return 'Pending';
    if (isDeleted) return 'Deleted';
    return 'Synced';
  }
}

/// Sync conflict information
class SyncConflictInfo {
  final String field;
  final dynamic localValue;
  final dynamic remoteValue;
  final DateTime detectedAt;
  final String? resolutionStrategy;
  final bool isResolved;

  const SyncConflictInfo({
    required this.field,
    required this.localValue,
    required this.remoteValue,
    required this.detectedAt,
    this.resolutionStrategy,
    required this.isResolved,
  });

  Map<String, dynamic> toJson() => {
        'field': field,
        'localValue': localValue,
        'remoteValue': remoteValue,
        'detectedAt': detectedAt.toIso8601String(),
        'resolutionStrategy': resolutionStrategy,
        'isResolved': isResolved,
      };

  factory SyncConflictInfo.fromJson(Map<String, dynamic> json) {
    return SyncConflictInfo(
      field: json['field'],
      localValue: json['localValue'],
      remoteValue: json['remoteValue'],
      detectedAt: DateTime.parse(json['detectedAt']),
      resolutionStrategy: json['resolutionStrategy'],
      isResolved: json['isResolved'],
    );
  }
}

/// Sync operation state
class SyncOperationState {
  final String operationId;
  final String type;
  final String collection;
  final String? entityId;
  final String status;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration? duration;
  final Map<String, dynamic> progress;
  final List<String> errors;
  final Map<String, dynamic> metadata;

  const SyncOperationState({
    required this.operationId,
    required this.type,
    required this.collection,
    this.entityId,
    required this.status,
    required this.startTime,
    this.endTime,
    this.duration,
    required this.progress,
    required this.errors,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'operationId': operationId,
        'type': type,
        'collection': collection,
        'entityId': entityId,
        'status': status,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'durationMs': duration?.inMilliseconds,
        'progress': progress,
        'errors': errors,
        'metadata': metadata,
      };

  /// Checks if operation is complete
  bool get isComplete => endTime != null;

  /// Checks if operation has errors
  bool get hasErrors => errors.isNotEmpty;

  /// Gets operation progress percentage
  double get progressPercentage {
    final total = progress['total'] as int? ?? 1;
    final completed = progress['completed'] as int? ?? 0;
    return ((completed / total) * 100).clamp(0.0, 100.0);
  }
}

/// Overall sync system state
class SyncSystemState {
  final bool isOnline;
  final bool isSyncing;
  final String backendType;
  final bool isBackendConnected;
  final DateTime? lastFullSync;
  final int activeOperations;
  final int pendingOperations;
  final int failedOperations;
  final List<SyncEntityState> entityStates;
  final List<SyncOperationState> recentOperations;
  final Map<String, dynamic> systemMetrics;

  const SyncSystemState({
    required this.isOnline,
    required this.isSyncing,
    required this.backendType,
    required this.isBackendConnected,
    this.lastFullSync,
    required this.activeOperations,
    required this.pendingOperations,
    required this.failedOperations,
    required this.entityStates,
    required this.recentOperations,
    this.systemMetrics = const {},
  });

  Map<String, dynamic> toJson() => {
        'isOnline': isOnline,
        'isSyncing': isSyncing,
        'backendType': backendType,
        'isBackendConnected': isBackendConnected,
        'lastFullSync': lastFullSync?.toIso8601String(),
        'activeOperations': activeOperations,
        'pendingOperations': pendingOperations,
        'failedOperations': failedOperations,
        'entityStates': entityStates.map((e) => e.toJson()).toList(),
        'recentOperations': recentOperations.map((o) => o.toJson()).toList(),
        'systemMetrics': systemMetrics,
      };

  /// Gets overall system health
  String get systemHealth {
    if (!isBackendConnected) return 'Backend Disconnected';
    if (!isOnline) return 'Offline';
    if (failedOperations > 5) return 'Multiple Failures';
    if (entityStates.any((e) => e.errorItems > 0)) return 'Sync Errors';
    if (entityStates.any((e) => e.dirtyItems > 0)) return 'Pending Changes';
    return 'Healthy';
  }

  /// Calculates overall sync percentage
  double get overallSyncPercentage {
    if (entityStates.isEmpty) return 100.0;

    final totalItems =
        entityStates.fold<int>(0, (sum, e) => sum + e.totalItems);
    if (totalItems == 0) return 100.0;

    final syncedItems =
        entityStates.fold<int>(0, (sum, e) => sum + e.syncedItems);
    return ((syncedItems / totalItems) * 100).clamp(0.0, 100.0);
  }
}

/// Sync state inspection service
class SyncStateInspector {
  final StreamController<SyncSystemState> _stateStreamController =
      StreamController<SyncSystemState>.broadcast();

  /// Stream of system state updates
  Stream<SyncSystemState> get stateStream => _stateStreamController.stream;

  /// Gets current system state
  Future<SyncSystemState> getCurrentSystemState() async {
    // This would integrate with the actual sync manager and database
    // For now, we'll return a mock state
    return SyncSystemState(
      isOnline: true,
      isSyncing: false,
      backendType: 'PocketBase',
      isBackendConnected: true,
      lastFullSync: DateTime.now().subtract(const Duration(minutes: 30)),
      activeOperations: 0,
      pendingOperations: 2,
      failedOperations: 0,
      entityStates: await _getEntityStates(),
      recentOperations: await _getRecentOperations(),
      systemMetrics: await _getSystemMetrics(),
    );
  }

  /// Gets state for a specific entity type
  Future<SyncEntityState> getEntityState(String entityType) async {
    // This would query the actual database
    return SyncEntityState(
      entityType: entityType,
      collection: '${entityType}_collection',
      totalItems: 100,
      dirtyItems: 5,
      syncedItems: 93,
      errorItems: 2,
      deletedItems: 0,
      lastSyncTime: DateTime.now().subtract(const Duration(minutes: 15)),
      lastModified: DateTime.now().subtract(const Duration(minutes: 5)),
      syncVersion: 42,
      pendingOperations: ['sync_pending_1', 'sync_pending_2'],
      metadata: {
        'avgSyncTime': 250,
        'lastError': null,
      },
    );
  }

  /// Gets detailed state for specific items
  Future<List<SyncItemState>> getItemStates(
    String entityType, {
    int? limit,
    String? status,
  }) async {
    // This would query the actual database
    return [
      SyncItemState(
        id: 'item_1',
        entityType: entityType,
        collection: '${entityType}_collection',
        isDirty: true,
        isDeleted: false,
        hasErrors: false,
        lastSyncedAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        syncVersion: 3,
        syncErrors: [],
        localData: {'name': 'Local Item 1', 'value': 42},
        remoteData: {'name': 'Remote Item 1', 'value': 40},
        conflicts: [
          SyncConflictInfo(
            field: 'value',
            localValue: 42,
            remoteValue: 40,
            detectedAt: DateTime.now().subtract(const Duration(minutes: 5)),
            isResolved: false,
          ),
        ],
      ),
    ];
  }

  /// Gets items with specific sync status
  Future<List<SyncItemState>> getItemsByStatus(
    String entityType,
    String status, {
    int? limit,
  }) async {
    final allItems = await getItemStates(entityType, limit: limit);
    return allItems.where((item) => item.syncStatus == status).toList();
  }

  /// Gets dirty (unsynced) items
  Future<List<SyncItemState>> getDirtyItems(String? entityType) async {
    if (entityType != null) {
      return (await getItemStates(entityType))
          .where((item) => item.isDirty)
          .toList();
    }

    // Get dirty items from all entity types
    final allStates = await _getEntityStates();
    final dirtyItems = <SyncItemState>[];

    for (final entityState in allStates) {
      if (entityState.dirtyItems > 0) {
        final items = await getDirtyItems(entityState.entityType);
        dirtyItems.addAll(items);
      }
    }

    return dirtyItems;
  }

  /// Gets items with sync errors
  Future<List<SyncItemState>> getErrorItems(String? entityType) async {
    if (entityType != null) {
      return (await getItemStates(entityType))
          .where((item) => item.hasErrors)
          .toList();
    }

    // Get error items from all entity types
    final allStates = await _getEntityStates();
    final errorItems = <SyncItemState>[];

    for (final entityState in allStates) {
      if (entityState.errorItems > 0) {
        final items = await getErrorItems(entityState.entityType);
        errorItems.addAll(items);
      }
    }

    return errorItems;
  }

  /// Gets items with conflicts
  Future<List<SyncItemState>> getConflictItems(String? entityType) async {
    if (entityType != null) {
      return (await getItemStates(entityType))
          .where((item) => item.conflicts.isNotEmpty)
          .toList();
    }

    // Get conflict items from all entity types
    final allStates = await _getEntityStates();
    final conflictItems = <SyncItemState>[];

    for (final entityState in allStates) {
      final items = await getConflictItems(entityState.entityType);
      conflictItems.addAll(items);
    }

    return conflictItems;
  }

  /// Gets current active operations
  Future<List<SyncOperationState>> getActiveOperations() async {
    return _getRecentOperations()
        .then((ops) => ops.where((op) => !op.isComplete).toList());
  }

  /// Gets recent completed operations
  Future<List<SyncOperationState>> getCompletedOperations({
    Duration? since,
    int? limit,
  }) async {
    final ops = await _getRecentOperations();
    var completedOps = ops.where((op) => op.isComplete).toList();

    if (since != null) {
      final cutoff = DateTime.now().subtract(since);
      completedOps =
          completedOps.where((op) => op.startTime.isAfter(cutoff)).toList();
    }

    if (limit != null) {
      completedOps = completedOps.take(limit).toList();
    }

    return completedOps;
  }

  /// Gets failed operations
  Future<List<SyncOperationState>> getFailedOperations({
    Duration? since,
    int? limit,
  }) async {
    final ops = await getCompletedOperations(since: since, limit: limit);
    return ops.where((op) => op.hasErrors).toList();
  }

  /// Diagnoses sync issues
  Future<Map<String, dynamic>> diagnoseSyncIssues() async {
    final systemState = await getCurrentSystemState();
    final issues = <String, dynamic>{};

    // Check connectivity
    if (!systemState.isOnline) {
      issues['connectivity'] = 'Device is offline';
    } else if (!systemState.isBackendConnected) {
      issues['backend'] = 'Backend connection failed';
    }

    // Check for failed operations
    if (systemState.failedOperations > 0) {
      final failedOps = await getFailedOperations(
        since: const Duration(hours: 24),
      );
      issues['failedOperations'] = {
        'count': systemState.failedOperations,
        'recentFailures': failedOps
            .map((op) => {
                  'id': op.operationId,
                  'type': op.type,
                  'errors': op.errors,
                })
            .toList(),
      };
    }

    // Check for entity-specific issues
    final entityIssues = <String, dynamic>{};
    for (final entityState in systemState.entityStates) {
      final entityProblems = <String, dynamic>{};

      if (entityState.errorItems > 0) {
        entityProblems['errorItems'] = entityState.errorItems;
      }

      if (entityState.dirtyItems > 0) {
        entityProblems['pendingItems'] = entityState.dirtyItems;
      }

      if (entityState.syncHealthPercentage < 90.0) {
        entityProblems['lowSyncHealth'] = entityState.syncHealthPercentage;
      }

      if (entityProblems.isNotEmpty) {
        entityIssues[entityState.entityType] = entityProblems;
      }
    }

    if (entityIssues.isNotEmpty) {
      issues['entities'] = entityIssues;
    }

    // Check for conflicts
    final conflictItems = await getConflictItems(null);
    if (conflictItems.isNotEmpty) {
      issues['conflicts'] = {
        'count': conflictItems.length,
        'items': conflictItems
            .map((item) => {
                  'id': item.id,
                  'entityType': item.entityType,
                  'conflicts': item.conflicts.length,
                })
            .toList(),
      };
    }

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'systemHealth': systemState.systemHealth,
      'overallSyncPercentage': systemState.overallSyncPercentage,
      'hasIssues': issues.isNotEmpty,
      'issues': issues,
      'recommendations': _generateRecommendations(issues),
    };
  }

  /// Exports complete state dump
  Future<Map<String, dynamic>> exportStateSnapshot({
    bool includeItemDetails = false,
  }) async {
    final systemState = await getCurrentSystemState();
    final snapshot = systemState.toJson();

    if (includeItemDetails) {
      final itemDetails = <String, dynamic>{};

      for (final entityState in systemState.entityStates) {
        final items = await getItemStates(entityState.entityType);
        itemDetails[entityState.entityType] =
            items.map((i) => i.toJson()).toList();
      }

      snapshot['itemDetails'] = itemDetails;
    }

    snapshot['diagnostics'] = await diagnoseSyncIssues();
    snapshot['exportedAt'] = DateTime.now().toIso8601String();

    return snapshot;
  }

  /// Monitors state changes
  void startStateMonitoring({Duration interval = const Duration(seconds: 30)}) {
    Timer.periodic(interval, (timer) async {
      try {
        final state = await getCurrentSystemState();
        _stateStreamController.add(state);
      } catch (e) {
        // Log error but continue monitoring
        print('State monitoring error: $e');
      }
    });
  }

  /// Mock methods - these would integrate with real database/sync manager

  Future<List<SyncEntityState>> _getEntityStates() async {
    // This would query all registered entity types
    return [
      SyncEntityState(
        entityType: 'organization_profiles',
        collection: 'organization_profiles',
        totalItems: 50,
        dirtyItems: 2,
        syncedItems: 47,
        errorItems: 1,
        deletedItems: 0,
        lastSyncTime: DateTime.now().subtract(const Duration(minutes: 15)),
        syncVersion: 10,
        pendingOperations: ['sync_orgs_1'],
      ),
      SyncEntityState(
        entityType: 'users',
        collection: 'users',
        totalItems: 25,
        dirtyItems: 1,
        syncedItems: 24,
        errorItems: 0,
        deletedItems: 0,
        lastSyncTime: DateTime.now().subtract(const Duration(minutes: 10)),
        syncVersion: 5,
        pendingOperations: [],
      ),
    ];
  }

  Future<List<SyncOperationState>> _getRecentOperations() async {
    // This would query the sync operation history
    return [
      SyncOperationState(
        operationId: 'op_1',
        type: 'sync',
        collection: 'organization_profiles',
        status: 'completed',
        startTime: DateTime.now().subtract(const Duration(minutes: 30)),
        endTime: DateTime.now().subtract(const Duration(minutes: 25)),
        duration: const Duration(minutes: 5),
        progress: {'total': 50, 'completed': 50},
        errors: [],
      ),
      SyncOperationState(
        operationId: 'op_2',
        type: 'sync',
        collection: 'users',
        status: 'running',
        startTime: DateTime.now().subtract(const Duration(minutes: 5)),
        progress: {'total': 25, 'completed': 20},
        errors: [],
      ),
    ];
  }

  Future<Map<String, dynamic>> _getSystemMetrics() async {
    // This would gather system performance metrics
    return {
      'avgSyncTime': 2500, // ms
      'networkLatency': 150, // ms
      'cacheHitRate': 0.85,
      'memoryUsage': 45.2, // MB
      'dbSize': 12.8, // MB
    };
  }

  List<String> _generateRecommendations(Map<String, dynamic> issues) {
    final recommendations = <String>[];

    if (issues.containsKey('connectivity')) {
      recommendations
          .add('Check internet connection and retry sync when online');
    }

    if (issues.containsKey('backend')) {
      recommendations.add('Verify backend service is running and accessible');
    }

    if (issues.containsKey('failedOperations')) {
      recommendations
          .add('Review failed operation logs and retry failed syncs');
    }

    if (issues.containsKey('conflicts')) {
      recommendations
          .add('Resolve data conflicts using conflict resolution tools');
    }

    if (issues.containsKey('entities')) {
      recommendations.add('Focus on entities with sync health below 90%');
      recommendations
          .add('Consider manual sync for entities with many pending items');
    }

    if (recommendations.isEmpty) {
      recommendations
          .add('System appears healthy - continue regular monitoring');
    }

    return recommendations;
  }

  /// Disposes the inspector
  void dispose() {
    _stateStreamController.close();
  }
}
