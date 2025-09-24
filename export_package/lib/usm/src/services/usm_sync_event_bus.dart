import 'dart:async';

import '../models/usm_sync_result.dart';
import '../config/usm_sync_enums.dart';
import 'usm_conflict_resolver.dart';
import 'usm_sync_queue.dart';
import 'usm_sync_scheduler.dart';

/// Base class for all sync events in the event bus
abstract class SyncBusEvent {
  final String id;
  final DateTime timestamp;
  final EventPriority priority;
  final Map<String, dynamic> metadata;

  const SyncBusEvent({
    required this.id,
    required this.timestamp,
    this.priority = EventPriority.normal,
    this.metadata = const {},
  });
}

/// Sync operation started event
class SyncOperationStartedEvent extends SyncBusEvent {
  final String collection;
  final SyncOperationType operationType;
  final String? entityId;

  const SyncOperationStartedEvent({
    required super.id,
    required super.timestamp,
    required this.collection,
    required this.operationType,
    this.entityId,
    super.priority = EventPriority.normal,
    super.metadata = const {},
  });
}

/// Sync operation completed event
class SyncOperationCompletedEvent extends SyncBusEvent {
  final String collection;
  final SyncOperationType operationType;
  final SyncResult result;
  final Duration duration;

  const SyncOperationCompletedEvent({
    required super.id,
    required super.timestamp,
    required this.collection,
    required this.operationType,
    required this.result,
    required this.duration,
    super.priority = EventPriority.normal,
    super.metadata = const {},
  });
}

/// Sync conflict detected event
class SyncConflictDetectedEvent extends SyncBusEvent {
  final SyncConflict conflict;

  const SyncConflictDetectedEvent({
    required super.id,
    required super.timestamp,
    required this.conflict,
    super.priority = EventPriority.high,
    super.metadata = const {},
  });
}

/// Sync conflict resolved event
class SyncConflictResolvedEvent extends SyncBusEvent {
  final SyncConflict conflict;
  final SyncConflictResolution resolution;

  const SyncConflictResolvedEvent({
    required super.id,
    required super.timestamp,
    required this.conflict,
    required this.resolution,
    super.priority = EventPriority.normal,
    super.metadata = const {},
  });
}

/// Network status changed event
class NetworkStatusChangedEvent extends SyncBusEvent {
  final NetworkCondition oldCondition;
  final NetworkCondition newCondition;

  const NetworkStatusChangedEvent({
    required super.id,
    required super.timestamp,
    required this.oldCondition,
    required this.newCondition,
    super.priority = EventPriority.high,
    super.metadata = const {},
  });
}

/// Sync queue status changed event
class SyncQueueStatusChangedEvent extends SyncBusEvent {
  final int queueSize;
  final Map<SyncPriority, int> queueSizeByPriority;

  const SyncQueueStatusChangedEvent({
    required super.id,
    required super.timestamp,
    required this.queueSize,
    required this.queueSizeByPriority,
    super.priority = EventPriority.low,
    super.metadata = const {},
  });
}

/// Sync trigger fired event
class SyncTriggerFiredEvent extends SyncBusEvent {
  final SyncTrigger trigger;

  const SyncTriggerFiredEvent({
    required super.id,
    required super.timestamp,
    required this.trigger,
    super.priority = EventPriority.normal,
    super.metadata = const {},
  });
}

/// Backend connection status changed event
class BackendConnectionStatusChangedEvent extends SyncBusEvent {
  final String backendName;
  final bool isConnected;
  final String? errorMessage;

  const BackendConnectionStatusChangedEvent({
    required super.id,
    required super.timestamp,
    required this.backendName,
    required this.isConnected,
    this.errorMessage,
    super.priority = EventPriority.high,
    super.metadata = const {},
  });
}

/// Data change detected event
class DataChangeDetectedEvent extends SyncBusEvent {
  final String collection;
  final String entityId;
  final SyncOperationType changeType;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;

  const DataChangeDetectedEvent({
    required super.id,
    required super.timestamp,
    required this.collection,
    required this.entityId,
    required this.changeType,
    this.oldData,
    this.newData,
    super.priority = EventPriority.normal,
    super.metadata = const {},
  });
}

/// Sync error occurred event
class SyncErrorOccurredEvent extends SyncBusEvent {
  final String collection;
  final SyncError error;
  final String? entityId;
  final bool willRetry;

  const SyncErrorOccurredEvent({
    required super.id,
    required super.timestamp,
    required this.collection,
    required this.error,
    this.entityId,
    this.willRetry = false,
    super.priority = EventPriority.high,
    super.metadata = const {},
  });
}

/// Event handler callback type
typedef EventHandler<T extends SyncBusEvent> = void Function(T event);

/// Event subscription information
class EventSubscription {
  final String id;
  final Type eventType;
  final Function
      handler; // Use Function instead of EventHandler for flexibility
  final EventPriority? minimumPriority;
  final DateTime createdAt;

  const EventSubscription({
    required this.id,
    required this.eventType,
    required this.handler,
    this.minimumPriority,
    required this.createdAt,
  });
}

/// Central event bus for sync operations
class SyncEventBus {
  static SyncEventBus? _instance;
  static SyncEventBus get instance => _instance ??= SyncEventBus._internal();

  SyncEventBus._internal();

  final Map<Type, List<EventSubscription>> _subscriptions = {};
  final StreamController<SyncBusEvent> _eventController =
      StreamController<SyncBusEvent>.broadcast();
  final List<SyncBusEvent> _eventHistory = [];
  final int _maxHistorySize = 1000;

  bool _isDisposed = false;

  /// Stream of all events
  Stream<SyncBusEvent> get eventStream => _eventController.stream;

  /// Publishes an event to all subscribers
  void publish(SyncBusEvent event) {
    if (_isDisposed) return;

    // Add to history
    _eventHistory.add(event);
    if (_eventHistory.length > _maxHistorySize) {
      _eventHistory.removeAt(0);
    }

    // Add to stream
    _eventController.add(event);

    // Notify specific subscribers
    final subscribers = _subscriptions[event.runtimeType] ?? [];
    for (final subscription in subscribers) {
      if (_shouldNotifySubscriber(subscription, event)) {
        try {
          subscription.handler(event);
        } catch (e) {
          // Log error but don't stop other handlers
          _publishError('Event handler error', e, subscription);
        }
      }
    }

    // Notify wildcard subscribers (subscribed to SyncBusEvent)
    final wildcardSubscribers = _subscriptions[SyncBusEvent] ?? [];
    for (final subscription in wildcardSubscribers) {
      if (_shouldNotifySubscriber(subscription, event)) {
        try {
          subscription.handler(event);
        } catch (e) {
          _publishError('Wildcard event handler error', e, subscription);
        }
      }
    }
  }

  /// Subscribes to events of a specific type
  String subscribe<T extends SyncBusEvent>(
    EventHandler<T> handler, {
    EventPriority? minimumPriority,
  }) {
    if (_isDisposed) throw StateError('SyncEventBus has been disposed');

    final subscriptionId = _generateSubscriptionId();
    final subscription = EventSubscription(
      id: subscriptionId,
      eventType: T,
      handler: handler,
      minimumPriority: minimumPriority,
      createdAt: DateTime.now(),
    );

    if (!_subscriptions.containsKey(T)) {
      _subscriptions[T] = [];
    }
    _subscriptions[T]!.add(subscription);

    return subscriptionId;
  }

  /// Subscribes to all events
  String subscribeToAll(
    EventHandler<SyncBusEvent> handler, {
    EventPriority? minimumPriority,
  }) {
    return subscribe<SyncBusEvent>(handler, minimumPriority: minimumPriority);
  }

  /// Unsubscribes from events
  bool unsubscribe(String subscriptionId) {
    for (final subscriptionList in _subscriptions.values) {
      final index = subscriptionList.indexWhere((s) => s.id == subscriptionId);
      if (index != -1) {
        subscriptionList.removeAt(index);
        return true;
      }
    }
    return false;
  }

  /// Unsubscribes all handlers for a specific event type
  void unsubscribeAll<T extends SyncBusEvent>() {
    _subscriptions.remove(T);
  }

  /// Clears all subscriptions
  void clearAllSubscriptions() {
    _subscriptions.clear();
  }

  /// Gets event history
  List<SyncBusEvent> getEventHistory({
    Type? eventType,
    EventPriority? minimumPriority,
    DateTime? since,
    int? limit,
  }) {
    var events = List<SyncBusEvent>.from(_eventHistory);

    // Filter by event type
    if (eventType != null) {
      events = events.where((e) => e.runtimeType == eventType).toList();
    }

    // Filter by priority
    if (minimumPriority != null) {
      events = events
          .where((e) =>
              _priorityValue(e.priority) >= _priorityValue(minimumPriority))
          .toList();
    }

    // Filter by time
    if (since != null) {
      events = events.where((e) => e.timestamp.isAfter(since)).toList();
    }

    // Apply limit
    if (limit != null && events.length > limit) {
      events = events.sublist(events.length - limit);
    }

    return events;
  }

  /// Gets subscription count for an event type
  int getSubscriptionCount<T extends SyncBusEvent>() {
    return _subscriptions[T]?.length ?? 0;
  }

  /// Gets all active subscriptions
  Map<Type, int> getActiveSubscriptions() {
    return _subscriptions.map((type, subs) => MapEntry(type, subs.length));
  }

  /// Clears event history
  void clearEventHistory() {
    _eventHistory.clear();
  }

  /// Convenience methods for common events

  void publishSyncOperationStarted({
    required String collection,
    required SyncOperationType operationType,
    String? entityId,
  }) {
    publish(SyncOperationStartedEvent(
      id: _generateEventId(),
      timestamp: DateTime.now(),
      collection: collection,
      operationType: operationType,
      entityId: entityId,
    ));
  }

  void publishSyncOperationCompleted({
    required String collection,
    required SyncOperationType operationType,
    required SyncResult result,
    required Duration duration,
  }) {
    publish(SyncOperationCompletedEvent(
      id: _generateEventId(),
      timestamp: DateTime.now(),
      collection: collection,
      operationType: operationType,
      result: result,
      duration: duration,
    ));
  }

  void publishSyncConflictDetected(SyncConflict conflict) {
    publish(SyncConflictDetectedEvent(
      id: _generateEventId(),
      timestamp: DateTime.now(),
      conflict: conflict,
    ));
  }

  void publishSyncConflictResolved({
    required SyncConflict conflict,
    required SyncConflictResolution resolution,
  }) {
    publish(SyncConflictResolvedEvent(
      id: _generateEventId(),
      timestamp: DateTime.now(),
      conflict: conflict,
      resolution: resolution,
    ));
  }

  void publishNetworkStatusChanged({
    required NetworkCondition oldCondition,
    required NetworkCondition newCondition,
  }) {
    publish(NetworkStatusChangedEvent(
      id: _generateEventId(),
      timestamp: DateTime.now(),
      oldCondition: oldCondition,
      newCondition: newCondition,
    ));
  }

  void publishSyncQueueStatusChanged({
    required int queueSize,
    required Map<SyncPriority, int> queueSizeByPriority,
  }) {
    publish(SyncQueueStatusChangedEvent(
      id: _generateEventId(),
      timestamp: DateTime.now(),
      queueSize: queueSize,
      queueSizeByPriority: queueSizeByPriority,
    ));
  }

  void publishSyncTriggerFired(SyncTrigger trigger) {
    publish(SyncTriggerFiredEvent(
      id: _generateEventId(),
      timestamp: DateTime.now(),
      trigger: trigger,
    ));
  }

  void publishBackendConnectionStatusChanged({
    required String backendName,
    required bool isConnected,
    String? errorMessage,
  }) {
    publish(BackendConnectionStatusChangedEvent(
      id: _generateEventId(),
      timestamp: DateTime.now(),
      backendName: backendName,
      isConnected: isConnected,
      errorMessage: errorMessage,
    ));
  }

  void publishDataChangeDetected({
    required String collection,
    required String entityId,
    required SyncOperationType changeType,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
  }) {
    publish(DataChangeDetectedEvent(
      id: _generateEventId(),
      timestamp: DateTime.now(),
      collection: collection,
      entityId: entityId,
      changeType: changeType,
      oldData: oldData,
      newData: newData,
    ));
  }

  void publishSyncErrorOccurred({
    required String collection,
    required SyncError error,
    String? entityId,
    bool willRetry = false,
  }) {
    publish(SyncErrorOccurredEvent(
      id: _generateEventId(),
      timestamp: DateTime.now(),
      collection: collection,
      error: error,
      entityId: entityId,
      willRetry: willRetry,
    ));
  }

  bool _shouldNotifySubscriber(
      EventSubscription subscription, SyncBusEvent event) {
    // Check priority filter
    if (subscription.minimumPriority != null) {
      final minPriorityValue = _priorityValue(subscription.minimumPriority!);
      final eventPriorityValue = _priorityValue(event.priority);
      if (eventPriorityValue < minPriorityValue) {
        return false;
      }
    }

    return true;
  }

  int _priorityValue(EventPriority priority) {
    switch (priority) {
      case EventPriority.low:
        return 0;
      case EventPriority.normal:
        return 1;
      case EventPriority.high:
        return 2;
      case EventPriority.critical:
        return 3;
    }
  }

  void _publishError(
      String message, dynamic error, EventSubscription subscription) {
    publish(SyncErrorOccurredEvent(
      id: _generateEventId(),
      timestamp: DateTime.now(),
      collection: 'event_bus',
      error: SyncError(
        message: '$message: $error',
        type: SyncErrorType.unknown,
      ),
      metadata: {
        'subscription_id': subscription.id,
        'event_type': subscription.eventType.toString(),
      },
    ));
  }

  String _generateEventId() {
    return 'event_${DateTime.now().millisecondsSinceEpoch}_${_eventHistory.length}';
  }

  String _generateSubscriptionId() {
    return 'subscription_${DateTime.now().millisecondsSinceEpoch}_${_subscriptions.length}';
  }

  /// Dispose method to clean up resources
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    clearAllSubscriptions();
    clearEventHistory();
    _eventController.close();
    _instance = null;
  }
}
