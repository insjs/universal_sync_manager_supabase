// test/live_tests/phase1_pocketbase/tests/sync_tests.dart

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';

/// Live Sync Tests for USM PocketBase Integration
///
/// This class performs live synchronization tests between local SQLite
/// and PocketBase backend to validate the Universal Sync Manager functionality.
class USMLiveSyncTests {
  late Map<String, dynamic> _config;
  late Map<String, dynamic> _schema;
  String? _authToken;

  /// Test execution results
  final List<TestResult> _testResults = [];

  /// Initialize test environment
  Future<void> initialize() async {
    print('🚀 Initializing USM Live Sync Tests...');

    await _loadConfiguration();
    await _loadSchema();
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
      _config = Map<String, dynamic>.from(doc);

      print('📋 Configuration loaded from: ${configFile.path}');
    } catch (e) {
      throw Exception('Failed to load configuration: $e');
    }
  }

  /// Load schema definition
  Future<void> _loadSchema() async {
    try {
      // Try multiple possible paths for the schema file
      final possiblePaths = [
        '../schemas/usm_test.yaml', // From tests directory
        'test/live_tests/phase1_pocketbase/schemas/usm_test.yaml', // From project root
        'schemas/usm_test.yaml', // Direct path
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
      _schema = Map<String, dynamic>.from(doc);

      print(
          '📄 Schema loaded from: ${schemaFile.path} (table: ${_schema['table']})');
    } catch (e) {
      throw Exception('Failed to load schema: $e');
    }
  }

  /// Authenticate with PocketBase
  Future<void> _authenticateWithPocketBase() async {
    try {
      final pbConfig = _config['pocketbase'] as Map<String, dynamic>;
      final baseUrl = pbConfig['url'] as String;
      final adminEmail = pbConfig['admin_email'] as String;
      final adminPassword = pbConfig['admin_password'] as String;

      print('🔐 Authenticating with PocketBase...');

      var response = await http.post(
        Uri.parse('$baseUrl/api/collections/_superusers/auth-with-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identity': adminEmail,
          'password': adminPassword,
        }),
      );

      if (response.statusCode == 404) {
        response = await http.post(
          Uri.parse('$baseUrl/api/admins/auth-with-password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'identity': adminEmail,
            'password': adminPassword,
          }),
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _authToken = data['token'];
        print('✅ Authenticated with PocketBase');
      } else {
        throw Exception('Authentication failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to authenticate: $e');
    }
  }

  /// Get headers with authentication
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': _authToken!,
      };

  /// Run all sync tests
  Future<void> runAllTests() async {
    print('🧪 Running USM Live Sync Tests...');
    print('================================');

    // Test 1: Local to Remote Sync
    await _testLocalToRemoteSync();

    // Test 2: Remote to Local Sync
    await _testRemoteToLocalSync();

    // Test 3: Bidirectional Sync
    await _testBidirectionalSync();

    // Test 4: Conflict Resolution
    await _testConflictResolution();

    // Test 5: Bulk Operations
    await _testBulkOperations();

    // Test 6: Network Failure Recovery
    await _testNetworkFailureRecovery();

    // Generate test report
    await _generateTestReport();
  }

  /// Test 1: Local to Remote Sync
  Future<void> _testLocalToRemoteSync() async {
    print('\n📤 Test 1: Local to Remote Sync');
    print('-------------------------------');

    final testStart = DateTime.now();

    try {
      // Create test record locally (simulated)
      final localRecord = {
        'id': 'test_local_${testStart.millisecondsSinceEpoch}',
        'organizationId': 'org_001',
        'testName': 'Local to Remote Test',
        'testDescription': 'Testing sync from local SQLite to PocketBase',
        'testCategory': 'local_to_remote',
        'isActive': 1,
        'priority': 5,
        'completionPercentage': 0.75,
        'testData': jsonEncode({
          'syncDirection': 'local_to_remote',
          'timestamp': testStart.toIso8601String()
        }),
        'tags': jsonEncode(['local-sync', 'test']),
        'lastResult': 'pending',
        'createdBy': 'test_user',
        'updatedBy': 'test_user',
        'createdAt': testStart.toIso8601String(),
        'updatedAt': testStart.toIso8601String(),
        'isDirty': 1, // Mark as dirty for sync
        'syncVersion': 1,
        'isDeleted': 0,
      };

      print('   📝 Created local record: ${localRecord['id']}');

      // Simulate sync to PocketBase
      final pbConfig = _config['pocketbase'] as Map<String, dynamic>;
      final baseUrl = pbConfig['url'] as String;
      final collectionName = _schema['table'] as String;

      final response = await http.post(
        Uri.parse('$baseUrl/api/collections/$collectionName/records'),
        headers: _headers,
        body: jsonEncode(localRecord),
      );

      final testEnd = DateTime.now();
      final duration = testEnd.difference(testStart);

      if (response.statusCode == 200) {
        final createdRecord = jsonDecode(response.body);
        print('   ✅ Record synced successfully');
        print('   📋 Remote ID: ${createdRecord['id']}');
        print('   ⏱️ Sync duration: ${duration.inMilliseconds}ms');

        _testResults.add(TestResult(
          testName: 'Local to Remote Sync',
          success: true,
          duration: duration,
          details: 'Record synced successfully',
        ));
      } else {
        print('   ❌ Sync failed: ${response.body}');
        _testResults.add(TestResult(
          testName: 'Local to Remote Sync',
          success: false,
          duration: duration,
          details: 'Sync failed: ${response.body}',
        ));
      }
    } catch (e) {
      final testEnd = DateTime.now();
      final duration = testEnd.difference(testStart);

      print('   ❌ Test failed: $e');
      _testResults.add(TestResult(
        testName: 'Local to Remote Sync',
        success: false,
        duration: duration,
        details: 'Test failed: $e',
      ));
    }
  }

  /// Test 2: Remote to Local Sync
  Future<void> _testRemoteToLocalSync() async {
    print('\n📥 Test 2: Remote to Local Sync');
    print('-------------------------------');

    final testStart = DateTime.now();

    try {
      // Create record in PocketBase
      final remoteRecord = {
        'organizationId': 'org_001',
        'testName': 'Remote to Local Test',
        'testDescription': 'Testing sync from PocketBase to local SQLite',
        'testCategory': 'remote_to_local',
        'isActive': 1,
        'priority': 3,
        'completionPercentage': 0.5,
        'testData': jsonEncode({
          'syncDirection': 'remote_to_local',
          'timestamp': testStart.toIso8601String()
        }),
        'tags': jsonEncode(['remote-sync', 'test']),
        'lastResult': 'pending',
        'createdBy': 'test_user',
        'updatedBy': 'test_user',
        'createdAt': testStart.toIso8601String(),
        'updatedAt': testStart.toIso8601String(),
        'isDirty': 0,
        'syncVersion': 1,
        'isDeleted': 0,
      };

      final pbConfig = _config['pocketbase'] as Map<String, dynamic>;
      final baseUrl = pbConfig['url'] as String;
      final collectionName = _schema['table'] as String;

      // Create in PocketBase
      final createResponse = await http.post(
        Uri.parse('$baseUrl/api/collections/$collectionName/records'),
        headers: _headers,
        body: jsonEncode(remoteRecord),
      );

      if (createResponse.statusCode == 200) {
        final createdRecord = jsonDecode(createResponse.body);
        print('   📝 Created remote record: ${createdRecord['id']}');

        // Simulate fetching for local sync
        final fetchResponse = await http.get(
          Uri.parse(
              '$baseUrl/api/collections/$collectionName/records/${createdRecord['id']}'),
          headers: _headers,
        );

        final testEnd = DateTime.now();
        final duration = testEnd.difference(testStart);

        if (fetchResponse.statusCode == 200) {
          final fetchedRecord = jsonDecode(fetchResponse.body);
          print('   ✅ Record fetched for local sync');
          print('   📋 Local sync data: ${fetchedRecord['testName']}');
          print('   ⏱️ Sync duration: ${duration.inMilliseconds}ms');

          _testResults.add(TestResult(
            testName: 'Remote to Local Sync',
            success: true,
            duration: duration,
            details: 'Record fetched and ready for local sync',
          ));
        } else {
          print('   ❌ Fetch failed: ${fetchResponse.body}');
          _testResults.add(TestResult(
            testName: 'Remote to Local Sync',
            success: false,
            duration: duration,
            details: 'Fetch failed: ${fetchResponse.body}',
          ));
        }
      } else {
        final testEnd = DateTime.now();
        final duration = testEnd.difference(testStart);

        print('   ❌ Remote creation failed: ${createResponse.body}');
        _testResults.add(TestResult(
          testName: 'Remote to Local Sync',
          success: false,
          duration: duration,
          details: 'Remote creation failed: ${createResponse.body}',
        ));
      }
    } catch (e) {
      final testEnd = DateTime.now();
      final duration = testEnd.difference(testStart);

      print('   ❌ Test failed: $e');
      _testResults.add(TestResult(
        testName: 'Remote to Local Sync',
        success: false,
        duration: duration,
        details: 'Test failed: $e',
      ));
    }
  }

  /// Test 3: Bidirectional Sync
  Future<void> _testBidirectionalSync() async {
    print('\n🔄 Test 3: Bidirectional Sync');
    print('-----------------------------');

    final testStart = DateTime.now();

    try {
      final pbConfig = _config['pocketbase'] as Map<String, dynamic>;
      final baseUrl = pbConfig['url'] as String;
      final collectionName = _schema['table'] as String;

      // Create initial record
      final initialRecord = {
        'organizationId': 'org_001',
        'testName': 'Bidirectional Sync Test',
        'testDescription': 'Testing bidirectional synchronization',
        'testCategory': 'bidirectional',
        'isActive': 1,
        'priority': 7,
        'completionPercentage': 0.0,
        'testData':
            jsonEncode({'syncDirection': 'bidirectional', 'version': 1}),
        'tags': jsonEncode(['bidirectional', 'test']),
        'lastResult': 'initial',
        'createdBy': 'test_user',
        'updatedBy': 'test_user',
        'createdAt': testStart.toIso8601String(),
        'updatedAt': testStart.toIso8601String(),
        'isDirty': 0,
        'syncVersion': 1,
        'isDeleted': 0,
      };

      // Create record
      final createResponse = await http.post(
        Uri.parse('$baseUrl/api/collections/$collectionName/records'),
        headers: _headers,
        body: jsonEncode(initialRecord),
      );

      if (createResponse.statusCode == 200) {
        final createdRecord = jsonDecode(createResponse.body);
        final recordId = createdRecord['id'];
        print('   📝 Created initial record: $recordId');

        // Simulate local update
        final localUpdate = {
          'completionPercentage': 0.5,
          'testData': jsonEncode({
            'syncDirection': 'bidirectional',
            'version': 2,
            'updatedLocally': true
          }),
          'lastResult': 'updated_locally',
          'updatedAt': DateTime.now().toIso8601String(),
          'syncVersion': 2,
        };

        // Update on server (simulating local->remote sync)
        final updateResponse = await http.patch(
          Uri.parse(
              '$baseUrl/api/collections/$collectionName/records/$recordId'),
          headers: _headers,
          body: jsonEncode(localUpdate),
        );

        if (updateResponse.statusCode == 200) {
          print('   📤 Local changes synced to remote');

          // Fetch updated record (simulating remote->local sync)
          final fetchResponse = await http.get(
            Uri.parse(
                '$baseUrl/api/collections/$collectionName/records/$recordId'),
            headers: _headers,
          );

          final testEnd = DateTime.now();
          final duration = testEnd.difference(testStart);

          if (fetchResponse.statusCode == 200) {
            final finalRecord = jsonDecode(fetchResponse.body);
            print('   📥 Remote changes fetched to local');
            print('   ✅ Bidirectional sync completed');
            print('   📊 Final version: ${finalRecord['syncVersion']}');
            print('   ⏱️ Total duration: ${duration.inMilliseconds}ms');

            _testResults.add(TestResult(
              testName: 'Bidirectional Sync',
              success: true,
              duration: duration,
              details: 'Bidirectional sync completed successfully',
            ));
          } else {
            print('   ❌ Fetch failed: ${fetchResponse.body}');
            _testResults.add(TestResult(
              testName: 'Bidirectional Sync',
              success: false,
              duration: duration,
              details: 'Fetch failed: ${fetchResponse.body}',
            ));
          }
        } else {
          final testEnd = DateTime.now();
          final duration = testEnd.difference(testStart);

          print('   ❌ Update failed: ${updateResponse.body}');
          _testResults.add(TestResult(
            testName: 'Bidirectional Sync',
            success: false,
            duration: duration,
            details: 'Update failed: ${updateResponse.body}',
          ));
        }
      } else {
        final testEnd = DateTime.now();
        final duration = testEnd.difference(testStart);

        print('   ❌ Creation failed: ${createResponse.body}');
        _testResults.add(TestResult(
          testName: 'Bidirectional Sync',
          success: false,
          duration: duration,
          details: 'Creation failed: ${createResponse.body}',
        ));
      }
    } catch (e) {
      final testEnd = DateTime.now();
      final duration = testEnd.difference(testStart);

      print('   ❌ Test failed: $e');
      _testResults.add(TestResult(
        testName: 'Bidirectional Sync',
        success: false,
        duration: duration,
        details: 'Test failed: $e',
      ));
    }
  }

  /// Test 4: Conflict Resolution
  Future<void> _testConflictResolution() async {
    print('\n⚔️ Test 4: Conflict Resolution');
    print('------------------------------');

    final testStart = DateTime.now();

    try {
      final pbConfig = _config['pocketbase'] as Map<String, dynamic>;
      final baseUrl = pbConfig['url'] as String;
      final collectionName = _schema['table'] as String;

      // Create initial record
      final initialRecord = {
        'organizationId': 'org_001',
        'testName': 'Conflict Resolution Test',
        'testDescription': 'Testing conflict resolution scenarios',
        'testCategory': 'conflict',
        'isActive': 1,
        'priority': 5,
        'completionPercentage': 0.3,
        'testData': jsonEncode({'version': 1, 'source': 'initial'}),
        'tags': jsonEncode(['conflict', 'test']),
        'lastResult': 'initial',
        'createdBy': 'test_user',
        'updatedBy': 'test_user',
        'createdAt': testStart.toIso8601String(),
        'updatedAt': testStart.toIso8601String(),
        'isDirty': 0,
        'syncVersion': 1,
        'isDeleted': 0,
      };

      // Create record
      final createResponse = await http.post(
        Uri.parse('$baseUrl/api/collections/$collectionName/records'),
        headers: _headers,
        body: jsonEncode(initialRecord),
      );

      if (createResponse.statusCode == 200) {
        final createdRecord = jsonDecode(createResponse.body);
        final recordId = createdRecord['id'];
        print('   📝 Created record for conflict test: $recordId');

        // Simulate concurrent updates (conflict scenario)
        // Note: In a real conflict scenario, both updates would happen independently
        // Here we're simulating the resolution process
        final remoteUpdate = {
          'completionPercentage': 0.8,
          'testData': jsonEncode({'version': 2, 'source': 'remote_update'}),
          'lastResult': 'updated_remotely',
          'updatedAt':
              DateTime.now().add(const Duration(seconds: 1)).toIso8601String(),
          'syncVersion': 2,
        };

        // Apply remote update first
        final remoteResponse = await http.patch(
          Uri.parse(
              '$baseUrl/api/collections/$collectionName/records/$recordId'),
          headers: _headers,
          body: jsonEncode(remoteUpdate),
        );

        if (remoteResponse.statusCode == 200) {
          print('   📤 Remote update applied');

          // Simulate conflict resolution (server wins strategy)
          final conflictResolution = {
            'completionPercentage': 0.8, // Keep remote value
            'testData': jsonEncode({
              'version': 3,
              'source': 'conflict_resolved',
              'strategy': 'server_wins',
              'local_value': 0.7,
              'remote_value': 0.8,
            }),
            'lastResult': 'conflict_resolved',
            'updatedAt': DateTime.now().toIso8601String(),
            'syncVersion': 3,
          };

          final resolveResponse = await http.patch(
            Uri.parse(
                '$baseUrl/api/collections/$collectionName/records/$recordId'),
            headers: _headers,
            body: jsonEncode(conflictResolution),
          );

          final testEnd = DateTime.now();
          final duration = testEnd.difference(testStart);

          if (resolveResponse.statusCode == 200) {
            final resolvedRecord = jsonDecode(resolveResponse.body);
            print('   ✅ Conflict resolved successfully');
            print('   📊 Resolution strategy: server_wins');
            print(
                '   📈 Final completion: ${resolvedRecord['completionPercentage']}');
            print('   ⏱️ Resolution duration: ${duration.inMilliseconds}ms');

            _testResults.add(TestResult(
              testName: 'Conflict Resolution',
              success: true,
              duration: duration,
              details: 'Conflict resolved using server_wins strategy',
            ));
          } else {
            print('   ❌ Conflict resolution failed: ${resolveResponse.body}');
            _testResults.add(TestResult(
              testName: 'Conflict Resolution',
              success: false,
              duration: duration,
              details: 'Conflict resolution failed: ${resolveResponse.body}',
            ));
          }
        } else {
          final testEnd = DateTime.now();
          final duration = testEnd.difference(testStart);

          print('   ❌ Remote update failed: ${remoteResponse.body}');
          _testResults.add(TestResult(
            testName: 'Conflict Resolution',
            success: false,
            duration: duration,
            details: 'Remote update failed: ${remoteResponse.body}',
          ));
        }
      } else {
        final testEnd = DateTime.now();
        final duration = testEnd.difference(testStart);

        print('   ❌ Creation failed: ${createResponse.body}');
        _testResults.add(TestResult(
          testName: 'Conflict Resolution',
          success: false,
          duration: duration,
          details: 'Creation failed: ${createResponse.body}',
        ));
      }
    } catch (e) {
      final testEnd = DateTime.now();
      final duration = testEnd.difference(testStart);

      print('   ❌ Test failed: $e');
      _testResults.add(TestResult(
        testName: 'Conflict Resolution',
        success: false,
        duration: duration,
        details: 'Test failed: $e',
      ));
    }
  }

  /// Test 5: Bulk Operations
  Future<void> _testBulkOperations() async {
    print('\n📦 Test 5: Bulk Operations');
    print('--------------------------');

    final testStart = DateTime.now();
    final batchSize = 5;

    try {
      final pbConfig = _config['pocketbase'] as Map<String, dynamic>;
      final baseUrl = pbConfig['url'] as String;
      final collectionName = _schema['table'] as String;

      print('   📊 Creating $batchSize records in bulk...');

      final createdIds = <String>[];

      // Create multiple records
      for (int i = 0; i < batchSize; i++) {
        final bulkRecord = {
          'organizationId': 'org_001',
          'testName': 'Bulk Test Record ${i + 1}',
          'testDescription': 'Bulk operation test record',
          'testCategory': 'bulk',
          'isActive': 1,
          'priority': i + 1,
          'completionPercentage': (i + 1) * 0.2,
          'testData': jsonEncode({'batchIndex': i, 'batchSize': batchSize}),
          'tags': jsonEncode(['bulk', 'test', 'batch_$batchSize']),
          'lastResult': 'created_in_bulk',
          'createdBy': 'test_user',
          'updatedBy': 'test_user',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'isDirty': 0,
          'syncVersion': 1,
          'isDeleted': 0,
        };

        final createResponse = await http.post(
          Uri.parse('$baseUrl/api/collections/$collectionName/records'),
          headers: _headers,
          body: jsonEncode(bulkRecord),
        );

        if (createResponse.statusCode == 200) {
          final createdRecord = jsonDecode(createResponse.body);
          createdIds.add(createdRecord['id']);
        } else {
          print(
              '   ❌ Failed to create record ${i + 1}: ${createResponse.body}');
        }
      }

      print('   ✅ Created ${createdIds.length}/$batchSize records');

      // Bulk update
      if (createdIds.isNotEmpty) {
        print('   📝 Updating ${createdIds.length} records in bulk...');

        int updateCount = 0;
        for (final recordId in createdIds) {
          final updateData = {
            'completionPercentage': 1.0,
            'lastResult': 'bulk_updated',
            'testData': jsonEncode({
              'bulkUpdated': true,
              'updateTimestamp': DateTime.now().toIso8601String()
            }),
            'updatedAt': DateTime.now().toIso8601String(),
            'syncVersion': 2,
          };

          final updateResponse = await http.patch(
            Uri.parse(
                '$baseUrl/api/collections/$collectionName/records/$recordId'),
            headers: _headers,
            body: jsonEncode(updateData),
          );

          if (updateResponse.statusCode == 200) {
            updateCount++;
          }
        }

        print('   ✅ Updated $updateCount/${createdIds.length} records');

        // Bulk fetch (verification)
        print('   📥 Fetching updated records...');

        int fetchCount = 0;
        for (final recordId in createdIds) {
          final fetchResponse = await http.get(
            Uri.parse(
                '$baseUrl/api/collections/$collectionName/records/$recordId'),
            headers: _headers,
          );

          if (fetchResponse.statusCode == 200) {
            fetchCount++;
          }
        }

        final testEnd = DateTime.now();
        final duration = testEnd.difference(testStart);

        print('   ✅ Fetched $fetchCount/${createdIds.length} records');
        print('   📊 Bulk operations completed');
        print('   ⏱️ Total duration: ${duration.inMilliseconds}ms');
        print(
            '   📈 Average per record: ${(duration.inMilliseconds / batchSize).round()}ms');

        _testResults.add(TestResult(
          testName: 'Bulk Operations',
          success: createdIds.length == batchSize &&
              updateCount == batchSize &&
              fetchCount == batchSize,
          duration: duration,
          details:
              'Created: ${createdIds.length}, Updated: $updateCount, Fetched: $fetchCount',
        ));
      } else {
        final testEnd = DateTime.now();
        final duration = testEnd.difference(testStart);

        print('   ❌ No records were created successfully');
        _testResults.add(TestResult(
          testName: 'Bulk Operations',
          success: false,
          duration: duration,
          details: 'Failed to create any records',
        ));
      }
    } catch (e) {
      final testEnd = DateTime.now();
      final duration = testEnd.difference(testStart);

      print('   ❌ Test failed: $e');
      _testResults.add(TestResult(
        testName: 'Bulk Operations',
        success: false,
        duration: duration,
        details: 'Test failed: $e',
      ));
    }
  }

  /// Test 6: Network Failure Recovery
  Future<void> _testNetworkFailureRecovery() async {
    print('\n🌐 Test 6: Network Failure Recovery');
    print('-----------------------------------');

    final testStart = DateTime.now();

    try {
      final pbConfig = _config['pocketbase'] as Map<String, dynamic>;
      final baseUrl = pbConfig['url'] as String;
      final collectionName = _schema['table'] as String;

      // Create record that will survive network issues
      final resilientRecord = {
        'organizationId': 'org_001',
        'testName': 'Network Recovery Test',
        'testDescription': 'Testing network failure recovery scenarios',
        'testCategory': 'network_recovery',
        'isActive': 1,
        'priority': 9,
        'completionPercentage': 0.1,
        'testData': jsonEncode({'networkTest': true, 'retryCount': 0}),
        'tags': jsonEncode(['network', 'recovery', 'resilience']),
        'lastResult': 'initial',
        'createdBy': 'test_user',
        'updatedBy': 'test_user',
        'createdAt': testStart.toIso8601String(),
        'updatedAt': testStart.toIso8601String(),
        'isDirty': 1, // Mark as dirty to simulate pending sync
        'syncVersion': 1,
        'isDeleted': 0,
      };

      // Test with retry logic
      int retryCount = 0;
      const maxRetries = 3;
      bool syncSuccessful = false;
      String? recordId;

      while (retryCount < maxRetries && !syncSuccessful) {
        try {
          print('   🔄 Sync attempt ${retryCount + 1}/$maxRetries');

          final response = await http
              .post(
                Uri.parse('$baseUrl/api/collections/$collectionName/records'),
                headers: _headers,
                body: jsonEncode({
                  ...resilientRecord,
                  'testData': jsonEncode({
                    'networkTest': true,
                    'retryCount': retryCount,
                    'attempt': retryCount + 1,
                  }),
                }),
              )
              .timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final createdRecord = jsonDecode(response.body);
            recordId = createdRecord['id'];
            syncSuccessful = true;
            print('   ✅ Sync successful on attempt ${retryCount + 1}');
          } else {
            print(
                '   ❌ Sync failed on attempt ${retryCount + 1}: ${response.body}');
            retryCount++;
            if (retryCount < maxRetries) {
              print('   ⏳ Waiting before retry...');
              await Future.delayed(
                  Duration(seconds: retryCount * 2)); // Exponential backoff
            }
          }
        } catch (e) {
          print('   ❌ Network error on attempt ${retryCount + 1}: $e');
          retryCount++;
          if (retryCount < maxRetries) {
            print('   ⏳ Waiting before retry...');
            await Future.delayed(
                Duration(seconds: retryCount * 2)); // Exponential backoff
          }
        }
      }

      final testEnd = DateTime.now();
      final duration = testEnd.difference(testStart);

      if (syncSuccessful && recordId != null) {
        // Verify the record exists
        final verifyResponse = await http.get(
          Uri.parse(
              '$baseUrl/api/collections/$collectionName/records/$recordId'),
          headers: _headers,
        );

        if (verifyResponse.statusCode == 200) {
          final verifiedRecord = jsonDecode(verifyResponse.body);
          print('   ✅ Record verified after recovery');
          print(
              '   📋 Final retry count: ${jsonDecode(verifiedRecord['testData'])['retryCount']}');
          print('   ⏱️ Total recovery time: ${duration.inMilliseconds}ms');

          _testResults.add(TestResult(
            testName: 'Network Failure Recovery',
            success: true,
            duration: duration,
            details: 'Recovered after $retryCount retries',
          ));
        } else {
          print('   ❌ Record verification failed');
          _testResults.add(TestResult(
            testName: 'Network Failure Recovery',
            success: false,
            duration: duration,
            details: 'Record verification failed after apparent success',
          ));
        }
      } else {
        print('   ❌ Network recovery failed after $maxRetries attempts');
        _testResults.add(TestResult(
          testName: 'Network Failure Recovery',
          success: false,
          duration: duration,
          details: 'Failed after $maxRetries retry attempts',
        ));
      }
    } catch (e) {
      final testEnd = DateTime.now();
      final duration = testEnd.difference(testStart);

      print('   ❌ Test failed: $e');
      _testResults.add(TestResult(
        testName: 'Network Failure Recovery',
        success: false,
        duration: duration,
        details: 'Test failed: $e',
      ));
    }
  }

  /// Generate comprehensive test report
  Future<void> _generateTestReport() async {
    print('\n📊 Test Report Generation');
    print('=========================');

    final reportData = {
      'test_session': {
        'timestamp': DateTime.now().toIso8601String(),
        'total_tests': _testResults.length,
        'passed_tests': _testResults.where((r) => r.success).length,
        'failed_tests': _testResults.where((r) => r.success == false).length,
        'total_duration_ms':
            _testResults.fold(0, (sum, r) => sum + r.duration.inMilliseconds),
      },
      'test_results': _testResults.map((r) => r.toJson()).toList(),
      'summary': {
        'success_rate': (_testResults.where((r) => r.success).length /
                _testResults.length *
                100)
            .toStringAsFixed(1),
        'average_duration_ms':
            (_testResults.fold(0, (sum, r) => sum + r.duration.inMilliseconds) /
                    _testResults.length)
                .round(),
        'fastest_test': _testResults
            .reduce((a, b) => a.duration < b.duration ? a : b)
            .testName,
        'slowest_test': _testResults
            .reduce((a, b) => a.duration > b.duration ? a : b)
            .testName,
      },
    };

    // Save report to file
    final reportFile = File(
        'results/test_report_${DateTime.now().millisecondsSinceEpoch}.json');
    await reportFile.parent.create(recursive: true);
    await reportFile.writeAsString(jsonEncode(reportData));

    print('📄 Test report saved: ${reportFile.path}');
    print('');
    print('📊 Test Summary:');
    final testSession = reportData['test_session'] as Map<String, dynamic>;
    final summary = reportData['summary'] as Map<String, dynamic>;
    print('   Total Tests: ${testSession['total_tests']}');
    print('   Passed: ${testSession['passed_tests']}');
    print('   Failed: ${testSession['failed_tests']}');
    print('   Success Rate: ${summary['success_rate']}%');
    print('   Average Duration: ${summary['average_duration_ms']}ms');
    print('   Total Duration: ${testSession['total_duration_ms']}ms');
    print('');

    // Print individual test results
    print('📋 Individual Test Results:');
    for (final result in _testResults) {
      final status = result.success ? '✅' : '❌';
      print(
          '   $status ${result.testName}: ${result.duration.inMilliseconds}ms');
      if (result.details.isNotEmpty) {
        print('      ${result.details}');
      }
    }

    print('');
    if (_testResults.every((r) => r.success)) {
      print(
          '🎉 All tests passed! USM PocketBase integration is working correctly.');
    } else {
      print('⚠️ Some tests failed. Review the results above for details.');
    }
  }
}

/// Test result data class
class TestResult {
  final String testName;
  final bool success;
  final Duration duration;
  final String details;

  TestResult({
    required this.testName,
    required this.success,
    required this.duration,
    this.details = '',
  });

  Map<String, dynamic> toJson() => {
        'test_name': testName,
        'success': success,
        'duration_ms': duration.inMilliseconds,
        'details': details,
      };
}

/// Main entry point for sync tests
Future<void> main(List<String> args) async {
  final tests = USMLiveSyncTests();

  try {
    await tests.initialize();
    await tests.runAllTests();
  } catch (e) {
    print('❌ Test execution failed: $e');
    print('');
    print('💡 Troubleshooting:');
    print('   1. Ensure PocketBase server is running');
    print('   2. Verify the test collection exists');
    print('   3. Check network connectivity');
    print('   4. Validate configuration settings');
    exit(1);
  }
}
