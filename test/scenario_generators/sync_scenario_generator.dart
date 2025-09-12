// test/scenario_generators/sync_scenario_generator.dart

import 'dart:math';

/// Test scenario types
enum SyncScenarioType {
  simpleSync,
  conflictResolution,
  networkFailure,
  largeBatch,
  realTimeUpdates,
  offlineSync,
  dataCorruption,
  concurrentUsers,
  backendFailover,
  performanceStress,
}

/// Individual sync operation in a scenario
class SyncOperation {
  final String id;
  final String type;
  final String collection;
  final String? entityId;
  final Map<String, dynamic> data;
  final Duration delay;
  final bool shouldFail;
  final String? errorMessage;
  final Map<String, dynamic> metadata;

  const SyncOperation({
    required this.id,
    required this.type,
    required this.collection,
    this.entityId,
    this.data = const {},
    this.delay = Duration.zero,
    this.shouldFail = false,
    this.errorMessage,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'collection': collection,
        'entityId': entityId,
        'data': data,
        'delayMs': delay.inMilliseconds,
        'shouldFail': shouldFail,
        'errorMessage': errorMessage,
        'metadata': metadata,
      };

  SyncOperation copyWith({
    String? id,
    String? type,
    String? collection,
    String? entityId,
    Map<String, dynamic>? data,
    Duration? delay,
    bool? shouldFail,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return SyncOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      collection: collection ?? this.collection,
      entityId: entityId ?? this.entityId,
      data: data ?? this.data,
      delay: delay ?? this.delay,
      shouldFail: shouldFail ?? this.shouldFail,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Complete test scenario
class SyncTestScenario {
  final String id;
  final String name;
  final String description;
  final SyncScenarioType type;
  final List<SyncOperation> operations;
  final Map<String, dynamic> initialData;
  final Map<String, dynamic> expectedResults;
  final Map<String, dynamic> networkConditions;
  final Map<String, dynamic> configuration;
  final Duration estimatedDuration;

  const SyncTestScenario({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.operations,
    this.initialData = const {},
    this.expectedResults = const {},
    this.networkConditions = const {},
    this.configuration = const {},
    required this.estimatedDuration,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type.name,
        'operations': operations.map((op) => op.toJson()).toList(),
        'initialData': initialData,
        'expectedResults': expectedResults,
        'networkConditions': networkConditions,
        'configuration': configuration,
        'estimatedDurationMs': estimatedDuration.inMilliseconds,
      };

  /// Gets operations count by type
  Map<String, int> get operationCounts {
    final counts = <String, int>{};
    for (final op in operations) {
      counts[op.type] = (counts[op.type] ?? 0) + 1;
    }
    return counts;
  }

  /// Gets total expected failures
  int get expectedFailures => operations.where((op) => op.shouldFail).length;
}

/// Configuration for scenario generation
class ScenarioGenerationConfig {
  final int maxOperations;
  final List<String> collections;
  final List<String> operationTypes;
  final Duration maxDelay;
  final double failureRate;
  final bool includeConflicts;
  final bool includeNetworkIssues;
  final Map<String, dynamic> customParameters;

  const ScenarioGenerationConfig({
    this.maxOperations = 100,
    this.collections = const ['organization_profiles', 'users', 'settings'],
    this.operationTypes = const ['create', 'read', 'update', 'delete', 'sync'],
    this.maxDelay = const Duration(seconds: 5),
    this.failureRate = 0.1,
    this.includeConflicts = true,
    this.includeNetworkIssues = true,
    this.customParameters = const {},
  });
}

/// Generates various sync test scenarios
class SyncScenarioGenerator {
  final Random _random = Random();
  int _operationCounter = 0;

  /// Generates a scenario based on type
  SyncTestScenario generateScenario(
    SyncScenarioType type, {
    ScenarioGenerationConfig? config,
    Map<String, dynamic>? customConfig,
  }) {
    final generationConfig = config ?? const ScenarioGenerationConfig();

    switch (type) {
      case SyncScenarioType.simpleSync:
        return _generateSimpleSyncScenario(generationConfig);
      case SyncScenarioType.conflictResolution:
        return _generateConflictResolutionScenario(generationConfig);
      case SyncScenarioType.networkFailure:
        return _generateNetworkFailureScenario(generationConfig);
      case SyncScenarioType.largeBatch:
        return _generateLargeBatchScenario(generationConfig);
      case SyncScenarioType.realTimeUpdates:
        return _generateRealTimeUpdatesScenario(generationConfig);
      case SyncScenarioType.offlineSync:
        return _generateOfflineSyncScenario(generationConfig);
      case SyncScenarioType.dataCorruption:
        return _generateDataCorruptionScenario(generationConfig);
      case SyncScenarioType.concurrentUsers:
        return _generateConcurrentUsersScenario(generationConfig);
      case SyncScenarioType.backendFailover:
        return _generateBackendFailoverScenario(generationConfig);
      case SyncScenarioType.performanceStress:
        return _generatePerformanceStressScenario(generationConfig);
    }
  }

  /// Generates multiple scenarios for comprehensive testing
  List<SyncTestScenario> generateTestSuite({
    List<SyncScenarioType>? types,
    ScenarioGenerationConfig? config,
  }) {
    final scenarioTypes = types ?? SyncScenarioType.values;
    final scenarios = <SyncTestScenario>[];

    for (final type in scenarioTypes) {
      scenarios.add(generateScenario(type, config: config));
    }

    return scenarios;
  }

  /// Generates scenarios with specific parameters
  List<SyncTestScenario> generateParameterizedScenarios(
    SyncScenarioType baseType,
    List<Map<String, dynamic>> parameterSets,
  ) {
    final scenarios = <SyncTestScenario>[];

    for (int i = 0; i < parameterSets.length; i++) {
      final params = parameterSets[i];
      final config = ScenarioGenerationConfig(
        maxOperations: params['maxOperations'] ?? 100,
        collections: List<String>.from(
            params['collections'] ?? ['organization_profiles', 'users']),
        operationTypes: List<String>.from(
            params['operationTypes'] ?? ['create', 'read', 'update', 'delete']),
        maxDelay: Duration(milliseconds: params['maxDelayMs'] ?? 5000),
        failureRate: (params['failureRate'] ?? 0.1).toDouble(),
        includeConflicts: params['includeConflicts'] ?? true,
        includeNetworkIssues: params['includeNetworkIssues'] ?? true,
        customParameters:
            Map<String, dynamic>.from(params['customParameters'] ?? {}),
      );

      final scenario = generateScenario(baseType, config: config);
      scenarios.add(SyncTestScenario(
        id: '${scenario.id}_variant_$i',
        name: '${scenario.name} (Variant ${i + 1})',
        description: '${scenario.description} - Variant with custom parameters',
        type: scenario.type,
        operations: scenario.operations,
        initialData: scenario.initialData,
        expectedResults: scenario.expectedResults,
        networkConditions: scenario.networkConditions,
        configuration: {...scenario.configuration, 'variantParams': params},
        estimatedDuration: scenario.estimatedDuration,
      ));
    }

    return scenarios;
  }

  // Private scenario generation methods

  SyncTestScenario _generateSimpleSyncScenario(
      ScenarioGenerationConfig config) {
    final operations = <SyncOperation>[];

    // Create some initial data
    for (int i = 0; i < 5; i++) {
      operations.add(_createOperation(
        'create',
        config.collections.first,
        data: {'name': 'Item $i', 'value': i * 10},
      ));
    }

    // Perform sync operations
    operations.add(_createOperation('sync', config.collections.first));

    // Update some items
    for (int i = 0; i < 2; i++) {
      operations.add(_createOperation(
        'update',
        config.collections.first,
        entityId: 'item_$i',
        data: {'name': 'Updated Item $i', 'value': i * 20},
      ));
    }

    // Final sync
    operations.add(_createOperation('sync', config.collections.first));

    return SyncTestScenario(
      id: 'simple_sync_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Simple Sync Test',
      description: 'Basic sync operations with create, update, and sync',
      type: SyncScenarioType.simpleSync,
      operations: operations,
      initialData: {'itemCount': 5},
      expectedResults: {'syncedItems': 5, 'updatedItems': 2},
      estimatedDuration: Duration(milliseconds: operations.length * 100),
    );
  }

  SyncTestScenario _generateConflictResolutionScenario(
      ScenarioGenerationConfig config) {
    final operations = <SyncOperation>[];

    // Create initial item
    operations.add(_createOperation(
      'create',
      config.collections.first,
      entityId: 'conflict_item',
      data: {'name': 'Original Item', 'value': 100},
    ));

    // Sync to establish baseline
    operations.add(_createOperation('sync', config.collections.first));

    // Simulate concurrent updates that will create conflicts
    operations.add(_createOperation(
      'update',
      config.collections.first,
      entityId: 'conflict_item',
      data: {'name': 'Local Update', 'value': 150},
      metadata: {'source': 'local'},
    ));

    operations.add(_createOperation(
      'update',
      config.collections.first,
      entityId: 'conflict_item',
      data: {'name': 'Remote Update', 'value': 200},
      metadata: {'source': 'remote', 'simulateConflict': true},
    ));

    // Attempt sync which should detect conflict
    operations.add(_createOperation(
      'sync',
      config.collections.first,
      metadata: {'expectConflict': true},
    ));

    return SyncTestScenario(
      id: 'conflict_resolution_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Conflict Resolution Test',
      description: 'Tests conflict detection and resolution during sync',
      type: SyncScenarioType.conflictResolution,
      operations: operations,
      configuration: {'conflictResolutionStrategy': 'serverWins'},
      expectedResults: {'conflicts': 1, 'resolutions': 1},
      estimatedDuration: Duration(milliseconds: operations.length * 200),
    );
  }

  SyncTestScenario _generateNetworkFailureScenario(
      ScenarioGenerationConfig config) {
    final operations = <SyncOperation>[];

    // Normal operations
    for (int i = 0; i < 3; i++) {
      operations.add(_createOperation(
        'create',
        config.collections.first,
        data: {'name': 'Item $i'},
      ));
    }

    // Network failure during sync
    operations.add(_createOperation(
      'sync',
      config.collections.first,
      shouldFail: true,
      errorMessage: 'Network timeout',
      metadata: {'networkCondition': 'offline'},
    ));

    // Recovery operations
    operations.add(_createOperation(
      'sync',
      config.collections.first,
      delay: const Duration(seconds: 2),
      metadata: {'networkCondition': 'restored'},
    ));

    return SyncTestScenario(
      id: 'network_failure_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Network Failure Recovery Test',
      description: 'Tests sync behavior during network failures and recovery',
      type: SyncScenarioType.networkFailure,
      operations: operations,
      networkConditions: {
        'initialState': 'online',
        'failurePoint': 'during_sync',
        'recoveryDelay': 2000,
      },
      expectedResults: {'failedSyncs': 1, 'recoveredSyncs': 1},
      estimatedDuration: const Duration(seconds: 5),
    );
  }

  SyncTestScenario _generateLargeBatchScenario(
      ScenarioGenerationConfig config) {
    final operations = <SyncOperation>[];
    final batchSize = config.maxOperations;

    // Create large batch of items
    for (int i = 0; i < batchSize; i++) {
      operations.add(_createOperation(
        'create',
        config.collections[i % config.collections.length],
        data: {
          'name': 'Batch Item $i',
          'batchIndex': i,
          'category': 'batch_test',
        },
        delay: Duration(milliseconds: _random.nextInt(50)),
      ));
    }

    // Batch sync operation
    operations.add(_createOperation(
      'batchSync',
      'all',
      metadata: {'batchSize': batchSize},
    ));

    return SyncTestScenario(
      id: 'large_batch_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Large Batch Sync Test',
      description: 'Tests sync performance with large batches of data',
      type: SyncScenarioType.largeBatch,
      operations: operations,
      configuration: {'batchSize': batchSize},
      expectedResults: {'batchedItems': batchSize},
      estimatedDuration: Duration(milliseconds: batchSize * 10),
    );
  }

  SyncTestScenario _generateRealTimeUpdatesScenario(
      ScenarioGenerationConfig config) {
    final operations = <SyncOperation>[];

    // Setup subscription
    operations.add(_createOperation(
      'subscribe',
      config.collections.first,
      metadata: {'subscriptionType': 'realtime'},
    ));

    // Create items with rapid updates
    for (int i = 0; i < 10; i++) {
      operations.add(_createOperation(
        'create',
        config.collections.first,
        entityId: 'realtime_item_$i',
        data: {'name': 'Realtime Item $i', 'status': 'active'},
        delay: Duration(milliseconds: 100 * i),
      ));

      // Immediate update
      operations.add(_createOperation(
        'update',
        config.collections.first,
        entityId: 'realtime_item_$i',
        data: {'status': 'updated'},
        delay: Duration(milliseconds: 50),
      ));
    }

    return SyncTestScenario(
      id: 'realtime_updates_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Real-time Updates Test',
      description: 'Tests real-time subscription and rapid updates',
      type: SyncScenarioType.realTimeUpdates,
      operations: operations,
      configuration: {'subscriptionEnabled': true},
      expectedResults: {'realtimeEvents': 20},
      estimatedDuration: const Duration(seconds: 3),
    );
  }

  SyncTestScenario _generateOfflineSyncScenario(
      ScenarioGenerationConfig config) {
    final operations = <SyncOperation>[];

    // Online operations
    for (int i = 0; i < 3; i++) {
      operations.add(_createOperation(
        'create',
        config.collections.first,
        data: {'name': 'Online Item $i'},
      ));
    }

    // Go offline
    operations.add(_createOperation(
      'setNetworkState',
      'system',
      metadata: {'state': 'offline'},
    ));

    // Offline operations (should queue)
    for (int i = 0; i < 5; i++) {
      operations.add(_createOperation(
        'create',
        config.collections.first,
        data: {'name': 'Offline Item $i'},
        metadata: {'queued': true},
      ));
    }

    // Come back online
    operations.add(_createOperation(
      'setNetworkState',
      'system',
      metadata: {'state': 'online'},
    ));

    // Sync queued operations
    operations.add(_createOperation(
      'syncQueued',
      'all',
      metadata: {'expectedQueuedItems': 5},
    ));

    return SyncTestScenario(
      id: 'offline_sync_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Offline Sync Test',
      description: 'Tests offline operation queueing and sync when online',
      type: SyncScenarioType.offlineSync,
      operations: operations,
      networkConditions: {'offlinePeriod': 5000},
      expectedResults: {'queuedOperations': 5, 'syncedAfterOnline': 5},
      estimatedDuration: const Duration(seconds: 8),
    );
  }

  SyncTestScenario _generateDataCorruptionScenario(
      ScenarioGenerationConfig config) {
    final operations = <SyncOperation>[];

    // Create normal data
    for (int i = 0; i < 5; i++) {
      operations.add(_createOperation(
        'create',
        config.collections.first,
        data: {'name': 'Normal Item $i', 'integrity': 'valid'},
      ));
    }

    // Introduce corruption
    operations.add(_createOperation(
      'corruptData',
      config.collections.first,
      metadata: {
        'corruptionType': 'invalid_json',
        'affectedItems': 2,
      },
    ));

    // Attempt sync (should detect corruption)
    operations.add(_createOperation(
      'sync',
      config.collections.first,
      metadata: {'expectCorruption': true},
    ));

    // Recovery operation
    operations.add(_createOperation(
      'repairData',
      config.collections.first,
      metadata: {'repairStrategy': 'restore_from_backup'},
    ));

    return SyncTestScenario(
      id: 'data_corruption_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Data Corruption Recovery Test',
      description: 'Tests detection and recovery from data corruption',
      type: SyncScenarioType.dataCorruption,
      operations: operations,
      expectedResults: {'corruptedItems': 2, 'repairedItems': 2},
      estimatedDuration: const Duration(seconds: 4),
    );
  }

  SyncTestScenario _generateConcurrentUsersScenario(
      ScenarioGenerationConfig config) {
    final operations = <SyncOperation>[];
    final userCount = 3;

    // Simulate multiple users working on same data
    for (int user = 0; user < userCount; user++) {
      for (int i = 0; i < 3; i++) {
        operations.add(_createOperation(
          'create',
          config.collections.first,
          data: {
            'name': 'User$user Item $i',
            'userId': 'user_$user',
            'created':
                DateTime.now().millisecondsSinceEpoch + (user * 1000) + i,
          },
          delay: Duration(milliseconds: user * 100),
          metadata: {'user': 'user_$user'},
        ));
      }
    }

    // Concurrent updates to same item
    for (int user = 0; user < userCount; user++) {
      operations.add(_createOperation(
        'update',
        config.collections.first,
        entityId: 'shared_item',
        data: {
          'lastEditedBy': 'user_$user',
          'editTimestamp': DateTime.now().millisecondsSinceEpoch + (user * 500),
        },
        delay: Duration(milliseconds: user * 200),
        metadata: {'user': 'user_$user'},
      ));
    }

    // Sync all changes
    operations.add(_createOperation(
      'sync',
      config.collections.first,
      metadata: {'expectConcurrencyConflicts': true},
    ));

    return SyncTestScenario(
      id: 'concurrent_users_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Concurrent Users Test',
      description: 'Tests sync behavior with multiple concurrent users',
      type: SyncScenarioType.concurrentUsers,
      operations: operations,
      configuration: {'userCount': userCount},
      expectedResults: {'concurrencyConflicts': 2},
      estimatedDuration: const Duration(seconds: 3),
    );
  }

  SyncTestScenario _generateBackendFailoverScenario(
      ScenarioGenerationConfig config) {
    final operations = <SyncOperation>[];

    // Normal operations on primary backend
    for (int i = 0; i < 3; i++) {
      operations.add(_createOperation(
        'create',
        config.collections.first,
        data: {'name': 'Primary Item $i'},
        metadata: {'backend': 'primary'},
      ));
    }

    // Primary backend failure
    operations.add(_createOperation(
      'simulateBackendFailure',
      'system',
      metadata: {'backend': 'primary'},
    ));

    // Failover to secondary backend
    operations.add(_createOperation(
      'failover',
      'system',
      metadata: {'from': 'primary', 'to': 'secondary'},
    ));

    // Continue operations on secondary
    for (int i = 0; i < 2; i++) {
      operations.add(_createOperation(
        'create',
        config.collections.first,
        data: {'name': 'Secondary Item $i'},
        metadata: {'backend': 'secondary'},
      ));
    }

    // Primary backend recovery
    operations.add(_createOperation(
      'restoreBackend',
      'system',
      metadata: {'backend': 'primary'},
    ));

    // Sync between backends
    operations.add(_createOperation(
      'syncBackends',
      'system',
      metadata: {'source': 'secondary', 'target': 'primary'},
    ));

    return SyncTestScenario(
      id: 'backend_failover_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Backend Failover Test',
      description: 'Tests backend failover and recovery scenarios',
      type: SyncScenarioType.backendFailover,
      operations: operations,
      configuration: {'backendCount': 2},
      expectedResults: {'failovers': 1, 'backendSyncs': 1},
      estimatedDuration: const Duration(seconds: 6),
    );
  }

  SyncTestScenario _generatePerformanceStressScenario(
      ScenarioGenerationConfig config) {
    final operations = <SyncOperation>[];
    final stressOperationCount = config.maxOperations * 2;

    // High-volume rapid operations
    for (int i = 0; i < stressOperationCount; i++) {
      final operationType =
          config.operationTypes[i % config.operationTypes.length];
      operations.add(_createOperation(
        operationType,
        config.collections[i % config.collections.length],
        data: {
          'name': 'Stress Item $i',
          'index': i,
          'timestamp': DateTime.now().millisecondsSinceEpoch + i,
        },
        delay: Duration(milliseconds: _random.nextInt(10)), // Very short delays
        metadata: {'stressTest': true},
      ));

      // Add sync every 50 operations
      if (i % 50 == 0) {
        operations.add(_createOperation(
          'sync',
          config.collections[i % config.collections.length],
          metadata: {'stressSyncPoint': i},
        ));
      }
    }

    return SyncTestScenario(
      id: 'performance_stress_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Performance Stress Test',
      description: 'High-volume operations to test performance limits',
      type: SyncScenarioType.performanceStress,
      operations: operations,
      configuration: {'operationCount': stressOperationCount},
      expectedResults: {'processedOperations': stressOperationCount},
      estimatedDuration: Duration(milliseconds: stressOperationCount * 5),
    );
  }

  SyncOperation _createOperation(
    String type,
    String collection, {
    String? entityId,
    Map<String, dynamic> data = const {},
    Duration delay = Duration.zero,
    bool shouldFail = false,
    String? errorMessage,
    Map<String, dynamic> metadata = const {},
  }) {
    return SyncOperation(
      id: 'op_${_operationCounter++}',
      type: type,
      collection: collection,
      entityId: entityId,
      data: data,
      delay: delay,
      shouldFail: shouldFail,
      errorMessage: errorMessage,
      metadata: metadata,
    );
  }
}
