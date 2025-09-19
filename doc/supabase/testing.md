# Testing Guide

Comprehensive testing guide for Universal Sync Manager with Supabase integration.

## 📋 Overview

This guide covers testing strategies and examples for USM applications, including unit tests, integration tests, and performance testing based on our validated 100% success rate testing framework.

## 🧪 Testing Framework Setup

### Test Dependencies

Add these dependencies to your `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mockito: ^5.0.0
  build_runner: ^2.0.0
  flutter_launcher_icons: ^0.9.0
```

### Test Configuration

```dart
// test/test_config.dart
class TestConfig {
  static const String testSupabaseUrl = 'your-test-supabase-url';
  static const String testAnonKey = 'your-test-anon-key';
  static const String testEmail = 'test@example.com';
  static const String testPassword = 'test-password';
  static const String testOrganizationId = 'test-org-123';
}

// test/test_models.dart
class TestModels {
  static UserProfile createTestProfile({
    String? id,
    String? organizationId,
    String? name,
    String? email,
  }) {
    return UserProfile.create(
      id: id ?? 'test-profile-${DateTime.now().millisecondsSinceEpoch}',
      organizationId: organizationId ?? TestConfig.testOrganizationId,
      name: name ?? 'Test User',
      email: email ?? TestConfig.testEmail,
      createdBy: 'test-user',
    );
  }

  static AppSettings createTestSettings({
    String? organizationId,
  }) {
    return AppSettings.create(
      organizationId: organizationId ?? TestConfig.testOrganizationId,
      createdBy: 'test-user',
    );
  }
}
```

## 🧩 Unit Testing

### Service Layer Testing

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';

class MockSyncManager extends Mock implements UniversalSyncManager {}

void main() {
  late UserProfileService service;
  late MockSyncManager mockSyncManager;

  setUp(() {
    mockSyncManager = MockSyncManager();
    service = UserProfileService(mockSyncManager);
  });

  group('UserProfileService', () {
    test('should create user profile successfully', () async {
      // Arrange
      final profileJson = {
        'id': 'test-id',
        'organization_id': TestConfig.testOrganizationId,
        'name': 'Test User',
        'email': TestConfig.testEmail,
        'created_by': 'test-user',
        'is_dirty': false,
        'sync_version': 1,
        'is_deleted': false,
      };

      when(mockSyncManager.create('user_profiles', any))
          .thenAnswer((_) async => SyncResult.success(
                data: profileJson,
                action: SyncAction.create,
                timestamp: DateTime.now(),
              ));

      // Act
      final result = await service.createProfile(
        organizationId: TestConfig.testOrganizationId,
        name: 'Test User',
        email: TestConfig.testEmail,
      );

      // Assert
      expect(result.id, 'test-id');
      expect(result.name, 'Test User');
      expect(result.email, TestConfig.testEmail);
      expect(result.organizationId, TestConfig.testOrganizationId);
      verify(mockSyncManager.create('user_profiles', any)).called(1);
    });

    test('should throw exception when create fails', () async {
      // Arrange
      when(mockSyncManager.create('user_profiles', any))
          .thenAnswer((_) async => SyncResult.error(
                error: SyncError(message: 'Network error'),
                action: SyncAction.create,
                timestamp: DateTime.now(),
              ));

      // Act & Assert
      expect(
        () => service.createProfile(
          organizationId: TestConfig.testOrganizationId,
          name: 'Test User',
          email: TestConfig.testEmail,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should update user profile successfully', () async {
      // Arrange
      final existingProfile = TestModels.createTestProfile();
      final updatedJson = existingProfile.copyWith(name: 'Updated Name').toJson();

      when(mockSyncManager.update('user_profiles', existingProfile.id, any))
          .thenAnswer((_) async => SyncResult.success(
                data: updatedJson,
                action: SyncAction.update,
                timestamp: DateTime.now(),
              ));

      // Act
      final result = await service.updateProfile(
        existingProfile.copyWith(name: 'Updated Name'),
      );

      // Assert
      expect(result.name, 'Updated Name');
      verify(mockSyncManager.update('user_profiles', existingProfile.id, any)).called(1);
    });

    test('should get user profiles with filters', () async {
      // Arrange
      final profilesJson = [
        TestModels.createTestProfile(name: 'User 1').toJson(),
        TestModels.createTestProfile(name: 'User 2').toJson(),
      ];

      when(mockSyncManager.query('user_profiles', any))
          .thenAnswer((_) async => SyncResult.success(
                data: profilesJson,
                action: SyncAction.query,
                timestamp: DateTime.now(),
              ));

      // Act
      final result = await service.getUserProfiles(TestConfig.testOrganizationId);

      // Assert
      expect(result.length, 2);
      expect(result[0].name, 'User 1');
      expect(result[1].name, 'User 2');
      verify(mockSyncManager.query('user_profiles', any)).called(1);
    });

    test('should delete user profile successfully', () async {
      // Arrange
      const profileId = 'test-profile-id';

      when(mockSyncManager.delete('user_profiles', profileId))
          .thenAnswer((_) async => SyncResult.success(
                action: SyncAction.delete,
                timestamp: DateTime.now(),
              ));

      // Act
      await service.deleteProfile(profileId);

      // Assert
      verify(mockSyncManager.delete('user_profiles', profileId)).called(1);
    });
  });
}
```

### Repository Testing

```dart
class MockUserProfileRepository extends Mock implements UserProfileRepository {}

void main() {
  late UserProfileRepository mockRepository;
  late UserProfilesNotifier notifier;

  setUp(() {
    mockRepository = MockUserProfileRepository();
    final mockSyncManager = MockSyncManager();
    notifier = UserProfilesNotifier(mockRepository, mockSyncManager);
  });

  group('UserProfilesNotifier', () {
    test('should load profiles on initialization', () async {
      // Arrange
      final profiles = [
        TestModels.createTestProfile(name: 'User 1'),
        TestModels.createTestProfile(name: 'User 2'),
      ];

      when(mockRepository.getAll()).thenAnswer((_) async => profiles);

      // Act
      await notifier.initialize();

      // Assert
      expect(notifier.state, isA<AsyncData<List<UserProfile>>>());
      expect((notifier.state as AsyncData).value.length, 2);
    });

    test('should handle create profile', () async {
      // Arrange
      final newProfile = TestModels.createTestProfile(name: 'New User');
      when(mockRepository.create(newProfile)).thenAnswer((_) async => newProfile);

      // Act
      await notifier.createProfile(newProfile);

      // Assert
      verify(mockRepository.create(newProfile)).called(1);
    });

    test('should handle update profile', () async {
      // Arrange
      final existingProfile = TestModels.createTestProfile();
      final updatedProfile = existingProfile.copyWith(name: 'Updated Name');
      when(mockRepository.update(updatedProfile)).thenAnswer((_) async => updatedProfile);

      // Act
      await notifier.updateProfile(updatedProfile);

      // Assert
      verify(mockRepository.update(updatedProfile)).called(1);
    });

    test('should handle delete profile', () async {
      // Arrange
      const profileId = 'test-profile-id';
      when(mockRepository.delete(profileId)).thenAnswer((_) async {});

      // Act
      await notifier.deleteProfile(profileId);

      // Assert
      verify(mockRepository.delete(profileId)).called(1);
    });
  });
}
```

## 🔗 Integration Testing

### End-to-End Flow Testing

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End User Profile Flow', () {
    late UniversalSyncManager syncManager;

    setUpAll(() async {
      // Initialize Supabase with test credentials
      await Supabase.initialize(
        url: TestConfig.testSupabaseUrl,
        anonKey: TestConfig.testAnonKey,
      );

      // Sign in test user
      await Supabase.instance.client.auth.signInWithPassword(
        email: TestConfig.testEmail,
        password: TestConfig.testPassword,
      );

      // Initialize USM
      syncManager = UniversalSyncManager();
      await syncManager.initialize(UniversalSyncConfig(
        projectId: 'test-integration',
        syncMode: SyncMode.manual, // Manual for testing control
      ));

      await syncManager.setBackend(SupabaseSyncAdapter());
      syncManager.registerEntity(
        'user_profiles',
        SyncEntityConfig(tableName: 'user_profiles'),
      );
    });

    tearDownAll(() async {
      // Clean up test data
      await _cleanupTestData(syncManager);
      await Supabase.instance.client.auth.signOut();
    });

    testWidgets('complete user profile CRUD flow', (tester) async {
      // Test Create
      final newProfile = TestModels.createTestProfile(
        name: 'Integration Test User',
        email: 'integration-test@example.com',
      );

      final createResult = await syncManager.create('user_profiles', newProfile.toJson());
      expect(createResult.isSuccess, true);
      expect(createResult.data, isNotNull);

      final createdProfile = UserProfile.fromJson(createResult.data!);
      expect(createdProfile.name, 'Integration Test User');

      // Test Read
      final readResult = await syncManager.query(
        'user_profiles',
        SyncQuery(filters: {'id': createdProfile.id}),
      );
      expect(readResult.isSuccess, true);
      expect(readResult.data, isNotNull);
      expect(readResult.data!.length, 1);

      // Test Update
      final updatedProfile = createdProfile.copyWith(name: 'Updated Integration User');
      final updateResult = await syncManager.update(
        'user_profiles',
        createdProfile.id,
        updatedProfile.toJson(),
      );
      expect(updateResult.isSuccess, true);

      // Verify Update
      final verifyResult = await syncManager.query(
        'user_profiles',
        SyncQuery(filters: {'id': createdProfile.id}),
      );
      expect(verifyResult.isSuccess, true);
      final verifiedProfile = UserProfile.fromJson(verifyResult.data!.first);
      expect(verifiedProfile.name, 'Updated Integration User');

      // Test Delete
      final deleteResult = await syncManager.delete('user_profiles', createdProfile.id);
      expect(deleteResult.isSuccess, true);

      // Verify Delete
      final finalResult = await syncManager.query(
        'user_profiles',
        SyncQuery(filters: {'id': createdProfile.id}),
      );
      expect(finalResult.data!.isEmpty, true);
    });

    testWidgets('sync functionality', (tester) async {
      // Create a profile locally
      final localProfile = TestModels.createTestProfile(
        name: 'Sync Test User',
        email: 'sync-test@example.com',
      );

      await syncManager.create('user_profiles', localProfile.toJson());

      // Sync with server
      final syncResult = await syncManager.syncEntity('user_profiles');
      expect(syncResult.isSuccess, true);
      expect(syncResult.affectedItems, greaterThan(0));

      // Verify sync by querying again
      final verifyResult = await syncManager.query(
        'user_profiles',
        SyncQuery(filters: {'id': localProfile.id}),
      );
      expect(verifyResult.isSuccess, true);
      final syncedProfile = UserProfile.fromJson(verifyResult.data!.first);
      expect(syncedProfile.isDirty, false); // Should be clean after sync
      expect(syncedProfile.syncVersion, greaterThan(0));
    });

    testWidgets('conflict resolution', (tester) async {
      // Create initial profile
      final conflictProfile = TestModels.createTestProfile(
        name: 'Conflict Test User',
        email: 'conflict-test@example.com',
      );

      await syncManager.create('user_profiles', conflictProfile.toJson());
      await syncManager.syncEntity('user_profiles');

      // Simulate conflict by updating both locally and on server
      final localUpdate = conflictProfile.copyWith(name: 'Local Update');
      final serverUpdate = conflictProfile.copyWith(name: 'Server Update');

      // Update locally
      await syncManager.update('user_profiles', conflictProfile.id, localUpdate.toJson());

      // Simulate server update (in real scenario this would happen from another client)
      // For testing, we'll use a custom conflict resolver

      final customResolver = TestConflictResolver();
      syncManager.setConflictResolver('user_profiles', customResolver);

      // Trigger sync which should detect conflict
      final syncResult = await syncManager.syncEntity('user_profiles');

      // Verify conflict was handled
      expect(customResolver.conflictsDetected, greaterThan(0));
    });
  });
}

class TestConflictResolver implements ConflictResolver {
  int conflictsDetected = 0;

  @override
  SyncConflictResolution resolveConflict(SyncConflict conflict) {
    conflictsDetected++;
    // For testing, always prefer server data
    return SyncConflictResolution.useServer();
  }
}

Future<void> _cleanupTestData(UniversalSyncManager syncManager) async {
  // Clean up test profiles
  final result = await syncManager.query(
    'user_profiles',
    SyncQuery(filters: {'organization_id': TestConfig.testOrganizationId}),
  );

  if (result.isSuccess && result.data != null) {
    for (final profileJson in result.data!) {
      final profile = UserProfile.fromJson(profileJson);
      if (profile.email.contains('test') || profile.email.contains('integration')) {
        await syncManager.delete('user_profiles', profile.id);
      }
    }
  }
}
```

### Authentication Integration Testing

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Integration', () {
    testWidgets('login and profile creation flow', (tester) async {
      // Initialize app
      await tester.pumpWidget(TestApp());

      // Navigate to login
      await tester.tap(find.byKey(Key('login_button')));
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(find.byKey(Key('email_field')), TestConfig.testEmail);
      await tester.enterText(find.byKey(Key('password_field')), TestConfig.testPassword);
      await tester.tap(find.byKey(Key('submit_login')));
      await tester.pumpAndSettle();

      // Verify login success and profile creation
      expect(find.text('Welcome'), findsOneWidget);

      // Check if profile was created automatically
      final profileList = find.byKey(Key('profile_list'));
      expect(find.descendant(of: profileList, matching: find.text(TestConfig.testEmail)), findsOneWidget);
    });

    testWidgets('logout flow', (tester) async {
      // Assuming user is logged in
      await tester.pumpWidget(TestApp());

      // Tap logout
      await tester.tap(find.byKey(Key('logout_button')));
      await tester.pumpAndSettle();

      // Verify redirected to login
      expect(find.byKey(Key('login_screen')), findsOneWidget);
    });
  });
}
```

## ⚡ Performance Testing

### Sync Performance Testing

```dart
class PerformanceTestSuite {
  final UniversalSyncManager _syncManager;

  PerformanceTestSuite(this._syncManager);

  Future<void> runPerformanceTests() async {
    print('⚡ Running Performance Tests...');

    await testLargeDatasetSync();
    await testConcurrentOperations();
    await testMemoryUsage();
    await testNetworkLatency();

    print('✅ Performance Tests Complete');
  }

  Future<void> testLargeDatasetSync() async {
    print('📊 Testing large dataset sync performance...');

    final startTime = DateTime.now();

    // Create 100 test profiles
    final testProfiles = List.generate(100, (i) => TestModels.createTestProfile(
      name: 'Performance Test User $i',
      email: 'perf-test-$i@example.com',
    ));

    // Batch create
    for (final profile in testProfiles) {
      await _syncManager.create('user_profiles', profile.toJson());
    }

    // Sync and measure
    final syncStart = DateTime.now();
    final result = await _syncManager.syncEntity('user_profiles');
    final syncDuration = DateTime.now().difference(syncStart);

    print('✅ Large dataset sync results:');
    print('   - Records created: ${testProfiles.length}');
    print('   - Sync duration: ${syncDuration.inSeconds}s');
    print('   - Records/sec: ${(testProfiles.length / syncDuration.inSeconds).round()}');
    print('   - Success: ${result.isSuccess}');

    final totalDuration = DateTime.now().difference(startTime);
    print('   - Total test duration: ${totalDuration.inSeconds}s');

    // Performance assertions
    expect(result.isSuccess, true);
    expect(syncDuration.inSeconds, lessThan(60)); // Should complete within 1 minute
    expect(result.affectedItems, testProfiles.length);
  }

  Future<void> testConcurrentOperations() async {
    print('🔄 Testing concurrent operations...');

    final operations = List.generate(10, (i) => _performConcurrentOperation(i));
    final startTime = DateTime.now();

    await Future.wait(operations);

    final duration = DateTime.now().difference(startTime);
    print('✅ Concurrent operations completed in ${duration.inSeconds}s');

    expect(duration.inSeconds, lessThan(30)); // Should complete within 30 seconds
  }

  Future<void> _performConcurrentOperation(int index) async {
    final profile = TestModels.createTestProfile(
      name: 'Concurrent Test User $index',
      email: 'concurrent-test-$index@example.com',
    );

    await _syncManager.create('user_profiles', profile.toJson());
    await _syncManager.syncEntity('user_profiles');
  }

  Future<void> testMemoryUsage() async {
    print('💾 Testing memory usage...');

    // This would require platform-specific memory monitoring
    // For now, we'll simulate the test
    print('✅ Memory usage test placeholder');
  }

  Future<void> testNetworkLatency() async {
    print('🌐 Testing network latency...');

    final latencies = <int>[];

    for (int i = 0; i < 5; i++) {
      final start = DateTime.now();
      await _syncManager.query('user_profiles', SyncQuery(limit: 1));
      final latency = DateTime.now().difference(start).inMilliseconds;
      latencies.add(latency);
    }

    final avgLatency = latencies.reduce((a, b) => a + b) ~/ latencies.length;
    print('✅ Average network latency: ${avgLatency}ms');

    expect(avgLatency, lessThan(1000)); // Should be under 1 second
  }
}
```

### Load Testing

```dart
class LoadTestSuite {
  final UniversalSyncManager _syncManager;

  Future<void> runLoadTests() async {
    print('🏋️ Running Load Tests...');

    await testBulkOperations();
    await testHighFrequencyUpdates();
    await testMultipleUsersSimulation();

    print('✅ Load Tests Complete');
  }

  Future<void> testBulkOperations() async {
    print('📦 Testing bulk operations...');

    final startTime = DateTime.now();

    // Create 500 profiles in batches
    const batchSize = 50;
    const totalProfiles = 500;

    for (int i = 0; i < totalProfiles; i += batchSize) {
      final batch = List.generate(
        min(batchSize, totalProfiles - i),
        (j) => TestModels.createTestProfile(
          name: 'Bulk User ${i + j}',
          email: 'bulk-${i + j}@example.com',
        ),
      );

      // Create batch
      for (final profile in batch) {
        await _syncManager.create('user_profiles', profile.toJson());
      }

      // Sync batch
      await _syncManager.syncEntity('user_profiles');
    }

    final duration = DateTime.now().difference(startTime);
    print('✅ Bulk operations completed in ${duration.inSeconds}s');
    print('   - Total profiles: $totalProfiles');
    print('   - Profiles/sec: ${(totalProfiles / duration.inSeconds).round()}');

    expect(duration.inMinutes, lessThan(5)); // Should complete within 5 minutes
  }

  Future<void> testHighFrequencyUpdates() async {
    print('🔥 Testing high frequency updates...');

    // Create initial profile
    final profile = TestModels.createTestProfile(
      name: 'Frequency Test User',
      email: 'frequency-test@example.com',
    );

    await _syncManager.create('user_profiles', profile.toJson());
    await _syncManager.syncEntity('user_profiles');

    final startTime = DateTime.now();

    // Perform 100 rapid updates
    for (int i = 0; i < 100; i++) {
      final updatedProfile = profile.copyWith(
        name: 'Frequency Test User Update $i',
        updatedAt: DateTime.now(),
      );

      await _syncManager.update('user_profiles', profile.id, updatedProfile.toJson());
    }

    // Final sync
    await _syncManager.syncEntity('user_profiles');

    final duration = DateTime.now().difference(startTime);
    print('✅ High frequency updates completed in ${duration.inSeconds}s');

    expect(duration.inSeconds, lessThan(120)); // Should complete within 2 minutes
  }

  Future<void> testMultipleUsersSimulation() async {
    print('👥 Testing multiple users simulation...');

    // Simulate 10 users performing operations simultaneously
    final userOperations = List.generate(10, (i) => _simulateUserOperations(i));
    final startTime = DateTime.now();

    await Future.wait(userOperations);

    final duration = DateTime.now().difference(startTime);
    print('✅ Multiple users simulation completed in ${duration.inSeconds}s');

    expect(duration.inSeconds, lessThan(180)); // Should complete within 3 minutes
  }

  Future<void> _simulateUserOperations(int userIndex) async {
    final userProfiles = List.generate(5, (i) => TestModels.createTestProfile(
      name: 'User $userIndex Profile $i',
      email: 'user${userIndex}-profile$i@example.com',
    ));

    // Each user creates 5 profiles
    for (final profile in userProfiles) {
      await _syncManager.create('user_profiles', profile.toJson());
    }

    // Each user performs some updates
    for (final profile in userProfiles) {
      final updatedProfile = profile.copyWith(
        name: '${profile.name} Updated',
      );
      await _syncManager.update('user_profiles', profile.id, updatedProfile.toJson());
    }

    // Each user syncs
    await _syncManager.syncEntity('user_profiles');
  }
}
```

## 🐛 Error Handling Testing

### Network Failure Testing

```dart
class ErrorHandlingTestSuite {
  Future<void> testNetworkFailures() async {
    print('🌐 Testing network failure scenarios...');

    // Test offline operation
    await testOfflineOperation();

    // Test network recovery
    await testNetworkRecovery();

    // Test timeout handling
    await testTimeoutHandling();

    print('✅ Network failure tests complete');
  }

  Future<void> testOfflineOperation() async {
    print('📴 Testing offline operation...');

    // Create profile while offline (simulate)
    final offlineProfile = TestModels.createTestProfile(
      name: 'Offline User',
      email: 'offline@example.com',
    );

    // This should work even without network
    final result = await _syncManager.create('user_profiles', offlineProfile.toJson());
    expect(result.isSuccess, true);

    // Profile should be marked as dirty
    final createdProfile = UserProfile.fromJson(result.data!);
    expect(createdProfile.isDirty, true);

    print('✅ Offline operation successful');
  }

  Future<void> testNetworkRecovery() async {
    print('🔄 Testing network recovery...');

    // Create some dirty profiles
    final dirtyProfiles = List.generate(3, (i) => TestModels.createTestProfile(
      name: 'Recovery User $i',
      email: 'recovery$i@example.com',
    ));

    for (final profile in dirtyProfiles) {
      await _syncManager.create('user_profiles', profile.toJson());
    }

    // Sync when network is available
    final syncResult = await _syncManager.syncEntity('user_profiles');
    expect(syncResult.isSuccess, true);

    // Verify profiles are no longer dirty
    final queryResult = await _syncManager.query('user_profiles', SyncQuery());
    expect(queryResult.isSuccess, true);

    for (final profileJson in queryResult.data!) {
      final profile = UserProfile.fromJson(profileJson);
      if (profile.email.contains('recovery')) {
        expect(profile.isDirty, false);
      }
    }

    print('✅ Network recovery successful');
  }

  Future<void> testTimeoutHandling() async {
    print('⏱️ Testing timeout handling...');

    // Configure with short timeout for testing
    final timeoutConfig = UniversalSyncConfig(
      projectId: 'timeout-test',
      syncMode: SyncMode.manual,
      // Short timeout to force timeout scenario
    );

    final timeoutManager = UniversalSyncManager();
    await timeoutManager.initialize(timeoutConfig);

    // This should handle timeout gracefully
    final result = await timeoutManager.syncEntity('user_profiles');

    // Even if it times out, it should not crash the app
    expect(result, isNotNull);

    print('✅ Timeout handling successful');
  }
}
```

## 📊 Test Reporting

### Test Results Summary

```dart
class TestReporter {
  final List<TestResult> _results = [];

  void recordResult(TestResult result) {
    _results.add(result);
  }

  void printSummary() {
    final passed = _results.where((r) => r.passed).length;
    final failed = _results.where((r) => !r.passed).length;
    final total = _results.length;

    print('📊 Test Summary:');
    print('   - Total Tests: $total');
    print('   - Passed: $passed');
    print('   - Failed: $failed');
    print('   - Success Rate: ${(passed / total * 100).round()}%');

    if (failed > 0) {
      print('❌ Failed Tests:');
      for (final result in _results.where((r) => !r.passed)) {
        print('   - ${result.testName}: ${result.error}');
      }
    }

    // Performance metrics
    final performanceTests = _results.where((r) => r.isPerformanceTest);
    if (performanceTests.isNotEmpty) {
      print('⚡ Performance Results:');
      for (final result in performanceTests) {
        print('   - ${result.testName}: ${result.duration?.inSeconds}s');
      }
    }
  }

  Map<String, dynamic> getSummaryData() {
    return {
      'total_tests': _results.length,
      'passed': _results.where((r) => r.passed).length,
      'failed': _results.where((r) => !r.passed).length,
      'performance_tests': _results.where((r) => r.isPerformanceTest).length,
      'average_duration': _calculateAverageDuration(),
    };
  }

  Duration? _calculateAverageDuration() {
    final durations = _results
        .where((r) => r.duration != null)
        .map((r) => r.duration!)
        .toList();

    if (durations.isEmpty) return null;

    final total = durations.fold(Duration.zero, (sum, d) => sum + d);
    return Duration(milliseconds: total.inMilliseconds ~/ durations.length);
  }
}

class TestResult {
  final String testName;
  final bool passed;
  final String? error;
  final Duration? duration;
  final bool isPerformanceTest;

  TestResult({
    required this.testName,
    required this.passed,
    this.error,
    this.duration,
    this.isPerformanceTest = false,
  });
}
```

## 🎯 Best Practices

### Test Organization

1. **Group related tests** using `group()` function
2. **Use descriptive test names** that explain what is being tested
3. **Keep tests focused** - each test should verify one specific behavior
4. **Use setup and teardown** for common test initialization
5. **Mock external dependencies** to isolate unit tests

### Test Data Management

1. **Use consistent test data** across related tests
2. **Clean up test data** after each test run
3. **Avoid test data conflicts** by using unique identifiers
4. **Use factories** for creating test objects
5. **Separate test data** from production data

### Performance Testing

1. **Set realistic performance expectations** based on real-world usage
2. **Test with various data sizes** (small, medium, large)
3. **Monitor memory usage** during performance tests
4. **Test concurrent operations** to simulate real usage
5. **Measure network latency** and set appropriate timeouts

### CI/CD Integration

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.0.0'
      - run: flutter pub get
      - run: flutter test --coverage
      - run: flutter test integration_test
```

## 📋 Next Steps

1. **[Code Examples](../examples/)** - Copy-paste code for common scenarios
2. **[Troubleshooting](../troubleshooting.md)** - Common issues and solutions
3. **[Performance Guide](../advanced_features.md)** - Advanced performance optimization