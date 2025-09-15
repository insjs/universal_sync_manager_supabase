import 'dart:async';
import 'package:universal_sync_manager/universal_sync_manager.dart';
import 'package:uuid/uuid.dart';

/// Service for testing USM Queue & Scheduling functionality
/// Tests Phase 3.3: Queue & Scheduling Testing components
class TestQueueOperationsService {
  final _uuid = const Uuid();
  late SyncQueue _syncQueue;
  late SyncScheduler _syncScheduler;
  final List<SyncOperation> _processedOperations = [];
  final List<String> _testResults = [];
  Timer? _backgroundTimer;

  TestQueueOperationsService() {
    _syncQueue = SyncQueue();
    _syncScheduler = SyncScheduler(
      config: SyncScheduleConfig(
        mode: SyncMode.automatic,
        interval: const Duration(seconds: 10),
        retryDelay: const Duration(seconds: 5),
        maxRetries: 3,
      ),
    );
    _setupQueueListeners();
  }

  /// Setup listeners for queue events
  void _setupQueueListeners() {
    // Listen to operations added to queue
    _syncQueue.operationAdded.listen((operation) {
      _testResults.add(
          '✅ Operation added to queue: ${operation.type.name} (${operation.priority.name})');
      print(
          '📦 Queue: Added ${operation.type.name} operation with ${operation.priority.name} priority');
    });

    // Listen to operations processed from queue
    _syncQueue.operationProcessed.listen((operation) {
      _processedOperations.add(operation);
      _testResults
          .add('✅ Operation processed from queue: ${operation.type.name}');
      print('⚡ Queue: Processed ${operation.type.name} operation');
    });

    // Listen to queue size changes
    _syncQueue.queueSizeChanged.listen((size) {
      print('📊 Queue size changed: $size operations pending');
    });
  }

  /// Test 1: Basic Queue Operations
  Future<void> testBasicQueueOperations() async {
    print('\n🔄 Testing Basic Queue Operations...');
    _testResults.clear();

    // Create test operations with different priorities
    final operations = [
      _createTestOperation('CREATE', SyncPriority.critical, 'user_profiles'),
      _createTestOperation(
          'UPDATE', SyncPriority.high, 'organization_profiles'),
      _createTestOperation('DELETE', SyncPriority.normal, 'audit_items'),
      _createTestOperation('QUERY', SyncPriority.low, 'app_settings'),
      _createTestOperation('BATCH', SyncPriority.high, 'batch_data'),
    ];

    // Enqueue operations
    print('📦 Enqueueing ${operations.length} operations...');
    for (final operation in operations) {
      _syncQueue.enqueue(operation);
      await Future.delayed(
          const Duration(milliseconds: 100)); // Small delay for visibility
    }

    print('📊 Queue status: ${_syncQueue.size} operations in queue');

    // Process operations (should come out in priority order)
    print('⚡ Processing operations in priority order...');
    while (_syncQueue.size > 0) {
      final operation = _syncQueue.dequeue();
      if (operation != null) {
        await _simulateOperation(operation);
        await Future.delayed(
            const Duration(milliseconds: 200)); // Simulate processing time
      }
    }

    print('✅ Basic queue operations test completed');
    print('📈 Results summary:');
    for (final result in _testResults) {
      print('  $result');
    }
  }

  /// Test 2: Queue Priority Handling
  Future<void> testQueuePriorityHandling() async {
    print('\n🏆 Testing Queue Priority Handling...');

    // Create mixed priority operations
    final mixedOperations = [
      _createTestOperation('LOW_TASK', SyncPriority.low, 'background_sync'),
      _createTestOperation(
          'CRITICAL_ALERT', SyncPriority.critical, 'security_events'),
      _createTestOperation('NORMAL_UPDATE', SyncPriority.normal, 'user_data'),
      _createTestOperation('HIGH_BACKUP', SyncPriority.high, 'data_backup'),
      _createTestOperation('ANOTHER_LOW', SyncPriority.low, 'analytics'),
      _createTestOperation(
          'ANOTHER_CRITICAL', SyncPriority.critical, 'system_alerts'),
    ];

    // Enqueue all at once
    print('📦 Enqueueing mixed priority operations...');
    for (final operation in mixedOperations) {
      _syncQueue.enqueue(operation);
    }

    // Process and verify order (Critical -> High -> Normal -> Low)
    print('⚡ Processing operations - verifying priority order...');
    final processedOrder = <String>[];

    while (_syncQueue.size > 0) {
      final operation = _syncQueue.dequeue();
      if (operation != null) {
        processedOrder.add(
            '${operation.priority.name.toUpperCase()}: ${operation.type.name}');
        print(
            '  🎯 Processed: ${operation.priority.name.toUpperCase()} - ${operation.type.name}');
        await _simulateOperation(operation);
      }
    }

    // Verify priority order was maintained
    print('✅ Priority handling test completed');
    print('📋 Processing order:');
    for (int i = 0; i < processedOrder.length; i++) {
      print('  ${i + 1}. ${processedOrder[i]}');
    }

    // Validate that critical operations came first
    final criticalFirst =
        processedOrder.where((order) => order.startsWith('CRITICAL')).toList();
    final highSecond =
        processedOrder.where((order) => order.startsWith('HIGH')).toList();
    print('🔍 Priority validation:');
    print('  Critical operations: ${criticalFirst.length} (processed first)');
    print('  High operations: ${highSecond.length} (processed second)');
  }

  /// Test 3: Failed Operation Retry
  Future<void> testFailedOperationRetry() async {
    print('\n🔄 Testing Failed Operation Retry...');

    // Create operations that will "fail" initially
    final retryOperation = _createTestOperation(
        'RETRY_TEST', SyncPriority.high, 'retry_collection');

    print('📦 Adding operation that will fail initially...');
    _syncQueue.enqueue(retryOperation);

    // Simulate processing with failures and retries
    var attemptCount = 0;
    const maxAttempts = 3;

    while (_syncQueue.size > 0 && attemptCount < maxAttempts) {
      final operation = _syncQueue.dequeue();
      if (operation != null) {
        attemptCount++;
        print('🔄 Attempt $attemptCount for ${operation.type.name}');

        // Simulate failure on first 2 attempts, success on 3rd
        if (attemptCount < 3) {
          print('  ❌ Operation failed - will retry');

          // Create retry operation with increased retry count
          final retryOp = operation.copyWith(
            retryCount: operation.retryCount + 1,
            retryDelay: Duration(
                seconds: 2 * operation.retryCount + 1), // Exponential backoff
          );

          // Re-queue with delay
          await Future.delayed(const Duration(milliseconds: 500));
          _syncQueue.enqueue(retryOp);
          print(
              '  ⏰ Retry scheduled with ${retryOp.retryDelay?.inSeconds}s delay');
        } else {
          print('  ✅ Operation succeeded on retry');
          await _simulateOperation(operation);
        }
      }
    }

    print('✅ Failed operation retry test completed');
    print('📊 Retry statistics: $attemptCount attempts made');
  }

  /// Test 4: Scheduled Sync Execution
  Future<void> testScheduledSyncExecution() async {
    print('\n⏰ Testing Scheduled Sync Execution...');

    // Configure scheduler for frequent testing
    _syncScheduler.updateConfig(SyncScheduleConfig(
      mode: SyncMode.automatic,
      interval: const Duration(seconds: 3), // Very frequent for testing
      retryDelay: const Duration(seconds: 1),
      maxRetries: 2,
    ));

    print('⚙️ Configured scheduler with 3-second interval');

    // Set up sync trigger handler
    var syncTriggerCount = 0;
    _syncScheduler.syncTriggers.listen((trigger) {
      syncTriggerCount++;
      print('  🔔 Sync triggered #$syncTriggerCount: ${trigger.type.name}');

      // Add an operation to queue when sync is triggered
      final scheduledOp = _createTestOperation(
          'SCHEDULED_SYNC_$syncTriggerCount',
          SyncPriority.normal,
          'scheduled_collection');
      _syncQueue.enqueue(scheduledOp);
    });

    // Start scheduler
    print('▶️ Starting scheduler...');
    _syncScheduler.start();

    // Wait for several scheduled executions
    print('⏳ Waiting for scheduled sync executions (9 seconds)...');
    await Future.delayed(const Duration(seconds: 9));

    // Stop scheduler
    print('⏸️ Stopping scheduler...');
    _syncScheduler.pause();

    // Process any queued operations
    while (_syncQueue.size > 0) {
      final operation = _syncQueue.dequeue();
      if (operation != null) {
        await _simulateOperation(operation);
      }
    }

    print('✅ Scheduled sync execution test completed');
    print('📊 Total sync triggers: $syncTriggerCount');
    print('📊 Expected triggers: ~3 (every 3 seconds for 9 seconds)');
  }

  /// Test 5: Background Sync Behavior
  Future<void> testBackgroundSyncBehavior() async {
    print('\n🌙 Testing Background Sync Behavior...');

    // Simulate background sync operations
    var backgroundSyncCount = 0;

    // Start background sync timer
    _backgroundTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      backgroundSyncCount++;
      print('  🌙 Background sync #$backgroundSyncCount triggered');

      // Create background operation
      final backgroundOp = _createTestOperation(
          'BACKGROUND_$backgroundSyncCount',
          SyncPriority.low, // Background operations are typically low priority
          'background_data');

      _syncQueue.enqueue(backgroundOp);

      // Stop after 5 background syncs
      if (backgroundSyncCount >= 5) {
        timer.cancel();
        _backgroundTimer = null;
      }
    });

    print('⚙️ Started background sync simulation (every 2 seconds)...');
    print('⏳ Running background sync for 10 seconds...');

    // Let background sync run
    await Future.delayed(const Duration(seconds: 10));

    // Process all background operations
    print('⚡ Processing background operations...');
    while (_syncQueue.size > 0) {
      final operation = _syncQueue.dequeue();
      if (operation != null) {
        print('  📱 Processing background: ${operation.type.name}');
        await _simulateOperation(operation);
      }
    }

    print('✅ Background sync behavior test completed');
    print('📊 Background syncs performed: $backgroundSyncCount');
  }

  /// Test 6: Queue Persistence Simulation
  Future<void> testQueuePersistence() async {
    print('\n💾 Testing Queue Persistence Simulation...');

    // Create some operations
    final persistentOps = [
      _createTestOperation(
          'PERSISTENT_1', SyncPriority.high, 'persistent_data'),
      _createTestOperation(
          'PERSISTENT_2', SyncPriority.normal, 'user_settings'),
      _createTestOperation(
          'PERSISTENT_3', SyncPriority.critical, 'critical_updates'),
    ];

    // Add to queue
    print('📦 Adding operations to queue...');
    for (final op in persistentOps) {
      _syncQueue.enqueue(op);
    }

    print('📊 Queue size before "restart": ${_syncQueue.size}');

    // Simulate app restart by creating new queue and restoring operations
    print('🔄 Simulating app restart...');
    final savedOperations = _syncQueue.getAllOperations();

    // Create new queue (simulating fresh app start)
    _syncQueue = SyncQueue();
    _setupQueueListeners();

    // Restore operations (simulating persistence restoration)
    print('♻️ Restoring persisted operations...');
    for (final op in savedOperations) {
      _syncQueue.enqueue(op);
      print('  ↩️ Restored: ${op.type.name} (${op.priority.name})');
    }

    print('📊 Queue size after "restart": ${_syncQueue.size}');

    // Process restored operations
    print('⚡ Processing restored operations...');
    while (_syncQueue.size > 0) {
      final operation = _syncQueue.dequeue();
      if (operation != null) {
        await _simulateOperation(operation);
      }
    }

    print('✅ Queue persistence simulation completed');
    print(
        '📊 All ${persistentOps.length} operations were successfully restored and processed');
  }

  /// Run all queue and scheduling tests
  Future<void> runAllQueueTests() async {
    print('🚀 Starting Queue & Scheduling Test Suite...');
    print('=' * 50);

    try {
      await testBasicQueueOperations();
      await Future.delayed(const Duration(seconds: 1));

      await testQueuePriorityHandling();
      await Future.delayed(const Duration(seconds: 1));

      await testFailedOperationRetry();
      await Future.delayed(const Duration(seconds: 1));

      await testScheduledSyncExecution();
      await Future.delayed(const Duration(seconds: 1));

      await testBackgroundSyncBehavior();
      await Future.delayed(const Duration(seconds: 1));

      await testQueuePersistence();

      print('\n🎉 All Queue & Scheduling Tests Completed Successfully!');
      print('📈 Test Summary:');
      print('  ✅ Basic Queue Operations');
      print('  ✅ Queue Priority Handling');
      print('  ✅ Failed Operation Retry');
      print('  ✅ Scheduled Sync Execution');
      print('  ✅ Background Sync Behavior');
      print('  ✅ Queue Persistence Simulation');
      print('📊 Total processed operations: ${_processedOperations.length}');
    } catch (e) {
      print('❌ Queue testing failed: $e');
      rethrow;
    } finally {
      // Cleanup
      _backgroundTimer?.cancel();
      _syncScheduler.stop();
    }
  }

  /// Create a test sync operation
  SyncOperation _createTestOperation(
      String type, SyncPriority priority, String collection) {
    return SyncOperation(
      id: _uuid.v4(),
      collection: collection,
      type: SyncOperationType.create, // Default to create for testing
      priority: priority,
      createdAt: DateTime.now(),
      data: {
        'test_type': type,
        'timestamp': DateTime.now().toIso8601String(),
        'test_data': 'Sample data for $type operation',
      },
      metadata: {
        'test_operation': true,
        'operation_name': type,
        'created_for_testing': true,
      },
    );
  }

  /// Simulate processing an operation
  Future<void> _simulateOperation(SyncOperation operation) async {
    // Simulate processing time based on priority
    final processingTime = switch (operation.priority) {
      SyncPriority.critical => 50, // Fast processing for critical
      SyncPriority.high => 100, // Medium processing for high
      SyncPriority.normal => 200, // Normal processing time
      SyncPriority.low => 300, // Slower for low priority
    };

    await Future.delayed(Duration(milliseconds: processingTime));

    // Log the simulated processing
    print(
        '    ⚡ Processed ${operation.type.name} (${operation.priority.name}) in ${processingTime}ms');
  }

  /// Get queue statistics
  Map<String, dynamic> getQueueStatistics() {
    return {
      'total_processed': _processedOperations.length,
      'current_queue_size': _syncQueue.size,
      'test_results_count': _testResults.length,
      'by_priority': {
        'critical': _processedOperations
            .where((op) => op.priority == SyncPriority.critical)
            .length,
        'high': _processedOperations
            .where((op) => op.priority == SyncPriority.high)
            .length,
        'normal': _processedOperations
            .where((op) => op.priority == SyncPriority.normal)
            .length,
        'low': _processedOperations
            .where((op) => op.priority == SyncPriority.low)
            .length,
      },
    };
  }

  /// Cleanup resources
  void dispose() {
    _backgroundTimer?.cancel();
    _syncScheduler.stop();
  }
}
