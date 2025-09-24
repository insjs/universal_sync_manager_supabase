/// Firebase Authentication integration helpers for Universal Sync Manager
///
/// This provides pre-built integration with Firebase Authentication, making it
/// trivial to connect Firebase Auth state changes with USM sync operations.

import 'dart:async';
import '../my_app_sync_manager.dart';

/// Firebase Authentication integration helper
///
/// This class provides seamless integration between Firebase Auth and USM.
/// It automatically handles auth state changes and token management.
///
/// Usage:
/// ```dart
/// // Initialize USM first
/// await MyAppSyncManager.initialize(
///   backendAdapter: MyFirebaseAdapter(),
/// );
///
/// // Connect Firebase Auth
/// await FirebaseAuthIntegration.connect(
///   firebaseAuth: FirebaseAuth.instance,
///   onUserChanged: (user) async {
///     if (user != null) {
///       final token = await user.getIdToken();
///       await MyAppSyncManager.instance.login(
///         token: token,
///         userId: user.uid,
///         metadata: {
///           'email': user.email,
///           'displayName': user.displayName,
///         },
///       );
///     } else {
///       await MyAppSyncManager.instance.logout();
///     }
///   },
/// );
/// ```
class FirebaseAuthIntegration {
  static StreamSubscription? _authSubscription;
  static bool _isConnected = false;

  /// Connect Firebase Auth to Universal Sync Manager
  ///
  /// [firebaseAuth] - Firebase Auth instance (usually FirebaseAuth.instance)
  /// [onUserChanged] - Callback for custom user processing (optional)
  /// [customClaims] - Whether to fetch custom claims for user metadata
  /// [tokenRefreshInterval] - How often to refresh the ID token
  static Future<void> connect({
    required dynamic firebaseAuth, // Using dynamic to avoid Firebase dependency
    Future<void> Function(dynamic user)? onUserChanged,
    bool customClaims = false,
    Duration tokenRefreshInterval = const Duration(hours: 1),
  }) async {
    if (_isConnected) {
      throw StateError('FirebaseAuthIntegration already connected');
    }

    _authSubscription =
        firebaseAuth.authStateChanges().listen((dynamic user) async {
      try {
        if (onUserChanged != null) {
          // Use custom callback if provided
          await onUserChanged(user);
        } else {
          // Default behavior
          await _handleUserChange(user, customClaims);
        }
      } catch (e) {
        print('Error handling Firebase auth change: $e');
      }
    });

    _isConnected = true;
  }

  /// Disconnect from Firebase Auth
  static Future<void> disconnect() async {
    await _authSubscription?.cancel();
    _authSubscription = null;
    _isConnected = false;
  }

  /// Check if currently connected
  static bool get isConnected => _isConnected;

  /// Default handler for Firebase auth state changes
  static Future<void> _handleUserChange(
      dynamic user, bool includeCustomClaims) async {
    if (user != null) {
      // User logged in
      try {
        final token = await user.getIdToken();
        final metadata = <String, dynamic>{
          'email': user.email,
          'displayName': user.displayName,
          'emailVerified': user.emailVerified,
          'phoneNumber': user.phoneNumber,
          'photoURL': user.photoURL,
        };

        // Add custom claims if requested
        if (includeCustomClaims) {
          final idTokenResult = await user.getIdTokenResult();
          metadata['customClaims'] = idTokenResult.claims;
        }

        // Login to USM
        final result = await MyAppSyncManager.instance.login(
          token: token,
          userId: user.uid,
          metadata: metadata,
        );

        if (!result.isSuccess) {
          print('Failed to login to USM: ${result.errorMessage}');
        }
      } catch (e) {
        print('Error processing Firebase user login: $e');
      }
    } else {
      // User logged out
      try {
        await MyAppSyncManager.instance.logout();
      } catch (e) {
        print('Error processing Firebase user logout: $e');
      }
    }
  }

  /// Manual token refresh for Firebase users
  static Future<void> refreshToken() async {
    try {
      // This would typically get the current Firebase user and refresh their token
      // Implementation would depend on having access to Firebase Auth instance
      print(
          'Manual token refresh requested - implement based on your Firebase setup');
    } catch (e) {
      print('Error refreshing Firebase token: $e');
    }
  }

  /// Get Firebase user metadata for USM
  static Map<String, dynamic> getUserMetadata(dynamic user) {
    if (user == null) return {};

    return {
      'email': user.email,
      'displayName': user.displayName,
      'emailVerified': user.emailVerified,
      'phoneNumber': user.phoneNumber,
      'photoURL': user.photoURL,
      'creationTime': user.metadata?.creationTime?.toIso8601String(),
      'lastSignInTime': user.metadata?.lastSignInTime?.toIso8601String(),
    };
  }
}

/// Firebase Auth integration configuration
class FirebaseAuthIntegrationConfig {
  /// Whether to include custom claims in user metadata
  final bool includeCustomClaims;

  /// How often to refresh the ID token
  final Duration tokenRefreshInterval;

  /// Custom metadata extractor function
  final Map<String, dynamic> Function(dynamic user)? customMetadataExtractor;

  /// Whether to automatically handle auth state changes
  final bool autoHandleAuthChanges;

  const FirebaseAuthIntegrationConfig({
    this.includeCustomClaims = false,
    this.tokenRefreshInterval = const Duration(hours: 1),
    this.customMetadataExtractor,
    this.autoHandleAuthChanges = true,
  });
}

/// Advanced Firebase Auth integration with custom configuration
class AdvancedFirebaseAuthIntegration {
  final FirebaseAuthIntegrationConfig config;
  final dynamic firebaseAuth;

  StreamSubscription? _authSubscription;
  Timer? _tokenRefreshTimer;
  bool _isConnected = false;

  AdvancedFirebaseAuthIntegration({
    required this.firebaseAuth,
    required this.config,
  });

  /// Connect with advanced configuration
  Future<void> connect() async {
    if (_isConnected) {
      throw StateError('AdvancedFirebaseAuthIntegration already connected');
    }

    if (config.autoHandleAuthChanges) {
      _authSubscription =
          firebaseAuth.authStateChanges().listen(_handleUserChange);
    }

    _isConnected = true;
  }

  /// Disconnect
  Future<void> disconnect() async {
    await _authSubscription?.cancel();
    _tokenRefreshTimer?.cancel();
    _authSubscription = null;
    _tokenRefreshTimer = null;
    _isConnected = false;
  }

  /// Handle user auth state change
  Future<void> _handleUserChange(dynamic user) async {
    if (user != null) {
      await _loginUser(user);
      _startTokenRefreshTimer(user);
    } else {
      await _logoutUser();
      _stopTokenRefreshTimer();
    }
  }

  /// Login user to USM
  Future<void> _loginUser(dynamic user) async {
    try {
      final token = await user.getIdToken();
      Map<String, dynamic> metadata = {};

      // Use custom metadata extractor if provided
      if (config.customMetadataExtractor != null) {
        metadata = config.customMetadataExtractor!(user);
      } else {
        metadata = FirebaseAuthIntegration.getUserMetadata(user);
      }

      // Add custom claims if requested
      if (config.includeCustomClaims) {
        final idTokenResult = await user.getIdTokenResult();
        metadata['customClaims'] = idTokenResult.claims;
      }

      final result = await MyAppSyncManager.instance.login(
        token: token,
        userId: user.uid,
        metadata: metadata,
      );

      if (!result.isSuccess) {
        print('Failed to login to USM: ${result.errorMessage}');
      }
    } catch (e) {
      print('Error logging in Firebase user: $e');
    }
  }

  /// Logout user from USM
  Future<void> _logoutUser() async {
    try {
      await MyAppSyncManager.instance.logout();
    } catch (e) {
      print('Error logging out Firebase user: $e');
    }
  }

  /// Start automatic token refresh
  void _startTokenRefreshTimer(dynamic user) {
    _stopTokenRefreshTimer();
    _tokenRefreshTimer = Timer.periodic(config.tokenRefreshInterval, (_) async {
      try {
        final newToken = await user.getIdToken(true); // Force refresh
        await MyAppSyncManager.instance.refreshAuthentication(
          newToken: newToken,
        );
      } catch (e) {
        print('Error refreshing Firebase token: $e');
      }
    });
  }

  /// Stop automatic token refresh
  void _stopTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
  }

  /// Check if connected
  bool get isConnected => _isConnected;
}
