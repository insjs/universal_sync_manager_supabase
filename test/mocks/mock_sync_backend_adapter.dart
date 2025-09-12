// test/mocks/mock_sync_backend_adapter.dart

import 'dart:async';
import 'dart:math';

/// Mock backend adapter for testing sync operations
class MockSyncBackendAdapter {
  final Map<String, Map<String, dynamic>> _collections = {};
  final Map<String, StreamController<Map<String, dynamic>>> _subscriptions = {};
  final List<Map<String, dynamic>> _operationLog = [];

  // Configurable behavior
  bool _isConnected = false;
  bool _shouldSimulateErrors = false;
  bool _shouldSimulateNetworkDelay = false;
  Duration _networkDelay = const Duration(milliseconds: 100);
  double _errorRate = 0.0; // 0.0 to 1.0

  // Network condition simulation
  bool _isOffline = false;
  int _networkLatency = 50; // milliseconds
  double _packetLossRate = 0.0;

  // Offline operation queue
  final List<Map<String, dynamic>> _offlineQueue = [];
  bool _conflictSimulationEnabled = false;
  bool _retryMechanismEnabled = false;
  int _maxRetries = 3;
  Duration _baseRetryDelay = const Duration(milliseconds: 100);
  bool _realTimeSubscriptionsEnabled = false;

  // State tracking
  int _operationCounter = 0;
  final Random _random = Random();

  /// Mock backend capabilities
  Map<String, dynamic> get capabilities => {
        'supportsRealtime': true,
        'supportsBatch': true,
        'supportsTransactions': false,
        'supportsConflictResolution': true,
        'maxBatchSize': 100,
        'supportedOperations': ['create', 'read', 'update', 'delete', 'query'],
      };

  /// Connection status
  bool get isConnected => _isConnected && !_isOffline;

  /// Configuration methods
  void configureErrorSimulation({
    bool shouldSimulateErrors = false,
    double errorRate = 0.1,
  }) {
    _shouldSimulateErrors = shouldSimulateErrors;
    _errorRate = errorRate.clamp(0.0, 1.0);
  }

  void configureNetworkSimulation({
    bool shouldSimulateDelay = false,
    Duration networkDelay = const Duration(milliseconds: 100),
    bool isOffline = false,
    int latency = 50,
    double packetLossRate = 0.0,
    int bandwidth = 1000,
  }) {
    _shouldSimulateNetworkDelay = shouldSimulateDelay;
    _networkDelay = networkDelay;
    _isOffline = isOffline;
    _networkLatency = latency;
    _packetLossRate = packetLossRate.clamp(0.0, 1.0);
    // bandwidth parameter accepted but not stored as it's not used in simulation
  }

  /// Connection management
  Future<bool> connect(Map<String, dynamic> config) async {
    await _simulateNetworkDelay();

    if (_shouldSimulateErrors && _random.nextDouble() < _errorRate) {
      throw Exception('Mock connection failed');
    }

    _isConnected = true;
    _logOperation('connect', null, null, {'config': config});
    return true;
  }

  Future<void> disconnect() async {
    await _simulateNetworkDelay();
    _isConnected = false;

    // Close all subscriptions
    for (final controller in _subscriptions.values) {
      controller.close();
    }
    _subscriptions.clear();

    _logOperation('disconnect', null, null, {});
  }

  /// CRUD Operations
  Future<Map<String, dynamic>> create(
    String collection,
    Map<String, dynamic> data,
  ) async {
    await _simulateNetworkDelay();

    // If offline, queue the operation
    if (_isOffline) {
      _offlineQueue.add({
        'operation': 'create',
        'collection': collection,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });
      return {
        'success': true,
        'data': data,
        'metadata': {'operation': 'create', 'queued': true},
      };
    }

    _throwIfOfflineOrError('create');

    final id = data['id'] ?? 'mock_${_operationCounter++}';
    final timestamp = DateTime.now().toIso8601String();

    final enrichedData = {
      ...data,
      'id': id,
      'createdAt': timestamp,
      'updatedAt': timestamp,
      'syncVersion': 1,
    };

    _collections.putIfAbsent(collection, () => {});
    _collections[collection]![id] = enrichedData;

    _logOperation('create', collection, id, enrichedData);
    _notifySubscribers(collection, 'create', enrichedData);

    return {
      'success': true,
      'data': enrichedData,
      'metadata': {
        'operation': 'create',
        'timestamp': timestamp,
        'networkLatency': _networkLatency,
      },
    };
  }

  Future<Map<String, dynamic>> read(String collection, String id) async {
    await _simulateNetworkDelay();
    _throwIfOfflineOrError('read');

    final collectionData = _collections[collection];
    if (collectionData == null || !collectionData.containsKey(id)) {
      return {
        'success': false,
        'error': 'Item not found',
        'data': null,
      };
    }

    final data = collectionData[id]!;
    _logOperation('read', collection, id, data);

    return {
      'success': true,
      'data': data,
      'metadata': {
        'operation': 'read',
        'timestamp': DateTime.now().toIso8601String(),
        'networkLatency': _networkLatency,
      },
    };
  }

  Future<Map<String, dynamic>> update(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    await _simulateNetworkDelay();

    // If offline, queue the operation
    if (_isOffline) {
      _offlineQueue.add({
        'operation': 'update',
        'collection': collection,
        'id': id,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });
      return {
        'success': true,
        'data': data,
        'metadata': {'operation': 'update', 'queued': true},
      };
    }

    _throwIfOfflineOrError('update');

    final collectionData = _collections[collection];
    if (collectionData == null || !collectionData.containsKey(id)) {
      return {
        'success': false,
        'error': 'Item not found for update',
        'data': null,
      };
    }

    final existingData = collectionData[id]!;
    final syncVersion = (existingData['syncVersion'] as int? ?? 0) + 1;

    final updatedData = <String, dynamic>{
      ...existingData,
      ...data,
      'id': id, // Preserve ID
      'updatedAt': DateTime.now().toIso8601String(),
      'syncVersion': syncVersion,
    };

    collectionData[id] = updatedData;
    _logOperation('update', collection, id, updatedData);
    _notifySubscribers(collection, 'update', updatedData);

    return {
      'success': true,
      'data': updatedData,
      'metadata': {
        'operation': 'update',
        'timestamp': DateTime.now().toIso8601String(),
        'networkLatency': _networkLatency,
        'syncVersion': syncVersion,
      },
    };
  }

  Future<Map<String, dynamic>> delete(String collection, String id) async {
    await _simulateNetworkDelay();

    // If offline, queue the operation
    if (_isOffline) {
      _offlineQueue.add({
        'operation': 'delete',
        'collection': collection,
        'id': id,
        'timestamp': DateTime.now().toIso8601String(),
      });
      return {
        'success': true,
        'data': {'id': id},
        'metadata': {'operation': 'delete', 'queued': true},
      };
    }

    _throwIfOfflineOrError('delete');

    final collectionData = _collections[collection];
    if (collectionData == null || !collectionData.containsKey(id)) {
      return {
        'success': false,
        'error': 'Item not found for deletion',
        'data': null,
      };
    }

    final deletedData = collectionData.remove(id)!;
    _logOperation('delete', collection, id, deletedData);
    _notifySubscribers(
        collection, 'delete', {'id': id, 'deletedData': deletedData});

    return {
      'success': true,
      'data': deletedData,
      'metadata': {
        'operation': 'delete',
        'timestamp': DateTime.now().toIso8601String(),
        'networkLatency': _networkLatency,
      },
    };
  }

  Future<Map<String, dynamic>> query(
    String collection,
    Map<String, dynamic> queryParams,
  ) async {
    await _simulateNetworkDelay();
    _throwIfOfflineOrError('query');

    final collectionData = _collections[collection] ?? {};
    var results = collectionData.values.toList();

    // Apply filtering
    if (queryParams.containsKey('filter')) {
      final filter = queryParams['filter'] as Map<String, dynamic>;
      results = results.where((item) {
        return filter.entries.every((entry) {
          final fieldValue = item[entry.key];
          return fieldValue == entry.value;
        });
      }).toList();
    }

    // Apply sorting
    if (queryParams.containsKey('sort')) {
      final sortField = queryParams['sort'] as String;
      final sortOrder = queryParams['sortOrder'] as String? ?? 'asc';

      results.sort((a, b) {
        final aValue = a[sortField];
        final bValue = b[sortField];
        final comparison = Comparable.compare(aValue, bValue);
        return sortOrder == 'desc' ? -comparison : comparison;
      });
    }

    // Apply pagination
    final limit = queryParams['limit'] as int?;
    final offset = queryParams['offset'] as int? ?? 0;

    if (offset > 0) {
      results = results.skip(offset).toList();
    }

    if (limit != null) {
      results = results.take(limit).toList();
    }

    _logOperation('query', collection, null, {
      'queryParams': queryParams,
      'resultCount': results.length,
    });

    return {
      'success': true,
      'data': results,
      'metadata': {
        'operation': 'query',
        'timestamp': DateTime.now().toIso8601String(),
        'totalCount': collectionData.length,
        'filteredCount': results.length,
        'networkLatency': _networkLatency,
      },
    };
  }

  /// Batch operations
  Future<Map<String, dynamic>> batchCreate(
    String collection,
    List<Map<String, dynamic>> items,
  ) async {
    await _simulateNetworkDelay();
    _throwIfOfflineOrError('batchCreate');

    final results = <Map<String, dynamic>>[];
    final errors = <Map<String, dynamic>>[];

    for (int i = 0; i < items.length; i++) {
      try {
        // Simulate individual item processing
        if (_shouldSimulateErrors && _random.nextDouble() < _errorRate) {
          errors.add({
            'index': i,
            'item': items[i],
            'error': 'Mock batch item error',
          });
          continue;
        }

        final result = await create(collection, items[i]);
        if (result['success']) {
          results.add(result['data']);
        } else {
          errors.add({
            'index': i,
            'item': items[i],
            'error': result['error'],
          });
        }
      } catch (e) {
        errors.add({
          'index': i,
          'item': items[i],
          'error': e.toString(),
        });
      }
    }

    _logOperation('batchCreate', collection, null, {
      'itemCount': items.length,
      'successCount': results.length,
      'errorCount': errors.length,
    });

    return {
      'success': errors.isEmpty,
      'data': results,
      'errors': errors,
      'metadata': {
        'operation': 'batchCreate',
        'timestamp': DateTime.now().toIso8601String(),
        'totalItems': items.length,
        'successfulItems': results.length,
        'failedItems': errors.length,
        'networkLatency': _networkLatency,
      },
    };
  }

  Future<Map<String, dynamic>> batchUpdate(
    String collection,
    List<Map<String, dynamic>> items,
  ) async {
    await _simulateNetworkDelay();
    _throwIfOfflineOrError('batchUpdate');

    final results = <Map<String, dynamic>>[];
    final errors = <Map<String, dynamic>>[];

    for (int i = 0; i < items.length; i++) {
      try {
        final item = items[i];
        final id = item['id'];

        if (id == null) {
          errors.add({
            'index': i,
            'item': item,
            'error': 'Missing ID for update',
          });
          continue;
        }

        if (_shouldSimulateErrors && _random.nextDouble() < _errorRate) {
          errors.add({
            'index': i,
            'item': item,
            'error': 'Mock batch update error',
          });
          continue;
        }

        final result = await update(collection, id, item);
        if (result['success']) {
          results.add(result['data']);
        } else {
          errors.add({
            'index': i,
            'item': item,
            'error': result['error'],
          });
        }
      } catch (e) {
        errors.add({
          'index': i,
          'item': items[i],
          'error': e.toString(),
        });
      }
    }

    _logOperation('batchUpdate', collection, null, {
      'itemCount': items.length,
      'successCount': results.length,
      'errorCount': errors.length,
    });

    return {
      'success': errors.isEmpty,
      'data': results,
      'errors': errors,
      'metadata': {
        'operation': 'batchUpdate',
        'timestamp': DateTime.now().toIso8601String(),
        'totalItems': items.length,
        'successfulItems': results.length,
        'failedItems': errors.length,
        'networkLatency': _networkLatency,
      },
    };
  }

  /// Real-time subscriptions
  Stream<Map<String, dynamic>> subscribe(
    String collection,
    Map<String, dynamic> options,
  ) {
    final subscriptionId = 'sub_${_operationCounter++}';
    final controller = StreamController<Map<String, dynamic>>.broadcast();

    _subscriptions[subscriptionId] = controller;

    _logOperation('subscribe', collection, null, {
      'subscriptionId': subscriptionId,
      'options': options,
    });

    // Send initial data if requested
    if (options['includeInitialData'] == true) {
      Timer(const Duration(milliseconds: 100), () {
        final collectionData = _collections[collection] ?? {};
        controller.add({
          'type': 'initial',
          'subscriptionId': subscriptionId,
          'data': collectionData.values.toList(),
          'timestamp': DateTime.now().toIso8601String(),
        });
      });
    }

    return controller.stream;
  }

  Future<void> unsubscribe(String subscriptionId) async {
    final controller = _subscriptions.remove(subscriptionId);
    if (controller != null) {
      await controller.close();
      _logOperation('unsubscribe', null, null, {
        'subscriptionId': subscriptionId,
      });
    }
  }

  /// Data management for testing
  void seedData(String collection, List<Map<String, dynamic>> items) {
    _collections[collection] = {};
    for (final item in items) {
      final id = item['id'] ?? 'seed_${_operationCounter++}';
      _collections[collection]![id] = {
        ...item,
        'id': id,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'syncVersion': 1,
      };
    }
  }

  void clearData([String? collection]) {
    if (collection != null) {
      _collections.remove(collection);
    } else {
      _collections.clear();
    }
  }

  Map<String, dynamic> getCollectionData(String collection) {
    return Map<String, dynamic>.from(_collections[collection] ?? {});
  }

  List<Map<String, dynamic>> getOperationLog() {
    return List<Map<String, dynamic>>.from(_operationLog);
  }

  void clearOperationLog() {
    _operationLog.clear();
  }

  /// Conflict simulation
  void simulateConflict(
      String collection, String id, Map<String, dynamic> conflictData) {
    final collectionData = _collections[collection];
    if (collectionData != null && collectionData.containsKey(id)) {
      // Modify the data to create a conflict
      final existingData = collectionData[id]!;
      collectionData[id] = {
        ...existingData,
        ...conflictData,
        'syncVersion': (existingData['syncVersion'] as int) + 1,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      _notifySubscribers(collection, 'conflict', {
        'id': id,
        'conflictData': conflictData,
        'existingData': existingData,
      });
    }
  }

  /// Private helper methods
  Future<void> _simulateNetworkDelay() async {
    if (_shouldSimulateNetworkDelay) {
      final additionalDelay = _random.nextInt(_networkLatency);
      await Future.delayed(
          _networkDelay + Duration(milliseconds: additionalDelay));

      // Simulate packet loss
      if (_random.nextDouble() < _packetLossRate) {
        throw Exception('Simulated packet loss');
      }
    }
  }

  void _throwIfOfflineOrError(String operation) {
    if (_isOffline) {
      throw Exception('Network offline - cannot perform $operation');
    }

    if (_shouldSimulateErrors && _random.nextDouble() < _errorRate) {
      throw Exception('Simulated error during $operation');
    }
  }

  void _logOperation(
    String operation,
    String? collection,
    String? id,
    Map<String, dynamic> data,
  ) {
    _operationLog.add({
      'operation': operation,
      'collection': collection,
      'id': id,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'operationNumber': _operationCounter,
    });
  }

  void _notifySubscribers(
    String collection,
    String eventType,
    Map<String, dynamic> data,
  ) {
    for (final entry in _subscriptions.entries) {
      final controller = entry.value;
      if (!controller.isClosed) {
        controller.add({
          'type': eventType,
          'collection': collection,
          'data': data,
          'timestamp': DateTime.now().toIso8601String(),
          'subscriptionId': entry.key,
        });
      }
    }
  }

  /// Test utilities
  void reset() {
    _collections.clear();
    _operationLog.clear();
    for (final controller in _subscriptions.values) {
      controller.close();
    }
    _subscriptions.clear();
    _isConnected = false;
    _operationCounter = 0;
  }

  Map<String, dynamic> getTestStatistics() {
    return {
      'collections': _collections.keys.length,
      'totalItems': _collections.values
          .fold<int>(0, (sum, collection) => sum + collection.length),
      'operations': _operationLog.length,
      'subscriptions': _subscriptions.length,
      'isConnected': _isConnected,
      'isOffline': _isOffline,
      'errorRate': _errorRate,
      'networkLatency': _networkLatency,
    };
  }

  /// Additional methods required by E2E tests
  void setOfflineMode(bool offline) {
    _isOffline = offline;
  }

  List<Map<String, dynamic>> getQueuedOperations() {
    return List<Map<String, dynamic>>.from(_offlineQueue);
  }

  Future<void> syncQueuedOperations() async {
    if (_isOffline) return;

    for (final operation in _offlineQueue) {
      try {
        final op = operation['operation'] as String;
        final collection = operation['collection'] as String;
        final data = operation['data'] as Map<String, dynamic>;

        switch (op) {
          case 'create':
            await create(collection, data);
            break;
          case 'update':
            final id = operation['id'] as String;
            await update(collection, id, data);
            break;
          case 'delete':
            final id = operation['id'] as String;
            await delete(collection, id);
            break;
        }
      } catch (e) {
        // Log error but continue processing
        print('Failed to sync operation: $e');
      }
    }

    _offlineQueue.clear();
  }

  void enableConflictSimulation(bool enabled) {
    _conflictSimulationEnabled = enabled;
  }

  Map<String, dynamic> getData(String collection, String id) {
    final collectionData = _collections[collection];
    if (collectionData == null || !collectionData.containsKey(id)) {
      return {};
    }
    return Map<String, dynamic>.from(collectionData[id]!);
  }

  void enableRetryMechanism(bool enabled,
      {int? maxRetries, Duration? baseDelay}) {
    _retryMechanismEnabled = enabled;
    if (maxRetries != null) _maxRetries = maxRetries;
    if (baseDelay != null) _baseRetryDelay = baseDelay;
  }

  int count(String collection) {
    return _collections[collection]?.length ?? 0;
  }

  void enableRealTimeSubscriptions(bool enabled) {
    _realTimeSubscriptionsEnabled = enabled;
  }
}
