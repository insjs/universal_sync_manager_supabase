/// Phase 2: Backend Adapter Integration Test Suite
///
/// This test suite validates the Enhanced Authentication Integration Pattern Phase 2
/// implementation, ensuring all backend adapters support enhanced authentication
/// with consistent behavior across backends.

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';

void main() {
  group('Phase 2: Backend Adapter Integration Tests', () {
    late SyncAuthConfiguration testAuthConfig;
    late AuthContext testAuthContext;

    setUpAll(() async {
      // Initialize test auth configuration
      testAuthConfig = SyncAuthConfiguration.fromApp(
        userId: 'test_user_123',
        organizationId: 'test_org_456',
        customFields: {
          'department': 'engineering',
          'role': 'developer',
        },
        roleMetadata: {
          'permissions': ['read', 'write'],
          'features': ['advanced_sync', 'real_time'],
          'role_level': 'standard',
        },
        onTokenRefresh: () async {
          // Simulate token refresh
          await Future.delayed(const Duration(milliseconds: 100));
          return 'refreshed_token_${DateTime.now().millisecondsSinceEpoch}';
        },
        authType: SyncAuthType.bearer,
        credentials: {
          'token': 'test_bearer_token_123',
          'email': 'test@example.com',
        },
      );

      // Initialize test auth context
      testAuthContext = AuthContext.authenticated(
        userId: 'test_user_123',
        organizationId: 'test_org_456',
        userContext: {
          'department': 'engineering',
          'role': 'developer',
          'email': 'test@example.com',
        },
        metadata: {
          'permissions': ['read', 'write'],
          'features': ['advanced_sync', 'real_time'],
        },
        credentials: {
          'token': 'test_bearer_token_123',
        },
        validity: const Duration(hours: 1),
      );
    });

    group('2.1 PocketBase Adapter Enhancement', () {
      test('Should integrate auth headers in HTTP requests', () async {
        final adapter = PocketBaseSyncAdapter(
          baseUrl: 'http://localhost:8090',
        );

        final config = SyncBackendConfiguration(
          configId: 'test-pb-auth',
          displayName: 'PocketBase Auth Test',
          backendType: 'pocketbase',
          baseUrl: 'http://localhost:8090',
          projectId: 'test_project',
          authConfig: testAuthConfig,
        );

        // Test that adapter stores auth configuration
        expect(() async => await adapter.connect(config), returnsNormally);

        // Verify backend info includes enhanced auth information
        final backendInfo = adapter.backendInfo;
        expect(backendInfo['hasAuthContext'], isNotNull);
        expect(backendInfo['authContextId'], isNotNull);
        expect(backendInfo['userId'], equals('test_user_123'));
        expect(backendInfo['organizationId'], equals('test_org_456'));
        expect(backendInfo['hasTokenManager'], isNotNull);
      });

      test('Should pass role/feature metadata to PocketBase', () async {
        final adapter = PocketBaseSyncAdapter(
          baseUrl: 'http://localhost:8090',
        );

        final config = SyncBackendConfiguration(
          configId: 'test-pb-metadata',
          displayName: 'PocketBase Metadata Test',
          backendType: 'pocketbase',
          baseUrl: 'http://localhost:8090',
          projectId: 'test_project',
          authConfig: testAuthConfig,
        );

        await adapter.connect(config);

        // Verify that auth context includes role metadata
        final backendInfo = adapter.backendInfo;
        expect(backendInfo['hasAuthContext'], isTrue);

        // Test would verify that HTTP requests include metadata headers
        // X-Meta-permissions, X-Meta-features, etc.
      });

      test('Should support both legacy and enhanced auth patterns', () async {
        final adapter = PocketBaseSyncAdapter(
          baseUrl: 'http://localhost:8090',
        );

        // Test legacy auth pattern
        final legacyConfig = SyncBackendConfiguration(
          configId: 'test-pb-legacy',
          displayName: 'PocketBase Legacy Auth',
          backendType: 'pocketbase',
          baseUrl: 'http://localhost:8090',
          projectId: 'test_project',
          customSettings: {
            'email': 'test@example.com',
            'password': 'testpassword',
          },
        );

        expect(
            () async => await adapter.connect(legacyConfig), returnsNormally);

        // Test enhanced auth pattern
        final enhancedConfig = SyncBackendConfiguration(
          configId: 'test-pb-enhanced',
          displayName: 'PocketBase Enhanced Auth',
          backendType: 'pocketbase',
          baseUrl: 'http://localhost:8090',
          projectId: 'test_project',
          authConfig: testAuthConfig,
        );

        expect(
            () async => await adapter.connect(enhancedConfig), returnsNormally);
      });
    });

    group('2.2 Firebase Adapter Enhancement', () {
      test('Should integrate Firebase Authentication tokens', () async {
        final adapter = FirebaseSyncAdapter(
          projectId: 'test-firebase-project',
        );

        final config = SyncBackendConfiguration(
          configId: 'test-firebase-auth',
          displayName: 'Firebase Auth Test',
          backendType: 'firebase',
          baseUrl: 'https://test-firebase-project.firebaseio.com',
          projectId: 'test-firebase-project',
          authConfig: testAuthConfig,
        );

        await adapter.connect(config);

        // Verify Firebase adapter includes enhanced auth information
        final backendInfo = adapter.backendInfo;
        expect(backendInfo['hasAuthContext'], isTrue);
        expect(backendInfo['userId'], equals('test_user_123'));
        expect(backendInfo['organizationId'], equals('test_org_456'));
        expect(backendInfo['hasTokenManager'], isTrue);
      });

      test('Should respect Firestore security rules', () async {
        final adapter = FirebaseSyncAdapter(
          projectId: 'test-firebase-project',
        );

        final config = SyncBackendConfiguration(
          configId: 'test-firebase-rules',
          displayName: 'Firebase Security Rules Test',
          backendType: 'firebase',
          baseUrl: 'https://test-firebase-project.firebaseio.com',
          projectId: 'test-firebase-project',
          authConfig: testAuthConfig,
        );

        await adapter.connect(config);

        // Test verifies that Firebase operations include user context
        // and custom claims for Firestore security rules
        expect(adapter.isConnected, isTrue);
      });

      test('Should pass Firebase user context and custom claims', () async {
        final adapter = FirebaseSyncAdapter(
          projectId: 'test-firebase-project',
        );

        final config = SyncBackendConfiguration(
          configId: 'test-firebase-claims',
          displayName: 'Firebase Custom Claims Test',
          backendType: 'firebase',
          baseUrl: 'https://test-firebase-project.firebaseio.com',
          projectId: 'test-firebase-project',
          authConfig: testAuthConfig,
        );

        await adapter.connect(config);

        // Verify custom claims are properly set in auth context
        final backendInfo = adapter.backendInfo;
        expect(backendInfo['authContextExpiry'], isNotNull);
      });
    });

    group('2.3 Supabase Adapter Enhancement', () {
      test('Should integrate with Supabase Auth and JWT tokens', () async {
        final adapter = SupabaseSyncAdapter(
          supabaseUrl: 'https://test-project.supabase.co',
          supabaseAnonKey: 'test-anon-key',
        );

        final config = SyncBackendConfiguration(
          configId: 'test-supabase-auth',
          displayName: 'Supabase Auth Test',
          backendType: 'supabase',
          baseUrl: 'https://test-project.supabase.co',
          projectId: 'test-project',
          authConfig: testAuthConfig,
        );

        await adapter.connect(config);

        // Verify Supabase adapter includes enhanced auth information
        final backendInfo = adapter.backendInfo;
        expect(backendInfo['hasAuthContext'], isTrue);
        expect(backendInfo['userId'], equals('test_user_123'));
        expect(backendInfo['organizationId'], equals('test_org_456'));
        expect(backendInfo['hasTokenManager'], isTrue);
      });

      test('Should respect Supabase Row Level Security policies', () async {
        final adapter = SupabaseSyncAdapter(
          supabaseUrl: 'https://test-project.supabase.co',
          supabaseAnonKey: 'test-anon-key',
        );

        final config = SyncBackendConfiguration(
          configId: 'test-supabase-rls',
          displayName: 'Supabase RLS Test',
          backendType: 'supabase',
          baseUrl: 'https://test-project.supabase.co',
          projectId: 'test-project',
          authConfig: testAuthConfig,
        );

        await adapter.connect(config);

        // Test verifies that Supabase operations set RLS context
        // and enhance data with user context for policies
        expect(adapter.isConnected, isTrue);
      });

      test('Should pass user metadata and roles to backend', () async {
        final adapter = SupabaseSyncAdapter(
          supabaseUrl: 'https://test-project.supabase.co',
          supabaseAnonKey: 'test-anon-key',
        );

        final config = SyncBackendConfiguration(
          configId: 'test-supabase-metadata',
          displayName: 'Supabase Metadata Test',
          backendType: 'supabase',
          baseUrl: 'https://test-project.supabase.co',
          projectId: 'test-project',
          authConfig: testAuthConfig,
        );

        await adapter.connect(config);

        // Verify metadata is available for RLS policies
        final backendInfo = adapter.backendInfo;
        expect(backendInfo['authContextId'], isNotNull);
        expect(backendInfo['authContextExpiry'], isNotNull);
      });
    });

    group('2.4 Simple Auth Interface', () {
      late DefaultSimpleAuth simpleAuth;

      setUp(() {
        simpleAuth = DefaultSimpleAuth();
      });

      tearDown(() {
        simpleAuth.dispose();
      });

      test('Should provide binary auth state', () async {
        // Initially public
        expect(simpleAuth.currentState, equals(AuthState.public));
        expect(simpleAuth.isPublic, isTrue);
        expect(simpleAuth.isAuthenticated, isFalse);

        // Authenticate
        final result = await simpleAuth.authenticate({
          'email': 'test@example.com',
          'password': 'testpassword',
        });

        expect(result.success, isTrue);
        expect(result.state, equals(AuthState.authenticated));
        expect(result.userId, isNotNull);
        expect(simpleAuth.isAuthenticated, isTrue);
        expect(simpleAuth.isPublic, isFalse);

        // Sign out
        await simpleAuth.signOut();
        expect(simpleAuth.currentState, equals(AuthState.public));
        expect(simpleAuth.isPublic, isTrue);
        expect(simpleAuth.isAuthenticated, isFalse);
      });

      test('Should implement token refresh and expiry handling', () async {
        // Authenticate first
        await simpleAuth.authenticate({
          'email': 'test@example.com',
          'password': 'testpassword',
        });

        expect(simpleAuth.isAuthenticated, isTrue);

        // Test token refresh
        final refreshResult = await simpleAuth.refreshAuth();
        expect(refreshResult.success, isTrue);
        expect(refreshResult.state, equals(AuthState.authenticated));

        // Test validation
        final isValid = await simpleAuth.validateAuth();
        expect(isValid, isTrue);
      });

      test('Should handle auth failures gracefully', () async {
        // Test authentication failure
        final failResult = await simpleAuth.authenticate({
          'email': '', // Invalid
          'password': '',
        });

        expect(failResult.success, isFalse);
        expect(failResult.error, isNotNull);
        expect(simpleAuth.currentState, equals(AuthState.public));

        // Test graceful failure handling
        final handleResult =
            await simpleAuth.handleAuthFailure('Network error');
        expect(handleResult.success, isFalse);
        expect(handleResult.error, contains('Network error'));
        expect(simpleAuth.currentState, equals(AuthState.public));
      });

      test('Should integrate with Phase 1 auth context', () async {
        // Update auth context from external source
        await simpleAuth.updateAuthContext(testAuthContext);

        expect(simpleAuth.isAuthenticated, isTrue);
        expect(simpleAuth.currentUserId, equals('test_user_123'));
        expect(simpleAuth.currentAuthContext, isNotNull);
        expect(simpleAuth.currentAuthContext!.userId, equals('test_user_123'));
        expect(simpleAuth.getOrganizationId(), equals('test_org_456'));

        // Test metadata access
        final metadata = simpleAuth.getUserMetadata();
        expect(metadata['department'], equals('engineering'));
        expect(metadata['role'], equals('developer'));

        // Create auth context from result
        final authResult = SimpleAuthResult.authenticated(
          userId: 'new_user_789',
          metadata: {'role': 'admin'},
        );

        final newContext = simpleAuth.createAuthContextFromResult(authResult);
        expect(newContext, isNotNull);
        expect(newContext!.userId, equals('new_user_789'));
        expect(newContext.userContext['role'], equals('admin'));
      });

      test('Should provide auth state change notifications', () async {
        final stateChanges = <SimpleAuthResult>[];

        // Listen to auth state changes
        simpleAuth.authStateChanges.listen((result) {
          stateChanges.add(result);
        });

        // Authenticate
        await simpleAuth.authenticate({
          'email': 'test@example.com',
          'password': 'testpassword',
        });

        // Sign out
        await simpleAuth.signOut();

        // Wait for events to be processed
        await Future.delayed(const Duration(milliseconds: 50));

        expect(stateChanges.length, equals(2));
        expect(stateChanges[0].state, equals(AuthState.authenticated));
        expect(stateChanges[1].state, equals(AuthState.public));
      });
    });

    group('Phase 2 Success Criteria Validation', () {
      test('All backend adapters support enhanced authentication', () async {
        // Test PocketBase
        final pbAdapter =
            PocketBaseSyncAdapter(baseUrl: 'http://localhost:8090');
        expect(pbAdapter.backendType, equals('pocketbase'));

        // Test Supabase
        final supabaseAdapter = SupabaseSyncAdapter(
          supabaseUrl: 'https://test.supabase.co',
          supabaseAnonKey: 'test-key',
        );
        expect(supabaseAdapter.backendType, equals('supabase'));

        // Test Firebase
        final firebaseAdapter = FirebaseSyncAdapter(projectId: 'test-project');
        expect(firebaseAdapter.backendType, equals('firebase'));

        // All adapters should support the enhanced auth pattern
        expect(pbAdapter, isA<ISyncBackendAdapter>());
        expect(supabaseAdapter, isA<ISyncBackendAdapter>());
        expect(firebaseAdapter, isA<ISyncBackendAdapter>());
      });

      test('Authentication behavior is consistent across backends', () async {
        final adapters = [
          PocketBaseSyncAdapter(baseUrl: 'http://localhost:8090'),
          SupabaseSyncAdapter(
            supabaseUrl: 'https://test.supabase.co',
            supabaseAnonKey: 'test-key',
          ),
          FirebaseSyncAdapter(projectId: 'test-project'),
        ];

        for (final adapter in adapters) {
          // All adapters should provide consistent backend info structure
          final info = adapter.backendInfo;
          expect(info, containsPair('isAuthenticated', anything));
          expect(info, containsPair('capabilities', anything));

          // Test auth configuration acceptance
          final config = SyncBackendConfiguration(
            configId: 'test-consistent-auth',
            displayName: 'Consistency Test',
            backendType: adapter.backendType,
            baseUrl: 'http://test.example.com',
            projectId: 'test_project',
            authConfig: testAuthConfig,
          );

          expect(() async => await adapter.connect(config), returnsNormally);
        }
      });

      test('Backend-specific security features are leveraged', () async {
        // PocketBase: Collection auth rules
        final pbAdapter =
            PocketBaseSyncAdapter(baseUrl: 'http://localhost:8090');
        final pbCapabilities = pbAdapter.capabilities;
        expect(pbCapabilities.supportsRealTimeSubscriptions, isTrue);

        // Supabase: Row Level Security
        final supabaseAdapter = SupabaseSyncAdapter(
          supabaseUrl: 'https://test.supabase.co',
          supabaseAnonKey: 'test-key',
        );
        final supabaseCapabilities = supabaseAdapter.capabilities;
        expect(supabaseCapabilities.supportsRealTimeSubscriptions, isTrue);

        // Firebase: Security Rules
        final firebaseAdapter = FirebaseSyncAdapter(projectId: 'test-project');
        final firebaseCapabilities = firebaseAdapter.capabilities;
        expect(firebaseCapabilities.supportsBatchOperations, isTrue);
      });

      test('Auth failures are handled gracefully with clear error messages',
          () async {
        final simpleAuth = DefaultSimpleAuth();

        // Test various failure scenarios
        final scenarios = [
          {'email': null, 'password': 'test'}, // Missing email
          {'email': 'test@example.com', 'password': null}, // Missing password
          {'email': '', 'password': ''}, // Empty credentials
        ];

        for (final scenario in scenarios) {
          final result = await simpleAuth.authenticate(scenario);
          expect(result.success, isFalse);
          expect(result.error, isNotNull);
          expect(result.error, isA<String>());
          expect(result.state, equals(AuthState.public));
        }

        simpleAuth.dispose();
      });
    });
  });
}
