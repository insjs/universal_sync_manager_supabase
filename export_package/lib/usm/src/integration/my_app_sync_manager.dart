/// Simple App Integration Pattern for Universal Sync Manager
///
/// This provides a high-level wrapper for easy integration with common app architectures.
/// Designed for simplicity - binary auth state (authenticated vs. public) with automatic
/// sync initialization and lifecycle management.

import 'dart:async';
import '../models/usm_auth_context.dart';
import '../services/usm_token_manager.dart';
import '../interfaces/usm_simple_auth_interface.dart';
import '../interfaces/usm_sync_backend_adapter.dart';
import '../core/usm_universal_sync_manager.dart';
import '../config/usm_sync_enums.dart';
import '../models/usm_app_sync_auth_configuration.dart';
import '../models/usm_sync_collection.dart';

/// Result of authentication operations
class AuthResult {
  final bool isSuccess;
  final String? errorMessage;

  const AuthResult._(this.isSuccess, this.errorMessage);

  factory AuthResult.success() => const AuthResult._(true, null);
  factory AuthResult.failure(String message) => AuthResult._(false, message);
}

/// High-level wrapper for Universal Sync Manager with simplified authentication
///
/// Usage:
/// ```dart
/// // Initialize once in your app
/// await MyAppSyncManager.initialize(
///   backendAdapter: MyBackendAdapter(),
///   publicCollections: ['public_data'],
/// );
///
/// // Login with any auth provider
/// await MyAppSyncManager.login(userToken, userId: 'user123');
///
/// // Check auth state
/// if (MyAppSyncManager.instance.isAuthenticated) {
///   // User is logged in, sync is active
/// }
///
/// // Logout
/// await MyAppSyncManager.logout();
/// ```
class MyAppSyncManager {
  static MyAppSyncManager? _instance;
  static MyAppSyncManager get instance {
    if (_instance == null) {
      throw StateError(
          'MyAppSyncManager not initialized. Call MyAppSyncManager.initialize() first.');
    }
    return _instance!;
  }

  final UniversalSyncManager _syncManager;
  final List<String> _publicCollections;

  AuthState _authState = AuthState.public;
  AuthContext? _currentAuthContext;
  TokenManager? _tokenManager;

  // Stream controllers for auth state changes
  final StreamController<AuthState> _authStateController =
      StreamController<AuthState>.broadcast();
  final StreamController<AuthContext?> _authContextController =
      StreamController<AuthContext?>.broadcast();

  MyAppSyncManager._({
    required UniversalSyncManager syncManager,
    required List<String> publicCollections,
  })  : _syncManager = syncManager,
        _publicCollections = publicCollections;

  /// Initialize MyAppSyncManager with backend adapter and configuration
  ///
  /// [backendAdapter] - The backend adapter to use (PocketBase, Firebase, Supabase, etc.)
  /// [publicCollections] - Collections that can be accessed without authentication
  /// [autoSync] - Whether to automatically start syncing on authentication (default: true)
  /// [syncInterval] - How often to sync data (default: 30 seconds)
  static Future<void> initialize({
    required ISyncBackendAdapter backendAdapter,
    List<String> publicCollections = const [],
    bool autoSync = true,
    Duration syncInterval = const Duration(seconds: 30),
  }) async {
    if (_instance != null) {
      throw StateError('MyAppSyncManager already initialized');
    }

    // Create UniversalSyncManager instance
    final syncManager = UniversalSyncManager(
      backendAdapter: backendAdapter,
      syncInterval: syncInterval,
      enableAutoSync: autoSync,
    );

    _instance = MyAppSyncManager._(
      syncManager: syncManager,
      publicCollections: publicCollections,
    );

    // Initialize with public-only access
    await _instance!._initializePublicSync();
  }

  /// Current authentication state
  AuthState get authState => _authState;

  /// Whether user is currently authenticated
  bool get isAuthenticated => _authState == AuthState.authenticated;

  /// Current authenticated user context (null if not authenticated)
  AuthContext? get currentUser => _currentAuthContext;

  /// Stream of authentication state changes
  Stream<AuthState> get authStateChanges => _authStateController.stream;

  /// Stream of authentication context changes
  Stream<AuthContext?> get authContextChanges => _authContextController.stream;

  /// Login with authentication token
  ///
  /// [token] - Authentication token from your auth provider
  /// [userId] - User identifier
  /// [organizationId] - Optional organization/tenant identifier
  /// [metadata] - Optional additional user metadata
  /// [refreshToken] - Optional refresh token for automatic token renewal
  /// [tokenExpiry] - When the token expires (for automatic refresh)
  Future<AuthResult> login({
    required String token,
    required String userId,
    String? organizationId,
    Map<String, dynamic>? metadata,
    String? refreshToken,
    DateTime? tokenExpiry,
  }) async {
    try {
      // Validate inputs
      if (token.trim().isEmpty || userId.trim().isEmpty) {
        return AuthResult.failure('Invalid token or user ID');
      }

      // Create auth context
      final authContext = AuthContext.authenticated(
        userId: userId,
        organizationId: organizationId,
        credentials: {'token': token},
        metadata: metadata ?? {},
      );

      // Create token manager if refresh token provided
      TokenManager? tokenManager;
      if (refreshToken != null) {
        tokenManager = TokenManager();
      }

      // Create auth configuration
      final authConfig = AppSyncAuthConfiguration(
        userId: userId,
        token: token,
        organizationId: organizationId,
        metadata: metadata ?? {},
        tokenManager: tokenManager,
      );

      // Update sync manager with authentication
      await _syncManager.updateAuthConfiguration(authConfig);

      // Update internal state
      _currentAuthContext = authContext;
      _tokenManager = tokenManager;
      _authState = AuthState.authenticated;

      // Notify listeners
      _authStateController.add(_authState);
      _authContextController.add(_currentAuthContext);

      // Start authenticated sync
      await _initializeAuthenticatedSync();

      return AuthResult.success();
    } catch (e) {
      return AuthResult.failure('Login failed: ${e.toString()}');
    }
  }

  /// Logout and clear authentication
  Future<void> logout() async {
    try {
      // Clear auth configuration
      await _syncManager.clearAuthConfiguration();

      // Update internal state
      _currentAuthContext = null;
      _tokenManager = null;
      _authState = AuthState.public;

      // Notify listeners
      _authStateController.add(_authState);
      _authContextController.add(_currentAuthContext);

      // Switch back to public-only sync
      await _initializePublicSync();
    } catch (e) {
      // Log error but don't throw - logout should always succeed
      print('Warning: Error during logout: $e');
    }
  }

  /// Switch to a different user (logout current, login new)
  Future<AuthResult> switchUser({
    required String token,
    required String userId,
    String? organizationId,
    Map<String, dynamic>? metadata,
    String? refreshToken,
    DateTime? tokenExpiry,
  }) async {
    await logout();
    return await login(
      token: token,
      userId: userId,
      organizationId: organizationId,
      metadata: metadata,
      refreshToken: refreshToken,
      tokenExpiry: tokenExpiry,
    );
  }

  /// Refresh the current authentication token
  Future<AuthResult> refreshAuthentication({
    required String newToken,
    DateTime? newTokenExpiry,
  }) async {
    if (!isAuthenticated || _currentAuthContext == null) {
      return AuthResult.failure('Not currently authenticated');
    }

    try {
      // Update auth context with new token
      final updatedAuthContext = AuthContext.authenticated(
        userId: _currentAuthContext!.userId!,
        organizationId: _currentAuthContext!.organizationId,
        metadata: _currentAuthContext!.metadata,
        credentials: {'token': newToken},
      );

      // Create updated auth configuration
      final authConfig = AppSyncAuthConfiguration(
        userId: updatedAuthContext.userId,
        token: newToken,
        organizationId: updatedAuthContext.organizationId,
        metadata: updatedAuthContext.metadata,
        tokenManager: _tokenManager,
      );

      // Update sync manager
      await _syncManager.updateAuthConfiguration(authConfig);

      // Update internal state
      _currentAuthContext = updatedAuthContext;

      // Notify listeners
      _authContextController.add(_currentAuthContext);

      return AuthResult.success();
    } catch (e) {
      return AuthResult.failure('Token refresh failed: ${e.toString()}');
    }
  }

  /// Get the underlying sync manager for advanced operations
  UniversalSyncManager get syncManager => _syncManager;

  /// Initialize public-only synchronization
  Future<void> _initializePublicSync() async {
    if (_publicCollections.isNotEmpty) {
      // Configure for public collections only
      final collections = _publicCollections
          .map((name) => SyncCollection(
              name: name, syncDirection: SyncDirection.bidirectional))
          .toList();

      await _syncManager.configure(collections: collections);
      await _syncManager.startSync();
    }
  }

  /// Initialize authenticated synchronization
  Future<void> _initializeAuthenticatedSync() async {
    // In authenticated mode, we typically sync all collections
    // This can be customized based on user roles/permissions
    await _syncManager.startSync();
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _authStateController.close();
    await _authContextController.close();
    await _syncManager.dispose();
    _instance = null;
  }
}
