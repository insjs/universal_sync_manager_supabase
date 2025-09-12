/// Authentication context management for Universal Sync Manager
///
/// This class provides thread-safe authentication state management and context
/// inheritance for sync operations, following the Enhanced Authentication
/// Integration Pattern Phase 1.2 requirements.

import 'dart:async';

/// Authentication context for managing user session data during sync operations
class AuthContext {
  /// Unique identifier for this auth context
  final String contextId;

  /// User identifier
  final String? userId;

  /// Organization or tenant identifier
  final String? organizationId;

  /// Additional user context data
  final Map<String, dynamic> userContext;

  /// Role-based metadata and feature flags
  final Map<String, dynamic> metadata;

  /// Authentication token or credentials
  final Map<String, dynamic> credentials;

  /// Context creation timestamp
  final DateTime createdAt;

  /// Context expiry time (if applicable)
  final DateTime? expiresAt;

  /// Whether this context is currently valid
  bool get isValid {
    if (expiresAt == null) return true;
    return DateTime.now().isBefore(expiresAt!);
  }

  /// Whether this context has expired
  bool get isExpired => !isValid;

  /// Time remaining until expiry (null if no expiry)
  Duration? get timeUntilExpiry {
    if (expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  const AuthContext({
    required this.contextId,
    this.userId,
    this.organizationId,
    this.userContext = const {},
    this.metadata = const {},
    this.credentials = const {},
    required this.createdAt,
    this.expiresAt,
  });

  /// Creates an authenticated context from user session data
  factory AuthContext.authenticated({
    required String userId,
    String? organizationId,
    Map<String, dynamic> userContext = const {},
    Map<String, dynamic> metadata = const {},
    Map<String, dynamic> credentials = const {},
    Duration? validity,
  }) {
    final contextId = 'auth_${userId}_${DateTime.now().millisecondsSinceEpoch}';
    final createdAt = DateTime.now();
    final expiresAt = validity != null ? createdAt.add(validity) : null;

    return AuthContext(
      contextId: contextId,
      userId: userId,
      organizationId: organizationId,
      userContext: userContext,
      metadata: metadata,
      credentials: credentials,
      createdAt: createdAt,
      expiresAt: expiresAt,
    );
  }

  /// Creates an anonymous/public context
  factory AuthContext.anonymous() {
    final contextId = 'anon_${DateTime.now().millisecondsSinceEpoch}';

    return AuthContext(
      contextId: contextId,
      createdAt: DateTime.now(),
    );
  }

  /// Creates a child context inheriting from this context
  AuthContext createChild({
    String? childUserId,
    Map<String, dynamic> additionalContext = const {},
    Map<String, dynamic> additionalMetadata = const {},
  }) {
    final childContextId =
        '${contextId}_child_${DateTime.now().millisecondsSinceEpoch}';

    return AuthContext(
      contextId: childContextId,
      userId: childUserId ?? userId,
      organizationId: organizationId,
      userContext: {...userContext, ...additionalContext},
      metadata: {...metadata, ...additionalMetadata},
      credentials: credentials,
      createdAt: DateTime.now(),
      expiresAt: expiresAt,
    );
  }

  /// Gets a custom field from user context
  T? getContextField<T>(String key) {
    final value = userContext[key];
    return value is T ? value : null;
  }

  /// Gets a metadata value
  T? getMetadata<T>(String key) {
    final value = metadata[key];
    return value is T ? value : null;
  }

  /// Checks if user has a specific role
  bool hasRole(String role) {
    final roles = metadata['roles'];
    if (roles is List) {
      return roles.contains(role);
    }
    return false;
  }

  /// Checks if user has a specific feature enabled
  bool hasFeature(String feature) {
    final features = metadata['features'] as Map<String, dynamic>?;
    return features?[feature] == true;
  }

  /// Gets all user roles
  List<String> get roles {
    final rolesData = metadata['roles'];
    if (rolesData is List) {
      return rolesData.cast<String>();
    }
    return [];
  }

  /// Creates a copy with updated expiry
  AuthContext copyWithExpiry(DateTime newExpiresAt) {
    return AuthContext(
      contextId: contextId,
      userId: userId,
      organizationId: organizationId,
      userContext: userContext,
      metadata: metadata,
      credentials: credentials,
      createdAt: createdAt,
      expiresAt: newExpiresAt,
    );
  }

  /// Creates a copy with updated credentials
  AuthContext copyWithCredentials(Map<String, dynamic> newCredentials) {
    return AuthContext(
      contextId: contextId,
      userId: userId,
      organizationId: organizationId,
      userContext: userContext,
      metadata: metadata,
      credentials: newCredentials,
      createdAt: createdAt,
      expiresAt: expiresAt,
    );
  }

  /// Converts to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'contextId': contextId,
      'userId': userId,
      'organization_id': organizationId,
      'userContext': userContext,
      'metadata': metadata,
      'credentials': credentials,
      'created_at': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  /// Creates from JSON
  factory AuthContext.fromJson(Map<String, dynamic> json) {
    return AuthContext(
      contextId: json['contextId'] as String,
      userId: json['userId'] as String?,
      organizationId: json['organization_id'] as String?,
      userContext: Map<String, dynamic>.from(json['userContext'] as Map? ?? {}),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      credentials: Map<String, dynamic>.from(json['credentials'] as Map? ?? {}),
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'AuthContext(id: $contextId, userId: $userId, valid: $isValid)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthContext && other.contextId == contextId;
  }

  @override
  int get hashCode => contextId.hashCode;
}

/// Thread-safe authentication state storage
class AuthStateStorage {
  AuthContext? _currentContext;
  StreamController<AuthContext?>? _stateController;

  AuthStateStorage() {
    _stateController = StreamController<AuthContext?>.broadcast();
  }

  /// Current authentication context
  AuthContext? get currentContext => _currentContext;

  /// Stream of authentication state changes
  Stream<AuthContext?> get stateChanges => _stateController!.stream;

  /// Sets the current authentication context
  void setContext(AuthContext? context) {
    if (_stateController == null || _stateController!.isClosed) {
      _stateController = StreamController<AuthContext?>.broadcast();
    }
    _currentContext = context;
    _stateController!.add(context);
  }

  /// Clears the current authentication context
  void clearContext() {
    _currentContext = null;
    if (_stateController != null && !_stateController!.isClosed) {
      _stateController!.add(null);
    }
  }

  /// Validates current context and clears if expired
  bool validateAndClean() {
    if (_currentContext?.isExpired == true) {
      clearContext();
      return false;
    }
    return _currentContext != null;
  }

  /// Updates current context credentials
  void updateCredentials(Map<String, dynamic> newCredentials) {
    if (_currentContext != null) {
      _currentContext = _currentContext!.copyWithCredentials(newCredentials);
      if (_stateController != null && !_stateController!.isClosed) {
        _stateController!.add(_currentContext);
      }
    }
  }

  /// Disposes resources
  void dispose() {
    if (_stateController != null && !_stateController!.isClosed) {
      _stateController!.close();
    }
  }
}
