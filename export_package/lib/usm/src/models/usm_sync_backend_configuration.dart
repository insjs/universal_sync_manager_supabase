/// Configuration class for backend adapter connections
///
/// This class encapsulates all the configuration needed to connect to a backend
/// service, including authentication, endpoints, and backend-specific settings.
class SyncBackendConfiguration {
  /// Unique identifier for this configuration
  final String configId;

  /// Human-readable name for this configuration
  final String displayName;

  /// Backend type identifier (e.g., 'firebase', 'supabase', 'pocketbase')
  final String backendType;

  /// Primary endpoint URL for the backend service
  final String baseUrl;

  /// Project or database identifier
  final String projectId;

  /// Authentication configuration
  final SyncAuthConfiguration? authConfig;

  /// Connection timeout settings
  final Duration connectionTimeout;

  /// Request timeout settings
  final Duration requestTimeout;

  /// Maximum number of retry attempts for failed requests
  final int maxRetries;

  /// Delay between retry attempts
  final Duration retryDelay;

  /// Whether to use SSL/TLS for connections
  final bool useSSL;

  /// Backend-specific configuration options
  final Map<String, dynamic> customSettings;

  /// Environment-specific settings (dev, staging, prod)
  final String environment;

  /// API version to use (if backend supports versioning)
  final String? apiVersion;

  /// Regional settings for geo-distributed backends
  final String? region;

  /// Connection pool settings
  final SyncConnectionPoolConfig? poolConfig;

  const SyncBackendConfiguration({
    required this.configId,
    required this.displayName,
    required this.backendType,
    required this.baseUrl,
    required this.projectId,
    this.authConfig,
    this.connectionTimeout = const Duration(seconds: 30),
    this.requestTimeout = const Duration(seconds: 15),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
    this.useSSL = true,
    this.customSettings = const {},
    this.environment = 'production',
    this.apiVersion,
    this.region,
    this.poolConfig,
  });

  /// Creates configuration for Firebase
  factory SyncBackendConfiguration.firebase({
    required String configId,
    required String projectId,
    String? apiKey,
    String? authDomain,
    String? databaseURL,
    String region = 'us-central1',
    String environment = 'production',
  }) {
    return SyncBackendConfiguration(
      configId: configId,
      displayName: 'Firebase ($projectId)',
      backendType: 'firebase',
      baseUrl: databaseURL ?? 'https://$projectId-default-rtdb.firebaseio.com',
      projectId: projectId,
      authConfig: apiKey != null ? SyncAuthConfiguration.apiKey(apiKey) : null,
      region: region,
      environment: environment,
      customSettings: {
        'authDomain': authDomain ?? '$projectId.firebaseapp.com',
        'storageBucket': '$projectId.appspot.com',
        'messagingSenderId': '', // To be filled by user
        'appId': '', // To be filled by user
      },
    );
  }

  /// Creates configuration for Supabase
  factory SyncBackendConfiguration.supabase({
    required String configId,
    required String projectUrl,
    required String anonKey,
    String? serviceRoleKey,
    String environment = 'production',
  }) {
    final projectId = Uri.parse(projectUrl).host.split('.').first;

    return SyncBackendConfiguration(
      configId: configId,
      displayName: 'Supabase ($projectId)',
      backendType: 'supabase',
      baseUrl: projectUrl,
      projectId: projectId,
      authConfig: SyncAuthConfiguration.bearer(anonKey),
      environment: environment,
      customSettings: {
        'anonKey': anonKey,
        'serviceRoleKey': serviceRoleKey,
        'schema': 'public',
      },
    );
  }

  /// Creates configuration for PocketBase
  factory SyncBackendConfiguration.pocketBase({
    required String configId,
    required String baseUrl,
    String? adminEmail,
    String? adminPassword,
    String environment = 'production',
  }) {
    final uri = Uri.parse(baseUrl);
    final projectId = uri.host.replaceAll('.', '_');

    return SyncBackendConfiguration(
      configId: configId,
      displayName: 'PocketBase ($projectId)',
      backendType: 'pocketbase',
      baseUrl: baseUrl,
      projectId: projectId,
      authConfig: adminEmail != null && adminPassword != null
          ? SyncAuthConfiguration.usernamePassword(adminEmail, adminPassword)
          : null,
      environment: environment,
      customSettings: {
        'adminEmail': adminEmail,
        'adminPassword': adminPassword,
      },
    );
  }

  /// Creates configuration for custom API backend
  factory SyncBackendConfiguration.customApi({
    required String configId,
    required String displayName,
    required String baseUrl,
    required String projectId,
    SyncAuthConfiguration? authConfig,
    Map<String, dynamic> customSettings = const {},
    String environment = 'production',
  }) {
    return SyncBackendConfiguration(
      configId: configId,
      displayName: displayName,
      backendType: 'custom',
      baseUrl: baseUrl,
      projectId: projectId,
      authConfig: authConfig,
      environment: environment,
      customSettings: customSettings,
    );
  }

  /// Gets the full URL for a specific endpoint
  String getEndpointUrl(String endpoint) {
    final baseUri = Uri.parse(baseUrl);
    if (endpoint.startsWith('/')) {
      return baseUri.resolve(endpoint).toString();
    }
    return baseUri.resolve('/$endpoint').toString();
  }

  /// Gets a custom setting value with type safety
  T? getCustomSetting<T>(String key) {
    final value = customSettings[key];
    return value is T ? value : null;
  }

  /// Creates a copy with modified values
  SyncBackendConfiguration copyWith({
    String? configId,
    String? displayName,
    String? backendType,
    String? baseUrl,
    String? projectId,
    SyncAuthConfiguration? authConfig,
    Duration? connectionTimeout,
    Duration? requestTimeout,
    int? maxRetries,
    Duration? retryDelay,
    bool? useSSL,
    Map<String, dynamic>? customSettings,
    String? environment,
    String? apiVersion,
    String? region,
    SyncConnectionPoolConfig? poolConfig,
  }) {
    return SyncBackendConfiguration(
      configId: configId ?? this.configId,
      displayName: displayName ?? this.displayName,
      backendType: backendType ?? this.backendType,
      baseUrl: baseUrl ?? this.baseUrl,
      projectId: projectId ?? this.projectId,
      authConfig: authConfig ?? this.authConfig,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      requestTimeout: requestTimeout ?? this.requestTimeout,
      maxRetries: maxRetries ?? this.maxRetries,
      retryDelay: retryDelay ?? this.retryDelay,
      useSSL: useSSL ?? this.useSSL,
      customSettings: customSettings ?? this.customSettings,
      environment: environment ?? this.environment,
      apiVersion: apiVersion ?? this.apiVersion,
      region: region ?? this.region,
      poolConfig: poolConfig ?? this.poolConfig,
    );
  }

  /// Converts to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'configId': configId,
      'displayName': displayName,
      'backendType': backendType,
      'baseUrl': baseUrl,
      'projectId': projectId,
      'authConfig': authConfig?.toJson(),
      'connectionTimeout': connectionTimeout.inMilliseconds,
      'requestTimeout': requestTimeout.inMilliseconds,
      'maxRetries': maxRetries,
      'retryDelay': retryDelay.inMilliseconds,
      'useSSL': useSSL,
      'customSettings': customSettings,
      'environment': environment,
      'apiVersion': apiVersion,
      'region': region,
      'poolConfig': poolConfig?.toJson(),
    };
  }

  /// Creates from JSON
  factory SyncBackendConfiguration.fromJson(Map<String, dynamic> json) {
    return SyncBackendConfiguration(
      configId: json['configId'] as String,
      displayName: json['displayName'] as String,
      backendType: json['backendType'] as String,
      baseUrl: json['baseUrl'] as String,
      projectId: json['projectId'] as String,
      authConfig: json['authConfig'] != null
          ? SyncAuthConfiguration.fromJson(
              json['authConfig'] as Map<String, dynamic>)
          : null,
      connectionTimeout:
          Duration(milliseconds: json['connectionTimeout'] as int),
      requestTimeout: Duration(milliseconds: json['requestTimeout'] as int),
      maxRetries: json['maxRetries'] as int,
      retryDelay: Duration(milliseconds: json['retryDelay'] as int),
      useSSL: json['useSSL'] as bool,
      customSettings: Map<String, dynamic>.from(json['customSettings'] as Map),
      environment: json['environment'] as String,
      apiVersion: json['apiVersion'] as String?,
      region: json['region'] as String?,
      poolConfig: json['poolConfig'] != null
          ? SyncConnectionPoolConfig.fromJson(
              json['poolConfig'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Authentication configuration for backend connections
class SyncAuthConfiguration {
  final SyncAuthType type;
  final Map<String, dynamic> credentials;

  /// User context information for authenticated operations
  final Map<String, dynamic>? userContext;

  /// Token refresh callback for automatic token management
  final Future<String> Function()? tokenRefreshCallback;

  /// Additional authentication metadata (roles, permissions, etc.)
  final Map<String, dynamic> metadata;

  const SyncAuthConfiguration({
    required this.type,
    required this.credentials,
    this.userContext,
    this.tokenRefreshCallback,
    this.metadata = const {},
  });

  /// Factory method for app integration with enhanced user context
  factory SyncAuthConfiguration.fromApp({
    required String userId,
    String? organizationId,
    Map<String, dynamic> customFields = const {},
    Map<String, dynamic> roleMetadata = const {},
    Future<String> Function()? onTokenRefresh,
    required SyncAuthType authType,
    required Map<String, dynamic> credentials,
  }) {
    final userContext = {
      'userId': userId,
      if (organizationId != null) 'organizationId': organizationId,
      ...customFields,
    };

    return SyncAuthConfiguration(
      type: authType,
      credentials: credentials,
      userContext: userContext,
      tokenRefreshCallback: onTokenRefresh,
      metadata: roleMetadata,
    );
  }

  /// API Key authentication
  factory SyncAuthConfiguration.apiKey(String apiKey) {
    return SyncAuthConfiguration(
      type: SyncAuthType.apiKey,
      credentials: {'apiKey': apiKey},
    );
  }

  /// Bearer token authentication
  factory SyncAuthConfiguration.bearer(String token) {
    return SyncAuthConfiguration(
      type: SyncAuthType.bearer,
      credentials: {'token': token},
    );
  }

  /// Username/password authentication
  factory SyncAuthConfiguration.usernamePassword(
      String username, String password) {
    return SyncAuthConfiguration(
      type: SyncAuthType.usernamePassword,
      credentials: {
        'username': username,
        'password': password,
      },
    );
  }

  /// OAuth 2.0 authentication
  factory SyncAuthConfiguration.oauth2({
    required String clientId,
    required String clientSecret,
    String? accessToken,
    String? refreshToken,
    String? scope,
  }) {
    return SyncAuthConfiguration(
      type: SyncAuthType.oauth2,
      credentials: {
        'clientId': clientId,
        'clientSecret': clientSecret,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'scope': scope,
      },
    );
  }

  /// Custom authentication
  factory SyncAuthConfiguration.custom(Map<String, dynamic> credentials) {
    return SyncAuthConfiguration(
      type: SyncAuthType.custom,
      credentials: credentials,
    );
  }

  /// Gets user ID from context
  String? get userId => userContext?['userId'] as String?;

  /// Gets organization ID from context
  String? get organizationId => userContext?['organizationId'] as String?;

  /// Gets custom field from user context
  T? getCustomField<T>(String key) {
    final value = userContext?[key];
    return value is T ? value : null;
  }

  /// Gets role-based feature flag from metadata
  bool hasFeature(String featureName) {
    final features = metadata['features'] as Map<String, dynamic>?;
    return features?[featureName] == true;
  }

  /// Gets role information from metadata
  List<String> get roles {
    final rolesData = metadata['roles'];
    if (rolesData is List) {
      return rolesData.cast<String>();
    }
    return [];
  }

  /// Gets a credential value with type safety
  T? getCredential<T>(String key) {
    final value = credentials[key];
    return value is T ? value : null;
  }

  /// Creates a copy with updated token (for refresh scenarios)
  SyncAuthConfiguration copyWithToken(String newToken) {
    final updatedCredentials = Map<String, dynamic>.from(credentials);

    switch (type) {
      case SyncAuthType.bearer:
        updatedCredentials['token'] = newToken;
        break;
      case SyncAuthType.oauth2:
        updatedCredentials['accessToken'] = newToken;
        break;
      case SyncAuthType.apiKey:
        updatedCredentials['apiKey'] = newToken;
        break;
      default:
        // For other types, store in a generic 'token' field
        updatedCredentials['token'] = newToken;
        break;
    }

    return SyncAuthConfiguration(
      type: type,
      credentials: updatedCredentials,
      userContext: userContext,
      tokenRefreshCallback: tokenRefreshCallback,
      metadata: metadata,
    );
  }

  /// Converts to JSON (excluding sensitive data in production)
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'credentials':
          credentials, // Note: Should mask sensitive data in production
      'userContext': userContext,
      'metadata': metadata,
    };
  }

  /// Creates from JSON
  factory SyncAuthConfiguration.fromJson(Map<String, dynamic> json) {
    return SyncAuthConfiguration(
      type: SyncAuthType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => SyncAuthType.custom,
      ),
      credentials: Map<String, dynamic>.from(json['credentials'] as Map),
      userContext: json['userContext'] != null
          ? Map<String, dynamic>.from(json['userContext'] as Map)
          : null,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const {},
    );
  }
}

/// Authentication types supported by the sync system
enum SyncAuthType {
  none,
  apiKey,
  bearer,
  usernamePassword,
  oauth2,
  custom,
}

/// Connection pool configuration for managing multiple connections
class SyncConnectionPoolConfig {
  final int maxConnections;
  final Duration connectionIdleTimeout;
  final Duration connectionMaxLifetime;
  final bool enableConnectionValidation;

  const SyncConnectionPoolConfig({
    this.maxConnections = 10,
    this.connectionIdleTimeout = const Duration(minutes: 5),
    this.connectionMaxLifetime = const Duration(hours: 1),
    this.enableConnectionValidation = true,
  });

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'maxConnections': maxConnections,
      'connectionIdleTimeout': connectionIdleTimeout.inMilliseconds,
      'connectionMaxLifetime': connectionMaxLifetime.inMilliseconds,
      'enableConnectionValidation': enableConnectionValidation,
    };
  }

  /// Creates from JSON
  factory SyncConnectionPoolConfig.fromJson(Map<String, dynamic> json) {
    return SyncConnectionPoolConfig(
      maxConnections: json['maxConnections'] as int,
      connectionIdleTimeout:
          Duration(milliseconds: json['connectionIdleTimeout'] as int),
      connectionMaxLifetime:
          Duration(milliseconds: json['connectionMaxLifetime'] as int),
      enableConnectionValidation: json['enableConnectionValidation'] as bool,
    );
  }
}
