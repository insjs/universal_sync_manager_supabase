/// Riverpod state management integration for Universal Sync Manager
///
/// This provides seamless integration with Riverpod state management,
/// making it easy to manage USM authentication state in your Riverpod app.

import 'dart:async';
import '../my_app_sync_manager.dart';
import '../../interfaces/usm_simple_auth_interface.dart';
import '../../models/usm_auth_context.dart';

/// Authentication sync state for Riverpod
class RiverpodAuthSyncState {
  final AuthState authState;
  final AuthContext? authContext;
  final bool isLoading;
  final String? error;
  final DateTime lastUpdated;

  const RiverpodAuthSyncState({
    required this.authState,
    this.authContext,
    this.isLoading = false,
    this.error,
    required this.lastUpdated,
  });

  /// Create initial state
  factory RiverpodAuthSyncState.initial() {
    return RiverpodAuthSyncState(
      authState: AuthState.public,
      lastUpdated: DateTime.now(),
    );
  }

  /// Create authenticated state
  factory RiverpodAuthSyncState.authenticated({
    required AuthContext authContext,
    bool isLoading = false,
  }) {
    return RiverpodAuthSyncState(
      authState: AuthState.authenticated,
      authContext: authContext,
      isLoading: isLoading,
      lastUpdated: DateTime.now(),
    );
  }

  /// Create public state
  factory RiverpodAuthSyncState.public({
    bool isLoading = false,
    String? error,
  }) {
    return RiverpodAuthSyncState(
      authState: AuthState.public,
      isLoading: isLoading,
      error: error,
      lastUpdated: DateTime.now(),
    );
  }

  /// Create loading state
  RiverpodAuthSyncState copyWithLoading() {
    return RiverpodAuthSyncState(
      authState: authState,
      authContext: authContext,
      isLoading: true,
      lastUpdated: DateTime.now(),
    );
  }

  /// Create error state
  RiverpodAuthSyncState copyWithError(String error) {
    return RiverpodAuthSyncState(
      authState: authState,
      authContext: authContext,
      isLoading: false,
      error: error,
      lastUpdated: DateTime.now(),
    );
  }

  /// Copy with new values
  RiverpodAuthSyncState copyWith({
    AuthState? authState,
    AuthContext? authContext,
    bool? isLoading,
    String? error,
  }) {
    return RiverpodAuthSyncState(
      authState: authState ?? this.authState,
      authContext: authContext ?? this.authContext,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastUpdated: DateTime.now(),
    );
  }

  /// Check if user is authenticated
  bool get isAuthenticated => authState == AuthState.authenticated;

  /// Check if user is public/not authenticated
  bool get isPublic => authState == AuthState.public;

  /// Get user ID if authenticated
  String? get userId => authContext?.userId;

  /// Get organization ID if available
  String? get organizationId => authContext?.organizationId;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RiverpodAuthSyncState &&
            runtimeType == other.runtimeType &&
            authState == other.authState &&
            authContext == other.authContext &&
            isLoading == other.isLoading &&
            error == other.error;
  }

  @override
  int get hashCode {
    return authState.hashCode ^
        authContext.hashCode ^
        isLoading.hashCode ^
        error.hashCode;
  }
}

/// StateNotifier for managing authentication sync state
class AuthSyncNotifier {
  RiverpodAuthSyncState _state = RiverpodAuthSyncState.initial();
  StreamSubscription? _authStateSubscription;
  final StreamController<RiverpodAuthSyncState> _stateController =
      StreamController<RiverpodAuthSyncState>.broadcast();

  /// Current state
  RiverpodAuthSyncState get state => _state;

  /// State stream
  Stream<RiverpodAuthSyncState> get stream => _stateController.stream;

  /// Initialize the notifier
  void initialize() {
    // Listen to USM auth state changes
    _authStateSubscription =
        MyAppSyncManager.instance.authStateChanges.listen((authState) {
      _updateFromUSM(authState);
    });
  }

  /// Login
  Future<void> login({
    required String token,
    required String userId,
    String? organizationId,
    Map<String, dynamic>? metadata,
  }) async {
    _updateState(_state.copyWithLoading());

    try {
      final result = await MyAppSyncManager.instance.login(
        token: token,
        userId: userId,
        organizationId: organizationId,
        metadata: metadata,
      );
      if (!result.isSuccess) {
        _updateState(
            _state.copyWithError(result.errorMessage ?? 'Login failed'));
      }
      // Success will be handled by USM state change listener
    } catch (e) {
      _updateState(_state.copyWithError('Login failed: ${e.toString()}'));
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await MyAppSyncManager.instance.logout();
      // State change will be handled by USM state change listener
    } catch (e) {
      _updateState(_state.copyWithError('Logout failed: ${e.toString()}'));
    }
  }

  /// Update state from USM changes
  void _updateFromUSM(AuthState authState) {
    if (authState == AuthState.authenticated) {
      final authContext = MyAppSyncManager.instance.currentUser;
      if (authContext != null) {
        _updateState(
            RiverpodAuthSyncState.authenticated(authContext: authContext));
      }
    } else {
      _updateState(RiverpodAuthSyncState.public());
    }
  }

  /// Update state internally
  void _updateState(RiverpodAuthSyncState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  /// Dispose resources
  void dispose() {
    _authStateSubscription?.cancel();
    _stateController.close();
  }
}

/// Example usage patterns for Riverpod integration
///
/// ```dart
/// // StateNotifier pattern (Riverpod 1.x)
/// final authSyncProvider = StateNotifierProvider<AuthSyncNotifier, RiverpodAuthSyncState>((ref) {
///   final notifier = AuthSyncNotifier();
///   notifier.initialize();
///   ref.onDispose(() => notifier.dispose());
///   return notifier;
/// });
///
/// // In your widget:
/// class MyWidget extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final authState = ref.watch(authSyncProvider);
///     
///     if (authState.isLoading) {
///       return CircularProgressIndicator();
///     }
///     
///     if (authState.isAuthenticated) {
///       return Text('Welcome ${authState.userId}!');
///     }
///     
///     return ElevatedButton(
///       onPressed: () {
///         ref.read(authSyncProvider.notifier).login({
///           'token': 'your-token',
///           'userId': 'user-id',
///         });
///       },
///       child: Text('Login'),
///     );
///   }
/// }
/// ```
