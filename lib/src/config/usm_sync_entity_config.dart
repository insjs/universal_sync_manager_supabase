import 'usm_sync_enums.dart';

/// Configuration for a specific syncable entity/table
///
/// This class defines entity-specific sync behavior and settings
/// that override the global Universal Sync Manager configuration.
///
/// Following USM naming conventions:
/// - File: usm_sync_entity_config.dart (snake_case with usm_ prefix)
/// - Class: SyncEntityConfig (PascalCase)
class SyncEntityConfig {
  /// Name of the table/collection in the backend
  final String tableName;

  /// Whether this entity requires authentication to access
  final bool requiresAuthentication;

  /// Conflict resolution strategy specific to this entity
  final ConflictResolutionStrategy? conflictStrategy;

  /// Sync direction for this entity
  final SyncDirection? syncDirection;

  /// Priority level for syncing this entity
  final SyncPriority? priority;

  /// Whether this entity supports real-time updates
  final bool enableRealTime;

  /// Whether to enable delta sync for this entity
  final bool enableDeltaSync;

  /// Maximum batch size for this entity
  final int? maxBatchSize;

  /// Custom sync interval for this entity (overrides global)
  final Duration? syncInterval;

  /// Whether this entity should be synced in offline mode
  final bool syncOffline;

  /// Security level required for this entity
  final SecurityLevel? securityLevel;

  /// Custom fields that should be excluded from sync
  final List<String> excludedFields;

  /// Custom fields that are required for sync
  final List<String> requiredFields;

  /// Whether to validate data before syncing
  final bool validateBeforeSync;

  /// Custom validation rules for this entity
  final Map<String, dynamic> validationRules;

  /// Transformation rules for field mapping
  final Map<String, String> fieldMappings;

  /// Whether to enable encryption for this entity
  final bool enableEncryption;

  /// Custom encryption settings
  final Map<String, dynamic> encryptionSettings;

  /// Whether to track changes for this entity
  final bool trackChanges;

  /// Maximum age of data before forced refresh
  final Duration? maxDataAge;

  /// Custom query filters for this entity
  final Map<String, dynamic> queryFilters;

  /// Whether to enable caching for this entity
  final bool enableCaching;

  /// Cache expiration time
  final Duration? cacheExpiration;

  /// Whether to enable compression for this entity
  final bool enableCompression;

  /// Compression settings specific to this entity
  final CompressionType? compressionType;

  /// Custom settings specific to this entity
  final Map<String, dynamic> customSettings;

  /// Creates a new sync entity configuration
  const SyncEntityConfig({
    required this.tableName,
    this.requiresAuthentication = false,
    this.conflictStrategy,
    this.syncDirection,
    this.priority,
    this.enableRealTime = true,
    this.enableDeltaSync = true,
    this.maxBatchSize,
    this.syncInterval,
    this.syncOffline = true,
    this.securityLevel,
    this.excludedFields = const [],
    this.requiredFields = const [],
    this.validateBeforeSync = true,
    this.validationRules = const {},
    this.fieldMappings = const {},
    this.enableEncryption = false,
    this.encryptionSettings = const {},
    this.trackChanges = true,
    this.maxDataAge,
    this.queryFilters = const {},
    this.enableCaching = true,
    this.cacheExpiration,
    this.enableCompression = false,
    this.compressionType,
    this.customSettings = const {},
  });

  /// Creates a configuration for public entities (no authentication required)
  factory SyncEntityConfig.public({
    required String tableName,
    SyncDirection? syncDirection,
    SyncPriority? priority,
    Map<String, dynamic> customSettings = const {},
  }) {
    return SyncEntityConfig(
      tableName: tableName,
      requiresAuthentication: false,
      syncDirection: syncDirection ?? SyncDirection.downloadOnly,
      priority: priority ?? SyncPriority.low,
      enableRealTime: false,
      enableDeltaSync: false,
      syncOffline: true,
      securityLevel: SecurityLevel.public,
      enableEncryption: false,
      customSettings: customSettings,
    );
  }

  /// Creates a configuration for protected entities (authentication required)
  factory SyncEntityConfig.protected({
    required String tableName,
    ConflictResolutionStrategy? conflictStrategy,
    SyncDirection? syncDirection,
    SyncPriority? priority,
    SecurityLevel? securityLevel,
    bool enableEncryption = true,
    Map<String, dynamic> customSettings = const {},
  }) {
    return SyncEntityConfig(
      tableName: tableName,
      requiresAuthentication: true,
      conflictStrategy:
          conflictStrategy ?? ConflictResolutionStrategy.timestampWins,
      syncDirection: syncDirection ?? SyncDirection.bidirectional,
      priority: priority ?? SyncPriority.normal,
      enableRealTime: true,
      enableDeltaSync: true,
      syncOffline: true,
      securityLevel: securityLevel ?? SecurityLevel.internal,
      enableEncryption: enableEncryption,
      customSettings: customSettings,
    );
  }

  /// Creates a configuration for high-priority entities
  factory SyncEntityConfig.highPriority({
    required String tableName,
    bool requiresAuthentication = true,
    ConflictResolutionStrategy? conflictStrategy,
    SecurityLevel? securityLevel,
    Map<String, dynamic> customSettings = const {},
  }) {
    return SyncEntityConfig(
      tableName: tableName,
      requiresAuthentication: requiresAuthentication,
      conflictStrategy:
          conflictStrategy ?? ConflictResolutionStrategy.timestampWins,
      syncDirection: SyncDirection.bidirectional,
      priority: SyncPriority.high,
      enableRealTime: true,
      enableDeltaSync: true,
      syncOffline: true,
      securityLevel: securityLevel ?? SecurityLevel.sensitive,
      enableEncryption: true,
      trackChanges: true,
      customSettings: customSettings,
    );
  }

  /// Creates a configuration for read-only entities
  factory SyncEntityConfig.readOnly({
    required String tableName,
    bool requiresAuthentication = false,
    SyncPriority? priority,
    Duration? cacheExpiration,
    Map<String, dynamic> customSettings = const {},
  }) {
    return SyncEntityConfig(
      tableName: tableName,
      requiresAuthentication: requiresAuthentication,
      syncDirection: SyncDirection.downloadOnly,
      priority: priority ?? SyncPriority.low,
      enableRealTime: false,
      enableDeltaSync: false,
      syncOffline: true,
      enableCaching: true,
      cacheExpiration: cacheExpiration ?? const Duration(hours: 24),
      trackChanges: false,
      customSettings: customSettings,
    );
  }

  /// Creates a copy of this configuration with specified overrides
  SyncEntityConfig copyWith({
    String? tableName,
    bool? requiresAuthentication,
    ConflictResolutionStrategy? conflictStrategy,
    SyncDirection? syncDirection,
    SyncPriority? priority,
    bool? enableRealTime,
    bool? enableDeltaSync,
    int? maxBatchSize,
    Duration? syncInterval,
    bool? syncOffline,
    SecurityLevel? securityLevel,
    List<String>? excludedFields,
    List<String>? requiredFields,
    bool? validateBeforeSync,
    Map<String, dynamic>? validationRules,
    Map<String, String>? fieldMappings,
    bool? enableEncryption,
    Map<String, dynamic>? encryptionSettings,
    bool? trackChanges,
    Duration? maxDataAge,
    Map<String, dynamic>? queryFilters,
    bool? enableCaching,
    Duration? cacheExpiration,
    bool? enableCompression,
    CompressionType? compressionType,
    Map<String, dynamic>? customSettings,
  }) {
    return SyncEntityConfig(
      tableName: tableName ?? this.tableName,
      requiresAuthentication:
          requiresAuthentication ?? this.requiresAuthentication,
      conflictStrategy: conflictStrategy ?? this.conflictStrategy,
      syncDirection: syncDirection ?? this.syncDirection,
      priority: priority ?? this.priority,
      enableRealTime: enableRealTime ?? this.enableRealTime,
      enableDeltaSync: enableDeltaSync ?? this.enableDeltaSync,
      maxBatchSize: maxBatchSize ?? this.maxBatchSize,
      syncInterval: syncInterval ?? this.syncInterval,
      syncOffline: syncOffline ?? this.syncOffline,
      securityLevel: securityLevel ?? this.securityLevel,
      excludedFields: excludedFields ?? this.excludedFields,
      requiredFields: requiredFields ?? this.requiredFields,
      validateBeforeSync: validateBeforeSync ?? this.validateBeforeSync,
      validationRules: validationRules ?? this.validationRules,
      fieldMappings: fieldMappings ?? this.fieldMappings,
      enableEncryption: enableEncryption ?? this.enableEncryption,
      encryptionSettings: encryptionSettings ?? this.encryptionSettings,
      trackChanges: trackChanges ?? this.trackChanges,
      maxDataAge: maxDataAge ?? this.maxDataAge,
      queryFilters: queryFilters ?? this.queryFilters,
      enableCaching: enableCaching ?? this.enableCaching,
      cacheExpiration: cacheExpiration ?? this.cacheExpiration,
      enableCompression: enableCompression ?? this.enableCompression,
      compressionType: compressionType ?? this.compressionType,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  /// Converts this configuration to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'tableName': tableName,
      'requiresAuthentication': requiresAuthentication,
      'conflictStrategy': conflictStrategy?.name,
      'syncDirection': syncDirection?.name,
      'priority': priority?.name,
      'enableRealTime': enableRealTime,
      'enableDeltaSync': enableDeltaSync,
      'maxBatchSize': maxBatchSize,
      'syncInterval': syncInterval?.inMilliseconds,
      'syncOffline': syncOffline,
      'securityLevel': securityLevel?.name,
      'excludedFields': excludedFields,
      'requiredFields': requiredFields,
      'validateBeforeSync': validateBeforeSync,
      'validationRules': validationRules,
      'fieldMappings': fieldMappings,
      'enableEncryption': enableEncryption,
      'encryptionSettings': encryptionSettings,
      'trackChanges': trackChanges,
      'maxDataAge': maxDataAge?.inMilliseconds,
      'queryFilters': queryFilters,
      'enableCaching': enableCaching,
      'cacheExpiration': cacheExpiration?.inMilliseconds,
      'enableCompression': enableCompression,
      'compressionType': compressionType?.name,
      'customSettings': customSettings,
    };
  }

  /// Creates a configuration from a JSON map
  factory SyncEntityConfig.fromJson(Map<String, dynamic> json) {
    return SyncEntityConfig(
      tableName: json['tableName'] as String,
      requiresAuthentication: json['requiresAuthentication'] as bool? ?? false,
      conflictStrategy: json['conflictStrategy'] != null
          ? ConflictResolutionStrategy.values
              .byName(json['conflictStrategy'] as String)
          : null,
      syncDirection: json['syncDirection'] != null
          ? SyncDirection.values.byName(json['syncDirection'] as String)
          : null,
      priority: json['priority'] != null
          ? SyncPriority.values.byName(json['priority'] as String)
          : null,
      enableRealTime: json['enableRealTime'] as bool? ?? true,
      enableDeltaSync: json['enableDeltaSync'] as bool? ?? true,
      maxBatchSize: json['maxBatchSize'] as int?,
      syncInterval: json['syncInterval'] != null
          ? Duration(milliseconds: json['syncInterval'] as int)
          : null,
      syncOffline: json['syncOffline'] as bool? ?? true,
      securityLevel: json['securityLevel'] != null
          ? SecurityLevel.values.byName(json['securityLevel'] as String)
          : null,
      excludedFields: List<String>.from(json['excludedFields'] as List? ?? []),
      requiredFields: List<String>.from(json['requiredFields'] as List? ?? []),
      validateBeforeSync: json['validateBeforeSync'] as bool? ?? true,
      validationRules:
          Map<String, dynamic>.from(json['validationRules'] as Map? ?? {}),
      fieldMappings:
          Map<String, String>.from(json['fieldMappings'] as Map? ?? {}),
      enableEncryption: json['enableEncryption'] as bool? ?? false,
      encryptionSettings:
          Map<String, dynamic>.from(json['encryptionSettings'] as Map? ?? {}),
      trackChanges: json['trackChanges'] as bool? ?? true,
      maxDataAge: json['maxDataAge'] != null
          ? Duration(milliseconds: json['maxDataAge'] as int)
          : null,
      queryFilters:
          Map<String, dynamic>.from(json['queryFilters'] as Map? ?? {}),
      enableCaching: json['enableCaching'] as bool? ?? true,
      cacheExpiration: json['cacheExpiration'] != null
          ? Duration(milliseconds: json['cacheExpiration'] as int)
          : null,
      enableCompression: json['enableCompression'] as bool? ?? false,
      compressionType: json['compressionType'] != null
          ? CompressionType.values.byName(json['compressionType'] as String)
          : null,
      customSettings:
          Map<String, dynamic>.from(json['customSettings'] as Map? ?? {}),
    );
  }

  /// Validates the configuration and returns any validation errors
  List<String> validate() {
    final errors = <String>[];

    if (tableName.isEmpty) {
      errors.add('Table name cannot be empty');
    }

    if (maxBatchSize != null && maxBatchSize! < 1) {
      errors.add('Max batch size must be at least 1');
    }

    if (syncInterval != null && syncInterval!.inSeconds < 1) {
      errors.add('Sync interval must be at least 1 second');
    }

    if (maxDataAge != null && maxDataAge!.inSeconds < 1) {
      errors.add('Max data age must be at least 1 second');
    }

    if (cacheExpiration != null && cacheExpiration!.inSeconds < 1) {
      errors.add('Cache expiration must be at least 1 second');
    }

    // Validate field mappings
    for (final mapping in fieldMappings.entries) {
      if (mapping.key.isEmpty || mapping.value.isEmpty) {
        errors.add('Field mapping keys and values cannot be empty');
        break;
      }
    }

    // Validate that required fields are not in excluded fields
    final conflictingFields =
        requiredFields.where((field) => excludedFields.contains(field));
    if (conflictingFields.isNotEmpty) {
      errors.add(
          'Fields cannot be both required and excluded: ${conflictingFields.join(', ')}');
    }

    return errors;
  }

  /// Checks if this configuration is valid
  bool get isValid => validate().isEmpty;

  @override
  String toString() {
    return 'SyncEntityConfig(tableName: $tableName, requiresAuthentication: $requiresAuthentication)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncEntityConfig &&
        other.tableName == tableName &&
        other.requiresAuthentication == requiresAuthentication;
  }

  @override
  int get hashCode => Object.hash(tableName, requiresAuthentication);
}

/// Registry for managing entity configurations
///
/// This class provides a centralized way to register and manage
/// sync configurations for different entities in the application.
class SyncEntityRegistry {
  final Map<String, SyncEntityConfig> _entities = {};

  /// Register a new entity configuration
  void register(String entityName, SyncEntityConfig config) {
    _entities[entityName] = config;
  }

  /// Get configuration for an entity
  SyncEntityConfig? getConfig(String entityName) {
    return _entities[entityName];
  }

  /// Get all registered entity names
  List<String> get entityNames => _entities.keys.toList();

  /// Get all registered configurations
  Map<String, SyncEntityConfig> get allConfigs => Map.unmodifiable(_entities);

  /// Remove an entity configuration
  void unregister(String entityName) {
    _entities.remove(entityName);
  }

  /// Clear all entity configurations
  void clear() {
    _entities.clear();
  }

  /// Get configurations that require authentication
  Map<String, SyncEntityConfig> get protectedEntities {
    return Map.fromEntries(
      _entities.entries.where((entry) => entry.value.requiresAuthentication),
    );
  }

  /// Get configurations that don't require authentication
  Map<String, SyncEntityConfig> get publicEntities {
    return Map.fromEntries(
      _entities.entries.where((entry) => !entry.value.requiresAuthentication),
    );
  }

  /// Get configurations by priority level
  Map<String, SyncEntityConfig> getEntitiesByPriority(SyncPriority priority) {
    return Map.fromEntries(
      _entities.entries.where((entry) => entry.value.priority == priority),
    );
  }

  /// Get configurations that support real-time sync
  Map<String, SyncEntityConfig> get realTimeEntities {
    return Map.fromEntries(
      _entities.entries.where((entry) => entry.value.enableRealTime),
    );
  }

  /// Validate all registered configurations
  Map<String, List<String>> validateAll() {
    final validationResults = <String, List<String>>{};

    for (final entry in _entities.entries) {
      final errors = entry.value.validate();
      if (errors.isNotEmpty) {
        validationResults[entry.key] = errors;
      }
    }

    return validationResults;
  }

  /// Check if all configurations are valid
  bool get areAllValid => validateAll().isEmpty;

  /// Convert all configurations to JSON
  Map<String, dynamic> toJson() {
    return _entities.map((key, value) => MapEntry(key, value.toJson()));
  }

  /// Load configurations from JSON
  void fromJson(Map<String, dynamic> json) {
    _entities.clear();
    for (final entry in json.entries) {
      _entities[entry.key] =
          SyncEntityConfig.fromJson(entry.value as Map<String, dynamic>);
    }
  }
}
