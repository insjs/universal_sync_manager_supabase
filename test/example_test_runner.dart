// test/example_test_runner.dart

import 'dart:io';
import 'dart:convert';
import 'suites/comprehensive_sync_test_suite.dart';
import 'scenario_generators/sync_scenario_generator.dart';

/// Example test runner demonstrating how to use the comprehensive test framework
void main() async {
  print('=== Universal Sync Manager Test Framework Demo ===\n');

  // Create test suite with custom configuration
  final testConfig = TestSuiteConfig(
    maxTestTimeout: const Duration(minutes: 2),
    enableDetailedLogging: true,
    enableParallelExecution: false, // Set to false for clearer output
    stopOnFirstFailure: false,
  );

  final testSuite = ComprehensiveSyncTestSuite(testConfig);

  try {
    // Run basic test suite
    print('🚀 Running Basic Test Suite...\n');
    final basicResults =
        await testSuite.runSuite(suiteName: 'Basic Functionality Tests');
    _printResults(basicResults);

    // Run scenario-based tests
    print('\n🎭 Running Scenario-based Tests...\n');
    final scenarioResults = await testSuite.runScenarios([
      SyncScenarioType.simpleSync,
      SyncScenarioType.conflictResolution,
      SyncScenarioType.networkFailure,
    ]);
    _printResults(scenarioResults);

    // Run performance tests
    print('\n⚡ Running Performance Tests...\n');
    final performanceResults = await testSuite.runPerformanceTests();
    _printResults(performanceResults);

    // Show overall statistics
    print('\n📊 Overall Test Statistics:');
    final stats = testSuite.getExecutionStatistics();
    _printStatistics(stats);

    // Export results to JSON file
    await _exportResults(testSuite.suiteResults);
  } catch (e) {
    print('❌ Test execution failed: $e');
    exit(1);
  }

  print('\n✅ Test execution completed successfully!');
}

void _printResults(TestSuiteResult result) {
  print('📋 Suite: ${result.suiteName}');
  print('⏱️  Duration: ${result.totalExecutionTime.inMilliseconds}ms');
  print('✅ Passed: ${result.passedTests}/${result.totalTests}');
  print('❌ Failed: ${result.failedTests}');
  print('⏭️  Skipped: ${result.skippedTests}');
  print('📈 Success Rate: ${(result.successRate * 100).toStringAsFixed(1)}%');

  if (result.failedTests > 0) {
    print('\n❌ Failed Tests:');
    for (final test in result.testResults.where((t) => t.isFailed)) {
      print('  • ${test.testName}: ${test.errorMessage}');
    }
  }

  print('');
}

void _printStatistics(Map<String, dynamic> stats) {
  print('  Total Suites: ${stats['totalSuites']}');
  print('  Total Tests: ${stats['totalTests']}');
  print(
      '  Overall Success Rate: ${(stats['overallSuccessRate'] * 100).toStringAsFixed(1)}%');
  print(
      '  Average Execution Time: ${stats['averageExecutionTimeMs'].toStringAsFixed(0)}ms');
}

Future<void> _exportResults(List<TestSuiteResult> results) async {
  try {
    final exportData = {
      'timestamp': DateTime.now().toIso8601String(),
      'testFrameworkVersion': '1.0.0',
      'results': results.map((r) => r.toJson()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
    final file =
        File('test_results_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonString);

    print('📄 Results exported to: ${file.path}');
  } catch (e) {
    print('⚠️  Failed to export results: $e');
  }
}
