// Test with shorter IDs to validate the sync logic works

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';

void main() {
  group('USM Short ID Tests', () {
    test('Test with 15-character IDs', () async {
      print('🔗 Testing USM with shorter IDs to validate sync logic...');

      // Create adapter
      final adapter = PocketBaseSyncAdapter(
        baseUrl: 'http://localhost:8090',
      );

      final backendConfig = SyncBackendConfiguration(
        configId: 'test-short-ids',
        displayName: 'Test Short IDs',
        backendType: 'pocketbase',
        baseUrl: 'http://localhost:8090',
        projectId: 'usm_test',
        customSettings: {
          'email': 'a@has.com',
          'password': '12345678',
        },
      );

      try {
        // Connect adapter
        final connected = await adapter.connect(backendConfig);
        expect(connected, isTrue);
        print('✅ Adapter connected successfully');

        // Test creating a record with short ID (15 chars max)
        final shortId =
            'test${DateTime.now().millisecondsSinceEpoch}'.substring(0, 15);
        print('   Using short ID: $shortId (${shortId.length} chars)');

        final testData = {
          'id': shortId,
          'organizationId': 'org001',
          'testName': 'Short ID Test',
          'testDescription': 'Testing with 15-character ID limit',
          'testCategory': 'sync',
          'isActive': 1,
          'priority': 5,
          'completionPercentage': 0.0,
          'createdBy': 'test-user',
          'updatedBy': 'test-user',
          'isDirty': 0,
          'lastSyncedAt': DateTime.now().toIso8601String(),
          'syncVersion': 1,
          'isDeleted': 0,
        };

        final result = await adapter.create('usm_test', testData);

        if (result.isSuccess) {
          print('✅ Record created successfully with short ID');
          print('   Record ID: ${result.data?['id']}');

          // Clean up - delete the test record
          final deleteResult = await adapter.delete('usm_test', shortId);
          if (deleteResult.isSuccess) {
            print('✅ Test record cleaned up');
          }
        } else {
          print('❌ Failed to create record: ${result.error?.message}');
          fail('Record creation failed: ${result.error?.message}');
        }

        await adapter.disconnect();
        print('✅ Test completed successfully');
      } catch (e) {
        print('❌ Test failed: $e');
        fail('USM short ID test failed: $e');
      }
    }, timeout: Timeout(Duration(seconds: 30)));
  });
}
