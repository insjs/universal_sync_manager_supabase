# Universal Sync Manager Test Framework

A comprehensive testing framework for the Universal Sync Manager, providing mock backends, scenario generators, conflict simulation, network condition simulation, and comprehensive test suites.

## Overview

The test framework consists of several key components:

### 🎭 Mock Backend Adapter
- **Location**: `test/mocks/mock_sync_backend_adapter.dart`
- **Purpose**: Simulates backend operations with configurable behavior
- **Features**:
  - Full CRUD operations
  - Batch operations
  - Real-time subscriptions
  - Network condition simulation
  - Error injection
  - Conflict simulation
  - Operation logging

### 🎬 Scenario Generators
- **Location**: `test/scenario_generators/sync_scenario_generator.dart`
- **Purpose**: Generates complex test scenarios for various sync situations
- **Scenario Types**:
  - Simple sync operations
  - Conflict resolution
  - Network failures
  - Large batch operations
  - Real-time updates
  - Offline sync
  - Data corruption
  - Concurrent users
  - Backend failover
  - Performance stress testing

### ⚔️ Conflict Simulation
- **Location**: `test/conflict_simulation/conflict_simulator.dart`
- **Purpose**: Simulates various types of sync conflicts
- **Conflict Types**:
  - Update-Update conflicts
  - Update-Delete conflicts
  - Create-Create conflicts
  - Timestamp skew conflicts
  - Version mismatch conflicts
  - Field-level conflicts
  - Structural conflicts

### 🌐 Network Condition Simulation
- **Location**: `test/network_simulation/network_condition_simulator.dart`
- **Purpose**: Simulates various network conditions and failures
- **Features**:
  - Multiple network types (WiFi, 4G, 3G, 2G, offline)
  - Network quality simulation
  - Bandwidth throttling
  - Latency injection
  - Packet loss simulation
  - Network instability
  - Gradual degradation

### 🧪 Comprehensive Test Suites
- **Location**: `test/suites/comprehensive_sync_test_suite.dart`
- **Purpose**: Orchestrates and executes comprehensive test suites
- **Features**:
  - Parallel and sequential test execution
  - Test result reporting
  - Performance metrics
  - Test filtering and tagging
  - Detailed logging

## Usage

### Basic Test Execution

```dart
import 'suites/comprehensive_sync_test_suite.dart';

void main() async {
  final testSuite = ComprehensiveSyncTestSuite();
  
  // Run all tests
  final results = await testSuite.runSuite();
  
  print('Tests passed: ${results.passedTests}/${results.totalTests}');
  print('Success rate: ${(results.successRate * 100).toStringAsFixed(1)}%');
}
```

### Scenario-Based Testing

```dart
import 'scenario_generators/sync_scenario_generator.dart';

void main() async {
  final generator = SyncScenarioGenerator();
  
  // Generate a conflict resolution scenario
  final scenario = generator.generateScenario(SyncScenarioType.conflictResolution);
  
  print('Generated ${scenario.operations.length} operations');
  print('Expected conflicts: ${scenario.expectedResults['conflicts']}');
}
```

### Conflict Simulation

```dart
import 'conflict_simulation/conflict_simulator.dart';

void main() async {
  final simulator = ConflictSimulator();
  
  // Simulate an update-update conflict
  final conflict = simulator.simulateSpecificConflict(
    ConflictType.updateUpdate,
    'entity_123',
    'organization_profiles',
    {'name': 'Original Name', 'status': 'active'},
  );
  
  // Resolve the conflict
  final resolution = simulator.resolveConflict(
    conflict,
    ConflictResolutionStrategy.timestampWins,
  );
  
  print('Conflict resolved: ${resolution.successful}');
}
```

### Network Condition Testing

```dart
import 'network_simulation/network_condition_simulator.dart';

void main() async {
  final simulator = NetworkConditionSimulator();
  
  // Simulate poor network conditions
  simulator.setNetworkCondition(NetworkCondition.poor());
  
  // Test operation under poor conditions
  final result = await simulator.simulateOperation(
    'sync_operation',
    1024 * 1024, // 1MB data
  );
  
  print('Operation took: ${result.actualDuration.inMilliseconds}ms');
  print('Success: ${result.successful}');
}
```

## Test Configuration

### Test Suite Configuration

```dart
final config = TestSuiteConfig(
  maxTestTimeout: Duration(minutes: 5),
  stopOnFirstFailure: false,
  enableParallelExecution: true,
  maxConcurrentTests: 4,
  enableDetailedLogging: true,
  excludedTestTags: ['slow', 'experimental'],
);

final testSuite = ComprehensiveSyncTestSuite(config);
```

### Scenario Generation Configuration

```dart
final config = ScenarioGenerationConfig(
  maxOperations: 50,
  collections: ['users', 'profiles', 'settings'],
  operationTypes: ['create', 'read', 'update', 'delete'],
  failureRate: 0.1,
  includeConflicts: true,
  includeNetworkIssues: true,
);

final scenario = generator.generateScenario(
  SyncScenarioType.largeBatch,
  config: config,
);
```

### Network Simulation Configuration

```dart
final config = NetworkSimulationConfig(
  conditionChangeDuration: Duration(seconds: 30),
  conditionChangeChance: 0.2,
  enableJitter: true,
  enablePacketLoss: true,
  allowedConditions: [
    NetworkCondition.excellent(),
    NetworkCondition.good(),
    NetworkCondition.fair(),
  ],
);

final simulator = NetworkConditionSimulator(config);
```

## Running Tests

### Command Line
```bash
# Run example test suite
dart test/example_test_runner.dart

# Run specific test files
dart test/suites/comprehensive_sync_test_suite_test.dart
```

### Automated Testing
The framework can be integrated into CI/CD pipelines:

```yaml
name: Sync Manager Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: dart-lang/setup-dart@v1
      - run: dart pub get
      - run: dart test/example_test_runner.dart
```

## Test Results

### Result Export
Test results are automatically exported to JSON format:

```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "testFrameworkVersion": "1.0.0",
  "results": [
    {
      "suiteId": "suite_123456789",
      "suiteName": "Basic Functionality Tests",
      "totalTests": 15,
      "passedTests": 14,
      "failedTests": 1,
      "successRate": 0.933,
      "totalExecutionTimeMs": 45000
    }
  ]
}
```

### Metrics Collected
- Test execution times
- Success/failure rates
- Network performance metrics
- Conflict resolution statistics
- Resource usage patterns

## Extending the Framework

### Custom Test Cases

```dart
class MyCustomTestCase extends SyncTestCase {
  @override
  String get testId => 'custom_test_001';
  
  @override
  String get testName => 'My Custom Test';
  
  @override
  List<String> get tags => ['custom', 'integration'];
  
  @override
  Future<TestResult> execute(TestExecutionContext context) async {
    // Your test implementation
    return TestResult(
      testId: testId,
      testName: testName,
      status: TestStatus.passed,
      executionTime: Duration(seconds: 1),
      startTime: DateTime.now(),
    );
  }
}

// Add to test suite
testSuite.addTest(MyCustomTestCase());
```

### Custom Scenarios

```dart
// Generate custom scenarios
final customScenarios = generator.generateParameterizedScenarios(
  SyncScenarioType.simpleSync,
  [
    {'maxOperations': 10, 'failureRate': 0.0},
    {'maxOperations': 100, 'failureRate': 0.1},
    {'maxOperations': 1000, 'failureRate': 0.2},
  ],
);
```

## Best Practices

1. **Start Simple**: Begin with basic sync operations before testing complex scenarios
2. **Use Realistic Data**: Configure scenarios with realistic data sizes and operation patterns
3. **Test Edge Cases**: Include tests for network failures, conflicts, and error conditions
4. **Monitor Performance**: Track execution times and resource usage
5. **Parallel Testing**: Use parallel execution for faster test cycles
6. **Continuous Integration**: Integrate tests into your CI/CD pipeline

## Troubleshooting

### Common Issues

1. **Test Timeouts**: Increase `maxTestTimeout` in configuration
2. **Memory Issues**: Reduce `maxConcurrentTests` for parallel execution
3. **Network Simulation**: Ensure realistic network conditions for your use case
4. **Conflict Resolution**: Verify conflict resolution strategies match your business logic

### Debug Mode
Enable detailed logging for troubleshooting:

```dart
final config = TestSuiteConfig(
  enableDetailedLogging: true,
);
```

## Contributing

To contribute to the test framework:

1. Add new test cases in the appropriate directories
2. Update documentation for new features
3. Ensure all tests pass before submitting
4. Follow the existing code style and patterns

## License

This test framework is part of the Universal Sync Manager project and follows the same license terms.
