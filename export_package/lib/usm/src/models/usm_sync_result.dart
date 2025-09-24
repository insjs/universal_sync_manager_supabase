/// Represents the result of a sync operation
///
/// This class encapsulates the outcome of any sync operation, whether successful
/// or failed, along with relevant metadata for tracking and debugging.

import '../config/usm_sync_enums.dart';

class SyncResult {
  /// Whether the operation was successful
  final bool isSuccess;

  /// The data returned from the operation (if successful)
  final Map<String, dynamic>? data;

  /// Error information (if operation failed)
  final SyncError? error;

  /// The type of sync action that was performed
  final SyncAction action;

  /// Timestamp when the operation completed
  final DateTime timestamp;

  /// Unique identifier for this operation (for tracking)
  final String operationId;

  /// The collection/table that was affected
  final String? collection;

  /// The record ID that was affected (for single-record operations)
  final String? recordId;

  /// Number of records affected (for batch operations)
  final int affectedRecords;

  /// Duration of the operation
  final Duration? duration;

  /// Backend-specific metadata
  final Map<String, dynamic> metadata;

  /// Sync version after the operation (for conflict detection)
  final int? syncVersion;

  const SyncResult({
    required this.isSuccess,
    this.data,
    this.error,
    required this.action,
    required this.timestamp,
    required this.operationId,
    this.collection,
    this.recordId,
    this.affectedRecords = 0,
    this.duration,
    this.metadata = const {},
    this.syncVersion,
  });

  /// Creates a successful result
  factory SyncResult.success({
    required Map<String, dynamic> data,
    required SyncAction action,
    DateTime? timestamp,
    String? operationId,
    String? collection,
    String? recordId,
    int affectedRecords = 1,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
    int? syncVersion,
  }) {
    return SyncResult(
      isSuccess: true,
      data: data,
      action: action,
      timestamp: timestamp ?? DateTime.now(),
      operationId: operationId ?? _generateOperationId(),
      collection: collection,
      recordId: recordId,
      affectedRecords: affectedRecords,
      duration: duration,
      metadata: metadata,
      syncVersion: syncVersion,
    );
  }

  /// Creates a failed result
  factory SyncResult.error({
    required SyncError error,
    required SyncAction action,
    DateTime? timestamp,
    String? operationId,
    String? collection,
    String? recordId,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) {
    return SyncResult(
      isSuccess: false,
      error: error,
      action: action,
      timestamp: timestamp ?? DateTime.now(),
      operationId: operationId ?? _generateOperationId(),
      collection: collection,
      recordId: recordId,
      affectedRecords: 0,
      duration: duration,
      metadata: metadata,
    );
  }

  /// Creates a batch success result
  factory SyncResult.batchSuccess({
    required List<Map<String, dynamic>> items,
    required SyncAction action,
    DateTime? timestamp,
    String? operationId,
    String? collection,
    int? affectedRecords,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) {
    return SyncResult(
      isSuccess: true,
      data: {'items': items, 'count': items.length},
      action: action,
      timestamp: timestamp ?? DateTime.now(),
      operationId: operationId ?? _generateOperationId(),
      collection: collection,
      affectedRecords: affectedRecords ?? items.length,
      duration: duration,
      metadata: metadata,
    );
  }

  /// Gets the record data as a typed object
  T? getRecord<T>() {
    if (!isSuccess || data == null) return null;
    return data! as T?;
  }

  /// Gets the batch items as a typed list
  List<T> getBatchItems<T>() {
    if (!isSuccess || data == null) return [];
    final items = data!['items'] as List?;
    return items?.cast<T>() ?? [];
  }

  /// Gets a metadata value with type safety
  T? getMetadata<T>(String key) {
    final value = metadata[key];
    return value is T ? value : null;
  }

  /// Converts to JSON for logging and debugging
  Map<String, dynamic> toJson() {
    return {
      'isSuccess': isSuccess,
      'data': data,
      'error': error?.toJson(),
      'action': action.name,
      'timestamp': timestamp.toIso8601String(),
      'operationId': operationId,
      'collection': collection,
      'recordId': recordId,
      'affectedRecords': affectedRecords,
      'duration': duration?.inMilliseconds,
      'metadata': metadata,
      'syncVersion': syncVersion,
    };
  }

  /// Creates from JSON
  factory SyncResult.fromJson(Map<String, dynamic> json) {
    return SyncResult(
      isSuccess: json['isSuccess'] as bool,
      data: json['data'] as Map<String, dynamic>?,
      error: json['error'] != null
          ? SyncError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
      action: SyncAction.values.firstWhere(
        (a) => a.name == json['action'],
        orElse: () => SyncAction.unknown,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      operationId: json['operationId'] as String,
      collection: json['collection'] as String?,
      recordId: json['recordId'] as String?,
      affectedRecords: json['affectedRecords'] as int,
      duration: json['duration'] != null
          ? Duration(milliseconds: json['duration'] as int)
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      syncVersion: json['syncVersion'] as int?,
    );
  }

  /// Generates a unique operation ID
  static String _generateOperationId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'op_${timestamp}_$random';
  }
}

/// Represents an error that occurred during a sync operation
class SyncError {
  /// The type/category of error
  final SyncErrorType type;

  /// Human-readable error message
  final String message;

  /// Detailed error description for debugging
  final String? details;

  /// Error code from the backend (if available)
  final String? errorCode;

  /// HTTP status code (for network-related errors)
  final int? httpStatusCode;

  /// Whether this error is retryable
  final bool isRetryable;

  /// Whether this error indicates a conflict
  final bool isConflict;

  /// The original exception that caused this error
  final dynamic originalException;

  /// Stack trace for debugging
  final StackTrace? stackTrace;

  /// Additional error context
  final Map<String, dynamic> context;

  /// Timestamp when the error occurred
  final DateTime timestamp;

  SyncError({
    required this.type,
    required this.message,
    this.details,
    this.errorCode,
    this.httpStatusCode,
    this.isRetryable = false,
    this.isConflict = false,
    this.originalException,
    this.stackTrace,
    this.context = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Creates a network error
  factory SyncError.network({
    required String message,
    String? details,
    int? httpStatusCode,
    String? errorCode,
    bool isRetryable = true,
    dynamic originalException,
    StackTrace? stackTrace,
    Map<String, dynamic> context = const {},
  }) {
    return SyncError(
      type: SyncErrorType.network,
      message: message,
      details: details,
      httpStatusCode: httpStatusCode,
      errorCode: errorCode,
      isRetryable: isRetryable,
      originalException: originalException,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// Creates an authentication error
  factory SyncError.authentication({
    required String message,
    String? details,
    String? errorCode,
    dynamic originalException,
    StackTrace? stackTrace,
    Map<String, dynamic> context = const {},
  }) {
    return SyncError(
      type: SyncErrorType.authentication,
      message: message,
      details: details,
      errorCode: errorCode,
      isRetryable: false,
      originalException: originalException,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// Creates an authorization error
  factory SyncError.authorization({
    required String message,
    String? details,
    String? errorCode,
    dynamic originalException,
    StackTrace? stackTrace,
    Map<String, dynamic> context = const {},
  }) {
    return SyncError(
      type: SyncErrorType.authorization,
      message: message,
      details: details,
      errorCode: errorCode,
      isRetryable: false,
      originalException: originalException,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// Creates a validation error
  factory SyncError.validation({
    required String message,
    String? details,
    Map<String, List<String>>? fieldErrors,
    String? errorCode,
    dynamic originalException,
    StackTrace? stackTrace,
  }) {
    return SyncError(
      type: SyncErrorType.validation,
      message: message,
      details: details,
      errorCode: errorCode,
      isRetryable: false,
      originalException: originalException,
      stackTrace: stackTrace,
      context: {'fieldErrors': fieldErrors ?? {}},
    );
  }

  /// Creates a conflict error
  factory SyncError.conflict({
    required String message,
    String? details,
    Map<String, dynamic>? conflictData,
    String? errorCode,
    dynamic originalException,
    StackTrace? stackTrace,
  }) {
    return SyncError(
      type: SyncErrorType.conflict,
      message: message,
      details: details,
      errorCode: errorCode,
      isRetryable: false,
      isConflict: true,
      originalException: originalException,
      stackTrace: stackTrace,
      context: {'conflictData': conflictData ?? {}},
    );
  }

  /// Creates a timeout error
  factory SyncError.timeout({
    required String message,
    String? details,
    Duration? timeout,
    bool isRetryable = true,
    dynamic originalException,
    StackTrace? stackTrace,
  }) {
    return SyncError(
      type: SyncErrorType.timeout,
      message: message,
      details: details,
      isRetryable: isRetryable,
      originalException: originalException,
      stackTrace: stackTrace,
      context: {'timeout': timeout?.inMilliseconds},
    );
  }

  /// Creates a rate limit error
  factory SyncError.rateLimit({
    required String message,
    String? details,
    Duration? retryAfter,
    String? errorCode,
    dynamic originalException,
    StackTrace? stackTrace,
  }) {
    return SyncError(
      type: SyncErrorType.rateLimit,
      message: message,
      details: details,
      errorCode: errorCode,
      isRetryable: true,
      originalException: originalException,
      stackTrace: stackTrace,
      context: {'retryAfter': retryAfter?.inSeconds},
    );
  }

  /// Creates a backend-specific error
  factory SyncError.backend({
    required String message,
    String? details,
    String? errorCode,
    int? httpStatusCode,
    bool isRetryable = false,
    dynamic originalException,
    StackTrace? stackTrace,
    Map<String, dynamic> context = const {},
  }) {
    return SyncError(
      type: SyncErrorType.backend,
      message: message,
      details: details,
      errorCode: errorCode,
      httpStatusCode: httpStatusCode,
      isRetryable: isRetryable,
      originalException: originalException,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// Creates an unknown error
  factory SyncError.unknown({
    required String message,
    String? details,
    dynamic originalException,
    StackTrace? stackTrace,
    Map<String, dynamic> context = const {},
  }) {
    return SyncError(
      type: SyncErrorType.unknown,
      message: message,
      details: details,
      isRetryable: true,
      originalException: originalException,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// Gets field validation errors
  Map<String, List<String>> get fieldErrors {
    final errors = context['fieldErrors'];
    if (errors is Map<String, List<String>>) {
      return errors;
    }
    return {};
  }

  /// Gets conflict data
  Map<String, dynamic> get conflictData {
    final data = context['conflictData'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return {};
  }

  /// Gets retry after duration (for rate limiting)
  Duration? get retryAfter {
    final seconds = context['retryAfter'];
    if (seconds is int) {
      return Duration(seconds: seconds);
    }
    return null;
  }

  /// Converts to JSON for logging
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'message': message,
      'details': details,
      'errorCode': errorCode,
      'httpStatusCode': httpStatusCode,
      'isRetryable': isRetryable,
      'isConflict': isConflict,
      'context': context,
      'timestamp': timestamp.toIso8601String(),
      'originalException': originalException?.toString(),
    };
  }

  /// Creates from JSON
  factory SyncError.fromJson(Map<String, dynamic> json) {
    return SyncError(
      type: SyncErrorType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => SyncErrorType.unknown,
      ),
      message: json['message'] as String,
      details: json['details'] as String?,
      errorCode: json['errorCode'] as String?,
      httpStatusCode: json['httpStatusCode'] as int?,
      isRetryable: json['isRetryable'] as bool? ?? false,
      isConflict: json['isConflict'] as bool? ?? false,
      context: Map<String, dynamic>.from(json['context'] as Map? ?? {}),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('SyncError(${type.name}): $message');
    if (details != null) {
      buffer.write(' - $details');
    }
    if (errorCode != null) {
      buffer.write(' [Code: $errorCode]');
    }
    return buffer.toString();
  }
}
