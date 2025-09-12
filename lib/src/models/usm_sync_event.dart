import 'dart:async';

import 'usm_sync_result.dart';
import '../interfaces/usm_sync_backend_adapter.dart';
import '../config/usm_sync_enums.dart';

/// Interface for managing real-time subscriptions to backend data changes
///
/// This interface provides a standard way to handle real-time updates from
/// different backend services, enabling live synchronization of data changes.
abstract class IRealtimeSubscription {
  /// Unique identifier for this subscription
  String get subscriptionId;

  /// Collection/table being subscribed to
  String get collection;

  /// Subscription options and filters
  SyncSubscriptionOptions get options;

  /// Current status of the subscription
  SyncSubscriptionStatus get status;

  /// Stream of sync events from this subscription
  Stream<SyncEvent> get eventStream;

  /// When the subscription was created
  DateTime get createdAt;

  /// Last activity timestamp
  DateTime? get lastActivity;

  /// Error information if subscription failed
  SyncError? get error;

  /// Cancels the subscription and stops receiving events
  Future<void> cancel();

  /// Pauses the subscription temporarily
  Future<void> pause();

  /// Resumes a paused subscription
  Future<void> resume();

  /// Updates the subscription options/filters
  Future<void> updateOptions(SyncSubscriptionOptions newOptions);
}

/// Implementation of real-time subscription
class RealtimeSubscription implements IRealtimeSubscription {
  @override
  final String subscriptionId;

  @override
  final String collection;

  @override
  SyncSubscriptionOptions options;

  @override
  SyncSubscriptionStatus status;

  @override
  final DateTime createdAt;

  @override
  DateTime? lastActivity;

  @override
  SyncError? error;

  /// Internal stream controller for events
  final _eventController = StreamController<SyncEvent>.broadcast();

  /// Callback to cancel backend subscription
  final Future<void> Function() _cancelCallback;

  RealtimeSubscription({
    required this.subscriptionId,
    required this.collection,
    required this.options,
    required dynamic backendSubscription, // Parameter but not stored
    required Future<void> Function() cancelCallback,
    this.status = SyncSubscriptionStatus.active,
    DateTime? createdAt,
  })  : _cancelCallback = cancelCallback,
        createdAt = createdAt ?? DateTime.now();

  @override
  Stream<SyncEvent> get eventStream => _eventController.stream;

  /// Adds an event to the stream
  void addEvent(SyncEvent event) {
    if (status == SyncSubscriptionStatus.active) {
      lastActivity = DateTime.now();
      _eventController.add(event);
    }
  }

  /// Adds an error to the stream
  void addError(SyncError error) {
    this.error = error;
    status = SyncSubscriptionStatus.error;
    _eventController.addError(error);
  }

  @override
  Future<void> cancel() async {
    if (status == SyncSubscriptionStatus.cancelled) return;

    status = SyncSubscriptionStatus.cancelled;
    await _cancelCallback();
    await _eventController.close();
  }

  @override
  Future<void> pause() async {
    if (status == SyncSubscriptionStatus.active) {
      status = SyncSubscriptionStatus.paused;
    }
  }

  @override
  Future<void> resume() async {
    if (status == SyncSubscriptionStatus.paused) {
      status = SyncSubscriptionStatus.active;
    }
  }

  @override
  Future<void> updateOptions(SyncSubscriptionOptions newOptions) async {
    options = newOptions;
    // Note: Implementing this may require recreating the backend subscription
    // depending on the backend capabilities
  }
}

/// Represents a real-time sync event from the backend
class SyncEvent {
  /// Type of event that occurred
  final SyncEventType type;

  /// Collection/table where the event occurred
  final String collection;

  /// ID of the affected record
  final String? recordId;

  /// Data associated with the event
  final Map<String, dynamic>? data;

  /// Previous data (for update events)
  final Map<String, dynamic>? previousData;

  /// Timestamp when the event occurred
  final DateTime timestamp;

  /// User/source that triggered the event
  final String? triggeredBy;

  /// Event metadata from the backend
  final Map<String, dynamic> metadata;

  /// Organization ID for multi-tenant filtering
  final String? organizationId;

  /// Sync version for conflict detection
  final int? syncVersion;

  const SyncEvent({
    required this.type,
    required this.collection,
    this.recordId,
    this.data,
    this.previousData,
    required this.timestamp,
    this.triggeredBy,
    this.metadata = const {},
    this.organizationId,
    this.syncVersion,
  });

  /// Creates a record creation event
  factory SyncEvent.create({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    DateTime? timestamp,
    String? triggeredBy,
    Map<String, dynamic> metadata = const {},
    String? organizationId,
    int? syncVersion,
  }) {
    return SyncEvent(
      type: SyncEventType.create,
      collection: collection,
      recordId: recordId,
      data: data,
      timestamp: timestamp ?? DateTime.now(),
      triggeredBy: triggeredBy,
      metadata: metadata,
      organizationId: organizationId,
      syncVersion: syncVersion,
    );
  }

  /// Creates a record update event
  factory SyncEvent.update({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    Map<String, dynamic>? previousData,
    DateTime? timestamp,
    String? triggeredBy,
    Map<String, dynamic> metadata = const {},
    String? organizationId,
    int? syncVersion,
  }) {
    return SyncEvent(
      type: SyncEventType.update,
      collection: collection,
      recordId: recordId,
      data: data,
      previousData: previousData,
      timestamp: timestamp ?? DateTime.now(),
      triggeredBy: triggeredBy,
      metadata: metadata,
      organizationId: organizationId,
      syncVersion: syncVersion,
    );
  }

  /// Creates a record deletion event
  factory SyncEvent.delete({
    required String collection,
    required String recordId,
    Map<String, dynamic>? previousData,
    DateTime? timestamp,
    String? triggeredBy,
    Map<String, dynamic> metadata = const {},
    String? organizationId,
    int? syncVersion,
  }) {
    return SyncEvent(
      type: SyncEventType.delete,
      collection: collection,
      recordId: recordId,
      previousData: previousData,
      timestamp: timestamp ?? DateTime.now(),
      triggeredBy: triggeredBy,
      metadata: metadata,
      organizationId: organizationId,
      syncVersion: syncVersion,
    );
  }

  /// Creates a connection status event
  factory SyncEvent.connection({
    required String collection,
    required SyncConnectionState state,
    DateTime? timestamp,
    Map<String, dynamic> metadata = const {},
  }) {
    return SyncEvent(
      type: SyncEventType.connection,
      collection: collection,
      data: {'connectionState': state.name},
      timestamp: timestamp ?? DateTime.now(),
      metadata: metadata,
    );
  }

  /// Creates an error event
  factory SyncEvent.error({
    required String collection,
    required SyncError error,
    DateTime? timestamp,
    Map<String, dynamic> metadata = const {},
  }) {
    return SyncEvent(
      type: SyncEventType.error,
      collection: collection,
      data: error.toJson(),
      timestamp: timestamp ?? DateTime.now(),
      metadata: metadata,
    );
  }

  /// Gets the connection state from a connection event
  SyncConnectionState? get connectionState {
    if (type != SyncEventType.connection || data == null) return null;
    final stateName = data!['connectionState'] as String?;
    if (stateName == null) return null;

    return SyncConnectionState.values.firstWhere(
      (state) => state.name == stateName,
      orElse: () => SyncConnectionState.disconnected,
    );
  }

  /// Gets the error from an error event
  SyncError? get eventError {
    if (type != SyncEventType.error || data == null) return null;
    try {
      return SyncError.fromJson(data!);
    } catch (e) {
      return null;
    }
  }

  /// Gets a metadata value with type safety
  T? getMetadata<T>(String key) {
    final value = metadata[key];
    return value is T ? value : null;
  }

  /// Checks if this event affects the specified organization
  bool affectsOrganization(String orgId) {
    return organizationId == null || organizationId == orgId;
  }

  /// Converts to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'collection': collection,
      'recordId': recordId,
      'data': data,
      'previousData': previousData,
      'timestamp': timestamp.toIso8601String(),
      'triggeredBy': triggeredBy,
      'metadata': metadata,
      'organization_id': organizationId,
      'sync_version': syncVersion,
    };
  }

  /// Creates from JSON
  factory SyncEvent.fromJson(Map<String, dynamic> json) {
    return SyncEvent(
      type: SyncEventType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => SyncEventType.unknown,
      ),
      collection: json['collection'] as String,
      recordId: json['recordId'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      previousData: json['previousData'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      triggeredBy: json['triggeredBy'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      organizationId: json['organization_id'] as String?,
      syncVersion: json['sync_version'] as int?,
    );
  }

  @override
  String toString() {
    return 'SyncEvent(${type.name} on $collection${recordId != null ? '/$recordId' : ''})';
  }
}

/// Types of sync events that can occur
// This enum is now defined in usm_sync_enums.dart
// Keeping this comment for reference

/// Aggregated sync event for batch processing
class SyncEventBatch {
  /// List of events in this batch
  final List<SyncEvent> events;

  /// Batch timestamp
  final DateTime timestamp;

  /// Batch ID for tracking
  final String batchId;

  /// Collection this batch applies to
  final String? collection;

  /// Organization this batch applies to
  final String? organizationId;

  const SyncEventBatch({
    required this.events,
    required this.timestamp,
    required this.batchId,
    this.collection,
    this.organizationId,
  });

  /// Groups events by type
  Map<SyncEventType, List<SyncEvent>> get eventsByType {
    final grouped = <SyncEventType, List<SyncEvent>>{};
    for (final event in events) {
      grouped.putIfAbsent(event.type, () => []).add(event);
    }
    return grouped;
  }

  /// Gets all affected record IDs
  Set<String> get affectedRecordIds {
    return events
        .where((e) => e.recordId != null)
        .map((e) => e.recordId!)
        .toSet();
  }

  /// Checks if batch contains any errors
  bool get hasErrors {
    return events.any((e) => e.type == SyncEventType.error);
  }

  /// Filters events by organization
  List<SyncEvent> eventsForOrganization(String orgId) {
    return events.where((e) => e.affectsOrganization(orgId)).toList();
  }
}

/// Manager for handling real-time subscription lifecycle
class SubscriptionManager {
  final Map<String, IRealtimeSubscription> _subscriptions = {};

  /// Gets all active subscriptions
  List<IRealtimeSubscription> get activeSubscriptions {
    return _subscriptions.values
        .where((sub) => sub.status == SyncSubscriptionStatus.active)
        .toList();
  }

  /// Gets subscription by ID
  IRealtimeSubscription? getSubscription(String subscriptionId) {
    return _subscriptions[subscriptionId];
  }

  /// Adds a subscription
  void addSubscription(IRealtimeSubscription subscription) {
    _subscriptions[subscription.subscriptionId] = subscription;
  }

  /// Removes a subscription
  Future<void> removeSubscription(String subscriptionId) async {
    final subscription = _subscriptions.remove(subscriptionId);
    if (subscription != null) {
      await subscription.cancel();
    }
  }

  /// Cancels all subscriptions
  Future<void> cancelAllSubscriptions() async {
    final futures = _subscriptions.values.map((sub) => sub.cancel());
    await Future.wait(futures);
    _subscriptions.clear();
  }

  /// Gets subscriptions for a specific collection
  List<IRealtimeSubscription> getSubscriptionsForCollection(String collection) {
    return _subscriptions.values
        .where((sub) => sub.collection == collection)
        .toList();
  }
}
