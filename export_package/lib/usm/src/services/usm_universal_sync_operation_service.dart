import 'dart:async';

import '../interfaces/usm_sync_backend_adapter.dart';
import '../models/usm_sync_result.dart';
import '../config/usm_sync_enums.dart';
import 'usm_sync_queue.dart';
import 'usm_conflict_resolver.dart';
import 'usm_enhanced_conflict_resolver.dart';
import 'usm_enhanced_conflict_resolution_manager.dart';
import 'usm_sync_scheduler.dart';
import 'usm_sync_event_bus.dart';

/// Configuration for sync operations
class SyncOperationConfig {
  final int maxConcurrentOperations;
  final Duration operationTimeout;
  final bool enableBatchOperations;
  final int batchSize;
  final bool enableConflictResolution;
  final bool enableRetryOnFailure;
  final bool enableEventPublishing;
  final Duration progressUpdateInterval;

  const SyncOperationConfig({
    this.maxConcurrentOperations = 3,
    this.operationTimeout = const Duration(minutes: 5),
    this.enableBatchOperations = true,
    this.batchSize = 50,
    this.enableConflictResolution = true,
    this.enableRetryOnFailure = true,
    this.enableEventPublishing = true,
    this.progressUpdateInterval = const Duration(seconds: 1),
  });

  SyncOperationConfig copyWith({
    int? maxConcurrentOperations,
    Duration? operationTimeout,
    bool? enableBatchOperations,
    int? batchSize,
    bool? enableConflictResolution,
    bool? enableRetryOnFailure,
    bool? enableEventPublishing,
    Duration? progressUpdateInterval,
  }) {
    return SyncOperationConfig(
      maxConcurrentOperations:
          maxConcurrentOperations ?? this.maxConcurrentOperations,
      operationTimeout: operationTimeout ?? this.operationTimeout,
      enableBatchOperations:
          enableBatchOperations ?? this.enableBatchOperations,
      batchSize: batchSize ?? this.batchSize,
      enableConflictResolution:
          enableConflictResolution ?? this.enableConflictResolution,
      enableRetryOnFailure: enableRetryOnFailure ?? this.enableRetryOnFailure,
      enableEventPublishing:
          enableEventPublishing ?? this.enableEventPublishing,
      progressUpdateInterval:
          progressUpdateInterval ?? this.progressUpdateInterval,
    );
  }
}

/// Progress information for sync operations
class SyncProgress {
  final String operationId;
  final String collection;
  final int totalItems;
  final int processedItems;
  final int successfulItems;
  final int failedItems;
  final double percentage;
  final SyncOperationType currentOperation;
  final Duration elapsed;
  final Duration? estimatedRemaining;
  final List<String> errors;

  const SyncProgress({
    required this.operationId,
    required this.collection,
    required this.totalItems,
    required this.processedItems,
    required this.successfulItems,
    required this.failedItems,
    required this.percentage,
    required this.currentOperation,
    required this.elapsed,
    this.estimatedRemaining,
    this.errors = const [],
  });

  SyncProgress copyWith({
    String? operationId,
    String? collection,
    int? totalItems,
    int? processedItems,
    int? successfulItems,
    int? failedItems,
    double? percentage,
    SyncOperationType? currentOperation,
    Duration? elapsed,
    Duration? estimatedRemaining,
    List<String>? errors,
  }) {
    return SyncProgress(
      operationId: operationId ?? this.operationId,
      collection: collection ?? this.collection,
      totalItems: totalItems ?? this.totalItems,
      processedItems: processedItems ?? this.processedItems,
      successfulItems: successfulItems ?? this.successfulItems,
      failedItems: failedItems ?? this.failedItems,
      percentage: percentage ?? this.percentage,
      currentOperation: currentOperation ?? this.currentOperation,
      elapsed: elapsed ?? this.elapsed,
      estimatedRemaining: estimatedRemaining ?? this.estimatedRemaining,
      errors: errors ?? this.errors,
    );
  }

  @override
  String toString() {
    return 'SyncProgress(collection: $collection, ${percentage.toStringAsFixed(1)}% - $processedItems/$totalItems)';
  }
}

/// Entity configuration for sync operations
class SyncEntityConfig {
  final String tableName;
  final Map<String, dynamic> fieldMappings;
  final ConflictResolutionStrategy conflictStrategy;
  final SyncPriority priority;
  final bool requiresAuthentication;
  final Duration? customSyncInterval;
  final bool enableRealTimeSync;
  final List<String> indexedFields;
  final Map<String, dynamic> metadata;

  const SyncEntityConfig({
    required this.tableName,
    this.fieldMappings = const {},
    this.conflictStrategy = ConflictResolutionStrategy.remoteWins,
    this.priority = SyncPriority.normal,
    this.requiresAuthentication = true,
    this.customSyncInterval,
    this.enableRealTimeSync = false,
    this.indexedFields = const [],
    this.metadata = const {},
  });

  SyncEntityConfig copyWith({
    String? tableName,
    Map<String, dynamic>? fieldMappings,
    ConflictResolutionStrategy? conflictStrategy,
    SyncPriority? priority,
    bool? requiresAuthentication,
    Duration? customSyncInterval,
    bool? enableRealTimeSync,
    List<String>? indexedFields,
    Map<String, dynamic>? metadata,
  }) {
    return SyncEntityConfig(
      tableName: tableName ?? this.tableName,
      fieldMappings: fieldMappings ?? this.fieldMappings,
      conflictStrategy: conflictStrategy ?? this.conflictStrategy,
      priority: priority ?? this.priority,
      requiresAuthentication:
          requiresAuthentication ?? this.requiresAuthentication,
      customSyncInterval: customSyncInterval ?? this.customSyncInterval,
      enableRealTimeSync: enableRealTimeSync ?? this.enableRealTimeSync,
      indexedFields: indexedFields ?? this.indexedFields,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Core sync orchestrator that coordinates all sync operations
class UniversalSyncOperationService {
  final ISyncBackendAdapter _backendAdapter;
  final SyncQueue _syncQueue;
  final EnhancedConflictResolutionManager _conflictResolverManager;
  final SyncScheduler _syncScheduler;
  final SyncEventBus _eventBus;

  SyncOperationConfig _config;
  final Map<String, SyncEntityConfig> _entityConfigs = {};
  final Map<String, Completer<SyncResult>> _activeOperations = {};
  final Map<String, SyncProgress> _progressTrackers = {};
  final Map<String, Timer> _progressTimers = {};

  Timer? _processingTimer;
  bool _isProcessing = false;
  bool _isPaused = false;
  bool _isDisposed = false;

  final StreamController<SyncProgress> _progressController =
      StreamController<SyncProgress>.broadcast();
  final StreamController<SyncResult> _resultController =
      StreamController<SyncResult>.broadcast();

  /// Stream of sync progress updates
  Stream<SyncProgress> get progressStream => _progressController.stream;

  /// Stream of sync results
  Stream<SyncResult> get resultStream => _resultController.stream;

  UniversalSyncOperationService({
    required ISyncBackendAdapter backendAdapter,
    SyncQueue? syncQueue,
    EnhancedConflictResolutionManager? conflictResolverManager,
    SyncScheduler? syncScheduler,
    SyncEventBus? eventBus,
    SyncOperationConfig? config,
  })  : _backendAdapter = backendAdapter,
        _syncQueue = syncQueue ?? SyncQueue(),
        _conflictResolverManager =
            conflictResolverManager ?? EnhancedConflictResolutionManager(),
        _syncScheduler = syncScheduler ?? SyncScheduler(),
        _eventBus = eventBus ?? SyncEventBus.instance,
        _config = config ?? const SyncOperationConfig() {
    _initialize();
  }

  void _initialize() {
    // Listen to sync triggers from scheduler
    _syncScheduler.syncTriggers.listen(_handleSyncTrigger);

    // Listen to queue changes
    _syncQueue.operationAdded.listen(_handleOperationAdded);
    _syncQueue.queueSizeChanged.listen(_handleQueueSizeChanged);

    // Listen to conflict events
    _conflictResolverManager.conflictDetected.listen(_handleConflictDetected);
    _conflictResolverManager.conflictResolved.listen(_handleConflictResolved);

    // Start processing
    _startProcessing();
  }

  /// Updates the operation configuration
  void updateConfig(SyncOperationConfig config) {
    _config = config;
    _restartProcessing();
  }

  /// Gets the current configuration
  SyncOperationConfig get config => _config;

  /// Registers an entity for sync operations
  void registerEntity(String collection, SyncEntityConfig config) {
    if (_isDisposed) return;

    _entityConfigs[collection] = config;

    // Register conflict resolver if custom strategy is specified
    if (config.conflictStrategy != ConflictResolutionStrategy.remoteWins) {
      // For now, just create a custom resolver
      // We could create a proper adapter here in a future version
      final resolverAdapter = _createSimpleResolver(config.conflictStrategy);
      _conflictResolverManager.registerResolver(collection, resolverAdapter);
    }

    // Setup scheduler for custom intervals
    if (config.customSyncInterval != null) {
      _syncScheduler.updateConfig(
        _syncScheduler.config.copyWith(
          collectionIntervals: {
            ..._syncScheduler.config.collectionIntervals,
            collection: config.customSyncInterval!,
          },
        ),
      );
    }
  }

  /// Unregisters an entity
  void unregisterEntity(String collection) {
    _entityConfigs.remove(collection);
    _conflictResolverManager.removeResolver(collection);
    _syncQueue.clearCollection(collection);
  }

  /// Queues a sync operation
  Future<SyncResult> queueOperation(SyncOperation operation) {
    if (_isDisposed) {
      return Future.value(SyncResult.error(
        error: SyncError(
          type: SyncErrorType.unknown,
          message: 'Service has been disposed',
        ),
        action: _convertOperationType(operation.type),
        timestamp: DateTime.now(),
      ));
    }

    final completer = Completer<SyncResult>();
    _activeOperations[operation.id] = completer;

    _syncQueue.enqueue(operation);

    if (_config.enableEventPublishing) {
      _eventBus.publishSyncOperationStarted(
        collection: operation.collection,
        operationType: operation.type,
        entityId: operation.entityId,
      );
    }

    return completer.future;
  }

  /// Performs a manual sync for a specific collection
  Future<SyncResult> syncCollection(String collection) async {
    if (_isDisposed) {
      return SyncResult.error(
        error: SyncError(
          type: SyncErrorType.unknown,
          message: 'Service has been disposed',
        ),
        action: SyncAction.query,
        timestamp: DateTime.now(),
      );
    }

    final entityConfig = _entityConfigs[collection];
    if (entityConfig == null) {
      return SyncResult.error(
        error: SyncError(
          type: SyncErrorType.validation,
          message: 'Collection not registered: $collection',
        ),
        action: SyncAction.query,
        timestamp: DateTime.now(),
      );
    }

    final operationId = _generateOperationId();
    final startTime = DateTime.now();

    try {
      // Create progress tracker
      final progress = SyncProgress(
        operationId: operationId,
        collection: collection,
        totalItems: 0,
        processedItems: 0,
        successfulItems: 0,
        failedItems: 0,
        percentage: 0.0,
        currentOperation: SyncOperationType.query,
        elapsed: Duration.zero,
      );

      _progressTrackers[operationId] = progress;
      _startProgressTracking(operationId);

      // Query backend for data
      final queryResult = await _backendAdapter
          .query(collection, SyncQuery())
          .timeout(_config.operationTimeout);

      // Process the results
      final results = queryResult;
      final updatedProgress = progress.copyWith(
        totalItems: results.length,
        currentOperation: SyncOperationType.update,
      );

      _updateProgress(operationId, updatedProgress);

      // Sync each item
      int successful = 0;
      int failed = 0;
      final errors = <String>[];

      for (int i = 0; i < results.length; i++) {
        final result = results[i];
        try {
          final syncResult = await _syncSingleItem(collection, result.data);
          if (syncResult.isSuccess) {
            successful++;
          } else {
            failed++;
            if (syncResult.error != null) {
              errors.add(syncResult.error!.message);
            }
          }
        } catch (e) {
          failed++;
          errors.add(e.toString());
        }

        // Update progress
        final itemProgress = _progressTrackers[operationId]?.copyWith(
          processedItems: i + 1,
          successfulItems: successful,
          failedItems: failed,
          percentage: ((i + 1) / results.length) * 100,
          elapsed: DateTime.now().difference(startTime),
          errors: errors,
        );

        if (itemProgress != null) {
          _updateProgress(operationId, itemProgress);
        }
      }

      final finalResult = SyncResult.success(
        data: {
          'total': results.length,
          'successful': successful,
          'failed': failed,
          'errors': errors,
        },
        action: SyncAction.query,
        timestamp: DateTime.now(),
      );

      return _completeOperation(operationId, finalResult, startTime);
    } catch (e) {
      final errorResult = SyncResult.error(
        error: SyncError(
          type: SyncErrorType.unknown,
          message: e.toString(),
        ),
        action: SyncAction.query,
        timestamp: DateTime.now(),
      );

      return _completeOperation(operationId, errorResult, startTime);
    }
  }

  /// Syncs all registered collections
  Future<List<SyncResult>> syncAll() async {
    final results = <SyncResult>[];

    for (final collection in _entityConfigs.keys) {
      final result = await syncCollection(collection);
      results.add(result);
    }

    return results;
  }

  /// Pauses sync operations
  void pause() {
    _isPaused = true;
    _syncScheduler.pause();
  }

  /// Resumes sync operations
  void resume() {
    _isPaused = false;
    _syncScheduler.resume();
    _startProcessing();
  }

  /// Stops all sync operations
  void stop() {
    _isPaused = true;
    _syncScheduler.stop();
    _stopProcessing();
  }

  /// Gets current sync status
  Map<String, dynamic> getStatus() {
    return {
      'isProcessing': _isProcessing,
      'isPaused': _isPaused,
      'queueSize': _syncQueue.size,
      'activeOperations': _activeOperations.length,
      'registeredCollections': _entityConfigs.keys.toList(),
      'progressTrackers': _progressTrackers.length,
    };
  }

  /// Gets progress for a specific operation
  SyncProgress? getProgress(String operationId) {
    return _progressTrackers[operationId];
  }

  /// Gets all active progress trackers
  Map<String, SyncProgress> getAllProgress() {
    return Map.from(_progressTrackers);
  }

  void _handleSyncTrigger(SyncTrigger trigger) {
    if (_isPaused || _isDisposed) return;

    if (_config.enableEventPublishing) {
      _eventBus.publishSyncTriggerFired(trigger);
    }

    if (trigger.collection != null) {
      syncCollection(trigger.collection!);
    } else {
      syncAll();
    }
  }

  void _handleOperationAdded(SyncOperation operation) {
    if (_config.enableEventPublishing) {
      _eventBus.publishSyncOperationStarted(
        collection: operation.collection,
        operationType: operation.type,
        entityId: operation.entityId,
      );
    }
  }

  void _handleQueueSizeChanged(int queueSize) {
    if (_config.enableEventPublishing) {
      _eventBus.publishSyncQueueStatusChanged(
        queueSize: queueSize,
        queueSizeByPriority: _syncQueue.sizeByPriority,
      );
    }
  }

  void _handleConflictDetected(EnhancedSyncConflict enhancedConflict) {
    if (_config.enableEventPublishing) {
      // Convert enhanced conflict to regular conflict for event bus compatibility
      final conflict = SyncConflict(
        entityId: enhancedConflict.entityId,
        collection: enhancedConflict.collection,
        localData: enhancedConflict.localData,
        remoteData: enhancedConflict.remoteData,
        fieldConflicts: {}, // We lose some data in this conversion
        localVersion: enhancedConflict.localVersion,
        remoteVersion: enhancedConflict.remoteVersion,
        detectedAt: enhancedConflict.detectedAt,
      );

      _eventBus.publishSyncConflictDetected(conflict);
    }
  }

  void _handleConflictResolved(
      EnhancedSyncConflictResolution enhancedResolution) {
    // Implementation depends on the conflict and resolution details
    // If needed, create a compatibility adapter here
  }

  Future<SyncResult> _syncSingleItem(
      String collection, Map<String, dynamic>? data) async {
    if (data == null) {
      return SyncResult.error(
        error: SyncError(
          type: SyncErrorType.validation,
          message: 'No data provided',
        ),
        action: SyncAction.update,
        timestamp: DateTime.now(),
      );
    }

    // Check for conflicts if enabled
    if (_config.enableConflictResolution) {
      final conflict = _conflictResolverManager.detectConflict(
        entityId: data['id'] ?? '',
        collection: collection,
        localData: data,
        remoteData: data, // In real implementation, fetch from local DB
        localVersion: data['sync_version'] ?? 0,
        remoteVersion: data['sync_version'] ?? 0,
      );

      if (conflict != null) {
        final resolution = _conflictResolverManager.resolveConflict(conflict);
        if (_config.enableEventPublishing) {
          // Convert enhanced types to regular types for event bus compatibility
          final simplifiedConflict = SyncConflict(
            entityId: conflict.entityId,
            collection: conflict.collection,
            localData: conflict.localData,
            remoteData: conflict.remoteData,
            fieldConflicts: {}, // We lose data in this conversion
            localVersion: conflict.localVersion,
            remoteVersion: conflict.remoteVersion,
            detectedAt: conflict.detectedAt,
          );

          // Use a factory method for simpler creation
          final simplifiedResolution =
              SyncConflictResolution.useRemote(resolution.resolvedData);

          _eventBus.publishSyncConflictResolved(
            conflict: simplifiedConflict,
            resolution: simplifiedResolution,
          );
        }
        // Use resolved data
        data = resolution.resolvedData;
      }
    }

    // Perform the actual sync operation
    return await _backendAdapter.update(collection, data['id'], data);
  }

  void _startProcessing() {
    if (_processingTimer != null) return;

    _processingTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _processQueue();
    });
  }

  void _stopProcessing() {
    _processingTimer?.cancel();
    _processingTimer = null;
    _isProcessing = false;
  }

  void _restartProcessing() {
    _stopProcessing();
    if (!_isPaused) {
      _startProcessing();
    }
  }

  void _processQueue() {
    if (_isPaused || _isDisposed || _isProcessing) return;
    if (_activeOperations.length >= _config.maxConcurrentOperations) return;

    final operation = _syncQueue.dequeue();
    if (operation == null) return;

    _isProcessing = true;
    _processOperation(operation).then((result) {
      _completeQueuedOperation(operation.id, result);
      _isProcessing = false;
    }).catchError((error) {
      final errorResult = SyncResult.error(
        error: SyncError(
          type: SyncErrorType.unknown,
          message: error.toString(),
        ),
        action: _convertOperationType(operation.type),
        timestamp: DateTime.now(),
      );
      _completeQueuedOperation(operation.id, errorResult);
      _isProcessing = false;
    });
  }

  Future<SyncResult> _processOperation(SyncOperation operation) async {
    try {
      switch (operation.type) {
        case SyncOperationType.create:
          return await _backendAdapter.create(
              operation.collection, operation.data ?? {});
        case SyncOperationType.read:
          return await _backendAdapter.read(
              operation.collection, operation.entityId ?? '');
        case SyncOperationType.update:
          return await _backendAdapter.update(operation.collection,
              operation.entityId ?? '', operation.data ?? {});
        case SyncOperationType.delete:
          return await _backendAdapter.delete(
              operation.collection, operation.entityId ?? '');
        case SyncOperationType.query:
          final results = await _backendAdapter.query(
              operation.collection, operation.query ?? SyncQuery());
          return SyncResult.success(
            data: {'results': results},
            action: _convertOperationType(operation.type),
            timestamp: DateTime.now(),
          );
        case SyncOperationType.batchCreate:
          return _processBatchOperation(operation);
        case SyncOperationType.batchUpdate:
          return _processBatchOperation(operation);
        case SyncOperationType.batch:
          return _processBatchOperation(operation);
      }
    } catch (e) {
      return SyncResult.error(
        error: SyncError(
          type: SyncErrorType.unknown,
          message: e.toString(),
        ),
        action: _convertOperationType(operation.type),
        timestamp: DateTime.now(),
      );
    }
  }

  Future<SyncResult> _processBatchOperation(SyncOperation operation) async {
    if (!_config.enableBatchOperations) {
      return SyncResult.error(
        error: SyncError(
          type: SyncErrorType.validation,
          message: 'Batch operations are disabled',
        ),
        action: _convertOperationType(operation.type),
        timestamp: DateTime.now(),
      );
    }

    final batchData = operation.batchData ?? [];
    if (batchData.isEmpty) {
      return SyncResult.success(
        data: {'results': []},
        action: _convertOperationType(operation.type),
        timestamp: DateTime.now(),
      );
    }

    try {
      List<SyncResult> results;

      switch (operation.type) {
        case SyncOperationType.batchCreate:
          results = await _backendAdapter.batchCreate(
              operation.collection, batchData);
          break;
        case SyncOperationType.batchUpdate:
          results = await _backendAdapter.batchUpdate(
              operation.collection, batchData);
          break;
        default:
          throw Exception('Unsupported batch operation: ${operation.type}');
      }

      return SyncResult.success(
        data: {'results': results},
        action: _convertOperationType(operation.type),
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return SyncResult.error(
        error: SyncError(
          type: SyncErrorType.unknown,
          message: e.toString(),
        ),
        action: _convertOperationType(operation.type),
        timestamp: DateTime.now(),
      );
    }
  }

  void _completeQueuedOperation(String operationId, SyncResult result) {
    final completer = _activeOperations.remove(operationId);
    completer?.complete(result);

    if (_config.enableEventPublishing) {
      _eventBus.publishSyncOperationCompleted(
        collection: result.collection ?? 'unknown',
        operationType: _convertSyncAction(result.action),
        result: result,
        duration: Duration.zero, // Calculate actual duration
      );
    }

    _resultController.add(result);
  }

  SyncResult _completeOperation(
      String operationId, SyncResult result, DateTime startTime) {
    _stopProgressTracking(operationId);

    final duration = DateTime.now().difference(startTime);

    if (_config.enableEventPublishing) {
      _eventBus.publishSyncOperationCompleted(
        collection: result.collection ?? 'unknown',
        operationType: _convertSyncAction(result.action),
        result: result,
        duration: duration,
      );
    }

    _resultController.add(result);
    return result;
  }

  void _startProgressTracking(String operationId) {
    if (!_config.enableEventPublishing) return;

    _progressTimers[operationId] =
        Timer.periodic(_config.progressUpdateInterval, (timer) {
      final progress = _progressTrackers[operationId];
      if (progress != null) {
        _progressController.add(progress);
      }
    });
  }

  void _stopProgressTracking(String operationId) {
    _progressTimers[operationId]?.cancel();
    _progressTimers.remove(operationId);
    _progressTrackers.remove(operationId);
  }

  void _updateProgress(String operationId, SyncProgress progress) {
    _progressTrackers[operationId] = progress;
    if (_config.enableEventPublishing) {
      _progressController.add(progress);
    }
  }

  String _generateOperationId() {
    return 'op_${DateTime.now().millisecondsSinceEpoch}_${_activeOperations.length}';
  }

  /// Converts SyncOperationType to SyncAction
  SyncAction _convertOperationType(SyncOperationType type) {
    switch (type) {
      case SyncOperationType.create:
        return SyncAction.create;
      case SyncOperationType.read:
        return SyncAction.read;
      case SyncOperationType.update:
        return SyncAction.update;
      case SyncOperationType.delete:
        return SyncAction.delete;
      case SyncOperationType.query:
        return SyncAction.query;
      case SyncOperationType.batchCreate:
        return SyncAction.batchCreate;
      case SyncOperationType.batchUpdate:
        return SyncAction.batchUpdate;
      case SyncOperationType.batch:
        return SyncAction
            .batchCreate; // Default to batchCreate for generic batch
    }
  }

  /// Converts SyncAction to SyncOperationType
  SyncOperationType _convertSyncAction(SyncAction action) {
    switch (action) {
      case SyncAction.create:
        return SyncOperationType.create;
      case SyncAction.read:
        return SyncOperationType.read;
      case SyncAction.update:
        return SyncOperationType.update;
      case SyncAction.delete:
        return SyncOperationType.delete;
      case SyncAction.query:
        return SyncOperationType.query;
      case SyncAction.batchCreate:
        return SyncOperationType.batchCreate;
      case SyncAction.batchUpdate:
        return SyncOperationType.batchUpdate;
      default:
        return SyncOperationType.query; // Default fallback
    }
  }

  /// Dispose method to clean up resources
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    _isPaused = true;

    _stopProcessing();

    // Cancel all progress timers
    for (final timer in _progressTimers.values) {
      timer.cancel();
    }
    _progressTimers.clear();

    // Complete any pending operations with error
    for (final completer in _activeOperations.values) {
      if (!completer.isCompleted) {
        completer.complete(SyncResult.error(
          error: SyncError(
            type: SyncErrorType.unknown,
            message: 'Service disposed',
          ),
          action: SyncAction.query,
          timestamp: DateTime.now(),
        ));
      }
    }
    _activeOperations.clear();

    _progressTrackers.clear();
    _entityConfigs.clear();

    _syncQueue.dispose();
    _conflictResolverManager.dispose();
    _syncScheduler.dispose();

    _progressController.close();
    _resultController.close();
  }

  /// Creates a simple adapter from ConflictResolutionStrategy to EnhancedConflictResolver
  EnhancedConflictResolver _createSimpleResolver(
      ConflictResolutionStrategy strategy) {
    // This is a simple adapter implementation
    return new SimpleConflictResolverAdapter(strategy);
  }
}

/// Adapter class to bridge between the old conflict resolver system and the new enhanced one
class SimpleConflictResolverAdapter implements EnhancedConflictResolver {
  final ConflictResolutionStrategy _strategy;

  SimpleConflictResolverAdapter(this._strategy);

  @override
  String get name => "SimpleAdapter";

  @override
  int get priority => 0;

  @override
  EnhancedSyncConflictResolution resolveConflict(
      EnhancedSyncConflict conflict) {
    final resolvedData = <String, dynamic>{};

    // Simple implementation - in a real app, this would be more sophisticated
    if (_strategy == ConflictResolutionStrategy.localWins) {
      resolvedData.addAll(conflict.localData);
    } else {
      resolvedData.addAll(conflict.remoteData);
    }

    // For now, map strategies simply using a fixed mapping
    // In a real implementation, this would be more sophisticated
    EnhancedConflictResolutionStrategy enhancedStrategy;
    switch (_strategy) {
      case ConflictResolutionStrategy.localWins:
        enhancedStrategy = EnhancedConflictResolutionStrategy.localWins;
        break;
      default:
        enhancedStrategy = EnhancedConflictResolutionStrategy.remoteWins;
        break;
    }

    return EnhancedSyncConflictResolution(
      conflictId: conflict.conflictId,
      resolvedData: resolvedData,
      strategy: enhancedStrategy,
      resolvedAt: DateTime.now(),
    );
  }

  @override
  bool canResolve(EnhancedSyncConflict conflict) {
    return true; // We can handle all conflicts
  }

  @override
  double getConfidenceScore(EnhancedSyncConflict conflict) {
    return 0.8; // Reasonable confidence
  }

  @override
  EnhancedSyncConflict preprocessConflict(EnhancedSyncConflict conflict) {
    return conflict; // No preprocessing needed
  }

  @override
  EnhancedSyncConflictResolution postprocessResolution(
      EnhancedSyncConflictResolution resolution) {
    return resolution; // No postprocessing needed
  }
}
