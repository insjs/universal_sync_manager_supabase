import 'dart:async';
import '../models/sync_event.dart';

/// Event bus for broadcasting and listening to sync events
/// Provides a centralized system for real-time sync notifications
class TestSyncEventBus {
  static final TestSyncEventBus _instance = TestSyncEventBus._internal();
  factory TestSyncEventBus() => _instance;
  TestSyncEventBus._internal();

  final StreamController<SyncEvent> _eventController =
      StreamController<SyncEvent>.broadcast();
  final Map<String, StreamSubscription> _subscriptions = {};
  final List<SyncEvent> _eventHistory = [];

  // Configuration
  static const int maxHistorySize = 100;
  static const Duration cleanupInterval = Duration(minutes: 5);

  Timer? _cleanupTimer;
  bool _isInitialized = false;

  /// Initialize the event bus
  void initialize() {
    if (_isInitialized) return;

    _isInitialized = true;

    // Start cleanup timer to prevent memory leaks
    _cleanupTimer = Timer.periodic(cleanupInterval, (timer) {
      _cleanupHistory();
    });

    print('🎯 TestSyncEventBus initialized');
  }

  /// Dispose the event bus and clean up resources
  void dispose() {
    _cleanupTimer?.cancel();
    _eventController.close();

    // Cancel all subscriptions
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();

    _eventHistory.clear();
    _isInitialized = false;

    print('🎯 TestSyncEventBus disposed');
  }

  /// Broadcast a sync event to all listeners
  void broadcast(SyncEvent event) {
    if (!_isInitialized) {
      print('⚠️ TestSyncEventBus not initialized, initializing now...');
      initialize();
    }

    // Add to history
    _eventHistory.add(event);

    // Broadcast to all listeners
    _eventController.add(event);

    // Debug logging
    _logEvent(event);
  }

  /// Subscribe to all sync events
  StreamSubscription<SyncEvent> listen(
    void Function(SyncEvent event) onEvent, {
    String? subscriptionId,
  }) {
    final id = subscriptionId ?? 'sub_${DateTime.now().millisecondsSinceEpoch}';

    final subscription = _eventController.stream.listen(onEvent);
    _subscriptions[id] = subscription;

    print('🎯 TestSyncEventBus: Added listener with ID: $id');
    return subscription;
  }

  /// Subscribe to specific event types
  StreamSubscription<SyncEvent> listenToType(
    SyncEventType eventType,
    void Function(SyncEvent event) onEvent, {
    String? subscriptionId,
  }) {
    final id =
        subscriptionId ?? 'type_sub_${DateTime.now().millisecondsSinceEpoch}';

    final subscription = _eventController.stream
        .where((event) => event.type == eventType)
        .listen(onEvent);

    _subscriptions[id] = subscription;

    print(
        '🎯 TestSyncEventBus: Added listener for type $eventType with ID: $id');
    return subscription;
  }

  /// Subscribe to multiple event types
  StreamSubscription<SyncEvent> listenToTypes(
    List<SyncEventType> eventTypes,
    void Function(SyncEvent event) onEvent, {
    String? subscriptionId,
  }) {
    final id =
        subscriptionId ?? 'types_sub_${DateTime.now().millisecondsSinceEpoch}';

    final subscription = _eventController.stream
        .where((event) => eventTypes.contains(event.type))
        .listen(onEvent);

    _subscriptions[id] = subscription;

    print(
        '🎯 TestSyncEventBus: Added listener for types $eventTypes with ID: $id');
    return subscription;
  }

  /// Subscribe to events for a specific collection
  StreamSubscription<SyncEvent> listenToCollection(
    String collection,
    void Function(SyncEvent event) onEvent, {
    String? subscriptionId,
  }) {
    final id = subscriptionId ??
        'collection_sub_${DateTime.now().millisecondsSinceEpoch}';

    final subscription = _eventController.stream
        .where((event) => _getEventCollection(event) == collection)
        .listen(onEvent);

    _subscriptions[id] = subscription;

    print(
        '🎯 TestSyncEventBus: Added listener for collection $collection with ID: $id');
    return subscription;
  }

  /// Unsubscribe from events
  void unsubscribe(String subscriptionId) {
    final subscription = _subscriptions.remove(subscriptionId);
    if (subscription != null) {
      subscription.cancel();
      print('🎯 TestSyncEventBus: Removed listener with ID: $subscriptionId');
    } else {
      print(
          '⚠️ TestSyncEventBus: No subscription found with ID: $subscriptionId');
    }
  }

  /// Get recent events (for debugging/history)
  List<SyncEvent> getRecentEvents({int? limit}) {
    final events = List<SyncEvent>.from(_eventHistory);
    events.sort(
        (a, b) => b.timestamp.compareTo(a.timestamp)); // Most recent first

    if (limit != null && limit > 0) {
      return events.take(limit).toList();
    }

    return events;
  }

  /// Get events by type
  List<SyncEvent> getEventsByType(SyncEventType type, {int? limit}) {
    final events = _eventHistory.where((event) => event.type == type).toList();

    events.sort(
        (a, b) => b.timestamp.compareTo(a.timestamp)); // Most recent first

    if (limit != null && limit > 0) {
      return events.take(limit).toList();
    }

    return events;
  }

  /// Get events for a specific collection
  List<SyncEvent> getEventsByCollection(String collection, {int? limit}) {
    final events = _eventHistory
        .where((event) => _getEventCollection(event) == collection)
        .toList();

    events.sort(
        (a, b) => b.timestamp.compareTo(a.timestamp)); // Most recent first

    if (limit != null && limit > 0) {
      return events.take(limit).toList();
    }

    return events;
  }

  /// Get event statistics
  Map<SyncEventType, int> getEventStatistics() {
    final stats = <SyncEventType, int>{};

    for (final event in _eventHistory) {
      stats[event.type] = (stats[event.type] ?? 0) + 1;
    }

    return stats;
  }

  /// Get current subscription count
  int get subscriptionCount => _subscriptions.length;

  /// Get event history size
  int get eventHistorySize => _eventHistory.length;

  /// Check if event bus is active
  bool get isInitialized => _isInitialized;

  // Helper methods

  String? _getEventCollection(SyncEvent event) {
    if (event is SyncProgressEvent) return event.collection;
    if (event is SyncCompletedEvent) return event.collection;
    if (event is SyncErrorEvent) return event.collection;
    if (event is DataOperationEvent) return event.collection;
    if (event is ConflictEvent) return event.collection;
    return null;
  }

  void _cleanupHistory() {
    if (_eventHistory.length > maxHistorySize) {
      // Remove oldest events, keep the most recent ones
      _eventHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _eventHistory.removeRange(maxHistorySize, _eventHistory.length);

      print(
          '🧹 TestSyncEventBus: Cleaned up event history, kept ${_eventHistory.length} events');
    }
  }

  void _logEvent(SyncEvent event) {
    // Only log important events to avoid spam
    switch (event.type) {
      case SyncEventType.syncStarted:
      case SyncEventType.syncCompleted:
      case SyncEventType.syncError:
      case SyncEventType.conflictDetected:
      case SyncEventType.conflictResolved:
      case SyncEventType.connectionLost:
      case SyncEventType.connectionEstablished:
        print('📡 Event: ${event.toString()}');
        break;
      default:
        // Don't log progress events and other frequent events
        break;
    }
  }

  // Convenience methods for common events

  /// Broadcast a sync started event
  void broadcastSyncStarted(String operation,
      {String? collection, String? operationId}) {
    broadcast(SyncProgressEvent(
      operation: operation,
      current: 0,
      total: 1,
      message: 'Starting $operation',
      collection: collection,
      operationId: operationId,
    ));
  }

  /// Broadcast a sync progress event
  void broadcastSyncProgress(
    String operation,
    int current,
    int total, {
    String? message,
    String? collection,
    String? operationId,
  }) {
    broadcast(SyncProgressEvent(
      operation: operation,
      current: current,
      total: total,
      message: message,
      collection: collection,
      operationId: operationId,
    ));
  }

  /// Broadcast a sync completed event
  void broadcastSyncCompleted(
    String operation,
    bool success,
    int affectedRecords,
    Duration duration, {
    String? message,
    String? collection,
    String? operationId,
  }) {
    broadcast(SyncCompletedEvent(
      operation: operation,
      success: success,
      affectedRecords: affectedRecords,
      duration: duration,
      message: message,
      collection: collection,
      operationId: operationId,
    ));
  }

  /// Broadcast a sync error event
  void broadcastSyncError(
    String operation,
    String error, {
    String? collection,
    StackTrace? stackTrace,
    Map<String, dynamic>? errorDetails,
    String? operationId,
  }) {
    broadcast(SyncErrorEvent(
      operation: operation,
      error: error,
      collection: collection,
      stackTrace: stackTrace,
      errorDetails: errorDetails,
      operationId: operationId,
    ));
  }

  /// Broadcast a data operation event
  void broadcastDataOperation(
    String operation,
    String collection,
    bool success, {
    String? recordId,
    Map<String, dynamic>? data,
    String? error,
    String? operationId,
  }) {
    broadcast(DataOperationEvent(
      operation: operation,
      collection: collection,
      success: success,
      recordId: recordId,
      data: data,
      error: error,
      operationId: operationId,
    ));
  }

  /// Broadcast a conflict event
  void broadcastConflict(
    String collection,
    String recordId,
    String conflictType,
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
    String resolution,
    bool resolved, {
    String? operationId,
  }) {
    broadcast(ConflictEvent(
      collection: collection,
      recordId: recordId,
      conflictType: conflictType,
      localData: localData,
      remoteData: remoteData,
      resolution: resolution,
      resolved: resolved,
      operationId: operationId,
    ));
  }

  /// Broadcast a connection event
  void broadcastConnection(
    String state, {
    String? backend,
    String? error,
    String? operationId,
  }) {
    broadcast(ConnectionEvent(
      state: state,
      backend: backend,
      error: error,
      operationId: operationId,
    ));
  }

  /// Broadcast an authentication event
  void broadcastAuth(
    String operation,
    bool success, {
    String? userId,
    String? organizationId,
    String? error,
    String? operationId,
  }) {
    broadcast(AuthEvent(
      operation: operation,
      success: success,
      userId: userId,
      organizationId: organizationId,
      error: error,
      operationId: operationId,
    ));
  }
}
