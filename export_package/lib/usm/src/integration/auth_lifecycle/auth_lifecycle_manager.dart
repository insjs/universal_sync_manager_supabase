/// Auth Lifecycle Management for Universal Sync Manager
///
/// This component provides comprehensive authentication lifecycle management,
/// including login/logout coordination, token refresh handling, session timeout
/// management, and simple user switching support.

import 'dart:async';
import '../my_app_sync_manager.dart';
import '../../interfaces/usm_simple_auth_interface.dart';
import '../../models/usm_auth_context.dart';

/// Authentication lifecycle events
enum AuthLifecycleEvent {
  loginStarted,
  loginSucceeded,
  loginFailed,
  logoutStarted,
  logoutCompleted,
  tokenRefreshStarted,
  tokenRefreshSucceeded,
  tokenRefreshFailed,
  sessionTimeout,
  userSwitchStarted,
  userSwitchCompleted,
}

/// Authentication lifecycle state
class AuthLifecycleState {
  final AuthState authState;
  final AuthContext? authContext;
  final AuthLifecycleEvent? lastEvent;
  final String? error;
  final DateTime lastUpdated;
  final bool isProcessing;

  const AuthLifecycleState({
    required this.authState,
    this.authContext,
    this.lastEvent,
    this.error,
    required this.lastUpdated,
    this.isProcessing = false,
  });

  /// Create initial state
  factory AuthLifecycleState.initial() {
    return AuthLifecycleState(
      authState: AuthState.public,
      lastUpdated: DateTime.now(),
    );
  }

  /// Copy with new values
  AuthLifecycleState copyWith({
    AuthState? authState,
    AuthContext? authContext,
    AuthLifecycleEvent? lastEvent,
    String? error,
    bool? isProcessing,
  }) {
    return AuthLifecycleState(
      authState: authState ?? this.authState,
      authContext: authContext ?? this.authContext,
      lastEvent: lastEvent ?? this.lastEvent,
      error: error ?? this.error,
      lastUpdated: DateTime.now(),
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }

  /// Check if user is authenticated
  bool get isAuthenticated => authState == AuthState.authenticated;

  /// Get user ID if authenticated
  String? get userId => authContext?.userId;
}

/// Authentication lifecycle manager
///
/// This class provides comprehensive authentication lifecycle management.
/// It coordinates login/logout operations, handles token refresh automatically,
/// manages session timeouts, and supports user switching.
///
/// Usage:
/// ```dart
/// // Initialize
/// final lifecycleManager = AuthLifecycleManager();
/// await lifecycleManager.initialize();
///
/// // Listen to lifecycle events
/// lifecycleManager.stateChanges.listen((state) {
///   print('Auth lifecycle state: ${state.authState}');
/// });
///
/// // Login with automatic lifecycle management
/// await lifecycleManager.login(
///   token: 'token',
///   userId: 'user123',
///   sessionDuration: Duration(hours: 8),
/// );
///
/// // Logout with cleanup
/// await lifecycleManager.logout();
/// ```
class AuthLifecycleManager {
  AuthLifecycleState _state = AuthLifecycleState.initial();
  final StreamController<AuthLifecycleState> _stateController =
      StreamController<AuthLifecycleState>.broadcast();
  final StreamController<AuthLifecycleEvent> _eventController =
      StreamController<AuthLifecycleEvent>.broadcast();

  StreamSubscription? _authStateSubscription;
  StreamSubscription? _authContextSubscription;
  Timer? _sessionTimeoutTimer;
  Timer? _tokenRefreshTimer;
  bool _isInitialized = false;

  /// Current authentication lifecycle state
  AuthLifecycleState get state => _state;

  /// Stream of authentication lifecycle state changes
  Stream<AuthLifecycleState> get stateChanges => _stateController.stream;

  /// Stream of authentication lifecycle events
  Stream<AuthLifecycleEvent> get eventStream => _eventController.stream;

  /// Initialize the lifecycle manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Listen to USM auth state changes
    _authStateSubscription = MyAppSyncManager.instance.authStateChanges
        .listen(_handleAuthStateChange);

    // Listen to USM auth context changes
    _authContextSubscription = MyAppSyncManager.instance.authContextChanges
        .listen(_handleAuthContextChange);

    _isInitialized = true;
  }

  /// Login with lifecycle management
  ///
  /// [token] - Authentication token
  /// [userId] - User identifier
  /// [organizationId] - Optional organization ID
  /// [metadata] - Optional user metadata
  /// [sessionDuration] - How long the session should last
  /// [autoRefreshInterval] - How often to refresh the token
  Future<AuthResult> login({
    required String token,
    required String userId,
    String? organizationId,
    Map<String, dynamic>? metadata,
    Duration? sessionDuration,
    Duration autoRefreshInterval = const Duration(minutes: 45),
  }) async {
    _emitEvent(AuthLifecycleEvent.loginStarted);
    _updateState(_state.copyWith(isProcessing: true));

    try {
      // Login through USM
      final result = await MyAppSyncManager.instance.login(
        token: token,
        userId: userId,
        organizationId: organizationId,
        metadata: metadata,
      );

      if (result.isSuccess) {
        _emitEvent(AuthLifecycleEvent.loginSucceeded);

        // Start session timeout if specified
        if (sessionDuration != null) {
          _startSessionTimeout(sessionDuration);
        }

        // Start automatic token refresh
        _startTokenRefresh(autoRefreshInterval);

        _updateState(_state.copyWith(isProcessing: false));
        return result;
      } else {
        _emitEvent(AuthLifecycleEvent.loginFailed);
        _updateState(_state.copyWith(
          isProcessing: false,
          error: result.errorMessage,
        ));
        return result;
      }
    } catch (e) {
      _emitEvent(AuthLifecycleEvent.loginFailed);
      _updateState(_state.copyWith(
        isProcessing: false,
        error: 'Login failed: ${e.toString()}',
      ));
      return AuthResult.failure('Login failed: ${e.toString()}');
    }
  }

  /// Logout with lifecycle management
  Future<void> logout() async {
    _emitEvent(AuthLifecycleEvent.logoutStarted);
    _updateState(_state.copyWith(isProcessing: true));

    try {
      // Clear timers
      _stopSessionTimeout();
      _stopTokenRefresh();

      // Logout through USM
      await MyAppSyncManager.instance.logout();

      _emitEvent(AuthLifecycleEvent.logoutCompleted);
      _updateState(_state.copyWith(isProcessing: false));
    } catch (e) {
      _updateState(_state.copyWith(
        isProcessing: false,
        error: 'Logout failed: ${e.toString()}',
      ));
    }
  }

  /// Switch to a different user
  Future<AuthResult> switchUser({
    required String token,
    required String userId,
    String? organizationId,
    Map<String, dynamic>? metadata,
    Duration? sessionDuration,
    Duration autoRefreshInterval = const Duration(minutes: 45),
  }) async {
    _emitEvent(AuthLifecycleEvent.userSwitchStarted);

    // Logout current user first
    await logout();

    // Login as new user
    final result = await login(
      token: token,
      userId: userId,
      organizationId: organizationId,
      metadata: metadata,
      sessionDuration: sessionDuration,
      autoRefreshInterval: autoRefreshInterval,
    );

    if (result.isSuccess) {
      _emitEvent(AuthLifecycleEvent.userSwitchCompleted);
    }

    return result;
  }

  /// Manually refresh authentication token
  Future<AuthResult> refreshToken(String newToken,
      [DateTime? newTokenExpiry]) async {
    _emitEvent(AuthLifecycleEvent.tokenRefreshStarted);

    try {
      final result = await MyAppSyncManager.instance.refreshAuthentication(
        newToken: newToken,
        newTokenExpiry: newTokenExpiry,
      );

      if (result.isSuccess) {
        _emitEvent(AuthLifecycleEvent.tokenRefreshSucceeded);
      } else {
        _emitEvent(AuthLifecycleEvent.tokenRefreshFailed);
      }

      return result;
    } catch (e) {
      _emitEvent(AuthLifecycleEvent.tokenRefreshFailed);
      return AuthResult.failure('Token refresh failed: ${e.toString()}');
    }
  }

  /// Handle USM auth state changes
  void _handleAuthStateChange(AuthState authState) {
    _updateState(_state.copyWith(authState: authState));
  }

  /// Handle USM auth context changes
  void _handleAuthContextChange(AuthContext? authContext) {
    _updateState(_state.copyWith(authContext: authContext));
  }

  /// Start session timeout timer
  void _startSessionTimeout(Duration sessionDuration) {
    _stopSessionTimeout();
    _sessionTimeoutTimer = Timer(sessionDuration, () {
      _emitEvent(AuthLifecycleEvent.sessionTimeout);
      logout(); // Auto-logout on session timeout
    });
  }

  /// Stop session timeout timer
  void _stopSessionTimeout() {
    _sessionTimeoutTimer?.cancel();
    _sessionTimeoutTimer = null;
  }

  /// Start automatic token refresh
  void _startTokenRefresh(Duration refreshInterval) {
    _stopTokenRefresh();
    _tokenRefreshTimer = Timer.periodic(refreshInterval, (_) {
      // This is a placeholder - in a real implementation, you would
      // call your auth provider's refresh method and then update USM
      print('Token refresh timer triggered - implement auth provider refresh');
    });
  }

  /// Stop automatic token refresh
  void _stopTokenRefresh() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
  }

  /// Update internal state
  void _updateState(AuthLifecycleState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  /// Emit lifecycle event
  void _emitEvent(AuthLifecycleEvent event) {
    _eventController.add(event);
  }

  /// Check if authenticated
  bool get isAuthenticated => _state.isAuthenticated;

  /// Check if currently processing
  bool get isProcessing => _state.isProcessing;

  /// Get current user ID
  String? get userId => _state.userId;

  /// Dispose resources
  Future<void> dispose() async {
    await _authStateSubscription?.cancel();
    await _authContextSubscription?.cancel();
    _stopSessionTimeout();
    _stopTokenRefresh();
    await _stateController.close();
    await _eventController.close();
    _isInitialized = false;
  }
}

/// Session management utilities
class SessionManager {
  static const Duration _defaultSessionDuration = Duration(hours: 8);
  static const Duration _defaultTokenRefreshInterval = Duration(minutes: 45);

  /// Create a session with default settings
  static Future<AuthResult> createSession({
    required String token,
    required String userId,
    String? organizationId,
    Map<String, dynamic>? metadata,
    Duration? sessionDuration,
    Duration? tokenRefreshInterval,
  }) async {
    final lifecycleManager = AuthLifecycleManager();
    await lifecycleManager.initialize();

    return await lifecycleManager.login(
      token: token,
      userId: userId,
      organizationId: organizationId,
      metadata: metadata,
      sessionDuration: sessionDuration ?? _defaultSessionDuration,
      autoRefreshInterval: tokenRefreshInterval ?? _defaultTokenRefreshInterval,
    );
  }

  /// End the current session
  static Future<void> endSession() async {
    final lifecycleManager = AuthLifecycleManager();
    await lifecycleManager.logout();
  }

  /// Switch session to different user
  static Future<AuthResult> switchSession({
    required String token,
    required String userId,
    String? organizationId,
    Map<String, dynamic>? metadata,
  }) async {
    final lifecycleManager = AuthLifecycleManager();
    await lifecycleManager.initialize();

    return await lifecycleManager.switchUser(
      token: token,
      userId: userId,
      organizationId: organizationId,
      metadata: metadata,
      sessionDuration: _defaultSessionDuration,
    );
  }
}

/// Token refresh coordinator
class TokenRefreshCoordinator {
  static Timer? _globalRefreshTimer;
  static Future<String> Function()? _refreshCallback;

  /// Set up global token refresh
  static void setupGlobalRefresh({
    required Future<String> Function() refreshCallback,
    Duration refreshInterval = const Duration(minutes: 45),
  }) {
    _refreshCallback = refreshCallback;
    _globalRefreshTimer?.cancel();

    _globalRefreshTimer = Timer.periodic(refreshInterval, (_) async {
      await _performGlobalRefresh();
    });
  }

  /// Perform global token refresh
  static Future<void> _performGlobalRefresh() async {
    if (_refreshCallback == null) return;

    try {
      final newToken = await _refreshCallback!();

      if (MyAppSyncManager.instance.isAuthenticated) {
        await MyAppSyncManager.instance.refreshAuthentication(
          newToken: newToken,
        );
      }
    } catch (e) {
      print('Global token refresh failed: $e');
    }
  }

  /// Stop global token refresh
  static void stopGlobalRefresh() {
    _globalRefreshTimer?.cancel();
    _globalRefreshTimer = null;
    _refreshCallback = null;
  }
}

/// User switching utilities
class UserSwitchManager {
  static final Map<String, Map<String, dynamic>> _savedUserSessions = {};

  /// Save current user session for later restoration
  static void saveCurrentSession(String sessionId) {
    if (MyAppSyncManager.instance.isAuthenticated) {
      final currentUser = MyAppSyncManager.instance.currentUser;
      if (currentUser != null) {
        _savedUserSessions[sessionId] = {
          'userId': currentUser.userId,
          'organizationId': currentUser.organizationId,
          'metadata': currentUser.metadata,
          'savedAt': DateTime.now().toIso8601String(),
        };
      }
    }
  }

  /// Restore a saved user session
  static Future<AuthResult> restoreSession(
    String sessionId,
    String newToken,
  ) async {
    final savedSession = _savedUserSessions[sessionId];
    if (savedSession == null) {
      return AuthResult.failure('No saved session found for ID: $sessionId');
    }

    return await MyAppSyncManager.instance.login(
      token: newToken,
      userId: savedSession['userId'],
      organizationId: savedSession['organizationId'],
      metadata: Map<String, dynamic>.from(savedSession['metadata'] ?? {}),
    );
  }

  /// List saved sessions
  static Map<String, Map<String, dynamic>> get savedSessions =>
      Map.unmodifiable(_savedUserSessions);

  /// Remove a saved session
  static void removeSavedSession(String sessionId) {
    _savedUserSessions.remove(sessionId);
  }

  /// Clear all saved sessions
  static void clearAllSavedSessions() {
    _savedUserSessions.clear();
  }
}
