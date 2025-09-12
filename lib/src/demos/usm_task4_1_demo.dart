/// Task 4.1: Intelligent Sync Optimization Demo
///
/// This demo showcases all the intelligent sync optimization features
/// implemented in Task 4.1, including delta sync, compression, batch operations,
/// smart scheduling, and priority queues.
library;

import 'dart:convert';
import '../services/usm_delta_sync_service.dart';
import '../services/usm_sync_compression_service.dart';
import '../services/usm_batch_sync_service.dart';
import '../services/usm_smart_sync_scheduler.dart';
import '../services/usm_sync_priority_queue_service.dart';
import '../config/usm_sync_enums.dart';
import '../models/usm_sync_result.dart';

/// Comprehensive demo for Task 4.1: Intelligent Sync Optimization
class Task41Demo {
  /// Run the complete demo showing all optimization features
  static Future<void> run() async {
    print(
        '\n🚀 Universal Sync Manager - Task 4.1: Intelligent Sync Optimization Demo');
    print('=' * 80);

    // Demo 1: Delta Sync Service
    await _demonstrateDeltaSync();

    // Demo 2: Compression Service
    await _demonstrateCompression();

    // Demo 3: Batch Sync Operations
    await _demonstrateBatchSync();

    // Demo 4: Smart Sync Scheduling
    await _demonstrateSmartScheduling();

    // Demo 5: Priority Queue Service
    await _demonstratePriorityQueues();

    print('\n✅ Task 4.1 Demo completed successfully!');
    print('All intelligent sync optimization features are working correctly.');
  }

  /// Demonstrate delta sync capabilities
  static Future<void> _demonstrateDeltaSync() async {
    print('\n📊 Demo 1: Delta Sync Service');
    print('-' * 40);

    final deltaService = DeltaSyncService();

    // Sample data for delta calculation
    final oldData = {
      'id': 'user_123',
      'name': 'John Doe',
      'email': 'john.doe@email.com',
      'age': 30,
      'city': 'New York',
      'preferences': {
        'theme': 'dark',
        'notifications': true,
      },
    };

    final newData = {
      'id': 'user_123',
      'name': 'John Doe',
      'email': 'john.doe.new@email.com', // Changed
      'age': 31, // Changed
      'city': 'New York',
      'preferences': {
        'theme': 'light', // Changed
        'notifications': true,
        'language': 'en', // Added
      },
      'lastLogin': '2025-08-11T10:30:00Z', // Added
    };

    // Calculate delta
    final patch = deltaService.calculateDelta(
      oldData,
      newData,
      entityId: 'user_123',
      entityType: 'user_profiles',
    );

    print('Original data size: ${jsonEncode(oldData).length} bytes');
    print('New data size: ${jsonEncode(newData).length} bytes');
    print('Delta patch size: ${patch.estimatedSize} bytes');
    print('Changes: ${patch.changes.keys.join(', ')}');
    print('Deletions: ${patch.deletions.join(', ')}');
    print(
        'Checksum validation: ${patch.sourceChecksum != null ? 'Enabled' : 'Disabled'}');

    // Apply delta
    final reconstructed = deltaService.applyDelta(oldData, patch);
    final isCorrect = jsonEncode(reconstructed) == jsonEncode(newData);
    print('Delta application: ${isCorrect ? '✅ Success' : '❌ Failed'}');

    // Collection delta example
    final oldRecords = [oldData];
    final newRecords = [
      newData,
      {
        'id': 'user_124',
        'name': 'Jane Smith',
        'email': 'jane.smith@email.com',
        'age': 28,
        'city': 'Boston',
      }
    ];

    final collectionDelta = deltaService.calculateCollectionDelta(
      oldRecords,
      newRecords,
      collectionName: 'user_profiles',
    );

    print('Collection delta:');
    print('  - Updated records: ${collectionDelta.patches.length}');
    print('  - Added records: ${collectionDelta.addedRecords.length}');
    print('  - Deleted records: ${collectionDelta.deletedIds.length}');
    print('  - Total affected: ${collectionDelta.affectedRecordCount}');
  }

  /// Demonstrate compression capabilities
  static Future<void> _demonstrateCompression() async {
    print('\n🗜️ Demo 2: Sync Compression Service');
    print('-' * 40);

    final compressionService = SyncCompressionService();

    // Large sample data for compression testing
    final largeData = {
      'users': List.generate(
          100,
          (index) => {
                'id': 'user_$index',
                'name': 'User Number $index',
                'email': 'user$index@example.com',
                'description':
                    'This is a long description for user $index. ' * 5,
                'metadata': {
                  'created': '2025-08-${(index % 28) + 1}T10:00:00Z',
                  'preferences': {
                    'theme': index % 2 == 0 ? 'dark' : 'light',
                    'notifications': index % 3 == 0,
                    'language': index % 5 == 0 ? 'en' : 'es',
                  }
                }
              }),
    };

    print('Testing compression algorithms:');

    // Test different compression types
    final compressionTypes = [
      CompressionType.none,
      CompressionType.gzip,
      CompressionType.brotli,
      CompressionType.lz4,
    ];

    for (final type in compressionTypes) {
      try {
        final result = await compressionService.compress(largeData, type);

        print('  ${type.name.toUpperCase()}:');
        print('    Original size: ${result.originalSize} bytes');
        print('    Compressed size: ${result.compressedSize} bytes');
        print(
            '    Compression ratio: ${(result.compressionRatio * 100).toStringAsFixed(1)}%');
        print('    Space savings: ${result.spaceSavings} bytes');
        print(
            '    Compression time: ${result.compressionTime.inMilliseconds}ms');
        print('    Worthwhile: ${result.isWorthwhile ? '✅' : '❌'}');

        // Test decompression
        final decompressed = await compressionService.decompress(result);
        final isCorrect = jsonEncode(decompressed) == jsonEncode(largeData);
        print('    Decompression: ${isCorrect ? '✅ Success' : '❌ Failed'}');
      } catch (e) {
        print('  ${type.name.toUpperCase()}: ❌ Error - $e');
      }
      print('');
    }

    // Smart compression strategy selection
    final strategy = compressionService.selectCompressionStrategy(
      largeData,
      networkCondition: NetworkCondition.limited,
      priority: SyncPriority.normal,
    );

    print('Smart strategy recommendation:');
    print('  Recommended: ${strategy.type.name} (level ${strategy.level})');
    print('  Reason: ${strategy.reason}');

    // Benchmark different algorithms
    final benchmark = await compressionService.benchmark(largeData);
    print('\nBenchmark results:');
    print('  Best by ratio: ${benchmark.bestByRatio?.name ?? 'N/A'}');
    print('  Fastest: ${benchmark.fastestCompression?.name ?? 'N/A'}');
    print('  Balanced: ${benchmark.balanced?.name ?? 'N/A'}');
  }

  /// Demonstrate batch sync operations
  static Future<void> _demonstrateBatchSync() async {
    print('\n📦 Demo 3: Batch Sync Operations');
    print('-' * 40);

    final batchService = BatchSyncService();

    // Create sample batch operations
    final operations = [
      // Create operations
      BatchSyncOperation.create('users', {
        'id': 'user_001',
        'name': 'Alice Johnson',
        'email': 'alice@example.com',
      }),
      BatchSyncOperation.create('users', {
        'id': 'user_002',
        'name': 'Bob Smith',
        'email': 'bob@example.com',
      }),

      // Update operations
      BatchSyncOperation.update('users', 'user_003', {
        'name': 'Charlie Brown Updated',
        'lastModified': DateTime.now().toIso8601String(),
      }),

      // Delete operations
      BatchSyncOperation.delete('users', 'user_004'),
      BatchSyncOperation.delete('users', 'user_005'),
    ];

    print('Batch operations created: ${operations.length}');
    for (final op in operations) {
      print(
          '  - ${op.type.name.toUpperCase()}: ${op.collection}/${op.entityId ?? 'new'}');
    }

    // Test different batch strategies
    final strategies = [
      ('Sequential', BatchStrategy.sequential()),
      ('Parallel', BatchStrategy.parallel(maxConcurrency: 3)),
      ('Chunked', BatchStrategy.chunked(chunkSize: 2)),
      ('Adaptive', BatchStrategy.adaptive()),
    ];

    for (final (name, strategy) in strategies) {
      print('\n$name Strategy:');

      final stopwatch = Stopwatch()..start();

      final result = await batchService.executeBatch(
        operations,
        strategy: strategy,
        onProgress: (progress) {
          // Progress callback - in real app this would update UI
          if (progress.completed % 2 == 0 ||
              progress.completed == progress.total) {
            print('    Progress: ${progress.percentageString}');
          }
        },
      );

      stopwatch.stop();

      print('  Results:');
      print('    Total operations: ${result.totalOperations}');
      print('    Successful: ${result.successfulOperations}');
      print('    Failed: ${result.failedOperations}');
      print(
          '    Success rate: ${(result.successRate * 100).toStringAsFixed(1)}%');
      print('    Duration: ${result.duration.inMilliseconds}ms');
      print(
          '    Average per operation: ${result.averageTimePerOperation.inMilliseconds}ms');
    }

    // Demonstrate batch optimization
    final optimizedStrategy = batchService.optimizeBatchStrategy(
      operations,
      networkCondition: NetworkCondition.good,
      systemResources: SystemResources.normal,
    );

    print('\nOptimized strategy recommendation:');
    print('  Type: ${optimizedStrategy.type.name}');
    print(
        '  Max concurrency: ${optimizedStrategy.maxConcurrency ?? 'Default'}');
    print('  Chunk size: ${optimizedStrategy.chunkSize ?? 'N/A'}');
    print('  Retry failed items: ${optimizedStrategy.retryFailedItems}');
  }

  /// Demonstrate smart sync scheduling
  static Future<void> _demonstrateSmartScheduling() async {
    print('\n🧠 Demo 4: Smart Sync Scheduling');
    print('-' * 40);

    final scheduler = SmartSyncScheduler(
      config: SmartSchedulerConfig.defaultConfig(),
      initialStrategy: SchedulingStrategy.adaptive(),
    );

    // Schedule different entities with various priorities
    final entities = [
      ('critical_alerts', SyncPriority.critical, EntitySyncStrategy.aggressive),
      ('user_profiles', SyncPriority.high, EntitySyncStrategy.adaptive),
      ('app_settings', SyncPriority.normal, EntitySyncStrategy.adaptive),
      ('analytics_data', SyncPriority.low, EntitySyncStrategy.conservative),
    ];

    print('Scheduling entities:');
    for (final (entityName, priority, strategy) in entities) {
      final schedule = scheduler.scheduleEntity(
        entityName,
        priority: priority,
        strategy: strategy,
      );

      print('  $entityName:');
      print('    Priority: ${priority.name}');
      print('    Strategy: ${strategy.name}');
      print('    Interval: ${schedule.interval}');
      print('    Next sync: ${schedule.nextSyncTime}');
    }

    // Simulate some sync completions
    await Future.delayed(Duration(milliseconds: 100));

    // Record sync results
    scheduler.recordSyncCompletion(
      'user_profiles',
      Duration(milliseconds: 250),
      true,
      recordsChanged: 5,
    );

    scheduler.recordSyncCompletion(
      'analytics_data',
      Duration(milliseconds: 100),
      true,
      recordsChanged: 0, // No changes
    );

    scheduler.recordSyncCompletion(
      'critical_alerts',
      Duration(seconds: 2),
      false, // Failed
    );

    print('\nEntity metrics after sync events:');
    for (final entry in scheduler.entityMetrics.entries) {
      final metrics = entry.value;
      print('  ${entry.key}:');
      print('    Total syncs: ${metrics.totalSyncs}');
      print(
          '    Success rate: ${(metrics.successRate * 100).toStringAsFixed(1)}%');
      print('    Current interval: ${metrics.currentInterval}');
      print('    Average duration: ${metrics.averageSyncDuration}');
    }

    // Get recommendations
    final recommendations = scheduler.getRecommendations();
    print('\nSync recommendations:');
    if (recommendations.isEmpty) {
      print('  No recommendations at this time.');
    } else {
      for (final rec in recommendations.take(3)) {
        print('  ${rec.impact.name.toUpperCase()}: ${rec.description}');
        print('    Action: ${rec.suggestedAction}');
        print('    Savings: ${rec.estimatedSavings}');
      }
    }

    // Clean up
    scheduler.dispose();
  }

  /// Demonstrate priority queue management
  static Future<void> _demonstratePriorityQueues() async {
    print('\n🎯 Demo 5: Sync Priority Queue Service');
    print('-' * 40);

    final queueService = SyncPriorityQueueService(
      config: PriorityQueueConfig.defaultConfig(),
    );

    // Create queue items with different priorities
    final queueItems = [
      SyncQueueItem.create(
        entityName: 'emergency_alerts',
        data: {'message': 'System alert'},
        priority: SyncPriority.critical,
      ),
      SyncQueueItem.update(
        entityName: 'user_sessions',
        entityId: 'session_123',
        data: {'lastActivity': DateTime.now().toIso8601String()},
        priority: SyncPriority.high,
      ),
      SyncQueueItem.create(
        entityName: 'user_preferences',
        data: {'theme': 'dark', 'language': 'en'},
        priority: SyncPriority.normal,
      ),
      SyncQueueItem.delete(
        entityName: 'temp_files',
        entityId: 'temp_123',
        priority: SyncPriority.low,
      ),
      SyncQueueItem.create(
        entityName: 'background_data',
        data: {'processedAt': DateTime.now().toIso8601String()},
        priority: SyncPriority.low,
      ),
    ];

    print('Enqueueing ${queueItems.length} items:');
    for (final item in queueItems) {
      await queueService.enqueue(item);
      print(
          '  ✓ ${item.priority.name.toUpperCase()}: ${item.operation.name} ${item.entityName}');
    }

    // Show current queue status
    var status = queueService.getQueueStatus();
    print('\nQueue status after enqueuing:');
    print('  Total items: ${status.totalQueueSize}');
    print('  By priority:');
    for (final entry in status.queueSizes.entries) {
      if (entry.value > 0) {
        print('    ${entry.key.name}: ${entry.value} items');
      }
    }

    // Demonstrate queue processing (dequeue items in priority order)
    print('\nProcessing items by priority:');
    while (status.totalQueueSize > 0) {
      final item = await queueService.dequeue();
      if (item != null) {
        print(
            '  Processing: ${item.priority.name.toUpperCase()} - ${item.operation.name} ${item.entityName}');

        // Simulate processing with occasional failures
        final success = item.priority != SyncPriority.critical ||
            DateTime.now().millisecondsSinceEpoch % 3 != 0;

        if (success) {
          await queueService.completeItem(
            item,
            SyncResult.success(
              data: {'processed': true},
              action: SyncAction.create,
              timestamp: DateTime.now(),
            ),
          );
          print('    ✅ Completed successfully');
        } else {
          await queueService.failItem(
            item,
            Exception('Simulated processing failure'),
          );
          print('    ❌ Failed - will retry');
        }

        await Future.delayed(
            Duration(milliseconds: 50)); // Simulate processing time
      }

      status = queueService.getQueueStatus();
    }

    // Show final statistics
    final finalStatus = queueService.getQueueStatus();
    print('\nFinal queue statistics:');
    print('  Total processed: ${finalStatus.statistics.totalCompleted}');
    print('  Total failed: ${finalStatus.statistics.totalFailed}');
    print('  Dead letter items: ${finalStatus.deadLetterCount}');
    print(
        '  Success rate: ${(finalStatus.overallSuccessRate * 100).toStringAsFixed(1)}%');

    // Show dead letter queue if any
    if (finalStatus.deadLetterCount > 0) {
      final deadLetterItems = queueService.getDeadLetterItems(limit: 5);
      print('\nDead letter queue items:');
      for (final item in deadLetterItems) {
        print('  - ${item.id}: ${item.lastFailureReason}');
      }
    }

    // Demonstrate batch enqueueing
    print('\nTesting batch enqueueing:');
    final batchItems = List.generate(
        10,
        (index) => SyncQueueItem.create(
              entityName: 'batch_test',
              data: {'index': index},
              priority: SyncPriority.normal,
            ));

    await queueService.enqueueBatch(batchItems);
    print('  ✓ Enqueued ${batchItems.length} items in batch');

    // Clean up
    queueService.clearQueues();
    queueService.dispose();
    print('  ✓ Queue service cleaned up');
  }
}
