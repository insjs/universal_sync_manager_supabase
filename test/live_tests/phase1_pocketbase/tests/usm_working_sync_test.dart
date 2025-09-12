// USM Bidirectional Sync Test with Working ID Strategy

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';

void main() {
  group('USM Working Sync Tests', () {
    late PocketBaseSyncAdapter adapter;

    setUpAll(() async {
      print('🚀 Setting up USM Working Sync Test...');

      // Initialize adapter
      adapter = PocketBaseSyncAdapter(
        baseUrl: 'http://localhost:8090',
      );

      final backendConfig = SyncBackendConfiguration(
        configId: 'usm-working-test',
        displayName: 'USM Working Test',
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
      print('✅ USM Adapter connected and authenticated');
      print('✅ Setup completed');
    });

    tearDownAll(() async {
      await adapter.disconnect();
      print('✅ Test cleanup completed');
    });

    test('USM Create-Read-Update-Delete Workflow', () async {
      // Generate short ID (15 chars max for current PocketBase schema)
      final shortId =
          'usm${DateTime.now().millisecondsSinceEpoch}'.substring(0, 15);
      print('🔧 Testing CRUD workflow with ID: $shortId');

      // 1. CREATE
      final createData = {
        'id': shortId,
        'organizationId': 'org_test_001',
        'testName': 'USM CRUD Test',
        'testDescription': 'Testing USM framework CRUD operations',
        'testCategory': 'sync',
        'isActive': 1,
        'priority': 8,
        'completionPercentage': 0.25,
        'createdBy': 'usm-test',
        'updatedBy': 'usm-test',
        'isDirty': 0,
        'lastSyncedAt': DateTime.now().toIso8601String(),
        'syncVersion': 1,
        'isDeleted': 0,
      };

      print('📝 Creating record...');
      final createResult = await adapter.create('usm_test', createData);
      expect(createResult.isSuccess, isTrue);
      expect(createResult.data?['id'], equals(shortId));
      print('✅ Record created: ${createResult.data?['testName']}');

      // 2. READ
      print('📖 Reading record...');
      final readResult = await adapter.read('usm_test', shortId);
      expect(readResult.isSuccess, isTrue);
      expect(readResult.data?['id'], equals(shortId));
      expect(readResult.data?['testName'], equals('USM CRUD Test'));
      print('✅ Record read: ${readResult.data?['testName']}');

      // 3. UPDATE
      print('✏️ Updating record...');
      final updateData = {
        'testName': 'USM CRUD Test - Updated',
        'completionPercentage': 0.75,
        'priority': 9,
        'updatedBy': 'usm-test-updated',
        'syncVersion': 2,
      };

      final updateResult =
          await adapter.update('usm_test', shortId, updateData);
      expect(updateResult.isSuccess, isTrue);
      expect(updateResult.data?['testName'], equals('USM CRUD Test - Updated'));
      expect(updateResult.data?['priority'], equals(9));
      print('✅ Record updated: ${updateResult.data?['testName']}');

      // 4. DELETE
      print('🗑️ Deleting record...');
      final deleteResult = await adapter.delete('usm_test', shortId);
      expect(deleteResult.isSuccess, isTrue);
      print('✅ Record deleted successfully');

      // 5. VERIFY DELETION
      print('🔍 Verifying deletion...');
      final verifyResult = await adapter.read('usm_test', shortId);
      expect(verifyResult.isSuccess, isFalse);
      print('✅ Deletion verified - record not found');
    });

    test('USM Batch Operations', () async {
      print('📦 Testing USM batch operations...');

      final batchIds = <String>[];
      final batchData = <Map<String, dynamic>>[];

      // Create batch of 3 records
      for (int i = 0; i < 3; i++) {
        final id = 'batch${DateTime.now().millisecondsSinceEpoch + i}'
            .substring(0, 15);
        batchIds.add(id);

        batchData.add({
          'id': id,
          'organizationId': 'org_batch_001',
          'testName': 'Batch Test $i',
          'testDescription': 'Batch operation test record $i',
          'testCategory': 'batch',
          'isActive': 1,
          'priority': 5 + i,
          'completionPercentage': 0.1 * i,
          'createdBy': 'batch-test',
          'updatedBy': 'batch-test',
          'isDirty': 0,
          'syncVersion': 1,
          'isDeleted': 0,
        });
      }

      // Create all records
      print('📝 Creating ${batchData.length} batch records...');
      for (int i = 0; i < batchData.length; i++) {
        final result = await adapter.create('usm_test', batchData[i]);
        expect(result.isSuccess, isTrue);
        print('   ✅ Created: ${batchData[i]['testName']}');
      }

      // Read all records
      print('📖 Reading batch records...');
      for (final id in batchIds) {
        final result = await adapter.read('usm_test', id);
        expect(result.isSuccess, isTrue);
        expect(result.data?['id'], equals(id));
      }
      print('✅ All batch records read successfully');

      // Clean up
      print('🧹 Cleaning up batch records...');
      for (final id in batchIds) {
        final result = await adapter.delete('usm_test', id);
        expect(result.isSuccess, isTrue);
      }
      print('✅ Batch cleanup completed');
    });
  });
}
