import 'package:flutter_test/flutter_test.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';

void main() {
  test('USM package imports and components work', () {
    // Test that key classes can be accessed
    final config = SyncBackendConfiguration(
      configId: 'test-config',
      displayName: 'Test Config',
      backendType: 'test',
      baseUrl: 'http://test.com',
      projectId: 'test-project',
    );
    
    expect(config.displayName, equals('Test Config'));
    expect(config.configId, equals('test-config'));
    print('✅ SyncBackendConfiguration: ${config.displayName}');
    
    // Test adapter creation
    final adapter = PocketBaseSyncAdapter(baseUrl: 'http://localhost:8090');
    expect(adapter, isNotNull);
    print('✅ PocketBaseSyncAdapter: ${adapter.runtimeType}');
    
    // Test enum access
    final syncMode = SyncMode.manual;
    expect(syncMode, equals(SyncMode.manual));
    print('✅ SyncMode: $syncMode');
    
    final strategy = ConflictResolutionStrategy.localWins;
    expect(strategy, equals(ConflictResolutionStrategy.localWins));
    print('✅ ConflictResolutionStrategy: $strategy');
    
    print('🎉 All USM imports work correctly!');
  });
}
