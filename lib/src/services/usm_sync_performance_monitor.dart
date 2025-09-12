// lib/src/services/usm_sync_performance_monitor.dart

import 'dart:async';
import 'dart:math' as math;

import 'usm_sync_analytics_service.dart';

/// Network performance metrics
class NetworkPerformanceMetrics {
  final double latency; // milliseconds
  final double bandwidth; // bytes per second
  final double packetLoss; // percentage (0.0 - 1.0)
  final bool isConnected;
  final String connectionType; // wifi, cellular, ethernet, etc.
  final DateTime timestamp;

  const NetworkPerformanceMetrics({
    required this.latency,
    required this.bandwidth,
    required this.packetLoss,
    required this.isConnected,
    required this.connectionType,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'latency': latency,
        'bandwidth': bandwidth,
        'packetLoss': packetLoss,
        'isConnected': isConnected,
        'connectionType': connectionType,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Backend performance metrics
class BackendPerformanceMetrics {
  final String backendType;
  final double responseTime; // milliseconds
  final bool isHealthy;
  final double throughput; // operations per second
  final Map<String, dynamic> customMetrics;
  final DateTime timestamp;

  const BackendPerformanceMetrics({
    required this.backendType,
    required this.responseTime,
    required this.isHealthy,
    required this.throughput,
    this.customMetrics = const {},
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'backendType': backendType,
        'responseTime': responseTime,
        'isHealthy': isHealthy,
        'throughput': throughput,
        'customMetrics': customMetrics,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Memory usage metrics for sync operations
class MemoryUsageMetrics {
  final int usedMemoryBytes;
  final int availableMemoryBytes;
  final double memoryPressure; // 0.0 to 1.0
  final int syncCacheSize;
  final int pendingOperations;
  final DateTime timestamp;

  const MemoryUsageMetrics({
    required this.usedMemoryBytes,
    required this.availableMemoryBytes,
    required this.memoryPressure,
    required this.syncCacheSize,
    required this.pendingOperations,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'usedMemoryBytes': usedMemoryBytes,
        'availableMemoryBytes': availableMemoryBytes,
        'memoryPressure': memoryPressure,
        'syncCacheSize': syncCacheSize,
        'pendingOperations': pendingOperations,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Comprehensive sync performance monitoring
class SyncPerformanceMonitor {
  final SyncAnalyticsService _analyticsService;

  final List<NetworkPerformanceMetrics> _networkHistory = [];
  final List<BackendPerformanceMetrics> _backendHistory = [];
  final List<MemoryUsageMetrics> _memoryHistory = [];

  final StreamController<NetworkPerformanceMetrics> _networkMetricsController =
      StreamController<NetworkPerformanceMetrics>.broadcast();
  final StreamController<BackendPerformanceMetrics> _backendMetricsController =
      StreamController<BackendPerformanceMetrics>.broadcast();
  final StreamController<MemoryUsageMetrics> _memoryMetricsController =
      StreamController<MemoryUsageMetrics>.broadcast();
  final StreamController<PerformanceAlert> _alertController =
      StreamController<PerformanceAlert>.broadcast();

  Timer? _monitoringTimer;
  Duration _monitoringInterval = const Duration(seconds: 30);
  Duration _metricsRetention = const Duration(hours: 24);

  // Performance thresholds
  double _latencyThreshold = 5000; // 5 seconds
  double _memoryPressureThreshold = 0.8; // 80%
  double _errorRateThreshold = 0.1; // 10%
  double _responseTimeThreshold = 10000; // 10 seconds

  SyncPerformanceMonitor(this._analyticsService);

  /// Stream of network performance metrics
  Stream<NetworkPerformanceMetrics> get networkMetrics =>
      _networkMetricsController.stream;

  /// Stream of backend performance metrics
  Stream<BackendPerformanceMetrics> get backendMetrics =>
      _backendMetricsController.stream;

  /// Stream of memory usage metrics
  Stream<MemoryUsageMetrics> get memoryMetrics =>
      _memoryMetricsController.stream;

  /// Stream of performance alerts
  Stream<PerformanceAlert> get alerts => _alertController.stream;

  /// Starts continuous performance monitoring
  void startMonitoring({Duration? interval}) {
    _monitoringInterval = interval ?? _monitoringInterval;

    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(_monitoringInterval, (_) {
      _collectMetrics();
    });

    // Collect initial metrics
    _collectMetrics();
  }

  /// Stops performance monitoring
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  /// Records network performance test result
  void recordNetworkTest({
    required double latency,
    required double bandwidth,
    double packetLoss = 0.0,
    required bool isConnected,
    required String connectionType,
  }) {
    final metrics = NetworkPerformanceMetrics(
      latency: latency,
      bandwidth: bandwidth,
      packetLoss: packetLoss,
      isConnected: isConnected,
      connectionType: connectionType,
      timestamp: DateTime.now(),
    );

    _networkHistory.add(metrics);
    _networkMetricsController.add(metrics);
    _cleanupNetworkHistory();

    _checkNetworkThresholds(metrics);
  }

  /// Records backend performance test result
  void recordBackendTest({
    required String backendType,
    required double responseTime,
    required bool isHealthy,
    double throughput = 0.0,
    Map<String, dynamic> customMetrics = const {},
  }) {
    final metrics = BackendPerformanceMetrics(
      backendType: backendType,
      responseTime: responseTime,
      isHealthy: isHealthy,
      throughput: throughput,
      customMetrics: customMetrics,
      timestamp: DateTime.now(),
    );

    _backendHistory.add(metrics);
    _backendMetricsController.add(metrics);
    _cleanupBackendHistory();

    _checkBackendThresholds(metrics);
  }

  /// Records memory usage metrics
  void recordMemoryUsage({
    required int usedMemoryBytes,
    required int availableMemoryBytes,
    required int syncCacheSize,
    required int pendingOperations,
  }) {
    final totalMemory = usedMemoryBytes + availableMemoryBytes;
    final memoryPressure =
        totalMemory > 0 ? usedMemoryBytes / totalMemory : 0.0;

    final metrics = MemoryUsageMetrics(
      usedMemoryBytes: usedMemoryBytes,
      availableMemoryBytes: availableMemoryBytes,
      memoryPressure: memoryPressure,
      syncCacheSize: syncCacheSize,
      pendingOperations: pendingOperations,
      timestamp: DateTime.now(),
    );

    _memoryHistory.add(metrics);
    _memoryMetricsController.add(metrics);
    _cleanupMemoryHistory();

    _checkMemoryThresholds(metrics);
  }

  /// Performs network latency test
  Future<NetworkPerformanceMetrics> testNetworkPerformance(
      String testUrl) async {
    try {
      final startTime = DateTime.now();

      // Simulate network test (in real implementation, use actual HTTP requests)
      await Future.delayed(
          Duration(milliseconds: math.Random().nextInt(1000) + 50));

      final endTime = DateTime.now();
      final latency = endTime.difference(startTime).inMilliseconds.toDouble();

      // Simulate bandwidth calculation
      final bandwidth =
          1024 * 1024 * (1 + math.Random().nextDouble()); // 1-2 MB/s

      final metrics = NetworkPerformanceMetrics(
        latency: latency,
        bandwidth: bandwidth,
        packetLoss: math.Random().nextDouble() * 0.01, // 0-1% packet loss
        isConnected: true,
        connectionType:
            'wifi', // In real implementation, detect actual connection type
        timestamp: DateTime.now(),
      );

      recordNetworkTest(
        latency: metrics.latency,
        bandwidth: metrics.bandwidth,
        packetLoss: metrics.packetLoss,
        isConnected: metrics.isConnected,
        connectionType: metrics.connectionType,
      );

      return metrics;
    } catch (e) {
      final metrics = NetworkPerformanceMetrics(
        latency: double.infinity,
        bandwidth: 0.0,
        packetLoss: 1.0,
        isConnected: false,
        connectionType: 'unknown',
        timestamp: DateTime.now(),
      );

      recordNetworkTest(
        latency: metrics.latency,
        bandwidth: metrics.bandwidth,
        packetLoss: metrics.packetLoss,
        isConnected: metrics.isConnected,
        connectionType: metrics.connectionType,
      );

      return metrics;
    }
  }

  /// Performs backend health check
  Future<BackendPerformanceMetrics> testBackendPerformance(
      String backendType) async {
    try {
      final startTime = DateTime.now();

      // Simulate backend health check
      await Future.delayed(
          Duration(milliseconds: math.Random().nextInt(2000) + 100));

      final endTime = DateTime.now();
      final responseTime =
          endTime.difference(startTime).inMilliseconds.toDouble();

      final metrics = BackendPerformanceMetrics(
        backendType: backendType,
        responseTime: responseTime,
        isHealthy: responseTime < 5000, // Consider healthy if response < 5s
        throughput: 10 + math.Random().nextDouble() * 20, // 10-30 ops/sec
        customMetrics: {
          'cpuUsage': math.Random().nextDouble() * 100,
          'memoryUsage': math.Random().nextDouble() * 100,
          'diskUsage': math.Random().nextDouble() * 100,
        },
        timestamp: DateTime.now(),
      );

      recordBackendTest(
        backendType: metrics.backendType,
        responseTime: metrics.responseTime,
        isHealthy: metrics.isHealthy,
        throughput: metrics.throughput,
        customMetrics: metrics.customMetrics,
      );

      return metrics;
    } catch (e) {
      final metrics = BackendPerformanceMetrics(
        backendType: backendType,
        responseTime: double.infinity,
        isHealthy: false,
        throughput: 0.0,
        customMetrics: {'error': e.toString()},
        timestamp: DateTime.now(),
      );

      recordBackendTest(
        backendType: metrics.backendType,
        responseTime: metrics.responseTime,
        isHealthy: metrics.isHealthy,
        throughput: metrics.throughput,
        customMetrics: metrics.customMetrics,
      );

      return metrics;
    }
  }

  /// Gets performance summary for a time period
  PerformanceSummary getPerformanceSummary({Duration? period}) {
    final now = DateTime.now();
    final start = period != null
        ? now.subtract(period)
        : now.subtract(const Duration(hours: 1));

    final recentNetwork =
        _networkHistory.where((m) => m.timestamp.isAfter(start)).toList();

    final recentBackend =
        _backendHistory.where((m) => m.timestamp.isAfter(start)).toList();

    final recentMemory =
        _memoryHistory.where((m) => m.timestamp.isAfter(start)).toList();

    final syncMetrics = _analyticsService.getPerformanceMetrics(period: period);

    return PerformanceSummary(
      networkMetrics: _summarizeNetworkMetrics(recentNetwork),
      backendMetrics: _summarizeBackendMetrics(recentBackend),
      memoryMetrics: _summarizeMemoryMetrics(recentMemory),
      syncMetrics: syncMetrics,
      periodStart: start,
      periodEnd: now,
    );
  }

  /// Updates performance thresholds
  void updateThresholds({
    double? latencyThreshold,
    double? memoryPressureThreshold,
    double? errorRateThreshold,
    double? responseTimeThreshold,
  }) {
    _latencyThreshold = latencyThreshold ?? _latencyThreshold;
    _memoryPressureThreshold =
        memoryPressureThreshold ?? _memoryPressureThreshold;
    _errorRateThreshold = errorRateThreshold ?? _errorRateThreshold;
    _responseTimeThreshold = responseTimeThreshold ?? _responseTimeThreshold;
  }

  /// Collects current system metrics
  void _collectMetrics() {
    // In a real implementation, these would collect actual system metrics
    _collectNetworkMetrics();
    _collectMemoryMetrics();
  }

  /// Collects network metrics
  void _collectNetworkMetrics() {
    // Simulate network metrics collection
    recordNetworkTest(
      latency: 50 + math.Random().nextDouble() * 100,
      bandwidth: 1024 * 1024 * (1 + math.Random().nextDouble() * 2),
      packetLoss: math.Random().nextDouble() * 0.02,
      isConnected: math.Random().nextBool() || true, // Bias toward connected
      connectionType: [
        'wifi',
        'cellular',
        'ethernet'
      ][math.Random().nextInt(3)],
    );
  }

  /// Collects memory metrics
  void _collectMemoryMetrics() {
    // Simulate memory metrics collection
    final used = 100 * 1024 * 1024 + math.Random().nextInt(500 * 1024 * 1024);
    final available =
        500 * 1024 * 1024 + math.Random().nextInt(1024 * 1024 * 1024);

    recordMemoryUsage(
      usedMemoryBytes: used,
      availableMemoryBytes: available,
      syncCacheSize: math.Random().nextInt(50 * 1024 * 1024),
      pendingOperations: math.Random().nextInt(20),
    );
  }

  /// Checks network performance thresholds
  void _checkNetworkThresholds(NetworkPerformanceMetrics metrics) {
    if (!metrics.isConnected) {
      _alertController.add(PerformanceAlert(
        type: AlertType.networkDisconnected,
        severity: AlertSeverity.critical,
        message: 'Network connection lost',
        timestamp: DateTime.now(),
        metrics: {'connectionType': metrics.connectionType},
      ));
    } else if (metrics.latency > _latencyThreshold) {
      _alertController.add(PerformanceAlert(
        type: AlertType.highLatency,
        severity: AlertSeverity.warning,
        message:
            'High network latency detected: ${metrics.latency.toStringAsFixed(0)}ms',
        timestamp: DateTime.now(),
        metrics: {'latency': metrics.latency, 'threshold': _latencyThreshold},
      ));
    }
  }

  /// Checks backend performance thresholds
  void _checkBackendThresholds(BackendPerformanceMetrics metrics) {
    if (!metrics.isHealthy) {
      _alertController.add(PerformanceAlert(
        type: AlertType.backendUnhealthy,
        severity: AlertSeverity.critical,
        message: 'Backend ${metrics.backendType} is unhealthy',
        timestamp: DateTime.now(),
        metrics: {
          'backendType': metrics.backendType,
          'responseTime': metrics.responseTime
        },
      ));
    } else if (metrics.responseTime > _responseTimeThreshold) {
      _alertController.add(PerformanceAlert(
        type: AlertType.slowBackend,
        severity: AlertSeverity.warning,
        message:
            'Backend ${metrics.backendType} is responding slowly: ${metrics.responseTime.toStringAsFixed(0)}ms',
        timestamp: DateTime.now(),
        metrics: {
          'backendType': metrics.backendType,
          'responseTime': metrics.responseTime
        },
      ));
    }
  }

  /// Checks memory usage thresholds
  void _checkMemoryThresholds(MemoryUsageMetrics metrics) {
    if (metrics.memoryPressure > _memoryPressureThreshold) {
      _alertController.add(PerformanceAlert(
        type: AlertType.highMemoryPressure,
        severity: metrics.memoryPressure > 0.9
            ? AlertSeverity.critical
            : AlertSeverity.warning,
        message:
            'High memory pressure: ${(metrics.memoryPressure * 100).toStringAsFixed(1)}%',
        timestamp: DateTime.now(),
        metrics: {
          'memoryPressure': metrics.memoryPressure,
          'usedMemoryMB': (metrics.usedMemoryBytes / (1024 * 1024)).round(),
          'availableMemoryMB':
              (metrics.availableMemoryBytes / (1024 * 1024)).round(),
        },
      ));
    }
  }

  /// Summarizes network metrics
  Map<String, dynamic> _summarizeNetworkMetrics(
      List<NetworkPerformanceMetrics> metrics) {
    if (metrics.isEmpty) return {};

    final latencies =
        metrics.map((m) => m.latency).where((l) => l.isFinite).toList();
    final bandwidths = metrics.map((m) => m.bandwidth).toList();
    final packetLosses = metrics.map((m) => m.packetLoss).toList();

    return {
      'averageLatency': latencies.isNotEmpty
          ? latencies.reduce((a, b) => a + b) / latencies.length
          : 0.0,
      'maxLatency': latencies.isNotEmpty ? latencies.reduce(math.max) : 0.0,
      'minLatency': latencies.isNotEmpty ? latencies.reduce(math.min) : 0.0,
      'averageBandwidth': bandwidths.isNotEmpty
          ? bandwidths.reduce((a, b) => a + b) / bandwidths.length
          : 0.0,
      'averagePacketLoss': packetLosses.isNotEmpty
          ? packetLosses.reduce((a, b) => a + b) / packetLosses.length
          : 0.0,
      'connectionUptime':
          metrics.where((m) => m.isConnected).length / metrics.length,
    };
  }

  /// Summarizes backend metrics
  Map<String, dynamic> _summarizeBackendMetrics(
      List<BackendPerformanceMetrics> metrics) {
    if (metrics.isEmpty) return {};

    final responseTimes =
        metrics.map((m) => m.responseTime).where((t) => t.isFinite).toList();
    final throughputs = metrics.map((m) => m.throughput).toList();

    return {
      'averageResponseTime': responseTimes.isNotEmpty
          ? responseTimes.reduce((a, b) => a + b) / responseTimes.length
          : 0.0,
      'maxResponseTime':
          responseTimes.isNotEmpty ? responseTimes.reduce(math.max) : 0.0,
      'minResponseTime':
          responseTimes.isNotEmpty ? responseTimes.reduce(math.min) : 0.0,
      'averageThroughput': throughputs.isNotEmpty
          ? throughputs.reduce((a, b) => a + b) / throughputs.length
          : 0.0,
      'uptime': metrics.where((m) => m.isHealthy).length / metrics.length,
    };
  }

  /// Summarizes memory metrics
  Map<String, dynamic> _summarizeMemoryMetrics(
      List<MemoryUsageMetrics> metrics) {
    if (metrics.isEmpty) return {};

    final pressures = metrics.map((m) => m.memoryPressure).toList();
    final cacheSizes = metrics.map((m) => m.syncCacheSize).toList();
    final pendingOps = metrics.map((m) => m.pendingOperations).toList();

    return {
      'averageMemoryPressure': pressures.isNotEmpty
          ? pressures.reduce((a, b) => a + b) / pressures.length
          : 0.0,
      'maxMemoryPressure':
          pressures.isNotEmpty ? pressures.reduce(math.max) : 0.0,
      'averageCacheSize': cacheSizes.isNotEmpty
          ? cacheSizes.reduce((a, b) => a + b) / cacheSizes.length
          : 0,
      'averagePendingOperations': pendingOps.isNotEmpty
          ? pendingOps.reduce((a, b) => a + b) / pendingOps.length
          : 0,
    };
  }

  /// Cleanup old metrics
  void _cleanupNetworkHistory() =>
      _cleanupHistory(_networkHistory, _metricsRetention);
  void _cleanupBackendHistory() =>
      _cleanupHistory(_backendHistory, _metricsRetention);
  void _cleanupMemoryHistory() =>
      _cleanupHistory(_memoryHistory, _metricsRetention);

  void _cleanupHistory<T extends dynamic>(List<T> history, Duration retention) {
    final cutoff = DateTime.now().subtract(retention);
    history.removeWhere((item) {
      if (item is NetworkPerformanceMetrics)
        return item.timestamp.isBefore(cutoff);
      if (item is BackendPerformanceMetrics)
        return item.timestamp.isBefore(cutoff);
      if (item is MemoryUsageMetrics) return item.timestamp.isBefore(cutoff);
      return false;
    });
  }

  /// Disposes the monitor
  void dispose() {
    stopMonitoring();
    _networkMetricsController.close();
    _backendMetricsController.close();
    _memoryMetricsController.close();
    _alertController.close();
  }
}

/// Performance summary for a specific time period
class PerformanceSummary {
  final Map<String, dynamic> networkMetrics;
  final Map<String, dynamic> backendMetrics;
  final Map<String, dynamic> memoryMetrics;
  final SyncPerformanceMetrics syncMetrics;
  final DateTime periodStart;
  final DateTime periodEnd;

  const PerformanceSummary({
    required this.networkMetrics,
    required this.backendMetrics,
    required this.memoryMetrics,
    required this.syncMetrics,
    required this.periodStart,
    required this.periodEnd,
  });

  Map<String, dynamic> toJson() => {
        'networkMetrics': networkMetrics,
        'backendMetrics': backendMetrics,
        'memoryMetrics': memoryMetrics,
        'syncMetrics': syncMetrics.toJson(),
        'periodStart': periodStart.toIso8601String(),
        'periodEnd': periodEnd.toIso8601String(),
      };
}

/// Performance alert types
enum AlertType {
  networkDisconnected,
  highLatency,
  backendUnhealthy,
  slowBackend,
  highMemoryPressure,
  syncFailureSpike,
  performanceDegradation,
}

/// Alert severity levels
enum AlertSeverity {
  info,
  warning,
  critical,
}

/// Performance alert
class PerformanceAlert {
  final AlertType type;
  final AlertSeverity severity;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> metrics;

  const PerformanceAlert({
    required this.type,
    required this.severity,
    required this.message,
    required this.timestamp,
    this.metrics = const {},
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'severity': severity.name,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'metrics': metrics,
      };
}
