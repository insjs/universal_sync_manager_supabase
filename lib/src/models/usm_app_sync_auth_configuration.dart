import '../models/usm_auth_context.dart';
import '../services/usm_token_manager.dart';

/// Simplified authentication configuration wrapper for app integration
///
/// This class provides a convenient way to configure authentication
/// for the Universal Sync Manager from an app context.
class AppSyncAuthConfiguration {
  /// User ID for authenticated operations
  final String? userId;

  /// Authentication token
  final String? token;

  /// Organization ID for multi-tenant applications
  final String? organizationId;

  /// Additional metadata for authentication
  final Map<String, dynamic> metadata;

  /// Optional token manager for token refresh
  final TokenManager? tokenManager;

  /// Creates a new authentication configuration
  const AppSyncAuthConfiguration({
    this.userId,
    this.token,
    this.organizationId,
    this.metadata = const {},
    this.tokenManager,
  });

  /// Create auth configuration from app context
  ///
  /// This factory constructor creates an authentication configuration
  /// from an existing AuthContext object, making it easier to integrate
  /// with app authentication systems.
  factory AppSyncAuthConfiguration.fromApp({
    required AuthContext authContext,
    TokenManager? tokenManager,
  }) {
    return AppSyncAuthConfiguration(
      userId: authContext.userId,
      token: authContext.credentials['token'] as String?,
      organizationId: authContext.organizationId,
      metadata: authContext.metadata,
      tokenManager: tokenManager,
    );
  }
}
