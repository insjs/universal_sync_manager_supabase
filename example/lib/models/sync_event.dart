/// Event types for Universal Sync Manager operations
/// Provides real-time feedback for sync progress, errors, and data changes

enum SyncEventType {
  // Sync operation events
  syncStarted,
  syncProgress,
  syncCompleted,
  syncError,

  // Data operation events
  dataCreated,
  dataUpdated,
  dataDeleted,
  dataQueried,

  // Conflict events
  conflictDetected,
  conflictResolved,

  // Connection events
  connectionEstablished,
  connectionLost,
  connectionRestored,

  // Auth events
  authenticationSuccess,
  authenticationFailed,
  tokenRefreshed,
}

/// Base class for all sync events
abstract class SyncEvent {
  final SyncEventType type;
  final DateTime timestamp;
  final String? operationId;
  final Map<String, dynamic>? metadata;

  SyncEvent({
    required this.type,
    DateTime? timestamp,
    this.operationId,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'SyncEvent(type: $type, timestamp: $timestamp, operationId: $operationId)';
  }
}

/// Event for sync operation progress
class SyncProgressEvent extends SyncEvent {
  final String operation;
  final int current;
  final int total;
  final String? message;
  final String? collection;

  SyncProgressEvent({
    required this.operation,
    required this.current,
    required this.total,
    this.message,
    this.collection,
    String? operationId,
    Map<String, dynamic>? metadata,
  }) : super(
          type: SyncEventType.syncProgress,
          operationId: operationId,
          metadata: metadata,
        );

  double get progressPercentage => total > 0 ? (current / total) * 100 : 0;

  @override
  String toString() {
    return 'SyncProgressEvent(operation: $operation, progress: $current/$total, collection: $collection)';
  }
}

/// Event for sync operation completion
class SyncCompletedEvent extends SyncEvent {
  final String operation;
  final bool success;
  final int affectedRecords;
  final String? collection;
  final Duration duration;
  final String? message;

  SyncCompletedEvent({
    required this.operation,
    required this.success,
    required this.affectedRecords,
    required this.duration,
    this.collection,
    this.message,
    String? operationId,
    Map<String, dynamic>? metadata,
  }) : super(
          type: SyncEventType.syncCompleted,
          operationId: operationId,
          metadata: metadata,
        );

  @override
  String toString() {
    return 'SyncCompletedEvent(operation: $operation, success: $success, records: $affectedRecords, duration: ${duration.inMilliseconds}ms)';
  }
}

/// Event for sync errors
class SyncErrorEvent extends SyncEvent {
  final String operation;
  final String error;
  final String? collection;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? errorDetails;

  SyncErrorEvent({
    required this.operation,
    required this.error,
    this.collection,
    this.stackTrace,
    this.errorDetails,
    String? operationId,
    Map<String, dynamic>? metadata,
  }) : super(
          type: SyncEventType.syncError,
          operationId: operationId,
          metadata: metadata,
        );

  @override
  String toString() {
    return 'SyncErrorEvent(operation: $operation, error: $error, collection: $collection)';
  }
}

/// Event for data operations (CRUD)
class DataOperationEvent extends SyncEvent {
  final String operation; // create, read, update, delete, query
  final String collection;
  final String? recordId;
  final Map<String, dynamic>? data;
  final bool success;
  final String? error;

  DataOperationEvent({
    required this.operation,
    required this.collection,
    required this.success,
    this.recordId,
    this.data,
    this.error,
    String? operationId,
    Map<String, dynamic>? metadata,
  }) : super(
          type: _getEventType(operation),
          operationId: operationId,
          metadata: metadata,
        );

  static SyncEventType _getEventType(String operation) {
    switch (operation.toLowerCase()) {
      case 'create':
        return SyncEventType.dataCreated;
      case 'update':
        return SyncEventType.dataUpdated;
      case 'delete':
        return SyncEventType.dataDeleted;
      case 'query':
      case 'read':
        return SyncEventType.dataQueried;
      default:
        return SyncEventType.dataQueried;
    }
  }

  @override
  String toString() {
    return 'DataOperationEvent(operation: $operation, collection: $collection, recordId: $recordId, success: $success)';
  }
}

/// Event for conflict detection and resolution
class ConflictEvent extends SyncEvent {
  final String collection;
  final String recordId;
  final String conflictType;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final String resolution;
  final bool resolved;

  ConflictEvent({
    required this.collection,
    required this.recordId,
    required this.conflictType,
    required this.localData,
    required this.remoteData,
    required this.resolution,
    required this.resolved,
    String? operationId,
    Map<String, dynamic>? metadata,
  }) : super(
          type: resolved
              ? SyncEventType.conflictResolved
              : SyncEventType.conflictDetected,
          operationId: operationId,
          metadata: metadata,
        );

  @override
  String toString() {
    return 'ConflictEvent(collection: $collection, recordId: $recordId, type: $conflictType, resolved: $resolved)';
  }
}

/// Event for connection state changes
class ConnectionEvent extends SyncEvent {
  final String state; // connected, disconnected, reconnecting
  final String? backend;
  final String? error;

  ConnectionEvent({
    required this.state,
    this.backend,
    this.error,
    String? operationId,
    Map<String, dynamic>? metadata,
  }) : super(
          type: _getConnectionEventType(state),
          operationId: operationId,
          metadata: metadata,
        );

  static SyncEventType _getConnectionEventType(String state) {
    switch (state.toLowerCase()) {
      case 'connected':
        return SyncEventType.connectionEstablished;
      case 'disconnected':
        return SyncEventType.connectionLost;
      case 'reconnecting':
      case 'restored':
        return SyncEventType.connectionRestored;
      default:
        return SyncEventType.connectionLost;
    }
  }

  @override
  String toString() {
    return 'ConnectionEvent(state: $state, backend: $backend, error: $error)';
  }
}

/// Event for authentication state changes
class AuthEvent extends SyncEvent {
  final String operation; // login, logout, token_refresh, auth_failed
  final bool success;
  final String? userId;
  final String? organizationId;
  final String? error;

  AuthEvent({
    required this.operation,
    required this.success,
    this.userId,
    this.organizationId,
    this.error,
    String? operationId,
    Map<String, dynamic>? metadata,
  }) : super(
          type: _getAuthEventType(operation, success),
          operationId: operationId,
          metadata: metadata,
        );

  static SyncEventType _getAuthEventType(String operation, bool success) {
    if (operation == 'token_refresh' && success) {
      return SyncEventType.tokenRefreshed;
    }
    if (success) {
      return SyncEventType.authenticationSuccess;
    } else {
      return SyncEventType.authenticationFailed;
    }
  }

  @override
  String toString() {
    return 'AuthEvent(operation: $operation, success: $success, userId: $userId, organizationId: $organizationId)';
  }
}
