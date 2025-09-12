// Quick test of just the first USM sync operation

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('USM Single Sync Test', () {
    test('USM Local Create to Remote Sync', () async {
      print('🚀 Testing USM Local Create to Remote Sync...');

      // Initialize USM components
      final adapter = PocketBaseSyncAdapter(
        baseUrl: 'http://localhost:8090',
      );

      final backendConfig = SyncBackendConfiguration(
        configId: 'usm-single-sync-test',
        displayName: 'USM Single Sync Test',
        backendType: 'pocketbase',
        baseUrl: 'http://localhost:8090',
        projectId: 'usm_test',
        customSettings: {
          'email': 'a@has.com',
          'password': '12345678',
        },
      );

      // Connect adapter
      final connected = await adapter.connect(backendConfig);
      expect(connected, isTrue);
      print('✅ USM Adapter connected');

      try {
        // Generate test data with proper UUID
        final uuid = Uuid();
        final recordId = uuid.v4();

        final testData = {
          'id': recordId,
          'organizationId': 'org_sync_test',
          'testName': 'USM Local to Remote Sync Test',
          'testDescription': 'Testing local create followed by remote sync',
          'testCategory': 'sync',
          'isActive': 1,
          'priority': 7,
          'completionPercentage': 0.3,
          'testData': '{"type": "sync_test", "stage": "local_create"}',
          'tags': '["usm", "sync", "test"]',
          'executionTime': 150.5,
          'lastResult': 'pending',
          'errorMessage': '',
          'config': '{"sync_mode": "bidirectional"}',
          'createdBy': 'usm-test-user',
          'updatedBy': 'usm-test-user',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'deletedAt': null,
          'lastSyncedAt': DateTime.now().toIso8601String(),
          'isDirty': 0,
          'syncVersion': 1,
          'isDeleted': 0,
        };

        print('📝 Creating record with ID: $recordId');

        // Create record using USM
        final createResult = await adapter.create('usm_test', testData);

        if (createResult.isSuccess) {
          print('✅ Record created successfully via USM');
          print('   Remote ID: ${createResult.data?['id']}');
          print('   Test Name: ${createResult.data?['testName']}');

          // Verify we can read it back
          final readResult = await adapter.read('usm_test', recordId);
          if (readResult.isSuccess) {
            print('✅ Record read back successfully');
            expect(readResult.data?['testName'],
                equals('USM Local to Remote Sync Test'));
          }

          // Clean up
          final deleteResult = await adapter.delete('usm_test', recordId);
          if (deleteResult.isSuccess) {
            print('✅ Test record cleaned up');
          }
        } else {
          print('❌ Failed to create record: ${createResult.error?.message}');
          fail('USM create operation failed: ${createResult.error?.message}');
        }

        await adapter.disconnect();
        print('✅ USM Local Create to Remote Sync test completed successfully');
      } catch (e) {
        print('❌ Test failed: $e');
        await adapter.disconnect();
        fail('USM sync test failed: $e');
      }
    }, timeout: Timeout(Duration(seconds: 30)));
  });
}
