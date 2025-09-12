# Usage Examples

Comprehensive examples for using Universal Sync Manager with Phase 3 App Integration Framework.

## Quick Start with MyAppSyncManager

### Basic Initialization

Initialize Universal Sync Manager with simplified high-level API

```dart
import 'package:universal_sync_manager/universal_sync_manager.dart';

void main() async {
  // Initialize with MyAppSyncManager for simplified usage
  await MyAppSyncManager.initialize(
    backendAdapter: PocketBaseSyncAdapter(
      configuration: SyncBackendConfiguration(
        configId: 'main-backend',
        backendType: 'pocketbase',
        baseUrl: 'https://your-pocketbase.com',
        projectId: 'my-app',
      ),
    ),
    publicCollections: ['announcements', 'public_data'],
    autoSync: true,
    syncInterval: Duration(seconds: 30),
  );
  
  print('✅ Universal Sync Manager initialized!');
}
```

---

### Authentication Flow

Simple binary auth state management (authenticated vs public)

```dart
// Login with any auth provider token
final result = await MyAppSyncManager.instance.login(
  token: 'user-auth-token-from-firebase-or-supabase',
  userId: 'user123',
  organizationId: 'org456', // optional for multi-tenant apps
  metadata: {
    'displayName': 'John Doe',
    'email': 'john@example.com',
  },
);

if (result.isSuccess) {
  print('✅ User authenticated and sync started');
} else {
  print('❌ Login failed: ${result.errorMessage}');
}

// Check authentication status
if (MyAppSyncManager.instance.isAuthenticated) {
  print('User is logged in');
  print('Current user: ${MyAppSyncManager.instance.currentUser?.userId}');
}

// Logout
await MyAppSyncManager.instance.logout();
print('✅ User logged out, switched to public-only sync');
```

---

## Auth Provider Integrations

### Firebase Auth Integration

Automatic Firebase Auth state synchronization with USM

```dart
import 'package:firebase_auth/firebase_auth.dart';

void setupFirebaseIntegration() {
  // Automatic Firebase Auth sync
  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) {
      // User signed in - sync with USM
      FirebaseAuthIntegration.syncWithUSM(user);
    } else {
      // User signed out - logout from USM
      MyAppSyncManager.instance.logout();
    }
  });
}

// Advanced Firebase integration with custom claims
void setupAdvancedFirebaseIntegration() {
  final integration = AdvancedFirebaseAuthIntegration(
    extractCustomClaims: (user) async {
      final idToken = await user.getIdTokenResult();
      return idToken.claims;
    },
    onAuthStateChange: (user, claims) {
      print('Firebase user: ${user?.uid}');
      print('Custom claims: $claims');
    },
  );
  
  integration.initialize();
}
```

---

### Supabase Auth Integration

Supabase Auth with Row Level Security (RLS) context

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void setupSupabaseIntegration() {
  final supabase = Supabase.instance.client;
  
  // Listen to Supabase auth changes
  supabase.auth.onAuthStateChange.listen((data) {
    final user = data.user;
    if (user != null) {
      // User signed in - sync with USM and set RLS context
      SupabaseAuthIntegration.syncWithUSM(user);
    } else {
      // User signed out
      MyAppSyncManager.instance.logout();
    }
  });
}

// Advanced Supabase integration with RLS
void setupAdvancedSupabaseIntegration() {
  final integration = AdvancedSupabaseAuthIntegration(
    supabaseClient: Supabase.instance.client,
    onAuthStateChange: (user, session) {
      print('Supabase user: ${user?.id}');
      print('Session: ${session?.accessToken}');
    },
  );
  
  integration.initialize();
  
  // Set RLS context for multi-tenant apps
  integration.setRLSContext({
    'organization_id': 'org123',
    'role': 'admin',
  });
}
```

---

### Auth0 Integration

Manual Auth0 token integration pattern

```dart
void setupAuth0Integration() {
  // Auth0 login flow (manual)
  Future<void> loginWithAuth0() async {
    // Your Auth0 login logic here
    final auth0Token = await getAuth0Token();
    final userProfile = await getAuth0UserProfile(auth0Token);
    
    // Sync with USM
    await Auth0Integration.syncWithUSM(
      token: auth0Token,
      userProfile: userProfile,
    );
  }
  
  // Advanced Auth0 integration
  final integration = AdvancedAuth0Integration(
    domain: 'your-domain.auth0.com',
    clientId: 'your-client-id',
    onTokenRefresh: (newToken) {
      print('Auth0 token refreshed: $newToken');
    },
  );
  
  integration.initialize();
}
```

---

## State Management Integrations

### Riverpod Integration

StateNotifier pattern for Riverpod 1.x and AsyncNotifier for Riverpod 2.0+

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Riverpod 1.x StateNotifier pattern
final authProvider = StateNotifierProvider<AuthSyncNotifier, RiverpodAuthSyncState>((ref) {
  final notifier = AuthSyncNotifier();
  notifier.initialize();
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

// In your widget
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    if (authState.isLoading) {
      return CircularProgressIndicator();
    }
    
    if (authState.isAuthenticated) {
      return Column(
        children: [
          Text('Welcome ${authState.userId}!'),
          Text('Organization: ${authState.organizationId}'),
        ],
      );
    }
    
    return ElevatedButton(
      onPressed: () {
        ref.read(authProvider.notifier).login(
          token: 'your-token',
          userId: 'user-id',
        );
      },
      child: Text('Login'),
    );
  }
}
```

---

### Bloc Integration

Bloc pattern with AuthSyncBlocMixin for easy integration

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

// Define your app events and states
abstract class AppEvent {}
class AppStarted extends AppEvent {}

abstract class AppState {}
class AppInitial extends AppState {}

// Use the mixin for automatic USM auth integration
class MyAppBloc extends Bloc<AppEvent, AppState> with AuthSyncBlocMixin {
  MyAppBloc() : super(AppInitial()) {
    // Initialize USM auth sync
    initializeAuthSync();
    
    on<AppStarted>((event, emit) {
      // Your app logic here
      // Auth state is automatically managed by the mixin
    });
  }
  
  @override
  Future<void> close() {
    disposeAuthSync();
    return super.close();
  }
}

// In your widget
class MyBlocWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyAppBloc, AppState>(
      builder: (context, state) {
        // Access auth state from the mixin
        final appBloc = context.read<MyAppBloc>();
        final authState = appBloc.authState;
        
        if (authState.isSyncing) {
          return CircularProgressIndicator();
        }
        
        if (authState.isAuthenticated) {
          return Text('Welcome ${authState.userId}!');
        }
        
        return ElevatedButton(
          onPressed: () {
            appBloc.loginWithUSM(
              token: 'your-token',
              userId: 'user-id',
            );
          },
          child: Text('Login'),
        );
      },
    );
  }
}
```

---

### GetX Integration

GetX reactive controller pattern

```dart
import 'package:get/get.dart';

// GetX binding
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    final controller = AuthSyncController();
    controller.initialize();
    Get.put<AuthSyncController>(controller);
  }
}

// In your widget
class MyGetXWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthSyncController>();
    
    return StreamBuilder<GetXAuthSyncState>(
      stream: authController.stream,
      initialData: authController.authState,
      builder: (context, snapshot) {
        final authState = snapshot.data!;
        
        if (authState.isLoading) {
          return CircularProgressIndicator();
        }
        
        if (authState.isAuthenticated) {
          return Column(
            children: [
              Text('Welcome ${authState.userId}!'),
              ElevatedButton(
                onPressed: () => authController.logout(),
                child: Text('Logout'),
              ),
            ],
          );
        }
        
        return ElevatedButton(
          onPressed: () {
            authController.login(
              token: 'your-token',
              userId: 'user-id',
            );
          },
          child: Text('Login'),
        );
      },
    );
  }
}
```

---

### Provider Integration

Classic Provider pattern integration

```dart
import 'package:provider/provider.dart';

// Setup provider
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provider<AuthSyncProvider>(
      create: (context) {
        final provider = AuthSyncProvider();
        provider.initialize();
        return provider;
      },
      dispose: (context, provider) => provider.dispose(),
      child: MaterialApp(
        home: MyProviderWidget(),
      ),
    );
  }
}

// Consumer widget
class MyProviderWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthSyncProvider>(context);
    
    return StreamBuilder<BlocAuthSyncState>(
      stream: authProvider.stream,
      initialData: authProvider.state,
      builder: (context, snapshot) {
        final authState = snapshot.data!;
        
        if (authState.isSyncing) {
          return CircularProgressIndicator();
        }
        
        if (authState.isAuthenticated) {
          return Column(
            children: [
              Text('Welcome ${authState.userId}!'),
              ElevatedButton(
                onPressed: () => authProvider.logout(),
                child: Text('Logout'),
              ),
            ],
          );
        }
        
        return ElevatedButton(
          onPressed: () {
            authProvider.login(
              token: 'your-token',
              userId: 'user-id',
            );
          },
          child: Text('Login'),
        );
      },
    );
  }
}
```

---

## Auth Lifecycle Management

### Session Management

Comprehensive session and token lifecycle management

```dart
void setupAuthLifecycleManagement() async {
  // Initialize auth lifecycle manager
  final lifecycleManager = AuthLifecycleManager();
  
  await lifecycleManager.initialize(
    sessionTimeoutDuration: Duration(hours: 8),
    refreshThreshold: Duration(minutes: 5),
    warningThreshold: Duration(minutes: 10),
  );
  
  // Start automatic token refresh coordination
  lifecycleManager.startTokenRefreshCoordination();
  
  // Listen to session events
  lifecycleManager.sessionEventStream.listen((event) {
    switch (event.type) {
      case SessionEventType.timeout:
        print('Session timeout - redirecting to login');
        // Handle session timeout
        break;
      case SessionEventType.refreshed:
        print('Token refreshed successfully');
        break;
      case SessionEventType.warning:
        print('Session expiring soon - show warning');
        // Show warning to user
        break;
    }
  });
}
```

---

### User Switching

Safe user context switching with state cleanup

```dart
Future<void> switchUser() async {
  final lifecycleManager = AuthLifecycleManager();
  
  // Safe user switching with conflict resolution
  final result = await lifecycleManager.switchUser(
    newToken: 'new-user-token',
    newUserId: 'new-user-id',
    newOrganizationId: 'new-org-id',
    handleConflicts: true,
    clearLocalData: false, // Keep local data but mark as different user
  );
  
  if (result.isSuccess) {
    print('✅ User switched successfully');
  } else {
    print('❌ User switch failed: ${result.errorMessage}');
  }
}
```

---

### Token Refresh Coordination

Multi-provider token refresh coordination

```dart
void setupTokenRefreshCoordination() {
  final coordinator = TokenRefreshCoordinator();
  
  coordinator.initialize([
    // Multiple auth providers can be coordinated
    FirebaseTokenRefreshProvider(),
    SupabaseTokenRefreshProvider(),
    Auth0TokenRefreshProvider(),
  ]);
  
  // Automatic coordination across all providers
  coordinator.startCoordination();
  
  // Listen to refresh events
  coordinator.refreshEventStream.listen((event) {
    print('Token refreshed for provider: ${event.providerId}');
    print('New token expires at: ${event.newExpiry}');
  });
}
```

---

## Backend Configuration

### PocketBase Adapter

Complete PocketBase backend configuration

```dart
final pocketbaseAdapter = PocketBaseSyncAdapter(
  configuration: SyncBackendConfiguration(
    configId: 'pocketbase-main',
    displayName: 'Main PocketBase Backend',
    backendType: 'pocketbase',
    baseUrl: 'https://your-pocketbase.com',
    projectId: 'my-app',
    connectionTimeout: Duration(seconds: 30),
    requestTimeout: Duration(seconds: 15),
    maxRetries: 3,
    environment: 'production',
    customHeaders: {
      'X-App-Version': '1.0.0',
    },
    enableLogging: true,
    logLevel: 'info',
  ),
);

// Check backend capabilities
final capabilities = await pocketbaseAdapter.getCapabilities();
print('Supports real-time: ${capabilities.supportsRealTimeSubscriptions}');
print('Max batch size: ${capabilities.maxBatchSize}');
```

---

### Supabase Adapter

Supabase backend with RLS support

```dart
final supabaseAdapter = SupabaseSyncAdapter(
  configuration: SyncBackendConfiguration(
    configId: 'supabase-main',
    backendType: 'supabase',
    baseUrl: 'https://your-project.supabase.co',
    projectId: 'your-project-id',
    apiKey: 'your-anon-key',
    environment: 'production',
  ),
);

// Enable RLS for multi-tenant apps
await supabaseAdapter.setRLSContext({
  'organization_id': 'current-org-id',
  'user_role': 'admin',
});
```

---

### Firebase Adapter

Firebase backend configuration

```dart
final firebaseAdapter = FirebaseSyncAdapter(
  configuration: SyncBackendConfiguration(
    configId: 'firebase-main',
    backendType: 'firebase',
    projectId: 'your-firebase-project-id',
    environment: 'production',
  ),
);

// Configure Firestore settings
await firebaseAdapter.configureFirestore(
  persistenceEnabled: true,
  cacheSizeBytes: 100 * 1024 * 1024, // 100MB
);
```

---

## Advanced Usage

### Real-time State Monitoring

Monitor authentication and sync state changes in real-time

```dart
void setupStateMonitoring() {
  // Monitor auth state changes
  MyAppSyncManager.instance.authStateChanges.listen((authState) {
    print('Auth state changed: $authState');
    
    switch (authState) {
      case AuthState.authenticated:
        print('✅ User authenticated - sync active');
        break;
      case AuthState.public:
        print('🔓 Public mode - limited sync');
        break;
    }
  });
  
  // Monitor auth context changes
  MyAppSyncManager.instance.authContextChanges.listen((authContext) {
    if (authContext != null) {
      print('Auth context updated:');
      print('  User ID: ${authContext.userId}');
      print('  Organization: ${authContext.organizationId}');
      print('  Token expires: ${authContext.tokenExpiry}');
    }
  });
}
```

---

### Error Handling

Comprehensive error handling patterns

```dart
Future<void> handleAuthOperations() async {
  try {
    // Login with error handling
    final result = await MyAppSyncManager.instance.login(
      token: 'user-token',
      userId: 'user-id',
    );
    
    if (!result.isSuccess) {
      // Handle specific auth errors
      switch (result.errorMessage) {
        case 'invalid_token':
          print('❌ Invalid token - redirect to login');
          break;
        case 'token_expired':
          print('❌ Token expired - refresh needed');
          break;
        case 'network_error':
          print('❌ Network error - retry later');
          break;
        default:
          print('❌ Unknown error: ${result.errorMessage}');
      }
    }
  } catch (e) {
    print('❌ Exception during auth: $e');
    // Handle unexpected errors
  }
}
```

---

### Production Configuration

Production-ready configuration examples

```dart
Future<void> setupProductionApp() async {
  // Production configuration
  await MyAppSyncManager.initialize(
    backendAdapter: PocketBaseSyncAdapter(
      configuration: SyncBackendConfiguration(
        configId: 'production-backend',
        backendType: 'pocketbase',
        baseUrl: 'https://api.yourapp.com',
        projectId: 'yourapp-prod',
        connectionTimeout: Duration(seconds: 30),
        requestTimeout: Duration(seconds: 15),
        maxRetries: 3,
        environment: 'production',
        enableLogging: false, // Disable in production
        customHeaders: {
          'X-App-Version': '1.0.0',
          'X-Platform': Platform.operatingSystem,
        },
      ),
    ),
    publicCollections: [
      'announcements',
      'app_config',
      'public_data',
    ],
    autoSync: true,
    syncInterval: Duration(minutes: 5), // Less frequent in production
  );
  
  // Setup lifecycle management
  final lifecycleManager = AuthLifecycleManager();
  await lifecycleManager.initialize(
    sessionTimeoutDuration: Duration(hours: 8),
    refreshThreshold: Duration(minutes: 5),
    warningThreshold: Duration(minutes: 10),
  );
  
  lifecycleManager.startTokenRefreshCoordination();
  
  print('🚀 Production app initialized successfully');
}
```
