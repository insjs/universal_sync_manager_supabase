/// Token management system for Universal Sync Manager
///
/// This system provides automatic token refresh, secure storage, validation,
/// and fallback mechanisms for authentication failures, following the Enhanced
/// Authentication Integration Pattern Phase 1.3 requirements.

import 'dart:async';
import 'dart:math';
import '../models/usm_auth_context.dart';
import '../models/usm_sync_backend_configuration.dart';

/// Result of a token refresh operation
class TokenRefreshResult {
  final bool success;
  final String? newToken;
  final DateTime? expiresAt;
  final String? error;
  final Duration? nextRetryDelay;

  const TokenRefreshResult({
    required this.success,
    this.newToken,
    this.expiresAt,
    this.error,
    this.nextRetryDelay,
  });

  factory TokenRefreshResult.success({
    required String token,
    DateTime? expiresAt,
  }) {
    return TokenRefreshResult(
      success: true,
      newToken: token,
      expiresAt: expiresAt,
    );
  }

  factory TokenRefreshResult.failure({
    required String error,
    Duration? retryDelay,
  }) {
    return TokenRefreshResult(
      success: false,
      error: error,
      nextRetryDelay: retryDelay,
    );
  }
}

/// Token validation result
class TokenValidationResult {
  final bool isValid;
  final bool isExpired;
  final Duration? timeUntilExpiry;
  final String? validationError;

  const TokenValidationResult({
    required this.isValid,
    required this.isExpired,
    this.timeUntilExpiry,
    this.validationError,
  });

  factory TokenValidationResult.valid({Duration? timeUntilExpiry}) {
    return TokenValidationResult(
      isValid: true,
      isExpired: false,
      timeUntilExpiry: timeUntilExpiry,
    );
  }

  factory TokenValidationResult.expired() {
    return const TokenValidationResult(
      isValid: false,
      isExpired: true,
      timeUntilExpiry: Duration.zero,
    );
  }

  factory TokenValidationResult.invalid(String error) {
    return TokenValidationResult(
      isValid: false,
      isExpired: false,
      validationError: error,
    );
  }
}

/// Configuration for token management behavior
class TokenManagementConfig {
  /// How long before expiry to trigger automatic refresh
  final Duration refreshThreshold;

  /// Maximum number of refresh attempts
  final int maxRefreshAttempts;

  /// Base delay between refresh attempts
  final Duration baseRetryDelay;

  /// Maximum delay between refresh attempts
  final Duration maxRetryDelay;

  /// Whether to use exponential backoff for retries
  final bool useExponentialBackoff;

  /// Whether to enable automatic token refresh
  final bool enableAutoRefresh;

  /// Grace period for expired tokens (allow operations briefly after expiry)
  final Duration expiredTokenGracePeriod;

  const TokenManagementConfig({
    this.refreshThreshold = const Duration(minutes: 5),
    this.maxRefreshAttempts = 3,
    this.baseRetryDelay = const Duration(seconds: 2),
    this.maxRetryDelay = const Duration(minutes: 1),
    this.useExponentialBackoff = true,
    this.enableAutoRefresh = true,
    this.expiredTokenGracePeriod = const Duration(seconds: 30),
  });
}

/// Automatic token refresh infrastructure
class TokenManager {
  final TokenManagementConfig config;
  final AuthStateStorage _authStorage;

  Timer? _refreshTimer;
  int _refreshAttempts = 0;
  bool _isRefreshing = false;

  final StreamController<TokenRefreshResult> _refreshResultController =
      StreamController<TokenRefreshResult>.broadcast();

  TokenManager({
    this.config = const TokenManagementConfig(),
    AuthStateStorage? authStorage,
  }) : _authStorage = authStorage ?? AuthStateStorage() {
    // Listen to auth state changes to manage token refresh
    _authStorage.stateChanges.listen(_onAuthStateChanged);
  }

  /// Stream of token refresh results
  Stream<TokenRefreshResult> get refreshResults =>
      _refreshResultController.stream;

  /// Validates the current token
  TokenValidationResult validateCurrentToken() {
    final context = _authStorage.currentContext;
    if (context == null) {
      return TokenValidationResult.invalid('No authentication context');
    }

    if (context.isExpired) {
      // Check if within grace period
      final expiredDuration = DateTime.now().difference(context.expiresAt!);
      if (expiredDuration <= config.expiredTokenGracePeriod) {
        return TokenValidationResult.valid(
          timeUntilExpiry: config.expiredTokenGracePeriod - expiredDuration,
        );
      }
      return TokenValidationResult.expired();
    }

    return TokenValidationResult.valid(
      timeUntilExpiry: context.timeUntilExpiry,
    );
  }

  /// Manually triggers token refresh
  Future<TokenRefreshResult> refreshToken({
    SyncAuthConfiguration? authConfig,
    bool forceRefresh = false,
  }) async {
    if (_isRefreshing && !forceRefresh) {
      return TokenRefreshResult.failure(
        error: 'Token refresh already in progress',
      );
    }

    _isRefreshing = true;

    try {
      final context = _authStorage.currentContext;
      final config = authConfig ?? _getAuthConfigFromContext(context);

      if (config?.tokenRefreshCallback == null) {
        return TokenRefreshResult.failure(
          error: 'No token refresh callback available',
        );
      }

      final newToken = await config!.tokenRefreshCallback!();

      // Update auth configuration and context with new token
      final updatedAuthConfig = config.copyWithToken(newToken);
      final updatedContext =
          context?.copyWithCredentials(updatedAuthConfig.credentials);

      if (updatedContext != null) {
        _authStorage.setContext(updatedContext);
      }

      _refreshAttempts = 0; // Reset on success

      final result = TokenRefreshResult.success(
        token: newToken,
        expiresAt: updatedContext?.expiresAt,
      );

      _refreshResultController.add(result);
      return result;
    } catch (e) {
      _refreshAttempts++;

      final retryDelay = _calculateRetryDelay();
      final result = TokenRefreshResult.failure(
        error: 'Token refresh failed: $e',
        retryDelay: retryDelay,
      );

      _refreshResultController.add(result);

      // Schedule retry if under max attempts
      if (_refreshAttempts < config.maxRefreshAttempts) {
        _scheduleRefreshRetry(retryDelay);
      }

      return result;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Securely stores a token (in memory for now, could be extended to secure storage)
  void storeToken(String token, {DateTime? expiresAt}) {
    final context = _authStorage.currentContext;
    if (context != null) {
      final updatedCredentials = Map<String, dynamic>.from(context.credentials);
      updatedCredentials['token'] = token;

      final updatedContext = context.copyWithCredentials(updatedCredentials);
      final contextWithExpiry = expiresAt != null
          ? updatedContext.copyWithExpiry(expiresAt)
          : updatedContext;

      _authStorage.setContext(contextWithExpiry);
    }
  }

  /// Retrieves the current token
  String? getCurrentToken() {
    final context = _authStorage.currentContext;
    return context?.credentials['token'] as String?;
  }

  /// Handles auth failures with appropriate fallback
  Future<bool> handleAuthFailure({
    required String error,
    bool attemptRefresh = true,
  }) async {
    // Clear expired context
    if (_authStorage.currentContext?.isExpired == true) {
      _authStorage.clearContext();
    }

    // Attempt token refresh if enabled and callback available
    if (attemptRefresh && config.enableAutoRefresh) {
      final refreshResult = await refreshToken();
      return refreshResult.success;
    }

    return false;
  }

  /// Starts automatic token refresh monitoring
  void startAutoRefresh() {
    if (!config.enableAutoRefresh) return;

    _scheduleNextRefresh();
  }

  /// Stops automatic token refresh monitoring
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Disposes resources
  void dispose() {
    stopAutoRefresh();
    _refreshResultController.close();
  }

  // Private methods

  void _onAuthStateChanged(AuthContext? context) {
    if (context != null && config.enableAutoRefresh) {
      _scheduleNextRefresh();
    } else {
      stopAutoRefresh();
    }
  }

  void _scheduleNextRefresh() {
    _refreshTimer?.cancel();

    final context = _authStorage.currentContext;
    if (context?.timeUntilExpiry == null) return;

    final timeUntilRefresh =
        context!.timeUntilExpiry! - config.refreshThreshold;
    if (timeUntilRefresh.isNegative) {
      // Token needs immediate refresh
      refreshToken();
      return;
    }

    _refreshTimer = Timer(timeUntilRefresh, () {
      refreshToken();
    });
  }

  void _scheduleRefreshRetry(Duration delay) {
    Timer(delay, () {
      if (_refreshAttempts < config.maxRefreshAttempts) {
        refreshToken();
      }
    });
  }

  Duration _calculateRetryDelay() {
    if (!config.useExponentialBackoff) {
      return config.baseRetryDelay;
    }

    final exponentialDelay =
        config.baseRetryDelay * pow(2, _refreshAttempts - 1);
    final delayMs = min(
        exponentialDelay.inMilliseconds, config.maxRetryDelay.inMilliseconds);

    return Duration(milliseconds: delayMs.toInt());
  }

  SyncAuthConfiguration? _getAuthConfigFromContext(AuthContext? context) {
    if (context == null) return null;

    // Try to reconstruct auth config from context
    // This is a simplified approach - in a real implementation, you might
    // store the full auth config reference
    return SyncAuthConfiguration.custom(context.credentials);
  }
}

/// Global token manager instance
TokenManager? _globalTokenManager;

/// Gets the global token manager instance
TokenManager getTokenManager() {
  return _globalTokenManager ??= TokenManager();
}

/// Sets a custom token manager configuration
void configureTokenManager(TokenManagementConfig config) {
  _globalTokenManager?.dispose();
  _globalTokenManager = TokenManager(config: config);
}

/// Disposes the global token manager
void disposeTokenManager() {
  _globalTokenManager?.dispose();
  _globalTokenManager = null;
}
