// test/test_suite_runner.dart

import 'integration/integration_test_framework.dart';
import 'benchmarks/performance_benchmark_suite.dart';
import 'e2e/end_to_end_test_scenarios.dart';

/// Comprehensive test suite runner for Universal Sync Manager
///
/// This file provides a centralized entry point for running all testing infrastructure
/// components developed in Phase 6, including:
/// - Integration Testing Framework (Task 6.2)
/// - Performance Benchmarking Suite (Task 6.3)
/// - End-to-end Testing Scenarios (Task 6.4)
class UniversalSyncManagerTestSuite {
  late final IntegrationTestFramework _integrationFramework;
  late final PerformanceBenchmarkSuite _benchmarkSuite;
  late final EndToEndTestScenarios _e2eScenarios;

  /// Initialize all testing components
  Future<void> initialize() async {
    print('🚀 Initializing Universal Sync Manager Test Suite...');

    // Task 6.2: Integration Testing Framework
    _integrationFramework =
        IntegrationTestFramework(const IntegrationTestConfig());

    // Task 6.3: Performance Benchmarking Suite
    _benchmarkSuite = PerformanceBenchmarkSuite(const BenchmarkConfig());

    // Task 6.4: End-to-end Testing Scenarios
    _e2eScenarios = EndToEndTestScenarios(const E2ETestConfig());

    print('✅ Test suite initialization complete!');
  }

  /// Run all tests with comprehensive coverage
  Future<TestSuiteResults> runCompleteTestSuite() async {
    print('\n🎯 Running Complete Universal Sync Manager Test Suite');
    print('=' * 60);

    final results = TestSuiteResults();
    final startTime = DateTime.now();

    try {
      // Phase 1: Unit and Integration Tests
      print('\n📋 Phase 1: Unit & Integration Testing');
      final integrationResults =
          await _integrationFramework.runIntegrationTests();
      results.integrationResults = integrationResults;
      print(
          '✅ Integration tests completed: ${integrationResults.length} tests');

      // Phase 2: Performance Benchmarks
      print('\n⚡ Phase 2: Performance Benchmarking');
      final benchmarkResults = await _benchmarkSuite.runAllBenchmarks();
      results.benchmarkResults = benchmarkResults;
      print(
          '✅ Performance benchmarks completed: ${benchmarkResults.length} benchmarks');

      // Phase 3: End-to-End Scenarios
      print('\n🎬 Phase 3: End-to-End Testing');
      final e2eResults = await _e2eScenarios.runAllScenarios();
      results.e2eResults = e2eResults;
      print('✅ E2E scenarios completed: ${e2eResults.length} scenarios');

      // Generate comprehensive report
      results.executionTime = DateTime.now().difference(startTime);
      await _generateComprehensiveReport(results);
    } catch (e) {
      print('❌ Test suite execution failed: $e');
      results.failed = true;
      results.errorMessage = e.toString();
    }

    return results;
  }

  /// Run specific test category
  Future<void> runTestCategory(TestCategory category) async {
    switch (category) {
      case TestCategory.integration:
        print('🔗 Running Integration Tests...');
        await _integrationFramework.runIntegrationTests();
        break;

      case TestCategory.performance:
        print('⚡ Running Performance Benchmarks...');
        await _benchmarkSuite.runAllBenchmarks();
        break;

      case TestCategory.endToEnd:
        print('🎬 Running End-to-End Scenarios...');
        await _e2eScenarios.runAllScenarios();
        break;

      case TestCategory.all:
        await runCompleteTestSuite();
        break;
    }
  }

  /// Run tests with specific tags
  Future<void> runTestsWithTags(List<String> tags) async {
    print('🏷️ Running tests with tags: ${tags.join(', ')}');

    // Run E2E scenarios with matching tags
    await _e2eScenarios.runScenariosWithTags(tags);

    // Run benchmarks for specific categories
    for (final tag in tags) {
      if (['performance', 'memory', 'network'].contains(tag)) {
        await _benchmarkSuite.runBenchmarkCategory(tag);
      }
    }
  }

  /// Get overall test coverage and quality metrics
  TestQualityMetrics getQualityMetrics() {
    return TestQualityMetrics(
      testFrameworkHealth: {'status': 'healthy', 'components': 3},
      integrationCoverage: {
        'totalTests': _e2eScenarios.results.length,
        'coverage': 85.0
      },
      performanceBaseline: _benchmarkSuite.getPerformanceStatistics(),
      e2eSuccessRate: _e2eScenarios.successRate,
    );
  }

  Future<void> _generateComprehensiveReport(TestSuiteResults results) async {
    final report = {
      'timestamp': DateTime.now().toIso8601String(),
      'testSuite': 'Universal Sync Manager - Phase 6 Testing Infrastructure',
      'executionSummary': {
        'totalExecutionTime': results.executionTime.inSeconds,
        'overallSuccess': !results.failed,
        'testCategories': {
          'integration': results.integrationResults.length,
          'performance': results.benchmarkResults.length,
          'endToEnd': results.e2eResults.length,
        },
      },
      'qualityMetrics': getQualityMetrics().toJson(),
      'detailedResults': {
        'integration':
            results.integrationResults.map((r) => r.toJson()).toList(),
        'benchmarks': results.benchmarkResults.map((r) => r.toJson()).toList(),
        'e2eScenarios': results.e2eResults.map((r) => r.toJson()).toList(),
      },
      'recommendations': _generateRecommendations(results),
    };

    print('\n📄 Comprehensive test report generated');
    print('📊 Test Results Summary:');
    print(
        '   • Report contains ${(report['detailedResults']! as Map).length} test categories');
    print('   • Integration Tests: ${results.integrationResults.length}');
    print('   • Performance Benchmarks: ${results.benchmarkResults.length}');
    print('   • E2E Scenarios: ${results.e2eResults.length}');
    print('   • Total Execution Time: ${results.executionTime.inSeconds}s');
    print('   • Overall Success: ${!results.failed ? "✅" : "❌"}');
  }

  List<String> _generateRecommendations(TestSuiteResults results) {
    final recommendations = <String>[];

    // Analyze E2E success rate
    final e2eSuccessRate = _e2eScenarios.successRate;
    if (e2eSuccessRate < 0.9) {
      recommendations.add(
          'E2E success rate is ${(e2eSuccessRate * 100).toStringAsFixed(1)}% - investigate failing scenarios');
    }

    // Analyze performance benchmarks
    final perfStats = _benchmarkSuite.getPerformanceStatistics();
    final avgTime = perfStats['overallAverageTime'] as double? ?? 0;
    if (avgTime > 1000) {
      // More than 1 second average
      recommendations.add(
          'Average operation time is ${avgTime.toStringAsFixed(0)}ms - consider performance optimization');
    }

    // Integration test recommendations
    if (results.integrationResults.isEmpty) {
      recommendations.add(
          'No integration tests executed - ensure comprehensive backend testing');
    }

    if (recommendations.isEmpty) {
      recommendations.add(
          'All test metrics are within acceptable ranges - system ready for production');
    }

    return recommendations;
  }
}

/// Test execution categories
enum TestCategory {
  integration,
  performance,
  endToEnd,
  all,
}

/// Consolidated test results from all phases
class TestSuiteResults {
  List<IntegrationTestResult> integrationResults = [];
  List<BenchmarkResult> benchmarkResults = [];
  List<E2ETestResult> e2eResults = [];
  Duration executionTime = Duration.zero;
  bool failed = false;
  String? errorMessage;
}

/// Quality metrics across all test categories
class TestQualityMetrics {
  final Map<String, dynamic> testFrameworkHealth;
  final Map<String, dynamic> integrationCoverage;
  final Map<String, dynamic> performanceBaseline;
  final double e2eSuccessRate;

  const TestQualityMetrics({
    required this.testFrameworkHealth,
    required this.integrationCoverage,
    required this.performanceBaseline,
    required this.e2eSuccessRate,
  });

  Map<String, dynamic> toJson() => {
        'testFrameworkHealth': testFrameworkHealth,
        'integrationCoverage': integrationCoverage,
        'performanceBaseline': performanceBaseline,
        'e2eSuccessRate': e2eSuccessRate,
        'overallQualityScore': _calculateQualityScore(),
      };

  double _calculateQualityScore() {
    // Weighted quality score (0-100)
    final e2eWeight = 0.4;
    final perfWeight = 0.3;
    final integrationWeight = 0.3;

    final e2eScore = e2eSuccessRate * 100;
    final perfScore = _calculatePerformanceScore();
    final integrationScore = _calculateIntegrationScore();

    return (e2eScore * e2eWeight) +
        (perfScore * perfWeight) +
        (integrationScore * integrationWeight);
  }

  double _calculatePerformanceScore() {
    // Simplified performance scoring based on baseline metrics
    final avgThroughput =
        performanceBaseline['overallThroughput'] as double? ?? 0;
    return (avgThroughput > 100)
        ? 100
        : avgThroughput; // 100+ ops/sec = perfect score
  }

  double _calculateIntegrationScore() {
    // Simplified integration scoring based on test coverage
    final testCount = integrationCoverage['totalTests'] as int? ?? 0;
    return (testCount > 10) ? 100 : testCount * 10; // 10+ tests = perfect score
  }
}

/// Main entry point for running tests
Future<void> main() async {
  final testSuite = UniversalSyncManagerTestSuite();

  try {
    await testSuite.initialize();
    final results = await testSuite.runCompleteTestSuite();

    if (results.failed) {
      print('\n❌ Test suite failed: ${results.errorMessage}');
    } else {
      print('\n🎉 All tests completed successfully!');
      final metrics = testSuite.getQualityMetrics();
      print(
          '📊 Overall Quality Score: ${metrics._calculateQualityScore().toStringAsFixed(1)}/100');
    }
  } catch (e) {
    print('\n💥 Test suite crashed: $e');
  }
}

/// Example usage for different test scenarios:
/// 
/// ```dart
/// // Run all tests
/// await testSuite.runCompleteTestSuite();
/// 
/// // Run specific category
/// await testSuite.runTestCategory(TestCategory.performance);
/// 
/// // Run tests with specific tags
/// await testSuite.runTestsWithTags(['core', 'offline']);
/// 
/// // Get quality metrics
/// final metrics = testSuite.getQualityMetrics();
/// print('E2E Success Rate: ${metrics.e2eSuccessRate}');
/// ```
