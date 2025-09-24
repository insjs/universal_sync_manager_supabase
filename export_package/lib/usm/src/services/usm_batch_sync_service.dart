/// Batch Sync Operations Service for Universal Sync Manager
///
/// This service handles batch synchronization operations to improve
/// performance and reduce network overhead when syncing multiple
/// entities or large datasets simultaneously.
library;

import 'dart:async';
import 'dart:collection';
import 'dart:math';

import '../config/usm_sync_enums.dart';
import '../models/usm_sync_result.dart';

/// Service for handling batch synchronization operations
///
/// This service provides efficient batch processing capabilities including:
/// - Batch creation, update, and deletion operations
/// - Intelligent batching strategies based on data characteristics
/// - Progress tracking and error handling for batch operations
/// - Automatic retry mechanisms for failed batch items
class BatchSyncService {
  static const int _defaultBatchSize = 50;
  static const int _maxBatchSize = 1000;
  static const Duration _defaultBatchTimeout = Duration(seconds: 30);

  /// Creates a new batch sync service
  const BatchSyncService();

  /// Execute a batch of sync operations
  ///
  /// Processes multiple [operations] in batches, optimizing for performance
  /// and network efficiency. Returns a [BatchSyncResult] with detailed
  /// results for each operation.
  ///
  /// Example:
  /// ```dart
  /// final operations = [
  ///   BatchSyncOperation.create('users', userData1),
  ///   BatchSyncOperation.update('users', 'id1', userData2),
  ///   BatchSyncOperation.delete('users', 'id2'),
  /// ];
  ///
  /// final result = await service.executeBatch(
  ///   operations,
  ///   strategy: BatchStrategy.parallel(),
  /// );
  /// ```
  Future<BatchSyncResult> executeBatch(
    List<BatchSyncOperation> operations, {
    BatchStrategy? strategy,
    Function(BatchProgress)? onProgress,
    Duration? timeout,
  }) async {
    final batchStrategy = strategy ?? BatchStrategy.sequential();
    final batchTimeout = timeout ?? _defaultBatchTimeout;

    final results = <BatchSyncOperation, SyncResult>{};
    final errors = <BatchSyncOperation, Exception>{};
    final startTime = DateTime.now();

    try {
      switch (batchStrategy.type) {
        case BatchType.sequential:
          await _executeSequential(
            operations,
            results,
            errors,
            batchStrategy,
            onProgress,
          );
          break;
        case BatchType.parallel:
          await _executeParallel(
            operations,
            results,
            errors,
            batchStrategy,
            onProgress,
          );
          break;
        case BatchType.chunked:
          await _executeChunked(
            operations,
            results,
            errors,
            batchStrategy,
            onProgress,
          );
          break;
        case BatchType.adaptive:
          await _executeAdaptive(
            operations,
            results,
            errors,
            batchStrategy,
            onProgress,
          );
          break;
      }
    } on TimeoutException {
      throw BatchTimeoutException(
        'Batch operation timed out after ${batchTimeout.inSeconds} seconds',
        results.length,
        operations.length,
      );
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    return BatchSyncResult(
      totalOperations: operations.length,
      successfulOperations: results.length,
      failedOperations: errors.length,
      results: results,
      errors: errors,
      duration: duration,
      strategy: batchStrategy,
      timestamp: endTime,
    );
  }

  /// Optimize batching strategy based on operation characteristics
  ///
  /// Analyzes the [operations] and returns a recommended [BatchStrategy]
  /// based on factors like operation types, data sizes, and system resources.
  BatchStrategy optimizeBatchStrategy(
    List<BatchSyncOperation> operations, {
    NetworkCondition networkCondition = NetworkCondition.good,
    SystemResources systemResources = SystemResources.normal,
  }) {
    if (operations.isEmpty) {
      return BatchStrategy.sequential();
    }

    final totalOperations = operations.length;
    final hasLargeData = operations.any((op) => op.estimatedSize > 100000);
    final hasComplexOperations = operations
        .any((op) => op.type == SyncOperationType.create && op.data != null);

    // Small batches - execute sequentially for simplicity
    if (totalOperations <= 10) {
      return BatchStrategy.sequential(
        retryFailedItems: true,
        maxRetries: 3,
      );
    }

    // Large data or poor network - use chunked approach
    if (hasLargeData || networkCondition == NetworkCondition.limited) {
      final chunkSize = _calculateOptimalChunkSize(
        operations,
        networkCondition,
        systemResources,
      );

      return BatchStrategy.chunked(
        chunkSize: chunkSize,
        maxConcurrentChunks:
            networkCondition == NetworkCondition.limited ? 1 : 2,
        retryFailedItems: true,
        maxRetries: 2,
      );
    }

    // Many simple operations with good resources - use parallel
    if (!hasComplexOperations && systemResources != SystemResources.limited) {
      final maxConcurrency = _calculateMaxConcurrency(
        systemResources,
        networkCondition,
      );

      return BatchStrategy.parallel(
        maxConcurrency: maxConcurrency,
        retryFailedItems: true,
        maxRetries: 3,
      );
    }

    // Default to adaptive strategy
    return BatchStrategy.adaptive(
      initialChunkSize: min(totalOperations ~/ 4, 25),
      maxConcurrency: 3,
      retryFailedItems: true,
      maxRetries: 2,
    );
  }

  /// Create a batch of create operations
  ///
  /// Helper method to easily create multiple records of the same type.
  List<BatchSyncOperation> createBatch(
    String collection,
    List<Map<String, dynamic>> records, {
    SyncPriority priority = SyncPriority.normal,
    Map<String, dynamic>? metadata,
  }) {
    return records
        .map((record) => BatchSyncOperation.create(
              collection,
              record,
              priority: priority,
              metadata: metadata,
            ))
        .toList();
  }

  /// Create a batch of update operations
  ///
  /// Helper method to easily update multiple records of the same type.
  List<BatchSyncOperation> updateBatch(
    String collection,
    Map<String, Map<String, dynamic>> updates, {
    SyncPriority priority = SyncPriority.normal,
    Map<String, dynamic>? metadata,
  }) {
    return updates.entries
        .map((entry) => BatchSyncOperation.update(
              collection,
              entry.key,
              entry.value,
              priority: priority,
              metadata: metadata,
            ))
        .toList();
  }

  /// Create a batch of delete operations
  ///
  /// Helper method to easily delete multiple records of the same type.
  List<BatchSyncOperation> deleteBatch(
    String collection,
    List<String> ids, {
    SyncPriority priority = SyncPriority.normal,
    Map<String, dynamic>? metadata,
  }) {
    return ids
        .map((id) => BatchSyncOperation.delete(
              collection,
              id,
              priority: priority,
              metadata: metadata,
            ))
        .toList();
  }

  // Private execution methods

  Future<void> _executeSequential(
    List<BatchSyncOperation> operations,
    Map<BatchSyncOperation, SyncResult> results,
    Map<BatchSyncOperation, Exception> errors,
    BatchStrategy strategy,
    Function(BatchProgress)? onProgress,
  ) async {
    for (int i = 0; i < operations.length; i++) {
      final operation = operations[i];

      try {
        final result = await _executeSingleOperation(operation);
        results[operation] = result;
      } catch (e) {
        errors[operation] = e is Exception ? e : Exception(e.toString());

        if (!strategy.continueOnError) {
          break;
        }
      }

      onProgress?.call(BatchProgress(
        completed: i + 1,
        total: operations.length,
        currentOperation: operation,
      ));
    }

    // Retry failed operations if enabled
    if (strategy.retryFailedItems && errors.isNotEmpty) {
      await _retryFailedOperations(
        errors.keys.toList(),
        results,
        errors,
        strategy,
        onProgress,
      );
    }
  }

  Future<void> _executeParallel(
    List<BatchSyncOperation> operations,
    Map<BatchSyncOperation, SyncResult> results,
    Map<BatchSyncOperation, Exception> errors,
    BatchStrategy strategy,
    Function(BatchProgress)? onProgress,
  ) async {
    final maxConcurrency = strategy.maxConcurrency ?? 5;
    final semaphore = Semaphore(maxConcurrency);
    final futures = <Future<void>>[];

    for (final operation in operations) {
      final future = semaphore.acquire().then((_) async {
        try {
          final result = await _executeSingleOperation(operation);
          results[operation] = result;
        } catch (e) {
          errors[operation] = e is Exception ? e : Exception(e.toString());
        } finally {
          semaphore.release();

          onProgress?.call(BatchProgress(
            completed: results.length + errors.length,
            total: operations.length,
            currentOperation: operation,
          ));
        }
      });

      futures.add(future);
    }

    await Future.wait(futures);

    // Retry failed operations if enabled
    if (strategy.retryFailedItems && errors.isNotEmpty) {
      await _retryFailedOperations(
        errors.keys.toList(),
        results,
        errors,
        strategy,
        onProgress,
      );
    }
  }

  Future<void> _executeChunked(
    List<BatchSyncOperation> operations,
    Map<BatchSyncOperation, SyncResult> results,
    Map<BatchSyncOperation, Exception> errors,
    BatchStrategy strategy,
    Function(BatchProgress)? onProgress,
  ) async {
    final chunkSize = strategy.chunkSize ?? _defaultBatchSize;
    final maxConcurrentChunks = strategy.maxConcurrentChunks ?? 2;

    final chunks = <List<BatchSyncOperation>>[];
    for (int i = 0; i < operations.length; i += chunkSize) {
      final end = min(i + chunkSize, operations.length);
      chunks.add(operations.sublist(i, end));
    }

    final semaphore = Semaphore(maxConcurrentChunks);
    final futures = <Future<void>>[];

    for (final chunk in chunks) {
      final future = semaphore.acquire().then((_) async {
        try {
          await _executeSequential(
              chunk, results, errors, strategy, onProgress);
        } finally {
          semaphore.release();
        }
      });

      futures.add(future);
    }

    await Future.wait(futures);
  }

  Future<void> _executeAdaptive(
    List<BatchSyncOperation> operations,
    Map<BatchSyncOperation, SyncResult> results,
    Map<BatchSyncOperation, Exception> errors,
    BatchStrategy strategy,
    Function(BatchProgress)? onProgress,
  ) async {
    // Start with initial strategy and adapt based on performance
    var currentChunkSize = strategy.initialChunkSize ?? 20;
    var currentConcurrency = strategy.maxConcurrency ?? 3;
    var remainingOperations = List<BatchSyncOperation>.from(operations);

    final performanceMetrics = <Duration>[];

    while (remainingOperations.isNotEmpty) {
      final chunkSize = min(currentChunkSize, remainingOperations.length);
      final chunk = remainingOperations.take(chunkSize).toList();
      remainingOperations = remainingOperations.skip(chunkSize).toList();

      final stopwatch = Stopwatch()..start();

      if (currentConcurrency > 1) {
        await _executeParallel(chunk, results, errors, strategy, onProgress);
      } else {
        await _executeSequential(chunk, results, errors, strategy, onProgress);
      }

      stopwatch.stop();
      performanceMetrics.add(stopwatch.elapsed);

      // Adapt strategy based on performance
      if (performanceMetrics.length >= 2) {
        final avgTime = performanceMetrics.last.inMilliseconds / chunkSize;
        final previousAvgTime =
            performanceMetrics[performanceMetrics.length - 2].inMilliseconds /
                chunkSize;

        // If performance is getting worse, reduce concurrency/chunk size
        if (avgTime > previousAvgTime * 1.2) {
          currentConcurrency = max(1, currentConcurrency - 1);
          currentChunkSize = max(5, (currentChunkSize * 0.8).round());
        }
        // If performance is good, try to increase throughput
        else if (avgTime < previousAvgTime * 0.8) {
          currentConcurrency =
              min(strategy.maxConcurrency ?? 5, currentConcurrency + 1);
          currentChunkSize =
              min(_maxBatchSize, (currentChunkSize * 1.2).round());
        }
      }
    }
  }

  Future<void> _retryFailedOperations(
    List<BatchSyncOperation> failedOperations,
    Map<BatchSyncOperation, SyncResult> results,
    Map<BatchSyncOperation, Exception> errors,
    BatchStrategy strategy,
    Function(BatchProgress)? onProgress,
  ) async {
    final maxRetries = strategy.maxRetries ?? 3;
    final retryableOperations = List<BatchSyncOperation>.from(failedOperations);

    for (int retry = 1;
        retry <= maxRetries && retryableOperations.isNotEmpty;
        retry++) {
      final currentRetryOperations =
          List<BatchSyncOperation>.from(retryableOperations);
      retryableOperations.clear();

      for (final operation in currentRetryOperations) {
        try {
          // Exponential backoff delay
          await Future.delayed(
              Duration(milliseconds: 100 * pow(2, retry - 1).toInt()));

          final result = await _executeSingleOperation(operation);
          results[operation] = result;
          errors.remove(operation);
        } catch (e) {
          // Keep in retry list for next attempt
          retryableOperations.add(operation);
          errors[operation] = e is Exception ? e : Exception(e.toString());
        }
      }
    }
  }

  Future<SyncResult> _executeSingleOperation(
      BatchSyncOperation operation) async {
    // This would be implemented by the actual sync backend adapter
    // For now, we'll simulate the operation
    await Future.delayed(Duration(milliseconds: 10 + Random().nextInt(90)));

    // Simulate occasional failures
    if (Random().nextInt(100) < 5) {
      // 5% failure rate
      throw Exception('Simulated sync failure for ${operation.type}');
    }

    return SyncResult.success(
      data: {'id': operation.entityId ?? 'generated-id'},
      action: SyncAction.create, // Convert operation type to sync action
      timestamp: DateTime.now(),
    );
  }

  int _calculateOptimalChunkSize(
    List<BatchSyncOperation> operations,
    NetworkCondition networkCondition,
    SystemResources systemResources,
  ) {
    final baseSize = networkCondition == NetworkCondition.limited ? 10 : 50;
    final avgDataSize =
        operations.map((op) => op.estimatedSize).fold(0, (a, b) => a + b) /
            operations.length;

    // Adjust based on data size
    if (avgDataSize > 50000) {
      return max(5, baseSize ~/ 4);
    } else if (avgDataSize > 10000) {
      return max(10, baseSize ~/ 2);
    }

    return min(_maxBatchSize, baseSize);
  }

  int _calculateMaxConcurrency(
    SystemResources systemResources,
    NetworkCondition networkCondition,
  ) {
    final baseConn = switch (networkCondition) {
      NetworkCondition.limited => 2,
      NetworkCondition.good => 4,
      NetworkCondition.excellent => 8,
      NetworkCondition.offline => 1,
      NetworkCondition.highSpeed => 8,
      NetworkCondition.mediumSpeed => 4,
      NetworkCondition.lowSpeed => 2,
      NetworkCondition.unknown => 2,
    };

    return switch (systemResources) {
      SystemResources.limited => max(1, baseConn ~/ 2),
      SystemResources.normal => baseConn,
      SystemResources.high => min(10, baseConn * 2),
    };
  }
}

/// Represents a single operation in a batch
class BatchSyncOperation {
  /// Type of sync operation
  final SyncOperationType type;

  /// Collection/table name
  final String collection;

  /// Entity ID (for update/delete operations)
  final String? entityId;

  /// Data payload (for create/update operations)
  final Map<String, dynamic>? data;

  /// Priority of this operation
  final SyncPriority priority;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  /// Creates a new batch sync operation
  const BatchSyncOperation({
    required this.type,
    required this.collection,
    this.entityId,
    this.data,
    this.priority = SyncPriority.normal,
    this.metadata,
  });

  /// Create a new record operation
  factory BatchSyncOperation.create(
    String collection,
    Map<String, dynamic> data, {
    SyncPriority priority = SyncPriority.normal,
    Map<String, dynamic>? metadata,
  }) {
    return BatchSyncOperation(
      type: SyncOperationType.create,
      collection: collection,
      data: data,
      priority: priority,
      metadata: metadata,
    );
  }

  /// Update existing record operation
  factory BatchSyncOperation.update(
    String collection,
    String entityId,
    Map<String, dynamic> data, {
    SyncPriority priority = SyncPriority.normal,
    Map<String, dynamic>? metadata,
  }) {
    return BatchSyncOperation(
      type: SyncOperationType.update,
      collection: collection,
      entityId: entityId,
      data: data,
      priority: priority,
      metadata: metadata,
    );
  }

  /// Delete record operation
  factory BatchSyncOperation.delete(
    String collection,
    String entityId, {
    SyncPriority priority = SyncPriority.normal,
    Map<String, dynamic>? metadata,
  }) {
    return BatchSyncOperation(
      type: SyncOperationType.delete,
      collection: collection,
      entityId: entityId,
      priority: priority,
      metadata: metadata,
    );
  }

  /// Estimated size of this operation in bytes
  int get estimatedSize {
    if (data == null) return 100; // Base size for delete operations
    return data.toString().length * 2; // Rough estimate
  }

  @override
  String toString() {
    return 'BatchSyncOperation(${type.name}, $collection, $entityId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BatchSyncOperation &&
        other.type == type &&
        other.collection == collection &&
        other.entityId == entityId;
  }

  @override
  int get hashCode {
    return Object.hash(type, collection, entityId);
  }
}

/// Strategy for executing batch operations
class BatchStrategy {
  /// Type of batching strategy
  final BatchType type;

  /// Maximum number of concurrent operations (for parallel strategies)
  final int? maxConcurrency;

  /// Size of each chunk (for chunked strategies)
  final int? chunkSize;

  /// Maximum number of concurrent chunks (for chunked strategies)
  final int? maxConcurrentChunks;

  /// Whether to continue processing after errors
  final bool continueOnError;

  /// Whether to retry failed operations
  final bool retryFailedItems;

  /// Maximum number of retries for failed operations
  final int? maxRetries;

  /// Initial chunk size for adaptive strategies
  final int? initialChunkSize;

  /// Creates a new batch strategy
  const BatchStrategy({
    required this.type,
    this.maxConcurrency,
    this.chunkSize,
    this.maxConcurrentChunks,
    this.continueOnError = true,
    this.retryFailedItems = true,
    this.maxRetries,
    this.initialChunkSize,
  });

  /// Sequential processing strategy
  factory BatchStrategy.sequential({
    bool continueOnError = true,
    bool retryFailedItems = true,
    int maxRetries = 3,
  }) {
    return BatchStrategy(
      type: BatchType.sequential,
      continueOnError: continueOnError,
      retryFailedItems: retryFailedItems,
      maxRetries: maxRetries,
    );
  }

  /// Parallel processing strategy
  factory BatchStrategy.parallel({
    int maxConcurrency = 5,
    bool continueOnError = true,
    bool retryFailedItems = true,
    int maxRetries = 3,
  }) {
    return BatchStrategy(
      type: BatchType.parallel,
      maxConcurrency: maxConcurrency,
      continueOnError: continueOnError,
      retryFailedItems: retryFailedItems,
      maxRetries: maxRetries,
    );
  }

  /// Chunked processing strategy
  factory BatchStrategy.chunked({
    int chunkSize = 25,
    int maxConcurrentChunks = 2,
    bool continueOnError = true,
    bool retryFailedItems = true,
    int maxRetries = 2,
  }) {
    return BatchStrategy(
      type: BatchType.chunked,
      chunkSize: chunkSize,
      maxConcurrentChunks: maxConcurrentChunks,
      continueOnError: continueOnError,
      retryFailedItems: retryFailedItems,
      maxRetries: maxRetries,
    );
  }

  /// Adaptive processing strategy
  factory BatchStrategy.adaptive({
    int initialChunkSize = 20,
    int maxConcurrency = 3,
    bool continueOnError = true,
    bool retryFailedItems = true,
    int maxRetries = 2,
  }) {
    return BatchStrategy(
      type: BatchType.adaptive,
      initialChunkSize: initialChunkSize,
      maxConcurrency: maxConcurrency,
      continueOnError: continueOnError,
      retryFailedItems: retryFailedItems,
      maxRetries: maxRetries,
    );
  }

  @override
  String toString() {
    return 'BatchStrategy(${type.name})';
  }
}

/// Progress information for batch operations
class BatchProgress {
  /// Number of completed operations
  final int completed;

  /// Total number of operations
  final int total;

  /// Currently processing operation
  final BatchSyncOperation? currentOperation;

  /// Creates new batch progress information
  const BatchProgress({
    required this.completed,
    required this.total,
    this.currentOperation,
  });

  /// Progress as a percentage (0.0 to 1.0)
  double get percentage => total > 0 ? completed / total : 0.0;

  /// Progress as a percentage string
  String get percentageString => '${(percentage * 100).toStringAsFixed(1)}%';

  @override
  String toString() {
    return 'BatchProgress($completed/$total - $percentageString)';
  }
}

/// Result of a batch sync operation
class BatchSyncResult {
  /// Total number of operations in the batch
  final int totalOperations;

  /// Number of successful operations
  final int successfulOperations;

  /// Number of failed operations
  final int failedOperations;

  /// Results for successful operations
  final Map<BatchSyncOperation, SyncResult> results;

  /// Errors for failed operations
  final Map<BatchSyncOperation, Exception> errors;

  /// Time taken to complete the batch
  final Duration duration;

  /// Strategy used for the batch
  final BatchStrategy strategy;

  /// When the batch was completed
  final DateTime timestamp;

  /// Creates a new batch sync result
  const BatchSyncResult({
    required this.totalOperations,
    required this.successfulOperations,
    required this.failedOperations,
    required this.results,
    required this.errors,
    required this.duration,
    required this.strategy,
    required this.timestamp,
  });

  /// Success rate as a percentage
  double get successRate =>
      totalOperations > 0 ? successfulOperations / totalOperations : 0.0;

  /// Whether the batch was completely successful
  bool get isSuccess => failedOperations == 0;

  /// Whether the batch had any successful operations
  bool get hasAnySuccess => successfulOperations > 0;

  /// Average time per operation
  Duration get averageTimePerOperation {
    if (totalOperations == 0) return Duration.zero;
    return Duration(microseconds: duration.inMicroseconds ~/ totalOperations);
  }

  @override
  String toString() {
    return 'BatchSyncResult(total: $totalOperations, success: $successfulOperations, '
        'failed: $failedOperations, duration: ${duration.inMilliseconds}ms)';
  }
}

/// Simple semaphore implementation for concurrency control
class Semaphore {
  final int _maxCount;
  int _currentCount;
  final Queue<Completer<void>> _waitQueue = Queue<Completer<void>>();

  Semaphore(this._maxCount) : _currentCount = _maxCount;

  Future<void> acquire() async {
    if (_currentCount > 0) {
      _currentCount--;
      return;
    }

    final completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }

  void release() {
    if (_waitQueue.isNotEmpty) {
      final completer = _waitQueue.removeFirst();
      completer.complete();
    } else if (_currentCount < _maxCount) {
      _currentCount++;
    }
  }
}

/// Exception thrown when batch operations timeout
class BatchTimeoutException implements Exception {
  /// Error message
  final String message;

  /// Number of completed operations before timeout
  final int completedOperations;

  /// Total number of operations in the batch
  final int totalOperations;

  /// Creates a new batch timeout exception
  const BatchTimeoutException(
    this.message,
    this.completedOperations,
    this.totalOperations,
  );

  @override
  String toString() {
    return 'BatchTimeoutException: $message ($completedOperations/$totalOperations completed)';
  }
}
