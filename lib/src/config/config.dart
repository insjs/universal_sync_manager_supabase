/// Universal Sync Manager Configuration System
///
/// This library provides comprehensive configuration management for the
/// Universal Sync Manager, including configuration classes, validation,
/// serialization, and entity management.
///
/// ## Core Components
///
/// ### Configuration Classes
/// - [UniversalSyncConfig] - Main configuration for the sync system
/// - [SyncEntityConfig] - Entity-specific configuration settings
/// - [SyncEntityRegistry] - Registry for managing entity configurations
///
/// ### Validation System
/// - [SyncConfigValidator] - Validates configurations for correctness
/// - [SyncConfigValidationResult] - Results of configuration validation
/// - [SyncEntityConfigValidationResult] - Results of entity validation
/// - [SyncSystemValidationResult] - Results of complete system validation
///
/// ### Serialization System
/// - [SyncConfigSerializer] - Handles configuration serialization/persistence
/// - [SyncSystemConfig] - Container for complete system configuration
/// - [SyncConfigSerializationException] - Exceptions during serialization
///
/// ### Enumerations
/// - [SyncMode] - How the sync manager operates
/// - [SyncDirection] - Direction of data flow during sync
/// - [SyncFrequency] - Frequency of automatic sync operations
/// - [SyncPriority] - Priority levels for sync operations
/// - [SyncStrategy] - Strategies for handling data synchronization
/// - [ConflictResolutionStrategy] - Strategies for resolving conflicts
/// - [SyncEnvironment] - Environment types (development, production, etc.)
/// - [SecurityLevel] - Security levels for data protection
/// - [NetworkCondition] - Network quality levels
/// - [CompressionType] - Compression algorithms for payloads
/// - [RetryStrategy] - Retry strategies for failed operations
/// - [LogLevel] - Logging verbosity levels
///
/// ## Usage Examples
///
/// ### Basic Configuration Setup
/// ```dart
/// import 'package:universal_sync_manager/config.dart';
///
/// // Create universal configuration
/// final universalConfig = UniversalSyncConfig(
///   projectId: 'my-app',
///   syncMode: SyncMode.automatic,
///   environment: SyncEnvironment.production,
/// );
///
/// // Create entity registry
/// final entityRegistry = SyncEntityRegistry();
///
/// // Register entities
/// entityRegistry.register('users', SyncEntityConfig.protected(
///   tableName: 'users',
///   priority: SyncPriority.high,
/// ));
///
/// entityRegistry.register('posts', SyncEntityConfig.public(
///   tableName: 'posts',
///   syncDirection: SyncDirection.downloadOnly,
/// ));
/// ```
///
/// ### Configuration Validation
/// ```dart
/// // Validate complete system
/// final validationResult = SyncConfigValidator.validateSyncSystem(
///   universalConfig,
///   entityRegistry,
/// );
///
/// if (!validationResult.isValid) {
///   print('Configuration errors found:');
///   for (final error in validationResult.systemErrors) {
///     print('  - $error');
///   }
/// }
/// ```
///
/// ### Configuration Persistence
/// ```dart
/// // Save configuration to file
/// await SyncConfigSerializer.saveToFile(
///   filePath: 'config/sync_config.json',
///   universalConfig: universalConfig,
///   entityRegistry: entityRegistry,
/// );
///
/// // Load configuration from file
/// final loadedConfig = await SyncConfigSerializer.loadFromFile(
///   filePath: 'config/sync_config.json',
/// );
/// ```
///
/// ### Factory Methods for Common Scenarios
/// ```dart
/// // Development configuration
/// final devConfig = UniversalSyncConfig.development(
///   projectId: 'my-app-dev',
/// );
///
/// // Production configuration
/// final prodConfig = UniversalSyncConfig.production(
///   projectId: 'my-app-prod',
/// );
///
/// // High-priority entity
/// final criticalEntity = SyncEntityConfig.highPriority(
///   tableName: 'critical_data',
///   requiresAuthentication: true,
/// );
///
/// // Read-only entity
/// final readOnlyEntity = SyncEntityConfig.readOnly(
///   tableName: 'reference_data',
///   cacheExpiration: Duration(hours: 24),
/// );
/// ```
///
/// ## Best Practices
///
/// 1. **Always validate** configurations before using them in production
/// 2. **Use factory methods** for common configuration patterns
/// 3. **Separate environments** with different configuration files
/// 4. **Regular validation** of loaded configurations
/// 5. **Backup configurations** before making changes
/// 6. **Use meaningful entity names** that follow snake_case convention
/// 7. **Set appropriate security levels** based on data sensitivity
/// 8. **Consider performance implications** of real-time sync for many entities
///
/// ## Architecture Notes
///
/// The configuration system follows these architectural principles:
/// - **Immutable configurations** - use copyWith() for modifications
/// - **Comprehensive validation** - catch issues early with detailed feedback
/// - **Flexible serialization** - JSON-based with migration support
/// - **Environment-aware** - different defaults for dev/test/prod
/// - **Entity-centric** - per-table configuration with sensible defaults
/// - **Security-conscious** - encryption and authentication settings
/// - **Performance-optimized** - compression, batching, and caching options
///
library;

// Core configuration classes
export 'usm_universal_sync_config.dart';
export 'usm_sync_entity_config.dart';

// Enumerations
export 'usm_sync_enums.dart';

// Validation system
export 'usm_sync_config_validator.dart';

// Serialization system
export 'usm_sync_config_serializer.dart';
