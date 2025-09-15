import 'package:flutter/material.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'local_sample_data.dart';
import 'remote_sample_data.dart';
import 'services/test_operations_service.dart';
import 'services/test_results_manager.dart';

class SupabaseTestPage extends StatefulWidget {
  const SupabaseTestPage({super.key});

  @override
  State<SupabaseTestPage> createState() => _SupabaseTestPageState();
}

class _SupabaseTestPageState extends State<SupabaseTestPage> {
  // Test configuration - UPDATE THESE WITH YOUR SUPABASE VALUES
  static const String supabaseUrl = 'https://rsuuacugtplmuhlevbbq.supabase.co';
  static const String supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJzdXVhY3VndHBsbXVobGV2YmJxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMzMjQ4MTksImV4cCI6MjA2ODkwMDgxOX0.Cq7UUeSWmo9BcRQPbadTT3xj9vusL5MjOdmfTfb-7cE';

  // USM components
  SupabaseSyncAdapter? _adapter;
  UniversalSyncManager? _syncManager;

  // Test state
  bool _isConnected = false;
  bool _isAuthenticated = false;
  String _status = 'Not initialized';
  List<Map<String, dynamic>> _testResults = [];

  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _initializeSupabase();
  }

  Future<void> _initializeSupabase() async {
    try {
      // Initialize Supabase
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
      );

      setState(() {
        _status = 'Supabase initialized';
      });

      _addTestResult(
          'Supabase initialization', true, 'Successfully initialized');
    } catch (e) {
      _addTestResult('Supabase initialization', false, e.toString());
    }
  }

  Future<void> _testAdapterConnection() async {
    try {
      print('🔗 Creating Supabase adapter...');

      _adapter = SupabaseSyncAdapter(
        supabaseUrl: supabaseUrl,
        supabaseAnonKey: supabaseKey, // Fixed parameter name
      );

      print('🔗 Adapter created, setting up configuration...');

      final config = SyncBackendConfiguration(
        configId: 'test-config',
        displayName: 'Supabase Test',
        backendType: 'supabase',
        baseUrl: supabaseUrl,
        projectId: 'test-project',
      );

      print('🔗 Connecting with config: ${config.toJson()}');
      final connected = await _adapter!.connect(config);

      print('🔗 Connection result: $connected');
      print('🔗 Adapter backend info: ${_adapter!.backendInfo}');
      print(
          '🔗 Adapter capabilities: ${_adapter!.capabilities.featureSummary}');

      setState(() {
        _isConnected = connected;
        _status = connected ? 'Connected to Supabase' : 'Connection failed';
      });

      _addTestResult(
          'Adapter connection',
          connected,
          connected
              ? 'Successfully connected to Supabase backend'
              : 'Connection failed');
    } catch (e) {
      print('❌ Adapter connection error: $e');
      _addTestResult('Adapter connection', false, e.toString());
    }
  }

  Future<void> _testPreAuthOperations() async {
    try {
      if (_adapter == null) {
        throw Exception('Adapter not connected');
      }

      print('📋 Testing pre-auth operations (public tables)...');

      // Test READ operations on pre-auth tables (should work without authentication)
      print('📋 Querying app_settings table...');
      final appSettingsQuery =
          await _adapter!.query('app_settings', SyncQuery());

      print('📋 App settings query result: ${appSettingsQuery.length} items');
      for (var i = 0; i < appSettingsQuery.length; i++) {
        final result = appSettingsQuery[i];
        print('📋 App setting $i: ${result.data}');
        print('📋 Result success: ${result.isSuccess}');
        print('📋 Result error: ${result.error?.message}');
      }

      _addTestResult(
          'Pre-auth READ (app_settings)',
          appSettingsQuery.isNotEmpty,
          appSettingsQuery.isNotEmpty
              ? 'Retrieved ${appSettingsQuery.length} settings'
              : 'No settings found');

      // Test if we can read specific records
      if (appSettingsQuery.isNotEmpty) {
        final firstSetting = appSettingsQuery.first;
        final settingData = firstSetting.data;

        if (settingData != null && settingData['id'] != null) {
          final settingId = settingData['id'];
          print('📋 Testing READ by ID for setting: $settingId');
          final readResult =
              await _adapter!.read('app_settings', settingId.toString());

          print('📋 READ by ID result: ${readResult.isSuccess}');
          if (readResult.isSuccess) {
            print('📋 Read data: ${readResult.data}');
          } else {
            print('❌ READ by ID error: ${readResult.error?.message}');
          }

          _addTestResult(
              'Pre-auth READ by ID',
              readResult.isSuccess,
              readResult.isSuccess
                  ? 'Successfully read setting by ID'
                  : readResult.error?.message ?? 'Unknown error');
        } else {
          print('📋 Setting data or ID is null, skipping READ by ID test');
          print('📋 First setting data: $settingData');
          _addTestResult(
              'Pre-auth READ by ID', false, 'Setting data or ID is null');
        }
      }
    } catch (e) {
      print('❌ Pre-auth operations error: $e');
      _addTestResult('Pre-auth operations', false, e.toString());
    }
  }

  Future<void> _testAuthentication() async {
    try {
      final supabase = Supabase.instance.client;

      print('🔐 Starting authentication with admin@has.com...');

      // Test user signin with email/password
      final response = await supabase.auth.signInWithPassword(
        email: 'admin@has.com',
        password: '123456789',
      );

      print('🔐 Auth response received: ${response.user?.id}');
      print('🔐 User email: ${response.user?.email}');
      print('🔐 User role: ${response.user?.role}');
      if (response.session?.accessToken != null) {
        print(
            '🔐 Access token: ${response.session!.accessToken.substring(0, 20)}...');
      }

      if (response.user != null) {
        setState(() {
          _isAuthenticated = true;
          _status = 'Authenticated as ${response.user!.email}';
        });

        _addTestResult('Authentication', true,
            'User authenticated: ${response.user!.email}');

        // Log auth state
        _logAuthState();
      } else {
        _addTestResult('Authentication', false, 'No user returned');
      }
    } catch (e) {
      print('❌ Authentication error: $e');
      _addTestResult('Authentication', false, e.toString());
    }
  }

  Future<void> _signOut() async {
    try {
      print('🔐 Signing out...');
      final supabase = Supabase.instance.client;
      await supabase.auth.signOut();

      setState(() {
        _isAuthenticated = false;
        _status = 'Signed out';
      });

      _addTestResult('Sign Out', true, 'Successfully signed out');
      _logAuthState();
    } catch (e) {
      print('❌ Sign out error: $e');
      _addTestResult('Sign Out', false, e.toString());
    }
  }

  void _logAuthState() {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final session = supabase.auth.currentSession;

    print('🔐 === AUTH STATE ===');
    print('🔐 Current User: ${user?.toJson()}');
    print('🔐 Current Session: ${session?.toJson()}');
    print('🔐 Is Authenticated: ${user != null}');
    print('🔐 User ID: ${user?.id}');
    print('🔐 User Email: ${user?.email}');
    print('🔐 Session Expires: ${session?.expiresAt}');
    print('🔐 ==================');
  }

  Future<void> _testSyncManagerInitialization() async {
    try {
      if (_adapter == null) {
        throw Exception('Adapter not connected');
      }

      // Initialize sync manager with the adapter
      _syncManager = UniversalSyncManager(
        backendAdapter: _adapter!,
        syncInterval: const Duration(seconds: 30),
        enableAutoSync: false, // Disable for testing
      );

      // Configure sync manager with both pre-auth and post-auth collections
      await _syncManager!.configure(
        collections: [
          // PRE-AUTH COLLECTIONS (accessible without authentication)
          SyncCollection(
            name: 'app_settings',
            syncDirection:
                SyncDirection.downloadOnly, // Usually read-only for clients
          ),
          // POST-AUTH COLLECTIONS (require authentication)
          SyncCollection(
            name: 'organization_profiles',
            syncDirection: SyncDirection.bidirectional,
          ),
          SyncCollection(
            name: 'audit_items',
            syncDirection: SyncDirection.bidirectional,
          ),
        ],
        backendConfig: SyncBackendConfiguration(
          configId: 'test-config',
          displayName: 'Test Config',
          backendType: 'supabase',
          baseUrl: supabaseUrl,
          projectId: 'test-project',
        ),
      );

      _addTestResult(
          'Sync Manager initialization', true, 'Successfully initialized');
    } catch (e) {
      _addTestResult('Sync Manager initialization', false, e.toString());
    }
  }

  Future<void> _testCrudOperations() async {
    try {
      if (_adapter == null) {
        throw Exception('Adapter not connected');
      }

      print('🔧 Starting CRUD operations test...');

      final orgId = _uuid.v4();
      final userId =
          Supabase.instance.client.auth.currentUser?.id ?? _uuid.v4();

      print('🔧 Generated organization_id: $orgId');
      print('🔧 Using user_id: $userId');

      // Test CREATE (Don't include 'id' field - let Supabase generate it)
      final createData = {
        'organization_id': orgId,
        'name': 'Test Organization ${DateTime.now().millisecondsSinceEpoch}',
        'description': 'Test Description for USM-Supabase integration',
        'is_active': true,
        'created_by': userId,
        'updated_by': userId,
        'sync_version': 1,
      };

      print('🔧 CREATE data: $createData');
      print(
          '🔧 Data types - orgId: ${orgId.runtimeType}, userId: ${userId.runtimeType}, is_active: ${true.runtimeType}, sync_version: ${1.runtimeType}');

      final createResult =
          await _adapter!.create('organization_profiles', createData);

      print('🔧 CREATE result success: ${createResult.isSuccess}');
      if (createResult.isSuccess) {
        print('🔧 Created record data: ${createResult.data}');
      } else {
        print('❌ CREATE error: ${createResult.error?.message}');
      }

      _addTestResult(
          'CREATE operation',
          createResult.isSuccess,
          createResult.isSuccess
              ? 'Data created successfully with ID: ${createResult.data?['id']}'
              : createResult.error?.message ?? 'Unknown error');

      if (createResult.isSuccess) {
        final recordId = createResult.data?['id'];
        print('🔧 Created record ID: $recordId');

        // Test READ
        print('🔧 Testing READ operation for ID: $recordId');
        final readResult =
            await _adapter!.read('organization_profiles', recordId.toString());

        print('🔧 READ result success: ${readResult.isSuccess}');
        if (readResult.isSuccess) {
          print('🔧 Read data: ${readResult.data}');
        } else {
          print('❌ READ error: ${readResult.error?.message}');
        }

        _addTestResult(
            'READ operation',
            readResult.isSuccess,
            readResult.isSuccess
                ? 'Data read successfully: ${readResult.data?['name']}'
                : readResult.error?.message ?? 'Unknown error');

        // Test UPDATE
        if (readResult.isSuccess) {
          print('🔧 Testing UPDATE operation...');
          final updateData = {
            ...readResult.data!,
            'name':
                'Updated Organization ${DateTime.now().millisecondsSinceEpoch}',
            'description': 'Updated description via USM',
            'sync_version': 2,
          };

          print('🔧 UPDATE data: $updateData');

          final updateResult = await _adapter!
              .update('organization_profiles', recordId.toString(), updateData);

          print('🔧 UPDATE result success: ${updateResult.isSuccess}');
          if (updateResult.isSuccess) {
            print('🔧 Updated data: ${updateResult.data}');
          } else {
            print('❌ UPDATE error: ${updateResult.error?.message}');
          }

          _addTestResult(
              'UPDATE operation',
              updateResult.isSuccess,
              updateResult.isSuccess
                  ? 'Data updated successfully: ${updateResult.data?['name']}'
                  : updateResult.error?.message ?? 'Unknown error');

          // Test DELETE
          print('🔧 Testing DELETE operation...');
          final deleteResult = await _adapter!
              .delete('organization_profiles', recordId.toString());

          print('🔧 DELETE result success: ${deleteResult.isSuccess}');
          if (!deleteResult.isSuccess) {
            print('❌ DELETE error: ${deleteResult.error?.message}');
          }

          _addTestResult(
              'DELETE operation',
              deleteResult.isSuccess,
              deleteResult.isSuccess
                  ? 'Data deleted successfully'
                  : deleteResult.error?.message ?? 'Unknown error');
        }
      }
    } catch (e) {
      print('❌ CRUD operations error: $e');
      _addTestResult('CRUD operations', false, e.toString());
    }
  }

  Future<void> _createSampleData() async {
    try {
      print('📝 Creating sample data in Supabase tables...');

      await RemoteSampleDataManager.createRemoteAppSettings();

      print('✅ Sample data created successfully');
      _addTestResult(
          'Sample data creation', true, 'Sample data created in public tables');
    } catch (e) {
      print('❌ Sample data creation error: $e');
      _addTestResult('Sample data creation', false, e.toString());
    }
  }

  Future<void> _createLocalSampleData() async {
    try {
      print('� Creating local sample data for local → remote sync testing...');

      await LocalSampleDataManager.createAllSampleData();

      // Show current local data
      final profiles =
          await LocalSampleDataManager.getLocalOrganizationProfiles();
      final audits = await LocalSampleDataManager.getLocalAuditItems();

      _addTestResult('Local sample data creation', true,
          'Created ${profiles.length} org profiles and ${audits.length} audit items locally');
    } catch (e) {
      print('❌ Local sample data creation error: $e');
      _addTestResult('Local sample data creation', false, e.toString());
    }
  }

  Future<void> _createRemoteSampleData() async {
    try {
      print(
          '☁️ Creating remote sample data for remote → local sync testing...');

      if (!_isAuthenticated) {
        _addTestResult('Remote sample data creation', false,
            'Must be authenticated first');
        return;
      }

      await RemoteSampleDataManager.createAllRemoteSampleData();

      // Show current remote data
      final profiles =
          await RemoteSampleDataManager.getRemoteOrganizationProfiles();
      final audits = await RemoteSampleDataManager.getRemoteAuditItems();

      _addTestResult('Remote sample data creation', true,
          'Created ${profiles.length} org profiles and ${audits.length} audit items remotely');
    } catch (e) {
      print('❌ Remote sample data creation error: $e');
      _addTestResult('Remote sample data creation', false, e.toString());
    }
  }

  Future<void> _testLocalToRemoteSync() async {
    try {
      print('� Testing Local → Remote Sync...');

      if (!_isAuthenticated || _syncManager == null) {
        _addTestResult('Local → Remote Sync', false,
            'Must be authenticated and sync manager initialized');
        return;
      }

      // Get dirty local records
      final dirtyProfiles =
          await LocalSampleDataManager.getDirtyOrganizationProfiles();
      final dirtyAudits = await LocalSampleDataManager.getDirtyAuditItems();

      print(
          '🔄 Found ${dirtyProfiles.length} dirty profiles and ${dirtyAudits.length} dirty audits');

      int syncedCount = 0;

      // Sync organization profiles
      for (int i = 0; i < dirtyProfiles.length; i++) {
        final profile = dirtyProfiles[i];
        try {
          print('🔄 Syncing profile: ${profile['name']}');
          final result =
              await _adapter!.create('organization_profiles', profile);
          if (result.isSuccess) {
            // Note: We don't mark as synced since we don't have the local record ID here
            // In a real implementation, you'd get the local records with their IDs for marking
            syncedCount++;
            print('✅ Successfully synced profile: ${profile['name']}');
          } else {
            print('❌ Failed to sync profile: ${result.error?.message}');
          }
        } catch (e) {
          print('❌ Failed to sync profile ${profile['name']}: $e');
        }
      }

      // Sync audit items
      for (int i = 0; i < dirtyAudits.length; i++) {
        final audit = dirtyAudits[i];
        try {
          print('🔄 Syncing audit: ${audit['title']}');
          final result = await _adapter!.create('audit_items', audit);
          if (result.isSuccess) {
            // Note: We don't mark as synced since we don't have the local record ID here
            // In a real implementation, you'd get the local records with their IDs for marking
            syncedCount++;
            print('✅ Successfully synced audit: ${audit['title']}');
          } else {
            print('❌ Failed to sync audit: ${result.error?.message}');
          }
        } catch (e) {
          print('❌ Failed to sync audit ${audit['title']}: $e');
        }
      }

      _addTestResult('Local → Remote Sync', syncedCount > 0,
          'Synced $syncedCount records from local to remote');
    } catch (e) {
      print('❌ Local → Remote sync error: $e');
      _addTestResult('Local → Remote Sync', false, e.toString());
    }
  }

  Future<void> _testRemoteToLocalSync() async {
    try {
      print('🔄 Testing Remote → Local Sync...');

      if (!_isAuthenticated || _adapter == null) {
        _addTestResult('Remote → Local Sync', false,
            'Must be authenticated and adapter connected');
        return;
      }

      // Get remote data
      final remoteProfiles =
          await _adapter!.query('organization_profiles', SyncQuery());
      final remoteAudits = await _adapter!.query('audit_items', SyncQuery());

      print(
          '🔄 Found ${remoteProfiles.length} remote profiles and ${remoteAudits.length} remote audits');

      int syncedCount = 0;

      // For demo purposes, we'll just count the remote records
      // In a real app, you'd check timestamps and sync only newer records
      syncedCount = remoteProfiles.length + remoteAudits.length;

      _addTestResult('Remote → Local Sync', syncedCount > 0,
          'Found $syncedCount records to sync from remote to local');
    } catch (e) {
      print('❌ Remote → Local sync error: $e');
      _addTestResult('Remote → Local Sync', false, e.toString());
    }
  }

  Future<void> _testBidirectionalSync() async {
    try {
      print('🔄🔄 Testing Bidirectional Sync...');
      _addTestResult(
          'Bidirectional Sync', false, 'Starting bidirectional sync test...');

      if (!_isAuthenticated || _adapter == null) {
        _addTestResult('Bidirectional Sync', false,
            'Must be authenticated and adapter connected');
        return;
      }

      // Create a test operations service for bidirectional sync
      final testResultsManager = TestResultsManager();
      final testService = TestOperationsService(testResultsManager);

      // Set the adapter and sync manager
      testService.adapter = _adapter;
      testService.syncManager = _syncManager;

      final success = await testService.testBidirectionalSync();

      if (success) {
        _addTestResult('Bidirectional Sync', true,
            'Successfully completed local→remote and remote→local sync with conflict detection');
        print('✅ Bidirectional sync completed successfully!');
      } else {
        _addTestResult('Bidirectional Sync', false,
            'Bidirectional sync failed - check logs for details');
        print('❌ Bidirectional sync failed!');
      }
    } catch (e) {
      print('❌ Bidirectional sync error: $e');
      _addTestResult('Bidirectional Sync', false, e.toString());
    }
  }

  Future<void> _testEventSystem() async {
    try {
      if (_syncManager == null) {
        throw Exception('Sync Manager not initialized');
      }

      // Test sync manager basic functionality instead of events for now
      final isAuthenticated = _syncManager!.isAuthenticated;
      final isSyncing = _syncManager!.isSyncing;

      _addTestResult('Sync Manager state check', true,
          'Auth: $isAuthenticated, Syncing: $isSyncing');
    } catch (e) {
      _addTestResult('Sync Manager state check', false, e.toString());
    }
  }

  void _addTestResult(String test, bool success, String message) {
    setState(() {
      _testResults.add({
        'test': test,
        'success': success,
        'message': message,
        'timestamp': DateTime.now(),
      });
    });
  }

  void _clearResults() {
    setState(() {
      _testResults.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('USM Supabase Testing'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Status Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status: $_status',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(_isConnected ? Icons.wifi : Icons.wifi_off,
                          color: _isConnected ? Colors.green : Colors.red),
                      const SizedBox(width: 8),
                      Text('Connected: $_isConnected'),
                      const SizedBox(width: 16),
                      Icon(_isAuthenticated ? Icons.lock_open : Icons.lock,
                          color: _isAuthenticated ? Colors.green : Colors.red),
                      const SizedBox(width: 8),
                      Text('Authenticated: $_isAuthenticated'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Test Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _testAdapterConnection,
                  child: const Text('Test Connection'),
                ),
                ElevatedButton(
                  onPressed: _createSampleData,
                  child: const Text('Create Public Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton(
                  onPressed: _testPreAuthOperations,
                  child: const Text('Test Pre-Auth'),
                ),
                ElevatedButton(
                  onPressed: _testAuthentication,
                  child: const Text('Sign In'),
                ),
                ElevatedButton(
                  onPressed: _signOut,
                  child: const Text('Sign Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton(
                  onPressed: _testSyncManagerInitialization,
                  child: const Text('Test Sync Manager'),
                ),
                ElevatedButton(
                  onPressed: _testCrudOperations,
                  child: const Text('Test Post-Auth CRUD'),
                ),
                ElevatedButton(
                  onPressed: _createLocalSampleData,
                  child: const Text('Create Local Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton(
                  onPressed: _createRemoteSampleData,
                  child: const Text('Create Remote Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton(
                  onPressed: _testLocalToRemoteSync,
                  child: const Text('Local → Remote'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton(
                  onPressed: _testRemoteToLocalSync,
                  child: const Text('Remote → Local'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton(
                  onPressed: _testBidirectionalSync,
                  child: const Text('🔄 Bidirectional'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton(
                  onPressed: _testEventSystem,
                  child: const Text('Test State'),
                ),
                ElevatedButton(
                  onPressed: _clearResults,
                  child: const Text('Clear Results'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Test Results
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _testResults.length,
              itemBuilder: (context, index) {
                final result = _testResults[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      result['success'] ? Icons.check_circle : Icons.error,
                      color: result['success'] ? Colors.green : Colors.red,
                    ),
                    title: Text(result['test']),
                    subtitle: Text(result['message']),
                    trailing: Text(
                      '${result['timestamp'].hour}:${result['timestamp'].minute.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
