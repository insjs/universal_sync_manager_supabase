/// Sync Priority Queue Service for Universal Sync Manager
///
/// This service manages priority-based sync queues to ensure critical data
/// is synchronized first, while optimizing overall sync performance through
/// intelligent queue management and resource allocation.
library;

import 'dart:async';
import 'dart:collection';

import '../config/usm_sync_enums.dart';
import '../models/usm_sync_result.dart';

/// Service for managing priority-based sync queues
///
/// This service provides:
/// - Priority-based queue management for sync operations
/// - Resource allocation optimization based on priorities
/// - Dead letter queue handling for failed operations
/// - Queue analytics and monitoring
/// - Dynamic priority adjustment based on conditions
class SyncPriorityQueueService {
  /// Priority queues for different sync priorities
  final Map<SyncPriority, Queue<SyncQueueItem>> _priorityQueues = {
    SyncPriority.critical: Queue<SyncQueueItem>(),
    SyncPriority.high: Queue<SyncQueueItem>(),
    SyncPriority.normal: Queue<SyncQueueItem>(),
    SyncPriority.low: Queue<SyncQueueItem>(),
  };

  /// Dead letter queue for failed operations
  final Queue<SyncQueueItem> _deadLetterQueue = Queue<SyncQueueItem>();

  /// Currently processing items
  final Map<String, SyncQueueItem> _processingItems = {};

  /// Queue configuration
  final PriorityQueueConfig config;

  /// Stream controller for queue events
  final StreamController<QueueEvent> _eventController =
      StreamController<QueueEvent>.broadcast();

  /// Queue statistics
  final QueueStatistics _statistics = QueueStatistics();

  /// Timer for periodic queue processing
  Timer? _processingTimer;

  /// Concurrency semaphores per priority
  final Map<SyncPriority, Semaphore> _semaphores = {};

  /// Creates a new sync priority queue service
  SyncPriorityQueueService({
    PriorityQueueConfig? config,
  }) : config = config ?? PriorityQueueConfig.defaultConfig() {
    _initializeSemaphores();
    _startProcessing();
  }

  /// Stream of queue events
  Stream<QueueEvent> get queueEvents => _eventController.stream;

  /// Current queue statistics
  QueueStatistics get statistics => _statistics;

  /// Current queue sizes by priority
  Map<SyncPriority, int> get queueSizes => {
        for (final entry in _priorityQueues.entries)
          entry.key: entry.value.length,
      };

  /// Total number of items in all queues
  int get totalQueueSize => _priorityQueues.values
      .map((queue) => queue.length)
      .fold(0, (sum, size) => sum + size);

  /// Number of items currently being processed
  int get processingCount => _processingItems.length;

  /// Number of items in dead letter queue
  int get deadLetterCount => _deadLetterQueue.length;

  /// Enqueue a sync operation with specified priority
  ///
  /// Adds a sync operation to the appropriate priority queue.
  /// Higher priority items are processed first, with intelligent
  /// resource allocation to prevent priority inversion.
  ///
  /// Example:
  /// ```dart
  /// final item = SyncQueueItem.create(
  ///   entityName: 'user_profiles',
  ///   operation: SyncOperationType.update,
  ///   data: updatedUserData,
  ///   priority: SyncPriority.high,
  /// );
  ///
  /// await queueService.enqueue(item);
  /// ```
  Future<void> enqueue(SyncQueueItem item) async {
    // Validate item
    if (!_validateQueueItem(item)) {
      throw ArgumentError('Invalid queue item: ${item.id}');
    }

    // Check queue capacity
    if (!_hasCapacity(item.priority)) {
      // Try to make room by processing lower priority items or aging out old items
      await _makeRoom(item.priority);

      if (!_hasCapacity(item.priority)) {
        throw QueueCapacityException(
          'Queue capacity exceeded for priority ${item.priority.name}',
          item.priority,
        );
      }
    }

    // Apply dynamic priority adjustment if configured
    final adjustedPriority = _adjustPriorityDynamically(item);
    final finalItem = item.copyWith(priority: adjustedPriority);

    // Add to appropriate queue
    _priorityQueues[adjustedPriority]!.add(finalItem);

    // Update statistics
    _statistics.totalEnqueued++;
    _statistics.enqueuedByPriority[adjustedPriority] =
        (_statistics.enqueuedByPriority[adjustedPriority] ?? 0) + 1;

    // Emit event
    _emitEvent(QueueEvent(
      type: QueueEventType.itemEnqueued,
      item: finalItem,
      timestamp: DateTime.now(),
      metadata: {'originalPriority': item.priority.name},
    ));

    // Try to process immediately if resources are available
    _tryProcessNext();
  }

  /// Enqueue multiple items in a batch
  ///
  /// Efficiently adds multiple sync operations to their respective
  /// priority queues with batch optimization.
  Future<void> enqueueBatch(List<SyncQueueItem> items) async {
    if (items.isEmpty) return;

    final batchStartTime = DateTime.now();
    var successCount = 0;
    var failureCount = 0;

    for (final item in items) {
      try {
        await enqueue(item);
        successCount++;
      } catch (e) {
        failureCount++;
        // Continue with other items
      }
    }

    _emitEvent(QueueEvent(
      type: QueueEventType.batchEnqueued,
      item: null,
      timestamp: DateTime.now(),
      metadata: {
        'totalItems': items.length,
        'successCount': successCount,
        'failureCount': failureCount,
        'duration': DateTime.now().difference(batchStartTime).inMilliseconds,
      },
    ));
  }

  /// Dequeue and process the next highest priority item
  ///
  /// Removes and returns the next item to be processed based on
  /// priority and queue management strategy.
  Future<SyncQueueItem?> dequeue() async {
    SyncQueueItem? item;

    // Process in priority order
    for (final priority in SyncPriority.values.reversed) {
      final queue = _priorityQueues[priority]!;
      if (queue.isNotEmpty) {
        // Check if we have available semaphore slots for this priority
        final semaphore = _semaphores[priority]!;
        if (semaphore.availablePermits > 0) {
          item = queue.removeFirst();
          break;
        }
      }
    }

    if (item != null) {
      // Mark as processing
      _processingItems[item.id] = item;

      // Acquire semaphore
      await _semaphores[item.priority]!.acquire();

      // Update statistics
      _statistics.totalDequeued++;
      _statistics.dequeuedByPriority[item.priority] =
          (_statistics.dequeuedByPriority[item.priority] ?? 0) + 1;

      _emitEvent(QueueEvent(
        type: QueueEventType.itemDequeued,
        item: item,
        timestamp: DateTime.now(),
      ));
    }

    return item;
  }

  /// Complete processing of an item
  ///
  /// Marks an item as completed and updates queue state.
  /// Successful items are removed from tracking, failed items
  /// may be retried or moved to dead letter queue.
  Future<void> completeItem(
    SyncQueueItem item,
    SyncResult result, {
    bool wasSuccessful = true,
  }) async {
    // Remove from processing
    _processingItems.remove(item.id);

    // Release semaphore
    _semaphores[item.priority]!.release();

    if (wasSuccessful) {
      // Update success statistics
      _statistics.totalCompleted++;
      _statistics.completedByPriority[item.priority] =
          (_statistics.completedByPriority[item.priority] ?? 0) + 1;

      _emitEvent(QueueEvent(
        type: QueueEventType.itemCompleted,
        item: item,
        timestamp: DateTime.now(),
        metadata: {'result': result.toString()},
      ));
    } else {
      // Handle failure
      await _handleFailedItem(item, result);
    }

    // Try to process next item
    _tryProcessNext();
  }

  /// Fail an item and handle retry or dead letter queue logic
  ///
  /// Handles items that failed processing, implementing retry logic
  /// or moving to dead letter queue based on configuration.
  Future<void> failItem(
    SyncQueueItem item,
    Exception error, {
    bool canRetry = true,
  }) async {
    // Remove from processing
    _processingItems.remove(item.id);

    // Release semaphore
    _semaphores[item.priority]!.release();

    // Create failed result
    final failedResult = SyncResult.error(
      error: SyncError(
        message: error.toString(),
        type: SyncErrorType.unknown,
      ),
      action: SyncAction.create, // Default action
      timestamp: DateTime.now(),
    );

    await _handleFailedItem(item, failedResult, canRetry: canRetry);

    // Try to process next item
    _tryProcessNext();
  }

  /// Get current queue status for all priorities
  ///
  /// Returns detailed status information about all priority queues
  /// including counts, processing status, and performance metrics.
  QueueStatus getQueueStatus() {
    return QueueStatus(
      queueSizes: queueSizes,
      processingCount: processingCount,
      deadLetterCount: deadLetterCount,
      statistics: _statistics,
      averageWaitTimes: _calculateAverageWaitTimes(),
      throughputRates: _calculateThroughputRates(),
      timestamp: DateTime.now(),
    );
  }

  /// Clear all queues
  ///
  /// Removes all pending items from all priority queues.
  /// Processing items are allowed to complete.
  void clearQueues({List<SyncPriority>? priorities}) {
    final prioritiesToClear = priorities ?? SyncPriority.values;

    var totalCleared = 0;
    for (final priority in prioritiesToClear) {
      final queue = _priorityQueues[priority]!;
      totalCleared += queue.length;
      queue.clear();
    }

    _emitEvent(QueueEvent(
      type: QueueEventType.queueCleared,
      item: null,
      timestamp: DateTime.now(),
      metadata: {
        'clearedPriorities': prioritiesToClear.map((p) => p.name).toList(),
        'totalCleared': totalCleared,
      },
    ));
  }

  /// Pause queue processing
  ///
  /// Stops automatic processing of queue items.
  /// Currently processing items will complete.
  void pauseProcessing() {
    _processingTimer?.cancel();
    _processingTimer = null;

    _emitEvent(QueueEvent(
      type: QueueEventType.processingPaused,
      item: null,
      timestamp: DateTime.now(),
    ));
  }

  /// Resume queue processing
  ///
  /// Restarts automatic processing of queue items.
  void resumeProcessing() {
    if (_processingTimer == null) {
      _startProcessing();

      _emitEvent(QueueEvent(
        type: QueueEventType.processingResumed,
        item: null,
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Get items from dead letter queue
  ///
  /// Returns items that failed processing and were moved to
  /// the dead letter queue for manual review or reprocessing.
  List<SyncQueueItem> getDeadLetterItems({int? limit}) {
    final items = _deadLetterQueue.toList();
    if (limit != null && items.length > limit) {
      return items.take(limit).toList();
    }
    return items;
  }

  /// Requeue items from dead letter queue
  ///
  /// Moves items from dead letter queue back to appropriate
  /// priority queues for retry processing.
  Future<void> requeueDeadLetterItems(List<String> itemIds) async {
    final itemsToRequeue = <SyncQueueItem>[];
    final remainingItems = <SyncQueueItem>[];

    // Find items to requeue
    for (final item in _deadLetterQueue) {
      if (itemIds.contains(item.id)) {
        itemsToRequeue.add(item);
      } else {
        remainingItems.add(item);
      }
    }

    // Update dead letter queue
    _deadLetterQueue.clear();
    _deadLetterQueue.addAll(remainingItems);

    // Requeue items with reset retry count
    for (final item in itemsToRequeue) {
      final resetItem = item.copyWith(retryCount: 0);
      await enqueue(resetItem);
    }

    _emitEvent(QueueEvent(
      type: QueueEventType.deadLetterRequeued,
      item: null,
      timestamp: DateTime.now(),
      metadata: {
        'requeuedCount': itemsToRequeue.length,
        'itemIds': itemIds,
      },
    ));
  }

  /// Dispose the service and clean up resources
  void dispose() {
    _processingTimer?.cancel();
    _eventController.close();

    // Clear all queues
    for (final queue in _priorityQueues.values) {
      queue.clear();
    }
    _deadLetterQueue.clear();
    _processingItems.clear();
  }

  // Private implementation methods

  void _initializeSemaphores() {
    for (final priority in SyncPriority.values) {
      final maxConcurrency = _getMaxConcurrencyForPriority(priority);
      _semaphores[priority] = Semaphore(maxConcurrency);
    }
  }

  int _getMaxConcurrencyForPriority(SyncPriority priority) {
    switch (priority) {
      case SyncPriority.critical:
        return config.maxConcurrentCritical;
      case SyncPriority.high:
        return config.maxConcurrentHigh;
      case SyncPriority.normal:
        return config.maxConcurrentNormal;
      case SyncPriority.low:
        return config.maxConcurrentLow;
    }
  }

  void _startProcessing() {
    _processingTimer = Timer.periodic(config.processingInterval, (_) {
      _tryProcessNext();
    });
  }

  void _tryProcessNext() {
    // This would trigger the actual sync processing
    // The implementation would depend on the sync backend adapter
    // For now, we just emit an event to indicate processing should occur
    if (totalQueueSize > 0 && processingCount < config.maxTotalConcurrent) {
      _emitEvent(QueueEvent(
        type: QueueEventType.processingTriggered,
        item: null,
        timestamp: DateTime.now(),
        metadata: {
          'queueSize': totalQueueSize,
          'processingCount': processingCount,
        },
      ));
    }
  }

  bool _validateQueueItem(SyncQueueItem item) {
    // Basic validation
    if (item.id.isEmpty) return false;
    if (item.entityName.isEmpty) return false;
    return true;
  }

  bool _hasCapacity(SyncPriority priority) {
    final queue = _priorityQueues[priority]!;
    final maxSize = _getMaxQueueSizeForPriority(priority);
    return queue.length < maxSize;
  }

  int _getMaxQueueSizeForPriority(SyncPriority priority) {
    switch (priority) {
      case SyncPriority.critical:
        return config.maxQueueSizeCritical;
      case SyncPriority.high:
        return config.maxQueueSizeHigh;
      case SyncPriority.normal:
        return config.maxQueueSizeNormal;
      case SyncPriority.low:
        return config.maxQueueSizeLow;
    }
  }

  Future<void> _makeRoom(SyncPriority priority) async {
    // Try to process some items immediately
    for (int i = 0; i < 5 && totalQueueSize > 0; i++) {
      final item = await dequeue();
      if (item != null) {
        // Simulate quick processing for lower priority items
        if (item.priority.index < priority.index) {
          await completeItem(
              item,
              SyncResult.success(
                data: {},
                action: SyncAction.create,
                timestamp: DateTime.now(),
              ));
        } else {
          // Put it back
          _priorityQueues[item.priority]!.addFirst(item);
          _processingItems.remove(item.id);
          _semaphores[item.priority]!.release();
          break;
        }
      }
    }
  }

  SyncPriority _adjustPriorityDynamically(SyncQueueItem item) {
    if (!config.enableDynamicPriority) {
      return item.priority;
    }

    // Simple dynamic priority adjustment based on age and queue conditions
    final age = DateTime.now().difference(item.createdAt);

    // Increase priority for old items
    if (age > config.priorityAgeThreshold) {
      final currentIndex = item.priority.index;
      final newIndex =
          (currentIndex + 1).clamp(0, SyncPriority.values.length - 1);
      return SyncPriority.values[newIndex];
    }

    // Check if lower priority queues are overloaded
    if (item.priority != SyncPriority.critical) {
      final currentQueueSize = _priorityQueues[item.priority]!.length;
      final maxSize = _getMaxQueueSizeForPriority(item.priority);

      if (currentQueueSize > maxSize * 0.8) {
        // Queue is getting full, bump priority
        final currentIndex = item.priority.index;
        final newIndex =
            (currentIndex + 1).clamp(0, SyncPriority.values.length - 1);
        return SyncPriority.values[newIndex];
      }
    }

    return item.priority;
  }

  Future<void> _handleFailedItem(
    SyncQueueItem item,
    SyncResult result, {
    bool canRetry = true,
  }) async {
    final newRetryCount = item.retryCount + 1;

    // Update failure statistics
    _statistics.totalFailed++;
    _statistics.failedByPriority[item.priority] =
        (_statistics.failedByPriority[item.priority] ?? 0) + 1;

    if (canRetry && newRetryCount <= config.maxRetries) {
      // Retry with backoff
      final delay = _calculateRetryDelay(newRetryCount);

      final retryItem = item.copyWith(
        retryCount: newRetryCount,
        lastFailureReason: result.error?.message,
      );

      // Schedule retry
      Timer(delay, () async {
        await enqueue(retryItem);
      });

      _emitEvent(QueueEvent(
        type: QueueEventType.itemRetried,
        item: retryItem,
        timestamp: DateTime.now(),
        metadata: {
          'retryCount': newRetryCount,
          'delay': delay.inMilliseconds,
          'error': result.error?.message,
        },
      ));
    } else {
      // Move to dead letter queue
      final deadLetterItem = item.copyWith(
        retryCount: newRetryCount,
        lastFailureReason: result.error?.message,
      );

      _deadLetterQueue.add(deadLetterItem);
      _statistics.totalDeadLettered++;

      _emitEvent(QueueEvent(
        type: QueueEventType.itemDeadLettered,
        item: deadLetterItem,
        timestamp: DateTime.now(),
        metadata: {
          'finalRetryCount': newRetryCount,
          'error': result.error?.message,
        },
      ));
    }
  }

  Duration _calculateRetryDelay(int retryCount) {
    // Exponential backoff with jitter
    final baseDelay = config.baseRetryDelay.inMilliseconds;
    final backoffMultiplier = config.retryBackoffMultiplier;
    final maxDelay = config.maxRetryDelay.inMilliseconds;

    final delay = (baseDelay * (backoffMultiplier * retryCount))
        .round()
        .clamp(baseDelay, maxDelay);

    // Add jitter (±10%)
    final jitter = (delay * 0.1).round();
    final randomJitter = jitter -
        (jitter * 2 * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000)
            .round();

    return Duration(milliseconds: delay + randomJitter);
  }

  Map<SyncPriority, Duration> _calculateAverageWaitTimes() {
    // This would track actual wait times in a real implementation
    // For now, return estimated values based on queue sizes
    final waitTimes = <SyncPriority, Duration>{};

    for (final priority in SyncPriority.values) {
      final queueSize = _priorityQueues[priority]!.length;
      final processingRate = _getMaxConcurrencyForPriority(priority);
      final estimatedWait = Duration(
        seconds:
            processingRate > 0 ? (queueSize / processingRate * 5).round() : 0,
      );
      waitTimes[priority] = estimatedWait;
    }

    return waitTimes;
  }

  Map<SyncPriority, double> _calculateThroughputRates() {
    // This would calculate actual throughput in a real implementation
    // For now, return estimated values
    final throughput = <SyncPriority, double>{};

    for (final priority in SyncPriority.values) {
      final completed = _statistics.completedByPriority[priority] ?? 0;
      final timeSpan =
          DateTime.now().difference(_statistics.startTime).inMinutes;
      throughput[priority] = timeSpan > 0 ? completed / timeSpan : 0.0;
    }

    return throughput;
  }

  void _emitEvent(QueueEvent event) {
    _eventController.add(event);
  }
}

/// Configuration for priority queue service
class PriorityQueueConfig {
  /// Maximum concurrent operations per priority level
  final int maxConcurrentCritical;
  final int maxConcurrentHigh;
  final int maxConcurrentNormal;
  final int maxConcurrentLow;

  /// Maximum total concurrent operations
  final int maxTotalConcurrent;

  /// Maximum queue sizes per priority level
  final int maxQueueSizeCritical;
  final int maxQueueSizeHigh;
  final int maxQueueSizeNormal;
  final int maxQueueSizeLow;

  /// Retry configuration
  final int maxRetries;
  final Duration baseRetryDelay;
  final double retryBackoffMultiplier;
  final Duration maxRetryDelay;

  /// Processing interval for queue monitoring
  final Duration processingInterval;

  /// Dynamic priority adjustment
  final bool enableDynamicPriority;
  final Duration priorityAgeThreshold;

  /// Creates a new priority queue configuration
  const PriorityQueueConfig({
    this.maxConcurrentCritical = 5,
    this.maxConcurrentHigh = 3,
    this.maxConcurrentNormal = 2,
    this.maxConcurrentLow = 1,
    this.maxTotalConcurrent = 10,
    this.maxQueueSizeCritical = 100,
    this.maxQueueSizeHigh = 200,
    this.maxQueueSizeNormal = 500,
    this.maxQueueSizeLow = 1000,
    this.maxRetries = 3,
    this.baseRetryDelay = const Duration(seconds: 1),
    this.retryBackoffMultiplier = 2.0,
    this.maxRetryDelay = const Duration(minutes: 5),
    this.processingInterval = const Duration(milliseconds: 100),
    this.enableDynamicPriority = true,
    this.priorityAgeThreshold = const Duration(minutes: 10),
  });

  /// Default configuration with balanced settings
  factory PriorityQueueConfig.defaultConfig() {
    return const PriorityQueueConfig();
  }

  /// Configuration optimized for high throughput
  factory PriorityQueueConfig.highThroughput() {
    return const PriorityQueueConfig(
      maxConcurrentCritical: 10,
      maxConcurrentHigh: 8,
      maxConcurrentNormal: 5,
      maxConcurrentLow: 3,
      maxTotalConcurrent: 20,
      processingInterval: Duration(milliseconds: 50),
    );
  }

  /// Configuration optimized for resource conservation
  factory PriorityQueueConfig.resourceConservative() {
    return const PriorityQueueConfig(
      maxConcurrentCritical: 2,
      maxConcurrentHigh: 1,
      maxConcurrentNormal: 1,
      maxConcurrentLow: 1,
      maxTotalConcurrent: 3,
      processingInterval: Duration(milliseconds: 500),
    );
  }
}

/// Item in the sync priority queue
class SyncQueueItem {
  /// Unique identifier for this queue item
  final String id;

  /// Name of the entity to sync
  final String entityName;

  /// Type of sync operation
  final SyncOperationType operation;

  /// Data payload for the operation
  final Map<String, dynamic>? data;

  /// Priority of this operation
  final SyncPriority priority;

  /// When this item was created
  final DateTime createdAt;

  /// Number of retry attempts
  final int retryCount;

  /// Reason for last failure (if any)
  final String? lastFailureReason;

  /// Additional metadata
  final Map<String, dynamic> metadata;

  /// Creates a new sync queue item
  const SyncQueueItem({
    required this.id,
    required this.entityName,
    required this.operation,
    this.data,
    required this.priority,
    required this.createdAt,
    this.retryCount = 0,
    this.lastFailureReason,
    this.metadata = const {},
  });

  /// Create a new sync queue item for creating data
  factory SyncQueueItem.create({
    required String entityName,
    required Map<String, dynamic> data,
    SyncPriority priority = SyncPriority.normal,
    Map<String, dynamic>? metadata,
  }) {
    return SyncQueueItem(
      id: 'create_${entityName}_${DateTime.now().millisecondsSinceEpoch}',
      entityName: entityName,
      operation: SyncOperationType.create,
      data: data,
      priority: priority,
      createdAt: DateTime.now(),
      metadata: metadata ?? {},
    );
  }

  /// Create a new sync queue item for updating data
  factory SyncQueueItem.update({
    required String entityName,
    required String entityId,
    required Map<String, dynamic> data,
    SyncPriority priority = SyncPriority.normal,
    Map<String, dynamic>? metadata,
  }) {
    return SyncQueueItem(
      id: 'update_${entityName}_${entityId}_${DateTime.now().millisecondsSinceEpoch}',
      entityName: entityName,
      operation: SyncOperationType.update,
      data: {'id': entityId, ...data},
      priority: priority,
      createdAt: DateTime.now(),
      metadata: metadata ?? {},
    );
  }

  /// Create a new sync queue item for deleting data
  factory SyncQueueItem.delete({
    required String entityName,
    required String entityId,
    SyncPriority priority = SyncPriority.normal,
    Map<String, dynamic>? metadata,
  }) {
    return SyncQueueItem(
      id: 'delete_${entityName}_${entityId}_${DateTime.now().millisecondsSinceEpoch}',
      entityName: entityName,
      operation: SyncOperationType.delete,
      data: {'id': entityId},
      priority: priority,
      createdAt: DateTime.now(),
      metadata: metadata ?? {},
    );
  }

  /// Create a copy with modified properties
  SyncQueueItem copyWith({
    String? id,
    String? entityName,
    SyncOperationType? operation,
    Map<String, dynamic>? data,
    SyncPriority? priority,
    DateTime? createdAt,
    int? retryCount,
    String? lastFailureReason,
    Map<String, dynamic>? metadata,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      entityName: entityName ?? this.entityName,
      operation: operation ?? this.operation,
      data: data ?? this.data,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastFailureReason: lastFailureReason ?? this.lastFailureReason,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Age of this queue item
  Duration get age => DateTime.now().difference(createdAt);

  /// Whether this item has been retried
  bool get hasBeenRetried => retryCount > 0;

  @override
  String toString() {
    return 'SyncQueueItem(${operation.name}, $entityName, ${priority.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncQueueItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Event emitted by the priority queue service
class QueueEvent {
  /// Type of queue event
  final QueueEventType type;

  /// Associated queue item (if applicable)
  final SyncQueueItem? item;

  /// When the event occurred
  final DateTime timestamp;

  /// Additional event metadata
  final Map<String, dynamic>? metadata;

  /// Creates a new queue event
  const QueueEvent({
    required this.type,
    this.item,
    required this.timestamp,
    this.metadata,
  });

  @override
  String toString() {
    return 'QueueEvent(${type.name}, ${item?.id}, $timestamp)';
  }
}

/// Current status of the priority queues
class QueueStatus {
  /// Number of items in each priority queue
  final Map<SyncPriority, int> queueSizes;

  /// Number of items currently being processed
  final int processingCount;

  /// Number of items in dead letter queue
  final int deadLetterCount;

  /// Queue statistics
  final QueueStatistics statistics;

  /// Average wait times by priority
  final Map<SyncPriority, Duration> averageWaitTimes;

  /// Throughput rates by priority (items per minute)
  final Map<SyncPriority, double> throughputRates;

  /// When this status was captured
  final DateTime timestamp;

  /// Creates a new queue status
  const QueueStatus({
    required this.queueSizes,
    required this.processingCount,
    required this.deadLetterCount,
    required this.statistics,
    required this.averageWaitTimes,
    required this.throughputRates,
    required this.timestamp,
  });

  /// Total number of items in all queues
  int get totalQueueSize =>
      queueSizes.values.fold(0, (sum, size) => sum + size);

  /// Overall success rate
  double get overallSuccessRate {
    if (statistics.totalCompleted == 0) return 1.0;
    return statistics.totalCompleted /
        (statistics.totalCompleted + statistics.totalFailed);
  }

  @override
  String toString() {
    return 'QueueStatus(total: $totalQueueSize, processing: $processingCount, '
        'success rate: ${(overallSuccessRate * 100).toStringAsFixed(1)}%)';
  }
}

/// Statistics for queue operations
class QueueStatistics {
  /// When statistics collection started
  final DateTime startTime = DateTime.now();

  /// Total items enqueued
  int totalEnqueued = 0;

  /// Total items dequeued
  int totalDequeued = 0;

  /// Total items completed successfully
  int totalCompleted = 0;

  /// Total items that failed
  int totalFailed = 0;

  /// Total items moved to dead letter queue
  int totalDeadLettered = 0;

  /// Statistics by priority level
  final Map<SyncPriority, int> enqueuedByPriority = {};
  final Map<SyncPriority, int> dequeuedByPriority = {};
  final Map<SyncPriority, int> completedByPriority = {};
  final Map<SyncPriority, int> failedByPriority = {};

  /// Reset all statistics
  void reset() {
    totalEnqueued = 0;
    totalDequeued = 0;
    totalCompleted = 0;
    totalFailed = 0;
    totalDeadLettered = 0;
    enqueuedByPriority.clear();
    dequeuedByPriority.clear();
    completedByPriority.clear();
    failedByPriority.clear();
  }

  @override
  String toString() {
    return 'QueueStatistics(enqueued: $totalEnqueued, completed: $totalCompleted, '
        'failed: $totalFailed, dead letter: $totalDeadLettered)';
  }
}

/// Types of queue events
enum QueueEventType {
  /// Item was added to queue
  itemEnqueued,

  /// Multiple items were added to queue
  batchEnqueued,

  /// Item was removed from queue for processing
  itemDequeued,

  /// Item processing completed successfully
  itemCompleted,

  /// Item processing failed and will be retried
  itemRetried,

  /// Item was moved to dead letter queue
  itemDeadLettered,

  /// Items were requeued from dead letter queue
  deadLetterRequeued,

  /// Queue was cleared
  queueCleared,

  /// Processing was paused
  processingPaused,

  /// Processing was resumed
  processingResumed,

  /// Processing was triggered
  processingTriggered,
}

/// Simple semaphore implementation for concurrency control
class Semaphore {
  final int _maxPermits;
  int _availablePermits;
  final Queue<Completer<void>> _waitQueue = Queue<Completer<void>>();

  /// Creates a new semaphore with the specified number of permits
  Semaphore(this._maxPermits) : _availablePermits = _maxPermits;

  /// Number of available permits
  int get availablePermits => _availablePermits;

  /// Acquire a permit (wait if none available)
  Future<void> acquire() async {
    if (_availablePermits > 0) {
      _availablePermits--;
      return;
    }

    final completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }

  /// Release a permit
  void release() {
    if (_waitQueue.isNotEmpty) {
      final completer = _waitQueue.removeFirst();
      completer.complete();
    } else if (_availablePermits < _maxPermits) {
      _availablePermits++;
    }
  }
}

/// Exception thrown when queue capacity is exceeded
class QueueCapacityException implements Exception {
  /// Error message
  final String message;

  /// Priority level that exceeded capacity
  final SyncPriority priority;

  /// Creates a new queue capacity exception
  const QueueCapacityException(this.message, this.priority);

  @override
  String toString() =>
      'QueueCapacityException: $message (priority: ${priority.name})';
}
