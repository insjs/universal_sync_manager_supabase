/// Auth0 integration patterns for Universal Sync Manager
///
/// This provides integration helpers for Auth0 authentication, making it easy
/// to connect Auth0 authentication flow with USM sync operations.

import 'dart:async';
import '../my_app_sync_manager.dart';

/// Auth0 integration helper
///
/// This class provides integration patterns for Auth0 authentication with USM.
/// Since Auth0 doesn't have a persistent auth state listener like Firebase/Supabase,
/// this provides manual integration methods.
///
/// Usage:
/// ```dart
/// // Initialize USM first
/// await MyAppSyncManager.initialize(
///   backendAdapter: MyBackendAdapter(),
/// );
///
/// // After Auth0 login
/// final credentials = await auth0.webAuthentication().login();
/// await Auth0Integration.loginWithCredentials(
///   credentials: credentials,
///   organizationId: 'my-org',
/// );
///
/// // On logout
/// await Auth0Integration.logout();
/// ```
class Auth0Integration {
  static bool _isConnected = false;
  static String? _currentAccessToken;
  static Timer? _tokenRefreshTimer;

  /// Login to USM using Auth0 credentials
  ///
  /// [credentials] - Auth0 credentials object
  /// [organizationId] - Optional organization/tenant ID
  /// [customMetadataExtractor] - Custom function to extract metadata from credentials
  static Future<AuthResult> loginWithCredentials({
    required dynamic credentials, // Using dynamic to avoid Auth0 dependency
    String? organizationId,
    Map<String, dynamic> Function(dynamic)? customMetadataExtractor,
  }) async {
    try {
      // Extract basic information from Auth0 credentials
      final accessToken = credentials.accessToken;
      final idToken = credentials.idToken;
      final user = credentials.user;

      if (accessToken == null || user == null) {
        return AuthResult.failure('Invalid Auth0 credentials');
      }

      // Extract user metadata
      Map<String, dynamic> metadata = {};
      if (customMetadataExtractor != null) {
        metadata = customMetadataExtractor(credentials);
      } else {
        metadata = _extractDefaultMetadata(user, idToken);
      }

      // Store current token for refresh
      _currentAccessToken = accessToken;

      // Login to USM
      final result = await MyAppSyncManager.instance.login(
        token: accessToken,
        userId: user.sub ?? user.id,
        organizationId: organizationId,
        metadata: metadata,
      );

      if (result.isSuccess) {
        _isConnected = true;
        _startTokenRefreshTimer(credentials);
      }

      return result;
    } catch (e) {
      return AuthResult.failure('Auth0 login failed: ${e.toString()}');
    }
  }

  /// Login to USM using Auth0 tokens directly
  ///
  /// [accessToken] - Auth0 access token
  /// [userId] - User identifier from Auth0
  /// [organizationId] - Optional organization/tenant ID
  /// [metadata] - Additional user metadata
  /// [refreshToken] - Optional refresh token for auto-refresh
  /// [tokenExpiry] - When the access token expires
  static Future<AuthResult> loginWithTokens({
    required String accessToken,
    required String userId,
    String? organizationId,
    Map<String, dynamic> metadata = const {},
    String? refreshToken,
    DateTime? tokenExpiry,
  }) async {
    try {
      _currentAccessToken = accessToken;

      final result = await MyAppSyncManager.instance.login(
        token: accessToken,
        userId: userId,
        organizationId: organizationId,
        metadata: metadata,
        refreshToken: refreshToken,
        tokenExpiry: tokenExpiry,
      );

      if (result.isSuccess) {
        _isConnected = true;
      }

      return result;
    } catch (e) {
      return AuthResult.failure('Auth0 token login failed: ${e.toString()}');
    }
  }

  /// Logout from USM and clear Auth0 session
  static Future<void> logout() async {
    try {
      await MyAppSyncManager.instance.logout();
      _stopTokenRefreshTimer();
      _currentAccessToken = null;
      _isConnected = false;
    } catch (e) {
      print('Error during Auth0 logout: $e');
    }
  }

  /// Refresh Auth0 token manually
  ///
  /// [newAccessToken] - New access token from Auth0
  /// [newTokenExpiry] - When the new token expires
  static Future<AuthResult> refreshToken({
    required String newAccessToken,
    DateTime? newTokenExpiry,
  }) async {
    try {
      _currentAccessToken = newAccessToken;

      return await MyAppSyncManager.instance.refreshAuthentication(
        newToken: newAccessToken,
        newTokenExpiry: newTokenExpiry,
      );
    } catch (e) {
      return AuthResult.failure('Auth0 token refresh failed: ${e.toString()}');
    }
  }

  /// Check if currently connected
  static bool get isConnected => _isConnected;

  /// Get current access token
  static String? get currentAccessToken => _currentAccessToken;

  /// Extract default metadata from Auth0 user and ID token
  static Map<String, dynamic> _extractDefaultMetadata(
      dynamic user, dynamic idToken) {
    final metadata = <String, dynamic>{
      'email': user.email,
      'name': user.name,
      'nickname': user.nickname,
      'picture': user.picture,
      'emailVerified': user.emailVerified,
      'updatedAt': user.updatedAt,
    };

    // Add custom claims from ID token if available
    if (idToken != null) {
      try {
        // Parse JWT claims (simplified - in real implementation you'd decode the JWT)
        metadata['idTokenClaims'] = 'ID token available';
      } catch (e) {
        // Ignore JWT parsing errors
      }
    }

    return metadata;
  }

  /// Start automatic token refresh timer (placeholder)
  static void _startTokenRefreshTimer(dynamic credentials) {
    // In a real implementation, this would set up periodic token refresh
    // based on the token expiry time
    _stopTokenRefreshTimer();

    // Example: refresh every 45 minutes for a 60-minute token
    _tokenRefreshTimer = Timer.periodic(const Duration(minutes: 45), (_) async {
      print('Auth0 token refresh needed - implement based on your Auth0 setup');
      // You would call your Auth0 refresh method here
    });
  }

  /// Stop automatic token refresh timer
  static void _stopTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
  }
}

/// Auth0 integration configuration
class Auth0IntegrationConfig {
  /// Auth0 domain
  final String domain;

  /// Auth0 client ID
  final String clientId;

  /// Auth0 audience (API identifier)
  final String? audience;

  /// Auth0 scope
  final String scope;

  /// Organization ID for multi-tenant apps
  final String? organizationId;

  /// Custom metadata extractor function
  final Map<String, dynamic> Function(dynamic credentials)?
      customMetadataExtractor;

  /// Whether to use refresh tokens
  final bool useRefreshTokens;

  /// Token refresh interval
  final Duration tokenRefreshInterval;

  const Auth0IntegrationConfig({
    required this.domain,
    required this.clientId,
    this.audience,
    this.scope = 'openid profile email',
    this.organizationId,
    this.customMetadataExtractor,
    this.useRefreshTokens = true,
    this.tokenRefreshInterval = const Duration(minutes: 45),
  });
}

/// Advanced Auth0 integration with configuration
class AdvancedAuth0Integration {
  final Auth0IntegrationConfig config;

  Timer? _tokenRefreshTimer;
  bool _isConnected = false;
  String? _currentAccessToken;
  String? _currentRefreshToken;
  DateTime? _tokenExpiry;

  AdvancedAuth0Integration({
    required this.config,
  });

  /// Login with Auth0 credentials using the configuration
  Future<AuthResult> loginWithCredentials(dynamic credentials) async {
    try {
      final accessToken = credentials.accessToken;
      final refreshToken = credentials.refreshToken;
      final user = credentials.user;
      final expiresIn = credentials.expiresIn;

      if (accessToken == null || user == null) {
        return AuthResult.failure('Invalid Auth0 credentials');
      }

      // Calculate token expiry
      DateTime? tokenExpiry;
      if (expiresIn != null) {
        tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
      }

      // Extract metadata
      Map<String, dynamic> metadata = {};
      if (config.customMetadataExtractor != null) {
        metadata = config.customMetadataExtractor!(credentials);
      } else {
        metadata =
            Auth0Integration._extractDefaultMetadata(user, credentials.idToken);
      }

      // Add organization ID if configured
      final organizationId = config.organizationId;

      // Store token information
      _currentAccessToken = accessToken;
      _currentRefreshToken = refreshToken;
      _tokenExpiry = tokenExpiry;

      // Login to USM
      final result = await MyAppSyncManager.instance.login(
        token: accessToken,
        userId: user.sub ?? user.id,
        organizationId: organizationId,
        metadata: metadata,
        refreshToken: refreshToken,
        tokenExpiry: tokenExpiry,
      );

      if (result.isSuccess) {
        _isConnected = true;
        if (config.useRefreshTokens && refreshToken != null) {
          _startTokenRefreshTimer();
        }
      }

      return result;
    } catch (e) {
      return AuthResult.failure('Auth0 login failed: ${e.toString()}');
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await MyAppSyncManager.instance.logout();
      _stopTokenRefreshTimer();
      _currentAccessToken = null;
      _currentRefreshToken = null;
      _tokenExpiry = null;
      _isConnected = false;
    } catch (e) {
      print('Error during Auth0 logout: $e');
    }
  }

  /// Start automatic token refresh
  void _startTokenRefreshTimer() {
    _stopTokenRefreshTimer();
    _tokenRefreshTimer = Timer.periodic(config.tokenRefreshInterval, (_) async {
      await _performTokenRefresh();
    });
  }

  /// Stop automatic token refresh
  void _stopTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
  }

  /// Perform token refresh (placeholder)
  Future<void> _performTokenRefresh() async {
    try {
      // In a real implementation, you would use Auth0's refresh token method
      print('Performing Auth0 token refresh...');

      // Example of what this would look like:
      // final newCredentials = await auth0.credentialsManager.credentials();
      // if (newCredentials != null) {
      //   await Auth0Integration.refreshToken(
      //     newAccessToken: newCredentials.accessToken,
      //     newTokenExpiry: DateTime.now().add(Duration(seconds: newCredentials.expiresIn)),
      //   );
      // }
    } catch (e) {
      print('Error refreshing Auth0 token: $e');
    }
  }

  /// Check if connected
  bool get isConnected => _isConnected;

  /// Get current access token
  String? get currentAccessToken => _currentAccessToken;

  /// Get token expiry
  DateTime? get tokenExpiry => _tokenExpiry;
}
