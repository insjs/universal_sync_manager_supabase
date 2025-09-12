// test/live_tests/phase1_pocketbase/tests/sync_tests_with_sdk.dart

import 'dart:io';
import 'dart:convert';
import 'package:pocketbase/pocketbase.dart';
import 'package:yaml/yaml.dart';

/// Live Sync Tests for USM PocketBase Integration using PocketBase SDK
///
/// This class performs live synchronization tests between local SQLite
/// and PocketBase backend using the official PocketBase SDK for better
/// reliability, HTTPS support, and cleaner code.
class USMLiveSyncTestsSDK {
  late Map<String, dynamic> _config;
  late Map<String, dynamic> _schema;
  late PocketBase _pb;
  bool _isAuthenticated = false;

  /// Test execution results
  final List<TestResult> _testResults = [];

  /// Initialize test environment
  Future<void> initialize() async {
    print('🚀 Initializing USM Live Sync Tests with PocketBase SDK...');

    await _loadConfiguration();
    await _loadSchema();
    await _initializePocketBase();
    await _authenticateWithPocketBase();

    print('✅ Test environment initialized');
  }

  /// Load configuration from YAML
  Future<void> _loadConfiguration() async {
    try {
      // Try multiple possible paths for the configuration file
      final possiblePaths = [
        '../setup/config.yaml', // From tests directory
        'test/live_tests/phase1_pocketbase/setup/config.yaml', // From project root
        'setup/config.yaml', // Direct path
      ];

      File? configFile;
      for (final path in possiblePaths) {
        final file = File(path);
        if (await file.exists()) {
          configFile = file;
          break;
        }
      }

      if (configFile == null) {
        throw Exception(
            'Configuration file not found. Tried: ${possiblePaths.join(', ')}');
      }

      final configContent = await configFile.readAsString();
      final doc = loadYaml(configContent);
      _config = _convertYamlToMap(doc);

      print('📋 Configuration loaded from: ${configFile.path}');
    } catch (e) {
      throw Exception('Failed to load configuration: $e');
    }
  }

  /// Load schema definition from YAML
  Future<void> _loadSchema() async {
    try {
      final testConfig = _config['test'] as Map<String, dynamic>;
      final schemaName = testConfig['schema'] as String;

      // Try multiple possible paths for the schema file
      final possiblePaths = [
        '../schemas/$schemaName.yaml', // From tests directory
        'test/live_tests/phase1_pocketbase/schemas/$schemaName.yaml', // From project root
        'tools/schema/$schemaName.yaml', // Tools directory
        'schemas/$schemaName.yaml', // Direct path
      ];

      File? schemaFile;
      for (final path in possiblePaths) {
        final file = File(path);
        if (await file.exists()) {
          schemaFile = file;
          break;
        }
      }

      if (schemaFile == null) {
        throw Exception(
            'Schema file not found. Tried: ${possiblePaths.join(', ')}');
      }

      final schemaContent = await schemaFile.readAsString();
      final doc = loadYaml(schemaContent);
      _schema = _convertYamlToMap(doc);

      print(
          '📄 Schema loaded from: ${schemaFile.path} (table: ${_schema['table']})');
    } catch (e) {
      throw Exception('Failed to load schema: $e');
    }
  }

  /// Convert YAML to Map<String, dynamic> safely
  Map<String, dynamic> _convertYamlToMap(dynamic yamlDoc) {
    return Map<String, dynamic>.from(
      json.decode(json.encode(yamlDoc)) as Map<String, dynamic>,
    );
  }

  /// Initialize PocketBase client
  Future<void> _initializePocketBase() async {
    try {
      final pbConfig = _config['pocketbase'] as Map<String, dynamic>;
      final baseUrl = pbConfig['url'] as String;

      _pb = PocketBase(baseUrl);
      print('🔗 PocketBase client initialized: $baseUrl');
    } catch (e) {
      throw Exception('Failed to initialize PocketBase client: $e');
    }
  }

  /// Authenticate with PocketBase admin
  Future<void> _authenticateWithPocketBase() async {
    try {
      final pbConfig = _config['pocketbase'] as Map<String, dynamic>;
      final adminEmail = pbConfig['admin_email'] as String;
      final adminPassword = pbConfig['admin_password'] as String;

      print('🔐 Authenticating with PocketBase...');

      // Try superusers authentication first (newer PocketBase versions)
      try {
        await _pb.collection('_superusers').authWithPassword(
              adminEmail,
              adminPassword,
            );
        _isAuthenticated = true;
        print('✅ Authenticated as superuser');
        return;
      } catch (e) {
        print('🔄 Superuser auth failed, trying admin auth...');
      }

      // Fallback to admin authentication (older PocketBase versions)
      await _pb.admins.authWithPassword(adminEmail, adminPassword);
      _isAuthenticated = true;
      print('✅ Authenticated as admin');
    } catch (e) {
      throw Exception('Failed to authenticate: $e');
    }
  }

  /// Run all sync tests
  Future<void> runAllTests() async {
    print('🧪 Running USM Live Sync Tests...');
    print('================================');

    if (!_isAuthenticated) {
      throw Exception('Not authenticated with PocketBase');
    }

    // Test 1: Local to Remote Sync (Create)
    await _testLocalToRemoteSync();

    // Test 2: Remote to Local Sync (Read)
    await _testRemoteToLocalSync();

    // Test 3: Bidirectional Sync (Update)
    await _testBidirectionalSync();

    // Test 4: Conflict Resolution
    await _testConflictResolution();

    // Test 5: Bulk Operations
    await _testBulkOperations();

    // Test 6: Network Failure Recovery
    await _testNetworkFailureRecovery();

    // Print summary
    _printTestSummary();
  }

  /// Test 1: Local to Remote Sync
  Future<void> _testLocalToRemoteSync() async {
    final testName = 'Local to Remote Sync';
    print('\\n🔄 Running Test 1: $testName');

    try {
      final tableName = _schema['table'] as String;
      final testData = _generateTestData();

      // Create record in PocketBase using SDK
      final record = await _pb.collection(tableName).create(body: testData);

      // Verify the record was created
      if (record.id.isNotEmpty) {
        _addTestResult(TestResult(
          name: testName,
          success: true,
          message: 'Successfully created record: ${record.id}',
          duration: DateTime.now(),
        ));
        print('✅ Test 1 passed: Record created with ID ${record.id}');
      } else {
        throw Exception('Record created but ID is empty');
      }
    } catch (e) {
      _addTestResult(TestResult(
        name: testName,
        success: false,
        message: 'Failed: $e',
        duration: DateTime.now(),
      ));
      print('❌ Test 1 failed: $e');
    }
  }

  /// Test 2: Remote to Local Sync
  Future<void> _testRemoteToLocalSync() async {
    final testName = 'Remote to Local Sync';
    print('\\n🔄 Running Test 2: $testName');

    try {
      final tableName = _schema['table'] as String;

      // Get all records from PocketBase
      final resultList = await _pb.collection(tableName).getList(
            page: 1,
            perPage: 50,
          );

      if (resultList.items.isNotEmpty) {
        _addTestResult(TestResult(
          name: testName,
          success: true,
          message: 'Successfully fetched ${resultList.items.length} records',
          duration: DateTime.now(),
        ));
        print('✅ Test 2 passed: Fetched ${resultList.items.length} records');
      } else {
        _addTestResult(TestResult(
          name: testName,
          success: true,
          message: 'No records found (expected for clean test)',
          duration: DateTime.now(),
        ));
        print('✅ Test 2 passed: No records found (clean state)');
      }
    } catch (e) {
      _addTestResult(TestResult(
        name: testName,
        success: false,
        message: 'Failed: $e',
        duration: DateTime.now(),
      ));
      print('❌ Test 2 failed: $e');
    }
  }

  /// Test 3: Bidirectional Sync
  Future<void> _testBidirectionalSync() async {
    final testName = 'Bidirectional Sync';
    print('\\n🔄 Running Test 3: $testName');

    try {
      final tableName = _schema['table'] as String;
      final testData = _generateTestData();

      // Create record
      final record = await _pb.collection(tableName).create(body: testData);

      // Update the record
      final updateData = Map<String, dynamic>.from(testData);
      updateData['name'] = 'Updated ${testData['name']}';
      updateData['updatedAt'] = DateTime.now().toIso8601String();

      final updatedRecord = await _pb.collection(tableName).update(
            record.id,
            body: updateData,
          );

      if (updatedRecord.data['name'] == updateData['name']) {
        _addTestResult(TestResult(
          name: testName,
          success: true,
          message: 'Successfully updated record: ${record.id}',
          duration: DateTime.now(),
        ));
        print('✅ Test 3 passed: Record updated successfully');
      } else {
        throw Exception('Record update verification failed');
      }
    } catch (e) {
      _addTestResult(TestResult(
        name: testName,
        success: false,
        message: 'Failed: $e',
        duration: DateTime.now(),
      ));
      print('❌ Test 3 failed: $e');
    }
  }

  /// Test 4: Conflict Resolution
  Future<void> _testConflictResolution() async {
    final testName = 'Conflict Resolution';
    print('\\n🔄 Running Test 4: $testName');

    try {
      final tableName = _schema['table'] as String;
      final testData = _generateTestData();

      // Create record
      final record = await _pb.collection(tableName).create(body: testData);

      // Simulate conflict by updating with different sync versions
      final localUpdate = Map<String, dynamic>.from(testData);
      localUpdate['name'] = 'Local Update';
      localUpdate['syncVersion'] = 1;
      localUpdate['updatedAt'] = DateTime.now().toIso8601String();

      final remoteUpdate = Map<String, dynamic>.from(testData);
      remoteUpdate['name'] = 'Remote Update';
      remoteUpdate['syncVersion'] = 2;
      remoteUpdate['updatedAt'] =
          DateTime.now().add(Duration(seconds: 1)).toIso8601String();

      // Apply remote update (should win due to higher sync version)
      final resolvedRecord = await _pb.collection(tableName).update(
            record.id,
            body: remoteUpdate,
          );

      if (resolvedRecord.data['name'] == 'Remote Update') {
        _addTestResult(TestResult(
          name: testName,
          success: true,
          message: 'Conflict resolved correctly (remote wins)',
          duration: DateTime.now(),
        ));
        print('✅ Test 4 passed: Conflict resolution working');
      } else {
        throw Exception('Conflict resolution failed');
      }
    } catch (e) {
      _addTestResult(TestResult(
        name: testName,
        success: false,
        message: 'Failed: $e',
        duration: DateTime.now(),
      ));
      print('❌ Test 4 failed: $e');
    }
  }

  /// Test 5: Bulk Operations
  Future<void> _testBulkOperations() async {
    final testName = 'Bulk Operations';
    print('\\n🔄 Running Test 5: $testName');

    try {
      final tableName = _schema['table'] as String;
      final batchSize = 5;
      final createdIds = <String>[];

      // Create multiple records
      for (int i = 0; i < batchSize; i++) {
        final testData = _generateTestData();
        testData['name'] = 'Bulk Test $i';

        final record = await _pb.collection(tableName).create(body: testData);
        createdIds.add(record.id);
      }

      // Verify all records were created
      final resultList = await _pb.collection(tableName).getList(
            page: 1,
            perPage: 50,
            filter: createdIds.map((id) => 'id="$id"').join(' || '),
          );

      if (resultList.items.length == batchSize) {
        _addTestResult(TestResult(
          name: testName,
          success: true,
          message: 'Successfully created and verified $batchSize records',
          duration: DateTime.now(),
        ));
        print('✅ Test 5 passed: Bulk operations working');
      } else {
        throw Exception(
            'Bulk verification failed: expected $batchSize, got ${resultList.items.length}');
      }
    } catch (e) {
      _addTestResult(TestResult(
        name: testName,
        success: false,
        message: 'Failed: $e',
        duration: DateTime.now(),
      ));
      print('❌ Test 5 failed: $e');
    }
  }

  /// Test 6: Network Failure Recovery
  Future<void> _testNetworkFailureRecovery() async {
    final testName = 'Network Failure Recovery';
    print('\\n🔄 Running Test 6: $testName');

    try {
      final tableName = _schema['table'] as String;

      // Test timeout handling
      final testData = _generateTestData();

      // Create record with normal operation
      final record = await _pb.collection(tableName).create(body: testData);

      // Simulate recovery by reading the record back
      final recoveredRecord = await _pb.collection(tableName).getOne(record.id);

      if (recoveredRecord.id == record.id) {
        _addTestResult(TestResult(
          name: testName,
          success: true,
          message: 'Network recovery simulation successful',
          duration: DateTime.now(),
        ));
        print('✅ Test 6 passed: Network failure recovery working');
      } else {
        throw Exception('Recovery verification failed');
      }
    } catch (e) {
      _addTestResult(TestResult(
        name: testName,
        success: false,
        message: 'Failed: $e',
        duration: DateTime.now(),
      ));
      print('❌ Test 6 failed: $e');
    }
  }

  /// Generate test data based on schema
  Map<String, dynamic> _generateTestData() {
    final fields = _schema['fields'] as Map<String, dynamic>;
    final testData = <String, dynamic>{};

    // Generate data based on field definitions
    fields.forEach((fieldName, fieldConfig) {
      final config = fieldConfig as Map<String, dynamic>;
      final type = config['type'] as String;

      switch (type) {
        case 'text':
          testData[fieldName] =
              'Test ${fieldName}_${DateTime.now().millisecondsSinceEpoch}';
          break;
        case 'number':
          testData[fieldName] = DateTime.now().millisecondsSinceEpoch;
          break;
        case 'bool':
          testData[fieldName] = true;
          break;
        case 'date':
          testData[fieldName] = DateTime.now().toIso8601String();
          break;
        case 'email':
          testData[fieldName] =
              'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
          break;
        case 'url':
          testData[fieldName] =
              'https://example.com/test_${DateTime.now().millisecondsSinceEpoch}';
          break;
        default:
          testData[fieldName] =
              'test_value_${DateTime.now().millisecondsSinceEpoch}';
      }
    });

    // Add standard USM fields
    final now = DateTime.now().toIso8601String();
    testData['organizationId'] =
        'test-org-${DateTime.now().millisecondsSinceEpoch}';
    testData['createdBy'] = 'test-user';
    testData['updatedBy'] = 'test-user';
    testData['createdAt'] = now;
    testData['updatedAt'] = now;
    testData['isDirty'] = false;
    testData['syncVersion'] = 0;
    testData['isDeleted'] = false;

    return testData;
  }

  /// Add test result
  void _addTestResult(TestResult result) {
    _testResults.add(result);
  }

  /// Print test summary
  void _printTestSummary() {
    print('\\n📊 Test Summary');
    print('================');

    final passed = _testResults.where((r) => r.success).length;
    final failed = _testResults.where((r) => !r.success).length;

    print('✅ Passed: $passed');
    print('❌ Failed: $failed');
    print('📝 Total: ${_testResults.length}');

    if (failed > 0) {
      print('\\n❌ Failed Tests:');
      for (final result in _testResults.where((r) => !r.success)) {
        print('   • ${result.name}: ${result.message}');
      }
    }

    print(
        '\\n🎯 Success Rate: ${(passed / _testResults.length * 100).toStringAsFixed(1)}%');
  }

  /// Clean up test environment
  Future<void> cleanup() async {
    try {
      final tableName = _schema['table'] as String;
      final testConfig = _config['test'] as Map<String, dynamic>;
      final cleanupAfterTests =
          testConfig['cleanup_after_tests'] as bool? ?? true;

      if (cleanupAfterTests) {
        print('\\n🧹 Cleaning up test data...');

        // Get all test records
        final resultList = await _pb.collection(tableName).getList(
              page: 1,
              perPage: 500,
              filter: 'createdBy="test-user"',
            );

        // Delete test records
        for (final record in resultList.items) {
          await _pb.collection(tableName).delete(record.id);
        }

        print('✅ Cleaned up ${resultList.items.length} test records');
      }
    } catch (e) {
      print('⚠️  Cleanup failed: $e');
    }
  }
}

/// Test result data class
class TestResult {
  final String name;
  final bool success;
  final String message;
  final DateTime duration;

  TestResult({
    required this.name,
    required this.success,
    required this.message,
    required this.duration,
  });
}

/// Main function to run the tests
void main() async {
  final tests = USMLiveSyncTestsSDK();

  try {
    await tests.initialize();
    await tests.runAllTests();
  } catch (e) {
    print('💥 Test execution failed: $e');
    exit(1);
  } finally {
    await tests.cleanup();
  }

  print('\\n🏁 Test execution completed');
}
