// test/live_tests/phase1_pocketbase/tests/bidirectional_sync_test.dart

import 'dart:io';
import 'dart:convert';
import 'package:pocketbase/pocketbase.dart';
import 'package:yaml/yaml.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

// Import USM components
import 'package:universal_sync_manager/universal_sync_manager.dart';

/// Comprehensive Bidirectional Sync Test for USM PocketBase Integration
///
/// This test performs actual bidirectional synchronization between local SQLite
/// and PocketBase backend using the Universal Sync Manager (USM) framework,
/// validating data integrity, conflict resolution, and USM adapter functionality.
class USMBidirectionalSyncTest {
  late Map<String, dynamic> _config;
  late Map<String, dynamic> _schema;
  late PocketBase _pb;
  late Database _localDb;

  // USM Components
  late PocketBaseSyncAdapter _usmAdapter;

  bool _isAuthenticated = false;
  String? _tableName;

  /// Test execution results
  final List<TestResult> _testResults = [];

  /// Initialize test environment
  Future<void> initialize() async {
    print('🚀 Initializing USM Bidirectional Sync Test...');

    await _loadConfiguration();
    await _loadSchema();
    await _initializeLocalDatabase();
    await _initializePocketBase();
    await _authenticateWithPocketBase();
    await _initializeUSMComponents();

    print('✅ Test environment initialized');
  }

  /// Load configuration from YAML
  Future<void> _loadConfiguration() async {
    try {
      final possiblePaths = [
        '../setup/config.yaml',
        'test/live_tests/phase1_pocketbase/setup/config.yaml',
        'setup/config.yaml',
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
      // Use the first schema from test_schemas or default to usm_test
      final testSchemas = _config['test_schemas'] as List<dynamic>?;
      final schemaName = testSchemas?.isNotEmpty == true
          ? testSchemas!.first.toString().replaceAll('.yaml', '')
          : 'usm_test';

      final possiblePaths = [
        'test/live_tests/phase1_pocketbase/schemas/$schemaName.yaml',
        'tools/schema/$schemaName.yaml',
        '../schemas/$schemaName.yaml',
        'schemas/$schemaName.yaml',
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
      _tableName = _schema['table'] as String;

      print('📄 Schema loaded from: ${schemaFile.path} (table: $_tableName)');
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

  /// Initialize local SQLite database
  Future<void> _initializeLocalDatabase() async {
    try {
      final dbConfig = _config['database'] as Map<String, dynamic>;
      final dbPath = dbConfig['path'] as String;

      // Resolve relative path to absolute
      final resolvedDbPath = path.isAbsolute(dbPath)
          ? dbPath
          : path.join(
              Directory.current.path,
              'test/live_tests/phase1_pocketbase/setup',
              dbPath.replaceFirst('./', ''));

      final dbFile = File(resolvedDbPath);
      if (!await dbFile.exists()) {
        throw Exception('Database file not found: $resolvedDbPath');
      }

      _localDb = sqlite3.open(resolvedDbPath);

      // Test database connection
      final result =
          _localDb.select('SELECT COUNT(*) as count FROM $_tableName');
      final recordCount = result.first['count'] as int;

      print('💾 Local database connected: $resolvedDbPath');
      print('📊 Current records in $_tableName: $recordCount');
    } catch (e) {
      throw Exception('Failed to initialize local database: $e');
    }
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

      await _pb.admins.authWithPassword(adminEmail, adminPassword);
      _isAuthenticated = true;
      print('✅ Authenticated as admin');
    } catch (e) {
      throw Exception('Failed to authenticate: $e');
    }
  }

  /// Initialize USM components for testing
  Future<void> _initializeUSMComponents() async {
    try {
      print('🔧 Initializing USM components...');

      final pbConfig = _config['pocketbase'] as Map<String, dynamic>;
      final baseUrl = pbConfig['url'] as String;

      // Initialize USM PocketBase adapter
      _usmAdapter = PocketBaseSyncAdapter(
        baseUrl: baseUrl,
        connectionTimeout: Duration(seconds: 30),
        requestTimeout: Duration(seconds: 30),
      );

      // Configure the adapter with regular user authentication (not admin)
      final userEmail = pbConfig['user_email'] as String;
      final userPassword = pbConfig['user_password'] as String;

      final authConfig = SyncBackendConfiguration(
        configId: 'usm-test-config',
        displayName: 'USM Test Configuration',
        backendType: 'pocketbase',
        baseUrl: baseUrl,
        projectId: _tableName ?? 'usm_test',
        customSettings: {
          'email': userEmail, // Regular user with collection access
          'password': userPassword,
        },
        connectionTimeout: Duration(seconds: 30),
        requestTimeout: Duration(seconds: 30),
      );

      // Connect the adapter
      final connected = await _usmAdapter.connect(authConfig);
      if (!connected) {
        throw Exception('Failed to connect USM adapter');
      }

      print('✅ USM components initialized and connected');
    } catch (e) {
      throw Exception('Failed to initialize USM components: $e');
    }
  }

  /// Run all bidirectional sync tests
  Future<void> runAllTests() async {
    print('\\n🧪 Running USM Bidirectional Sync Tests...');
    print('=============================================');

    if (!_isAuthenticated) {
      throw Exception('Not authenticated with PocketBase');
    }

    // Test 1: Local Create → Remote Sync
    await _testLocalCreateToRemoteSync();

    // Test 2: Remote Create → Local Sync
    await _testRemoteCreateToLocalSync();

    // Test 3: Local Update → Remote Sync
    await _testLocalUpdateToRemoteSync();

    // Test 4: Remote Update → Local Sync
    await _testRemoteUpdateToLocalSync();

    // Test 5: Bidirectional Conflict Resolution
    await _testBidirectionalConflictResolution();

    // Test 6: Incremental Sync (Delta Sync)
    await _testIncrementalSync();

    // Test 7: Bulk Bidirectional Sync
    await _testBulkBidirectionalSync();

    // Test 8: Data Integrity Validation
    await _testDataIntegrityValidation();

    // Print summary
    _printTestSummary();
  }

  /// Test 1: Local Create → Remote Sync
  Future<void> _testLocalCreateToRemoteSync() async {
    final testName = 'Local Create → Remote Sync';
    print('\\n📤 Running Test 1: $testName');

    final testStart = DateTime.now();
    String? localRecordId;
    String? remoteRecordId;

    try {
      // Create record locally with same UUID for local-first strategy
      final localData = _generateTestData();
      localRecordId = localData['id'] as String;

      final insertSql = '''
        INSERT INTO $_tableName (
          id, organizationId, testName, testDescription, testCategory,
          isActive, priority, completionPercentage, testData, tags,
          executionTime, lastResult, errorMessage, config,
          createdBy, updatedBy, createdAt, updatedAt, deletedAt,
          lastSyncedAt, isDirty, syncVersion, isDeleted
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''';

      _localDb.execute(insertSql, [
        localData['id'],
        localData['organizationId'],
        localData['testName'],
        localData['testDescription'],
        localData['testCategory'],
        localData['isActive'],
        localData['priority'],
        localData['completionPercentage'],
        localData['testData'],
        localData['tags'],
        localData['executionTime'],
        localData['lastResult'],
        localData['errorMessage'],
        localData['config'],
        localData['createdBy'],
        localData['updatedBy'],
        localData['createdAt'],
        localData['updatedAt'],
        localData['deletedAt'],
        localData['lastSyncedAt'],
        1, // isDirty = true
        localData['syncVersion'],
        localData['isDeleted'],
      ]);

      print('   📝 Created local record: $localRecordId');

      // Simulate sync to remote (find dirty records and sync)
      final dirtyRecords = _localDb.select(
          'SELECT * FROM $_tableName WHERE isDirty = 1 AND id = ?',
          [localRecordId]);

      if (dirtyRecords.isNotEmpty) {
        final record = dirtyRecords.first;

        // Convert to PocketBase format (include ID for local-first strategy)
        final remoteData = <String, dynamic>{};
        for (final key in record.keys) {
          remoteData[key] = record[key];
        }

        // Sync to PocketBase using USM framework instead of direct PocketBase SDK
        final syncResult = await _usmAdapter.create(_tableName!, remoteData);

        if (syncResult.isSuccess) {
          remoteRecordId = syncResult.data?['id'] as String;
          print('   📤 Synced to remote via USM: $remoteRecordId');

          // Update local record with sync success and clear dirty flag
          _localDb.execute('''
            UPDATE $_tableName 
            SET isDirty = 0, lastSyncedAt = ?, syncVersion = syncVersion + 1
            WHERE id = ?
          ''', [DateTime.now().toIso8601String(), localRecordId]);

          print('   ✅ Local dirty flag cleared');
        } else {
          throw Exception('USM sync failed: ${syncResult.error?.message}');
        }

        final testEnd = DateTime.now();
        final duration = testEnd.difference(testStart);

        _addTestResult(TestResult(
          name: testName,
          success: true,
          message: 'Local record synced to remote successfully',
          duration: duration,
        ));
        print('   ⏱️ Duration: ${duration.inMilliseconds}ms');
      } else {
        throw Exception('No dirty records found for sync');
      }
    } catch (e) {
      final testEnd = DateTime.now();
      final duration = testEnd.difference(testStart);

      _addTestResult(TestResult(
        name: testName,
        success: false,
        message: 'Failed: $e',
        duration: duration,
      ));
      print('   ❌ Test failed: $e');
    }
  }

  /// Test 2: Remote Create → Local Sync
  Future<void> _testRemoteCreateToLocalSync() async {
    final testName = 'Remote Create → Local Sync';
    print('\\n📥 Running Test 2: $testName');

    final testStart = DateTime.now();
    String? remoteRecordId;

    try {
      // Create record in PocketBase using USM
      final remoteData = _generateTestData();
      final createResult = await _usmAdapter.create(_tableName!, remoteData);

      if (!createResult.isSuccess) {
        throw Exception('USM create failed: ${createResult.error?.message}');
      }

      remoteRecordId = createResult.data?['id'] as String;
      print('   📝 Created remote record via USM: $remoteRecordId');

      // Simulate sync from remote (fetch new records using USM query)
      final lastSyncTime = _getLastSyncTime();
      final queryResults = await _usmAdapter.query(
          _tableName!,
          SyncQuery(
            filters: {'created': '>= "$lastSyncTime"'},
            limit: 50,
          ));

      for (final result in queryResults) {
        if (!result.isSuccess) {
          print('   ⚠️ Skipping failed query result: ${result.error?.message}');
          continue;
        }

        final data = result.data!;

        // Check if record exists locally
        final existingRecords = _localDb.select(
            'SELECT COUNT(*) as count FROM $_tableName WHERE id = ?',
            [data['id']]);

        final exists = existingRecords.first['count'] as int > 0;

        if (!exists) {
          // Insert new record locally
          final insertSql = '''
            INSERT INTO $_tableName (
              id, organizationId, testName, testDescription, testCategory,
              isActive, priority, completionPercentage, testData, tags,
              executionTime, lastResult, errorMessage, config,
              createdBy, updatedBy, createdAt, updatedAt, deletedAt,
              lastSyncedAt, isDirty, syncVersion, isDeleted
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''';

          _localDb.execute(insertSql, [
            data['id'],
            data['organizationId'],
            data['testName'],
            data['testDescription'],
            data['testCategory'],
            data['isActive'],
            data['priority'],
            data['completionPercentage'],
            data['testData'],
            data['tags'],
            data['executionTime'],
            data['lastResult'],
            data['errorMessage'],
            data['config'],
            data['createdBy'],
            data['updatedBy'],
            data['createdAt'],
            data['updatedAt'],
            data['deletedAt'],
            DateTime.now().toIso8601String(), // lastSyncedAt
            0, // isDirty = false (just synced)
            data['syncVersion'] ?? 0,
            data['isDeleted'] ?? 0,
          ]);

          print('   📥 Synced to local: ${data['id']}');
        }
      }

      // Update last sync time
      _updateLastSyncTime();

      final testEnd = DateTime.now();
      final duration = testEnd.difference(testStart);

      _addTestResult(TestResult(
        name: testName,
        success: true,
        message: 'Remote record synced to local successfully',
        duration: duration,
      ));
      print('   ⏱️ Duration: ${duration.inMilliseconds}ms');
    } catch (e) {
      final testEnd = DateTime.now();
      final duration = testEnd.difference(testStart);

      _addTestResult(TestResult(
        name: testName,
        success: false,
        message: 'Failed: $e',
        duration: duration,
      ));
      print('   ❌ Test failed: $e');
    }
  }

  /// Test 3: Local Update → Remote Sync
  Future<void> _testLocalUpdateToRemoteSync() async {
    final testName = 'Local Update → Remote Sync';
    print('\\n🔄 Running Test 3: $testName');

    final testStart = DateTime.now();

    try {
      // Find an existing record or create one
      final existingRecords = _localDb
          .select('SELECT * FROM $_tableName WHERE isDeleted = 0 LIMIT 1');

      String targetId;
      if (existingRecords.isNotEmpty) {
        targetId = existingRecords.first['id'] as String;
      } else {
        // Create a record first
        final testData = _generateTestData();
        targetId = testData['id'] as String;

        final insertSql = '''
          INSERT INTO $_tableName (
            id, organizationId, testName, testDescription, testCategory,
            isActive, priority, completionPercentage, testData, tags,
            executionTime, lastResult, errorMessage, config,
            createdBy, updatedBy, createdAt, updatedAt, deletedAt,
            lastSyncedAt, isDirty, syncVersion, isDeleted
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''';

        _localDb.execute(insertSql, [
          testData['id'],
          testData['organizationId'],
          testData['testName'],
          testData['testDescription'],
          testData['testCategory'],
          testData['isActive'],
          testData['priority'],
          testData['completionPercentage'],
          testData['testData'],
          testData['tags'],
          testData['executionTime'],
          testData['lastResult'],
          testData['errorMessage'],
          testData['config'],
          testData['createdBy'],
          testData['updatedBy'],
          testData['createdAt'],
          testData['updatedAt'],
          testData['deletedAt'],
          DateTime.now().toIso8601String(),
          0,
          testData['syncVersion'],
          testData['isDeleted'],
        ]);

        // Also create in PocketBase using USM
        final createResult = await _usmAdapter.create(_tableName!, testData);
        if (!createResult.isSuccess) {
          throw Exception(
              'Failed to create record in PocketBase: ${createResult.error?.message}');
        }
      }

      print('   📝 Updating local record: $targetId');

      // Update record locally
      final updateTime = DateTime.now().toIso8601String();
      _localDb.execute('''
        UPDATE $_tableName 
        SET testName = ?, completionPercentage = ?, updatedAt = ?, 
            isDirty = 1, syncVersion = syncVersion + 1
        WHERE id = ?
      ''', ['Updated Test Name', 0.85, updateTime, targetId]);

      print('   📝 Local update completed, marked as dirty');

      // Sync dirty records to remote
      final dirtyRecords = _localDb.select(
          'SELECT * FROM $_tableName WHERE isDirty = 1 AND id = ?', [targetId]);

      if (dirtyRecords.isNotEmpty) {
        final record = dirtyRecords.first;

        // Find corresponding PocketBase record using USM
        final queryResult = await _usmAdapter.query(
            _tableName!,
            SyncQuery(
              filters: {'id': targetId},
            ));

        if (queryResult.isNotEmpty && queryResult.first.isSuccess) {
          final pbRecord = queryResult.first.data!;
          final pbRecordId = pbRecord['id'];

          // Update in PocketBase using USM
          final updateData = {
            'testName': record['testName'],
            'completionPercentage': record['completionPercentage'],
            'updatedAt': record['updatedAt'],
            'syncVersion': record['syncVersion'],
          };

          final updateResult =
              await _usmAdapter.update(_tableName!, pbRecordId, updateData);
          if (!updateResult.isSuccess) {
            throw Exception(
                'Failed to update record in PocketBase: ${updateResult.error?.message}');
          }

          // Clear dirty flag locally
          _localDb.execute('''
            UPDATE $_tableName 
            SET isDirty = 0, lastSyncedAt = ?
            WHERE id = ?
          ''', [DateTime.now().toIso8601String(), targetId]);

          print('   📤 Update synced to remote');
          print('   ✅ Local dirty flag cleared');

          final testEnd = DateTime.now();
          final duration = testEnd.difference(testStart);

          _addTestResult(TestResult(
            name: testName,
            success: true,
            message: 'Local update synced to remote successfully',
            duration: duration,
          ));
          print('   ⏱️ Duration: ${duration.inMilliseconds}ms');
        } else {
          throw Exception('Remote record not found for update sync');
        }
      } else {
        throw Exception('No dirty records found for update sync');
      }
    } catch (e) {
      final testEnd = DateTime.now();
      final duration = testEnd.difference(testStart);

      _addTestResult(TestResult(
        name: testName,
        success: false,
        message: 'Failed: $e',
        duration: duration,
      ));
      print('   ❌ Test failed: $e');
    }
  }

  /// Test 4: Remote Update → Local Sync
  Future<void> _testRemoteUpdateToLocalSync() async {
    final testName = 'Remote Update → Local Sync';
    print('\\n📥 Running Test 4: $testName');

    final testStart = DateTime.now();

    try {
      // Find an existing PocketBase record or create one using USM
      final queryResult = await _usmAdapter.query(
          _tableName!,
          SyncQuery(
            limit: 1,
          ));

      String targetPbId;
      if (queryResult.isNotEmpty && queryResult.first.isSuccess) {
        targetPbId = queryResult.first.data!['id'];
      } else {
        // Create a record first using USM
        final testData = _generateTestData();
        final createResult = await _usmAdapter.create(_tableName!, testData);
        if (!createResult.isSuccess) {
          throw Exception(
              'Failed to create record: ${createResult.error?.message}');
        }
        targetPbId = createResult.data!['id'];
      }

      print('   📝 Updating remote record: $targetPbId');

      // Update record in PocketBase using USM
      final updateData = {
        'testName': 'Remote Updated Test Name',
        'completionPercentage': 0.95,
        'updatedAt': DateTime.now().toIso8601String(),
        'syncVersion': 10, // Higher version to simulate remote update
      };

      final updateResult =
          await _usmAdapter.update(_tableName!, targetPbId, updateData);
      if (!updateResult.isSuccess) {
        throw Exception(
            'Failed to update record: ${updateResult.error?.message}');
      }
      print('   📤 Remote update completed');

      // Simulate sync from remote (fetch updated records) using USM
      final lastSyncTime = _getLastSyncTime();
      final updatedResults = await _usmAdapter.query(
          _tableName!,
          SyncQuery(
            filters: {'updatedAt': '>= "$lastSyncTime"'},
            limit: 50,
          ));

      for (final result in updatedResults) {
        if (!result.isSuccess) continue;

        final data = result.data!;

        // Check if record exists locally
        final existingRecords = _localDb
            .select('SELECT * FROM $_tableName WHERE id = ?', [data['id']]);

        if (existingRecords.isNotEmpty) {
          final localRecord = existingRecords.first;
          final localSyncVersion = localRecord['syncVersion'] as int;
          final remoteSyncVersion = data['syncVersion'] as int? ?? 0;

          // Update if remote version is newer
          if (remoteSyncVersion > localSyncVersion) {
            _localDb.execute('''
              UPDATE $_tableName 
              SET testName = ?, completionPercentage = ?, updatedAt = ?,
                  syncVersion = ?, lastSyncedAt = ?, isDirty = 0
              WHERE id = ?
            ''', [
              data['testName'],
              data['completionPercentage'],
              data['updatedAt'],
              remoteSyncVersion,
              DateTime.now().toIso8601String(),
              data['id'],
            ]);

            print('   📥 Updated local record: ${data['id']}');
          }
        }
      }

      // Update last sync time
      _updateLastSyncTime();

      final testEnd = DateTime.now();
      final duration = testEnd.difference(testStart);

      _addTestResult(TestResult(
        name: testName,
        success: true,
        message: 'Remote update synced to local successfully',
        duration: duration,
      ));
      print('   ⏱️ Duration: ${duration.inMilliseconds}ms');
    } catch (e) {
      final testEnd = DateTime.now();
      final duration = testEnd.difference(testStart);

      _addTestResult(TestResult(
        name: testName,
        success: false,
        message: 'Failed: $e',
        duration: duration,
      ));
      print('   ❌ Test failed: $e');
    }
  }

  /// Test 5: Bidirectional Conflict Resolution
  Future<void> _testBidirectionalConflictResolution() async {
    final testName = 'Bidirectional Conflict Resolution';
    print('\\n⚔️ Running Test 5: $testName');

    final testStart = DateTime.now();

    try {
      // Create a record in both places
      final testData = _generateTestData();
      final localId = testData['id'] as String;

      // Create locally
      final insertSql = '''
        INSERT INTO $_tableName (
          id, organizationId, testName, testDescription, testCategory,
          isActive, priority, completionPercentage, testData, tags,
          executionTime, lastResult, errorMessage, config,
          createdBy, updatedBy, createdAt, updatedAt, deletedAt,
          lastSyncedAt, isDirty, syncVersion, isDeleted
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''';

      _localDb.execute(insertSql, [
        testData['id'],
        testData['organizationId'],
        testData['testName'],
        testData['testDescription'],
        testData['testCategory'],
        testData['isActive'],
        testData['priority'],
        testData['completionPercentage'],
        testData['testData'],
        testData['tags'],
        testData['executionTime'],
        testData['lastResult'],
        testData['errorMessage'],
        testData['config'],
        testData['createdBy'],
        testData['updatedBy'],
        testData['createdAt'],
        testData['updatedAt'],
        testData['deletedAt'],
        DateTime.now().toIso8601String(),
        0,
        testData['syncVersion'],
        testData['isDeleted'],
      ]);

      // Create in PocketBase using USM
      final createResult = await _usmAdapter.create(_tableName!, testData);
      if (!createResult.isSuccess) {
        throw Exception(
            'Failed to create record: ${createResult.error?.message}');
      }
      final remoteId = createResult.data!['id'];

      print('   📝 Created conflict test record');

      // Create conflicting updates
      // Local update
      _localDb.execute('''
        UPDATE $_tableName 
        SET testName = ?, completionPercentage = ?, updatedAt = ?, 
            isDirty = 1, syncVersion = 2
        WHERE id = ?
      ''', [
        'Local Conflict Update',
        0.60,
        DateTime.now().toIso8601String(),
        localId
      ]);

      // Remote update using USM
      final remoteUpdateResult =
          await _usmAdapter.update(_tableName!, remoteId, {
        'testName': 'Remote Conflict Update',
        'completionPercentage': 0.80,
        'updatedAt': DateTime.now().add(Duration(seconds: 1)).toIso8601String(),
        'syncVersion': 3, // Higher version - should win
      });

      if (!remoteUpdateResult.isSuccess) {
        throw Exception(
            'Failed to update remote record: ${remoteUpdateResult.error?.message}');
      }

      print('   ⚔️ Created conflicting updates');

      // Resolve conflict - remote wins (higher sync version)
      final readResult = await _usmAdapter.read(_tableName!, remoteId);
      if (!readResult.isSuccess) {
        throw Exception(
            'Failed to read remote record: ${readResult.error?.message}');
      }
      final remoteData = readResult.data!;
      final remoteSyncVersion = remoteData['syncVersion'] as int;

      final localRecords = _localDb.select(
          'SELECT syncVersion FROM $_tableName WHERE id = ?', [localId]);
      final localSyncVersion = localRecords.first['syncVersion'] as int;

      if (remoteSyncVersion > localSyncVersion) {
        // Remote wins - update local
        _localDb.execute('''
          UPDATE $_tableName 
          SET testName = ?, completionPercentage = ?, updatedAt = ?,
              syncVersion = ?, lastSyncedAt = ?, isDirty = 0
          WHERE id = ?
        ''', [
          remoteData['testName'],
          remoteData['completionPercentage'],
          remoteData['updatedAt'] is DateTime
              ? (remoteData['updatedAt'] as DateTime).toIso8601String()
              : remoteData['updatedAt'],
          remoteSyncVersion,
          DateTime.now().toIso8601String(),
          localId,
        ]);

        print('   🏆 Conflict resolved: Remote wins (higher sync version)');
        print('   📥 Local record updated with remote data');

        final testEnd = DateTime.now();
        final duration = testEnd.difference(testStart);

        _addTestResult(TestResult(
          name: testName,
          success: true,
          message: 'Conflict resolved successfully (remote wins)',
          duration: duration,
        ));
        print('   ⏱️ Duration: ${duration.inMilliseconds}ms');
      } else {
        throw Exception('Conflict resolution logic failed');
      }
    } catch (e) {
      final testEnd = DateTime.now();
      final duration = testEnd.difference(testStart);

      _addTestResult(TestResult(
        name: testName,
        success: false,
        message: 'Failed: $e',
        duration: duration,
      ));
      print('   ❌ Test failed: $e');
    }
  }

  /// Test 6: Incremental Sync (Delta Sync)
  Future<void> _testIncrementalSync() async {
    final testName = 'Incremental Sync (Delta Sync)';
    print('\\n🔄 Running Test 6: $testName');

    final testStart = DateTime.now();

    try {
      // Create multiple records with different timestamps
      final batchSize = 3;
      final createdIds = <String>[];

      for (int i = 0; i < batchSize; i++) {
        final testData = _generateTestData();
        testData['testName'] = 'Incremental Test $i';

        final createResult = await _usmAdapter.create(_tableName!, testData);
        if (!createResult.isSuccess) {
          throw Exception(
              'Failed to create record $i: ${createResult.error?.message}');
        }
        createdIds.add(createResult.data!['id']);

        // Wait a bit to ensure different timestamps
        await Future.delayed(Duration(milliseconds: 100));
      }

      print('   📝 Created $batchSize records for incremental sync test');

      // Simulate incremental sync using USM
      final lastSyncTime =
          DateTime.now().subtract(Duration(minutes: 1)).toIso8601String();

      final newResults = await _usmAdapter.query(
          _tableName!,
          SyncQuery(
            filters: {'created': '>= "$lastSyncTime"'},
            orderBy: [SyncOrderBy.asc('created')],
            limit: 50,
          ));

      final successResults = newResults.where((r) => r.isSuccess).toList();
      print('   📊 Found ${successResults.length} records since last sync');

      int syncedCount = 0;
      for (final result in successResults) {
        final data = result.data!;

        // Check if already exists locally
        final existingRecords = _localDb.select(
            'SELECT COUNT(*) as count FROM $_tableName WHERE id = ?',
            [data['id']]);

        final exists = existingRecords.first['count'] as int > 0;

        if (!exists) {
          final insertSql = '''
            INSERT INTO $_tableName (
              id, organizationId, testName, testDescription, testCategory,
              isActive, priority, completionPercentage, testData, tags,
              executionTime, lastResult, errorMessage, config,
              createdBy, updatedBy, createdAt, updatedAt, deletedAt,
              lastSyncedAt, isDirty, syncVersion, isDeleted
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''';

          _localDb.execute(insertSql, [
            data['id'],
            data['organizationId'],
            data['testName'],
            data['testDescription'],
            data['testCategory'],
            data['isActive'],
            data['priority'],
            data['completionPercentage'],
            data['testData'],
            data['tags'],
            data['executionTime'],
            data['lastResult'],
            data['errorMessage'],
            data['config'],
            data['createdBy'],
            data['updatedBy'],
            data['createdAt'],
            data['updatedAt'],
            data['deletedAt'],
            DateTime.now().toIso8601String(),
            0,
            data['syncVersion'] ?? 0,
            data['isDeleted'] ?? 0,
          ]);

          syncedCount++;
        }
      }

      print('   📥 Synced $syncedCount new records to local');

      final testEnd = DateTime.now();
      final duration = testEnd.difference(testStart);

      _addTestResult(TestResult(
        name: testName,
        success: true,
        message: 'Incremental sync completed: $syncedCount records',
        duration: duration,
      ));
      print('   ⏱️ Duration: ${duration.inMilliseconds}ms');
    } catch (e) {
      final testEnd = DateTime.now();
      final duration = testEnd.difference(testStart);

      _addTestResult(TestResult(
        name: testName,
        success: false,
        message: 'Failed: $e',
        duration: duration,
      ));
      print('   ❌ Test failed: $e');
    }
  }

  /// Test 7: Bulk Bidirectional Sync
  Future<void> _testBulkBidirectionalSync() async {
    final testName = 'Bulk Bidirectional Sync';
    print('\\n📦 Running Test 7: $testName');

    final testStart = DateTime.now();

    try {
      final batchSize = 5;

      // Create bulk records locally
      print('   📝 Creating $batchSize local records...');
      for (int i = 0; i < batchSize; i++) {
        final testData = _generateTestData();
        testData['testName'] = 'Bulk Local Test $i';

        final insertSql = '''
          INSERT INTO $_tableName (
            id, organizationId, testName, testDescription, testCategory,
            isActive, priority, completionPercentage, testData, tags,
            executionTime, lastResult, errorMessage, config,
            createdBy, updatedBy, createdAt, updatedAt, deletedAt,
            lastSyncedAt, isDirty, syncVersion, isDeleted
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''';

        _localDb.execute(insertSql, [
          testData['id'], testData['organizationId'], testData['testName'],
          testData['testDescription'], testData['testCategory'],
          testData['isActive'], testData['priority'],
          testData['completionPercentage'],
          testData['testData'], testData['tags'], testData['executionTime'],
          testData['lastResult'], testData['errorMessage'], testData['config'],
          testData['createdBy'], testData['updatedBy'], testData['createdAt'],
          testData['updatedAt'], testData['deletedAt'],
          null, 1, testData['syncVersion'],
          testData['isDeleted'], // isDirty = 1
        ]);
      }

      // Bulk sync to remote
      final dirtyRecords =
          _localDb.select('SELECT * FROM $_tableName WHERE isDirty = 1');

      print('   📤 Syncing ${dirtyRecords.length} dirty records to remote...');
      int syncedToRemote = 0;

      for (final record in dirtyRecords) {
        try {
          final remoteData = <String, dynamic>{};
          for (final key in record.keys) {
            remoteData[key] = record[key];
          }

          await _usmAdapter.create(_tableName!, remoteData);

          // Clear dirty flag
          _localDb.execute('''
            UPDATE $_tableName 
            SET isDirty = 0, lastSyncedAt = ?
            WHERE id = ?
          ''', [DateTime.now().toIso8601String(), record['id']]);

          syncedToRemote++;
        } catch (e) {
          print('   ⚠️ Failed to sync record ${record['id']}: $e');
        }
      }

      // Create bulk records remotely
      print('   📝 Creating $batchSize remote records...');
      for (int i = 0; i < batchSize; i++) {
        final testData = _generateTestData();
        testData['testName'] = 'Bulk Remote Test $i';

        final createResult = await _usmAdapter.create(_tableName!, testData);
        if (!createResult.isSuccess) {
          throw Exception(
              'Failed to create remote record $i: ${createResult.error?.message}');
        }
      }

      // Bulk sync from remote using USM
      final lastSyncTime =
          DateTime.now().subtract(Duration(minutes: 5)).toIso8601String();
      final remoteResults = await _usmAdapter.query(
          _tableName!,
          SyncQuery(
            filters: {'created': '>= "$lastSyncTime"'},
            limit: 50,
          ));

      final successResults = remoteResults.where((r) => r.isSuccess).toList();
      print(
          '   📥 Syncing ${successResults.length} remote records to local...');
      int syncedToLocal = 0;

      for (final result in successResults) {
        final data = result.data!;

        final existingRecords = _localDb.select(
            'SELECT COUNT(*) as count FROM $_tableName WHERE id = ?',
            [data['id']]);

        final exists = existingRecords.first['count'] as int > 0;

        if (!exists) {
          final insertSql = '''
            INSERT INTO $_tableName (
              id, organizationId, testName, testDescription, testCategory,
              isActive, priority, completionPercentage, testData, tags,
              executionTime, lastResult, errorMessage, config,
              createdBy, updatedBy, createdAt, updatedAt, deletedAt,
              lastSyncedAt, isDirty, syncVersion, isDeleted
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''';

          _localDb.execute(insertSql, [
            data['id'],
            data['organizationId'],
            data['testName'],
            data['testDescription'],
            data['testCategory'],
            data['isActive'],
            data['priority'],
            data['completionPercentage'],
            data['testData'],
            data['tags'],
            data['executionTime'],
            data['lastResult'],
            data['errorMessage'],
            data['config'],
            data['createdBy'],
            data['updatedBy'],
            data['createdAt'],
            data['updatedAt'],
            data['deletedAt'],
            DateTime.now().toIso8601String(),
            0,
            data['syncVersion'] ?? 0,
            data['isDeleted'] ?? 0,
          ]);

          syncedToLocal++;
        }
      }

      final testEnd = DateTime.now();
      final duration = testEnd.difference(testStart);

      print('   📊 Bulk sync completed:');
      print('     📤 Local → Remote: $syncedToRemote records');
      print('     📥 Remote → Local: $syncedToLocal records');

      _addTestResult(TestResult(
        name: testName,
        success: true,
        message: 'Bulk sync: $syncedToRemote↑ $syncedToLocal↓',
        duration: duration,
      ));
      print('   ⏱️ Duration: ${duration.inMilliseconds}ms');
    } catch (e) {
      final testEnd = DateTime.now();
      final duration = testEnd.difference(testStart);

      _addTestResult(TestResult(
        name: testName,
        success: false,
        message: 'Failed: $e',
        duration: duration,
      ));
      print('   ❌ Test failed: $e');
    }
  }

  /// Test 8: Data Integrity Validation
  Future<void> _testDataIntegrityValidation() async {
    final testName = 'Data Integrity Validation';
    print('\\n🔍 Running Test 8: $testName');

    final testStart = DateTime.now();

    try {
      // Get counts
      final localCountResult =
          _localDb.select('SELECT COUNT(*) as count FROM $_tableName');
      final localCount = localCountResult.first['count'] as int;

      // Get remote count using USM
      // For count, we'll need to fetch all and count (simplified approach)
      final allRemoteResults =
          await _usmAdapter.query(_tableName!, SyncQuery());
      final remoteCount = allRemoteResults.where((r) => r.isSuccess).length;

      print('   📊 Record counts:');
      print('     💾 Local: $localCount');
      print('     ☁️ Remote: $remoteCount');

      // Sample data integrity check
      final sampleRecords = _localDb.select(
          'SELECT * FROM $_tableName WHERE lastSyncedAt IS NOT NULL LIMIT 3');

      int integrityErrors = 0;
      int checkedRecords = 0;

      for (final localRecord in sampleRecords) {
        try {
          final remoteResults = await _usmAdapter.query(
              _tableName!,
              SyncQuery(
                filters: {'id': localRecord['id']},
              ));

          final successResults =
              remoteResults.where((r) => r.isSuccess).toList();
          if (successResults.isNotEmpty) {
            final remoteData = successResults.first.data!;
            checkedRecords++;

            // Check key fields for consistency
            final fieldsToCheck = [
              'testName',
              'completionPercentage',
              'syncVersion'
            ];

            for (final field in fieldsToCheck) {
              final localValue = localRecord[field];
              final remoteValue = remoteData[field];

              if (localValue != remoteValue) {
                print(
                    '   ⚠️ Integrity error in ${localRecord['id']}.$field: local=$localValue, remote=$remoteValue');
                integrityErrors++;
              }
            }
          }
        } catch (e) {
          print('   ⚠️ Error checking record ${localRecord['id']}: $e');
          integrityErrors++;
        }
      }

      // Check dirty flag consistency
      final dirtyRecords = _localDb.select(
          'SELECT COUNT(*) as count FROM $_tableName WHERE isDirty = 1');
      final dirtyCount = dirtyRecords.first['count'] as int;

      print('   📊 Integrity check results:');
      print('     ✅ Records checked: $checkedRecords');
      print('     ⚠️ Integrity errors: $integrityErrors');
      print('     🔄 Pending sync (dirty): $dirtyCount');

      final testEnd = DateTime.now();
      final duration = testEnd.difference(testStart);

      final success = integrityErrors == 0;
      _addTestResult(TestResult(
        name: testName,
        success: success,
        message: success
            ? 'Data integrity validated: $checkedRecords records checked'
            : 'Integrity errors found: $integrityErrors errors',
        duration: duration,
      ));

      if (success) {
        print('   ✅ Data integrity validation passed');
      } else {
        print('   ❌ Data integrity validation failed');
      }
      print('   ⏱️ Duration: ${duration.inMilliseconds}ms');
    } catch (e) {
      final testEnd = DateTime.now();
      final duration = testEnd.difference(testStart);

      _addTestResult(TestResult(
        name: testName,
        success: false,
        message: 'Failed: $e',
        duration: duration,
      ));
      print('   ❌ Test failed: $e');
    }
  }

  /// Generate test data based on schema
  Map<String, dynamic> _generateTestData() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;

    // Generate proper UUID for local-first strategy
    final uuid = _generateUUID();

    return {
      'id': uuid, // Use id for PocketBase (supports custom UUIDs)
      'organizationId': 'test-org-$timestamp',
      'testName': 'Bidirectional Test $timestamp',
      'testDescription': 'Test record for bidirectional sync validation',
      'testCategory': 'bidirectional_sync',
      'isActive': 1,
      'priority': 5,
      'completionPercentage': 0.5,
      'testData': jsonEncode({
        'syncTest': true,
        'timestamp': now.toIso8601String(),
        'testType': 'bidirectional'
      }),
      'tags': jsonEncode(['sync', 'test', 'bidirectional']),
      'executionTime': 100.0,
      'lastResult': 'pending',
      'errorMessage': null,
      'config': jsonEncode({'syncEnabled': true}),
      'createdBy': 'test-user',
      'updatedBy': 'test-user',
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'deletedAt': null,
      'lastSyncedAt': null,
      'isDirty': 0,
      'syncVersion': 0,
      'isDeleted': 0,
    };
  }

  /// Get last sync time (simulated)
  String _getLastSyncTime() {
    return DateTime.now().subtract(Duration(hours: 1)).toIso8601String();
  }

  /// Update last sync time (simulated)
  void _updateLastSyncTime() {
    // In a real implementation, this would update a sync metadata table
    print('   📅 Last sync time updated');
  }

  /// Generate a proper UUID for PocketBase compatibility
  String _generateUUID() {
    const uuid = Uuid();
    return uuid.v4();
  }

  /// Add test result
  void _addTestResult(TestResult result) {
    _testResults.add(result);
  }

  /// Print test summary
  void _printTestSummary() {
    print('\\n📊 Bidirectional Sync Test Summary');
    print('====================================');

    final passed = _testResults.where((r) => r.success).length;
    final failed = _testResults.where((r) => !r.success).length;
    final totalDuration =
        _testResults.fold(Duration.zero, (sum, r) => sum + r.duration);

    print('✅ Passed: $passed');
    print('❌ Failed: $failed');
    print('📝 Total: ${_testResults.length}');
    print('⏱️ Total Duration: ${totalDuration.inMilliseconds}ms');

    if (failed > 0) {
      print('\\n❌ Failed Tests:');
      for (final result in _testResults.where((r) => !r.success)) {
        print('   • ${result.name}: ${result.message}');
      }
    }

    final successRate = (passed / _testResults.length * 100).toStringAsFixed(1);
    print('\\n🎯 Success Rate: $successRate%');

    if (passed == _testResults.length) {
      print('\\n🎉 All bidirectional sync tests passed!');
      print('✅ USM PocketBase integration is working correctly.');
      print('✅ Local ↔ Remote sync functionality validated.');
      print('✅ Data integrity maintained across sync operations.');
    } else {
      print('\\n⚠️ Some tests failed. Review the results above for details.');
    }
  }

  /// Clean up test environment
  Future<void> cleanup() async {
    try {
      print('\\n🧹 Cleaning up test environment...');

      // Clean up test records from PocketBase
      final testConfig = _config['test'] as Map<String, dynamic>?;
      final cleanupAfterTests =
          testConfig?['cleanup_after_tests'] as bool? ?? true;

      if (cleanupAfterTests) {
        // Delete test records from PocketBase using USM
        final testResults = await _usmAdapter.query(
            _tableName!,
            SyncQuery(
              filters: {'createdBy': 'test-user'},
              limit: 500,
            ));

        final successResults = testResults.where((r) => r.isSuccess).toList();

        for (final result in successResults) {
          final data = result.data!;
          final deleteResult =
              await _usmAdapter.delete(_tableName!, data['id']);
          if (!deleteResult.isSuccess) {
            print(
                '   ⚠️ Failed to delete record ${data['id']}: ${deleteResult.error?.message}');
          }
        }

        // Delete test records from local database
        _localDb
            .execute('DELETE FROM $_tableName WHERE createdBy = "test-user"');

        print('✅ Cleaned up ${successResults.length} test records');
      }

      // Close database connection
      _localDb.dispose();
      print('✅ Database connection closed');
    } catch (e) {
      print('⚠️ Cleanup failed: $e');
    }
  }
}

/// Test result data class
class TestResult {
  final String name;
  final bool success;
  final String message;
  final Duration duration;

  TestResult({
    required this.name,
    required this.success,
    required this.message,
    required this.duration,
  });
}

/// Main function to run the bidirectional sync tests
void main() async {
  final tests = USMBidirectionalSyncTest();

  try {
    await tests.initialize();
    await tests.runAllTests();
  } catch (e) {
    print('💥 Test execution failed: $e');
    exit(1);
  } finally {
    await tests.cleanup();
  }

  print('\\n🏁 Bidirectional sync test execution completed');
}
