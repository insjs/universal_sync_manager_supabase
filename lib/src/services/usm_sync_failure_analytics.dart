// lib/src/services/usm_sync_failure_analytics.dart

import 'dart:async';
import 'dart:math' as math;

import 'usm_sync_analytics_service.dart';
import 'usm_sync_performance_monitor.dart';

/// Failure pattern types for categorization
enum FailurePatternType {
  intermittent, // Random failures
  recurring, // Regular pattern
  cascading, // Failure causes more failures
  timeout, // Network/timeout related
  authentication, // Auth related failures
  dataCorruption, // Data integrity issues
  resourceExhaustion, // Memory/disk/network limits
  unknown, // Unclassified
}

/// Detailed failure classification
class FailureClassification {
  final FailurePatternType patternType;
  final String category;
  final String subcategory;
  final double confidence; // 0.0 to 1.0
  final List<String> indicators;
  final Map<String, dynamic> metadata;

  const FailureClassification({
    required this.patternType,
    required this.category,
    required this.subcategory,
    required this.confidence,
    required this.indicators,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'patternType': patternType.name,
        'category': category,
        'subcategory': subcategory,
        'confidence': confidence,
        'indicators': indicators,
        'metadata': metadata,
      };
}

/// Failure prediction model
class FailurePrediction {
  final double probability; // 0.0 to 1.0
  final Duration timeframe;
  final List<String> riskFactors;
  final List<String> recommendations;
  final Map<String, double> contributingFactors;
  final DateTime predictionTime;

  const FailurePrediction({
    required this.probability,
    required this.timeframe,
    required this.riskFactors,
    required this.recommendations,
    required this.contributingFactors,
    required this.predictionTime,
  });

  Map<String, dynamic> toJson() => {
        'probability': probability,
        'timeframeMinutes': timeframe.inMinutes,
        'riskFactors': riskFactors,
        'recommendations': recommendations,
        'contributingFactors': contributingFactors,
        'predictionTime': predictionTime.toIso8601String(),
      };
}

/// Failure trend analysis
class FailureTrendAnalysis {
  final TrendDirection direction;
  final double magnitude; // Rate of change
  final Duration analysisWindow;
  final List<DataPoint> dataPoints;
  final Map<String, dynamic> trendMetrics;
  final DateTime analysisTime;

  const FailureTrendAnalysis({
    required this.direction,
    required this.magnitude,
    required this.analysisWindow,
    required this.dataPoints,
    required this.trendMetrics,
    required this.analysisTime,
  });

  Map<String, dynamic> toJson() => {
        'direction': direction.name,
        'magnitude': magnitude,
        'analysisWindowMinutes': analysisWindow.inMinutes,
        'dataPoints': dataPoints.map((d) => d.toJson()).toList(),
        'trendMetrics': trendMetrics,
        'analysisTime': analysisTime.toIso8601String(),
      };
}

/// Trend direction enumeration
enum TrendDirection {
  improving,
  stable,
  degrading,
  volatile,
}

/// Data point for trend analysis
class DataPoint {
  final DateTime timestamp;
  final double value;
  final Map<String, dynamic> context;

  const DataPoint({
    required this.timestamp,
    required this.value,
    this.context = const {},
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'value': value,
        'context': context,
      };
}

/// Root cause analysis result
class RootCauseAnalysis {
  final String primaryCause;
  final List<String> contributingCauses;
  final double confidence;
  final List<String> evidenceChain;
  final Map<String, dynamic> analysisData;
  final List<String> recommendedActions;
  final DateTime analysisTime;

  const RootCauseAnalysis({
    required this.primaryCause,
    required this.contributingCauses,
    required this.confidence,
    required this.evidenceChain,
    required this.analysisData,
    required this.recommendedActions,
    required this.analysisTime,
  });

  Map<String, dynamic> toJson() => {
        'primaryCause': primaryCause,
        'contributingCauses': contributingCauses,
        'confidence': confidence,
        'evidenceChain': evidenceChain,
        'analysisData': analysisData,
        'recommendedActions': recommendedActions,
        'analysisTime': analysisTime.toIso8601String(),
      };
}

/// Comprehensive sync failure analytics service
class SyncFailureAnalytics {
  final SyncAnalyticsService _analyticsService;
  final SyncPerformanceMonitor? _performanceMonitor;

  final List<FailureClassification> _classifiedFailures = [];
  final List<FailurePrediction> _predictions = [];
  final Map<String, List<SyncOperationMetrics>> _failurePatterns = {};

  final StreamController<FailureClassification> _classificationController =
      StreamController<FailureClassification>.broadcast();
  final StreamController<FailurePrediction> _predictionController =
      StreamController<FailurePrediction>.broadcast();
  final StreamController<RootCauseAnalysis> _rootCauseController =
      StreamController<RootCauseAnalysis>.broadcast();

  Timer? _analysisTimer;
  Duration _analysisInterval = const Duration(minutes: 15);

  // Classification thresholds
  double _timeoutFailureThreshold = 5.0; // seconds

  SyncFailureAnalytics(this._analyticsService, [this._performanceMonitor]) {
    _initializeAnalysis();
  }

  /// Stream of failure classifications
  Stream<FailureClassification> get classifications =>
      _classificationController.stream;

  /// Stream of failure predictions
  Stream<FailurePrediction> get predictions => _predictionController.stream;

  /// Stream of root cause analyses
  Stream<RootCauseAnalysis> get rootCauseAnalyses =>
      _rootCauseController.stream;

  /// Starts automatic failure analysis
  void startAnalysis({Duration? interval}) {
    _analysisInterval = interval ?? _analysisInterval;

    _analysisTimer?.cancel();
    _analysisTimer = Timer.periodic(_analysisInterval, (_) {
      _performAnalysis();
    });

    // Perform initial analysis
    _performAnalysis();
  }

  /// Stops automatic analysis
  void stopAnalysis() {
    _analysisTimer?.cancel();
    _analysisTimer = null;
  }

  /// Classifies a specific failure
  FailureClassification classifyFailure(SyncOperationMetrics failure) {
    final indicators = <String>[];
    var confidence = 0.0;
    var category = 'unknown';
    var subcategory = 'unclassified';
    var patternType = FailurePatternType.unknown;

    // Analyze error message for patterns
    final errorMessage = failure.errorMessage?.toLowerCase() ?? '';

    // Authentication failures
    if (_isAuthFailure(errorMessage)) {
      category = 'authentication';
      subcategory = 'credential_invalid';
      patternType = FailurePatternType.authentication;
      confidence += 0.3;
      indicators.add('Authentication error detected in message');
    }

    // Timeout failures
    if (_isTimeoutFailure(errorMessage, failure.duration)) {
      category = 'network';
      subcategory = 'timeout';
      patternType = FailurePatternType.timeout;
      confidence += 0.3;
      indicators.add('Timeout pattern detected');
    }

    // Network connectivity failures
    if (_isNetworkFailure(errorMessage)) {
      category = 'network';
      subcategory = 'connectivity';
      patternType = FailurePatternType.intermittent;
      confidence += 0.25;
      indicators.add('Network connectivity issue detected');
    }

    // Data corruption failures
    if (_isDataCorruptionFailure(errorMessage)) {
      category = 'data';
      subcategory = 'corruption';
      patternType = FailurePatternType.dataCorruption;
      confidence += 0.4;
      indicators.add('Data integrity issue detected');
    }

    // Resource exhaustion
    if (_isResourceExhaustionFailure(errorMessage)) {
      category = 'resources';
      subcategory = 'exhaustion';
      patternType = FailurePatternType.resourceExhaustion;
      confidence += 0.35;
      indicators.add('Resource exhaustion detected');
    }

    // Pattern analysis
    _analyzeFailurePattern(failure, indicators);

    // Adjust confidence based on number of indicators
    confidence = math.min(1.0, confidence + (indicators.length * 0.1));

    final classification = FailureClassification(
      patternType: patternType,
      category: category,
      subcategory: subcategory,
      confidence: confidence,
      indicators: indicators,
      metadata: {
        'operationId': failure.operationId,
        'collection': failure.collection,
        'operationType': failure.operationType.name,
        'errorMessage': failure.errorMessage,
        'duration': failure.duration?.inMilliseconds,
        'itemsFailed': failure.itemsFailed,
      },
    );

    _classifiedFailures.add(classification);
    _classificationController.add(classification);

    return classification;
  }

  /// Analyzes failure trends over time
  FailureTrendAnalysis analyzeFailureTrends({Duration? period}) {
    final now = DateTime.now();
    final window = period ?? const Duration(hours: 24);
    final start = now.subtract(window);

    final failures = _analyticsService
        .getOperationHistory(since: start)
        .where((op) => op.status == SyncOperationStatus.failed)
        .toList();

    // Create hourly buckets for trend analysis
    final buckets = <DateTime, int>{};
    final bucketSize = Duration(minutes: 60);

    for (var time = start; time.isBefore(now); time = time.add(bucketSize)) {
      buckets[time] = 0;
    }

    // Count failures per bucket
    for (final failure in failures) {
      final bucketTime = DateTime(
        failure.startTime.year,
        failure.startTime.month,
        failure.startTime.day,
        failure.startTime.hour,
      );

      if (buckets.containsKey(bucketTime)) {
        buckets[bucketTime] = buckets[bucketTime]! + 1;
      }
    }

    // Convert to data points
    final dataPoints = buckets.entries
        .map((entry) => DataPoint(
              timestamp: entry.key,
              value: entry.value.toDouble(),
            ))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Calculate trend direction and magnitude
    final direction = _calculateTrendDirection(dataPoints);
    final magnitude = _calculateTrendMagnitude(dataPoints);

    return FailureTrendAnalysis(
      direction: direction,
      magnitude: magnitude,
      analysisWindow: window,
      dataPoints: dataPoints,
      trendMetrics: {
        'totalFailures': failures.length,
        'averageFailuresPerHour': failures.length / window.inHours,
        'peakFailures': dataPoints.isNotEmpty
            ? dataPoints.map((d) => d.value).reduce(math.max)
            : 0,
        'variance': _calculateVariance(dataPoints.map((d) => d.value).toList()),
      },
      analysisTime: now,
    );
  }

  /// Predicts future failures based on current patterns
  FailurePrediction predictFailures({Duration? lookAhead}) {
    final timeframe = lookAhead ?? const Duration(hours: 2);
    final recentMetrics = _analyticsService.getPerformanceMetrics(
      period: const Duration(hours: 6),
    );

    var probability = 0.0;
    final riskFactors = <String>[];
    final recommendations = <String>[];
    final contributingFactors = <String, double>{};

    // Analyze current failure rate
    final currentFailureRate = recentMetrics.totalOperations > 0
        ? recentMetrics.failedOperations / recentMetrics.totalOperations
        : 0.0;

    if (currentFailureRate > 0.1) {
      probability += 0.3;
      riskFactors.add('High current failure rate');
      contributingFactors['currentFailureRate'] = currentFailureRate;
    }

    // Analyze performance degradation
    final avgResponseTime = recentMetrics.averageOperationTime.inMilliseconds;
    if (avgResponseTime > 5000) {
      probability += 0.2;
      riskFactors.add('Slow operation performance');
      contributingFactors['responseTime'] = avgResponseTime.toDouble();
      recommendations.add('Investigate performance bottlenecks');
    }

    // Analyze network conditions
    // Note: In real implementation, integrate with network monitoring
    final networkRisk = _assessNetworkRisk();
    probability += networkRisk * 0.25;
    if (networkRisk > 0.5) {
      riskFactors.add('Unstable network conditions');
      contributingFactors['networkRisk'] = networkRisk;
      recommendations.add('Monitor network stability');
    }

    // Analyze resource usage
    final resourceRisk = _assessResourceRisk();
    probability += resourceRisk * 0.25;
    if (resourceRisk > 0.7) {
      riskFactors.add('High resource usage');
      contributingFactors['resourceRisk'] = resourceRisk;
      recommendations.add('Free up system resources');
    }

    // Cap probability at 1.0
    probability = math.min(1.0, probability);

    // Add general recommendations based on probability
    if (probability > 0.7) {
      recommendations.add('Consider pausing non-critical sync operations');
    } else if (probability > 0.5) {
      recommendations.add('Increase monitoring frequency');
    }

    final prediction = FailurePrediction(
      probability: probability,
      timeframe: timeframe,
      riskFactors: riskFactors,
      recommendations: recommendations,
      contributingFactors: contributingFactors,
      predictionTime: DateTime.now(),
    );

    _predictions.add(prediction);
    _predictionController.add(prediction);

    return prediction;
  }

  /// Performs root cause analysis for a failure pattern
  RootCauseAnalysis performRootCauseAnalysis(
      List<SyncOperationMetrics> relatedFailures) {
    final evidenceChain = <String>[];
    final contributingCauses = <String>[];
    final analysisData = <String, dynamic>{};
    final recommendations = <String>[];

    var primaryCause = 'Unknown';
    var confidence = 0.0;

    // Analyze temporal patterns
    final timings = relatedFailures.map((f) => f.startTime).toList()..sort();
    if (timings.length > 1) {
      final intervals = <Duration>[];
      for (int i = 1; i < timings.length; i++) {
        intervals.add(timings[i].difference(timings[i - 1]));
      }

      final avgInterval = intervals.isNotEmpty
          ? Duration(
              milliseconds: (intervals
                          .map((d) => d.inMilliseconds)
                          .reduce((a, b) => a + b) /
                      intervals.length)
                  .round())
          : Duration.zero;

      analysisData['averageFailureInterval'] = avgInterval.inMinutes;
      evidenceChain.add('Analyzed temporal failure pattern');

      if (avgInterval.inMinutes < 5) {
        contributingCauses.add('Rapid consecutive failures');
        confidence += 0.2;
      }
    }

    // Analyze error message patterns
    final errorMessages = relatedFailures
        .where((f) => f.errorMessage != null)
        .map((f) => f.errorMessage!)
        .toList();

    if (errorMessages.isNotEmpty) {
      final commonErrors = _findCommonErrorPatterns(errorMessages);
      analysisData['commonErrorPatterns'] = commonErrors;
      evidenceChain.add('Analyzed error message patterns');

      if (commonErrors.isNotEmpty) {
        primaryCause = 'Error pattern: ${commonErrors.first}';
        confidence += 0.3;
      }
    }

    // Analyze affected collections
    final collections = relatedFailures.map((f) => f.collection).toSet();
    analysisData['affectedCollections'] = collections.toList();
    evidenceChain.add('Analyzed affected data collections');

    if (collections.length == 1) {
      contributingCauses
          .add('Isolated to single collection: ${collections.first}');
      recommendations
          .add('Review ${collections.first} collection configuration');
      confidence += 0.2;
    } else if (collections.length > 1) {
      contributingCauses.add('Cross-collection impact detected');
      recommendations.add('Check system-wide configuration');
      confidence += 0.15;
    }

    // Analyze operation types
    final operationTypes = relatedFailures.map((f) => f.operationType).toSet();
    analysisData['affectedOperationTypes'] =
        operationTypes.map((t) => t.name).toList();
    evidenceChain.add('Analyzed affected operation types');

    // Generate recommendations based on analysis
    if (confidence > 0.7) {
      recommendations.add('High confidence root cause identified');
    } else if (confidence > 0.4) {
      recommendations
          .add('Likely root cause identified, monitor for confirmation');
    } else {
      recommendations.add('Multiple potential causes, continue investigation');
    }

    final analysis = RootCauseAnalysis(
      primaryCause: primaryCause,
      contributingCauses: contributingCauses,
      confidence: confidence,
      evidenceChain: evidenceChain,
      analysisData: analysisData,
      recommendedActions: recommendations,
      analysisTime: DateTime.now(),
    );

    _rootCauseController.add(analysis);
    return analysis;
  }

  /// Gets failure statistics by category
  Map<String, dynamic> getFailureStatistics({Duration? period}) {
    final now = DateTime.now();
    final start = period != null
        ? now.subtract(period)
        : now.subtract(const Duration(days: 7));

    final relevantClassifications = _classifiedFailures
        .where((c) =>
            c.metadata['timestamp'] != null &&
            DateTime.parse(c.metadata['timestamp']).isAfter(start))
        .toList();

    final categoryStats = <String, int>{};
    final patternStats = <String, int>{};
    final confidenceStats = <double>[];

    for (final classification in relevantClassifications) {
      categoryStats[classification.category] =
          (categoryStats[classification.category] ?? 0) + 1;
      patternStats[classification.patternType.name] =
          (patternStats[classification.patternType.name] ?? 0) + 1;
      confidenceStats.add(classification.confidence);
    }

    final avgConfidence = confidenceStats.isNotEmpty
        ? confidenceStats.reduce((a, b) => a + b) / confidenceStats.length
        : 0.0;

    return {
      'totalClassifiedFailures': relevantClassifications.length,
      'categoryBreakdown': categoryStats,
      'patternBreakdown': patternStats,
      'averageClassificationConfidence': avgConfidence,
      'highConfidenceClassifications':
          confidenceStats.where((c) => c > 0.7).length,
      'analysisTimeframe': period?.inHours ?? 168, // Default 7 days
    };
  }

  /// Initialize analysis components
  void _initializeAnalysis() {
    // Listen to completed operations for real-time classification
    _analyticsService.operationCompleted.listen((operation) {
      if (operation.status == SyncOperationStatus.failed) {
        classifyFailure(operation);
      }
    });
  }

  /// Performs periodic analysis
  void _performAnalysis() {
    // Classify recent failures
    final recentFailures = _analyticsService
        .getOperationHistory(
          limit: 50,
          since: DateTime.now().subtract(Duration(hours: 1)),
        )
        .where((op) => op.status == SyncOperationStatus.failed)
        .toList();

    for (final failure in recentFailures) {
      // Only classify if not already classified
      final alreadyClassified = _classifiedFailures.any(
        (c) => c.metadata['operationId'] == failure.operationId,
      );

      if (!alreadyClassified) {
        classifyFailure(failure);
      }
    }

    // Generate predictions
    predictFailures();

    // Analyze trends
    analyzeFailureTrends();
  }

  /// Checks if failure is authentication related
  bool _isAuthFailure(String errorMessage) {
    const authKeywords = [
      'authentication',
      'unauthorized',
      'forbidden',
      'invalid token',
      'expired token',
      'access denied',
      'permission',
      'login',
    ];

    return authKeywords.any((keyword) => errorMessage.contains(keyword));
  }

  /// Checks if failure is timeout related
  bool _isTimeoutFailure(String errorMessage, Duration? duration) {
    const timeoutKeywords = ['timeout', 'timed out', 'deadline exceeded'];

    final hasTimeoutKeyword =
        timeoutKeywords.any((keyword) => errorMessage.contains(keyword));
    final isSlowOperation =
        duration != null && duration.inSeconds > _timeoutFailureThreshold;

    return hasTimeoutKeyword || isSlowOperation;
  }

  /// Checks if failure is network related
  bool _isNetworkFailure(String errorMessage) {
    const networkKeywords = [
      'network',
      'connection',
      'offline',
      'no internet',
      'dns',
      'host unreachable',
      'connection refused',
      'socket',
    ];

    return networkKeywords.any((keyword) => errorMessage.contains(keyword));
  }

  /// Checks if failure is data corruption related
  bool _isDataCorruptionFailure(String errorMessage) {
    const dataKeywords = [
      'corrupt',
      'invalid data',
      'parse error',
      'malformed',
      'schema',
      'validation',
      'integrity',
      'checksum',
    ];

    return dataKeywords.any((keyword) => errorMessage.contains(keyword));
  }

  /// Checks if failure is resource exhaustion related
  bool _isResourceExhaustionFailure(String errorMessage) {
    const resourceKeywords = [
      'memory',
      'disk space',
      'storage',
      'quota',
      'limit',
      'throttle',
      'rate limit',
      'too many requests',
    ];

    return resourceKeywords.any((keyword) => errorMessage.contains(keyword));
  }

  /// Analyzes failure patterns
  void _analyzeFailurePattern(
      SyncOperationMetrics failure, List<String> indicators) {
    final collection = failure.collection;

    _failurePatterns.putIfAbsent(collection, () => []).add(failure);

    final collectionFailures = _failurePatterns[collection]!;
    if (collectionFailures.length >= 3) {
      // Look for patterns in recent failures
      final recentFailures = collectionFailures
          .where((f) =>
              f.startTime.isAfter(DateTime.now().subtract(Duration(hours: 1))))
          .toList();

      if (recentFailures.length >= 2) {
        indicators.add('Recurring failures in collection $collection');
      }
    }
  }

  /// Calculates trend direction from data points
  TrendDirection _calculateTrendDirection(List<DataPoint> dataPoints) {
    if (dataPoints.length < 2) return TrendDirection.stable;

    final values = dataPoints.map((d) => d.value).toList();
    final first = values.take(values.length ~/ 2).toList();
    final second = values.skip(values.length ~/ 2).toList();

    final firstAvg =
        first.isNotEmpty ? first.reduce((a, b) => a + b) / first.length : 0.0;
    final secondAvg = second.isNotEmpty
        ? second.reduce((a, b) => a + b) / second.length
        : 0.0;

    final change = secondAvg - firstAvg;
    final variance = _calculateVariance(values);

    if (variance > secondAvg * 0.5) {
      return TrendDirection.volatile;
    } else if (change > firstAvg * 0.1) {
      return TrendDirection.degrading;
    } else if (change < -firstAvg * 0.1) {
      return TrendDirection.improving;
    } else {
      return TrendDirection.stable;
    }
  }

  /// Calculates trend magnitude
  double _calculateTrendMagnitude(List<DataPoint> dataPoints) {
    if (dataPoints.length < 2) return 0.0;

    final values = dataPoints.map((d) => d.value).toList();
    final first = values.first;
    final last = values.last;

    return first > 0 ? (last - first).abs() / first : 0.0;
  }

  /// Calculates variance of values
  double _calculateVariance(List<double> values) {
    if (values.length < 2) return 0.0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => math.pow(v - mean, 2)).toList();

    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  /// Assesses network risk
  double _assessNetworkRisk() {
    // In real implementation, integrate with network monitoring
    // For now, simulate based on random factors
    return math.Random().nextDouble() * 0.5; // 0-50% risk
  }

  /// Assesses resource risk
  double _assessResourceRisk() {
    // In real implementation, integrate with system monitoring
    // For now, simulate based on random factors
    return math.Random().nextDouble() * 0.8; // 0-80% risk
  }

  /// Finds common patterns in error messages
  List<String> _findCommonErrorPatterns(List<String> errorMessages) {
    final patterns = <String, int>{};

    for (final message in errorMessages) {
      final words = message.toLowerCase().split(' ');
      for (final word in words) {
        if (word.length > 3) {
          // Skip short words
          patterns[word] = (patterns[word] ?? 0) + 1;
        }
      }
    }

    return patterns.entries
        .where((entry) => entry.value > 1)
        .map((entry) => entry.key)
        .take(5)
        .toList();
  }

  /// Disposes the analytics service
  void dispose() {
    stopAnalysis();
    _classificationController.close();
    _predictionController.close();
    _rootCauseController.close();
  }
}
