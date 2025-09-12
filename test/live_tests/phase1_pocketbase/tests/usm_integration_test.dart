// Simple USM Integration Test to validate framework components work

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';

void main() {
  group('USM Integration Tests', () {
    test('USM Components Can Be Instantiated', () {
      // Test that USM configuration classes can be created
      final backendConfig = SyncBackendConfiguration(
        configId: 'test-backend',
        displayName: 'Test Backend',
        backendType: 'pocketbase',
        baseUrl: 'http://localhost:8090',
        projectId: 'test-project',
      );

      expect(backendConfig.configId, equals('test-backend'));
      expect(backendConfig.backendType, equals('pocketbase'));
      expect(backendConfig.baseUrl, equals('http://localhost:8090'));

      // Test authentication configuration
      final authConfig = SyncAuthConfiguration.usernamePassword(
        'xinzqr@gmail.com',
        '12345678',
      );

      expect(authConfig.credentials['username'], equals('xinzqr@gmail.com'));
      expect(authConfig.credentials['password'], equals('12345678'));

      print('✅ USM Configuration classes instantiated successfully');
    });

    test('USM PocketBase Adapter Can Be Created', () {
      // Test that the PocketBase adapter can be instantiated
      final adapter = PocketBaseSyncAdapter(
        baseUrl: 'http://localhost:8090',
      );

      expect(adapter, isNotNull);
      expect(adapter, isA<ISyncBackendAdapter>());
      expect(adapter.backendType, equals('pocketbase'));

      print('✅ PocketBase Sync Adapter created successfully');
    });

    test('USM Sync Service Can Be Created', () {
      // Test that the sync service can be instantiated
      final adapter = PocketBaseSyncAdapter(
        baseUrl: 'http://localhost:8090',
      );
      final syncService = UniversalSyncOperationService(
        backendAdapter: adapter,
      );

      expect(syncService, isNotNull);
      expect(syncService, isA<UniversalSyncOperationService>());

      print('✅ Universal Sync Operation Service created successfully');
    });
  });
}
