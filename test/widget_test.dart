// Package widget tests for Universal Sync Manager
// Since this is a package, we test individual components rather than a full app

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';

void main() {
  testWidgets('USM package components can be imported',
      (WidgetTester tester) async {
    // Test that core USM components can be instantiated
    final config = SyncBackendConfiguration(
      configId: 'test-config',
      displayName: 'Test Config',
      backendType: 'test',
      baseUrl: 'http://test.com',
      projectId: 'test',
    );
    expect(config, isA<SyncBackendConfiguration>());
    expect(SyncMode.manual, isA<SyncMode>());
    expect(ConflictResolutionStrategy.localWins,
        isA<ConflictResolutionStrategy>());
  });
}
