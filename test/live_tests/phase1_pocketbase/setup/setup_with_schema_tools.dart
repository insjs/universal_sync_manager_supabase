#!/usr/bin/env dart

/// Universal Sync Manager - PocketBase Live Test Setup
///
/// This script uses the existing schema management tools to set up PocketBase
/// for live testing instead of recreating the functionality.
///
/// Usage:
/// dart setup_with_schema_tools.dart [config_file]

import 'dart:io';
import 'dart:convert';
import 'package:yaml/yaml.dart';
import 'package:http/http.dart' as http;

void main(List<String> arguments) async {
  print('🚀 Universal Sync Manager - PocketBase Live Test Setup');
  print('📊 Using existing schema management tools...\n');

  try {
    // Load configuration
    final configFile =
        arguments.isNotEmpty ? arguments[0] : 'setup/config.yaml';

    final config = await _loadConfig(configFile);
    final pbConfig = config['pocketbase'] as Map;

    final baseUrl = pbConfig['url'] as String;
    final adminEmail = pbConfig['admin_email'] as String;
    final adminPassword = pbConfig['admin_password'] as String;

    print('🌐 PocketBase URL: $baseUrl');
    print('👤 Admin email: $adminEmail');
    print('---\n');

    // Check if PocketBase is running
    if (!await _isPocketBaseRunning(baseUrl)) {
      print('❌ PocketBase is not running at $baseUrl');
      print('💡 Please start PocketBase first: ./pocketbase serve');
      exit(1);
    }

    // Get test schemas to setup
    final testSchemas = config['test_schemas'] as List? ??
        [
          'universal_sync_manager_test.yaml',
          'ost_managed_users_test_simple.yaml'
        ];

    print('📋 Setting up ${testSchemas.length} test schemas...\n');

    // Setup each schema using the schema manager
    var successCount = 0;
    for (final schemaFile in testSchemas) {
      final schemaPath = _findSchemaPath(schemaFile as String);
      if (schemaPath == null) {
        print('❌ Schema file not found: $schemaFile');
        continue;
      }

      print('🔧 Setting up schema: $schemaFile');

      final result = await _runSchemaManager(
        schemaPath,
        baseUrl,
        adminEmail,
        adminPassword,
      );

      if (result) {
        successCount++;
        print('✅ Successfully set up: $schemaFile\n');
      } else {
        print('❌ Failed to set up: $schemaFile\n');
      }
    }

    // Summary
    print('---');
    print('📊 Setup Summary:');
    print('   ✅ Successful: $successCount schemas');
    print('   ❌ Failed: ${testSchemas.length - successCount} schemas');

    if (successCount == testSchemas.length) {
      print('\n🎉 All test schemas successfully set up in PocketBase!');
      print('🚀 You can now run the live tests.');
    } else {
      print(
          '\n⚠️  Some schemas failed to set up. Check the output above for details.');
      exit(1);
    }
  } catch (e) {
    print('❌ Setup failed: $e');
    exit(1);
  }
}

/// Load configuration from YAML file
Future<Map<String, dynamic>> _loadConfig(String configPath) async {
  final possiblePaths = [
    configPath,
    'setup/$configPath',
    'test/live_tests/phase1_pocketbase/setup/$configPath',
    'test/live_tests/phase1_pocketbase/setup/config.yaml'
  ];

  File? configFile;
  for (final path in possiblePaths) {
    final file = File(path);
    if (await file.exists()) {
      configFile = file;
      break;
    }
  }

  if (configFile == null) {
    throw Exception(
        'Configuration file not found. Tried: ${possiblePaths.join(', ')}');
  }

  final configContent = await configFile.readAsString();
  final doc = loadYaml(configContent);

  print('📋 Configuration loaded from: ${configFile.path}');

  // Convert YAML to Map using JSON encode/decode to avoid type issues
  return json.decode(json.encode(doc)) as Map<String, dynamic>;
}

/// Check if PocketBase is running
Future<bool> _isPocketBaseRunning(String baseUrl) async {
  try {
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/health'),
        )
        .timeout(Duration(seconds: 5));

    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}

/// Find schema file path
String? _findSchemaPath(String schemaFile) {
  final possiblePaths = [
    'tools/schema/$schemaFile',
    'schema/$schemaFile',
    '../../../tools/schema/$schemaFile',
    '../../../../tools/schema/$schemaFile',
  ];

  for (final path in possiblePaths) {
    final file = File(path);
    if (file.existsSync()) {
      return path;
    }
  }

  return null;
}

/// Run the schema manager for a specific schema file
Future<bool> _runSchemaManager(
  String schemaPath,
  String baseUrl,
  String adminEmail,
  String adminPassword,
) async {
  try {
    // Find the schema manager script
    const managerScript = 'tools/pocketbase_schema_manager.dart';

    final managerFile = File(managerScript);
    if (!managerFile.existsSync()) {
      // Try relative path
      final relativeManager = File('../../../$managerScript');
      if (!relativeManager.existsSync()) {
        print('❌ Schema manager not found: $managerScript');
        return false;
      }
    }

    // Run the schema manager as a subprocess
    final result = await Process.run(
      'dart',
      [
        managerScript,
        schemaPath,
        baseUrl,
        adminEmail,
        adminPassword,
      ],
      workingDirectory: Directory.current.path,
    );

    if (result.exitCode == 0) {
      // Print output from schema manager
      if (result.stdout.toString().isNotEmpty) {
        print(result.stdout.toString().trim());
      }
      return true;
    } else {
      print('❌ Schema manager failed:');
      if (result.stderr.toString().isNotEmpty) {
        print(result.stderr.toString().trim());
      }
      if (result.stdout.toString().isNotEmpty) {
        print(result.stdout.toString().trim());
      }
      return false;
    }
  } catch (e) {
    print('❌ Error running schema manager: $e');
    return false;
  }
}
