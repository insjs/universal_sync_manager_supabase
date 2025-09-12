// lib/src/services/usm_sync_analytics_service.dart

import 'dart:async';
import 'dart:math' as math;
import '../config/usm_sync_enums.dart';

/// Sync operation metrics for detailed tracking
class SyncOperationMetrics {
  final String operationId;
  final String entityType;
  final String collection;
  final SyncOperationType operationType;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration? duration;
  final SyncOperationStatus status;
  final int itemsProcessed;
  final int itemsSuccessful;
  final int itemsFailed;
  final int bytesTransferred;
  final String? errorMessage;
  final Map<String, dynamic> metadata;

  const SyncOperationMetrics({
    required this.operationId,
    required this.entityType,
    required this.collection,
    required this.operationType,
    required this.startTime,
    this.endTime,
    this.duration,
    required this.status,
    this.itemsProcessed = 0,
    this.itemsSuccessful = 0,
    this.itemsFailed = 0,
    this.bytesTransferred = 0,
    this.errorMessage,
    this.metadata = const {},
  });

  /// Creates completed metrics
  SyncOperationMetrics complete({
    required DateTime endTime,
    int? itemsSuccessful,
    int? itemsFailed,
    int? bytesTransferred,
    String? errorMessage,
  }) {
    final duration = endTime.difference(startTime);
    final status = (itemsFailed ?? this.itemsFailed) > 0
        ? SyncOperationStatus.failed
        : SyncOperationStatus.completed;

    return SyncOperationMetrics(
      operationId: operationId,
      entityType: entityType,
      collection: collection,
      operationType: operationType,
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      status: status,
      itemsProcessed: itemsProcessed,
      itemsSuccessful: itemsSuccessful ?? this.itemsSuccessful,
      itemsFailed: itemsFailed ?? this.itemsFailed,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      errorMessage: errorMessage,
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'operationId': operationId,
        'entityType': entityType,
        'collection': collection,
        'operationType': operationType.name,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'durationMs': duration?.inMilliseconds,
        'status': status.name,
        'itemsProcessed': itemsProcessed,
        'itemsSuccessful': itemsSuccessful,
        'itemsFailed': itemsFailed,
        'bytesTransferred': bytesTransferred,
        'errorMessage': errorMessage,
        'metadata': metadata,
      };

  factory SyncOperationMetrics.fromJson(Map<String, dynamic> json) {
    return SyncOperationMetrics(
      operationId: json['operationId'],
      entityType: json['entityType'],
      collection: json['collection'],
      operationType: SyncOperationType.values.firstWhere(
        (t) => t.name == json['operationType'],
      ),
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      duration: json['durationMs'] != null
          ? Duration(milliseconds: json['durationMs'])
          : null,
      status: SyncOperationStatus.values.firstWhere(
        (s) => s.name == json['status'],
      ),
      itemsProcessed: json['itemsProcessed'] ?? 0,
      itemsSuccessful: json['itemsSuccessful'] ?? 0,
      itemsFailed: json['itemsFailed'] ?? 0,
      bytesTransferred: json['bytesTransferred'] ?? 0,
      errorMessage: json['errorMessage'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

/// Enum for sync operation status
enum SyncOperationStatus {
  pending,
  running,
  completed,
  failed,
  cancelled,
  retrying,
}

/// Performance metrics for sync operations
class SyncPerformanceMetrics {
  final Duration averageOperationTime;
  final double operationsPerSecond;
  final int totalOperations;
  final int successfulOperations;
  final int failedOperations;
  final double successRate;
  final int totalBytesTransferred;
  final double averageBytesPerSecond;
  final Map<String, int> operationTypeCount;
  final Map<String, Duration> averageTimeByType;
  final DateTime periodStart;
  final DateTime periodEnd;

  const SyncPerformanceMetrics({
    required this.averageOperationTime,
    required this.operationsPerSecond,
    required this.totalOperations,
    required this.successfulOperations,
    required this.failedOperations,
    required this.successRate,
    required this.totalBytesTransferred,
    required this.averageBytesPerSecond,
    required this.operationTypeCount,
    required this.averageTimeByType,
    required this.periodStart,
    required this.periodEnd,
  });

  Map<String, dynamic> toJson() => {
        'averageOperationTimeMs': averageOperationTime.inMilliseconds,
        'operationsPerSecond': operationsPerSecond,
        'totalOperations': totalOperations,
        'successfulOperations': successfulOperations,
        'failedOperations': failedOperations,
        'successRate': successRate,
        'totalBytesTransferred': totalBytesTransferred,
        'averageBytesPerSecond': averageBytesPerSecond,
        'operationTypeCount': operationTypeCount,
        'averageTimeByType':
            averageTimeByType.map((k, v) => MapEntry(k, v.inMilliseconds)),
        'periodStart': periodStart.toIso8601String(),
        'periodEnd': periodEnd.toIso8601String(),
      };
}

/// Sync failure analysis data
class SyncFailureAnalysis {
  final int totalFailures;
  final Map<String, int> failuresByType;
  final Map<String, int> failuresByCollection;
  final Map<String, int> errorCodeFrequency;
  final List<String> topErrorMessages;
  final double meanTimeBetweenFailures;
  final DateTime firstFailure;
  final DateTime lastFailure;
  final List<SyncOperationMetrics> recentFailures;

  const SyncFailureAnalysis({
    required this.totalFailures,
    required this.failuresByType,
    required this.failuresByCollection,
    required this.errorCodeFrequency,
    required this.topErrorMessages,
    required this.meanTimeBetweenFailures,
    required this.firstFailure,
    required this.lastFailure,
    required this.recentFailures,
  });

  Map<String, dynamic> toJson() => {
        'totalFailures': totalFailures,
        'failuresByType': failuresByType,
        'failuresByCollection': failuresByCollection,
        'errorCodeFrequency': errorCodeFrequency,
        'topErrorMessages': topErrorMessages,
        'meanTimeBetweenFailures': meanTimeBetweenFailures,
        'firstFailure': firstFailure.toIso8601String(),
        'lastFailure': lastFailure.toIso8601String(),
        'recentFailures': recentFailures.map((f) => f.toJson()).toList(),
      };
}

/// Real-time sync health status
class SyncHealthStatus {
  final SyncHealthLevel healthLevel;
  final double healthScore; // 0.0 to 1.0
  final List<String> activeIssues;
  final List<String> warnings;
  final Map<String, dynamic> healthMetrics;
  final DateTime lastUpdated;

  const SyncHealthStatus({
    required this.healthLevel,
    required this.healthScore,
    required this.activeIssues,
    required this.warnings,
    required this.healthMetrics,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
        'healthLevel': healthLevel.name,
        'healthScore': healthScore,
        'activeIssues': activeIssues,
        'warnings': warnings,
        'healthMetrics': healthMetrics,
        'lastUpdated': lastUpdated.toIso8601String(),
      };
}

/// Enum for sync health levels
enum SyncHealthLevel {
  excellent, // 0.9+
  good, // 0.7-0.89
  fair, // 0.5-0.69
  poor, // 0.3-0.49
  critical, // <0.3
}

/// Comprehensive sync analytics service
class SyncAnalyticsService {
  final List<SyncOperationMetrics> _operationHistory = [];
  final Map<String, SyncOperationMetrics> _activeOperations = {};
  final StreamController<SyncOperationMetrics> _operationCompletedController =
      StreamController<SyncOperationMetrics>.broadcast();
  final StreamController<SyncHealthStatus> _healthStatusController =
      StreamController<SyncHealthStatus>.broadcast();

  Timer? _healthMonitorTimer;
  Duration _retentionPeriod = const Duration(days: 30);
  int _maxHistorySize = 10000;

  /// Stream of completed operations
  Stream<SyncOperationMetrics> get operationCompleted =>
      _operationCompletedController.stream;

  /// Stream of health status updates
  Stream<SyncHealthStatus> get healthStatus => _healthStatusController.stream;

  /// Starts tracking a new sync operation
  String startOperation({
    required String entityType,
    required String collection,
    required SyncOperationType operationType,
    Map<String, dynamic> metadata = const {},
  }) {
    final operationId =
        'op_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';

    final metrics = SyncOperationMetrics(
      operationId: operationId,
      entityType: entityType,
      collection: collection,
      operationType: operationType,
      startTime: DateTime.now(),
      status: SyncOperationStatus.running,
      metadata: metadata,
    );

    _activeOperations[operationId] = metrics;
    return operationId;
  }

  /// Updates an active operation with progress
  void updateOperation(
    String operationId, {
    int? itemsProcessed,
    int? itemsSuccessful,
    int? itemsFailed,
    int? bytesTransferred,
    Map<String, dynamic>? metadata,
  }) {
    final operation = _activeOperations[operationId];
    if (operation == null) return;

    final updatedMetrics = SyncOperationMetrics(
      operationId: operation.operationId,
      entityType: operation.entityType,
      collection: operation.collection,
      operationType: operation.operationType,
      startTime: operation.startTime,
      status: operation.status,
      itemsProcessed: itemsProcessed ?? operation.itemsProcessed,
      itemsSuccessful: itemsSuccessful ?? operation.itemsSuccessful,
      itemsFailed: itemsFailed ?? operation.itemsFailed,
      bytesTransferred: bytesTransferred ?? operation.bytesTransferred,
      metadata: metadata != null
          ? {...operation.metadata, ...metadata}
          : operation.metadata,
    );

    _activeOperations[operationId] = updatedMetrics;
  }

  /// Completes an operation and moves it to history
  void completeOperation(
    String operationId, {
    int? itemsSuccessful,
    int? itemsFailed,
    int? bytesTransferred,
    String? errorMessage,
  }) {
    final operation = _activeOperations[operationId];
    if (operation == null) return;

    final completedMetrics = operation.complete(
      endTime: DateTime.now(),
      itemsSuccessful: itemsSuccessful,
      itemsFailed: itemsFailed,
      bytesTransferred: bytesTransferred,
      errorMessage: errorMessage,
    );

    _activeOperations.remove(operationId);
    _operationHistory.add(completedMetrics);

    _operationCompletedController.add(completedMetrics);
    _cleanupHistory();
    _updateHealthStatus();
  }

  /// Cancels an active operation
  void cancelOperation(String operationId, {String? reason}) {
    final operation = _activeOperations[operationId];
    if (operation == null) return;

    final cancelledMetrics = SyncOperationMetrics(
      operationId: operation.operationId,
      entityType: operation.entityType,
      collection: operation.collection,
      operationType: operation.operationType,
      startTime: operation.startTime,
      endTime: DateTime.now(),
      duration: DateTime.now().difference(operation.startTime),
      status: SyncOperationStatus.cancelled,
      itemsProcessed: operation.itemsProcessed,
      itemsSuccessful: operation.itemsSuccessful,
      itemsFailed: operation.itemsFailed,
      bytesTransferred: operation.bytesTransferred,
      errorMessage: reason ?? 'Operation cancelled',
      metadata: operation.metadata,
    );

    _activeOperations.remove(operationId);
    _operationHistory.add(cancelledMetrics);
    _operationCompletedController.add(cancelledMetrics);
  }

  /// Gets current performance metrics
  SyncPerformanceMetrics getPerformanceMetrics({
    Duration? period,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    final now = DateTime.now();
    final start = startTime ??
        (period != null
            ? now.subtract(period)
            : now.subtract(const Duration(hours: 24)));
    final end = endTime ?? now;

    final relevantOps = _operationHistory
        .where(
            (op) => op.startTime.isAfter(start) && op.startTime.isBefore(end))
        .toList();

    if (relevantOps.isEmpty) {
      return SyncPerformanceMetrics(
        averageOperationTime: Duration.zero,
        operationsPerSecond: 0.0,
        totalOperations: 0,
        successfulOperations: 0,
        failedOperations: 0,
        successRate: 0.0,
        totalBytesTransferred: 0,
        averageBytesPerSecond: 0.0,
        operationTypeCount: {},
        averageTimeByType: {},
        periodStart: start,
        periodEnd: end,
      );
    }

    final totalDuration = relevantOps
        .where((op) => op.duration != null)
        .fold<Duration>(Duration.zero, (sum, op) => sum + op.duration!);

    final averageTime = relevantOps.isNotEmpty
        ? Duration(
            milliseconds:
                (totalDuration.inMilliseconds / relevantOps.length).round())
        : Duration.zero;

    final successful = relevantOps
        .where((op) => op.status == SyncOperationStatus.completed)
        .length;
    final failed = relevantOps
        .where((op) => op.status == SyncOperationStatus.failed)
        .length;
    final successRate =
        relevantOps.isNotEmpty ? successful / relevantOps.length : 0.0;

    final totalBytes =
        relevantOps.fold<int>(0, (sum, op) => sum + op.bytesTransferred);
    final periodDuration = end.difference(start);
    final avgBytesPerSecond = periodDuration.inSeconds > 0
        ? totalBytes / periodDuration.inSeconds
        : 0.0;

    final operationTypeCount = <String, int>{};
    final timeByType = <String, List<Duration>>{};

    for (final op in relevantOps) {
      operationTypeCount[op.operationType.name] =
          (operationTypeCount[op.operationType.name] ?? 0) + 1;

      if (op.duration != null) {
        timeByType
            .putIfAbsent(op.operationType.name, () => [])
            .add(op.duration!);
      }
    }

    final averageTimeByType = <String, Duration>{};
    for (final entry in timeByType.entries) {
      final totalMs = entry.value
          .fold<int>(0, (sum, duration) => sum + duration.inMilliseconds);
      averageTimeByType[entry.key] =
          Duration(milliseconds: (totalMs / entry.value.length).round());
    }

    return SyncPerformanceMetrics(
      averageOperationTime: averageTime,
      operationsPerSecond: periodDuration.inSeconds > 0
          ? relevantOps.length / periodDuration.inSeconds
          : 0.0,
      totalOperations: relevantOps.length,
      successfulOperations: successful,
      failedOperations: failed,
      successRate: successRate,
      totalBytesTransferred: totalBytes,
      averageBytesPerSecond: avgBytesPerSecond,
      operationTypeCount: operationTypeCount,
      averageTimeByType: averageTimeByType,
      periodStart: start,
      periodEnd: end,
    );
  }

  /// Gets failure analysis
  SyncFailureAnalysis getFailureAnalysis({Duration? period}) {
    final now = DateTime.now();
    final start = period != null
        ? now.subtract(period)
        : now.subtract(const Duration(days: 7));

    final failures = _operationHistory
        .where((op) =>
            op.status == SyncOperationStatus.failed &&
            op.startTime.isAfter(start))
        .toList();

    if (failures.isEmpty) {
      return SyncFailureAnalysis(
        totalFailures: 0,
        failuresByType: {},
        failuresByCollection: {},
        errorCodeFrequency: {},
        topErrorMessages: [],
        meanTimeBetweenFailures: 0.0,
        firstFailure: now,
        lastFailure: now,
        recentFailures: [],
      );
    }

    final failuresByType = <String, int>{};
    final failuresByCollection = <String, int>{};
    final errorMessages = <String>[];

    for (final failure in failures) {
      failuresByType[failure.operationType.name] =
          (failuresByType[failure.operationType.name] ?? 0) + 1;
      failuresByCollection[failure.collection] =
          (failuresByCollection[failure.collection] ?? 0) + 1;

      if (failure.errorMessage != null && failure.errorMessage!.isNotEmpty) {
        errorMessages.add(failure.errorMessage!);
      }
    }

    // Calculate top error messages
    final errorCounts = <String, int>{};
    for (final error in errorMessages) {
      errorCounts[error] = (errorCounts[error] ?? 0) + 1;
    }
    final topErrors = errorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value))
      ..take(10);

    final sortedFailures = failures
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final firstFailure = sortedFailures.first.startTime;
    final lastFailure = sortedFailures.last.startTime;

    final timeBetweenFailures = failures.length > 1
        ? lastFailure.difference(firstFailure).inMilliseconds /
            (failures.length - 1)
        : 0.0;

    return SyncFailureAnalysis(
      totalFailures: failures.length,
      failuresByType: failuresByType,
      failuresByCollection: failuresByCollection,
      errorCodeFrequency: errorCounts,
      topErrorMessages: topErrors.map((e) => e.key).toList(),
      meanTimeBetweenFailures: timeBetweenFailures,
      firstFailure: firstFailure,
      lastFailure: lastFailure,
      recentFailures: failures.take(20).toList(),
    );
  }

  /// Gets current health status
  SyncHealthStatus getCurrentHealthStatus() {
    final recentMetrics =
        getPerformanceMetrics(period: const Duration(hours: 1));
    final recentFailures = getFailureAnalysis(period: const Duration(hours: 1));

    double healthScore = 1.0;
    final issues = <String>[];
    final warnings = <String>[];

    // Success rate impact (40% of score)
    healthScore *= math.max(0.0, recentMetrics.successRate);

    // Performance impact (30% of score)
    if (recentMetrics.averageOperationTime.inSeconds > 30) {
      healthScore *= 0.8;
      warnings.add('Operations taking longer than expected');
    }
    if (recentMetrics.averageOperationTime.inSeconds > 60) {
      healthScore *= 0.7;
      issues.add('Severe performance degradation detected');
    }

    // Failure frequency impact (30% of score)
    if (recentFailures.totalFailures > 0) {
      final failureRate = recentFailures.totalFailures /
          math.max(1, recentMetrics.totalOperations);
      if (failureRate > 0.1) {
        healthScore *= 0.6;
        issues.add(
            'High failure rate: ${(failureRate * 100).toStringAsFixed(1)}%');
      } else if (failureRate > 0.05) {
        healthScore *= 0.8;
        warnings.add(
            'Elevated failure rate: ${(failureRate * 100).toStringAsFixed(1)}%');
      }
    }

    // Active operations impact
    if (_activeOperations.length > 50) {
      healthScore *= 0.9;
      warnings.add('High number of concurrent operations');
    }

    // Determine health level
    SyncHealthLevel healthLevel;
    if (healthScore >= 0.9) {
      healthLevel = SyncHealthLevel.excellent;
    } else if (healthScore >= 0.7) {
      healthLevel = SyncHealthLevel.good;
    } else if (healthScore >= 0.5) {
      healthLevel = SyncHealthLevel.fair;
    } else if (healthScore >= 0.3) {
      healthLevel = SyncHealthLevel.poor;
    } else {
      healthLevel = SyncHealthLevel.critical;
    }

    return SyncHealthStatus(
      healthLevel: healthLevel,
      healthScore: healthScore,
      activeIssues: issues,
      warnings: warnings,
      healthMetrics: {
        'successRate': recentMetrics.successRate,
        'averageOperationTimeMs':
            recentMetrics.averageOperationTime.inMilliseconds,
        'activeOperations': _activeOperations.length,
        'recentFailures': recentFailures.totalFailures,
        'operationsPerSecond': recentMetrics.operationsPerSecond,
      },
      lastUpdated: DateTime.now(),
    );
  }

  /// Starts automatic health monitoring
  void startHealthMonitoring({Duration interval = const Duration(minutes: 5)}) {
    _healthMonitorTimer?.cancel();
    _healthMonitorTimer = Timer.periodic(interval, (_) {
      final health = getCurrentHealthStatus();
      _healthStatusController.add(health);
    });
  }

  /// Stops health monitoring
  void stopHealthMonitoring() {
    _healthMonitorTimer?.cancel();
    _healthMonitorTimer = null;
  }

  /// Gets all active operations
  List<SyncOperationMetrics> getActiveOperations() =>
      List.unmodifiable(_activeOperations.values);

  /// Gets operation history
  List<SyncOperationMetrics> getOperationHistory({
    int? limit,
    DateTime? since,
    String? collection,
    SyncOperationType? operationType,
  }) {
    var filtered = _operationHistory.asMap().entries.toList();

    if (since != null) {
      filtered = filtered
          .where((entry) => entry.value.startTime.isAfter(since))
          .toList();
    }

    if (collection != null) {
      filtered = filtered
          .where((entry) => entry.value.collection == collection)
          .toList();
    }

    if (operationType != null) {
      filtered = filtered
          .where((entry) => entry.value.operationType == operationType)
          .toList();
    }

    // Sort by start time descending (most recent first)
    filtered.sort((a, b) => b.value.startTime.compareTo(a.value.startTime));

    if (limit != null) {
      filtered = filtered.take(limit).toList();
    }

    return filtered.map((entry) => entry.value).toList();
  }

  /// Exports analytics data
  Map<String, dynamic> exportAnalytics({Duration? period}) {
    final performance = getPerformanceMetrics(period: period);
    final failures = getFailureAnalysis(period: period);
    final health = getCurrentHealthStatus();

    return {
      'exportedAt': DateTime.now().toIso8601String(),
      'period': period?.inMilliseconds,
      'performance': performance.toJson(),
      'failures': failures.toJson(),
      'health': health.toJson(),
      'activeOperations': _activeOperations.length,
      'totalHistorySize': _operationHistory.length,
    };
  }

  /// Cleans up old history based on retention policy
  void _cleanupHistory() {
    final cutoff = DateTime.now().subtract(_retentionPeriod);

    _operationHistory.removeWhere((op) => op.startTime.isBefore(cutoff));

    if (_operationHistory.length > _maxHistorySize) {
      _operationHistory.sort((a, b) => b.startTime.compareTo(a.startTime));
      _operationHistory.removeRange(_maxHistorySize, _operationHistory.length);
    }
  }

  /// Updates health status when operations complete
  void _updateHealthStatus() {
    // Only update if health monitoring is active
    if (_healthMonitorTimer != null) {
      final health = getCurrentHealthStatus();
      _healthStatusController.add(health);
    }
  }

  /// Sets retention policy
  void setRetentionPolicy({Duration? retentionPeriod, int? maxHistorySize}) {
    _retentionPeriod = retentionPeriod ?? _retentionPeriod;
    _maxHistorySize = maxHistorySize ?? _maxHistorySize;
    _cleanupHistory();
  }

  /// Disposes the service
  void dispose() {
    _healthMonitorTimer?.cancel();
    _operationCompletedController.close();
    _healthStatusController.close();
  }
}
