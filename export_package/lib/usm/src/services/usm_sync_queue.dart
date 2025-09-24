import 'dart:collection';
import 'dart:async';

import '../interfaces/usm_sync_backend_adapter.dart';
import '../config/usm_sync_enums.dart';

/// Represents a pending sync operation in the queue
class SyncOperation {
  final String id;
  final String collection;
  final SyncOperationType type;
  final Map<String, dynamic>? data;
  final List<Map<String, dynamic>>? batchData;
  final String? entityId;
  final SyncQuery? query;
  final SyncPriority priority;
  final DateTime createdAt;
  final int retryCount;
  final Duration? retryDelay;
  final Map<String, dynamic> metadata;

  const SyncOperation({
    required this.id,
    required this.collection,
    required this.type,
    this.data,
    this.batchData,
    this.entityId,
    this.query,
    this.priority = SyncPriority.normal,
    required this.createdAt,
    this.retryCount = 0,
    this.retryDelay,
    this.metadata = const {},
  });

  SyncOperation copyWith({
    String? id,
    String? collection,
    SyncOperationType? type,
    Map<String, dynamic>? data,
    List<Map<String, dynamic>>? batchData,
    String? entityId,
    SyncQuery? query,
    SyncPriority? priority,
    DateTime? createdAt,
    int? retryCount,
    Duration? retryDelay,
    Map<String, dynamic>? metadata,
  }) {
    return SyncOperation(
      id: id ?? this.id,
      collection: collection ?? this.collection,
      type: type ?? this.type,
      data: data ?? this.data,
      batchData: batchData ?? this.batchData,
      entityId: entityId ?? this.entityId,
      query: query ?? this.query,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      retryDelay: retryDelay ?? this.retryDelay,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'SyncOperation(id: $id, collection: $collection, type: $type, priority: $priority, retryCount: $retryCount)';
  }
}

/// Manages a queue of pending sync operations with priority-based processing
class SyncQueue {
  final Queue<SyncOperation> _criticalQueue = Queue<SyncOperation>();
  final Queue<SyncOperation> _highQueue = Queue<SyncOperation>();
  final Queue<SyncOperation> _normalQueue = Queue<SyncOperation>();
  final Queue<SyncOperation> _lowQueue = Queue<SyncOperation>();
  final Map<String, SyncOperation> _operationMap = {};

  final StreamController<SyncOperation> _operationAddedController =
      StreamController<SyncOperation>.broadcast();
  final StreamController<SyncOperation> _operationProcessedController =
      StreamController<SyncOperation>.broadcast();
  final StreamController<int> _queueSizeController =
      StreamController<int>.broadcast();

  /// Stream of operations added to the queue
  Stream<SyncOperation> get operationAdded => _operationAddedController.stream;

  /// Stream of operations that have been processed
  Stream<SyncOperation> get operationProcessed =>
      _operationProcessedController.stream;

  /// Stream of queue size changes
  Stream<int> get queueSizeChanged => _queueSizeController.stream;

  /// Adds an operation to the queue based on its priority
  void enqueue(SyncOperation operation) {
    // Remove existing operation with same ID if it exists
    if (_operationMap.containsKey(operation.id)) {
      _removeOperationById(operation.id);
    }

    _operationMap[operation.id] = operation;

    switch (operation.priority) {
      case SyncPriority.critical:
        _criticalQueue.add(operation);
        break;
      case SyncPriority.high:
        _highQueue.add(operation);
        break;
      case SyncPriority.normal:
        _normalQueue.add(operation);
        break;
      case SyncPriority.low:
        _lowQueue.add(operation);
        break;
    }

    _operationAddedController.add(operation);
    _queueSizeController.add(size);
  }

  /// Removes and returns the next operation to process (highest priority first)
  SyncOperation? dequeue() {
    SyncOperation? operation;

    if (_criticalQueue.isNotEmpty) {
      operation = _criticalQueue.removeFirst();
    } else if (_highQueue.isNotEmpty) {
      operation = _highQueue.removeFirst();
    } else if (_normalQueue.isNotEmpty) {
      operation = _normalQueue.removeFirst();
    } else if (_lowQueue.isNotEmpty) {
      operation = _lowQueue.removeFirst();
    }

    if (operation != null) {
      _operationMap.remove(operation.id);
      _operationProcessedController.add(operation);
      _queueSizeController.add(size);
    }

    return operation;
  }

  /// Peeks at the next operation without removing it
  SyncOperation? peek() {
    if (_criticalQueue.isNotEmpty) {
      return _criticalQueue.first;
    } else if (_highQueue.isNotEmpty) {
      return _highQueue.first;
    } else if (_normalQueue.isNotEmpty) {
      return _normalQueue.first;
    } else if (_lowQueue.isNotEmpty) {
      return _lowQueue.first;
    }
    return null;
  }

  /// Removes an operation by ID from the queue
  bool removeOperation(String operationId) {
    return _removeOperationById(operationId);
  }

  bool _removeOperationById(String operationId) {
    final operation = _operationMap[operationId];
    if (operation == null) return false;

    _operationMap.remove(operationId);

    bool removed = false;
    switch (operation.priority) {
      case SyncPriority.critical:
        removed = _removeFromQueue(_criticalQueue, operationId);
        break;
      case SyncPriority.high:
        removed = _removeFromQueue(_highQueue, operationId);
        break;
      case SyncPriority.normal:
        removed = _removeFromQueue(_normalQueue, operationId);
        break;
      case SyncPriority.low:
        removed = _removeFromQueue(_lowQueue, operationId);
        break;
    }

    if (removed) {
      _queueSizeController.add(size);
    }

    return removed;
  }

  bool _removeFromQueue(Queue<SyncOperation> queue, String operationId) {
    final tempList = <SyncOperation>[];
    bool found = false;

    while (queue.isNotEmpty) {
      final operation = queue.removeFirst();
      if (operation.id == operationId) {
        found = true;
      } else {
        tempList.add(operation);
      }
    }

    // Add back all operations except the one we removed
    for (final operation in tempList) {
      queue.add(operation);
    }

    return found;
  }

  /// Gets an operation by ID
  SyncOperation? getOperation(String operationId) {
    return _operationMap[operationId];
  }

  /// Returns all operations in the queue (prioritized order)
  List<SyncOperation> getAllOperations() {
    final allOperations = <SyncOperation>[];
    allOperations.addAll(_criticalQueue);
    allOperations.addAll(_highQueue);
    allOperations.addAll(_normalQueue);
    allOperations.addAll(_lowQueue);
    return allOperations;
  }

  /// Returns operations for a specific collection
  List<SyncOperation> getOperationsForCollection(String collection) {
    return _operationMap.values
        .where((op) => op.collection == collection)
        .toList();
  }

  /// Returns operations by priority
  List<SyncOperation> getOperationsByPriority(SyncPriority priority) {
    switch (priority) {
      case SyncPriority.critical:
        return List.from(_criticalQueue);
      case SyncPriority.high:
        return List.from(_highQueue);
      case SyncPriority.normal:
        return List.from(_normalQueue);
      case SyncPriority.low:
        return List.from(_lowQueue);
    }
  }

  /// Clears all operations from the queue
  void clear() {
    _criticalQueue.clear();
    _highQueue.clear();
    _normalQueue.clear();
    _lowQueue.clear();
    _operationMap.clear();
    _queueSizeController.add(0);
  }

  /// Clears operations for a specific collection
  void clearCollection(String collection) {
    final operationsToRemove = _operationMap.values
        .where((op) => op.collection == collection)
        .map((op) => op.id)
        .toList();

    for (final operationId in operationsToRemove) {
      removeOperation(operationId);
    }
  }

  /// Total number of operations in the queue
  int get size => _operationMap.length;

  /// Number of operations by priority
  Map<SyncPriority, int> get sizeByPriority => {
        SyncPriority.critical: _criticalQueue.length,
        SyncPriority.high: _highQueue.length,
        SyncPriority.normal: _normalQueue.length,
        SyncPriority.low: _lowQueue.length,
      };

  /// Checks if the queue is empty
  bool get isEmpty => size == 0;

  /// Checks if the queue has operations
  bool get isNotEmpty => size > 0;

  /// Dispose method to clean up resources
  void dispose() {
    clear();
    _operationAddedController.close();
    _operationProcessedController.close();
    _queueSizeController.close();
  }
}
