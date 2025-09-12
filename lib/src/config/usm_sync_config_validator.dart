import 'usm_universal_sync_config.dart';
import 'usm_sync_entity_config.dart';
import 'usm_sync_enums.dart';

/// Configuration validation system for Universal Sync Manager
///
/// This class provides comprehensive validation for all USM configuration
/// components to ensure they are properly configured before use.
///
/// Following USM naming conventions:
/// - File: usm_sync_config_validator.dart (snake_case with usm_ prefix)
/// - Class: SyncConfigValidator (PascalCase)
class SyncConfigValidator {
  /// Private constructor to prevent instantiation
  const SyncConfigValidator._();

  /// Validates a UniversalSyncConfig and returns validation results
  static SyncConfigValidationResult validateUniversalConfig(
      UniversalSyncConfig config) {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];

    // Validate project ID
    if (config.projectId.isEmpty) {
      errors.add(ValidationError(
        field: 'projectId',
        message: 'Project ID cannot be empty',
        severity: ValidationSeverity.error,
      ));
    } else if (config.projectId.length < 3) {
      warnings.add(ValidationWarning(
        field: 'projectId',
        message: 'Project ID should be at least 3 characters long',
      ));
    }

    // Validate sync interval
    if (config.syncInterval.inSeconds < 1) {
      errors.add(ValidationError(
        field: 'syncInterval',
        message: 'Sync interval must be at least 1 second',
        severity: ValidationSeverity.error,
      ));
    } else if (config.syncInterval.inSeconds < 10 &&
        config.syncMode == SyncMode.automatic) {
      warnings.add(ValidationWarning(
        field: 'syncInterval',
        message:
            'Very short sync intervals may impact performance in automatic mode',
      ));
    }

    // Validate retry configuration
    if (config.maxRetries < 0) {
      errors.add(ValidationError(
        field: 'maxRetries',
        message: 'Max retries cannot be negative',
        severity: ValidationSeverity.error,
      ));
    } else if (config.maxRetries > 10) {
      warnings.add(ValidationWarning(
        field: 'maxRetries',
        message: 'Very high retry counts may cause delays in error scenarios',
      ));
    }

    if (config.retryDelay.inSeconds < 1) {
      errors.add(ValidationError(
        field: 'retryDelay',
        message: 'Retry delay must be at least 1 second',
        severity: ValidationSeverity.error,
      ));
    }

    // Validate batch size
    if (config.maxBatchSize < 1) {
      errors.add(ValidationError(
        field: 'maxBatchSize',
        message: 'Max batch size must be at least 1',
        severity: ValidationSeverity.error,
      ));
    } else if (config.maxBatchSize > 1000) {
      warnings.add(ValidationWarning(
        field: 'maxBatchSize',
        message: 'Very large batch sizes may cause memory issues',
      ));
    }

    // Validate timeouts
    if (config.operationTimeout.inSeconds < 1) {
      errors.add(ValidationError(
        field: 'operationTimeout',
        message: 'Operation timeout must be at least 1 second',
        severity: ValidationSeverity.error,
      ));
    }

    if (config.connectionTimeout.inSeconds < 1) {
      errors.add(ValidationError(
        field: 'connectionTimeout',
        message: 'Connection timeout must be at least 1 second',
        severity: ValidationSeverity.error,
      ));
    }

    if (config.connectionTimeout > config.operationTimeout) {
      warnings.add(ValidationWarning(
        field: 'connectionTimeout',
        message: 'Connection timeout is longer than operation timeout',
      ));
    }

    // Validate concurrent operations
    if (config.maxConcurrentOperations < 1) {
      errors.add(ValidationError(
        field: 'maxConcurrentOperations',
        message: 'Max concurrent operations must be at least 1',
        severity: ValidationSeverity.error,
      ));
    } else if (config.maxConcurrentOperations > 20) {
      warnings.add(ValidationWarning(
        field: 'maxConcurrentOperations',
        message: 'Very high concurrency may overwhelm backend services',
      ));
    }

    // Validate environment-specific settings
    _validateEnvironmentSettings(config, errors, warnings);

    // Validate network settings
    _validateNetworkSettings(config.networkSettings, errors, warnings);

    // Validate security settings
    _validateSecuritySettings(config.securitySettings, errors, warnings);

    // Validate offline settings
    _validateOfflineSettings(config.offlineSettings, errors, warnings);

    // Validate platform optimizations
    _validatePlatformOptimizations(
        config.platformOptimizations, errors, warnings);

    return SyncConfigValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validates a SyncEntityConfig and returns validation results
  static SyncEntityConfigValidationResult validateEntityConfig(
    String entityName,
    SyncEntityConfig config,
  ) {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];

    // Validate entity name
    if (entityName.isEmpty) {
      errors.add(ValidationError(
        field: 'entityName',
        message: 'Entity name cannot be empty',
        severity: ValidationSeverity.error,
      ));
    }

    // Validate table name
    if (config.tableName.isEmpty) {
      errors.add(ValidationError(
        field: 'tableName',
        message: 'Table name cannot be empty',
        severity: ValidationSeverity.error,
      ));
    } else if (!_isValidTableName(config.tableName)) {
      warnings.add(ValidationWarning(
        field: 'tableName',
        message: 'Table name should follow snake_case convention',
      ));
    }

    // Validate batch size
    if (config.maxBatchSize != null && config.maxBatchSize! < 1) {
      errors.add(ValidationError(
        field: 'maxBatchSize',
        message: 'Max batch size must be at least 1',
        severity: ValidationSeverity.error,
      ));
    }

    // Validate sync interval
    if (config.syncInterval != null && config.syncInterval!.inSeconds < 1) {
      errors.add(ValidationError(
        field: 'syncInterval',
        message: 'Sync interval must be at least 1 second',
        severity: ValidationSeverity.error,
      ));
    }

    // Validate max data age
    if (config.maxDataAge != null && config.maxDataAge!.inSeconds < 1) {
      errors.add(ValidationError(
        field: 'maxDataAge',
        message: 'Max data age must be at least 1 second',
        severity: ValidationSeverity.error,
      ));
    }

    // Validate cache expiration
    if (config.cacheExpiration != null &&
        config.cacheExpiration!.inSeconds < 1) {
      errors.add(ValidationError(
        field: 'cacheExpiration',
        message: 'Cache expiration must be at least 1 second',
        severity: ValidationSeverity.error,
      ));
    }

    // Validate field mappings
    for (final mapping in config.fieldMappings.entries) {
      if (mapping.key.isEmpty || mapping.value.isEmpty) {
        errors.add(ValidationError(
          field: 'fieldMappings',
          message: 'Field mapping keys and values cannot be empty',
          severity: ValidationSeverity.error,
        ));
        break;
      }
    }

    // Validate field conflicts
    final conflictingFields = config.requiredFields
        .where((field) => config.excludedFields.contains(field));
    if (conflictingFields.isNotEmpty) {
      errors.add(ValidationError(
        field: 'requiredFields/excludedFields',
        message:
            'Fields cannot be both required and excluded: ${conflictingFields.join(', ')}',
        severity: ValidationSeverity.error,
      ));
    }

    // Validate security settings
    if (config.requiresAuthentication &&
        config.securityLevel == SecurityLevel.public) {
      warnings.add(ValidationWarning(
        field: 'securityLevel',
        message: 'Entity requires authentication but has public security level',
      ));
    }

    if (config.enableEncryption &&
        config.securityLevel == SecurityLevel.public) {
      warnings.add(ValidationWarning(
        field: 'enableEncryption',
        message: 'Encryption enabled for public security level entity',
      ));
    }

    // Validate sync direction with real-time
    if (config.syncDirection == SyncDirection.downloadOnly &&
        config.enableRealTime) {
      warnings.add(ValidationWarning(
        field: 'enableRealTime',
        message: 'Real-time sync may not be needed for download-only entities',
      ));
    }

    // Validate caching with real-time
    if (config.enableCaching && config.enableRealTime) {
      warnings.add(ValidationWarning(
        field: 'enableCaching',
        message: 'Caching may conflict with real-time updates',
      ));
    }

    return SyncEntityConfigValidationResult(
      entityName: entityName,
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validates multiple entity configurations
  static SyncEntityRegistryValidationResult validateEntityRegistry(
      SyncEntityRegistry registry) {
    final results = <String, SyncEntityConfigValidationResult>{};
    final globalErrors = <ValidationError>[];
    final globalWarnings = <ValidationWarning>[];

    // Validate individual configurations
    for (final entityName in registry.entityNames) {
      final config = registry.getConfig(entityName)!;
      results[entityName] = validateEntityConfig(entityName, config);
    }

    // Check for duplicate table names
    final tableNames = <String, List<String>>{};
    for (final entry in registry.allConfigs.entries) {
      final tableName = entry.value.tableName;
      tableNames.putIfAbsent(tableName, () => []).add(entry.key);
    }

    for (final entry in tableNames.entries) {
      if (entry.value.length > 1) {
        globalErrors.add(ValidationError(
          field: 'tableName',
          message:
              'Duplicate table name "${entry.key}" used by entities: ${entry.value.join(', ')}',
          severity: ValidationSeverity.error,
        ));
      }
    }

    // Check for conflicting configurations
    final realTimeEntities = registry.realTimeEntities;
    if (realTimeEntities.length > 10) {
      globalWarnings.add(ValidationWarning(
        field: 'realTimeEntities',
        message: 'Large number of real-time entities may impact performance',
      ));
    }

    return SyncEntityRegistryValidationResult(
      isValid: globalErrors.isEmpty && results.values.every((r) => r.isValid),
      entityResults: results,
      globalErrors: globalErrors,
      globalWarnings: globalWarnings,
    );
  }

  /// Validates complete sync system configuration
  static SyncSystemValidationResult validateSyncSystem(
    UniversalSyncConfig universalConfig,
    SyncEntityRegistry entityRegistry,
  ) {
    final universalResult = validateUniversalConfig(universalConfig);
    final registryResult = validateEntityRegistry(entityRegistry);
    final systemErrors = <ValidationError>[];
    final systemWarnings = <ValidationWarning>[];

    // Cross-validate universal config with entity configs
    final protectedEntities = entityRegistry.protectedEntities;
    final publicEntities = entityRegistry.publicEntities;

    // Check if protected entities are in the right lists
    for (final entityName in protectedEntities.keys) {
      if (universalConfig.publicEntities.contains(entityName)) {
        systemErrors.add(ValidationError(
          field: 'publicEntities',
          message:
              'Entity "$entityName" requires authentication but is listed as public',
          severity: ValidationSeverity.error,
        ));
      }
    }

    for (final entityName in publicEntities.keys) {
      if (universalConfig.protectedEntities.contains(entityName)) {
        systemErrors.add(ValidationError(
          field: 'protectedEntities',
          message:
              'Entity "$entityName" does not require authentication but is listed as protected',
          severity: ValidationSeverity.error,
        ));
      }
    }

    // Check if real-time is enabled globally but entities don't support it
    if (universalConfig.enableRealTimeSync) {
      final nonRealTimeEntities = entityRegistry.allConfigs.entries
          .where((entry) => !entry.value.enableRealTime)
          .map((entry) => entry.key)
          .toList();

      if (nonRealTimeEntities.isNotEmpty) {
        systemWarnings.add(ValidationWarning(
          field: 'enableRealTimeSync',
          message:
              'Real-time sync enabled globally but some entities do not support it: ${nonRealTimeEntities.join(', ')}',
        ));
      }
    }

    // Check for performance implications
    if (universalConfig.syncMode == SyncMode.realtime &&
        entityRegistry.entityNames.length > 20) {
      systemWarnings.add(ValidationWarning(
        field: 'syncMode',
        message:
            'Real-time sync mode with many entities may impact performance',
      ));
    }

    return SyncSystemValidationResult(
      isValid: universalResult.isValid &&
          registryResult.isValid &&
          systemErrors.isEmpty,
      universalConfigResult: universalResult,
      entityRegistryResult: registryResult,
      systemErrors: systemErrors,
      systemWarnings: systemWarnings,
    );
  }

  /// Helper method to validate environment-specific settings
  static void _validateEnvironmentSettings(
    UniversalSyncConfig config,
    List<ValidationError> errors,
    List<ValidationWarning> warnings,
  ) {
    switch (config.environment) {
      case SyncEnvironment.production:
        if (config.backendConfig.isEmpty) {
          errors.add(ValidationError(
            field: 'backendConfig',
            message:
                'Backend configuration required for production environment',
            severity: ValidationSeverity.error,
          ));
        }

        if (config.logLevel == LogLevel.debug ||
            config.logLevel == LogLevel.verbose) {
          warnings.add(ValidationWarning(
            field: 'logLevel',
            message: 'Debug logging not recommended for production',
          ));
        }

        if (!config.enableAnalytics) {
          warnings.add(ValidationWarning(
            field: 'enableAnalytics',
            message: 'Analytics recommended for production monitoring',
          ));
        }
        break;

      case SyncEnvironment.development:
        if (config.maxRetries > 3) {
          warnings.add(ValidationWarning(
            field: 'maxRetries',
            message: 'High retry counts may slow development feedback',
          ));
        }
        break;

      case SyncEnvironment.testing:
        if (config.enableAnalytics) {
          warnings.add(ValidationWarning(
            field: 'enableAnalytics',
            message: 'Analytics not typically needed in testing environment',
          ));
        }
        break;

      case SyncEnvironment.staging:
        // Staging-specific validations can be added here
        break;
    }
  }

  /// Helper method to validate network settings
  static void _validateNetworkSettings(
    NetworkSettings settings,
    List<ValidationError> errors,
    List<ValidationWarning> warnings,
  ) {
    if (settings.requestTimeout.inSeconds < 1) {
      errors.add(ValidationError(
        field: 'networkSettings.requestTimeout',
        message: 'Request timeout must be at least 1 second',
        severity: ValidationSeverity.error,
      ));
    }

    if (settings.maxBandwidthKBps < 1) {
      errors.add(ValidationError(
        field: 'networkSettings.maxBandwidthKBps',
        message: 'Max bandwidth must be at least 1 KB/s',
        severity: ValidationSeverity.error,
      ));
    }

    if (!settings.allowCellularSync &&
        settings.minNetworkQuality == NetworkCondition.limited) {
      warnings.add(ValidationWarning(
        field: 'networkSettings.allowCellularSync',
        message:
            'Cellular sync disabled but accepting limited network conditions',
      ));
    }
  }

  /// Helper method to validate security settings
  static void _validateSecuritySettings(
    SecuritySettings settings,
    List<ValidationError> errors,
    List<ValidationWarning> warnings,
  ) {
    if (settings.defaultSecurityLevel == SecurityLevel.restricted &&
        !settings.enableEncryption) {
      warnings.add(ValidationWarning(
        field: 'securitySettings.enableEncryption',
        message: 'Encryption recommended for restricted security level',
      ));
    }

    if (!settings.validateSSLCertificates) {
      warnings.add(ValidationWarning(
        field: 'securitySettings.validateSSLCertificates',
        message: 'SSL certificate validation disabled - security risk',
      ));
    }
  }

  /// Helper method to validate offline settings
  static void _validateOfflineSettings(
    OfflineSettings settings,
    List<ValidationError> errors,
    List<ValidationWarning> warnings,
  ) {
    if (settings.maxOfflineTime.inSeconds < 1) {
      errors.add(ValidationError(
        field: 'offlineSettings.maxOfflineTime',
        message: 'Max offline time must be at least 1 second',
        severity: ValidationSeverity.error,
      ));
    }

    if (settings.maxOfflineOperations < 1) {
      errors.add(ValidationError(
        field: 'offlineSettings.maxOfflineOperations',
        message: 'Max offline operations must be at least 1',
        severity: ValidationSeverity.error,
      ));
    }

    if (settings.maxOfflineOperations > 10000) {
      warnings.add(ValidationWarning(
        field: 'offlineSettings.maxOfflineOperations',
        message: 'Very high offline operation limits may cause memory issues',
      ));
    }
  }

  /// Helper method to validate platform optimizations
  static void _validatePlatformOptimizations(
    PlatformOptimizations optimizations,
    List<ValidationError> errors,
    List<ValidationWarning> warnings,
  ) {
    if (optimizations.maxCacheMemoryMB < 1) {
      errors.add(ValidationError(
        field: 'platformOptimizations.maxCacheMemoryMB',
        message: 'Max cache memory must be at least 1 MB',
        severity: ValidationSeverity.error,
      ));
    }

    if (optimizations.maxCacheMemoryMB > 1000) {
      warnings.add(ValidationWarning(
        field: 'platformOptimizations.maxCacheMemoryMB',
        message: 'Very high cache memory may impact device performance',
      ));
    }

    if (optimizations.wifiOnlySync && optimizations.enableBackgroundSync) {
      warnings.add(ValidationWarning(
        field: 'platformOptimizations.wifiOnlySync',
        message: 'WiFi-only sync may limit background sync effectiveness',
      ));
    }
  }

  /// Helper method to check if table name follows conventions
  static bool _isValidTableName(String tableName) {
    // Check if table name follows snake_case convention
    final snakeCaseRegex = RegExp(r'^[a-z][a-z0-9_]*[a-z0-9]$');
    return snakeCaseRegex.hasMatch(tableName);
  }
}

/// Validation severity levels
enum ValidationSeverity {
  /// Warning - configuration will work but may not be optimal
  warning,

  /// Error - configuration is invalid and will cause issues
  error,
}

/// Base class for validation issues
abstract class ValidationIssue {
  const ValidationIssue({
    required this.field,
    required this.message,
  });

  final String field;
  final String message;

  @override
  String toString() => '$field: $message';
}

/// Validation error class
class ValidationError extends ValidationIssue {
  const ValidationError({
    required super.field,
    required super.message,
    required this.severity,
  });

  final ValidationSeverity severity;

  @override
  String toString() => 'ERROR - ${super.toString()}';
}

/// Validation warning class
class ValidationWarning extends ValidationIssue {
  const ValidationWarning({
    required super.field,
    required super.message,
  });

  @override
  String toString() => 'WARNING - ${super.toString()}';
}

/// Validation result for UniversalSyncConfig
class SyncConfigValidationResult {
  const SyncConfigValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  final bool isValid;
  final List<ValidationError> errors;
  final List<ValidationWarning> warnings;

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln(
        'Universal Sync Config Validation: ${isValid ? 'VALID' : 'INVALID'}');

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

/// Validation result for SyncEntityConfig
class SyncEntityConfigValidationResult {
  const SyncEntityConfigValidationResult({
    required this.entityName,
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  final String entityName;
  final bool isValid;
  final List<ValidationError> errors;
  final List<ValidationWarning> warnings;

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln(
        'Entity "$entityName" Validation: ${isValid ? 'VALID' : 'INVALID'}');

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

/// Validation result for SyncEntityRegistry
class SyncEntityRegistryValidationResult {
  const SyncEntityRegistryValidationResult({
    required this.isValid,
    required this.entityResults,
    required this.globalErrors,
    required this.globalWarnings,
  });

  final bool isValid;
  final Map<String, SyncEntityConfigValidationResult> entityResults;
  final List<ValidationError> globalErrors;
  final List<ValidationWarning> globalWarnings;

  bool get hasWarnings =>
      globalWarnings.isNotEmpty ||
      entityResults.values.any((r) => r.hasWarnings);
  bool get hasErrors =>
      globalErrors.isNotEmpty || entityResults.values.any((r) => r.hasErrors);

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln(
        'Entity Registry Validation: ${isValid ? 'VALID' : 'INVALID'}');

    if (globalErrors.isNotEmpty) {
      buffer.writeln('Global Errors:');
      for (final error in globalErrors) {
        buffer.writeln('  - $error');
      }
    }

    if (globalWarnings.isNotEmpty) {
      buffer.writeln('Global Warnings:');
      for (final warning in globalWarnings) {
        buffer.writeln('  - $warning');
      }
    }

    for (final result in entityResults.values) {
      if (!result.isValid || result.hasWarnings) {
        buffer.writeln(result.toString());
      }
    }

    return buffer.toString();
  }
}

/// Validation result for complete sync system
class SyncSystemValidationResult {
  const SyncSystemValidationResult({
    required this.isValid,
    required this.universalConfigResult,
    required this.entityRegistryResult,
    required this.systemErrors,
    required this.systemWarnings,
  });

  final bool isValid;
  final SyncConfigValidationResult universalConfigResult;
  final SyncEntityRegistryValidationResult entityRegistryResult;
  final List<ValidationError> systemErrors;
  final List<ValidationWarning> systemWarnings;

  bool get hasWarnings =>
      systemWarnings.isNotEmpty ||
      universalConfigResult.hasWarnings ||
      entityRegistryResult.hasWarnings;

  bool get hasErrors =>
      systemErrors.isNotEmpty ||
      universalConfigResult.hasErrors ||
      entityRegistryResult.hasErrors;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Sync System Validation: ${isValid ? 'VALID' : 'INVALID'}');

    if (systemErrors.isNotEmpty) {
      buffer.writeln('System Errors:');
      for (final error in systemErrors) {
        buffer.writeln('  - $error');
      }
    }

    if (systemWarnings.isNotEmpty) {
      buffer.writeln('System Warnings:');
      for (final warning in systemWarnings) {
        buffer.writeln('  - $warning');
      }
    }

    buffer.writeln(universalConfigResult.toString());
    buffer.writeln(entityRegistryResult.toString());

    return buffer.toString();
  }
}
