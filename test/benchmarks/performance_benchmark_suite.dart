// test/benchmarks/performance_benchmark_suite.dart

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import '../mocks/mock_sync_backend_adapter.dart';
import '../network_simulation/network_condition_simulator.dart';

/// Performance benchmark configuration
class BenchmarkConfig {
  final List<int> dataSizes;
  final List<int> concurrencyLevels;
  final List<NetworkCondition> networkConditions;
  final int warmupIterations;
  final int benchmarkIterations;
  final Duration maxTestDuration;
  final bool enableMemoryTracking;
  final bool enableCpuTracking;
  final Map<String, dynamic> customParameters;

  static final _defaultNetworkConditions = [
    NetworkCondition.excellent(),
    NetworkCondition.good(),
    NetworkCondition.fair(),
    NetworkCondition.poor(),
  ];

  const BenchmarkConfig({
    this.dataSizes = const [10, 100, 1000, 10000],
    this.concurrencyLevels = const [1, 5, 10, 20],
    this.networkConditions = const [],
    this.warmupIterations = 3,
    this.benchmarkIterations = 10,
    this.maxTestDuration = const Duration(minutes: 30),
    this.enableMemoryTracking = true,
    this.enableCpuTracking = true,
    this.customParameters = const {},
  });
}

/// Individual benchmark result
class BenchmarkResult {
  final String benchmarkId;
  final String benchmarkName;
  final String category;
  final Map<String, dynamic> parameters;
  final List<Duration> executionTimes;
  final List<double> throughputMetrics;
  final MemoryMetrics? memoryMetrics;
  final CpuMetrics? cpuMetrics;
  final Map<String, dynamic> customMetrics;
  final DateTime timestamp;

  const BenchmarkResult({
    required this.benchmarkId,
    required this.benchmarkName,
    required this.category,
    required this.parameters,
    required this.executionTimes,
    required this.throughputMetrics,
    this.memoryMetrics,
    this.cpuMetrics,
    this.customMetrics = const {},
    required this.timestamp,
  });

  // Statistical calculations
  Duration get averageExecutionTime {
    if (executionTimes.isEmpty) return Duration.zero;
    final totalMs =
        executionTimes.map((d) => d.inMilliseconds).reduce((a, b) => a + b);
    return Duration(milliseconds: (totalMs / executionTimes.length).round());
  }

  Duration get minExecutionTime {
    if (executionTimes.isEmpty) return Duration.zero;
    return executionTimes
        .reduce((a, b) => a.inMilliseconds < b.inMilliseconds ? a : b);
  }

  Duration get maxExecutionTime {
    if (executionTimes.isEmpty) return Duration.zero;
    return executionTimes
        .reduce((a, b) => a.inMilliseconds > b.inMilliseconds ? a : b);
  }

  double get averageThroughput {
    if (throughputMetrics.isEmpty) return 0.0;
    return throughputMetrics.reduce((a, b) => a + b) / throughputMetrics.length;
  }

  double get standardDeviation {
    if (executionTimes.length < 2) return 0.0;
    final mean = averageExecutionTime.inMilliseconds.toDouble();
    final variance = executionTimes
            .map((d) => pow(d.inMilliseconds - mean, 2))
            .reduce((a, b) => a + b) /
        executionTimes.length;
    return sqrt(variance);
  }

  Map<String, dynamic> toJson() => {
        'benchmarkId': benchmarkId,
        'benchmarkName': benchmarkName,
        'category': category,
        'parameters': parameters,
        'statistics': {
          'averageExecutionTimeMs': averageExecutionTime.inMilliseconds,
          'minExecutionTimeMs': minExecutionTime.inMilliseconds,
          'maxExecutionTimeMs': maxExecutionTime.inMilliseconds,
          'standardDeviation': standardDeviation,
          'averageThroughput': averageThroughput,
          'sampleCount': executionTimes.length,
        },
        'memoryMetrics': memoryMetrics?.toJson(),
        'cpuMetrics': cpuMetrics?.toJson(),
        'customMetrics': customMetrics,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Memory usage metrics
class MemoryMetrics {
  final int peakMemoryUsageBytes;
  final int averageMemoryUsageBytes;
  final int memoryGrowthBytes;
  final List<int> memorySnapshots;

  const MemoryMetrics({
    required this.peakMemoryUsageBytes,
    required this.averageMemoryUsageBytes,
    required this.memoryGrowthBytes,
    required this.memorySnapshots,
  });

  Map<String, dynamic> toJson() => {
        'peakMemoryUsageBytes': peakMemoryUsageBytes,
        'averageMemoryUsageBytes': averageMemoryUsageBytes,
        'memoryGrowthBytes': memoryGrowthBytes,
        'peakMemoryUsageMB':
            (peakMemoryUsageBytes / (1024 * 1024)).toStringAsFixed(2),
        'memoryGrowthMB':
            (memoryGrowthBytes / (1024 * 1024)).toStringAsFixed(2),
      };
}

/// CPU usage metrics
class CpuMetrics {
  final double averageCpuUsage;
  final double peakCpuUsage;
  final List<double> cpuSnapshots;

  const CpuMetrics({
    required this.averageCpuUsage,
    required this.peakCpuUsage,
    required this.cpuSnapshots,
  });

  Map<String, dynamic> toJson() => {
        'averageCpuUsage': averageCpuUsage,
        'peakCpuUsage': peakCpuUsage,
        'cpuEfficiency': averageCpuUsage < 50
            ? 'Good'
            : averageCpuUsage < 80
                ? 'Fair'
                : 'Poor',
      };
}

/// Benchmark test case
abstract class BenchmarkTestCase {
  String get benchmarkId;
  String get benchmarkName;
  String get category;

  Future<BenchmarkResult> runBenchmark(
    BenchmarkConfig config,
    Map<String, dynamic> parameters,
  );
}

/// Performance benchmarking suite
class PerformanceBenchmarkSuite {
  final BenchmarkConfig _config;
  final List<BenchmarkTestCase> _benchmarks = [];
  final List<BenchmarkResult> _results = [];

  late final MockSyncBackendAdapter _mockBackend;
  late final NetworkConditionSimulator _networkSimulator;

  PerformanceBenchmarkSuite(this._config) {
    _mockBackend = MockSyncBackendAdapter();
    _networkSimulator = NetworkConditionSimulator();
    _registerDefaultBenchmarks();
  }

  List<NetworkCondition> get _effectiveNetworkConditions {
    return _config.networkConditions.isEmpty
        ? BenchmarkConfig._defaultNetworkConditions
        : _config.networkConditions;
  }

  /// Runs complete benchmark suite
  Future<List<BenchmarkResult>> runAllBenchmarks() async {
    print('🚀 Starting Performance Benchmark Suite...');
    print('Data sizes: ${_config.dataSizes}');
    print('Concurrency levels: ${_config.concurrencyLevels}');
    print('Network conditions: ${_effectiveNetworkConditions.length}');

    final results = <BenchmarkResult>[];

    for (final benchmark in _benchmarks) {
      print('\n📊 Running benchmark: ${benchmark.benchmarkName}');

      // Test with different data sizes
      for (final dataSize in _config.dataSizes) {
        // Test with different concurrency levels
        for (final concurrency in _config.concurrencyLevels) {
          // Test with different network conditions
          for (final networkCondition in _effectiveNetworkConditions) {
            final parameters = {
              'dataSize': dataSize,
              'concurrency': concurrency,
              'networkCondition': networkCondition.toJson(),
            };

            try {
              _networkSimulator.setNetworkCondition(networkCondition);
              final result = await benchmark.runBenchmark(_config, parameters);
              results.add(result);

              print('  ✅ ${benchmark.benchmarkName} - Size: $dataSize, '
                  'Concurrency: $concurrency, Network: ${networkCondition.quality.name} '
                  '- Avg: ${result.averageExecutionTime.inMilliseconds}ms');
            } catch (e) {
              print('  ❌ ${benchmark.benchmarkName} failed: $e');
            }
          }
        }
      }
    }

    _results.addAll(results);
    await _generateBenchmarkReport();

    return results;
  }

  /// Runs specific benchmark category
  Future<List<BenchmarkResult>> runBenchmarkCategory(String category) async {
    final categoryBenchmarks =
        _benchmarks.where((b) => b.category == category).toList();

    if (categoryBenchmarks.isEmpty) {
      print('⚠️ No benchmarks found for category: $category');
      return [];
    }

    print('🎯 Running benchmarks for category: $category');
    final results = <BenchmarkResult>[];

    for (final benchmark in categoryBenchmarks) {
      // Simplified run with default parameters
      final parameters = {
        'dataSize': _config.dataSizes.first,
        'concurrency': _config.concurrencyLevels.first,
        'networkCondition': _config.networkConditions.first.toJson(),
      };

      try {
        final result = await benchmark.runBenchmark(_config, parameters);
        results.add(result);
        print(
            '  ✅ ${benchmark.benchmarkName} - ${result.averageExecutionTime.inMilliseconds}ms');
      } catch (e) {
        print('  ❌ ${benchmark.benchmarkName} failed: $e');
      }
    }

    return results;
  }

  /// Gets benchmark results
  List<BenchmarkResult> get results => List.unmodifiable(_results);

  /// Gets performance statistics
  Map<String, dynamic> getPerformanceStatistics() {
    if (_results.isEmpty) return {'message': 'No benchmarks executed'};

    final categoryStats = <String, Map<String, dynamic>>{};

    for (final result in _results) {
      if (!categoryStats.containsKey(result.category)) {
        categoryStats[result.category] = {
          'count': 0,
          'totalTime': 0,
          'minTime': double.maxFinite,
          'maxTime': 0.0,
          'avgThroughput': 0.0,
        };
      }

      final stats = categoryStats[result.category]!;
      stats['count'] = stats['count'] + 1;
      stats['totalTime'] =
          stats['totalTime'] + result.averageExecutionTime.inMilliseconds;
      stats['minTime'] = min<double>(stats['minTime'] as double,
          result.minExecutionTime.inMilliseconds.toDouble());
      stats['maxTime'] = max<double>(stats['maxTime'] as double,
          result.maxExecutionTime.inMilliseconds.toDouble());
      stats['avgThroughput'] =
          stats['avgThroughput'] + result.averageThroughput;
    }

    // Calculate averages
    for (final stats in categoryStats.values) {
      final count = stats['count'] as int;
      stats['avgTime'] = (stats['totalTime'] as int) / count;
      stats['avgThroughput'] = (stats['avgThroughput'] as double) / count;
    }

    return {
      'totalBenchmarks': _results.length,
      'categoriesCount': categoryStats.length,
      'categoryStatistics': categoryStats,
      'overallAverageTime': _results
              .map((r) => r.averageExecutionTime.inMilliseconds)
              .reduce((a, b) => a + b) /
          _results.length,
      'overallThroughput':
          _results.map((r) => r.averageThroughput).reduce((a, b) => a + b) /
              _results.length,
    };
  }

  /// Adds custom benchmark
  void addBenchmark(BenchmarkTestCase benchmark) {
    _benchmarks.add(benchmark);
  }

  // Private implementation methods

  void _registerDefaultBenchmarks() {
    addBenchmark(CrudOperationsBenchmark(_mockBackend));
    addBenchmark(BatchOperationsBenchmark(_mockBackend));
    addBenchmark(ConcurrentOperationsBenchmark(_mockBackend));
    addBenchmark(LargeDatasetBenchmark(_mockBackend));
    addBenchmark(NetworkLatencyBenchmark(_mockBackend, _networkSimulator));
    addBenchmark(ConflictResolutionBenchmark(_mockBackend));
    addBenchmark(MemoryUsageBenchmark(_mockBackend));
    addBenchmark(ThroughputBenchmark(_mockBackend));
  }

  Future<void> _generateBenchmarkReport() async {
    final report = {
      'timestamp': DateTime.now().toIso8601String(),
      'framework': 'Universal Sync Manager Performance Benchmarks',
      'configuration': {
        'dataSizes': _config.dataSizes,
        'concurrencyLevels': _config.concurrencyLevels,
        'networkConditions': _config.networkConditions.length,
        'iterations': _config.benchmarkIterations,
      },
      'statistics': getPerformanceStatistics(),
      'results': _results.map((r) => r.toJson()).toList(),
    };

    try {
      final file = File(
          'performance_benchmark_report_${DateTime.now().millisecondsSinceEpoch}.json');
      await file
          .writeAsString(const JsonEncoder.withIndent('  ').convert(report));
      print('📄 Performance benchmark report saved: ${file.path}');
    } catch (e) {
      print('⚠️ Failed to save benchmark report: $e');
    }
  }
}

// Benchmark implementations

class CrudOperationsBenchmark extends BenchmarkTestCase {
  final MockSyncBackendAdapter _backend;

  CrudOperationsBenchmark(this._backend);

  @override
  String get benchmarkId => 'crud_operations';

  @override
  String get benchmarkName => 'CRUD Operations Performance';

  @override
  String get category => 'Basic Operations';

  @override
  Future<BenchmarkResult> runBenchmark(
      BenchmarkConfig config, Map<String, dynamic> parameters) async {
    final dataSize = parameters['dataSize'] as int;
    final executionTimes = <Duration>[];
    final throughputMetrics = <double>[];

    for (int i = 0; i < config.benchmarkIterations; i++) {
      final startTime = DateTime.now();

      // Perform CRUD operations
      for (int j = 0; j < dataSize; j++) {
        final data = {'name': 'Item $j', 'value': j};

        // Create
        final createResult = await _backend.create('test_collection', data);
        final id = createResult['id'];

        // Read
        await _backend.read('test_collection', id);

        // Update
        await _backend.update('test_collection', id, {'value': j * 2});

        // Delete
        await _backend.delete('test_collection', id);
      }

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      executionTimes.add(duration);

      final throughput =
          (dataSize * 4) / (duration.inMilliseconds / 1000); // ops/sec
      throughputMetrics.add(throughput);
    }

    return BenchmarkResult(
      benchmarkId: benchmarkId,
      benchmarkName: benchmarkName,
      category: category,
      parameters: parameters,
      executionTimes: executionTimes,
      throughputMetrics: throughputMetrics,
      timestamp: DateTime.now(),
    );
  }
}

class BatchOperationsBenchmark extends BenchmarkTestCase {
  final MockSyncBackendAdapter _backend;

  BatchOperationsBenchmark(this._backend);

  @override
  String get benchmarkId => 'batch_operations';

  @override
  String get benchmarkName => 'Batch Operations Performance';

  @override
  String get category => 'Batch Operations';

  @override
  Future<BenchmarkResult> runBenchmark(
      BenchmarkConfig config, Map<String, dynamic> parameters) async {
    final dataSize = parameters['dataSize'] as int;
    final executionTimes = <Duration>[];
    final throughputMetrics = <double>[];

    for (int i = 0; i < config.benchmarkIterations; i++) {
      final batchData = List.generate(
          dataSize,
          (index) => {
                'name': 'Batch Item $index',
                'value': index,
              });

      final startTime = DateTime.now();
      await _backend.batchCreate('test_collection', batchData);
      final endTime = DateTime.now();

      final duration = endTime.difference(startTime);
      executionTimes.add(duration);

      final throughput = dataSize / (duration.inMilliseconds / 1000);
      throughputMetrics.add(throughput);
    }

    return BenchmarkResult(
      benchmarkId: benchmarkId,
      benchmarkName: benchmarkName,
      category: category,
      parameters: parameters,
      executionTimes: executionTimes,
      throughputMetrics: throughputMetrics,
      timestamp: DateTime.now(),
    );
  }
}

class ConcurrentOperationsBenchmark extends BenchmarkTestCase {
  final MockSyncBackendAdapter _backend;

  ConcurrentOperationsBenchmark(this._backend);

  @override
  String get benchmarkId => 'concurrent_operations';

  @override
  String get benchmarkName => 'Concurrent Operations Performance';

  @override
  String get category => 'Concurrency';

  @override
  Future<BenchmarkResult> runBenchmark(
      BenchmarkConfig config, Map<String, dynamic> parameters) async {
    final dataSize = parameters['dataSize'] as int;
    final concurrency = parameters['concurrency'] as int;
    final executionTimes = <Duration>[];
    final throughputMetrics = <double>[];

    for (int i = 0; i < config.benchmarkIterations; i++) {
      final startTime = DateTime.now();

      final futures = <Future>[];
      for (int j = 0; j < concurrency; j++) {
        futures.add(_performConcurrentOperations(dataSize ~/ concurrency, j));
      }

      await Future.wait(futures);
      final endTime = DateTime.now();

      final duration = endTime.difference(startTime);
      executionTimes.add(duration);

      final throughput = dataSize / (duration.inMilliseconds / 1000);
      throughputMetrics.add(throughput);
    }

    return BenchmarkResult(
      benchmarkId: benchmarkId,
      benchmarkName: benchmarkName,
      category: category,
      parameters: parameters,
      executionTimes: executionTimes,
      throughputMetrics: throughputMetrics,
      timestamp: DateTime.now(),
    );
  }

  Future<void> _performConcurrentOperations(
      int operationCount, int threadId) async {
    for (int i = 0; i < operationCount; i++) {
      await _backend.create('test_collection', {
        'name': 'Concurrent Item $threadId-$i',
        'threadId': threadId,
        'index': i,
      });
    }
  }
}

class LargeDatasetBenchmark extends BenchmarkTestCase {
  final MockSyncBackendAdapter _backend;

  LargeDatasetBenchmark(this._backend);

  @override
  String get benchmarkId => 'large_dataset';

  @override
  String get benchmarkName => 'Large Dataset Performance';

  @override
  String get category => 'Scalability';

  @override
  Future<BenchmarkResult> runBenchmark(
      BenchmarkConfig config, Map<String, dynamic> parameters) async {
    final dataSize = parameters['dataSize'] as int;
    final executionTimes = <Duration>[];
    final throughputMetrics = <double>[];

    for (int i = 0; i < config.benchmarkIterations; i++) {
      final largeData = List.generate(
          dataSize,
          (index) => {
                'name': 'Large Dataset Item $index',
                'data': 'x' * 1000, // 1KB per item
                'index': index,
              });

      final startTime = DateTime.now();

      // Process in chunks
      const chunkSize = 100;
      for (int j = 0; j < largeData.length; j += chunkSize) {
        final chunk =
            largeData.sublist(j, min(j + chunkSize, largeData.length));
        await _backend.batchCreate('test_collection', chunk);
      }

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      executionTimes.add(duration);

      final throughput = dataSize / (duration.inMilliseconds / 1000);
      throughputMetrics.add(throughput);
    }

    return BenchmarkResult(
      benchmarkId: benchmarkId,
      benchmarkName: benchmarkName,
      category: category,
      parameters: parameters,
      executionTimes: executionTimes,
      throughputMetrics: throughputMetrics,
      customMetrics: {
        'dataVolumeKB': dataSize * 1.0, // Approximate KB
        'chunkingStrategy': 'Fixed 100-item chunks',
      },
      timestamp: DateTime.now(),
    );
  }
}

class NetworkLatencyBenchmark extends BenchmarkTestCase {
  final MockSyncBackendAdapter _backend;
  final NetworkConditionSimulator _networkSimulator;

  NetworkLatencyBenchmark(this._backend, this._networkSimulator);

  @override
  String get benchmarkId => 'network_latency';

  @override
  String get benchmarkName => 'Network Latency Impact';

  @override
  String get category => 'Network Performance';

  @override
  Future<BenchmarkResult> runBenchmark(
      BenchmarkConfig config, Map<String, dynamic> parameters) async {
    final dataSize = parameters['dataSize'] as int;
    final networkCondition =
        parameters['networkCondition'] as Map<String, dynamic>;
    final executionTimes = <Duration>[];
    final throughputMetrics = <double>[];

    for (int i = 0; i < config.benchmarkIterations; i++) {
      final startTime = DateTime.now();

      for (int j = 0; j < dataSize; j++) {
        // Simulate network operation
        await _networkSimulator.simulateOperation(
          'benchmark_op_$j',
          1024, // 1KB operation
        );

        await _backend.create('test_collection', {
          'name': 'Network Test Item $j',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      executionTimes.add(duration);

      final throughput = dataSize / (duration.inMilliseconds / 1000);
      throughputMetrics.add(throughput);
    }

    return BenchmarkResult(
      benchmarkId: benchmarkId,
      benchmarkName: benchmarkName,
      category: category,
      parameters: parameters,
      executionTimes: executionTimes,
      throughputMetrics: throughputMetrics,
      customMetrics: {
        'networkLatency': networkCondition['latencyMs'],
        'networkBandwidth': networkCondition['bandwidthMbps'],
        'packetLossRate': networkCondition['packetLossRate'],
      },
      timestamp: DateTime.now(),
    );
  }
}

class ConflictResolutionBenchmark extends BenchmarkTestCase {
  final MockSyncBackendAdapter _backend;

  ConflictResolutionBenchmark(this._backend);

  @override
  String get benchmarkId => 'conflict_resolution';

  @override
  String get benchmarkName => 'Conflict Resolution Performance';

  @override
  String get category => 'Conflict Handling';

  @override
  Future<BenchmarkResult> runBenchmark(
      BenchmarkConfig config, Map<String, dynamic> parameters) async {
    final dataSize = parameters['dataSize'] as int;
    final executionTimes = <Duration>[];
    final throughputMetrics = <double>[];

    for (int i = 0; i < config.benchmarkIterations; i++) {
      final startTime = DateTime.now();

      // Create conflicts and resolve them
      for (int j = 0; j < dataSize; j++) {
        // Simulate conflicting updates
        _backend.enableConflictSimulation(true);

        await _backend.create('test_collection', {
          'name': 'Conflict Item $j',
          'value': j,
        });

        // This will create a conflict scenario
        await _backend.update('test_collection', 'conflict_item_$j', {
          'value': j * 2,
        });
      }

      _backend.enableConflictSimulation(false);
      final endTime = DateTime.now();

      final duration = endTime.difference(startTime);
      executionTimes.add(duration);

      final throughput = dataSize / (duration.inMilliseconds / 1000);
      throughputMetrics.add(throughput);
    }

    return BenchmarkResult(
      benchmarkId: benchmarkId,
      benchmarkName: benchmarkName,
      category: category,
      parameters: parameters,
      executionTimes: executionTimes,
      throughputMetrics: throughputMetrics,
      timestamp: DateTime.now(),
    );
  }
}

class MemoryUsageBenchmark extends BenchmarkTestCase {
  final MockSyncBackendAdapter _backend;

  MemoryUsageBenchmark(this._backend);

  @override
  String get benchmarkId => 'memory_usage';

  @override
  String get benchmarkName => 'Memory Usage Tracking';

  @override
  String get category => 'Resource Usage';

  @override
  Future<BenchmarkResult> runBenchmark(
      BenchmarkConfig config, Map<String, dynamic> parameters) async {
    final dataSize = parameters['dataSize'] as int;
    final executionTimes = <Duration>[];
    final throughputMetrics = <double>[];
    final memorySnapshots = <int>[];

    for (int i = 0; i < config.benchmarkIterations; i++) {
      // Force garbage collection before measurement
      // Note: In real implementation, would use platform-specific memory tracking

      final startTime = DateTime.now();
      final initialMemory = _getMemoryUsage();
      memorySnapshots.add(initialMemory);

      // Perform memory-intensive operations
      final largeDataset = <Map<String, dynamic>>[];
      for (int j = 0; j < dataSize; j++) {
        largeDataset.add({
          'name': 'Memory Test Item $j',
          'data': List.filled(1000, 'x'), // Large data structure
          'index': j,
        });
      }

      await _backend.batchCreate('test_collection', largeDataset);

      final peakMemory = _getMemoryUsage();
      memorySnapshots.add(peakMemory);

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      executionTimes.add(duration);

      final throughput = dataSize / (duration.inMilliseconds / 1000);
      throughputMetrics.add(throughput);
    }

    final memoryMetrics = MemoryMetrics(
      peakMemoryUsageBytes: memorySnapshots.reduce(max),
      averageMemoryUsageBytes:
          (memorySnapshots.reduce((a, b) => a + b) / memorySnapshots.length)
              .round(),
      memoryGrowthBytes: memorySnapshots.last - memorySnapshots.first,
      memorySnapshots: memorySnapshots,
    );

    return BenchmarkResult(
      benchmarkId: benchmarkId,
      benchmarkName: benchmarkName,
      category: category,
      parameters: parameters,
      executionTimes: executionTimes,
      throughputMetrics: throughputMetrics,
      memoryMetrics: memoryMetrics,
      timestamp: DateTime.now(),
    );
  }

  int _getMemoryUsage() {
    // Simplified memory tracking - in real implementation would use:
    // - Platform-specific APIs
    // - VM service protocol
    // - External memory profiling tools
    return DateTime.now().millisecondsSinceEpoch % 1000000; // Mock value
  }
}

class ThroughputBenchmark extends BenchmarkTestCase {
  final MockSyncBackendAdapter _backend;

  ThroughputBenchmark(this._backend);

  @override
  String get benchmarkId => 'throughput';

  @override
  String get benchmarkName => 'Maximum Throughput';

  @override
  String get category => 'Performance Limits';

  @override
  Future<BenchmarkResult> runBenchmark(
      BenchmarkConfig config, Map<String, dynamic> parameters) async {
    final dataSize = parameters['dataSize'] as int;
    final concurrency = parameters['concurrency'] as int;
    final executionTimes = <Duration>[];
    final throughputMetrics = <double>[];

    for (int i = 0; i < config.benchmarkIterations; i++) {
      final startTime = DateTime.now();

      // Maximum throughput test with concurrent operations
      final futures = <Future>[];
      for (int j = 0; j < concurrency; j++) {
        futures.add(_maxThroughputOperations(dataSize ~/ concurrency, j));
      }

      await Future.wait(futures);
      final endTime = DateTime.now();

      final duration = endTime.difference(startTime);
      executionTimes.add(duration);

      final throughput = dataSize / (duration.inMilliseconds / 1000);
      throughputMetrics.add(throughput);
    }

    return BenchmarkResult(
      benchmarkId: benchmarkId,
      benchmarkName: benchmarkName,
      category: category,
      parameters: parameters,
      executionTimes: executionTimes,
      throughputMetrics: throughputMetrics,
      customMetrics: {
        'maxConcurrency': concurrency,
        'peakThroughput': throughputMetrics.reduce(max),
        'sustainedThroughput': throughputMetrics.reduce((a, b) => a + b) /
            throughputMetrics.length,
      },
      timestamp: DateTime.now(),
    );
  }

  Future<void> _maxThroughputOperations(
      int operationCount, int threadId) async {
    final batch = <Map<String, dynamic>>[];

    for (int i = 0; i < operationCount; i++) {
      batch.add({
        'name': 'Throughput Item $threadId-$i',
        'threadId': threadId,
        'index': i,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }

    await _backend.batchCreate('test_collection', batch);
  }
}
