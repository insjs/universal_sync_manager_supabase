import 'usm_sync_enums.dart';

/// Universal Sync Manager configuration class
///
/// This class contains all the settings needed to configure and operate
/// the Universal Sync Manager. It provides a centralized configuration
/// system that works across all backends and platforms.
///
/// Following USM naming conventions:
/// - File: usm_universal_sync_config.dart (snake_case with usm_ prefix)
/// - Class: UniversalSyncConfig (PascalCase)
class UniversalSyncConfig {
  /// Unique identifier for this sync project
  final String projectId;

  /// How the sync manager should operate
  final SyncMode syncMode;

  /// Interval between automatic sync operations
  final Duration syncInterval;

  /// Default strategy for resolving conflicts
  final ConflictResolutionStrategy defaultConflictStrategy;

  /// Maximum number of retry attempts for failed operations
  final int maxRetries;

  /// Delay between retry attempts
  final Duration retryDelay;

  /// Strategy for retry timing
  final RetryStrategy retryStrategy;

  /// Whether to enable compression for sync payloads
  final bool enableCompression;

  /// Type of compression to use
  final CompressionType compressionType;

  /// Whether to enable delta sync for incremental updates
  final bool enableDeltaSync;

  /// Default priority for sync operations
  final SyncPriority defaultPriority;

  /// Backend-specific configuration settings
  final Map<String, dynamic> backendConfig;

  /// Platform-specific optimizations
  final PlatformOptimizations platformOptimizations;

  /// Authentication-based entity categorization
  final List<String> publicEntities;

  /// Entities that require authentication
  final List<String> protectedEntities;

  /// Maximum size for batch operations
  final int maxBatchSize;

  /// Timeout for sync operations
  final Duration operationTimeout;

  /// Timeout for connection attempts
  final Duration connectionTimeout;

  /// Whether to enable real-time subscriptions
  final bool enableRealTimeSync;

  /// Maximum number of concurrent sync operations
  final int maxConcurrentOperations;

  /// Environment this configuration is for
  final SyncEnvironment environment;

  /// Logging level for sync operations
  final LogLevel logLevel;

  /// Whether to enable performance monitoring
  final bool enablePerformanceMonitoring;

  /// Whether to enable sync analytics
  final bool enableAnalytics;

  /// Custom configuration options for specific use cases
  final Map<String, dynamic> customSettings;

  /// Network-specific settings
  final NetworkSettings networkSettings;

  /// Security settings
  final SecuritySettings securitySettings;

  /// Offline mode settings
  final OfflineSettings offlineSettings;

  /// Creates a new Universal Sync Configuration
  const UniversalSyncConfig({
    required this.projectId,
    this.syncMode = SyncMode.automatic,
    this.syncInterval = const Duration(minutes: 15),
    this.defaultConflictStrategy = ConflictResolutionStrategy.timestampWins,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 5),
    this.retryStrategy = RetryStrategy.exponential,
    this.enableCompression = true,
    this.compressionType = CompressionType.gzip,
    this.enableDeltaSync = true,
    this.defaultPriority = SyncPriority.normal,
    this.backendConfig = const {},
    this.platformOptimizations = const PlatformOptimizations(),
    this.publicEntities = const [],
    this.protectedEntities = const [],
    this.maxBatchSize = 100,
    this.operationTimeout = const Duration(minutes: 5),
    this.connectionTimeout = const Duration(seconds: 30),
    this.enableRealTimeSync = true,
    this.maxConcurrentOperations = 5,
    this.environment = SyncEnvironment.development,
    this.logLevel = LogLevel.info,
    this.enablePerformanceMonitoring = false,
    this.enableAnalytics = false,
    this.customSettings = const {},
    this.networkSettings = const NetworkSettings(),
    this.securitySettings = const SecuritySettings(),
    this.offlineSettings = const OfflineSettings(),
  });

  /// Creates a configuration optimized for development
  factory UniversalSyncConfig.development({
    required String projectId,
    Map<String, dynamic> backendConfig = const {},
    Map<String, dynamic> customSettings = const {},
  }) {
    return UniversalSyncConfig(
      projectId: projectId,
      syncMode: SyncMode.manual,
      syncInterval: const Duration(minutes: 5),
      environment: SyncEnvironment.development,
      logLevel: LogLevel.debug,
      enablePerformanceMonitoring: true,
      maxRetries: 1,
      retryDelay: const Duration(seconds: 2),
      enableCompression: false,
      enableDeltaSync: false,
      backendConfig: backendConfig,
      customSettings: customSettings,
    );
  }

  /// Creates a configuration optimized for production
  factory UniversalSyncConfig.production({
    required String projectId,
    Map<String, dynamic> backendConfig = const {},
    Map<String, dynamic> customSettings = const {},
  }) {
    return UniversalSyncConfig(
      projectId: projectId,
      syncMode: SyncMode.automatic,
      syncInterval: const Duration(minutes: 30),
      environment: SyncEnvironment.production,
      logLevel: LogLevel.warning,
      enablePerformanceMonitoring: true,
      enableAnalytics: true,
      maxRetries: 5,
      retryDelay: const Duration(seconds: 10),
      enableCompression: true,
      enableDeltaSync: true,
      maxConcurrentOperations: 3,
      operationTimeout: const Duration(minutes: 10),
      backendConfig: backendConfig,
      customSettings: customSettings,
    );
  }

  /// Creates a configuration optimized for testing
  factory UniversalSyncConfig.testing({
    required String projectId,
    Map<String, dynamic> backendConfig = const {},
    Map<String, dynamic> customSettings = const {},
  }) {
    return UniversalSyncConfig(
      projectId: projectId,
      syncMode: SyncMode.manual,
      syncInterval: const Duration(seconds: 30),
      environment: SyncEnvironment.testing,
      logLevel: LogLevel.error,
      enablePerformanceMonitoring: false,
      enableAnalytics: false,
      maxRetries: 0,
      retryDelay: const Duration(seconds: 1),
      enableCompression: false,
      enableDeltaSync: false,
      enableRealTimeSync: false,
      maxConcurrentOperations: 1,
      operationTimeout: const Duration(seconds: 30),
      backendConfig: backendConfig,
      customSettings: customSettings,
    );
  }

  /// Creates a copy of this configuration with specified overrides
  UniversalSyncConfig copyWith({
    String? projectId,
    SyncMode? syncMode,
    Duration? syncInterval,
    ConflictResolutionStrategy? defaultConflictStrategy,
    int? maxRetries,
    Duration? retryDelay,
    RetryStrategy? retryStrategy,
    bool? enableCompression,
    CompressionType? compressionType,
    bool? enableDeltaSync,
    SyncPriority? defaultPriority,
    Map<String, dynamic>? backendConfig,
    PlatformOptimizations? platformOptimizations,
    List<String>? publicEntities,
    List<String>? protectedEntities,
    int? maxBatchSize,
    Duration? operationTimeout,
    Duration? connectionTimeout,
    bool? enableRealTimeSync,
    int? maxConcurrentOperations,
    SyncEnvironment? environment,
    LogLevel? logLevel,
    bool? enablePerformanceMonitoring,
    bool? enableAnalytics,
    Map<String, dynamic>? customSettings,
    NetworkSettings? networkSettings,
    SecuritySettings? securitySettings,
    OfflineSettings? offlineSettings,
  }) {
    return UniversalSyncConfig(
      projectId: projectId ?? this.projectId,
      syncMode: syncMode ?? this.syncMode,
      syncInterval: syncInterval ?? this.syncInterval,
      defaultConflictStrategy:
          defaultConflictStrategy ?? this.defaultConflictStrategy,
      maxRetries: maxRetries ?? this.maxRetries,
      retryDelay: retryDelay ?? this.retryDelay,
      retryStrategy: retryStrategy ?? this.retryStrategy,
      enableCompression: enableCompression ?? this.enableCompression,
      compressionType: compressionType ?? this.compressionType,
      enableDeltaSync: enableDeltaSync ?? this.enableDeltaSync,
      defaultPriority: defaultPriority ?? this.defaultPriority,
      backendConfig: backendConfig ?? this.backendConfig,
      platformOptimizations:
          platformOptimizations ?? this.platformOptimizations,
      publicEntities: publicEntities ?? this.publicEntities,
      protectedEntities: protectedEntities ?? this.protectedEntities,
      maxBatchSize: maxBatchSize ?? this.maxBatchSize,
      operationTimeout: operationTimeout ?? this.operationTimeout,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      enableRealTimeSync: enableRealTimeSync ?? this.enableRealTimeSync,
      maxConcurrentOperations:
          maxConcurrentOperations ?? this.maxConcurrentOperations,
      environment: environment ?? this.environment,
      logLevel: logLevel ?? this.logLevel,
      enablePerformanceMonitoring:
          enablePerformanceMonitoring ?? this.enablePerformanceMonitoring,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      customSettings: customSettings ?? this.customSettings,
      networkSettings: networkSettings ?? this.networkSettings,
      securitySettings: securitySettings ?? this.securitySettings,
      offlineSettings: offlineSettings ?? this.offlineSettings,
    );
  }

  /// Converts this configuration to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'syncMode': syncMode.name,
      'syncInterval': syncInterval.inMilliseconds,
      'defaultConflictStrategy': defaultConflictStrategy.name,
      'maxRetries': maxRetries,
      'retryDelay': retryDelay.inMilliseconds,
      'retryStrategy': retryStrategy.name,
      'enableCompression': enableCompression,
      'compressionType': compressionType.name,
      'enableDeltaSync': enableDeltaSync,
      'defaultPriority': defaultPriority.name,
      'backendConfig': backendConfig,
      'platformOptimizations': platformOptimizations.toJson(),
      'publicEntities': publicEntities,
      'protectedEntities': protectedEntities,
      'maxBatchSize': maxBatchSize,
      'operationTimeout': operationTimeout.inMilliseconds,
      'connectionTimeout': connectionTimeout.inMilliseconds,
      'enableRealTimeSync': enableRealTimeSync,
      'maxConcurrentOperations': maxConcurrentOperations,
      'environment': environment.name,
      'logLevel': logLevel.name,
      'enablePerformanceMonitoring': enablePerformanceMonitoring,
      'enableAnalytics': enableAnalytics,
      'customSettings': customSettings,
      'networkSettings': networkSettings.toJson(),
      'securitySettings': securitySettings.toJson(),
      'offlineSettings': offlineSettings.toJson(),
    };
  }

  /// Creates a configuration from a JSON map
  factory UniversalSyncConfig.fromJson(Map<String, dynamic> json) {
    return UniversalSyncConfig(
      projectId: json['projectId'] as String,
      syncMode: SyncMode.values.byName(json['syncMode'] as String),
      syncInterval: Duration(milliseconds: json['syncInterval'] as int),
      defaultConflictStrategy: ConflictResolutionStrategy.values
          .byName(json['defaultConflictStrategy'] as String),
      maxRetries: json['maxRetries'] as int,
      retryDelay: Duration(milliseconds: json['retryDelay'] as int),
      retryStrategy:
          RetryStrategy.values.byName(json['retryStrategy'] as String),
      enableCompression: json['enableCompression'] as bool,
      compressionType:
          CompressionType.values.byName(json['compressionType'] as String),
      enableDeltaSync: json['enableDeltaSync'] as bool,
      defaultPriority:
          SyncPriority.values.byName(json['defaultPriority'] as String),
      backendConfig: Map<String, dynamic>.from(json['backendConfig'] as Map),
      platformOptimizations: PlatformOptimizations.fromJson(
          json['platformOptimizations'] as Map<String, dynamic>),
      publicEntities: List<String>.from(json['publicEntities'] as List),
      protectedEntities: List<String>.from(json['protectedEntities'] as List),
      maxBatchSize: json['maxBatchSize'] as int,
      operationTimeout: Duration(milliseconds: json['operationTimeout'] as int),
      connectionTimeout:
          Duration(milliseconds: json['connectionTimeout'] as int),
      enableRealTimeSync: json['enableRealTimeSync'] as bool,
      maxConcurrentOperations: json['maxConcurrentOperations'] as int,
      environment: SyncEnvironment.values.byName(json['environment'] as String),
      logLevel: LogLevel.values.byName(json['logLevel'] as String),
      enablePerformanceMonitoring: json['enablePerformanceMonitoring'] as bool,
      enableAnalytics: json['enableAnalytics'] as bool,
      customSettings: Map<String, dynamic>.from(json['customSettings'] as Map),
      networkSettings: NetworkSettings.fromJson(
          json['networkSettings'] as Map<String, dynamic>),
      securitySettings: SecuritySettings.fromJson(
          json['securitySettings'] as Map<String, dynamic>),
      offlineSettings: OfflineSettings.fromJson(
          json['offlineSettings'] as Map<String, dynamic>),
    );
  }

  /// Validates the configuration and returns any validation errors
  List<String> validate() {
    final errors = <String>[];

    if (projectId.isEmpty) {
      errors.add('Project ID cannot be empty');
    }

    if (syncInterval.inSeconds < 1) {
      errors.add('Sync interval must be at least 1 second');
    }

    if (maxRetries < 0) {
      errors.add('Max retries cannot be negative');
    }

    if (maxBatchSize < 1) {
      errors.add('Max batch size must be at least 1');
    }

    if (maxConcurrentOperations < 1) {
      errors.add('Max concurrent operations must be at least 1');
    }

    if (operationTimeout.inSeconds < 1) {
      errors.add('Operation timeout must be at least 1 second');
    }

    if (connectionTimeout.inSeconds < 1) {
      errors.add('Connection timeout must be at least 1 second');
    }

    // Validate backend config based on environment
    if (environment == SyncEnvironment.production && backendConfig.isEmpty) {
      errors.add('Backend configuration required for production environment');
    }

    return errors;
  }

  /// Checks if this configuration is valid
  bool get isValid => validate().isEmpty;

  @override
  String toString() {
    return 'UniversalSyncConfig(projectId: $projectId, syncMode: $syncMode, environment: $environment)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UniversalSyncConfig &&
        other.projectId == projectId &&
        other.syncMode == syncMode &&
        other.environment == environment;
  }

  @override
  int get hashCode => Object.hash(projectId, syncMode, environment);
}

/// Platform-specific optimization settings
class PlatformOptimizations {
  /// Whether to enable platform-specific database optimizations
  final bool enableDatabaseOptimizations;

  /// Whether to use platform-specific networking
  final bool usePlatformNetworking;

  /// Maximum memory usage for caching (in MB)
  final int maxCacheMemoryMB;

  /// Whether to enable background sync on mobile platforms
  final bool enableBackgroundSync;

  /// Whether to respect battery optimization settings
  final bool respectBatteryOptimization;

  /// Whether to use WiFi-only sync mode
  final bool wifiOnlySync;

  /// Custom platform-specific settings
  final Map<String, dynamic> customPlatformSettings;

  const PlatformOptimizations({
    this.enableDatabaseOptimizations = true,
    this.usePlatformNetworking = true,
    this.maxCacheMemoryMB = 100,
    this.enableBackgroundSync = false,
    this.respectBatteryOptimization = true,
    this.wifiOnlySync = false,
    this.customPlatformSettings = const {},
  });

  Map<String, dynamic> toJson() => {
        'enableDatabaseOptimizations': enableDatabaseOptimizations,
        'usePlatformNetworking': usePlatformNetworking,
        'maxCacheMemoryMB': maxCacheMemoryMB,
        'enableBackgroundSync': enableBackgroundSync,
        'respectBatteryOptimization': respectBatteryOptimization,
        'wifiOnlySync': wifiOnlySync,
        'customPlatformSettings': customPlatformSettings,
      };

  factory PlatformOptimizations.fromJson(Map<String, dynamic> json) =>
      PlatformOptimizations(
        enableDatabaseOptimizations:
            json['enableDatabaseOptimizations'] as bool,
        usePlatformNetworking: json['usePlatformNetworking'] as bool,
        maxCacheMemoryMB: json['maxCacheMemoryMB'] as int,
        enableBackgroundSync: json['enableBackgroundSync'] as bool,
        respectBatteryOptimization: json['respectBatteryOptimization'] as bool,
        wifiOnlySync: json['wifiOnlySync'] as bool,
        customPlatformSettings:
            Map<String, dynamic>.from(json['customPlatformSettings'] as Map),
      );
}

/// Network-specific configuration settings
class NetworkSettings {
  /// Maximum time to wait for network requests
  final Duration requestTimeout;

  /// Whether to automatically retry on network errors
  final bool autoRetryOnNetworkError;

  /// Minimum network quality required for sync
  final NetworkCondition minNetworkQuality;

  /// Whether to use cellular data for sync
  final bool allowCellularSync;

  /// Maximum bandwidth usage per sync operation (in KB/s)
  final int maxBandwidthKBps;

  /// Whether to enable request compression
  final bool enableRequestCompression;

  const NetworkSettings({
    this.requestTimeout = const Duration(seconds: 30),
    this.autoRetryOnNetworkError = true,
    this.minNetworkQuality = NetworkCondition.limited,
    this.allowCellularSync = true,
    this.maxBandwidthKBps = 1024, // 1 MB/s
    this.enableRequestCompression = true,
  });

  Map<String, dynamic> toJson() => {
        'requestTimeout': requestTimeout.inMilliseconds,
        'autoRetryOnNetworkError': autoRetryOnNetworkError,
        'minNetworkQuality': minNetworkQuality.name,
        'allowCellularSync': allowCellularSync,
        'maxBandwidthKBps': maxBandwidthKBps,
        'enableRequestCompression': enableRequestCompression,
      };

  factory NetworkSettings.fromJson(Map<String, dynamic> json) =>
      NetworkSettings(
        requestTimeout: Duration(milliseconds: json['requestTimeout'] as int),
        autoRetryOnNetworkError: json['autoRetryOnNetworkError'] as bool,
        minNetworkQuality:
            NetworkCondition.values.byName(json['minNetworkQuality'] as String),
        allowCellularSync: json['allowCellularSync'] as bool,
        maxBandwidthKBps: json['maxBandwidthKBps'] as int,
        enableRequestCompression: json['enableRequestCompression'] as bool,
      );
}

/// Security-related configuration settings
class SecuritySettings {
  /// Whether to enable end-to-end encryption
  final bool enableEncryption;

  /// Security level for sensitive data
  final SecurityLevel defaultSecurityLevel;

  /// Whether to validate SSL certificates
  final bool validateSSLCertificates;

  /// Whether to enable request signing
  final bool enableRequestSigning;

  /// Custom security settings
  final Map<String, dynamic> customSecuritySettings;

  const SecuritySettings({
    this.enableEncryption = false,
    this.defaultSecurityLevel = SecurityLevel.internal,
    this.validateSSLCertificates = true,
    this.enableRequestSigning = false,
    this.customSecuritySettings = const {},
  });

  Map<String, dynamic> toJson() => {
        'enableEncryption': enableEncryption,
        'defaultSecurityLevel': defaultSecurityLevel.name,
        'validateSSLCertificates': validateSSLCertificates,
        'enableRequestSigning': enableRequestSigning,
        'customSecuritySettings': customSecuritySettings,
      };

  factory SecuritySettings.fromJson(Map<String, dynamic> json) =>
      SecuritySettings(
        enableEncryption: json['enableEncryption'] as bool,
        defaultSecurityLevel:
            SecurityLevel.values.byName(json['defaultSecurityLevel'] as String),
        validateSSLCertificates: json['validateSSLCertificates'] as bool,
        enableRequestSigning: json['enableRequestSigning'] as bool,
        customSecuritySettings:
            Map<String, dynamic>.from(json['customSecuritySettings'] as Map),
      );
}

/// Offline mode configuration settings
class OfflineSettings {
  /// Whether to enable offline mode
  final bool enableOfflineMode;

  /// Maximum time to keep data offline before forcing sync
  final Duration maxOfflineTime;

  /// Maximum number of offline operations to queue
  final int maxOfflineOperations;

  /// Whether to automatically sync when connection is restored
  final bool autoSyncOnReconnect;

  /// Whether to enable conflict detection for offline changes
  final bool enableOfflineConflictDetection;

  const OfflineSettings({
    this.enableOfflineMode = true,
    this.maxOfflineTime = const Duration(days: 7),
    this.maxOfflineOperations = 1000,
    this.autoSyncOnReconnect = true,
    this.enableOfflineConflictDetection = true,
  });

  Map<String, dynamic> toJson() => {
        'enableOfflineMode': enableOfflineMode,
        'maxOfflineTime': maxOfflineTime.inMilliseconds,
        'maxOfflineOperations': maxOfflineOperations,
        'autoSyncOnReconnect': autoSyncOnReconnect,
        'enableOfflineConflictDetection': enableOfflineConflictDetection,
      };

  factory OfflineSettings.fromJson(Map<String, dynamic> json) =>
      OfflineSettings(
        enableOfflineMode: json['enableOfflineMode'] as bool,
        maxOfflineTime: Duration(milliseconds: json['maxOfflineTime'] as int),
        maxOfflineOperations: json['maxOfflineOperations'] as int,
        autoSyncOnReconnect: json['autoSyncOnReconnect'] as bool,
        enableOfflineConflictDetection:
            json['enableOfflineConflictDetection'] as bool,
      );
}
