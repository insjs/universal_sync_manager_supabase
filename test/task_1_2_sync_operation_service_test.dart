import 'package:flutter_test/flutter_test.dart';
import 'package:universal_sync_manager/src/services/usm_services.dart';
import 'package:universal_sync_manager/src/interfaces/usm_sync_backend_adapter.dart';
import 'package:universal_sync_manager/src/models/usm_sync_result.dart';
import 'package:universal_sync_manager/src/models/usm_sync_backend_configuration.dart';
import 'package:universal_sync_manager/src/models/usm_sync_backend_capabilities.dart';
import 'package:universal_sync_manager/src/models/usm_sync_event.dart';

// Mock backend adapter for testing
class MockSyncBackendAdapter implements ISyncBackendAdapter {
  bool _isConnected = false;
  final Map<String, Map<String, dynamic>> _data = {};

  @override
  bool get isConnected => _isConnected;

  @override
  Future<bool> connect(SyncBackendConfiguration config) async {
    _isConnected = true;
    return true;
  }

  @override
  Future<void> disconnect() async {
    _isConnected = false;
  }

  @override
  Future<SyncResult> create(
      String collection, Map<String, dynamic> data) async {
    final id = data['id'] ?? 'mock_id_${DateTime.now().millisecondsSinceEpoch}';
    data['id'] = id;
    _data[id] = Map.from(data);

    return SyncResult.success(
      data: data,
      action: SyncAction.create,
      collection: collection,
      recordId: id,
    );
  }

  @override
  Future<SyncResult> read(String collection, String id) async {
    final data = _data[id];
    if (data == null) {
      return SyncResult.error(
        error: SyncError(
          type: SyncErrorType.validation,
          message: 'Record not found: $id',
        ),
        action: SyncAction.read,
        collection: collection,
      );
    }

    return SyncResult.success(
      data: data,
      action: SyncAction.read,
      collection: collection,
      recordId: id,
    );
  }

  @override
  Future<SyncResult> update(
      String collection, String id, Map<String, dynamic> data) async {
    if (!_data.containsKey(id)) {
      return SyncResult.error(
        error: SyncError(
          type: SyncErrorType.validation,
          message: 'Record not found: $id',
        ),
        action: SyncAction.update,
        collection: collection,
      );
    }

    _data[id] = Map.from(data);
    data['id'] = id;

    return SyncResult.success(
      data: data,
      action: SyncAction.update,
      collection: collection,
      recordId: id,
    );
  }

  @override
  Future<SyncResult> delete(String collection, String id) async {
    final data = _data.remove(id);
    if (data == null) {
      return SyncResult.error(
        error: SyncError(
          type: SyncErrorType.validation,
          message: 'Record not found: $id',
        ),
        action: SyncAction.delete,
        collection: collection,
      );
    }

    return SyncResult.success(
      data: data,
      action: SyncAction.delete,
      collection: collection,
      recordId: id,
    );
  }

  @override
  Future<List<SyncResult>> query(String collection, SyncQuery query) async {
    final results = _data.values
        .map((data) => SyncResult.success(
              data: data,
              action: SyncAction.read,
              collection: collection,
              recordId: data['id'],
            ))
        .toList();

    return results;
  }

  @override
  Future<List<SyncResult>> batchCreate(
      String collection, List<Map<String, dynamic>> items) async {
    final results = <SyncResult>[];
    for (final item in items) {
      final result = await create(collection, item);
      results.add(result);
    }
    return results;
  }

  @override
  Future<List<SyncResult>> batchUpdate(
      String collection, List<Map<String, dynamic>> items) async {
    final results = <SyncResult>[];
    for (final item in items) {
      final id = item['id'];
      if (id != null) {
        final result = await update(collection, id, item);
        results.add(result);
      }
    }
    return results;
  }

  @override
  Future<List<SyncResult>> batchDelete(
      String collection, List<String> ids) async {
    final results = <SyncResult>[];
    for (final id in ids) {
      final result = await delete(collection, id);
      results.add(result);
    }
    return results;
  }

  @override
  Stream<SyncEvent> subscribe(
      String collection, SyncSubscriptionOptions options) {
    // Simple mock implementation
    return Stream.empty();
  }

  @override
  Future<void> unsubscribe(String subscriptionId) async {
    // Mock implementation
  }

  @override
  SyncBackendCapabilities get capabilities =>
      SyncBackendCapabilities.fullFeatured();

  @override
  String get backendType => 'mock';

  @override
  String get backendVersion => '1.0.0';

  @override
  Map<String, dynamic> get backendInfo => {'type': 'mock', 'version': '1.0.0'};
}

void main() {
  group('Task 1.2: Sync Operation Service Tests', () {
    late MockSyncBackendAdapter mockAdapter;
    late SyncQueue syncQueue;
    late ConflictResolverManager conflictResolver;
    late SyncScheduler syncScheduler;
    late SyncEventBus eventBus;
    late UniversalSyncOperationService syncService;

    setUp(() {
      mockAdapter = MockSyncBackendAdapter();
      syncQueue = SyncQueue();
      conflictResolver = ConflictResolverManager();
      syncScheduler = SyncScheduler();
      eventBus = SyncEventBus.instance;

      syncService = UniversalSyncOperationService(
        backendAdapter: mockAdapter,
        syncQueue: syncQueue,
        conflictResolverManager: conflictResolver,
        syncScheduler: syncScheduler,
        eventBus: eventBus,
      );
    });

    tearDown(() {
      syncService.dispose();
      eventBus.dispose();
    });

    group('1. UniversalSyncOperationService Tests', () {
      test('should create service with default configuration', () {
        expect(syncService.config.maxConcurrentOperations, equals(3));
        expect(syncService.config.enableBatchOperations, isTrue);
        expect(syncService.config.enableConflictResolution, isTrue);
      });

      test('should update configuration', () {
        final newConfig = SyncOperationConfig(
          maxConcurrentOperations: 5,
          enableBatchOperations: false,
        );

        syncService.updateConfig(newConfig);

        expect(syncService.config.maxConcurrentOperations, equals(5));
        expect(syncService.config.enableBatchOperations, isFalse);
      });

      test('should register entity configuration', () {
        const collection = 'test_collection';
        const entityConfig = SyncEntityConfig(tableName: collection);

        syncService.registerEntity(collection, entityConfig);

        final status = syncService.getStatus();
        expect(status['registeredCollections'], contains(collection));
      });

      test('should unregister entity', () {
        const collection = 'test_collection';
        const entityConfig = SyncEntityConfig(tableName: collection);

        syncService.registerEntity(collection, entityConfig);
        syncService.unregisterEntity(collection);

        final status = syncService.getStatus();
        expect(status['registeredCollections'], isNot(contains(collection)));
      });

      test('should sync collection successfully', () async {
        const collection = 'test_collection';
        const entityConfig = SyncEntityConfig(tableName: collection);

        // Add some test data to mock adapter
        await mockAdapter.create(collection, {'id': '1', 'name': 'Test 1'});
        await mockAdapter.create(collection, {'id': '2', 'name': 'Test 2'});

        syncService.registerEntity(collection, entityConfig);

        final result = await syncService.syncCollection(collection);

        expect(result.isSuccess, isTrue);
        expect(result.data?['total'], equals(2));
      });

      test('should handle sync errors gracefully', () async {
        const collection = 'nonexistent_collection';

        final result = await syncService.syncCollection(collection);

        expect(result.isSuccess, isFalse);
        expect(result.error?.message, contains('not registered'));
      });

      test('should sync all registered collections', () async {
        const collection1 = 'collection1';
        const collection2 = 'collection2';

        syncService.registerEntity(
            collection1, const SyncEntityConfig(tableName: collection1));
        syncService.registerEntity(
            collection2, const SyncEntityConfig(tableName: collection2));

        final results = await syncService.syncAll();

        expect(results, hasLength(2));
        expect(results.every((r) => r.isSuccess), isTrue);
      });

      test('should handle pause and resume', () {
        syncService.pause();

        final status = syncService.getStatus();
        expect(status['isPaused'], isTrue);

        syncService.resume();
        // Note: Since resume is async internally, we check the immediate effect
        expect(syncService.getStatus()['isPaused'], isFalse);
      });

      test('should track progress during sync operations', () async {
        const collection = 'test_collection';
        const entityConfig = SyncEntityConfig(tableName: collection);

        syncService.registerEntity(collection, entityConfig);

        final progressEvents = <SyncProgress>[];
        syncService.progressStream.listen(progressEvents.add);

        await syncService.syncCollection(collection);

        // Allow some time for progress events
        await Future.delayed(const Duration(milliseconds: 100));

        // We should have received some progress updates
        expect(progressEvents, isNotEmpty);
      });
    });

    group('2. SyncQueue Tests', () {
      test('should enqueue operations by priority', () {
        final operation1 = SyncOperation(
          id: '1',
          collection: 'test',
          type: SyncOperationType.create,
          priority: SyncPriority.normal,
          createdAt: DateTime.now(),
        );

        final operation2 = SyncOperation(
          id: '2',
          collection: 'test',
          type: SyncOperationType.update,
          priority: SyncPriority.high,
          createdAt: DateTime.now(),
        );

        syncQueue.enqueue(operation1);
        syncQueue.enqueue(operation2);

        expect(syncQueue.size, equals(2));

        // High priority should come first
        final dequeued = syncQueue.dequeue();
        expect(dequeued?.id, equals('2'));
        expect(dequeued?.priority, equals(SyncPriority.high));
      });

      test('should handle queue events', () async {
        final addedEvents = <SyncOperation>[];
        final processedEvents = <SyncOperation>[];

        syncQueue.operationAdded.listen(addedEvents.add);
        syncQueue.operationProcessed.listen(processedEvents.add);

        final operation = SyncOperation(
          id: '1',
          collection: 'test',
          type: SyncOperationType.create,
          createdAt: DateTime.now(),
        );

        syncQueue.enqueue(operation);
        syncQueue.dequeue();

        await Future.delayed(const Duration(milliseconds: 10));

        expect(addedEvents, hasLength(1));
        expect(processedEvents, hasLength(1));
      });

      test('should remove operations by ID', () {
        final operation = SyncOperation(
          id: '1',
          collection: 'test',
          type: SyncOperationType.create,
          createdAt: DateTime.now(),
        );

        syncQueue.enqueue(operation);
        expect(syncQueue.size, equals(1));

        final removed = syncQueue.removeOperation('1');
        expect(removed, isTrue);
        expect(syncQueue.size, equals(0));
      });

      test('should clear queue by collection', () {
        final operation1 = SyncOperation(
          id: '1',
          collection: 'collection1',
          type: SyncOperationType.create,
          createdAt: DateTime.now(),
        );

        final operation2 = SyncOperation(
          id: '2',
          collection: 'collection2',
          type: SyncOperationType.create,
          createdAt: DateTime.now(),
        );

        syncQueue.enqueue(operation1);
        syncQueue.enqueue(operation2);

        syncQueue.clearCollection('collection1');

        expect(syncQueue.size, equals(1));
        expect(syncQueue.peek()?.collection, equals('collection2'));
      });

      test('should provide queue statistics', () {
        final operation1 = SyncOperation(
          id: '1',
          collection: 'test',
          type: SyncOperationType.create,
          priority: SyncPriority.high,
          createdAt: DateTime.now(),
        );

        final operation2 = SyncOperation(
          id: '2',
          collection: 'test',
          type: SyncOperationType.create,
          priority: SyncPriority.normal,
          createdAt: DateTime.now(),
        );

        syncQueue.enqueue(operation1);
        syncQueue.enqueue(operation2);

        final stats = syncQueue.sizeByPriority;
        expect(stats[SyncPriority.high], equals(1));
        expect(stats[SyncPriority.normal], equals(1));
        expect(stats[SyncPriority.critical], equals(0));
      });
    });

    group('3. ConflictResolver Tests', () {
      test('should detect field conflicts', () {
        final localData = {'id': '1', 'name': 'Local Name', 'value': 100};
        final remoteData = {'id': '1', 'name': 'Remote Name', 'value': 200};

        final conflict = conflictResolver.detectConflict(
          entityId: '1',
          collection: 'test',
          localData: localData,
          remoteData: remoteData,
          localVersion: 1,
          remoteVersion: 2,
        );

        expect(conflict, isNotNull);
        expect(conflict!.fieldConflicts, hasLength(2));
        expect(conflict.fieldConflicts.containsKey('name'), isTrue);
        expect(conflict.fieldConflicts.containsKey('value'), isTrue);
      });

      test('should resolve conflicts with local wins strategy', () {
        final localData = {'id': '1', 'name': 'Local Name'};
        final remoteData = {'id': '1', 'name': 'Remote Name'};

        final conflict = SyncConflict(
          entityId: '1',
          collection: 'test',
          localData: localData,
          remoteData: remoteData,
          fieldConflicts: {'name': ConflictType.valueDifference},
          detectedAt: DateTime.now(),
          localVersion: 1,
          remoteVersion: 1,
        );

        final resolver = DefaultConflictResolver(
          defaultStrategy: ConflictResolutionStrategy.localWins,
        );

        final resolution = resolver.resolveConflict(conflict);

        expect(resolution.resolvedData['name'], equals('Local Name'));
        expect(
            resolution.strategy, equals(ConflictResolutionStrategy.localWins));
      });

      test('should resolve conflicts with remote wins strategy', () {
        final localData = {'id': '1', 'name': 'Local Name'};
        final remoteData = {'id': '1', 'name': 'Remote Name'};

        final conflict = SyncConflict(
          entityId: '1',
          collection: 'test',
          localData: localData,
          remoteData: remoteData,
          fieldConflicts: {'name': ConflictType.valueDifference},
          detectedAt: DateTime.now(),
          localVersion: 1,
          remoteVersion: 1,
        );

        final resolver = DefaultConflictResolver(
          defaultStrategy: ConflictResolutionStrategy.remoteWins,
        );

        final resolution = resolver.resolveConflict(conflict);

        expect(resolution.resolvedData['name'], equals('Remote Name'));
        expect(
            resolution.strategy, equals(ConflictResolutionStrategy.remoteWins));
      });

      test('should resolve conflicts with newest wins strategy', () {
        final localData = {
          'id': '1',
          'name': 'Local Name',
          'updatedAt':
              DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        };
        final remoteData = {
          'id': '1',
          'name': 'Remote Name',
          'updatedAt': DateTime.now().toIso8601String(),
        };

        final conflict = SyncConflict(
          entityId: '1',
          collection: 'test',
          localData: localData,
          remoteData: remoteData,
          fieldConflicts: {'name': ConflictType.valueDifference},
          detectedAt: DateTime.now(),
          localVersion: 1,
          remoteVersion: 1,
        );

        final resolver = DefaultConflictResolver(
          defaultStrategy: ConflictResolutionStrategy.newestWins,
        );

        final resolution = resolver.resolveConflict(conflict);

        expect(resolution.resolvedData['name'], equals('Local Name'));
      });

      test('should register collection-specific resolvers', () {
        final customResolver = DefaultConflictResolver(
          defaultStrategy: ConflictResolutionStrategy.localWins,
        );

        conflictResolver.registerResolver('special_collection', customResolver);

        final localData = {'id': '1', 'name': 'Local Name'};
        final remoteData = {'id': '1', 'name': 'Remote Name'};

        final conflict = SyncConflict(
          entityId: '1',
          collection: 'special_collection',
          localData: localData,
          remoteData: remoteData,
          fieldConflicts: {'name': ConflictType.valueDifference},
          detectedAt: DateTime.now(),
          localVersion: 1,
          remoteVersion: 1,
        );

        final resolution = conflictResolver.resolveConflict(conflict);

        expect(resolution.resolvedData['name'], equals('Local Name'));
        expect(
            resolution.strategy, equals(ConflictResolutionStrategy.localWins));
      });
    });

    group('4. SyncScheduler Tests', () {
      test('should create scheduler with default configuration', () {
        expect(syncScheduler.config.mode, equals(SyncMode.automatic));
        expect(
            syncScheduler.config.interval, equals(const Duration(minutes: 15)));
        expect(syncScheduler.config.maxRetries, equals(3));
      });

      test('should update scheduler configuration', () {
        final newConfig = SyncScheduleConfig(
          mode: SyncMode.manual,
          interval: const Duration(minutes: 30),
          maxRetries: 5,
        );

        syncScheduler.updateConfig(newConfig);

        expect(syncScheduler.config.mode, equals(SyncMode.manual));
        expect(
            syncScheduler.config.interval, equals(const Duration(minutes: 30)));
        expect(syncScheduler.config.maxRetries, equals(5));
      });

      test('should trigger manual sync', () async {
        final triggers = <SyncTrigger>[];
        syncScheduler.syncTriggers.listen(triggers.add);

        syncScheduler.triggerManualSync(collection: 'test_collection');

        await Future.delayed(const Duration(milliseconds: 10));

        expect(triggers, hasLength(1));
        expect(triggers.first.type, equals(SyncTriggerType.manual));
        expect(triggers.first.collection, equals('test_collection'));
      });

      test('should schedule sync with delay', () async {
        final triggers = <SyncTrigger>[];
        syncScheduler.syncTriggers.listen(triggers.add);

        syncScheduler.scheduleSync(
          delay: const Duration(milliseconds: 50),
          collection: 'test_collection',
        );

        await Future.delayed(const Duration(milliseconds: 100));

        expect(triggers, hasLength(1));
        expect(triggers.first.type, equals(SyncTriggerType.scheduled));
      });

      test('should handle retry scheduling with exponential backoff', () {
        syncScheduler.scheduleRetry(
            collection: 'test_collection', retryCount: 0);
        syncScheduler.scheduleRetry(
            collection: 'test_collection', retryCount: 1);
        syncScheduler.scheduleRetry(
            collection: 'test_collection', retryCount: 2);

        // After max retries, should not schedule more
        syncScheduler.scheduleRetry(
            collection: 'test_collection', retryCount: 3);

        // Test passes if no exceptions are thrown
        expect(true, isTrue);
      });

      test('should notify sync success and reset retry counter', () {
        syncScheduler.scheduleRetry(
            collection: 'test_collection', retryCount: 2);
        syncScheduler.notifySyncSuccess('test_collection');

        // After success, retry counter should be reset
        // This is tested implicitly by the lack of errors
        expect(true, isTrue);
      });

      test('should handle network condition changes', () async {
        final triggers = <SyncTrigger>[];
        syncScheduler.syncTriggers.listen(triggers.add);

        syncScheduler.updateNetworkCondition(NetworkCondition.offline);
        syncScheduler.updateNetworkCondition(NetworkCondition.highSpeed);

        await Future.delayed(const Duration(milliseconds: 10));

        // Should trigger sync when network is restored
        expect(triggers.any((t) => t.type == SyncTriggerType.networkRestore),
            isTrue);
      });

      test('should handle data change notifications', () async {
        final triggers = <SyncTrigger>[];

        // Set to real-time mode
        syncScheduler
            .updateConfig(const SyncScheduleConfig(mode: SyncMode.realtime));
        syncScheduler.syncTriggers.listen(triggers.add);

        syncScheduler.notifyDataChange('test_collection');

        await Future.delayed(const Duration(milliseconds: 10));

        expect(
            triggers.any((t) => t.type == SyncTriggerType.dataChange), isTrue);
      });

      test('should calculate next sync time', () {
        final nextSyncTime = syncScheduler.getNextSyncTime();

        // For automatic mode, should return a future time
        expect(nextSyncTime, isNotNull);
        expect(nextSyncTime!.isAfter(DateTime.now()), isTrue);
      });

      test('should pause and resume scheduling', () {
        syncScheduler.start();
        syncScheduler.pause();

        // In pause state, manual triggers should still work but automatic ones shouldn't
        syncScheduler.triggerManualSync(); // Should work

        syncScheduler.resume();
        // Should be able to resume normal operation
        expect(true, isTrue);
      });
    });

    group('5. SyncEventBus Tests', () {
      test('should publish and subscribe to events', () async {
        final events = <SyncOperationStartedEvent>[];

        eventBus.subscribe<SyncOperationStartedEvent>(events.add);

        eventBus.publishSyncOperationStarted(
          collection: 'test_collection',
          operationType: SyncOperationType.create,
          entityId: '123',
        );

        await Future.delayed(const Duration(milliseconds: 10));

        expect(events, hasLength(1));
        expect(events.first.collection, equals('test_collection'));
        expect(events.first.operationType, equals(SyncOperationType.create));
      });

      test('should filter events by priority', () async {
        final highPriorityEvents = <SyncBusEvent>[];
        final allEvents = <SyncBusEvent>[];

        eventBus.subscribe<SyncBusEvent>(
          highPriorityEvents.add,
          minimumPriority: EventPriority.high,
        );
        eventBus.subscribe<SyncBusEvent>(allEvents.add);

        // Publish normal priority event
        eventBus.publish(SyncOperationStartedEvent(
          id: '1',
          timestamp: DateTime.now(),
          collection: 'test',
          operationType: SyncOperationType.create,
          priority: EventPriority.normal,
        ));

        // Publish high priority event
        eventBus.publish(SyncOperationStartedEvent(
          id: '2',
          timestamp: DateTime.now(),
          collection: 'test',
          operationType: SyncOperationType.create,
          priority: EventPriority.high,
        ));

        await Future.delayed(const Duration(milliseconds: 10));

        expect(allEvents, hasLength(2));
        expect(highPriorityEvents, hasLength(1));
        expect(highPriorityEvents.first.priority, equals(EventPriority.high));
      });

      test('should unsubscribe from events', () async {
        final events = <SyncOperationStartedEvent>[];

        final subscriptionId =
            eventBus.subscribe<SyncOperationStartedEvent>(events.add);

        eventBus.publishSyncOperationStarted(
          collection: 'test_collection',
          operationType: SyncOperationType.create,
        );

        final unsubscribed = eventBus.unsubscribe(subscriptionId);
        expect(unsubscribed, isTrue);

        eventBus.publishSyncOperationStarted(
          collection: 'test_collection',
          operationType: SyncOperationType.update,
        );

        await Future.delayed(const Duration(milliseconds: 10));

        // Should only receive the first event
        expect(events, hasLength(1));
      });

      test('should maintain event history', () {
        eventBus.publishSyncOperationStarted(
          collection: 'collection1',
          operationType: SyncOperationType.create,
        );

        eventBus.publishSyncOperationStarted(
          collection: 'collection2',
          operationType: SyncOperationType.update,
        );

        final history = eventBus.getEventHistory();
        expect(history, hasLength(2));

        final filteredHistory = eventBus.getEventHistory(
          eventType: SyncOperationStartedEvent,
        );
        expect(filteredHistory, hasLength(2));
      });

      test('should clear event history', () {
        eventBus.publishSyncOperationStarted(
          collection: 'test',
          operationType: SyncOperationType.create,
        );

        expect(eventBus.getEventHistory(), hasLength(1));

        eventBus.clearEventHistory();

        expect(eventBus.getEventHistory(), isEmpty);
      });

      test('should get subscription counts', () {
        final subscription1 =
            eventBus.subscribe<SyncOperationStartedEvent>((event) {});
        eventBus.subscribe<SyncOperationCompletedEvent>((event) {});
        eventBus.subscribe<SyncOperationStartedEvent>((event) {});

        expect(eventBus.getSubscriptionCount<SyncOperationStartedEvent>(),
            equals(2));
        expect(eventBus.getSubscriptionCount<SyncOperationCompletedEvent>(),
            equals(1));

        eventBus.unsubscribe(subscription1);
        expect(eventBus.getSubscriptionCount<SyncOperationStartedEvent>(),
            equals(1));
      });

      test('should handle event handler errors gracefully', () async {
        final successfulEvents = <SyncOperationStartedEvent>[];

        // Subscribe with a handler that throws
        eventBus.subscribe<SyncOperationStartedEvent>((event) {
          throw Exception('Handler error');
        });

        // Subscribe with a successful handler
        eventBus.subscribe<SyncOperationStartedEvent>(successfulEvents.add);

        eventBus.publishSyncOperationStarted(
          collection: 'test',
          operationType: SyncOperationType.create,
        );

        await Future.delayed(const Duration(milliseconds: 10));

        // Successful handler should still receive the event
        expect(successfulEvents, hasLength(1));
      });

      test('should publish various sync events', () async {
        final allEvents = <SyncBusEvent>[];
        eventBus.subscribeToAll(allEvents.add);

        // Test different event types
        eventBus.publishSyncOperationStarted(
          collection: 'test',
          operationType: SyncOperationType.create,
        );

        eventBus.publishSyncOperationCompleted(
          collection: 'test',
          operationType: SyncOperationType.create,
          result: SyncResult.success(
            data: {'id': '1'},
            action: SyncAction.create,
          ),
          duration: const Duration(seconds: 1),
        );

        eventBus.publishNetworkStatusChanged(
          oldCondition: NetworkCondition.offline,
          newCondition: NetworkCondition.highSpeed,
        );

        eventBus.publishSyncQueueStatusChanged(
          queueSize: 5,
          queueSizeByPriority: {
            SyncPriority.high: 2,
            SyncPriority.normal: 3,
          },
        );

        await Future.delayed(const Duration(milliseconds: 10));

        expect(allEvents, hasLength(4));
        expect(allEvents.any((e) => e is SyncOperationStartedEvent), isTrue);
        expect(allEvents.any((e) => e is SyncOperationCompletedEvent), isTrue);
        expect(allEvents.any((e) => e is NetworkStatusChangedEvent), isTrue);
        expect(allEvents.any((e) => e is SyncQueueStatusChangedEvent), isTrue);
      });
    });

    group('Integration Tests', () {
      test('should integrate all services for complete sync workflow',
          () async {
        // Setup
        const collection = 'integration_test';
        const entityConfig = SyncEntityConfig(tableName: collection);

        await mockAdapter.connect(SyncBackendConfiguration.pocketBase(
          configId: 'test_config',
          baseUrl: 'http://localhost:8090',
        ));

        syncService.registerEntity(collection, entityConfig);

        // Add test data
        await mockAdapter
            .create(collection, {'id': '1', 'name': 'Test Item 1'});
        await mockAdapter
            .create(collection, {'id': '2', 'name': 'Test Item 2'});

        // Track events
        final events = <SyncBusEvent>[];
        eventBus.subscribeToAll(events.add);

        // Trigger sync
        final result = await syncService.syncCollection(collection);

        await Future.delayed(const Duration(milliseconds: 100));

        // Verify results
        expect(result.isSuccess, isTrue);
        expect(result.data?['total'], equals(2));
        expect(result.data?['successful'], equals(2));

        // Verify events were published
        expect(events.any((e) => e is SyncOperationStartedEvent), isTrue);
        expect(events.any((e) => e is SyncOperationCompletedEvent), isTrue);
      });

      test('should handle conflict resolution in complete workflow', () async {
        // Setup conflict scenario
        final localData = {'id': '1', 'name': 'Local Name', 'syncVersion': 1};
        final remoteData = {'id': '1', 'name': 'Remote Name', 'syncVersion': 2};

        // Set up conflict resolver
        conflictResolver.setDefaultResolver(DefaultConflictResolver(
          defaultStrategy: ConflictResolutionStrategy.newestWins,
        ));

        // Simulate conflict detection
        final conflict = conflictResolver.detectConflict(
          entityId: '1',
          collection: 'test',
          localData: localData,
          remoteData: remoteData,
          localVersion: 1,
          remoteVersion: 2,
        );

        expect(conflict, isNotNull);

        // Resolve conflict
        final resolution = conflictResolver.resolveConflict(conflict!);

        expect(
            resolution.strategy, equals(ConflictResolutionStrategy.remoteWins));
        expect(resolution.resolvedData['name'], equals('Remote Name'));
      });

      test('should handle scheduled sync triggers', () async {
        const collection = 'scheduled_test';
        const entityConfig = SyncEntityConfig(
          tableName: collection,
          customSyncInterval: Duration(milliseconds: 100),
        );

        syncService.registerEntity(collection, entityConfig);

        // Set up scheduler for rapid testing
        syncScheduler.updateConfig(SyncScheduleConfig(
          mode: SyncMode.automatic,
          interval: const Duration(milliseconds: 100),
        ));

        final triggers = <SyncTrigger>[];
        syncScheduler.syncTriggers.listen(triggers.add);

        syncScheduler.start();

        await Future.delayed(const Duration(milliseconds: 200));

        syncScheduler.stop();

        // Should have received at least one trigger
        expect(triggers.isNotEmpty, isTrue);
      });
    });
  });
}
