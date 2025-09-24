/// Supabase Authentication integration utilities for Universal Sync Manager
///
/// This provides seamless integration with Supabase Auth, automatically handling
/// auth state changes, RLS context, and JWT token management.

import 'dart:async';
import '../my_app_sync_manager.dart';

/// Supabase Authentication integration helper
///
/// This class provides seamless integration between Supabase Auth and USM.
/// It automatically handles auth state changes, RLS context, and token management.
///
/// Usage:
/// ```dart
/// // Initialize USM first
/// await MyAppSyncManager.initialize(
///   backendAdapter: MySupabaseAdapter(),
/// );
///
/// // Connect Supabase Auth
/// await SupabaseAuthIntegration.connect(
///   supabaseClient: Supabase.instance.client,
/// );
/// ```
class SupabaseAuthIntegration {
  static StreamSubscription? _authSubscription;
  static bool _isConnected = false;
  static dynamic _supabaseClient;

  /// Connect Supabase Auth to Universal Sync Manager
  ///
  /// [supabaseClient] - Supabase client instance (usually Supabase.instance.client)
  /// [onUserChanged] - Callback for custom user processing (optional)
  /// [includeUserMetadata] - Whether to include user metadata from Supabase
  static Future<void> connect({
    required dynamic
        supabaseClient, // Using dynamic to avoid Supabase dependency
    Future<void> Function(dynamic user)? onUserChanged,
    bool includeUserMetadata = true,
  }) async {
    if (_isConnected) {
      throw StateError('SupabaseAuthIntegration already connected');
    }

    _supabaseClient = supabaseClient;

    _authSubscription =
        supabaseClient.auth.onAuthStateChange.listen((dynamic data) async {
      try {
        final session = data.session;
        final user = session?.user;

        if (onUserChanged != null) {
          // Use custom callback if provided
          await onUserChanged(user);
        } else {
          // Default behavior
          await _handleUserChange(user, session, includeUserMetadata);
        }
      } catch (e) {
        print('Error handling Supabase auth change: $e');
      }
    });

    _isConnected = true;
  }

  /// Disconnect from Supabase Auth
  static Future<void> disconnect() async {
    await _authSubscription?.cancel();
    _authSubscription = null;
    _supabaseClient = null;
    _isConnected = false;
  }

  /// Check if currently connected
  static bool get isConnected => _isConnected;

  /// Default handler for Supabase auth state changes
  static Future<void> _handleUserChange(
      dynamic user, dynamic session, bool includeUserMetadata) async {
    if (user != null && session != null) {
      // User logged in
      try {
        final metadata = <String, dynamic>{
          'email': user.email,
          'phone': user.phone,
          'emailConfirmedAt': user.emailConfirmedAt?.toIso8601String(),
          'phoneConfirmedAt': user.phoneConfirmedAt?.toIso8601String(),
          'lastSignInAt': user.lastSignInAt?.toIso8601String(),
          'createdAt': user.createdAt?.toIso8601String(),
        };

        // Add user metadata if requested and available
        if (includeUserMetadata && user.userMetadata != null) {
          metadata['userMetadata'] = user.userMetadata;
        }

        // Add app metadata if available
        if (user.appMetadata != null) {
          metadata['appMetadata'] = user.appMetadata;
        }

        // Login to USM
        final result = await MyAppSyncManager.instance.login(
          token: session.accessToken,
          userId: user.id,
          metadata: metadata,
          refreshToken: session.refreshToken,
          tokenExpiry: session.expiresAt != null
              ? DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)
              : null,
        );

        if (!result.isSuccess) {
          print('Failed to login to USM: ${result.errorMessage}');
        }
      } catch (e) {
        print('Error processing Supabase user login: $e');
      }
    } else {
      // User logged out
      try {
        await MyAppSyncManager.instance.logout();
      } catch (e) {
        print('Error processing Supabase user logout: $e');
      }
    }
  }

  /// Manual token refresh for Supabase users
  static Future<void> refreshToken() async {
    try {
      if (_supabaseClient?.auth.currentSession != null) {
        final response = await _supabaseClient.auth.refreshSession();
        final session = response.session;

        if (session != null) {
          await MyAppSyncManager.instance.refreshAuthentication(
            newToken: session.accessToken,
            newTokenExpiry: session.expiresAt != null
                ? DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)
                : null,
          );
        }
      }
    } catch (e) {
      print('Error refreshing Supabase token: $e');
    }
  }

  /// Get Supabase user metadata for USM
  static Map<String, dynamic> getUserMetadata(dynamic user) {
    if (user == null) return {};

    return {
      'email': user.email,
      'phone': user.phone,
      'emailConfirmedAt': user.emailConfirmedAt?.toIso8601String(),
      'phoneConfirmedAt': user.phoneConfirmedAt?.toIso8601String(),
      'lastSignInAt': user.lastSignInAt?.toIso8601String(),
      'createdAt': user.createdAt?.toIso8601String(),
      'userMetadata': user.userMetadata,
      'appMetadata': user.appMetadata,
    };
  }

  /// Set RLS context for current user (useful for Row Level Security)
  static Future<void> setRLSContext({
    String? organizationId,
    List<String>? roles,
    Map<String, dynamic>? customContext,
  }) async {
    try {
      if (_supabaseClient?.auth.currentUser != null) {
        final context = <String, dynamic>{
          'user_id': _supabaseClient.auth.currentUser.id,
          if (organizationId != null) 'organization_id': organizationId,
          if (roles != null) 'user_roles': roles,
          if (customContext != null) ...customContext,
        };

        // Call RPC to set session variables for RLS
        await _supabaseClient.rpc('set_session_variables', context);
      }
    } catch (e) {
      print('Error setting RLS context: $e');
    }
  }
}

/// Supabase Auth integration configuration
class SupabaseAuthIntegrationConfig {
  /// Whether to include user metadata in USM auth context
  final bool includeUserMetadata;

  /// Whether to automatically set RLS context
  final bool autoSetRLSContext;

  /// Organization ID for RLS context
  final String? organizationId;

  /// User roles for RLS context
  final List<String>? userRoles;

  /// Custom metadata extractor function
  final Map<String, dynamic> Function(dynamic user)? customMetadataExtractor;

  /// Custom RLS context provider
  final Map<String, dynamic> Function(dynamic user)? customRLSContextProvider;

  const SupabaseAuthIntegrationConfig({
    this.includeUserMetadata = true,
    this.autoSetRLSContext = false,
    this.organizationId,
    this.userRoles,
    this.customMetadataExtractor,
    this.customRLSContextProvider,
  });
}

/// Advanced Supabase Auth integration with custom configuration
class AdvancedSupabaseAuthIntegration {
  final SupabaseAuthIntegrationConfig config;
  final dynamic supabaseClient;

  StreamSubscription? _authSubscription;
  bool _isConnected = false;

  AdvancedSupabaseAuthIntegration({
    required this.supabaseClient,
    required this.config,
  });

  /// Connect with advanced configuration
  Future<void> connect() async {
    if (_isConnected) {
      throw StateError('AdvancedSupabaseAuthIntegration already connected');
    }

    _authSubscription =
        supabaseClient.auth.onAuthStateChange.listen(_handleAuthChange);
    _isConnected = true;
  }

  /// Disconnect
  Future<void> disconnect() async {
    await _authSubscription?.cancel();
    _authSubscription = null;
    _isConnected = false;
  }

  /// Handle auth state change
  Future<void> _handleAuthChange(dynamic data) async {
    final session = data.session;
    final user = session?.user;

    if (user != null && session != null) {
      await _loginUser(user, session);
    } else {
      await _logoutUser();
    }
  }

  /// Login user to USM
  Future<void> _loginUser(dynamic user, dynamic session) async {
    try {
      Map<String, dynamic> metadata = {};

      // Use custom metadata extractor if provided
      if (config.customMetadataExtractor != null) {
        metadata = config.customMetadataExtractor!(user);
      } else {
        metadata = SupabaseAuthIntegration.getUserMetadata(user);
      }

      // Login to USM
      final result = await MyAppSyncManager.instance.login(
        token: session.accessToken,
        userId: user.id,
        metadata: metadata,
        refreshToken: session.refreshToken,
        tokenExpiry: session.expiresAt != null
            ? DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)
            : null,
      );

      if (!result.isSuccess) {
        print('Failed to login to USM: ${result.errorMessage}');
        return;
      }

      // Set RLS context if configured
      if (config.autoSetRLSContext) {
        await _setRLSContext(user);
      }
    } catch (e) {
      print('Error logging in Supabase user: $e');
    }
  }

  /// Logout user from USM
  Future<void> _logoutUser() async {
    try {
      await MyAppSyncManager.instance.logout();
    } catch (e) {
      print('Error logging out Supabase user: $e');
    }
  }

  /// Set RLS context for the user
  Future<void> _setRLSContext(dynamic user) async {
    try {
      Map<String, dynamic> rlsContext = {
        'user_id': user.id,
      };

      // Add organization ID if configured
      if (config.organizationId != null) {
        rlsContext['organization_id'] = config.organizationId!;
      }

      // Add user roles if configured
      if (config.userRoles != null) {
        rlsContext['user_roles'] = config.userRoles!;
      }

      // Use custom RLS context provider if available
      if (config.customRLSContextProvider != null) {
        final customContext = config.customRLSContextProvider!(user);
        rlsContext.addAll(customContext);
      }

      // Set RLS context
      await supabaseClient.rpc('set_session_variables', rlsContext);
    } catch (e) {
      print('Error setting RLS context: $e');
    }
  }

  /// Check if connected
  bool get isConnected => _isConnected;
}
