import '../config/usm_sync_entity_config.dart';
import '../config/usm_entity_discovery.dart';
import '../config/usm_field_mapping_config.dart';
import '../config/usm_sync_strategies.dart';
import '../config/usm_sync_enums.dart';

/// Simple demonstration of Task 3.2: Entity Registration System
class Task32Demo {
  static Future<void> run() async {
    print('Universal Sync Manager - Task 3.2: Entity Registration System Demo');
    print('');

    await _demonstrateEntityRegistry();
    await _demonstrateEntityDiscovery();
    await _demonstrateFieldMapping();
    await _demonstrateSyncStrategies();

    print('');
    print('Task 3.2 Demo Completed Successfully!');
  }

  static Future<void> _demonstrateEntityRegistry() async {
    print('1. Entity Registry Demonstration');

    final registry = SyncEntityRegistry();

    registry.register(
        'user_profiles',
        SyncEntityConfig(
          tableName: 'user_profiles',
          requiresAuthentication: true,
          priority: SyncPriority.high,
          conflictStrategy: ConflictResolutionStrategy.timestampWins,
          enableRealTime: true,
          syncDirection: SyncDirection.bidirectional,
        ));

    registry.register(
        'audit_logs',
        SyncEntityConfig(
          tableName: 'audit_logs',
          requiresAuthentication: true,
          priority: SyncPriority.critical,
          conflictStrategy: ConflictResolutionStrategy.serverWins,
          syncDirection: SyncDirection.uploadOnly,
          enableDeltaSync: true,
        ));

    print('Registered ${registry.allConfigs.length} entities');

    for (final entry in registry.allConfigs.entries) {
      final entityName = entry.key;
      final config = entry.value;
      print(
          '  $entityName: ${config.priority!.name} priority, ${config.syncDirection!.name} sync');
    }

    final highPriorityEntities =
        registry.getEntitiesByPriority(SyncPriority.high);
    print('High priority entities: ${highPriorityEntities.keys.toList()}');

    print('');
  }

  static Future<void> _demonstrateEntityDiscovery() async {
    print('2. Entity Discovery Demonstration');

    final entityDefinitions = [
      EntityDefinition(
        tableName: 'organization_profiles',
        className: 'OrganizationProfile',
        requiresAuthentication: true,
        fields: [
          FieldInfo(name: 'id', type: 'String', isPrimaryKey: true),
          FieldInfo(name: 'name', type: 'String'),
          FieldInfo(name: 'createdBy', type: 'String'),
          FieldInfo(name: 'updatedBy', type: 'String'),
          FieldInfo(name: 'createdAt', type: 'DateTime'),
          FieldInfo(name: 'updatedAt', type: 'DateTime'),
          FieldInfo(name: 'isDirty', type: 'bool'),
          FieldInfo(name: 'syncVersion', type: 'int'),
        ],
      ),
    ];

    final discoveredFromDefinitions =
        SyncEntityDiscovery.discoverFromDefinitions(entityDefinitions);
    print(
        'Discovered ${discoveredFromDefinitions.length} entities from definitions');

    for (final entity in discoveredFromDefinitions) {
      print(
          '  ${entity.entityName} (${entity.className}) - Audit: ${entity.hasAuditFields}, Sync: ${entity.hasSyncFields}');
    }

    final tableNames = [
      'user_sessions',
      'notification_settings',
      'reference_countries'
    ];
    final discoveredFromTables =
        SyncEntityDiscovery.discoverFromTableNames(tableNames);
    print(
        'Discovered ${discoveredFromTables.length} entities from table names');

    for (final entity in discoveredFromTables) {
      print(
          '  ${entity.entityName} → ${entity.className} (${entity.discoveryMethod.name})');
    }

    print('');
  }

  static Future<void> _demonstrateFieldMapping() async {
    print('3. Field Mapping Configuration Demonstration');

    final fieldMapping = SyncFieldMappingConfig(
      fieldMappings: {
        'userId': 'user_id',
        'organizationId': 'org_id',
        'createdAt': 'created_date',
        'updatedAt': 'modified_date',
      },
      fieldTransformations: {
        'email': FieldTransformation(
          type: TransformationType.lowercase,
          applyOnWrite: true,
          applyOnRead: false,
        ),
        'phoneNumber': FieldTransformation(
          type: TransformationType.replace,
          parameters: {'find': '-', 'replace': ''},
          applyOnWrite: true,
        ),
      },
      fieldValidations: {
        'email': FieldValidation(
          required: true,
          pattern: r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
          errorMessage: 'Please enter a valid email address',
        ),
      },
      excludedFields: ['password', 'internalNotes'],
      requiredFields: ['id', 'name', 'email'],
      encryptedFields: ['ssn', 'creditCard'],
    );

    print('Field mapping configuration created:');
    print('  Mappings: ${fieldMapping.fieldMappings.length}');
    print('  Transformations: ${fieldMapping.fieldTransformations.length}');
    print('  Validations: ${fieldMapping.fieldValidations.length}');
    print('  Excluded: ${fieldMapping.excludedFields.length}');
    print('  Encrypted: ${fieldMapping.encryptedFields.length}');

    final emailTransform = fieldMapping.fieldTransformations['email']!;
    final originalEmail = 'USER@EXAMPLE.COM';
    final transformedEmail = emailTransform.transform(originalEmail);
    print('  Email transform: "$originalEmail" → "$transformedEmail"');

    final emailValidation = fieldMapping.fieldValidations['email']!;
    final validResult = emailValidation.validate('user@example.com');
    final invalidResult = emailValidation.validate('invalid-email');

    print('  Valid email validation: ${validResult.isValid}');
    print('  Invalid email validation: ${invalidResult.isValid}');

    print('');
  }

  static Future<void> _demonstrateSyncStrategies() async {
    print('4. Sync Strategies Demonstration');

    final strategyManager = SyncStrategyManager();

    final timestampStrategy = TimestampSyncStrategy(
      syncIntervalMinutes: 10,
      maxRetries: 3,
      batchSize: 50,
    );

    final priorityStrategy = PrioritySyncStrategy(
      highPriorityFirst: true,
      priorityWeights: {
        SyncPriority.critical: 10.0,
        SyncPriority.high: 5.0,
        SyncPriority.normal: 1.0,
        SyncPriority.low: 0.5,
      },
    );

    strategyManager.registerStrategy(timestampStrategy);
    strategyManager.registerStrategy(priorityStrategy);

    print(
        'Registered ${strategyManager.getAllStrategies().length} sync strategies:');
    for (final strategy in strategyManager.getAllStrategies().values) {
      print('  ${strategy.name}: ${strategy.description}');
    }

    strategyManager.setEntityStrategy('user_profiles', 'timestamp');
    strategyManager.setEntityStrategy('task_items', 'priority');

    print('Entity strategy assignments:');
    final entities = ['user_profiles', 'task_items'];
    for (final entity in entities) {
      final strategy = strategyManager.getEntityStrategy(entity);
      print('  $entity → ${strategy?.name ?? 'default'}');
    }

    final syncContext = SyncContext(
      entityName: 'user_profiles',
      entityPriority: SyncPriority.high,
      lastSyncTime: DateTime.now().subtract(Duration(minutes: 15)),
      userId: 'user123',
      organizationId: 'org456',
    );

    final shouldSync = await timestampStrategy.shouldSync(syncContext);
    print(
        'Timestamp strategy shouldSync: $shouldSync (last sync was 15 min ago)');

    print('');
  }
}
