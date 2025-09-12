// lib/src/services/usm_sync_replay_service.dart

import 'dart:async';

/// Replay operation types
enum ReplayOperationType {
  create,
  update,
  delete,
  query,
  batch,
  sync,
  conflict,
  rollback,
}

/// Replay event representing a sync operation that can be replayed
class ReplayEvent {
  final String id;
  final DateTime timestamp;
  final ReplayOperationType operation;
  final String collection;
  final String? entityId;
  final Map<String, dynamic> beforeState;
  final Map<String, dynamic> afterState;
  final Map<String, dynamic> operationContext;
  final String? operationId;
  final Duration? originalDuration;
  final bool wasSuccessful;
  final String? errorMessage;

  const ReplayEvent({
    required this.id,
    required this.timestamp,
    required this.operation,
    required this.collection,
    this.entityId,
    this.beforeState = const {},
    this.afterState = const {},
    this.operationContext = const {},
    this.operationId,
    this.originalDuration,
    required this.wasSuccessful,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'operation': operation.name,
        'collection': collection,
        'entityId': entityId,
        'beforeState': beforeState,
        'afterState': afterState,
        'operationContext': operationContext,
        'operationId': operationId,
        'originalDurationMs': originalDuration?.inMilliseconds,
        'wasSuccessful': wasSuccessful,
        'errorMessage': errorMessage,
      };

  factory ReplayEvent.fromJson(Map<String, dynamic> json) {
    return ReplayEvent(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      operation: ReplayOperationType.values.firstWhere(
        (op) => op.name == json['operation'],
      ),
      collection: json['collection'],
      entityId: json['entityId'],
      beforeState: Map<String, dynamic>.from(json['beforeState'] ?? {}),
      afterState: Map<String, dynamic>.from(json['afterState'] ?? {}),
      operationContext:
          Map<String, dynamic>.from(json['operationContext'] ?? {}),
      operationId: json['operationId'],
      originalDuration: json['originalDurationMs'] != null
          ? Duration(milliseconds: json['originalDurationMs'])
          : null,
      wasSuccessful: json['wasSuccessful'],
      errorMessage: json['errorMessage'],
    );
  }

  /// Creates a formatted description of the event
  String get description {
    final buffer = StringBuffer();
    buffer.write('${operation.name.toUpperCase()} ');

    if (entityId != null) {
      buffer.write('$entityId ');
    }

    buffer.write('in $collection');

    if (originalDuration != null) {
      buffer.write(' (${originalDuration!.inMilliseconds}ms)');
    }

    if (!wasSuccessful && errorMessage != null) {
      buffer.write(' - ERROR: $errorMessage');
    }

    return buffer.toString();
  }

  /// Creates a copy of this event with modifications
  ReplayEvent copyWith({
    String? id,
    DateTime? timestamp,
    ReplayOperationType? operation,
    String? collection,
    String? entityId,
    Map<String, dynamic>? beforeState,
    Map<String, dynamic>? afterState,
    Map<String, dynamic>? operationContext,
    String? operationId,
    Duration? originalDuration,
    bool? wasSuccessful,
    String? errorMessage,
  }) {
    return ReplayEvent(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      operation: operation ?? this.operation,
      collection: collection ?? this.collection,
      entityId: entityId ?? this.entityId,
      beforeState: beforeState ?? this.beforeState,
      afterState: afterState ?? this.afterState,
      operationContext: operationContext ?? this.operationContext,
      operationId: operationId ?? this.operationId,
      originalDuration: originalDuration ?? this.originalDuration,
      wasSuccessful: wasSuccessful ?? this.wasSuccessful,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Replay session configuration
class ReplaySessionConfig {
  final String sessionId;
  final DateTime startTime;
  final DateTime? endTime;
  final List<String>? collections;
  final List<ReplayOperationType>? operations;
  final bool replaySuccessfulOnly;
  final bool replayFailedOnly;
  final Duration? speedMultiplier;
  final bool dryRun;
  final Map<String, dynamic> filterCriteria;

  const ReplaySessionConfig({
    required this.sessionId,
    required this.startTime,
    this.endTime,
    this.collections,
    this.operations,
    this.replaySuccessfulOnly = false,
    this.replayFailedOnly = false,
    this.speedMultiplier,
    this.dryRun = false,
    this.filterCriteria = const {},
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'collections': collections,
        'operations': operations?.map((op) => op.name).toList(),
        'replaySuccessfulOnly': replaySuccessfulOnly,
        'replayFailedOnly': replayFailedOnly,
        'speedMultiplierMs': speedMultiplier?.inMilliseconds,
        'dryRun': dryRun,
        'filterCriteria': filterCriteria,
      };
}

/// Replay execution result
class ReplayExecutionResult {
  final String sessionId;
  final String eventId;
  final ReplayOperationType operation;
  final bool success;
  final String message;
  final Duration executionTime;
  final Map<String, dynamic> comparisonResults;
  final List<String> warnings;
  final List<String> errors;

  const ReplayExecutionResult({
    required this.sessionId,
    required this.eventId,
    required this.operation,
    required this.success,
    required this.message,
    required this.executionTime,
    this.comparisonResults = const {},
    this.warnings = const [],
    this.errors = const [],
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'eventId': eventId,
        'operation': operation.name,
        'success': success,
        'message': message,
        'executionTimeMs': executionTime.inMilliseconds,
        'comparisonResults': comparisonResults,
        'warnings': warnings,
        'errors': errors,
      };
}

/// Replay session summary
class ReplaySessionSummary {
  final String sessionId;
  final DateTime startTime;
  final DateTime endTime;
  final int totalEvents;
  final int successfulReplays;
  final int failedReplays;
  final int skippedEvents;
  final Duration totalDuration;
  final Map<String, int> operationCounts;
  final Map<String, int> collectionCounts;
  final List<ReplayExecutionResult> failures;

  const ReplaySessionSummary({
    required this.sessionId,
    required this.startTime,
    required this.endTime,
    required this.totalEvents,
    required this.successfulReplays,
    required this.failedReplays,
    required this.skippedEvents,
    required this.totalDuration,
    this.operationCounts = const {},
    this.collectionCounts = const {},
    this.failures = const [],
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'totalEvents': totalEvents,
        'successfulReplays': successfulReplays,
        'failedReplays': failedReplays,
        'skippedEvents': skippedEvents,
        'totalDurationMs': totalDuration.inMilliseconds,
        'operationCounts': operationCounts,
        'collectionCounts': collectionCounts,
        'failures': failures.map((f) => f.toJson()).toList(),
      };

  /// Calculates success rate percentage
  double get successRate {
    if (totalEvents == 0) return 100.0;
    return ((successfulReplays / totalEvents) * 100).clamp(0.0, 100.0);
  }
}

/// Event filter for replay queries
class ReplayEventFilter {
  final DateTime? startTime;
  final DateTime? endTime;
  final List<String>? collections;
  final List<ReplayOperationType>? operations;
  final List<String>? entityIds;
  final String? operationId;
  final bool? wasSuccessful;
  final String? searchText;
  final int? limit;
  final int? offset;

  const ReplayEventFilter({
    this.startTime,
    this.endTime,
    this.collections,
    this.operations,
    this.entityIds,
    this.operationId,
    this.wasSuccessful,
    this.searchText,
    this.limit,
    this.offset,
  });

  /// Checks if an event matches this filter
  bool matches(ReplayEvent event) {
    if (startTime != null && event.timestamp.isBefore(startTime!)) return false;
    if (endTime != null && event.timestamp.isAfter(endTime!)) return false;
    if (collections != null && !collections!.contains(event.collection))
      return false;
    if (operations != null && !operations!.contains(event.operation))
      return false;
    if (entityIds != null && !entityIds!.contains(event.entityId)) return false;
    if (operationId != null && event.operationId != operationId) return false;
    if (wasSuccessful != null && event.wasSuccessful != wasSuccessful)
      return false;

    if (searchText != null && searchText!.isNotEmpty) {
      final searchLower = searchText!.toLowerCase();
      if (!event.description.toLowerCase().contains(searchLower) &&
          !event.toJson().toString().toLowerCase().contains(searchLower)) {
        return false;
      }
    }

    return true;
  }
}

/// Comprehensive sync replay service
class SyncReplayService {
  final List<ReplayEvent> _eventHistory = [];
  final StreamController<ReplayEvent> _eventStreamController =
      StreamController<ReplayEvent>.broadcast();
  final StreamController<ReplayExecutionResult> _replayStreamController =
      StreamController<ReplayExecutionResult>.broadcast();

  bool _isRecording = false;
  String? _currentSessionId;

  /// Stream of replay events as they're recorded
  Stream<ReplayEvent> get eventStream => _eventStreamController.stream;

  /// Stream of replay execution results
  Stream<ReplayExecutionResult> get replayStream =>
      _replayStreamController.stream;

  /// Starts recording sync events
  void startRecording() {
    _isRecording = true;
    _eventHistory.clear();
  }

  /// Stops recording sync events
  void stopRecording() {
    _isRecording = false;
  }

  /// Checks if currently recording
  bool get isRecording => _isRecording;

  /// Records a sync event
  void recordEvent(ReplayEvent event) {
    if (!_isRecording) return;

    _eventHistory.add(event);
    _eventStreamController.add(event);
  }

  /// Records a sync operation for replay
  void recordSyncOperation({
    required ReplayOperationType operation,
    required String collection,
    String? entityId,
    Map<String, dynamic> beforeState = const {},
    Map<String, dynamic> afterState = const {},
    Map<String, dynamic> operationContext = const {},
    String? operationId,
    Duration? duration,
    bool success = true,
    String? errorMessage,
  }) {
    final event = ReplayEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}_${_eventHistory.length}',
      timestamp: DateTime.now(),
      operation: operation,
      collection: collection,
      entityId: entityId,
      beforeState: beforeState,
      afterState: afterState,
      operationContext: operationContext,
      operationId: operationId,
      originalDuration: duration,
      wasSuccessful: success,
      errorMessage: errorMessage,
    );

    recordEvent(event);
  }

  /// Gets replay events with optional filtering
  List<ReplayEvent> getEvents({ReplayEventFilter? filter}) {
    var events = List<ReplayEvent>.from(_eventHistory);

    if (filter != null) {
      events = events.where(filter.matches).toList();
    }

    // Sort by timestamp
    events.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Apply pagination
    if (filter?.offset != null) {
      final offset = filter!.offset!;
      if (offset < events.length) {
        events = events.sublist(offset);
      } else {
        events = [];
      }
    }

    if (filter?.limit != null) {
      final limit = filter!.limit!;
      if (limit < events.length) {
        events = events.take(limit).toList();
      }
    }

    return events;
  }

  /// Gets events for a specific operation ID
  List<ReplayEvent> getOperationEvents(String operationId) {
    return getEvents(filter: ReplayEventFilter(operationId: operationId));
  }

  /// Gets events for a specific time range
  List<ReplayEvent> getEventsByTimeRange(DateTime start, DateTime end) {
    return getEvents(filter: ReplayEventFilter(startTime: start, endTime: end));
  }

  /// Gets failed events only
  List<ReplayEvent> getFailedEvents() {
    return getEvents(filter: const ReplayEventFilter(wasSuccessful: false));
  }

  /// Gets successful events only
  List<ReplayEvent> getSuccessfulEvents() {
    return getEvents(filter: const ReplayEventFilter(wasSuccessful: true));
  }

  /// Replays a single event
  Future<ReplayExecutionResult> replayEvent(
    ReplayEvent event, {
    bool dryRun = false,
    bool compareResults = true,
  }) async {
    final startTime = DateTime.now();
    _currentSessionId ??= 'session_${startTime.millisecondsSinceEpoch}';

    try {
      final executionResult = await _executeReplayEvent(event, dryRun: dryRun);

      Map<String, dynamic> comparisonResults = {};
      if (compareResults && !dryRun) {
        comparisonResults = await _compareEventResults(event, executionResult);
      }

      final result = ReplayExecutionResult(
        sessionId: _currentSessionId!,
        eventId: event.id,
        operation: event.operation,
        success: executionResult['success'] as bool,
        message: executionResult['message'] as String,
        executionTime: DateTime.now().difference(startTime),
        comparisonResults: comparisonResults,
        warnings: List<String>.from(executionResult['warnings'] ?? []),
        errors: List<String>.from(executionResult['errors'] ?? []),
      );

      _replayStreamController.add(result);
      return result;
    } catch (e) {
      final result = ReplayExecutionResult(
        sessionId: _currentSessionId!,
        eventId: event.id,
        operation: event.operation,
        success: false,
        message: 'Replay failed: $e',
        executionTime: DateTime.now().difference(startTime),
        errors: [e.toString()],
      );

      _replayStreamController.add(result);
      return result;
    }
  }

  /// Replays multiple events in sequence
  Future<ReplaySessionSummary> replayEvents(
    List<ReplayEvent> events, {
    ReplaySessionConfig? config,
  }) async {
    final sessionId =
        config?.sessionId ?? 'session_${DateTime.now().millisecondsSinceEpoch}';
    _currentSessionId = sessionId;

    final startTime = DateTime.now();
    final results = <ReplayExecutionResult>[];
    int skippedEvents = 0;

    for (int i = 0; i < events.length; i++) {
      final event = events[i];

      // Apply filtering if config is provided
      if (config != null && !_shouldReplayEvent(event, config)) {
        skippedEvents++;
        continue;
      }

      // Apply speed control
      if (config?.speedMultiplier != null && i > 0) {
        final previousEvent = events[i - 1];
        final originalInterval =
            event.timestamp.difference(previousEvent.timestamp);
        final adjustedInterval = Duration(
          milliseconds: (originalInterval.inMilliseconds /
                  (config!.speedMultiplier!.inMilliseconds / 1000))
              .round(),
        );

        if (adjustedInterval.inMilliseconds > 0) {
          await Future.delayed(adjustedInterval);
        }
      }

      final result = await replayEvent(
        event,
        dryRun: config?.dryRun ?? false,
      );

      results.add(result);
    }

    final endTime = DateTime.now();
    final operationCounts = <String, int>{};
    final collectionCounts = <String, int>{};
    final failures = <ReplayExecutionResult>[];

    for (final result in results) {
      operationCounts[result.operation.name] =
          (operationCounts[result.operation.name] ?? 0) + 1;

      final event = events.firstWhere((e) => e.id == result.eventId);
      collectionCounts[event.collection] =
          (collectionCounts[event.collection] ?? 0) + 1;

      if (!result.success) {
        failures.add(result);
      }
    }

    final summary = ReplaySessionSummary(
      sessionId: sessionId,
      startTime: startTime,
      endTime: endTime,
      totalEvents: events.length,
      successfulReplays: results.where((r) => r.success).length,
      failedReplays: results.where((r) => !r.success).length,
      skippedEvents: skippedEvents,
      totalDuration: endTime.difference(startTime),
      operationCounts: operationCounts,
      collectionCounts: collectionCounts,
      failures: failures,
    );

    _currentSessionId = null;
    return summary;
  }

  /// Replays events from a specific time range
  Future<ReplaySessionSummary> replayTimeRange(
    DateTime start,
    DateTime end, {
    ReplaySessionConfig? config,
  }) async {
    final events = getEventsByTimeRange(start, end);
    return replayEvents(events, config: config);
  }

  /// Replays failed events only
  Future<ReplaySessionSummary> replayFailedEvents({
    ReplaySessionConfig? config,
  }) async {
    final events = getFailedEvents();
    return replayEvents(events, config: config);
  }

  /// Replays events for a specific operation
  Future<ReplaySessionSummary> replayOperation(
    String operationId, {
    ReplaySessionConfig? config,
  }) async {
    final events = getOperationEvents(operationId);
    return replayEvents(events, config: config);
  }

  /// Creates a replay scenario for testing
  Future<List<ReplayEvent>> createTestScenario({
    required String scenarioName,
    required List<Map<String, dynamic>> operations,
  }) async {
    final events = <ReplayEvent>[];
    var timestamp = DateTime.now();

    for (int i = 0; i < operations.length; i++) {
      final op = operations[i];
      timestamp = timestamp.add(Duration(seconds: i + 1));

      final event = ReplayEvent(
        id: 'scenario_${scenarioName}_$i',
        timestamp: timestamp,
        operation: ReplayOperationType.values.firstWhere(
          (type) => type.name == op['operation'],
        ),
        collection: op['collection'],
        entityId: op['entityId'],
        beforeState: Map<String, dynamic>.from(op['beforeState'] ?? {}),
        afterState: Map<String, dynamic>.from(op['afterState'] ?? {}),
        operationContext: Map<String, dynamic>.from(op['context'] ?? {}),
        operationId: 'test_op_$i',
        wasSuccessful: op['success'] ?? true,
        errorMessage: op['errorMessage'],
      );

      events.add(event);
    }

    return events;
  }

  /// Exports replay events to JSON
  Map<String, dynamic> exportEvents({ReplayEventFilter? filter}) {
    final events = getEvents(filter: filter);

    return {
      'exportedAt': DateTime.now().toIso8601String(),
      'eventCount': events.length,
      'filter': filter != null
          ? {
              'startTime': filter.startTime?.toIso8601String(),
              'endTime': filter.endTime?.toIso8601String(),
              'collections': filter.collections,
              'operations': filter.operations?.map((op) => op.name).toList(),
            }
          : null,
      'events': events.map((event) => event.toJson()).toList(),
    };
  }

  /// Imports replay events from JSON
  void importEvents(Map<String, dynamic> data) {
    final eventsList = data['events'] as List<dynamic>;

    for (final eventData in eventsList) {
      final event = ReplayEvent.fromJson(Map<String, dynamic>.from(eventData));
      _eventHistory.add(event);
    }
  }

  /// Gets replay statistics
  Map<String, dynamic> getReplayStatistics() {
    final totalEvents = _eventHistory.length;
    if (totalEvents == 0) {
      return {
        'totalEvents': 0,
        'successfulEvents': 0,
        'failedEvents': 0,
        'successRate': 100.0,
        'operationBreakdown': {},
        'collectionBreakdown': {},
        'timeRange': null,
      };
    }

    final successfulEvents = _eventHistory.where((e) => e.wasSuccessful).length;
    final failedEvents = totalEvents - successfulEvents;

    final operationBreakdown = <String, int>{};
    final collectionBreakdown = <String, int>{};

    for (final event in _eventHistory) {
      operationBreakdown[event.operation.name] =
          (operationBreakdown[event.operation.name] ?? 0) + 1;
      collectionBreakdown[event.collection] =
          (collectionBreakdown[event.collection] ?? 0) + 1;
    }

    final timestamps = _eventHistory.map((e) => e.timestamp).toList();
    timestamps.sort();

    return {
      'totalEvents': totalEvents,
      'successfulEvents': successfulEvents,
      'failedEvents': failedEvents,
      'successRate': ((successfulEvents / totalEvents) * 100).roundToDouble(),
      'operationBreakdown': operationBreakdown,
      'collectionBreakdown': collectionBreakdown,
      'timeRange': {
        'start': timestamps.first.toIso8601String(),
        'end': timestamps.last.toIso8601String(),
      },
    };
  }

  /// Clears replay history
  void clearHistory() {
    _eventHistory.clear();
  }

  // Private helper methods

  bool _shouldReplayEvent(ReplayEvent event, ReplaySessionConfig config) {
    if (config.collections != null &&
        !config.collections!.contains(event.collection)) {
      return false;
    }

    if (config.operations != null &&
        !config.operations!.contains(event.operation)) {
      return false;
    }

    if (config.replaySuccessfulOnly && !event.wasSuccessful) {
      return false;
    }

    if (config.replayFailedOnly && event.wasSuccessful) {
      return false;
    }

    return true;
  }

  Future<Map<String, dynamic>> _executeReplayEvent(
    ReplayEvent event, {
    required bool dryRun,
  }) async {
    // This would integrate with the actual sync manager to replay the operation
    // For now, return a mock result

    if (dryRun) {
      return {
        'success': true,
        'message':
            'Dry run - would execute ${event.operation.name} on ${event.collection}',
        'warnings': [],
        'errors': [],
      };
    }

    // Simulate execution time
    await Future.delayed(const Duration(milliseconds: 100));

    // Mock success/failure based on original event success
    return {
      'success': event.wasSuccessful,
      'message': event.wasSuccessful
          ? 'Successfully replayed ${event.operation.name}'
          : 'Failed to replay ${event.operation.name}: ${event.errorMessage}',
      'warnings': [],
      'errors':
          event.wasSuccessful ? [] : [event.errorMessage ?? 'Unknown error'],
    };
  }

  Future<Map<String, dynamic>> _compareEventResults(
    ReplayEvent originalEvent,
    Map<String, dynamic> replayResult,
  ) async {
    // This would compare the original event results with replay results
    return {
      'stateMatches': true,
      'differences': [],
      'confidence': 0.95,
    };
  }

  /// Disposes the replay service
  void dispose() {
    _eventStreamController.close();
    _replayStreamController.close();
  }
}
