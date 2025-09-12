import 'package:flutter/material.dart';

import 'services/test_results_manager.dart';
import 'services/authentication_service.dart';
import 'services/test_operations_service.dart';
import 'widgets/status_display.dart';
import 'widgets/test_action_buttons.dart';
import 'widgets/test_results_list.dart';

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

    // Listen to results manager changes to update UI
    _resultsManager.addListener(_onResultsChanged);
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
  }

  @override
  void dispose() {
    _resultsManager.removeListener(_onResultsChanged);
    _resultsManager.dispose();
    _testService.cleanup();
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
              onTestEventSystem: _testEventSystem,
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

  Future<void> _testEventSystem() async {
    await _testService.testEventSystem();
  }

  void _clearResults() {
    _resultsManager.clearResults();
  }
}
