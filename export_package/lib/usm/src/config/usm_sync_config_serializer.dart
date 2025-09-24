import 'dart:convert';
import 'dart:io';

import 'usm_universal_sync_config.dart';
import 'usm_sync_entity_config.dart';
import 'usm_sync_config_validator.dart';
import 'usm_sync_enums.dart';

/// Configuration serialization and persistence system for Universal Sync Manager
///
/// This class provides comprehensive serialization, deserialization, and
/// persistence capabilities for USM configurations with support for JSON,
/// migration, and validation.
///
/// Following USM naming conventions:
/// - File: usm_sync_config_serializer.dart (snake_case with usm_ prefix)
/// - Class: SyncConfigSerializer (PascalCase)
class SyncConfigSerializer {
  /// Current configuration format version
  static const int currentVersion = 1;

  /// Private constructor to prevent instantiation
  const SyncConfigSerializer._();

  /// Serializes a complete sync configuration to JSON
  static Map<String, dynamic> serializeSyncSystem({
    required UniversalSyncConfig universalConfig,
    required SyncEntityRegistry entityRegistry,
    Map<String, dynamic>? metadata,
  }) {
    return {
      'version': currentVersion,
      'timestamp': DateTime.now().toIso8601String(),
      'universalConfig': universalConfig.toJson(),
      'entityRegistry': entityRegistry.toJson(),
      'metadata': metadata ?? {},
    };
  }

  /// Deserializes a complete sync configuration from JSON
  static SyncSystemConfig deserializeSyncSystem(Map<String, dynamic> json) {
    final version = json['version'] as int? ?? 1;

    // Handle version migrations if needed
    final migratedJson = _migrateConfiguration(json, version);

    final universalConfig = UniversalSyncConfig.fromJson(
      migratedJson['universalConfig'] as Map<String, dynamic>,
    );

    final entityRegistry = SyncEntityRegistry();
    entityRegistry
        .fromJson(migratedJson['entityRegistry'] as Map<String, dynamic>);

    return SyncSystemConfig(
      universalConfig: universalConfig,
      entityRegistry: entityRegistry,
      version: version,
      timestamp:
          DateTime.tryParse(migratedJson['timestamp'] as String? ?? '') ??
              DateTime.now(),
      metadata:
          Map<String, dynamic>.from(migratedJson['metadata'] as Map? ?? {}),
    );
  }

  /// Saves configuration to a JSON file
  static Future<void> saveToFile({
    required String filePath,
    required UniversalSyncConfig universalConfig,
    required SyncEntityRegistry entityRegistry,
    Map<String, dynamic>? metadata,
    bool validateBeforeSave = true,
    bool createBackup = true,
  }) async {
    // Validate configuration before saving
    if (validateBeforeSave) {
      final validationResult = SyncConfigValidator.validateSyncSystem(
        universalConfig,
        entityRegistry,
      );

      if (!validationResult.isValid) {
        throw SyncConfigSerializationException(
          'Configuration validation failed',
          details: validationResult.toString(),
        );
      }
    }

    final file = File(filePath);

    // Create backup if requested and file exists
    if (createBackup && await file.exists()) {
      final backupPath =
          '$filePath.backup.${DateTime.now().millisecondsSinceEpoch}';
      await file.copy(backupPath);
    }

    // Ensure directory exists
    await file.parent.create(recursive: true);

    // Serialize configuration
    final configJson = serializeSyncSystem(
      universalConfig: universalConfig,
      entityRegistry: entityRegistry,
      metadata: metadata,
    );

    // Write to file with pretty formatting
    final jsonString = JsonEncoder.withIndent('  ').convert(configJson);
    await file.writeAsString(jsonString);
  }

  /// Loads configuration from a JSON file
  static Future<SyncSystemConfig> loadFromFile({
    required String filePath,
    bool validateAfterLoad = true,
  }) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw SyncConfigSerializationException(
        'Configuration file not found: $filePath',
      );
    }

    try {
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      final config = deserializeSyncSystem(jsonData);

      // Validate configuration after loading
      if (validateAfterLoad) {
        final validationResult = SyncConfigValidator.validateSyncSystem(
          config.universalConfig,
          config.entityRegistry,
        );

        if (!validationResult.isValid) {
          throw SyncConfigSerializationException(
            'Loaded configuration is invalid',
            details: validationResult.toString(),
          );
        }
      }

      return config;
    } catch (e) {
      if (e is SyncConfigSerializationException) {
        rethrow;
      }

      throw SyncConfigSerializationException(
        'Failed to load configuration from file',
        cause: e,
      );
    }
  }

  /// Exports configuration to a formatted JSON string
  static String exportToJsonString({
    required UniversalSyncConfig universalConfig,
    required SyncEntityRegistry entityRegistry,
    Map<String, dynamic>? metadata,
    bool prettyFormat = true,
  }) {
    final configJson = serializeSyncSystem(
      universalConfig: universalConfig,
      entityRegistry: entityRegistry,
      metadata: metadata,
    );

    if (prettyFormat) {
      return JsonEncoder.withIndent('  ').convert(configJson);
    } else {
      return jsonEncode(configJson);
    }
  }

  /// Imports configuration from a JSON string
  static SyncSystemConfig importFromJsonString(String jsonString) {
    try {
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      return deserializeSyncSystem(jsonData);
    } catch (e) {
      throw SyncConfigSerializationException(
        'Failed to import configuration from JSON string',
        cause: e,
      );
    }
  }

  /// Creates a configuration template with common settings
  static SyncSystemConfig createTemplate({
    required String projectId,
    SyncEnvironment environment = SyncEnvironment.development,
    List<String> entityNames = const [],
  }) {
    final universalConfig = UniversalSyncConfig(
      projectId: projectId,
      environment: environment,
      syncMode: environment == SyncEnvironment.production
          ? SyncMode.automatic
          : SyncMode.manual,
      enableAnalytics: environment == SyncEnvironment.production,
      enablePerformanceMonitoring: environment != SyncEnvironment.testing,
    );

    final entityRegistry = SyncEntityRegistry();

    // Add template entities
    for (final entityName in entityNames) {
      entityRegistry.register(
        entityName,
        SyncEntityConfig(
          tableName: entityName,
          requiresAuthentication: true,
        ),
      );
    }

    return SyncSystemConfig(
      universalConfig: universalConfig,
      entityRegistry: entityRegistry,
      version: currentVersion,
      timestamp: DateTime.now(),
      metadata: {
        'createdBy': 'SyncConfigSerializer.createTemplate',
        'description': 'Template configuration for $projectId',
      },
    );
  }

  /// Merges two configurations, with the second taking precedence
  static SyncSystemConfig mergeConfigurations(
    SyncSystemConfig baseConfig,
    SyncSystemConfig overrideConfig,
  ) {
    // Merge universal configurations
    final mergedUniversalConfig = _mergeUniversalConfigs(
      baseConfig.universalConfig,
      overrideConfig.universalConfig,
    );

    // Merge entity registries
    final mergedEntityRegistry = _mergeEntityRegistries(
      baseConfig.entityRegistry,
      overrideConfig.entityRegistry,
    );

    // Merge metadata
    final mergedMetadata = Map<String, dynamic>.from(baseConfig.metadata);
    mergedMetadata.addAll(overrideConfig.metadata);
    mergedMetadata['mergedAt'] = DateTime.now().toIso8601String();

    return SyncSystemConfig(
      universalConfig: mergedUniversalConfig,
      entityRegistry: mergedEntityRegistry,
      version: currentVersion,
      timestamp: DateTime.now(),
      metadata: mergedMetadata,
    );
  }

  /// Applies configuration overrides to a base configuration
  static SyncSystemConfig applyOverrides(
    SyncSystemConfig baseConfig,
    Map<String, dynamic> overrides,
  ) {
    final configJson = baseConfig.toJson();

    // Apply overrides recursively
    _applyOverridesRecursive(configJson, overrides);

    return deserializeSyncSystem(configJson);
  }

  /// Validates configuration file format
  static Future<SyncConfigFileValidationResult> validateConfigFile(
      String filePath) async {
    final file = File(filePath);
    final errors = <String>[];
    final warnings = <String>[];

    // Check if file exists
    if (!await file.exists()) {
      errors.add('Configuration file does not exist: $filePath');
      return SyncConfigFileValidationResult(
        isValid: false,
        errors: errors,
        warnings: warnings,
      );
    }

    try {
      // Check if file is readable
      final jsonString = await file.readAsString();

      // Check if valid JSON
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Check version
      final version = jsonData['version'] as int?;
      if (version == null) {
        warnings.add('Configuration missing version field');
      } else if (version > currentVersion) {
        warnings.add(
            'Configuration version ($version) is newer than supported ($currentVersion)');
      }

      // Check required fields
      if (!jsonData.containsKey('universalConfig')) {
        errors.add('Missing required field: universalConfig');
      }

      if (!jsonData.containsKey('entityRegistry')) {
        errors.add('Missing required field: entityRegistry');
      }

      // Try to deserialize
      if (errors.isEmpty) {
        final config = deserializeSyncSystem(jsonData);

        // Validate the configuration itself
        final validationResult = SyncConfigValidator.validateSyncSystem(
          config.universalConfig,
          config.entityRegistry,
        );

        if (!validationResult.isValid) {
          errors.add('Configuration content is invalid');
        }

        if (validationResult.hasWarnings) {
          warnings.add('Configuration has validation warnings');
        }
      }
    } catch (e) {
      errors.add('Failed to parse configuration file: $e');
    }

    return SyncConfigFileValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Migrates configuration from older versions
  static Map<String, dynamic> _migrateConfiguration(
    Map<String, dynamic> json,
    int fromVersion,
  ) {
    final migratedJson = Map<String, dynamic>.from(json);

    // Apply migrations in sequence
    for (int version = fromVersion; version < currentVersion; version++) {
      _applyMigration(migratedJson, version, version + 1);
    }

    migratedJson['version'] = currentVersion;
    return migratedJson;
  }

  /// Applies a specific version migration
  static void _applyMigration(
    Map<String, dynamic> json,
    int fromVersion,
    int toVersion,
  ) {
    // Future migration logic would go here
    // For now, we only have version 1, so no migrations needed
    switch (fromVersion) {
      case 1:
        // Example: if migrating from v1 to v2
        // _migrateFromV1ToV2(json);
        break;
      default:
        // No migration needed
        break;
    }
  }

  /// Merges two universal configurations
  static UniversalSyncConfig _mergeUniversalConfigs(
    UniversalSyncConfig base,
    UniversalSyncConfig override,
  ) {
    // Use copyWith to merge configurations
    // Override takes precedence for all non-null values
    return base.copyWith(
      projectId: override.projectId,
      syncMode: override.syncMode,
      syncInterval: override.syncInterval,
      defaultConflictStrategy: override.defaultConflictStrategy,
      maxRetries: override.maxRetries,
      retryDelay: override.retryDelay,
      retryStrategy: override.retryStrategy,
      enableCompression: override.enableCompression,
      compressionType: override.compressionType,
      enableDeltaSync: override.enableDeltaSync,
      defaultPriority: override.defaultPriority,
      backendConfig: {...base.backendConfig, ...override.backendConfig},
      platformOptimizations: override.platformOptimizations,
      publicEntities: override.publicEntities,
      protectedEntities: override.protectedEntities,
      maxBatchSize: override.maxBatchSize,
      operationTimeout: override.operationTimeout,
      connectionTimeout: override.connectionTimeout,
      enableRealTimeSync: override.enableRealTimeSync,
      maxConcurrentOperations: override.maxConcurrentOperations,
      environment: override.environment,
      logLevel: override.logLevel,
      enablePerformanceMonitoring: override.enablePerformanceMonitoring,
      enableAnalytics: override.enableAnalytics,
      customSettings: {...base.customSettings, ...override.customSettings},
      networkSettings: override.networkSettings,
      securitySettings: override.securitySettings,
      offlineSettings: override.offlineSettings,
    );
  }

  /// Merges two entity registries
  static SyncEntityRegistry _mergeEntityRegistries(
    SyncEntityRegistry base,
    SyncEntityRegistry override,
  ) {
    final merged = SyncEntityRegistry();

    // Add all entities from base
    for (final entry in base.allConfigs.entries) {
      merged.register(entry.key, entry.value);
    }

    // Override with entities from override registry
    for (final entry in override.allConfigs.entries) {
      merged.register(entry.key, entry.value);
    }

    return merged;
  }

  /// Recursively applies overrides to a JSON object
  static void _applyOverridesRecursive(
    Map<String, dynamic> target,
    Map<String, dynamic> overrides,
  ) {
    for (final entry in overrides.entries) {
      if (entry.value is Map<String, dynamic> &&
          target[entry.key] is Map<String, dynamic>) {
        _applyOverridesRecursive(
          target[entry.key] as Map<String, dynamic>,
          entry.value as Map<String, dynamic>,
        );
      } else {
        target[entry.key] = entry.value;
      }
    }
  }
}

/// Container class for a complete sync system configuration
class SyncSystemConfig {
  const SyncSystemConfig({
    required this.universalConfig,
    required this.entityRegistry,
    required this.version,
    required this.timestamp,
    this.metadata = const {},
  });

  final UniversalSyncConfig universalConfig;
  final SyncEntityRegistry entityRegistry;
  final int version;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  /// Converts this configuration to JSON
  Map<String, dynamic> toJson() {
    return SyncConfigSerializer.serializeSyncSystem(
      universalConfig: universalConfig,
      entityRegistry: entityRegistry,
      metadata: metadata,
    );
  }

  /// Creates a copy with specified overrides
  SyncSystemConfig copyWith({
    UniversalSyncConfig? universalConfig,
    SyncEntityRegistry? entityRegistry,
    int? version,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return SyncSystemConfig(
      universalConfig: universalConfig ?? this.universalConfig,
      entityRegistry: entityRegistry ?? this.entityRegistry,
      version: version ?? this.version,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'SyncSystemConfig(projectId: ${universalConfig.projectId}, '
        'version: $version, entities: ${entityRegistry.entityNames.length})';
  }
}

/// Validation result for configuration files
class SyncConfigFileValidationResult {
  const SyncConfigFileValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln(
        'Configuration File Validation: ${isValid ? 'VALID' : 'INVALID'}');

    if (errors.isNotEmpty) {
      buffer.writeln('Errors:');
      for (final error in errors) {
        buffer.writeln('  - $error');
      }
    }

    if (warnings.isNotEmpty) {
      buffer.writeln('Warnings:');
      for (final warning in warnings) {
        buffer.writeln('  - $warning');
      }
    }

    return buffer.toString();
  }
}

/// Exception thrown during configuration serialization/deserialization
class SyncConfigSerializationException implements Exception {
  const SyncConfigSerializationException(
    this.message, {
    this.cause,
    this.details,
  });

  final String message;
  final Object? cause;
  final String? details;

  @override
  String toString() {
    final buffer = StringBuffer('SyncConfigSerializationException: $message');

    if (details != null) {
      buffer.writeln('\nDetails: $details');
    }

    if (cause != null) {
      buffer.writeln('\nCaused by: $cause');
    }

    return buffer.toString();
  }
}
