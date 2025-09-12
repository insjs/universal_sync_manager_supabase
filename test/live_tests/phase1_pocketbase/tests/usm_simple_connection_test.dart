// Simple USM PocketBase connection test without authentication

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';

void main() {
  group('USM PocketBase Simple Connection Tests', () {
    test('USM PocketBase Adapter Health Check Only', () async {
      // Create backend configuration without authentication
      final backendConfig = SyncBackendConfiguration(
        configId: 'test-connection-simple',
        displayName: 'Test Connection Simple',
        backendType: 'pocketbase',
        baseUrl: 'http://localhost:8090',
        projectId: 'usm_test',
        // No authentication - just test the health check
      );

      // Create adapter
      final adapter = PocketBaseSyncAdapter(
        baseUrl: 'http://localhost:8090',
      );

      print('🔗 Testing USM PocketBase health check only...');
      print('   Base URL: ${backendConfig.baseUrl}');

      try {
        // Attempt connection without authentication
        final connected = await adapter.connect(backendConfig);

        print('✅ Connection result: $connected');
        print('   Adapter connected: ${adapter.isConnected}');
        print('   Backend type: ${adapter.backendType}');

        expect(connected, isTrue);
        expect(adapter.isConnected, isTrue);
      } catch (e) {
        print('❌ Connection failed: $e');
        fail('USM PocketBase adapter health check failed: $e');
      }
    }, timeout: Timeout(Duration(seconds: 30)));
  });
}
