// test/network_simulation/network_condition_simulator.dart

import 'dart:async';
import 'dart:math';

/// Network connection types
enum NetworkType {
  wifi,
  cellular4g,
  cellular3g,
  cellular2g,
  ethernet,
  offline,
  unknown,
}

/// Network quality levels
enum NetworkQuality {
  excellent, // >50 Mbps, <10ms latency
  good, // 10-50 Mbps, 10-50ms latency
  fair, // 1-10 Mbps, 50-200ms latency
  poor, // <1 Mbps, >200ms latency
  unstable, // Highly variable
}

/// Network condition parameters
class NetworkCondition {
  final NetworkType type;
  final NetworkQuality quality;
  final double bandwidthMbps;
  final int latencyMs;
  final double packetLossRate;
  final double jitterMs;
  final bool isStable;
  final Map<String, dynamic> metadata;

  const NetworkCondition({
    required this.type,
    required this.quality,
    required this.bandwidthMbps,
    required this.latencyMs,
    required this.packetLossRate,
    required this.jitterMs,
    this.isStable = true,
    this.metadata = const {},
  });

  factory NetworkCondition.excellent() => const NetworkCondition(
        type: NetworkType.wifi,
        quality: NetworkQuality.excellent,
        bandwidthMbps: 100.0,
        latencyMs: 5,
        packetLossRate: 0.001,
        jitterMs: 1.0,
        isStable: true,
      );

  factory NetworkCondition.good() => const NetworkCondition(
        type: NetworkType.wifi,
        quality: NetworkQuality.good,
        bandwidthMbps: 25.0,
        latencyMs: 25,
        packetLossRate: 0.01,
        jitterMs: 5.0,
      );

  factory NetworkCondition.fair() => const NetworkCondition(
        type: NetworkType.cellular4g,
        quality: NetworkQuality.fair,
        bandwidthMbps: 5.0,
        latencyMs: 100,
        packetLossRate: 0.02,
        jitterMs: 20.0,
      );

  factory NetworkCondition.poor() => const NetworkCondition(
        type: NetworkType.cellular3g,
        quality: NetworkQuality.poor,
        bandwidthMbps: 0.5,
        latencyMs: 300,
        packetLossRate: 0.05,
        jitterMs: 50.0,
      );

  factory NetworkCondition.unstable() => const NetworkCondition(
        type: NetworkType.cellular3g,
        quality: NetworkQuality.unstable,
        bandwidthMbps: 2.0,
        latencyMs: 150,
        packetLossRate: 0.1,
        jitterMs: 100.0,
        isStable: false,
      );

  factory NetworkCondition.offline() => const NetworkCondition(
        type: NetworkType.offline,
        quality: NetworkQuality.poor,
        bandwidthMbps: 0.0,
        latencyMs: 0,
        packetLossRate: 1.0,
        jitterMs: 0.0,
      );

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'quality': quality.name,
        'bandwidthMbps': bandwidthMbps,
        'latencyMs': latencyMs,
        'packetLossRate': packetLossRate,
        'jitterMs': jitterMs,
        'isStable': isStable,
        'metadata': metadata,
      };

  NetworkCondition copyWith({
    NetworkType? type,
    NetworkQuality? quality,
    double? bandwidthMbps,
    int? latencyMs,
    double? packetLossRate,
    double? jitterMs,
    bool? isStable,
    Map<String, dynamic>? metadata,
  }) {
    return NetworkCondition(
      type: type ?? this.type,
      quality: quality ?? this.quality,
      bandwidthMbps: bandwidthMbps ?? this.bandwidthMbps,
      latencyMs: latencyMs ?? this.latencyMs,
      packetLossRate: packetLossRate ?? this.packetLossRate,
      jitterMs: jitterMs ?? this.jitterMs,
      isStable: isStable ?? this.isStable,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Calculates estimated transfer time for given data size
  Duration estimateTransferTime(int dataSizeBytes) {
    if (bandwidthMbps == 0) return Duration.zero;

    final dataSizeMb = dataSizeBytes / (1024 * 1024);
    final baseTransferTimeMs = (dataSizeMb / bandwidthMbps * 1000).round();
    final totalTimeMs = baseTransferTimeMs + latencyMs;

    return Duration(milliseconds: totalTimeMs);
  }

  /// Determines if operation should fail based on packet loss
  bool shouldOperationFail(Random random) {
    return random.nextDouble() < packetLossRate;
  }
}

/// Configuration for network simulation
class NetworkSimulationConfig {
  final Duration conditionChangeDuration;
  final double conditionChangeChance;
  final bool enableJitter;
  final bool enablePacketLoss;
  final bool enableLatencyVariation;
  final List<NetworkCondition>? allowedConditions;
  final Map<String, dynamic> customParameters;

  const NetworkSimulationConfig({
    this.conditionChangeDuration = const Duration(seconds: 30),
    this.conditionChangeChance = 0.1,
    this.enableJitter = true,
    this.enablePacketLoss = true,
    this.enableLatencyVariation = true,
    this.allowedConditions,
    this.customParameters = const {},
  });

  static List<NetworkCondition> get defaultAllowedConditions => [
        NetworkCondition.excellent(),
        NetworkCondition.good(),
        NetworkCondition.fair(),
        NetworkCondition.poor(),
      ];
}

/// Represents a network event during simulation
class NetworkEvent {
  final String id;
  final String type;
  final DateTime timestamp;
  final NetworkCondition? previousCondition;
  final NetworkCondition? currentCondition;
  final Map<String, dynamic> data;

  const NetworkEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    this.previousCondition,
    this.currentCondition,
    this.data = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'timestamp': timestamp.toIso8601String(),
        'previousCondition': previousCondition?.toJson(),
        'currentCondition': currentCondition?.toJson(),
        'data': data,
      };
}

/// Result of a simulated network operation
class NetworkOperationResult {
  final String operationId;
  final bool successful;
  final Duration actualDuration;
  final Duration estimatedDuration;
  final int dataSizeBytes;
  final NetworkCondition appliedCondition;
  final String? errorMessage;
  final Map<String, dynamic> metrics;

  const NetworkOperationResult({
    required this.operationId,
    required this.successful,
    required this.actualDuration,
    required this.estimatedDuration,
    required this.dataSizeBytes,
    required this.appliedCondition,
    this.errorMessage,
    this.metrics = const {},
  });

  Map<String, dynamic> toJson() => {
        'operationId': operationId,
        'successful': successful,
        'actualDurationMs': actualDuration.inMilliseconds,
        'estimatedDurationMs': estimatedDuration.inMilliseconds,
        'dataSizeBytes': dataSizeBytes,
        'appliedCondition': appliedCondition.toJson(),
        'errorMessage': errorMessage,
        'metrics': metrics,
      };

  /// Calculates performance ratio (actual vs estimated)
  double get performanceRatio {
    if (estimatedDuration.inMilliseconds == 0) return 1.0;
    return actualDuration.inMilliseconds / estimatedDuration.inMilliseconds;
  }
}

/// Simulates various network conditions for testing sync operations
class NetworkConditionSimulator {
  final NetworkSimulationConfig _config;
  final Random _random = Random();

  NetworkCondition _currentCondition = NetworkCondition.excellent();
  final List<NetworkEvent> _events = [];
  final List<NetworkOperationResult> _operationResults = [];

  Timer? _conditionChangeTimer;
  final StreamController<NetworkEvent> _eventController =
      StreamController.broadcast();

  int _eventCounter = 0;
  int _operationCounter = 0;

  NetworkConditionSimulator([NetworkSimulationConfig? config])
      : _config = config ?? const NetworkSimulationConfig() {
    _startConditionChanges();
  }

  /// Stream of network events
  Stream<NetworkEvent> get eventStream => _eventController.stream;

  /// Current network condition
  NetworkCondition get currentCondition => _currentCondition;

  /// All recorded events
  List<NetworkEvent> get events => List.unmodifiable(_events);

  /// All operation results
  List<NetworkOperationResult> get operationResults =>
      List.unmodifiable(_operationResults);

  /// Sets a specific network condition
  void setNetworkCondition(NetworkCondition condition) {
    final previousCondition = _currentCondition;
    _currentCondition = condition;

    _recordEvent(
      'condition_changed',
      previousCondition: previousCondition,
      currentCondition: condition,
    );
  }

  /// Simulates going offline
  void goOffline() {
    setNetworkCondition(NetworkCondition.offline());
  }

  /// Simulates coming back online
  void goOnline([NetworkCondition? condition]) {
    setNetworkCondition(condition ?? NetworkCondition.good());
  }

  /// Simulates a network operation with current conditions
  Future<NetworkOperationResult> simulateOperation(
    String operationId,
    int dataSizeBytes, {
    Duration? customDelay,
  }) async {
    final startTime = DateTime.now();
    final condition = _getCurrentEffectiveCondition();
    final estimatedDuration = condition.estimateTransferTime(dataSizeBytes);

    // Apply custom delay if specified
    final delay = customDelay ?? estimatedDuration;

    // Check if operation should fail due to packet loss
    final shouldFail = condition.shouldOperationFail(_random);

    if (shouldFail) {
      final result = NetworkOperationResult(
        operationId: operationId,
        successful: false,
        actualDuration:
            Duration(milliseconds: _random.nextInt(delay.inMilliseconds)),
        estimatedDuration: estimatedDuration,
        dataSizeBytes: dataSizeBytes,
        appliedCondition: condition,
        errorMessage: 'Network operation failed due to packet loss',
        metrics: {
          'packetLossRate': condition.packetLossRate,
          'bandwidth': condition.bandwidthMbps,
          'latency': condition.latencyMs,
        },
      );

      _operationResults.add(result);
      return result;
    }

    // Simulate the delay with jitter
    var actualDelay = delay;
    if (_config.enableJitter && condition.jitterMs > 0) {
      final jitterMs = (_random.nextDouble() - 0.5) * 2 * condition.jitterMs;
      actualDelay = Duration(
        milliseconds: (delay.inMilliseconds + jitterMs)
            .round()
            .clamp(0, delay.inMilliseconds * 2),
      );
    }

    await Future.delayed(actualDelay);

    final endTime = DateTime.now();
    final actualDuration = endTime.difference(startTime);

    final result = NetworkOperationResult(
      operationId: operationId,
      successful: true,
      actualDuration: actualDuration,
      estimatedDuration: estimatedDuration,
      dataSizeBytes: dataSizeBytes,
      appliedCondition: condition,
      metrics: {
        'jitterApplied': _config.enableJitter,
        'performanceRatio':
            actualDuration.inMilliseconds / estimatedDuration.inMilliseconds,
        'bandwidth': condition.bandwidthMbps,
        'latency': condition.latencyMs,
      },
    );

    _operationResults.add(result);
    return result;
  }

  /// Simulates multiple concurrent operations
  Future<List<NetworkOperationResult>> simulateConcurrentOperations(
    List<Map<String, dynamic>> operations,
  ) async {
    final futures = operations.map((op) {
      return simulateOperation(
        op['operationId'] ?? 'concurrent_op_${_operationCounter++}',
        op['dataSizeBytes'] ?? 1024,
        customDelay: op['customDelay'] != null
            ? Duration(milliseconds: op['customDelay'])
            : null,
      );
    }).toList();

    return await Future.wait(futures);
  }

  /// Simulates network instability
  void simulateInstability(Duration duration) {
    final endTime = DateTime.now().add(duration);

    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (DateTime.now().isAfter(endTime)) {
        timer.cancel();
        return;
      }

      // Randomly change conditions during instability
      if (_random.nextDouble() < 0.3) {
        final conditions = [
          NetworkCondition.poor(),
          NetworkCondition.fair(),
          NetworkCondition.unstable(),
        ];
        setNetworkCondition(conditions[_random.nextInt(conditions.length)]);
      }
    });
  }

  /// Simulates gradual network degradation
  void simulateGradualDegradation(
    NetworkCondition startCondition,
    NetworkCondition endCondition,
    Duration duration,
  ) {
    final steps = 10;
    final stepDuration =
        Duration(milliseconds: duration.inMilliseconds ~/ steps);

    setNetworkCondition(startCondition);

    for (int i = 1; i <= steps; i++) {
      Timer(Duration(milliseconds: stepDuration.inMilliseconds * i), () {
        final progress = i / steps;
        final interpolatedCondition = _interpolateConditions(
          startCondition,
          endCondition,
          progress,
        );
        setNetworkCondition(interpolatedCondition);
      });
    }
  }

  /// Gets network performance statistics
  Map<String, dynamic> getNetworkStatistics() {
    final successfulOps = _operationResults.where((r) => r.successful).toList();
    final failedOps = _operationResults.where((r) => !r.successful).toList();

    if (_operationResults.isEmpty) {
      return {
        'totalOperations': 0,
        'successRate': 0.0,
        'averageLatency': 0.0,
        'averageBandwidth': 0.0,
      };
    }

    final averageLatency = _operationResults
            .map((r) => r.actualDuration.inMilliseconds)
            .reduce((a, b) => a + b) /
        _operationResults.length;

    final averageBandwidth = _operationResults
            .map((r) => r.appliedCondition.bandwidthMbps)
            .reduce((a, b) => a + b) /
        _operationResults.length;

    return {
      'totalOperations': _operationResults.length,
      'successfulOperations': successfulOps.length,
      'failedOperations': failedOps.length,
      'successRate': successfulOps.length / _operationResults.length,
      'averageLatency': averageLatency,
      'averageBandwidth': averageBandwidth,
      'conditionChanges':
          _events.where((e) => e.type == 'condition_changed').length,
      'performanceRatios':
          successfulOps.map((r) => r.performanceRatio).toList(),
    };
  }

  /// Creates a test scenario with specific network conditions
  List<NetworkEvent> createNetworkScenario(
      List<Map<String, dynamic>> scenario) {
    final events = <NetworkEvent>[];

    for (final step in scenario) {
      final condition = _parseNetworkCondition(step['condition']);
      final delay = Duration(milliseconds: step['delayMs'] ?? 0);

      Timer(delay, () {
        setNetworkCondition(condition);
      });

      events.add(NetworkEvent(
        id: 'scenario_event_${events.length}',
        type: 'scheduled_condition_change',
        timestamp: DateTime.now().add(delay),
        currentCondition: condition,
        data: step,
      ));
    }

    return events;
  }

  /// Disposes resources
  void dispose() {
    _conditionChangeTimer?.cancel();
    _eventController.close();
  }

  // Private helper methods

  void _startConditionChanges() {
    if (_config.conditionChangeDuration.inMilliseconds > 0) {
      _conditionChangeTimer =
          Timer.periodic(_config.conditionChangeDuration, (_) {
        if (_random.nextDouble() < _config.conditionChangeChance) {
          final allowedConditions = _config.allowedConditions ??
              NetworkSimulationConfig.defaultAllowedConditions;
          final newCondition =
              allowedConditions[_random.nextInt(allowedConditions.length)];
          setNetworkCondition(newCondition);
        }
      });
    }
  }

  NetworkCondition _getCurrentEffectiveCondition() {
    var condition = _currentCondition;

    // Apply latency variation if enabled
    if (_config.enableLatencyVariation && condition.latencyMs > 0) {
      final variation =
          (_random.nextDouble() - 0.5) * 0.5 * condition.latencyMs;
      final newLatency = (condition.latencyMs + variation)
          .round()
          .clamp(1, condition.latencyMs * 2);
      condition = condition.copyWith(latencyMs: newLatency);
    }

    return condition;
  }

  void _recordEvent(
    String type, {
    NetworkCondition? previousCondition,
    NetworkCondition? currentCondition,
    Map<String, dynamic> data = const {},
  }) {
    final event = NetworkEvent(
      id: 'event_${_eventCounter++}',
      type: type,
      timestamp: DateTime.now(),
      previousCondition: previousCondition,
      currentCondition: currentCondition,
      data: data,
    );

    _events.add(event);
    _eventController.add(event);
  }

  NetworkCondition _interpolateConditions(
    NetworkCondition start,
    NetworkCondition end,
    double progress,
  ) {
    final bandwidth = start.bandwidthMbps +
        (end.bandwidthMbps - start.bandwidthMbps) * progress;
    final latency = start.latencyMs +
        ((end.latencyMs - start.latencyMs) * progress).round();
    final packetLoss = start.packetLossRate +
        (end.packetLossRate - start.packetLossRate) * progress;
    final jitter = start.jitterMs + (end.jitterMs - start.jitterMs) * progress;

    return NetworkCondition(
      type: progress < 0.5 ? start.type : end.type,
      quality: progress < 0.5 ? start.quality : end.quality,
      bandwidthMbps: bandwidth,
      latencyMs: latency,
      packetLossRate: packetLoss,
      jitterMs: jitter,
      isStable: progress < 0.5 ? start.isStable : end.isStable,
      metadata: {
        'interpolated': true,
        'progress': progress,
      },
    );
  }

  NetworkCondition _parseNetworkCondition(Map<String, dynamic> conditionData) {
    final type = NetworkType.values.firstWhere(
      (t) => t.name == conditionData['type'],
      orElse: () => NetworkType.wifi,
    );

    final quality = NetworkQuality.values.firstWhere(
      (q) => q.name == conditionData['quality'],
      orElse: () => NetworkQuality.good,
    );

    return NetworkCondition(
      type: type,
      quality: quality,
      bandwidthMbps: (conditionData['bandwidthMbps'] ?? 10.0).toDouble(),
      latencyMs: conditionData['latencyMs'] ?? 50,
      packetLossRate: (conditionData['packetLossRate'] ?? 0.01).toDouble(),
      jitterMs: (conditionData['jitterMs'] ?? 5.0).toDouble(),
      isStable: conditionData['isStable'] ?? true,
      metadata: Map<String, dynamic>.from(conditionData['metadata'] ?? {}),
    );
  }
}
