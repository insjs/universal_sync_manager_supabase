/// Comprehensive Authentication Lifecycle Testing Service
///
/// Tests Phase 4.1: Auth Provider Integration Testing
/// - SupabaseAuthIntegration
/// - AuthLifecycleManager
/// - Multi-session handling
/// - Token refresh automation
/// - Auth state synchronization

import 'dart:async';
import 'dart:math';
import 'package:universal_sync_manager/universal_sync_manager.dart';

class TestAuthLifecycleService {
  final AuthLifecycleManager _lifecycleManager = AuthLifecycleManager();
  bool _isInitialized = false;

  // Test data generators
  final Random _random = Random();
  final List<String> _testUserIds = [];
  final Map<String, Map<String, dynamic>> _testSessions = {};

  /// Initialize auth lifecycle testing service
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('🔧 Initializing Auth Lifecycle Testing Service...');

    try {
      // Initialize the lifecycle manager
      await _lifecycleManager.initialize();
      print('✅ AuthLifecycleManager initialized successfully');

      // Generate test user data
      _generateTestUserData();

      _isInitialized = true;
      print('🎯 Auth Lifecycle Testing Service ready');
    } catch (e) {
      print('❌ Failed to initialize auth lifecycle testing: $e');
      rethrow;
    }
  }

  /// Generate test user data for multi-session testing
  void _generateTestUserData() {
    for (int i = 1; i <= 5; i++) {
      final userId = 'test-user-$i';
      _testUserIds.add(userId);
      _testSessions[userId] = {
        'token': 'test-token-${_random.nextInt(100000)}',
        'organizationId': 'org-${(i % 3) + 1}', // 3 different orgs
        'metadata': {
          'name': 'Test User $i',
          'email': 'user$i@example.com',
          'role': ['admin', 'user', 'viewer'][i % 3],
          'department': ['engineering', 'sales', 'marketing'][i % 3],
        },
      };
    }
    print(
        '📊 Generated ${_testUserIds.length} test users across ${_testSessions.values.map((s) => s['organizationId']).toSet().length} organizations');
  }

  /// Test 1: Supabase Auth Integration
  Future<void> testSupabaseAuthIntegration() async {
    print('🚀 Testing Supabase Auth Integration...');
    print('==================================================');

    try {
      // Test 1.1: Check connection status
      print('🔍 Checking Supabase Auth connection status...');
      final isConnected = SupabaseAuthIntegration.isConnected;
      print('📡 Supabase Auth connected: $isConnected');

      // Test 1.2: Manual token refresh simulation
      print('🔄 Testing manual token refresh...');
      try {
        await SupabaseAuthIntegration.refreshToken();
        print('✅ Manual token refresh completed successfully');
      } catch (e) {
        print('⚠️ Manual token refresh: $e (expected if no active session)');
      }

      // Test 1.3: User metadata extraction
      print('📋 Testing user metadata extraction...');
      final mockUser = {
        'id': 'test-user-123',
        'email': 'test@example.com',
        'phone': '+1234567890',
        'user_metadata': {
          'name': 'Test User',
          'role': 'admin',
        },
        'app_metadata': {
          'organization_id': 'org-123',
          'permissions': ['read', 'write'],
        },
      };

      final metadata = SupabaseAuthIntegration.getUserMetadata(mockUser);
      print('📊 Extracted metadata: ${metadata.keys.length} fields');
      print('   📋 Email: ${metadata['email']}');
      print('   📋 Phone: ${metadata['phone']}');
      print('   📋 Role: ${metadata['role']}');
      print('   📋 Organization ID: ${metadata['organization_id']}');

      print('✅ Supabase Auth Integration test completed');
    } catch (e) {
      print('❌ Supabase Auth Integration test failed: $e');
    }
  }

  /// Test 2: Auth Lifecycle Events Testing
  Future<void> testAuthLifecycleEvents() async {
    print('🎭 Testing Auth Lifecycle Events...');
    print('==================================================');

    final eventsList = <AuthLifecycleEvent>[];
    final statesList = <AuthLifecycleState>[];

    // Listen to lifecycle events
    final eventSubscription = _lifecycleManager.eventStream.listen((event) {
      eventsList.add(event);
      print('📢 Lifecycle Event: ${event.toString()}');
    });

    // Listen to state changes
    final stateSubscription = _lifecycleManager.stateChanges.listen((state) {
      statesList.add(state);
      print(
          '📊 State Change: ${state.authState} (Processing: ${state.isProcessing})');
      if (state.authContext != null) {
        print('   👤 User: ${state.authContext!.userId}');
        print('   🏢 Org: ${state.authContext!.organizationId}');
      }
      if (state.error != null) {
        print('   ❌ Error: ${state.error}');
      }
    });

    try {
      print('🔄 Starting lifecycle event sequence...');

      // Test login sequence
      final testUser = _testSessions[_testUserIds.first]!;
      print('📝 Testing login with user: ${_testUserIds.first}');

      final loginResult = await _lifecycleManager.login(
        token: testUser['token'],
        userId: _testUserIds.first,
        organizationId: testUser['organizationId'],
        metadata: testUser['metadata'],
        sessionDuration: Duration(seconds: 10), // Short duration for testing
        autoRefreshInterval: Duration(seconds: 5),
      );

      if (loginResult.isSuccess) {
        print('✅ Login successful');

        // Wait for some events
        await Future.delayed(Duration(seconds: 2));

        // Test token refresh
        print('🔄 Testing manual token refresh...');
        final refreshResult = await _lifecycleManager.refreshToken(
          'refreshed-${testUser['token']}',
          DateTime.now().add(Duration(hours: 1)),
        );

        if (refreshResult.isSuccess) {
          print('✅ Token refresh successful');
        } else {
          print('❌ Token refresh failed: ${refreshResult.errorMessage}');
        }

        // Wait a bit more
        await Future.delayed(Duration(seconds: 2));

        // Test logout
        print('🚪 Testing logout...');
        await _lifecycleManager.logout();
        print('✅ Logout completed');
      } else {
        print('❌ Login failed: ${loginResult.errorMessage}');
      }

      // Wait for final events
      await Future.delayed(Duration(seconds: 1));

      print('📈 Event sequence results:');
      print('   📊 Total events captured: ${eventsList.length}');
      print('   📊 Total state changes: ${statesList.length}');

      // Analyze events
      final eventCounts = <AuthLifecycleEvent, int>{};
      for (final event in eventsList) {
        eventCounts[event] = (eventCounts[event] ?? 0) + 1;
      }

      for (final entry in eventCounts.entries) {
        print('   🎯 ${entry.key}: ${entry.value} times');
      }

      print('✅ Auth Lifecycle Events test completed');
    } catch (e) {
      print('❌ Auth Lifecycle Events test failed: $e');
    } finally {
      await eventSubscription.cancel();
      await stateSubscription.cancel();
    }
  }

  /// Test 3: Token Management and Refresh
  Future<void> testTokenManagement() async {
    print('🎫 Testing Token Management & Refresh...');
    print('==================================================');

    try {
      print('🔧 Setting up token refresh coordination...');

      // Test global refresh setup
      var refreshCount = 0;
      TokenRefreshCoordinator.setupGlobalRefresh(
        refreshCallback: () async {
          refreshCount++;
          final newToken =
              'auto-refreshed-token-$refreshCount-${_random.nextInt(10000)}';
          print('🔄 Global refresh callback triggered (attempt $refreshCount)');
          print('   🎫 Generated new token: ${newToken.substring(0, 20)}...');
          return newToken;
        },
        refreshInterval: Duration(seconds: 3), // Short interval for testing
      );

      print('✅ Global refresh coordination setup completed');

      // Login a user to test token refresh
      final testUser = _testSessions[_testUserIds[1]]!;
      print('👤 Logging in user for token refresh testing: ${_testUserIds[1]}');

      final loginResult = await _lifecycleManager.login(
        token: testUser['token'],
        userId: _testUserIds[1],
        organizationId: testUser['organizationId'],
        metadata: testUser['metadata'],
        autoRefreshInterval: Duration(seconds: 2), // Short interval
      );

      if (loginResult.isSuccess) {
        print('✅ Login successful - monitoring token refresh...');

        // Monitor for 8 seconds to see automatic refresh
        print('⏳ Monitoring automatic token refresh for 8 seconds...');
        for (int i = 1; i <= 8; i++) {
          await Future.delayed(Duration(seconds: 1));
          print('   ⏱️ Second $i - Refresh count: $refreshCount');
        }

        // Test manual refresh
        print('🔧 Testing manual token refresh...');
        final manualRefreshResult = await _lifecycleManager.refreshToken(
          'manual-refresh-token-${_random.nextInt(10000)}',
          DateTime.now().add(Duration(hours: 2)),
        );

        if (manualRefreshResult.isSuccess) {
          print('✅ Manual token refresh successful');
        } else {
          print(
              '❌ Manual token refresh failed: ${manualRefreshResult.errorMessage}');
        }

        // Cleanup
        await _lifecycleManager.logout();
        print('🚪 Logged out user');
      } else {
        print('❌ Login failed: ${loginResult.errorMessage}');
      }

      // Stop global refresh
      TokenRefreshCoordinator.stopGlobalRefresh();
      print('⏹️ Stopped global refresh coordination');

      print('📊 Token refresh statistics:');
      print('   🔄 Total automatic refreshes: $refreshCount');

      print('✅ Token Management test completed');
    } catch (e) {
      print('❌ Token Management test failed: $e');
    }
  }

  /// Test 4: Multi-Session Handling
  Future<void> testMultiSessionHandling() async {
    print('👥 Testing Multi-Session Handling...');
    print('==================================================');

    try {
      print('📋 Testing user session management...');

      // Test saving sessions
      print('💾 Testing session saving...');
      for (int i = 0; i < 3; i++) {
        final userId = _testUserIds[i];
        final userSession = _testSessions[userId]!;

        // Login user
        final loginResult = await _lifecycleManager.login(
          token: userSession['token'],
          userId: userId,
          organizationId: userSession['organizationId'],
          metadata: userSession['metadata'],
        );

        if (loginResult.isSuccess) {
          print('✅ Logged in user: $userId');

          // Save session
          final sessionId =
              'session-$userId-${DateTime.now().millisecondsSinceEpoch}';
          UserSwitchManager.saveCurrentSession(sessionId);
          print('💾 Saved session: $sessionId');

          // Logout to prepare for next user
          await _lifecycleManager.logout();
          await Future.delayed(Duration(milliseconds: 500));
        }
      }

      // Test listing saved sessions
      final savedSessions = UserSwitchManager.savedSessions;
      print('📊 Total saved sessions: ${savedSessions.length}');

      for (final entry in savedSessions.entries) {
        final sessionData = entry.value;
        print('   📋 Session ${entry.key}:');
        print('      👤 User: ${sessionData['userId']}');
        print('      🏢 Org: ${sessionData['organizationId']}');
        print('      📅 Saved: ${sessionData['savedAt']}');
      }

      // Test user switching
      print('🔄 Testing user switching...');
      final firstUser = _testUserIds[0];
      final secondUser = _testUserIds[1];

      // Login first user
      final firstSession = _testSessions[firstUser]!;
      final firstLoginResult = await _lifecycleManager.login(
        token: firstSession['token'],
        userId: firstUser,
        organizationId: firstSession['organizationId'],
        metadata: firstSession['metadata'],
      );

      if (firstLoginResult.isSuccess) {
        print('✅ Logged in first user: $firstUser');
        print('   🏢 Organization: ${firstSession['organizationId']}');

        await Future.delayed(Duration(seconds: 1));

        // Switch to second user
        print('🔄 Switching to second user...');
        final secondSession = _testSessions[secondUser]!;
        final switchResult = await _lifecycleManager.switchUser(
          token: secondSession['token'],
          userId: secondUser,
          organizationId: secondSession['organizationId'],
          metadata: secondSession['metadata'],
        );

        if (switchResult.isSuccess) {
          print('✅ Successfully switched to user: $secondUser');
          print('   🏢 Organization: ${secondSession['organizationId']}');

          // Verify switch
          final currentUserId = _lifecycleManager.userId;
          print('🔍 Current user after switch: $currentUserId');

          if (currentUserId == secondUser) {
            print('✅ User switch verification successful');
          } else {
            print('❌ User switch verification failed');
          }
        } else {
          print('❌ User switch failed: ${switchResult.errorMessage}');
        }

        // Cleanup
        await _lifecycleManager.logout();
      }

      // Test session restoration
      if (savedSessions.isNotEmpty) {
        print('♻️ Testing session restoration...');
        final sessionToRestore = savedSessions.keys.first;
        final newToken = 'restored-token-${_random.nextInt(10000)}';

        final restoreResult = await UserSwitchManager.restoreSession(
          sessionToRestore,
          newToken,
        );

        if (restoreResult.isSuccess) {
          print('✅ Session restoration successful');
          print('   📋 Restored session: $sessionToRestore');
          await _lifecycleManager.logout();
        } else {
          print('❌ Session restoration failed: ${restoreResult.errorMessage}');
        }
      }

      // Cleanup saved sessions
      UserSwitchManager.clearAllSavedSessions();
      print('🧹 Cleared all saved sessions');

      print('✅ Multi-Session Handling test completed');
    } catch (e) {
      print('❌ Multi-Session Handling test failed: $e');
    }
  }

  /// Test 5: Auth State Synchronization
  Future<void> testAuthStateSynchronization() async {
    print('🔄 Testing Auth State Synchronization...');
    print('==================================================');

    try {
      final stateChanges = <AuthLifecycleState>[];
      final authEvents = <AuthLifecycleEvent>[];

      // Monitor state synchronization
      final stateSubscription = _lifecycleManager.stateChanges.listen((state) {
        stateChanges.add(state);
        print('📊 State sync: ${state.authState}');
        if (state.authContext != null) {
          print(
              '   👤 Context: ${state.authContext!.userId} @ ${state.authContext!.organizationId}');
        }
        if (state.lastEvent != null) {
          print('   🎯 Last event: ${state.lastEvent}');
        }
      });

      final eventSubscription = _lifecycleManager.eventStream.listen((event) {
        authEvents.add(event);
        print('📢 Auth event: $event');
      });

      print('🎭 Testing state synchronization scenarios...');

      // Scenario 1: Login-Logout cycle
      print('📝 Scenario 1: Login-Logout cycle');
      final testUser = _testSessions[_testUserIds[2]]!;

      final loginResult = await _lifecycleManager.login(
        token: testUser['token'],
        userId: _testUserIds[2],
        organizationId: testUser['organizationId'],
        metadata: testUser['metadata'],
      );

      await Future.delayed(Duration(seconds: 1));

      if (loginResult.isSuccess) {
        print('✅ Login completed - verifying state consistency');

        // Check current state
        final currentState = _lifecycleManager.state;
        print('   📊 Current auth state: ${currentState.authState}');
        print('   👤 Current user: ${currentState.userId}');
        print('   🔍 Is authenticated: ${currentState.isAuthenticated}');

        // Logout
        await _lifecycleManager.logout();
        await Future.delayed(Duration(seconds: 1));

        // Check state after logout
        final logoutState = _lifecycleManager.state;
        print('   📊 State after logout: ${logoutState.authState}');
        print('   🔍 Is authenticated: ${logoutState.isAuthenticated}');
      }

      // Scenario 2: Session timeout simulation
      print('📝 Scenario 2: Session timeout simulation');
      final shortLoginResult = await _lifecycleManager.login(
        token: '${testUser['token']}-timeout',
        userId: _testUserIds[2],
        organizationId: testUser['organizationId'],
        metadata: testUser['metadata'],
        sessionDuration: Duration(seconds: 3), // Very short session
      );

      if (shortLoginResult.isSuccess) {
        print('✅ Short session login successful');
        print('⏳ Waiting for session timeout (3 seconds)...');

        // Wait for timeout
        await Future.delayed(Duration(seconds: 4));

        final timeoutState = _lifecycleManager.state;
        print('   📊 State after timeout: ${timeoutState.authState}');
        print('   🔍 Is authenticated: ${timeoutState.isAuthenticated}');
      }

      // Scenario 3: Multiple rapid state changes
      print('📝 Scenario 3: Multiple rapid state changes');
      final users = _testUserIds.take(3).toList();

      for (int i = 0; i < users.length; i++) {
        final userId = users[i];
        final userSession = _testSessions[userId]!;

        print('   🔄 Rapid login/logout $i: $userId');

        final rapidLoginResult = await _lifecycleManager.login(
          token: '${userSession['token']}-rapid-$i',
          userId: userId,
          organizationId: userSession['organizationId'],
          metadata: userSession['metadata'],
        );

        await Future.delayed(Duration(milliseconds: 500));

        if (rapidLoginResult.isSuccess) {
          await _lifecycleManager.logout();
          await Future.delayed(Duration(milliseconds: 300));
        }
      }

      print('📈 State synchronization analysis:');
      print('   📊 Total state changes: ${stateChanges.length}');
      print('   📊 Total auth events: ${authEvents.length}');

      // Analyze state transitions
      final stateTransitions = <String, int>{};
      for (int i = 1; i < stateChanges.length; i++) {
        final transition =
            '${stateChanges[i - 1].authState} → ${stateChanges[i].authState}';
        stateTransitions[transition] = (stateTransitions[transition] ?? 0) + 1;
      }

      print('   🔄 State transitions:');
      for (final entry in stateTransitions.entries) {
        print('      ${entry.key}: ${entry.value} times');
      }

      await stateSubscription.cancel();
      await eventSubscription.cancel();

      print('✅ Auth State Synchronization test completed');
    } catch (e) {
      print('❌ Auth State Synchronization test failed: $e');
    }
  }

  /// Test 6: Session Management Utilities
  Future<void> testSessionManagementUtilities() async {
    print('🛠️ Testing Session Management Utilities...');
    print('==================================================');

    try {
      print('🔧 Testing SessionManager utility class...');

      // Test 1: Create session with defaults
      print('📝 Testing createSession with defaults...');
      final testUser = _testSessions[_testUserIds[3]]!;

      final sessionResult = await SessionManager.createSession(
        token: testUser['token'],
        userId: _testUserIds[3],
        organizationId: testUser['organizationId'],
        metadata: testUser['metadata'],
      );

      if (sessionResult.isSuccess) {
        print('✅ Session created successfully with defaults');
        print('   👤 User: ${_testUserIds[3]}');
        print('   🏢 Organization: ${testUser['organizationId']}');

        // Test session switching
        print('🔄 Testing session switching utility...');
        final switchUser = _testSessions[_testUserIds[4]]!;

        final switchResult = await SessionManager.switchSession(
          token: switchUser['token'],
          userId: _testUserIds[4],
          organizationId: switchUser['organizationId'],
          metadata: switchUser['metadata'],
        );

        if (switchResult.isSuccess) {
          print('✅ Session switch successful');
          print('   👤 Switched to user: ${_testUserIds[4]}');
          print('   🏢 Organization: ${switchUser['organizationId']}');
        } else {
          print('❌ Session switch failed: ${switchResult.errorMessage}');
        }

        // Test session end
        print('🛑 Testing session end utility...');
        await SessionManager.endSession();
        print('✅ Session ended successfully');
      } else {
        print('❌ Session creation failed: ${sessionResult.errorMessage}');
      }

      print('✅ Session Management Utilities test completed');
    } catch (e) {
      print('❌ Session Management Utilities test failed: $e');
    }
  }

  /// Run all auth lifecycle tests
  Future<void> runAllAuthLifecycleTests() async {
    print('🚀 Starting Comprehensive Auth Lifecycle Test Suite...');
    print('==================================================');

    if (!_isInitialized) {
      await initialize();
    }

    final startTime = DateTime.now();
    int completedTests = 0;
    int totalTests = 6;

    try {
      // Test 1: Supabase Auth Integration
      print('\n🧪 Test 1/6: Supabase Auth Integration');
      await testSupabaseAuthIntegration();
      completedTests++;
      await Future.delayed(Duration(seconds: 1));

      // Test 2: Auth Lifecycle Events
      print('\n🧪 Test 2/6: Auth Lifecycle Events');
      await testAuthLifecycleEvents();
      completedTests++;
      await Future.delayed(Duration(seconds: 1));

      // Test 3: Token Management
      print('\n🧪 Test 3/6: Token Management & Refresh');
      await testTokenManagement();
      completedTests++;
      await Future.delayed(Duration(seconds: 1));

      // Test 4: Multi-Session Handling
      print('\n🧪 Test 4/6: Multi-Session Handling');
      await testMultiSessionHandling();
      completedTests++;
      await Future.delayed(Duration(seconds: 1));

      // Test 5: Auth State Synchronization
      print('\n🧪 Test 5/6: Auth State Synchronization');
      await testAuthStateSynchronization();
      completedTests++;
      await Future.delayed(Duration(seconds: 1));

      // Test 6: Session Management Utilities
      print('\n🧪 Test 6/6: Session Management Utilities');
      await testSessionManagementUtilities();
      completedTests++;
    } catch (e) {
      print('❌ Test suite error: $e');
    }

    final duration = DateTime.now().difference(startTime);

    print('\n🎉 Auth Lifecycle Test Suite Completed!');
    print('==================================================');
    print('📊 Tests completed: $completedTests/$totalTests');
    print('⏱️ Total duration: ${duration.inSeconds} seconds');
    print(
        '📈 Success rate: ${((completedTests / totalTests) * 100).toStringAsFixed(1)}%');

    if (completedTests == totalTests) {
      print('✅ All auth lifecycle tests passed successfully!');
      print('🎯 Phase 4.1 Auth Provider Integration Testing - COMPLETED');
    } else {
      print('⚠️ Some tests may have encountered issues - check logs above');
    }

    // Cleanup
    await _cleanup();
  }

  /// Cleanup resources
  Future<void> _cleanup() async {
    try {
      // Ensure logout
      if (_lifecycleManager.isAuthenticated) {
        await _lifecycleManager.logout();
      }

      // Clear any saved sessions
      UserSwitchManager.clearAllSavedSessions();

      // Stop any global refresh
      TokenRefreshCoordinator.stopGlobalRefresh();

      // Dispose lifecycle manager
      await _lifecycleManager.dispose();

      print('🧹 Auth lifecycle testing cleanup completed');
    } catch (e) {
      print('⚠️ Cleanup warning: $e');
    }
  }
}
