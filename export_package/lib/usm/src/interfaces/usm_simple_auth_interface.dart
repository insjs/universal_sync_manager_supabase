/// Simple authentication interface for Universal Sync Manager
///
/// This interface provides a simplified binary authentication state pattern
/// as specified in the Enhanced Authentication Integration Pattern Phase 2.4.
/// It focuses on practical authentication patterns without over-engineering
/// complex permission systems.

import 'dart:async';
import '../models/usm_auth_context.dart';

/// Binary authentication states
enum AuthState {
  /// User is authenticated and can access private data
  authenticated,

  /// User is not authenticated and can only access public data
  public,
}

/// Simple authentication result
class SimpleAuthResult {
  final bool success;
  final AuthState state;
  final String? userId;
  final String? error;
  final Map<String, dynamic>? userMetadata;

  const SimpleAuthResult({
    required this.success,
    required this.state,
    this.userId,
    this.error,
    this.userMetadata,
  });

  factory SimpleAuthResult.authenticated({
    required String userId,
    Map<String, dynamic>? metadata,
  }) {
    return SimpleAuthResult(
      success: true,
      state: AuthState.authenticated,
      userId: userId,
      userMetadata: metadata,
    );
  }

  factory SimpleAuthResult.public() {
    return const SimpleAuthResult(
      success: true,
      state: AuthState.public,
    );
  }

  factory SimpleAuthResult.failure(String error) {
    return SimpleAuthResult(
      success: false,
      state: AuthState.public,
      error: error,
    );
  }
}

/// Simple authentication interface for USM backend adapters
abstract class ISimpleAuth {
  /// Current authentication state
  AuthState get currentState;

  /// Whether the user is currently authenticated
  bool get isAuthenticated => currentState == AuthState.authenticated;

  /// Whether the user is in public mode
  bool get isPublic => currentState == AuthState.public;

  /// Current user ID (null if not authenticated)
  String? get currentUserId;

  /// Stream of authentication state changes
  Stream<SimpleAuthResult> get authStateChanges;

  /// Attempt to authenticate with provided credentials
  Future<SimpleAuthResult> authenticate(Map<String, dynamic> credentials);

  /// Sign out and return to public state
  Future<void> signOut();

  /// Refresh current authentication token
  Future<SimpleAuthResult> refreshAuth();

  /// Check if current authentication is still valid
  Future<bool> validateAuth();

  /// Handle authentication failures gracefully
  Future<SimpleAuthResult> handleAuthFailure(dynamic error);
}

/// Enhanced simple auth interface that integrates with USM auth context
abstract class IEnhancedSimpleAuth extends ISimpleAuth {
  /// Current auth context (from Phase 1)
  AuthContext? get currentAuthContext;

  /// Update auth context from external auth provider
  Future<void> updateAuthContext(AuthContext context);

  /// Create auth context from simple auth result
  AuthContext? createAuthContextFromResult(SimpleAuthResult result);

  /// Get user metadata for backend filtering
  Map<String, dynamic> getUserMetadata();

  /// Get organization context for multi-tenant scenarios
  String? getOrganizationId();
}

/// Default implementation of enhanced simple auth
class DefaultSimpleAuth implements IEnhancedSimpleAuth {
  AuthState _currentState = AuthState.public;
  String? _currentUserId;
  AuthContext? _authContext;
  Map<String, dynamic>? _userMetadata;

  final StreamController<SimpleAuthResult> _stateController =
      StreamController<SimpleAuthResult>.broadcast();

  @override
  AuthState get currentState => _currentState;

  @override
  bool get isAuthenticated => _currentState == AuthState.authenticated;

  @override
  bool get isPublic => _currentState == AuthState.public;

  @override
  String? get currentUserId => _currentUserId;

  @override
  AuthContext? get currentAuthContext => _authContext;

  @override
  Stream<SimpleAuthResult> get authStateChanges => _stateController.stream;

  @override
  Future<SimpleAuthResult> authenticate(
      Map<String, dynamic> credentials) async {
    try {
      // This would be overridden by specific implementations
      // For now, provide a basic pattern

      final email = credentials['email'] as String?;
      final password = credentials['password'] as String?;

      if (email == null ||
          password == null ||
          email.isEmpty ||
          password.isEmpty) {
        return SimpleAuthResult.failure('Email and password required');
      }

      // Simulate authentication (implement per backend)
      _currentState = AuthState.authenticated;
      _currentUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      _userMetadata = {
        'email': email,
        'loginTime': DateTime.now().toIso8601String(),
      };

      // Create auth context
      _authContext = AuthContext.authenticated(
        userId: _currentUserId!,
        userContext: _userMetadata!,
        validity: const Duration(hours: 24),
      );

      final result = SimpleAuthResult.authenticated(
        userId: _currentUserId!,
        metadata: _userMetadata,
      );

      _stateController.add(result);
      return result;
    } catch (e) {
      final result = SimpleAuthResult.failure('Authentication failed: $e');
      _stateController.add(result);
      return result;
    }
  }

  @override
  Future<void> signOut() async {
    _currentState = AuthState.public;
    _currentUserId = null;
    _authContext = null;
    _userMetadata = null;

    final result = SimpleAuthResult.public();
    _stateController.add(result);
  }

  @override
  Future<SimpleAuthResult> refreshAuth() async {
    if (_currentState == AuthState.public) {
      return SimpleAuthResult.public();
    }

    try {
      // Implement token refresh logic per backend
      // For now, just validate current state
      if (_authContext?.isValid == true) {
        return SimpleAuthResult.authenticated(
          userId: _currentUserId!,
          metadata: _userMetadata,
        );
      } else {
        await signOut();
        return SimpleAuthResult.failure('Auth session expired');
      }
    } catch (e) {
      return handleAuthFailure(e);
    }
  }

  @override
  Future<bool> validateAuth() async {
    if (_currentState == AuthState.public) return true;

    return _authContext?.isValid ?? false;
  }

  @override
  Future<SimpleAuthResult> handleAuthFailure(dynamic error) async {
    // Graceful fallback for auth failures
    await signOut();

    final result = SimpleAuthResult.failure('Auth failure: $error');
    _stateController.add(result);
    return result;
  }

  @override
  Future<void> updateAuthContext(AuthContext context) async {
    _authContext = context;
    _currentUserId = context.userId;
    _userMetadata = context.userContext;

    if (context.userId != null) {
      _currentState = AuthState.authenticated;

      final result = SimpleAuthResult.authenticated(
        userId: context.userId!,
        metadata: context.userContext,
      );
      _stateController.add(result);
    } else {
      await signOut();
    }
  }

  @override
  AuthContext? createAuthContextFromResult(SimpleAuthResult result) {
    if (result.state == AuthState.authenticated && result.userId != null) {
      return AuthContext.authenticated(
        userId: result.userId!,
        userContext: result.userMetadata ?? {},
        validity: const Duration(hours: 24),
      );
    }
    return null;
  }

  @override
  Map<String, dynamic> getUserMetadata() {
    return _userMetadata ?? {};
  }

  @override
  String? getOrganizationId() {
    return _authContext?.organizationId ??
        _userMetadata?['organizationId'] as String?;
  }

  /// Dispose resources
  void dispose() {
    _stateController.close();
  }
}
