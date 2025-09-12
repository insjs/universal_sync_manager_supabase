/// Comprehensive Test Suite for Task 1.3: Platform Abstraction Layer
///
/// Tests all platform-specific implementations and factory functionality.
library task_1_3_platform_abstraction_test;

import 'dart:async';
import '../lib/src/interfaces/usm_sync_platform_service.dart';
import '../lib/src/platform/usm_platform_service_factory.dart';
import '../lib/src/platform/usm_windows_platform_service.dart';
import '../lib/src/platform/usm_mobile_platform_service.dart';

/// Simple test framework for validation
class TestRunner {
  static int _passed = 0;
  static int _failed = 0;
  static final List<String> _failures = [];

  static void test(String description, Function() testFunction) {
    try {
      testFunction();
      _passed++;
      print('✓ $description');
    } catch (e) {
      _failed++;
      _failures.add('✗ $description: $e');
      print('✗ $description: $e');
    }
  }

  static Future<void> testAsync(
      String description, Future<void> Function() testFunction) async {
    try {
      await testFunction();
      _passed++;
      print('✓ $description');
    } catch (e) {
      _failed++;
      _failures.add('✗ $description: $e');
      print('✗ $description: $e');
    }
  }

  static void expect(dynamic actual, dynamic expected, [String? message]) {
    if (actual != expected) {
      throw Exception(message ?? 'Expected $expected, but got $actual');
    }
  }

  static void expectType<T>(dynamic actual, [String? message]) {
    if (actual is! T) {
      throw Exception(
          message ?? 'Expected type $T, but got ${actual.runtimeType}');
    }
  }

  static void expectNotNull(dynamic actual, [String? message]) {
    if (actual == null) {
      throw Exception(message ?? 'Expected non-null value, but got null');
    }
  }

  static void expectTrue(bool actual, [String? message]) {
    if (!actual) {
      throw Exception(message ?? 'Expected true, but got false');
    }
  }

  static void expectFalse(bool actual, [String? message]) {
    if (actual) {
      throw Exception(message ?? 'Expected false, but got true');
    }
  }

  static void summary() {
    print('\n=== Test Summary ===');
    print('Passed: $_passed');
    print('Failed: $_failed');
    print('Total: ${_passed + _failed}');

    if (_failures.isNotEmpty) {
      print('\nFailures:');
      for (final failure in _failures) {
        print(failure);
      }
    }

    print(_failed == 0 ? '\n🎉 All tests passed!' : '\n❌ Some tests failed');
  }
}

void main() async {
  print('Running Task 1.3: Platform Abstraction Layer Tests');
  print('====================================================');

  // Test 1: Platform Service Factory Tests
  print('\n1. Platform Service Factory Tests');
  print('----------------------------------');

  TestRunner.test('should detect current platform type', () {
    final platformType = SyncPlatformServiceFactory.getCurrentPlatform();
    TestRunner.expectType<SyncPlatformType>(platformType);
    TestRunner.expectTrue(platformType != SyncPlatformType.unknown,
        'Platform should be detected, not unknown');
  });

  TestRunner.test('should create platform service for current platform', () {
    final service = SyncPlatformServiceFactory.createForCurrentPlatform();
    TestRunner.expectType<ISyncPlatformService>(service);
    TestRunner.expectType<SyncPlatformType>(service.platformType);
  });

  TestRunner.test('should create Windows platform service', () {
    final service =
        SyncPlatformServiceFactory.createForPlatform(SyncPlatformType.windows);
    TestRunner.expectType<WindowsSyncPlatformService>(service);
    TestRunner.expect(service.platformType, SyncPlatformType.windows);
  });

  TestRunner.test('should create mobile platform service for Android', () {
    final service =
        SyncPlatformServiceFactory.createForPlatform(SyncPlatformType.android);
    TestRunner.expectType<MobileSyncPlatformService>(service);
    TestRunner.expectTrue(
        service.platformType == SyncPlatformType.android ||
            service.platformType == SyncPlatformType.ios,
        'Mobile service should be Android or iOS');
  });

  TestRunner.test('should provide platform capabilities', () {
    final capabilities = SyncPlatformServiceFactory.getPlatformCapabilities();
    TestRunner.expectType<Map<String, dynamic>>(capabilities);
    TestRunner.expectType<String>(capabilities['platformType']);
    TestRunner.expectType<bool>(capabilities['supportsBackgroundSync']);
    TestRunner.expectType<bool>(capabilities['supportsBatteryManagement']);
    TestRunner.expectType<bool>(capabilities['supportsFileSystem']);
    TestRunner.expectType<int>(capabilities['recommendedSyncInterval']);
    TestRunner.expectType<Map<String, dynamic>>(capabilities['optimizations']);
    TestRunner.expectType<String>(capabilities['detectedAt']);
  });

  // Test 2: Platform Type Extension Tests
  print('\n2. Platform Type Extension Tests');
  print('---------------------------------');

  TestRunner.test('should correctly identify mobile platforms', () {
    TestRunner.expectTrue(SyncPlatformType.android.isMobile);
    TestRunner.expectTrue(SyncPlatformType.ios.isMobile);
    TestRunner.expectFalse(SyncPlatformType.windows.isMobile);
    TestRunner.expectFalse(SyncPlatformType.web.isMobile);
  });

  TestRunner.test('should correctly identify desktop platforms', () {
    TestRunner.expectTrue(SyncPlatformType.windows.isDesktop);
    TestRunner.expectTrue(SyncPlatformType.macos.isDesktop);
    TestRunner.expectTrue(SyncPlatformType.linux.isDesktop);
    TestRunner.expectFalse(SyncPlatformType.android.isDesktop);
    TestRunner.expectFalse(SyncPlatformType.web.isDesktop);
  });

  TestRunner.test('should provide correct display names', () {
    TestRunner.expect(SyncPlatformType.android.displayName, 'Android');
    TestRunner.expect(SyncPlatformType.ios.displayName, 'iOS');
    TestRunner.expect(SyncPlatformType.windows.displayName, 'Windows');
    TestRunner.expect(SyncPlatformType.web.displayName, 'Web');
  });

  // Test 3: Windows Platform Service Tests
  print('\n3. Windows Platform Service Tests');
  print('----------------------------------');

  final windowsService = WindowsSyncPlatformService();

  TestRunner.test('should have correct platform type and properties', () {
    TestRunner.expect(windowsService.platformType, SyncPlatformType.windows);
    TestRunner.expectType<String>(windowsService.platformVersion);
    TestRunner.expectFalse(windowsService.isInitialized);
  });

  await TestRunner.testAsync('should initialize successfully', () async {
    final result = await windowsService.initialize();
    TestRunner.expectTrue(result);
    TestRunner.expectTrue(windowsService.isInitialized);
    TestRunner.expectType<String>(windowsService.documentsPath);
    TestRunner.expectType<String>(windowsService.cachePath);
    TestRunner.expectType<String>(windowsService.tempPath);
  });

  await TestRunner.testAsync('should provide network information', () async {
    final networkInfo = await windowsService.getNetworkInfo();
    TestRunner.expectType<PlatformNetworkInfo>(networkInfo);
    TestRunner.expectType<NetworkConnectionType>(networkInfo.connectionType);
    TestRunner.expectType<NetworkQuality>(networkInfo.quality);
    TestRunner.expectType<bool>(networkInfo.isMetered);
  });

  await TestRunner.testAsync('should provide battery information', () async {
    final batteryInfo = await windowsService.getBatteryInfo();
    TestRunner.expectType<PlatformBatteryInfo>(batteryInfo);
    TestRunner.expectType<bool>(batteryInfo.isCharging);
    TestRunner.expectType<bool>(batteryInfo.isLowPowerMode);
    TestRunner.expectType<BatteryOptimizationLevel>(
        batteryInfo.recommendedOptimization);
  });

  await TestRunner.testAsync('should provide database configuration', () async {
    final dbConfig = await windowsService.getDatabaseConfig('test-org');
    TestRunner.expectType<PlatformDatabaseConfig>(dbConfig);
    TestRunner.expectType<String>(dbConfig.databasePath);
    TestRunner.expectType<int>(dbConfig.maxConnections);
    TestRunner.expectType<bool>(dbConfig.enableWAL);
    TestRunner.expectType<Map<String, dynamic>>(
        dbConfig.platformSpecificOptions);
  });

  await TestRunner.testAsync('should perform file operations', () async {
    const testPath = 'test-file.txt';
    const testContent = 'Hello, Windows!';

    // Test write
    final writeResult = await windowsService.writeFile(testPath, testContent);
    TestRunner.expectTrue(writeResult.success);

    // Test exists
    final existsResult = await windowsService.fileExists(testPath);
    TestRunner.expectTrue(existsResult.success);
    TestRunner.expectTrue(existsResult.data as bool);

    // Test read
    final readResult = await windowsService.readFile(testPath);
    TestRunner.expectTrue(readResult.success);
    TestRunner.expect(readResult.data, testContent);

    // Test delete
    final deleteResult = await windowsService.deleteFile(testPath);
    TestRunner.expectTrue(deleteResult.success);
  });

  await TestRunner.testAsync('should handle secure storage', () async {
    const key = 'test-key';
    const value = 'test-value';

    // Store secure value
    final storeResult = await windowsService.storeSecureValue(key, value);
    TestRunner.expectTrue(storeResult);

    // Retrieve secure value
    final retrievedValue = await windowsService.getSecureValue(key);
    TestRunner.expect(retrievedValue, value);

    // Delete secure value
    final deleteResult = await windowsService.deleteSecureValue(key);
    TestRunner.expectTrue(deleteResult);
  });

  // Test 4: Mobile Platform Service Tests
  print('\n4. Mobile Platform Service Tests');
  print('---------------------------------');

  final mobileService = MobileSyncPlatformService();

  TestRunner.test('should have correct platform type and properties', () {
    TestRunner.expectTrue(
        mobileService.platformType == SyncPlatformType.android ||
            mobileService.platformType == SyncPlatformType.ios,
        'Mobile service should be Android or iOS');
    TestRunner.expectType<String>(mobileService.platformVersion);
    TestRunner.expectFalse(mobileService.isInitialized);
  });

  await TestRunner.testAsync('should initialize successfully', () async {
    final result = await mobileService.initialize();
    TestRunner.expectTrue(result);
    TestRunner.expectTrue(mobileService.isInitialized);
  });

  await TestRunner.testAsync(
      'should provide mobile-optimized database configuration', () async {
    final dbConfig = await mobileService.getDatabaseConfig('test-org');
    TestRunner.expectType<PlatformDatabaseConfig>(dbConfig);
    TestRunner.expect(
        dbConfig.maxConnections, 1); // Mobile uses single connection
    TestRunner.expect(dbConfig.cacheSize, 1000); // Smaller cache for mobile
  });

  await TestRunner.testAsync('should provide mobile-specific optimizations',
      () async {
    final recommendations =
        await mobileService.getOptimizationRecommendations();
    TestRunner.expectType<Map<String, dynamic>>(recommendations);
    TestRunner.expect(
        recommendations['batchSize'], 'small'); // Mobile prefers small batches
    TestRunner.expect(
        recommendations['compressionLevel'], 'high'); // Save bandwidth

    final platformSpecific =
        recommendations['platformSpecific'] as Map<String, dynamic>;
    TestRunner.expectFalse(
        platformSpecific['useMemoryCache'] as bool); // Conserve memory
    TestRunner.expect(platformSpecific['maxConnections'], 1);
  });

  // Test 5: Data Model Tests
  print('\n5. Data Model Tests');
  print('-------------------');

  TestRunner.test('PlatformNetworkInfo should work correctly', () {
    const networkInfo = PlatformNetworkInfo(
      connectionType: NetworkConnectionType.wifi,
      quality: NetworkQuality.good,
      isMetered: false,
      signalStrength: 0.8,
      networkName: 'Test Network',
    );

    TestRunner.expectTrue(networkInfo.isConnected);
    TestRunner.expectTrue(networkInfo.isHighQuality);
    TestRunner.expectTrue(networkInfo.isSuitableForSync);

    final map = networkInfo.toMap();
    TestRunner.expectType<Map<String, dynamic>>(map);
    TestRunner.expect(map['connectionType'], 'wifi');
    TestRunner.expect(map['quality'], 'good');

    final recreated = PlatformNetworkInfo.fromMap(map);
    TestRunner.expect(recreated.connectionType, networkInfo.connectionType);
    TestRunner.expect(recreated.quality, networkInfo.quality);
  });

  TestRunner.test('PlatformBatteryInfo should work correctly', () {
    const batteryInfo = PlatformBatteryInfo(
      batteryLevel: 0.75,
      isCharging: false,
      isLowPowerMode: false,
      recommendedOptimization: BatteryOptimizationLevel.moderate,
    );

    TestRunner.expectTrue(batteryInfo.isBatteryOptimal);

    final map = batteryInfo.toMap();
    TestRunner.expectType<Map<String, dynamic>>(map);
    TestRunner.expect(map['batteryLevel'], 0.75);
    TestRunner.expectFalse(map['isCharging'] as bool);

    final recreated = PlatformBatteryInfo.fromMap(map);
    TestRunner.expect(recreated.batteryLevel, batteryInfo.batteryLevel);
    TestRunner.expect(recreated.isCharging, batteryInfo.isCharging);
  });

  TestRunner.test('FileOperationResult should work correctly', () {
    final successResult = FileOperationResult.success(
      operationType: FileOperationType.read,
      data: 'test data',
    );

    TestRunner.expectTrue(successResult.success);
    TestRunner.expect(successResult.error, null);
    TestRunner.expect(successResult.data, 'test data');

    final failureResult = FileOperationResult.failure(
      operationType: FileOperationType.write,
      error: 'Write failed',
    );

    TestRunner.expectFalse(failureResult.success);
    TestRunner.expect(failureResult.error, 'Write failed');
    TestRunner.expect(failureResult.data, null);
  });

  // Test 6: Integration Tests
  print('\n6. Integration Tests');
  print('--------------------');

  await TestRunner.testAsync('should integrate platform services with factory',
      () async {
    final service = SyncPlatformServiceFactory.createForCurrentPlatform();

    // Initialize service
    final initResult = await service.initialize();
    TestRunner.expectTrue(initResult);

    try {
      // Test network capabilities
      final networkInfo = await service.getNetworkInfo();
      TestRunner.expectType<PlatformNetworkInfo>(networkInfo);

      // Test database configuration
      final dbConfig = await service.getDatabaseConfig('integration-test');
      TestRunner.expectType<PlatformDatabaseConfig>(dbConfig);

      // Test optimization recommendations
      final optimizations = await service.getOptimizationRecommendations();
      TestRunner.expectType<Map<String, dynamic>>(optimizations);

      // Test diagnostic capabilities
      final report = await service.getDiagnosticReport();
      TestRunner.expectType<Map<String, dynamic>>(report);
    } finally {
      await service.dispose();
    }
  });

  TestRunner.test('should provide consistent platform detection', () {
    final platformType1 = SyncPlatformServiceFactory.getCurrentPlatform();
    final platformType2 = SyncPlatformServiceFactory.getCurrentPlatform();

    TestRunner.expect(platformType1, platformType2);

    final service1 = SyncPlatformServiceFactory.createForCurrentPlatform();
    final service2 = SyncPlatformServiceFactory.createForCurrentPlatform();

    TestRunner.expect(service1.platformType, service2.platformType);
  });

  // Cleanup
  if (windowsService.isInitialized) {
    await windowsService.dispose();
  }
  if (mobileService.isInitialized) {
    await mobileService.dispose();
  }

  // Print test summary
  TestRunner.summary();
}
