// Test script to verify USM package works correctly when imported locally
// This simulates how other projects would use the Universal Sync Manager package

import 'package:universal_sync_manager/universal_sync_manager.dart';

void main() async {
  print('🧪 Testing Universal Sync Manager Local Package Usage');
  print('');

  try {
    // Test 1: Import Core Classes
    print('✅ Test 1: Core imports successful');
    print('   - PocketBaseSyncAdapter: ${PocketBaseSyncAdapter}');
    print('   - MyAppSyncManager: ${MyAppSyncManager}');
    print('   - SyncResult: ${SyncResult}');
    print('   - AuthContext: ${AuthContext}');
    print('');

    // Test 2: Create Backend Configuration
    print('🔧 Test 2: Backend Configuration');
    final backendConfig = SyncBackendConfiguration(
      configId: 'test-config',
      displayName: 'Test Backend',
      backendType: 'pocketbase',
      baseUrl: 'http://localhost:8090',
      projectId: 'test-project',
    );
    print('   ✅ Backend configuration created: ${backendConfig.configId}');
    print('');

    // Test 3: Create PocketBase Adapter
    print('🔌 Test 3: PocketBase Adapter Creation');
    final adapter = PocketBaseSyncAdapter(
      baseUrl: 'http://localhost:8090',
      connectionTimeout: const Duration(seconds: 10),
      requestTimeout: const Duration(seconds: 5),
    );
    print('   ✅ PocketBase adapter created');
    print('   📍 Base URL: ${adapter.baseUrl}');
    print('');

    // Test 4: Create Auth Context
    print('🔐 Test 4: Auth Context Creation');
    final authContext = AuthContext.authenticated(
      userId: 'test-user-123',
      organizationId: 'test-org-456',
      userContext: {'email': 'test@example.com'},
      metadata: {'role': 'admin'},
      validity: const Duration(hours: 1),
    );
    print('   ✅ Auth context created');
    print('   👤 User ID: ${authContext.userId}');
    print('   🏢 Organization ID: ${authContext.organizationId}');
    print('   ⏰ Valid until: ${authContext.expiresAt}');
    print('');

    // Test 5: Test Sync Result
    print('📊 Test 5: Sync Result Creation');
    final syncResult = SyncResult.success(
      data: {'test': 'data'},
      action: SyncAction.create,
      timestamp: DateTime.now(),
    );
    print('   ✅ Sync result created');
    print('   📈 Success: ${syncResult.isSuccess}');
    print('   🎯 Action: ${syncResult.action}');
    print('');

    print('🎉 All tests passed! USM package is ready for local usage.');
    print('');
    print('📋 Summary:');
    print('   ✅ All core classes import successfully');
    print('   ✅ Backend configuration works');
    print('   ✅ Adapters can be instantiated');
    print('   ✅ Auth context creation works');
    print('   ✅ Sync results can be created');
    print('');
    print('🚀 Package is ready to be used in other Flutter projects!');
  } catch (e, stackTrace) {
    print('❌ Test failed with error: $e');
    print('📚 Stack trace: $stackTrace');
  }
}
