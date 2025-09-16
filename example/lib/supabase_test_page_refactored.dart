import 'package:flutter/material.dart';
import 'dart:async';

import 'services/test_results_manager.dart';
import 'services/authentication_service.dart';
import 'services/test_operations_service.dart';
import 'services/test_queue_operations_service.dart';
import 'services/test_auth_lifecycle_service.dart';
import 'services/test_state_management_service.dart';
import 'services/test_token_management_service.dart';
import 'services/test_network_connection_service.dart';
import 'services/test_data_integrity_service.dart';
import 'services/test_performance_service.dart';
import 'widgets/status_display.dart';
import 'widgets/test_action_buttons.dart';
import 'widgets/test_results_list.dart';
import 'models/sync_event.dart';

/// Refactored Supabase test page using modular components
class SupabaseTestPageRefactored extends StatefulWidget {
  const SupabaseTestPageRefactored({super.key});

  @override
  State<SupabaseTestPageRefactored> createState() =>
      _SupabaseTestPageRefactoredState();
}

class _SupabaseTestPageRefactoredState
    extends State<SupabaseTestPageRefactored> {
  // Service instances
  late final TestResultsManager _resultsManager;
  late final AuthenticationService _authService;
  late final TestOperationsService _testService;
  late final TestQueueOperationsService _queueTestService;
  late final TestAuthLifecycleService _authLifecycleTestService;
  late final TestStateManagementService _stateManagementTestService;
  late final TestTokenManagementService _tokenManagementTestService;
  late final TestNetworkConnectionService _networkTestService;
  late final TestDataIntegrityService _dataIntegrityTestService;
  late final TestPerformanceService _performanceTestService;

  // Event system state
  String _lastEventMessage = 'No events yet';
  Color _eventStatusColor = Colors.grey;
  final List<String> _recentEvents = [];
  StreamSubscription<SyncEvent>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeSupabase();
  }

  void _initializeServices() {
    _resultsManager = TestResultsManager();
    _authService = AuthenticationService(_resultsManager);
    _testService = TestOperationsService(_resultsManager);
    _queueTestService = TestQueueOperationsService();
    _authLifecycleTestService = TestAuthLifecycleService();
    _stateManagementTestService = TestStateManagementService();
    _tokenManagementTestService = TestTokenManagementService();
    _networkTestService = TestNetworkConnectionService();
    _dataIntegrityTestService = TestDataIntegrityService(null);
    _performanceTestService = TestPerformanceService(_resultsManager);

    // Listen to results manager changes to update UI
    _resultsManager.addListener(_onResultsChanged);

    // Set up event system listeners
    _setupEventListeners();
  }

  void _setupEventListeners() {
    // Listen to all sync events for real-time UI updates
    _eventSubscription = _testService.eventBus.listen(_onSyncEvent);
  }

  void _onSyncEvent(SyncEvent event) {
    if (!mounted) return;

    setState(() {
      // Update status message based on event type
      switch (event.type) {
        case SyncEventType.syncStarted:
          _lastEventMessage =
              '🚀 Started: ${(event as SyncProgressEvent).operation}';
          _eventStatusColor = Colors.blue;
          break;
        case SyncEventType.syncProgress:
          final progressEvent = event as SyncProgressEvent;
          _lastEventMessage =
              '⏳ ${progressEvent.operation}: ${progressEvent.current}/${progressEvent.total}';
          _eventStatusColor = Colors.orange;
          break;
        case SyncEventType.syncCompleted:
          final completedEvent = event as SyncCompletedEvent;
          _lastEventMessage = completedEvent.success
              ? '✅ Completed: ${completedEvent.operation} (${completedEvent.affectedRecords} records)'
              : '❌ Failed: ${completedEvent.operation}';
          _eventStatusColor =
              completedEvent.success ? Colors.green : Colors.red;
          break;
        case SyncEventType.syncError:
          final errorEvent = event as SyncErrorEvent;
          _lastEventMessage =
              '❌ Error in ${errorEvent.operation}: ${errorEvent.error}';
          _eventStatusColor = Colors.red;
          break;
        case SyncEventType.conflictDetected:
          final conflictEvent = event as ConflictEvent;
          _lastEventMessage =
              '⚡ Conflict detected: ${conflictEvent.collection}/${conflictEvent.recordId}';
          _eventStatusColor = Colors.purple;
          break;
        case SyncEventType.conflictResolved:
          final resolvedEvent = event as ConflictEvent;
          _lastEventMessage =
              '✅ Conflict resolved: ${resolvedEvent.resolution}';
          _eventStatusColor = Colors.green;
          break;
        case SyncEventType.dataCreated:
        case SyncEventType.dataUpdated:
        case SyncEventType.dataDeleted:
          final dataEvent = event as DataOperationEvent;
          final icon = dataEvent.success ? '✅' : '❌';
          _lastEventMessage =
              '$icon ${dataEvent.operation.toUpperCase()}: ${dataEvent.collection}';
          _eventStatusColor = dataEvent.success ? Colors.green : Colors.red;
          break;
        default:
          _lastEventMessage = '📡 ${event.type.toString().split('.').last}';
          _eventStatusColor = Colors.blue;
      }

      // Add to recent events list (keep last 10)
      _recentEvents.insert(0,
          '${DateTime.now().toString().substring(11, 19)} - $_lastEventMessage');
      if (_recentEvents.length > 10) {
        _recentEvents.removeLast();
      }
    });
  }

  void _onResultsChanged() {
    if (mounted) {
      setState(() {
        // UI will rebuild with updated results
      });
    }
  }

  Future<void> _initializeSupabase() async {
    await _testService.initializeSupabase();
    // Initialize MyAppSyncManager for auth lifecycle integration
    await _testService.initializeMyAppSyncManager();
  }

  @override
  void dispose() {
    _resultsManager.removeListener(_onResultsChanged);
    _resultsManager.dispose();
    _testService.cleanup();
    _stateManagementTestService.dispose();
    _tokenManagementTestService.dispose();
    _eventSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Universal Sync Manager - Supabase Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Status Display
          Padding(
            padding: const EdgeInsets.all(16),
            child: StatusDisplay(
              status: _resultsManager.status,
              isConnected: _resultsManager.isConnected,
              isAuthenticated: _resultsManager.isAuthenticated,
            ),
          ),

          // Real-time Event Status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              color: _eventStatusColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.flash_on,
                          color: _eventStatusColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Live Event Status',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _lastEventMessage,
                      style: TextStyle(color: _eventStatusColor),
                    ),
                    if (_recentEvents.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 4),
                      const Text(
                        'Recent Events:',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      ...(_recentEvents.take(3).map((event) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              event,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ))),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Test Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TestActionButtons(
              onTestConnection: _testConnection,
              onTestPreAuth: _testPreAuthOperations,
              onTestAuthentication: _testAuthentication,
              onSignOut: _signOut,
              onTestSyncManager: _testSyncManager,
              onTestCrud: _testCrudOperations,
              onTestBatchOperations: _testBatchOperations,
              onCreateSampleData: _createSampleData,
              onCreateLocalData: _createLocalSampleData,
              onCreateRemoteData: _createRemoteSampleData,
              onTestLocalToRemote: _testLocalToRemoteSync,
              onTestRemoteToLocal: _testRemoteToLocalSync,
              onTestBidirectionalSync: _testBidirectionalSync,
              onTestEventSystem: _testEventSystem,
              onTestFullEventIntegration: _testFullEventIntegration,
              onTestConflictResolution: _testConflictResolution,
              onTestTableConflicts: _testTableConflicts,
              onTestQueueOperations: _testQueueOperations,
              onTestAuthLifecycle: _testAuthLifecycle,
              onTestStateManagement: _testStateManagement,
              onTestTokenManagement: _testTokenManagement,
              onTestNetworkConnection: _testNetworkConnection,
              onTestDataIntegrity: _testDataIntegrity,
              onTestPerformance: _testPerformance,
              onClearResults: _clearResults,
            ),
          ),

          const SizedBox(height: 16),

          // Test Results List
          Expanded(
            child: TestResultsList(
              results: _resultsManager.results,
            ),
          ),
        ],
      ),
    );
  }

  // Test Methods - now just delegate to services

  Future<void> _testConnection() async {
    await _testService.testAdapterConnection();
  }

  Future<void> _testPreAuthOperations() async {
    await _testService.testPreAuthOperations();
  }

  Future<void> _testAuthentication() async {
    await _authService.signInWithTestCredentials();
  }

  Future<void> _signOut() async {
    await _authService.signOut();
  }

  Future<void> _testSyncManager() async {
    await _testService.testSyncManagerInitialization();
  }

  Future<void> _testCrudOperations() async {
    await _testService.testCrudOperations();
  }

  Future<void> _testBatchOperations() async {
    await _testService.testBatchOperations();
  }

  Future<void> _createSampleData() async {
    await _testService.createSampleData();
  }

  Future<void> _createLocalSampleData() async {
    await _testService.createLocalSampleData();
  }

  Future<void> _createRemoteSampleData() async {
    await _testService.createRemoteSampleData();
  }

  Future<void> _testLocalToRemoteSync() async {
    await _testService.testLocalToRemoteSync();
  }

  Future<void> _testRemoteToLocalSync() async {
    await _testService.testRemoteToLocalSync();
  }

  Future<void> _testBidirectionalSync() async {
    await _testService.testBidirectionalSync();
  }

  Future<void> _testEventSystem() async {
    await _testService.testEventSystem();
  }

  Future<void> _testFullEventIntegration() async {
    await _testService.testFullEventSystemIntegration();
  }

  Future<void> _testConflictResolution() async {
    await _testService.testAllConflictResolutionStrategies();
  }

  Future<void> _testTableConflicts() async {
    await _testService.testTableConflictResolution();
  }

  Future<void> _testQueueOperations() async {
    await _queueTestService.runAllQueueTests();
  }

  Future<void> _testAuthLifecycle() async {
    await _authLifecycleTestService.runAllAuthLifecycleTests();
  }

  Future<void> _testStateManagement() async {
    await _stateManagementTestService.runAllStateManagementTests();
  }

  Future<void> _testTokenManagement() async {
    await _tokenManagementTestService.runAllTests();
  }

  Future<void> _testNetworkConnection() async {
    try {
      // Ensure sync manager is available
      if (_testService.syncManager == null) {
        print('❌ Network connection testing requires initialized sync manager');
        return;
      }

      await _networkTestService.initialize(_testService.syncManager!);
      await _networkTestService.runAllNetworkTests();
    } catch (e) {
      print('❌ Failed to run network connection tests: $e');
    }
  }

  Future<void> _testDataIntegrity() async {
    try {
      // Run data integrity tests
      print('🔍 Starting Data Integrity Testing...');
      await _dataIntegrityTestService.runAllDataIntegrityTests();
      print('✅ Data integrity testing completed');
    } catch (e) {
      print('❌ Failed to run data integrity tests: $e');
    }
  }

  Future<void> _testPerformance() async {
    try {
      // Run performance tests
      print('⚡ Starting Performance Testing...');
      await _performanceTestService.runAllPerformanceTests();
      print('✅ Performance testing completed');
    } catch (e) {
      print('❌ Failed to run performance tests: $e');
    }
  }

  void _clearResults() {
    _resultsManager.clearResults();
  }
}
