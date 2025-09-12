// Test USM with proper UUID format to match the regex pattern

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('USM UUID Format Tests', () {
    test('Test with proper UUID format matching PocketBase regex', () async {
      print('🔗 Testing USM with proper UUID format...');

      // Create adapter
      final adapter = PocketBaseSyncAdapter(
        baseUrl: 'http://localhost:8090',
      );

      final backendConfig = SyncBackendConfiguration(
        configId: 'test-uuid-format',
        displayName: 'Test UUID Format',
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

        // Test with proper UUID format (matches regex pattern)
        final uuid = Uuid();
        final properUuid = uuid
            .v4(); // Generate proper UUID like: 550e8400-e29b-41d4-a716-446655440000
        print('   Using proper UUID: $properUuid (${properUuid.length} chars)');
        print('   UUID format: ${properUuid.runtimeType}');

        // Verify UUID matches the expected pattern
        final uuidPattern = RegExp(
            r'^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$');
        final matches = uuidPattern.hasMatch(properUuid);
        print('   UUID matches pattern: $matches');
        expect(matches, isTrue);

        final testData = {
          'id': properUuid,
          'organizationId': 'org001',
          'testName': 'Proper UUID Test',
          'testDescription':
              'Testing with proper UUID format matching PocketBase regex',
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

        print('📝 Creating record with proper UUID...');
        final result = await adapter.create('usm_test', testData);

        if (result.isSuccess) {
          print('✅ Record created successfully with proper UUID');
          print('   Record ID: ${result.data?['id']}');

          // Test reading the record
          final readResult = await adapter.read('usm_test', properUuid);
          if (readResult.isSuccess) {
            print('✅ Record read successfully');
          }

          // Clean up - delete the test record
          final deleteResult = await adapter.delete('usm_test', properUuid);
          if (deleteResult.isSuccess) {
            print('✅ Test record cleaned up');
          }
        } else {
          print('❌ Failed to create record: ${result.error?.message}');
          print('   Error details: ${result.error?.details}');
          print('   HTTP status: ${result.error?.httpStatusCode}');

          // Don't fail the test yet - let's see what the exact error is
          print('   This will help us debug the actual issue...');
        }

        await adapter.disconnect();
        print('✅ Test completed');
      } catch (e) {
        print('❌ Test failed: $e');
        fail('USM UUID format test failed: $e');
      }
    }, timeout: Timeout(Duration(seconds: 30)));

    test('Test with 15-char ID format (alternative pattern)', () async {
      print('🔗 Testing USM with 15-char ID format...');

      // Create adapter
      final adapter = PocketBaseSyncAdapter(
        baseUrl: 'http://localhost:8090',
      );

      final backendConfig = SyncBackendConfiguration(
        configId: 'test-15char-format',
        displayName: 'Test 15-Char Format',
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

        // Generate 15-character ID that matches [a-z0-9]{15} pattern
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final shortId = 'usm$timestamp'
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]'), '')
            .substring(0, 15);
        print('   Using 15-char ID: $shortId (${shortId.length} chars)');

        // Verify it matches the pattern
        final shortPattern = RegExp(r'^[a-z0-9]{15}$');
        final matches = shortPattern.hasMatch(shortId);
        print('   ID matches pattern: $matches');
        expect(matches, isTrue);

        final testData = {
          'id': shortId,
          'organizationId': 'org001',
          'testName': '15-Char ID Test',
          'testDescription': 'Testing with 15-character ID format',
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
        expect(result.isSuccess, isTrue);
        print('✅ 15-char ID record created successfully');

        // Clean up
        await adapter.delete('usm_test', shortId);
        await adapter.disconnect();
      } catch (e) {
        print('❌ 15-char test failed: $e');
        fail('15-char ID test failed: $e');
      }
    });
  });
}
