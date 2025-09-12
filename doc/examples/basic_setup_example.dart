import 'package:universal_sync_manager/universal_sync_manager.dart';

/// Phase 3: App Integration Framework - Basic Setup Example
///
/// This example demonstrates how to use the new MyAppSyncManager
/// high-level API for simplified Universal Sync Manager integration.
///
/// Features demonstrated:
/// 1. MyAppSyncManager initialization with backend adapter
/// 2. Simple binary auth state (authenticated vs public)
/// 3. Auth provider integration patterns
/// 4. Real-time auth state monitoring

Future<void> basicSetupExample() async {
  print('🚀 Universal Sync Manager - Phase 3 Basic Setup Example');
  print('');

  // Step 1: Initialize MyAppSyncManager
  print('Step 1: Initialize MyAppSyncManager');
  print('✅ High-level wrapper for easy integration');

  await MyAppSyncManager.initialize(
    backendAdapter: PocketBaseSyncAdapter(
      baseUrl: 'https://your-pocketbase.com',
      connectionTimeout: const Duration(seconds: 30),
      requestTimeout: const Duration(seconds: 15),
    ),
    publicCollections: [
      'announcements',
      'public_data',
      'app_config',
    ],
    autoSync: true,
    syncInterval: const Duration(seconds: 30),
  );

  print('✅ MyAppSyncManager initialized successfully');
  print('');

  // Step 2: Demonstrate authentication flow
  print('Step 2: Authentication Flow');

  // Check initial auth state
  print('Initial auth state: ${MyAppSyncManager.instance.authState}');
  print('Is authenticated: ${MyAppSyncManager.instance.isAuthenticated}');
  print('');

  // Simulate login
  print('🔐 Simulating login...');
  final loginResult = await MyAppSyncManager.instance.login(
    token: 'example-user-token-from-auth-provider',
    userId: 'user123',
    organizationId: 'org456',
    metadata: {
      'displayName': 'John Doe',
      'email': 'john@example.com',
      'role': 'user',
    },
  );

  if (loginResult.isSuccess) {
    print('✅ Login successful');
    print('Auth state: ${MyAppSyncManager.instance.authState}');
    print('Current user: ${MyAppSyncManager.instance.currentUser?.userId}');
    print(
        'Organization: ${MyAppSyncManager.instance.currentUser?.organizationId}');
  } else {
    print('❌ Login failed: ${loginResult.errorMessage}');
  }
  print('');

  // Step 3: Monitor auth state changes
  print('Step 3: Auth State Monitoring');

  // Listen to auth state changes
  final stateSubscription =
      MyAppSyncManager.instance.authStateChanges.listen((authState) {
    print('🔄 Auth state changed: $authState');
  });

  // Listen to auth context changes
  final contextSubscription =
      MyAppSyncManager.instance.authContextChanges.listen((authContext) {
    if (authContext != null) {
      print('👤 Auth context updated: ${authContext.userId}');
    } else {
      print('👤 Auth context cleared');
    }
  });

  // Step 4: Demonstrate logout
  print('Step 4: Logout Flow');
  print('🚪 Logging out...');

  await MyAppSyncManager.instance.logout();
  print('✅ Logout successful');
  print('Auth state: ${MyAppSyncManager.instance.authState}');
  print('Is authenticated: ${MyAppSyncManager.instance.isAuthenticated}');
  print('');

  // Step 5: Clean up
  print('Step 5: Cleanup');
  stateSubscription.cancel();
  contextSubscription.cancel();
  print('✅ Subscriptions cancelled');
  print('');

  // Step 6: Show available integrations
  print('Step 6: Available Integration Patterns');
  print('');

  print('🔐 Auth Provider Integrations:');
  print('  ✅ Firebase Auth - FirebaseAuthIntegration.syncWithUSM()');
  print('  ✅ Supabase Auth - SupabaseAuthIntegration.syncWithUSM()');
  print('  ✅ Auth0 - Auth0Integration.syncWithUSM()');
  print('');

  print('🎭 State Management Integrations:');
  print('  ✅ Bloc/Provider - AuthSyncBlocMixin, AuthSyncProvider');
  print('  ✅ Riverpod - AuthSyncNotifier, RiverpodAuthSyncState');
  print('  ✅ GetX - AuthSyncController, GetXAuthSyncState');
  print('');

  print('⚙️ Auth Lifecycle Management:');
  print('  ✅ Session Management - AuthLifecycleManager');
  print('  ✅ Token Refresh - TokenRefreshCoordinator');
  print('  ✅ User Switching - UserSwitchManager');
  print('');

  print('🎉 Phase 3: App Integration Framework Example Complete!');
  print('');
  print('Next Steps:');
  print('1. Choose your auth provider (Firebase, Supabase, Auth0)');
  print('2. Select your state management framework (Bloc, Riverpod, GetX)');
  print('3. Configure auth lifecycle management for production');
  print('4. Implement real-time auth state in your UI');
}

/// Example: Firebase Auth Integration
void exampleFirebaseIntegration() {
  print('🔥 Firebase Auth Integration Example:');
  print('''
import 'package:firebase_auth/firebase_auth.dart';

void setupFirebaseIntegration() {
  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) {
      FirebaseAuthIntegration.syncWithUSM(user);
    } else {
      MyAppSyncManager.instance.logout();
    }
  });
}
''');
}

/// Example: Riverpod State Management Integration
void exampleRiverpodIntegration() {
  print('🏗️ Riverpod State Management Integration Example:');
  print('''
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authProvider = StateNotifierProvider<AuthSyncNotifier, RiverpodAuthSyncState>((ref) {
  final notifier = AuthSyncNotifier();
  notifier.initialize();
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    if (authState.isAuthenticated) {
      return Text('Welcome \${authState.userId}!');
    }
    
    return LoginButton();
  }
}
''');
}

/// Example: Auth Lifecycle Management
void exampleAuthLifecycleManagement() {
  print('🔄 Auth Lifecycle Management Example:');
  print('''
Future<void> setupAuthLifecycle() async {
  final lifecycleManager = AuthLifecycleManager();
  
  await lifecycleManager.initialize(
    sessionTimeoutDuration: Duration(hours: 8),
    refreshThreshold: Duration(minutes: 5),
  );
  
  lifecycleManager.startTokenRefreshCoordination();
  
  lifecycleManager.sessionEventStream.listen((event) {
    switch (event.type) {
      case SessionEventType.timeout:
        // Handle session timeout
        break;
      case SessionEventType.refreshed:
        print('Token refreshed successfully');
        break;
    }
  });
}
''');
}

/// Key Features Demonstrated:
/// 
/// 1. **MyAppSyncManager**: High-level wrapper for simplified integration
/// 2. **Binary Auth State**: Simple authenticated vs public state management  
/// 3. **Backend Adapters**: PocketBase, Supabase, Firebase support
/// 4. **Auth Provider Integration**: Automatic sync with Firebase, Supabase, Auth0
/// 5. **State Management**: Bloc, Riverpod, GetX integration patterns
/// 6. **Auth Lifecycle**: Session management, token refresh, user switching
/// 
/// Production Benefits:
/// 
/// - Simplified API reduces boilerplate code
/// - Automatic auth state synchronization
/// - Framework-agnostic state management integration
/// - Comprehensive session and token management
/// - Real-time auth state monitoring
/// - Production-ready error handling
/// 
/// Next Steps:
/// 
/// 1. Implement your preferred auth provider integration
/// 2. Choose and configure your state management solution
/// 3. Set up auth lifecycle management for your app's needs
/// 4. Build reactive UI components using the auth state streams
