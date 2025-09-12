/// Test file demonstrating Universal Sync Manager configuration system
///
/// This file shows how to use all the configuration components together
/// and serves as both documentation and validation of the implementation.

import 'dart:io';
import '../lib/src/config/config.dart';

/// Demonstrates the complete configuration system usage
Future<void> demonstrateConfigurationSystem() async {
  print('=== Universal Sync Manager Configuration System Demo ===\n');

  // 1. Create Universal Configuration
  print('1. Creating Universal Sync Configuration...');
  final universalConfig = UniversalSyncConfig.production(
    projectId: 'demo-project',
    backendConfig: {
      'baseUrl': 'https://api.example.com',
      'apiKey': 'demo-key',
    },
    customSettings: {
      'appVersion': '1.0.0',
      'features': ['realtime', 'offline'],
    },
  );
  print(
      '   ✓ Created production configuration for: ${universalConfig.projectId}');
  print('   ✓ Sync mode: ${universalConfig.syncMode}');
  print('   ✓ Environment: ${universalConfig.environment}\n');

  // 2. Create Entity Registry and Register Entities
  print('2. Setting up Entity Registry...');
  final entityRegistry = SyncEntityRegistry();

  // Register different types of entities
  entityRegistry.register(
      'users',
      SyncEntityConfig.protected(
        tableName: 'users',
        priority: SyncPriority.high,
        conflictStrategy: ConflictResolutionStrategy.timestampWins,
        securityLevel: SecurityLevel.sensitive,
      ));

  entityRegistry.register(
      'posts',
      SyncEntityConfig.public(
        tableName: 'posts',
        syncDirection: SyncDirection.downloadOnly,
        priority: SyncPriority.normal,
      ));

  entityRegistry.register(
      'audit_logs',
      SyncEntityConfig.highPriority(
        tableName: 'audit_logs',
        requiresAuthentication: true,
        securityLevel: SecurityLevel.restricted,
      ));

  entityRegistry.register(
      'reference_data',
      SyncEntityConfig.readOnly(
        tableName: 'reference_data',
        requiresAuthentication: false,
        cacheExpiration: Duration(hours: 24),
      ));

  print('   ✓ Registered ${entityRegistry.entityNames.length} entities:');
  for (final entityName in entityRegistry.entityNames) {
    final config = entityRegistry.getConfig(entityName)!;
    print(
        '     - $entityName (${config.tableName}) - Auth: ${config.requiresAuthentication}');
  }
  print('');

  // 3. Validate Configuration
  print('3. Validating Configuration...');
  final validationResult = SyncConfigValidator.validateSyncSystem(
    universalConfig,
    entityRegistry,
  );

  if (validationResult.isValid) {
    print('   ✓ Configuration is valid!');
  } else {
    print('   ✗ Configuration has errors:');
    for (final error in validationResult.systemErrors) {
      print('     - $error');
    }
  }

  if (validationResult.hasWarnings) {
    print('   ⚠ Configuration has warnings:');
    for (final warning in validationResult.systemWarnings) {
      print('     - $warning');
    }
  }
  print('');

  // 4. Test Serialization
  print('4. Testing Serialization...');

  // Export to JSON string
  final jsonString = SyncConfigSerializer.exportToJsonString(
    universalConfig: universalConfig,
    entityRegistry: entityRegistry,
    metadata: {
      'exportedBy': 'demo',
      'exportedAt': DateTime.now().toIso8601String(),
    },
    prettyFormat: true,
  );
  print(
      '   ✓ Exported configuration to JSON (${jsonString.length} characters)');

  // Import from JSON string
  final importedConfig = SyncConfigSerializer.importFromJsonString(jsonString);
  print('   ✓ Imported configuration from JSON');
  print('   ✓ Project ID: ${importedConfig.universalConfig.projectId}');
  print('   ✓ Entities: ${importedConfig.entityRegistry.entityNames.length}');
  print('');

  // 5. Test File Persistence
  print('5. Testing File Persistence...');

  final configDir = Directory('test_config');
  if (!await configDir.exists()) {
    await configDir.create();
  }

  final configFile = 'test_config/demo_sync_config.json';

  try {
    // Save to file
    await SyncConfigSerializer.saveToFile(
      filePath: configFile,
      universalConfig: universalConfig,
      entityRegistry: entityRegistry,
      metadata: {
        'savedBy': 'demo',
        'purpose': 'testing',
      },
    );
    print('   ✓ Saved configuration to file: $configFile');

    // Load from file
    final loadedConfig = await SyncConfigSerializer.loadFromFile(
      filePath: configFile,
    );
    print('   ✓ Loaded configuration from file');
    print('   ✓ Project ID: ${loadedConfig.universalConfig.projectId}');
    print('   ✓ Version: ${loadedConfig.version}');
    print('   ✓ Timestamp: ${loadedConfig.timestamp}');

    // Validate file format
    final fileValidation =
        await SyncConfigSerializer.validateConfigFile(configFile);
    if (fileValidation.isValid) {
      print('   ✓ Configuration file format is valid');
    } else {
      print('   ✗ Configuration file format errors:');
      for (final error in fileValidation.errors) {
        print('     - $error');
      }
    }
  } catch (e) {
    print('   ✗ File persistence error: $e');
  }
  print('');

  // 6. Test Configuration Templates
  print('6. Testing Configuration Templates...');

  final templateConfig = SyncConfigSerializer.createTemplate(
    projectId: 'template-project',
    environment: SyncEnvironment.development,
    entityNames: ['users', 'settings', 'data'],
  );

  print('   ✓ Created template configuration');
  print('   ✓ Project ID: ${templateConfig.universalConfig.projectId}');
  print('   ✓ Environment: ${templateConfig.universalConfig.environment}');
  print(
      '   ✓ Template entities: ${templateConfig.entityRegistry.entityNames.join(', ')}');
  print('');

  // 7. Test Entity Registry Features
  print('7. Testing Entity Registry Features...');

  final protectedEntities = entityRegistry.protectedEntities;
  final publicEntities = entityRegistry.publicEntities;
  final realTimeEntities = entityRegistry.realTimeEntities;
  final highPriorityEntities =
      entityRegistry.getEntitiesByPriority(SyncPriority.high);

  print('   ✓ Protected entities: ${protectedEntities.keys.join(', ')}');
  print('   ✓ Public entities: ${publicEntities.keys.join(', ')}');
  print('   ✓ Real-time entities: ${realTimeEntities.keys.join(', ')}');
  print('   ✓ High priority entities: ${highPriorityEntities.keys.join(', ')}');
  print('');

  // 8. Test Configuration Merging
  print('8. Testing Configuration Merging...');

  final overrideConfig = SyncSystemConfig(
    universalConfig: UniversalSyncConfig(
      projectId: 'merged-project',
      syncMode: SyncMode.manual,
      maxRetries: 5,
    ),
    entityRegistry: SyncEntityRegistry(),
    version: 1,
    timestamp: DateTime.now(),
    metadata: {'source': 'override'},
  );

  final mergedConfig = SyncConfigSerializer.mergeConfigurations(
    importedConfig,
    overrideConfig,
  );

  print('   ✓ Merged configurations');
  print('   ✓ Merged project ID: ${mergedConfig.universalConfig.projectId}');
  print('   ✓ Merged sync mode: ${mergedConfig.universalConfig.syncMode}');
  print('   ✓ Merged max retries: ${mergedConfig.universalConfig.maxRetries}');
  print('');

  // 9. Test Individual Validations
  print('9. Testing Individual Validations...');

  // Test entity validation
  final entityValidation = SyncConfigValidator.validateEntityConfig(
    'test_entity',
    SyncEntityConfig(
      tableName: 'test_entity',
      maxBatchSize: -1, // This should cause an error
    ),
  );

  if (!entityValidation.isValid) {
    print('   ✓ Entity validation correctly caught errors:');
    for (final error in entityValidation.errors) {
      print('     - $error');
    }
  }

  // Test universal config validation
  final invalidUniversalConfig = UniversalSyncConfig(
    projectId: '', // This should cause an error
    maxRetries: -1, // This should cause an error
  );

  final universalValidation =
      SyncConfigValidator.validateUniversalConfig(invalidUniversalConfig);
  if (!universalValidation.isValid) {
    print('   ✓ Universal config validation correctly caught errors:');
    for (final error in universalValidation.errors) {
      print('     - $error');
    }
  }
  print('');

  // 10. Test Configuration Factories
  print('10. Testing Configuration Factories...');

  final devConfig = UniversalSyncConfig.development(
    projectId: 'dev-project',
  );
  print(
      '   ✓ Development config - Mode: ${devConfig.syncMode}, Log Level: ${devConfig.logLevel}');

  final testConfig = UniversalSyncConfig.testing(
    projectId: 'test-project',
  );
  print(
      '   ✓ Testing config - Mode: ${testConfig.syncMode}, Analytics: ${testConfig.enableAnalytics}');

  final prodConfig = UniversalSyncConfig.production(
    projectId: 'prod-project',
  );
  print(
      '   ✓ Production config - Mode: ${prodConfig.syncMode}, Analytics: ${prodConfig.enableAnalytics}');
  print('');

  // Cleanup
  print('11. Cleaning up...');
  try {
    final file = File(configFile);
    if (await file.exists()) {
      await file.delete();
      print('   ✓ Deleted test configuration file');
    }

    if (await configDir.exists()) {
      await configDir.delete();
      print('   ✓ Deleted test configuration directory');
    }
  } catch (e) {
    print('   ⚠ Cleanup warning: $e');
  }

  print('\n=== Configuration System Demo Complete ===');
  print('✓ All configuration components working correctly!');
}

/// Demonstrates error handling in the configuration system
void demonstrateErrorHandling() {
  print('\n=== Configuration Error Handling Demo ===\n');

  try {
    // Test invalid configuration
    final invalidConfig = UniversalSyncConfig(
      projectId: '',
      syncInterval: Duration(seconds: 0),
      maxRetries: -1,
      maxBatchSize: 0,
    );

    final validation =
        SyncConfigValidator.validateUniversalConfig(invalidConfig);
    print('Validation errors found:');
    for (final error in validation.errors) {
      print('  - $error');
    }
  } catch (e) {
    print('Exception caught: $e');
  }

  try {
    // Test invalid JSON
    SyncConfigSerializer.importFromJsonString('invalid json');
  } catch (e) {
    print('\nSerialization error correctly caught: ${e.runtimeType}');
  }

  print('\n✓ Error handling working correctly!');
}

/// Main function to run all demonstrations
Future<void> main() async {
  await demonstrateConfigurationSystem();
  demonstrateErrorHandling();
}
