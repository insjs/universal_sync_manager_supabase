// Minimal USM PocketBase authentication test

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';

void main() {
  group('USM PocketBase Authentication Tests', () {
    test('USM PocketBase Adapter Connection Test', () async {
      // Create backend configuration
      final backendConfig = SyncBackendConfiguration(
        configId: 'test-connection',
        displayName: 'Test Connection',
        backendType: 'pocketbase',
        baseUrl: 'http://localhost:8090',
        projectId: 'usm_test',
        customSettings: {
          'email': 'a@has.com', // Regular user with collection access
          'password': '12345678',
        },
      );

      // Create adapter
      final adapter = PocketBaseSyncAdapter(
        baseUrl: 'http://localhost:8090',
      );

      print('🔗 Attempting to connect USM PocketBase adapter...');
      print('   Base URL: ${backendConfig.baseUrl}');
      print('   Email: ${backendConfig.customSettings['email']}');

      try {
        // Attempt connection
        final connected = await adapter.connect(backendConfig);

        print('✅ Connection result: $connected');
        print('   Adapter connected: ${adapter.isConnected}');
        print('   Backend type: ${adapter.backendType}');
        print('   Backend info: ${adapter.backendInfo}');

        expect(connected, isTrue);
        expect(adapter.isConnected, isTrue);
      } catch (e) {
        print('❌ Connection failed: $e');
        fail('USM PocketBase adapter connection failed: $e');
      }
    }, timeout: Timeout(Duration(seconds: 30)));
  });
}
