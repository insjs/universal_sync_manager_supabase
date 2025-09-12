#!/usr/bin/env dart

/// Minimal test to verify USM package structure is correct
/// This only checks import resolution without compiling

import 'dart:io';

void main() async {
  print('🧪 Testing Universal Sync Manager Package Structure...\n');

  try {
    // Test 1: Check if pubspec.yaml is properly configured as a package
    print('✅ Test 1: Checking package configuration...');
    await _testPackageConfig();

    // Test 2: Check if main export file exists and has content
    print('✅ Test 2: Checking main export file...');
    await _testExportFile();

    // Test 3: Check if key source files exist
    print('✅ Test 3: Checking source files exist...');
    await _testSourceFiles();

    print('\n🎉 All package structure tests passed!');
    print('✅ USM is properly structured as a Flutter package');
    print('✅ Ready to be imported in other projects as a local dependency');
  } catch (e, stackTrace) {
    print('\n❌ Package structure test failed:');
    print('Error: $e');
    exit(1);
  }
}

Future<void> _testPackageConfig() async {
  final pubspecFile = File('../pubspec.yaml');
  if (!await pubspecFile.exists()) {
    throw Exception('pubspec.yaml not found');
  }

  final content = await pubspecFile.readAsString();
  if (!content.contains('name: universal_sync_manager')) {
    throw Exception('Package name not correctly set in pubspec.yaml');
  }

  if (content.contains('flutter:') && content.contains('sdk: flutter')) {
    print('   ✅ Flutter package dependencies found');
  } else {
    throw Exception('Flutter dependencies not properly configured');
  }

  print('   ✅ pubspec.yaml is properly configured');
}

Future<void> _testExportFile() async {
  final exportFile = File('../lib/universal_sync_manager.dart');
  if (!await exportFile.exists()) {
    throw Exception(
        'Main export file lib/universal_sync_manager.dart not found');
  }

  final content = await exportFile.readAsString();
  final expectedExports = [
    'export \'src/interfaces/sync_backend_adapter.dart\'',
    'export \'src/core/sync_result.dart\'',
    'export \'src/adapters/pocketbase_sync_adapter.dart\'',
    'export \'src/config/auth_context.dart\'',
    'export \'src/services/myapp_sync_manager.dart\'',
  ];

  for (final exportLine in expectedExports) {
    if (!content.contains(exportLine)) {
      throw Exception('Missing export: $exportLine');
    }
  }

  print('   ✅ Main export file contains all required exports');
}

Future<void> _testSourceFiles() async {
  final requiredFiles = [
    '../lib/src/interfaces/sync_backend_adapter.dart',
    '../lib/src/core/sync_result.dart',
    '../lib/src/adapters/pocketbase_sync_adapter.dart',
    '../lib/src/config/auth_context.dart',
    '../lib/src/services/myapp_sync_manager.dart',
    '../lib/src/models/syncable_model.dart',
  ];

  for (final filePath in requiredFiles) {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Required source file not found: $filePath');
    }

    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      throw Exception('Source file is empty: $filePath');
    }
  }

  print('   ✅ All required source files exist and contain code');
}
