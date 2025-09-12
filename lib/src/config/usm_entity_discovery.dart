import 'usm_sync_entity_config.dart';
import 'usm_sync_enums.dart';

/// Automatic entity discovery system for Universal Sync Manager
///
/// This class provides automatic discovery and registration of syncable
/// entities based on annotations, database schema, and naming conventions.
/// Uses a practical approach that works across all platforms without mirrors.
///
/// Following USM naming conventions:
/// - File: usm_entity_discovery.dart (snake_case with usm_ prefix)
/// - Class: SyncEntityDiscovery (PascalCase)
class SyncEntityDiscovery {
  /// Private constructor to prevent instantiation
  const SyncEntityDiscovery._();

  /// Discovers entities from a provided list of entity definitions
  static List<DiscoveredEntity> discoverFromDefinitions(
    List<EntityDefinition> entityDefinitions,
  ) {
    final discoveredEntities = <DiscoveredEntity>[];

    for (final definition in entityDefinitions) {
      final entity = DiscoveredEntity(
        entityName: definition.tableName,
        tableName: definition.tableName,
        className: definition.className,
        discoveryMethod: EntityDiscoveryMethod.manual,
        annotations: definition.annotations,
        fields: definition.fields,
        hasAuditFields: _hasAuditFieldsInClass(definition.fields),
        hasSyncFields: _hasSyncFieldsInClass(definition.fields),
        requiresAuthentication: definition.requiresAuthentication,
      );

      discoveredEntities.add(entity);
    }

    return discoveredEntities;
  }

  /// Discovers entities by scanning database schema
  static Future<List<DiscoveredEntity>> discoverFromDatabase(
    Future<List<TableInfo>> Function() getTableInfo,
  ) async {
    final discoveredEntities = <DiscoveredEntity>[];

    try {
      final tables = await getTableInfo();

      for (final table in tables) {
        // Skip system tables
        if (_isSystemTable(table.name)) {
          continue;
        }

        final entity = DiscoveredEntity(
          entityName: table.name,
          tableName: table.name,
          className: _tableNameToClassName(table.name),
          discoveryMethod: EntityDiscoveryMethod.database,
          fields: table.columns
              .map((col) => FieldInfo(
                    name: col.name,
                    type: col.type,
                    isNullable: col.isNullable,
                    isPrimaryKey: col.isPrimaryKey,
                    isForeignKey: col.isForeignKey,
                    defaultValue: col.defaultValue,
                  ))
              .toList(),
          hasAuditFields: _hasAuditFields(table.columns),
          hasSyncFields: _hasSyncFields(table.columns),
          requiresAuthentication: _requiresAuth(table.name),
        );

        discoveredEntities.add(entity);
      }
    } catch (e) {
      print('Database discovery failed: $e');
    }

    return discoveredEntities;
  }

  /// Discovers entities from table name patterns
  static List<DiscoveredEntity> discoverFromTableNames(
    List<String> tableNames,
  ) {
    final discoveredEntities = <DiscoveredEntity>[];

    for (final tableName in tableNames) {
      if (_isSystemTable(tableName)) {
        continue;
      }

      final entity = DiscoveredEntity(
        entityName: tableName,
        tableName: tableName,
        className: _tableNameToClassName(tableName),
        discoveryMethod: EntityDiscoveryMethod.convention,
        hasAuditFields: true, // Assume standard tables have audit fields
        hasSyncFields: true, // Assume standard tables have sync fields
        requiresAuthentication: _requiresAuth(tableName),
      );

      discoveredEntities.add(entity);
    }

    return discoveredEntities;
  }

  /// Automatically registers discovered entities with a registry
  static void autoRegisterEntities(
    SyncEntityRegistry registry,
    List<DiscoveredEntity> discoveredEntities, {
    SyncEntityConfig Function(DiscoveredEntity)? configBuilder,
  }) {
    for (final entity in discoveredEntities) {
      final config = configBuilder?.call(entity) ?? _buildDefaultConfig(entity);
      registry.register(entity.entityName, config);
    }
  }

  /// Creates entity configurations based on conventions
  static SyncEntityConfig createConventionBasedConfig(
    String tableName, {
    Map<String, dynamic> overrides = const {},
  }) {
    // Determine authentication requirement based on table name
    final requiresAuth = !_isPublicTable(tableName);

    // Determine priority based on table name patterns
    final priority = _determinePriority(tableName);

    // Determine sync direction based on table type
    final syncDirection = _determineSyncDirection(tableName);

    // Create base configuration
    var config = SyncEntityConfig(
      tableName: tableName,
      requiresAuthentication: requiresAuth,
      priority: priority,
      syncDirection: syncDirection,
      enableRealTime: requiresAuth, // Real-time for authenticated entities
      securityLevel:
          requiresAuth ? SecurityLevel.internal : SecurityLevel.public,
    );

    // Apply overrides
    if (overrides.isNotEmpty) {
      config = _applyConfigOverrides(config, overrides);
    }

    return config;
  }

  /// Creates a bulk discovery and registration helper
  static Future<int> discoverAndRegister(
    SyncEntityRegistry registry, {
    List<EntityDefinition>? entityDefinitions,
    List<String>? tableNames,
    Future<List<TableInfo>> Function()? getDatabaseTables,
    SyncEntityConfig Function(DiscoveredEntity)? configBuilder,
  }) async {
    final allEntities = <DiscoveredEntity>[];

    // Discover from definitions
    if (entityDefinitions != null) {
      allEntities.addAll(discoverFromDefinitions(entityDefinitions));
    }

    // Discover from table names
    if (tableNames != null) {
      allEntities.addAll(discoverFromTableNames(tableNames));
    }

    // Discover from database
    if (getDatabaseTables != null) {
      final dbEntities = await discoverFromDatabase(getDatabaseTables);
      allEntities.addAll(dbEntities);
    }

    // Remove duplicates based on table name
    final uniqueEntities = <String, DiscoveredEntity>{};
    for (final entity in allEntities) {
      uniqueEntities[entity.tableName] = entity;
    }

    // Register all unique entities
    autoRegisterEntities(registry, uniqueEntities.values.toList(),
        configBuilder: configBuilder);

    return uniqueEntities.length;
  }

  /// Private helper methods
  static SyncEntityConfig _buildDefaultConfig(DiscoveredEntity entity) {
    return createConventionBasedConfig(entity.tableName);
  }

  static String _tableNameToClassName(String tableName) {
    // Convert snake_case to PascalCase
    return tableName
        .split('_')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join('');
  }

  static bool _isSystemTable(String tableName) {
    const systemTables = {
      'sqlite_master',
      'sqlite_sequence',
      'android_metadata',
      'sync_metadata',
      'sync_queue',
    };
    return systemTables.contains(tableName.toLowerCase());
  }

  static bool _isPublicTable(String tableName) {
    const publicPatterns = [
      'reference_',
      'lookup_',
      'config_',
      'settings_',
      'public_',
    ];
    return publicPatterns.any((pattern) => tableName.startsWith(pattern));
  }

  static bool _hasAuditFields(List<ColumnInfo> columns) {
    const auditFields = {
      'created_by',
      'updated_by',
      'created_at',
      'updated_at'
    };
    final columnNames = columns.map((c) => c.name).toSet();
    return auditFields.every((field) => columnNames.contains(field));
  }

  static bool _hasSyncFields(List<ColumnInfo> columns) {
    const syncFields = {
      'isDirty',
      'last_synced_at',
      'sync_version',
      'isDeleted'
    };
    final columnNames = columns.map((c) => c.name).toSet();
    return syncFields.every((field) => columnNames.contains(field));
  }

  static bool _hasAuditFieldsInClass(List<FieldInfo> fields) {
    const auditFields = {
      'created_by',
      'updated_by',
      'created_at',
      'updated_at'
    };
    final fieldNames = fields.map((f) => f.name).toSet();
    return auditFields.every((field) => fieldNames.contains(field));
  }

  static bool _hasSyncFieldsInClass(List<FieldInfo> fields) {
    const syncFields = {
      'isDirty',
      'last_synced_at',
      'sync_version',
      'isDeleted'
    };
    final fieldNames = fields.map((f) => f.name).toSet();
    return syncFields.every((field) => fieldNames.contains(field));
  }

  static bool _requiresAuth(String tableName) {
    return !_isPublicTable(tableName);
  }

  static SyncPriority _determinePriority(String tableName) {
    if (tableName.contains('audit') || tableName.contains('log')) {
      return SyncPriority.high;
    }
    if (tableName.contains('user') || tableName.contains('profile')) {
      return SyncPriority.high;
    }
    if (tableName.contains('reference') || tableName.contains('lookup')) {
      return SyncPriority.low;
    }
    return SyncPriority.normal;
  }

  static SyncDirection _determineSyncDirection(String tableName) {
    if (tableName.contains('reference') || tableName.contains('lookup')) {
      return SyncDirection.downloadOnly;
    }
    if (tableName.contains('audit') || tableName.contains('log')) {
      return SyncDirection.uploadOnly;
    }
    return SyncDirection.bidirectional;
  }

  static SyncEntityConfig _applyConfigOverrides(
    SyncEntityConfig config,
    Map<String, dynamic> overrides,
  ) {
    return config.copyWith(
      requiresAuthentication: overrides['requiresAuthentication'] as bool?,
      conflictStrategy:
          overrides['conflictStrategy'] as ConflictResolutionStrategy?,
      syncDirection: overrides['syncDirection'] as SyncDirection?,
      priority: overrides['priority'] as SyncPriority?,
      enableRealTime: overrides['enableRealTime'] as bool?,
      enableDeltaSync: overrides['enableDeltaSync'] as bool?,
      maxBatchSize: overrides['maxBatchSize'] as int?,
      syncInterval: overrides['syncInterval'] as Duration?,
      syncOffline: overrides['syncOffline'] as bool?,
      securityLevel: overrides['securityLevel'] as SecurityLevel?,
      excludedFields: overrides['excludedFields'] as List<String>?,
      requiredFields: overrides['requiredFields'] as List<String>?,
      validateBeforeSync: overrides['validateBeforeSync'] as bool?,
      validationRules: overrides['validationRules'] as Map<String, dynamic>?,
      fieldMappings: overrides['fieldMappings'] as Map<String, String>?,
      enableEncryption: overrides['enableEncryption'] as bool?,
      encryptionSettings:
          overrides['encryptionSettings'] as Map<String, dynamic>?,
      trackChanges: overrides['trackChanges'] as bool?,
      maxDataAge: overrides['maxDataAge'] as Duration?,
      queryFilters: overrides['queryFilters'] as Map<String, dynamic>?,
      enableCaching: overrides['enableCaching'] as bool?,
      cacheExpiration: overrides['cacheExpiration'] as Duration?,
      enableCompression: overrides['enableCompression'] as bool?,
      compressionType: overrides['compressionType'] as CompressionType?,
      customSettings: overrides['customSettings'] as Map<String, dynamic>?,
    );
  }
}

/// Represents a discovered entity
class DiscoveredEntity {
  const DiscoveredEntity({
    required this.entityName,
    required this.tableName,
    required this.className,
    required this.discoveryMethod,
    this.annotations = const [],
    this.fields = const [],
    this.hasAuditFields = false,
    this.hasSyncFields = false,
    this.requiresAuthentication = true,
  });

  final String entityName;
  final String tableName;
  final String className;
  final EntityDiscoveryMethod discoveryMethod;
  final List<EntityAnnotation> annotations;
  final List<FieldInfo> fields;
  final bool hasAuditFields;
  final bool hasSyncFields;
  final bool requiresAuthentication;

  @override
  String toString() {
    return 'DiscoveredEntity(entityName: $entityName, className: $className, '
        'method: $discoveryMethod, hasAudit: $hasAuditFields, hasSync: $hasSyncFields)';
  }
}

/// Manual entity definition for discovery
class EntityDefinition {
  const EntityDefinition({
    required this.tableName,
    required this.className,
    this.requiresAuthentication = true,
    this.annotations = const [],
    this.fields = const [],
  });

  final String tableName;
  final String className;
  final bool requiresAuthentication;
  final List<EntityAnnotation> annotations;
  final List<FieldInfo> fields;
}

/// Discovery methods for entities
enum EntityDiscoveryMethod {
  manual,
  convention,
  database,
  annotation,
}

/// Base class for entity annotations
abstract class EntityAnnotation {
  const EntityAnnotation();
}

/// Annotation for marking syncable entities
class SyncEntityAnnotation extends EntityAnnotation {
  const SyncEntityAnnotation({
    this.tableName = '',
    this.requiresAuthentication = true,
    this.priority = SyncPriority.normal,
    this.conflictStrategy = ConflictResolutionStrategy.timestampWins,
  });

  final String tableName;
  final bool requiresAuthentication;
  final SyncPriority priority;
  final ConflictResolutionStrategy conflictStrategy;
}

/// Annotation for table configuration
class SyncTableAnnotation extends EntityAnnotation {
  const SyncTableAnnotation({
    required this.tableName,
    this.enableRealTime = true,
    this.enableDeltaSync = true,
  });

  final String tableName;
  final bool enableRealTime;
  final bool enableDeltaSync;
}

/// Annotation for field configuration
class SyncFieldAnnotation extends EntityAnnotation {
  const SyncFieldAnnotation({
    this.exclude = false,
    this.encrypt = false,
    this.mapping = '',
  });

  final bool exclude;
  final bool encrypt;
  final String mapping;
}

/// Information about a discovered field
class FieldInfo {
  const FieldInfo({
    required this.name,
    required this.type,
    this.isNullable = false,
    this.isPrimaryKey = false,
    this.isForeignKey = false,
    this.defaultValue,
    this.annotations = const [],
  });

  final String name;
  final String type;
  final bool isNullable;
  final bool isPrimaryKey;
  final bool isForeignKey;
  final dynamic defaultValue;
  final List<EntityAnnotation> annotations;

  @override
  String toString() {
    return 'FieldInfo(name: $name, type: $type, nullable: $isNullable)';
  }
}

/// Database table information
class TableInfo {
  const TableInfo({
    required this.name,
    required this.columns,
  });

  final String name;
  final List<ColumnInfo> columns;
}

/// Database column information
class ColumnInfo {
  const ColumnInfo({
    required this.name,
    required this.type,
    this.isNullable = false,
    this.isPrimaryKey = false,
    this.isForeignKey = false,
    this.defaultValue,
  });

  final String name;
  final String type;
  final bool isNullable;
  final bool isPrimaryKey;
  final bool isForeignKey;
  final dynamic defaultValue;
}
