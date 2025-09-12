import 'package:flutter_test/flutter_test.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';

void main() {
  group('Universal Sync Manager Package Import Tests', () {
    test('should import USM core classes without errors', () {
      // Test that core USM classes can be imported and referenced
      expect(() => PocketBaseSyncAdapter, returnsNormally);
      expect(() => SyncBackendConfiguration, returnsNormally);
      expect(() => SyncResult, returnsNormally);
      expect(() => AuthContext, returnsNormally);
    });

    test('should be able to create basic USM objects', () {
      // Test creating a backend configuration
      final config = SyncBackendConfiguration(
        configId: 'test-config',
        displayName: 'Test Backend',
        backendType: 'pocketbase',
        baseUrl: 'http://localhost:8090',
        projectId: 'test-project',
      );

      expect(config.configId, equals('test-config'));
      expect(config.baseUrl, equals('http://localhost:8090'));
    });

    test('should be able to create auth context', () {
      // Test creating an auth context
      final authContext = AuthContext.authenticated(
        userId: 'test-user-123',
        organizationId: 'test-org-456',
        userContext: {'email': 'test@example.com'},
      );

      expect(authContext.userId, equals('test-user-123'));
      expect(authContext.organizationId, equals('test-org-456'));
      expect(authContext.isValid, isTrue);
    });

    test('should be able to create PocketBase adapter', () {
      // Test creating a PocketBase adapter
      final adapter = PocketBaseSyncAdapter(
        baseUrl: 'http://localhost:8090',
        connectionTimeout: const Duration(seconds: 30),
        requestTimeout: const Duration(seconds: 15),
      );

      expect(adapter.baseUrl, equals('http://localhost:8090'));
      expect(adapter.isConnected, isFalse); // Should not be connected initially
    });
  });
}
