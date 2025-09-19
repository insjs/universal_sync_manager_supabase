# Authentication Guide

Complete guide for implementing authentication with Universal Sync Manager and Supabase.

## 📋 Overview

USM integrates seamlessly with Supabase Auth to provide secure, session-managed synchronization. The system automatically handles authentication state and applies it to all sync operations.

## 🔐 Authentication Patterns

### 1. Basic Email/Password Authentication

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UniversalSyncManager _syncManager;

  AuthService(this._syncManager);

  // Sign up new user
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String organizationId,
    required String name,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'organization_id': organizationId,
          'name': name,
        },
      );

      if (response.user != null) {
        // Create user profile in database
        await _createUserProfile(response.user!, organizationId, name);
      }

      return response;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign in existing user
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Sync manager automatically uses the authenticated session
      // No additional setup required for sync operations

      return response;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();

      // Clear any cached sync data if needed
      await _syncManager.clearCache();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Create user profile after signup
  Future<void> _createUserProfile(User user, String organizationId, String name) async {
    final profileData = {
      'id': user.id,
      'organization_id': organizationId,
      'name': name,
      'email': user.email!,
      'is_active': true,
      'created_by': user.id,
      'updated_by': user.id,
      'is_dirty': true,
      'sync_version': 0,
      'is_deleted': false,
    };

    final result = await _syncManager.create('user_profiles', profileData);

    if (!result.isSuccess) {
      print('Warning: Failed to create user profile: ${result.error?.message}');
    }
  }
}
```

### 2. Authentication State Management

```dart
class AuthStateManager {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UniversalSyncManager _syncManager;

  AuthStateManager(this._syncManager) {
    _setupAuthListener();
  }

  // Listen for authentication state changes
  void _setupAuthListener() {
    _supabase.auth.onAuthStateChange.listen((event) async {
      final session = event.session;
      final user = session?.user;

      switch (event.event) {
        case AuthChangeEvent.signedIn:
          if (user != null) {
            await _handleSignIn(user);
          }
          break;

        case AuthChangeEvent.signedOut:
          await _handleSignOut();
          break;

        case AuthChangeEvent.tokenRefreshed:
          await _handleTokenRefresh(session);
          break;

        default:
          break;
      }
    });
  }

  Future<void> _handleSignIn(User user) async {
    print('User signed in: ${user.email}');

    // Sync manager automatically uses the new session
    // Trigger initial sync for user data
    try {
      await _syncManager.syncAll();
      print('Initial sync completed for user: ${user.id}');
    } catch (e) {
      print('Initial sync failed: $e');
    }
  }

  Future<void> _handleSignOut() async {
    print('User signed out');

    // Clear local sync cache
    await _syncManager.clearCache();

    // Reset sync state
    await _syncManager.reset();
  }

  Future<void> _handleTokenRefresh(Session? session) async {
    if (session != null) {
      print('Auth token refreshed');

      // Sync manager automatically uses the new token
      // Optionally trigger a sync to ensure data consistency
      await _syncManager.syncEntity('user_profiles');
    }
  }

  // Get current authentication state
  bool get isAuthenticated => _supabase.auth.currentUser != null;
  User? get currentUser => _supabase.auth.currentUser;
  String? get organizationId => _supabase.auth.currentUser?.userMetadata?['organization_id'];
}
```

### 3. Pre-Authentication Operations

```dart
class PublicDataService {
  final UniversalSyncManager _syncManager;

  PublicDataService(this._syncManager);

  // Read public data without authentication
  Future<List<Map<String, dynamic>>> getAppSettings() async {
    try {
      final result = await _syncManager.query(
        'app_settings',
        SyncQuery(), // Empty query gets all records
      );

      if (result.isSuccess) {
        return result.data ?? [];
      } else {
        print('Failed to load app settings: ${result.error?.message}');
        return [];
      }
    } catch (e) {
      print('Error loading app settings: $e');
      return [];
    }
  }

  // Read specific public record
  Future<Map<String, dynamic>?> getAppSetting(String key) async {
    try {
      final result = await _syncManager.query(
        'app_settings',
        SyncQuery(
          filters: {'key': key},
          limit: 1,
        ),
      );

      if (result.isSuccess && result.data?.isNotEmpty == true) {
        return result.data!.first;
      } else {
        print('App setting not found: $key');
        return null;
      }
    } catch (e) {
      print('Error loading app setting: $e');
      return null;
    }
  }

  // Public operations work without authentication
  // because app_settings table allows public read access
}
```

## 🔒 Security Best Practices

### 1. JWT Token Structure

Ensure your JWT tokens include organization context:

```json
{
  "sub": "user-id",
  "email": "user@example.com",
  "user_metadata": {
    "organization_id": "org-123",
    "name": "John Doe"
  },
  "app_metadata": {
    "role": "user"
  }
}
```

### 2. Row Level Security (RLS) Policies

Your RLS policies should use the organization_id from JWT:

```sql
-- Users can only access their organization's data
CREATE POLICY "organization_isolation"
  ON user_profiles FOR ALL
  USING (auth.jwt() ->> 'organization_id' = organization_id);
```

### 3. Secure Token Storage

```dart
class SecureAuthStorage {
  static const String _tokenKey = 'supabase_auth_token';

  // Store token securely
  static Future<void> storeToken(String token) async {
    // Use flutter_secure_storage for encrypted storage
    // Never store in plain text
  }

  // Retrieve token securely
  static Future<String?> getToken() async {
    // Retrieve from secure storage
  }
}
```

## 🧪 Testing Authentication

### 1. Authentication Test Suite

```dart
class AuthTestSuite {
  final AuthService _authService;
  final PublicDataService _publicDataService;

  AuthTestSuite(this._authService, this._publicDataService);

  Future<void> runAllTests() async {
    print('🧪 Running Authentication Tests...');

    await testPreAuthOperations();
    await testSignUp();
    await testSignIn();
    await testAuthenticatedOperations();
    await testSignOut();

    print('✅ Authentication Tests Complete');
  }

  Future<void> testPreAuthOperations() async {
    print('📋 Testing pre-auth operations...');

    // Should work without authentication
    final settings = await _publicDataService.getAppSettings();
    print('✅ Pre-auth app settings loaded: ${settings.length} items');

    final version = await _publicDataService.getAppSetting('app_version');
    print('✅ Pre-auth app version loaded: ${version?['value']}');
  }

  Future<void> testSignUp() async {
    print('📝 Testing user signup...');

    try {
      final response = await _authService.signUp(
        email: 'test-${DateTime.now().millisecondsSinceEpoch}@example.com',
        password: 'testpassword123',
        organizationId: 'org-test-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Test User',
      );

      if (response.user != null) {
        print('✅ User signup successful: ${response.user!.email}');
      } else {
        print('❌ User signup failed');
      }
    } catch (e) {
      print('❌ Signup test failed: $e');
    }
  }

  Future<void> testSignIn() async {
    print('🔐 Testing user signin...');

    try {
      final response = await _authService.signIn(
        email: 'admin@has.com',
        password: '123456789',
      );

      if (response.user != null) {
        print('✅ User signin successful: ${response.user!.email}');
      } else {
        print('❌ User signin failed');
      }
    } catch (e) {
      print('❌ Signin test failed: $e');
    }
  }

  Future<void> testAuthenticatedOperations() async {
    print('🔒 Testing authenticated operations...');

    // These should work after authentication
    // Test will be implemented in CRUD operations guide
    print('✅ Authenticated operations test placeholder');
  }

  Future<void> testSignOut() async {
    print('🚪 Testing user signout...');

    try {
      await _authService.signOut();
      print('✅ User signout successful');
    } catch (e) {
      print('❌ Signout test failed: $e');
    }
  }
}
```

### 2. Integration Test

```dart
void main() {
  late AuthService authService;
  late PublicDataService publicDataService;
  late AuthTestSuite testSuite;

  setUp(() async {
    // Initialize services
    final syncManager = await initializeSyncManager();
    authService = AuthService(syncManager);
    publicDataService = PublicDataService(syncManager);
    testSuite = AuthTestSuite(authService, publicDataService);
  });

  test('Complete authentication flow', () async {
    await testSuite.runAllTests();
  });
}
```

## 🔄 Session Management

### 1. Automatic Session Handling

USM automatically handles Supabase sessions:

```dart
class SessionManager {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  // Check if session is valid
  bool get isSessionValid {
    final session = currentSession;
    if (session == null) return false;

    // Check if token is expired
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return false;

    return DateTime.now().isBefore(
      DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000)
    );
  }

  // Refresh session if needed
  Future<void> ensureValidSession() async {
    if (!isSessionValid) {
      try {
        await _supabase.auth.refreshSession();
      } catch (e) {
        // Handle refresh failure
        await _supabase.auth.signOut();
        throw Exception('Session refresh failed');
      }
    }
  }
}
```

### 2. Background Session Refresh

```dart
class BackgroundSessionRefresher {
  Timer? _refreshTimer;

  void start(Session session) {
    // Calculate refresh time (5 minutes before expiry)
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return;

    final expiryTime = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
    final refreshTime = expiryTime.subtract(Duration(minutes: 5));
    final now = DateTime.now();

    if (refreshTime.isAfter(now)) {
      final duration = refreshTime.difference(now);
      _refreshTimer = Timer(duration, () async {
        try {
          await Supabase.instance.client.auth.refreshSession();
          print('Session refreshed automatically');
        } catch (e) {
          print('Automatic session refresh failed: $e');
        }
      });
    }
  }

  void stop() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }
}
```

## 🚨 Error Handling

### 1. Authentication Errors

```dart
class AuthErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is AuthException) {
      switch (error.message) {
        case 'Invalid login credentials':
          return 'Invalid email or password';
        case 'Email not confirmed':
          return 'Please check your email and confirm your account';
        case 'Too many requests':
          return 'Too many login attempts. Please try again later';
        default:
          return 'Authentication failed: ${error.message}';
      }
    }

    return 'An unexpected error occurred';
  }

  static void handleAuthError(dynamic error, StackTrace stackTrace) {
    final message = getErrorMessage(error);
    print('Auth Error: $message');
    print('Stack trace: $stackTrace');

    // Log to analytics or error reporting service
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
}
```

## 📋 Next Steps

1. **[CRUD Operations](../crud_operations.md)** - Start working with authenticated data
2. **[Sync Features](../sync_features.md)** - Understand synchronization behavior
3. **[Testing Guide](../testing.md)** - Test your authentication implementation

## 🆘 Troubleshooting

**Session Issues:**
- Check JWT token contains required claims
- Verify RLS policies match your token structure
- Ensure session refresh is working properly

**Authentication Failures:**
- Verify Supabase project configuration
- Check email confirmation settings
- Confirm password policy requirements

**Permission Errors:**
- Review RLS policies for your tables
- Check organization_id in user metadata
- Verify user roles and permissions