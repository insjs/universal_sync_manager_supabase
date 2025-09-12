#!/usr/bin/env dart

/// Quick USM Package Validation Script
/// Run this script to verify USM package is working correctly
/// Usage: dart validate_usm_package.dart

import 'dart:io';

void main() async {
  print('🚀 USM Package Validation Script');
  print('================================\n');

  // Step 1: Check if we're in a Flutter project
  await validateFlutterProject();

  // Step 2: Check pubspec.yaml for USM dependency
  await validatePubspecDependency();

  // Step 3: Check if packages are available
  await validatePackagesInstalled();

  // Step 4: Validate USM imports work
  await validateUSMImports();

  print('\n🎉 USM Package validation completed!');
  print('You can now run the integration tests as described in the guide.');
}

Future<void> validateFlutterProject() async {
  print('📋 Step 1: Checking Flutter project...');

  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('❌ Not in a Flutter project directory (no pubspec.yaml found)');
    print('💡 Navigate to your test project directory first');
    exit(1);
  }

  final content = await pubspecFile.readAsString();
  if (!content.contains('flutter:')) {
    print('❌ Not a Flutter project (no flutter dependency in pubspec.yaml)');
    exit(1);
  }

  print('✅ Flutter project detected');
}

Future<void> validatePubspecDependency() async {
  print('📋 Step 2: Checking USM dependency...');

  final pubspecFile = File('pubspec.yaml');
  final content = await pubspecFile.readAsString();

  if (!content.contains('universal_sync_manager:')) {
    print('❌ USM package not found in pubspec.yaml');
    print('💡 Add this to your pubspec.yaml dependencies:');
    print('  universal_sync_manager:');
    print('    path: ../universal_sync_manager  # Adjust path as needed');
    exit(1);
  }

  if (!content.contains('path:')) {
    print('⚠️  USM dependency found but no path specified');
    print('💡 Make sure you have a local path dependency like:');
    print('  universal_sync_manager:');
    print('    path: ../universal_sync_manager');
  }

  print('✅ USM dependency found in pubspec.yaml');
}

Future<void> validatePackagesInstalled() async {
  print('📋 Step 3: Checking if packages are installed...');

  final packageConfigFile = File('.dart_tool/package_config.json');
  if (!packageConfigFile.existsSync()) {
    print('❌ Packages not installed');
    print('💡 Run: flutter pub get');
    exit(1);
  }

  final content = await packageConfigFile.readAsString();
  if (!content.contains('universal_sync_manager')) {
    print('❌ USM package not found in package config');
    print('💡 Run: flutter pub get');
    print('💡 Check that the path to USM package is correct');
    exit(1);
  }

  print('✅ USM package installed and available');
}

Future<void> validateUSMImports() async {
  print('📋 Step 4: Validating USM imports...');

  // Check if we can run flutter command first
  try {
    final flutterCheck = await Process.run('flutter', ['--version']);
    if (flutterCheck.exitCode != 0) {
      print('⚠️  Flutter not available in PATH, skipping import test');
      print('💡 Import validation should be done in a consumer project');
      print('✅ Basic package validation completed successfully');
      return;
    }
  } catch (e) {
    print('⚠️  Flutter not available in PATH, skipping import test');
    print('💡 Import validation should be done in a consumer project');
    print('✅ Basic package validation completed successfully');
    return;
  }

  // Create a temporary test file to validate imports
  final testDir = Directory('test');
  if (!testDir.existsSync()) {
    await testDir.create();
  }

  final testFile = File('test/test_usm_import_test.dart');
  await testFile.writeAsString('''
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';

void main() {
  test('USM package imports and basic functionality', () {
    // Test basic component creation
    final config = SyncBackendConfiguration(
      configId: 'test',
      displayName: 'Test',
      backendType: 'test',
      baseUrl: 'http://test.com',
      projectId: 'test',
    );
    
    expect(config.displayName, equals('Test'));
    expect(config.configId, equals('test'));
    expect(config.backendType, equals('test'));
    
    print('USM package import successful!');
    print('Config created: \${config.displayName}');
  });
}
''');

  // Try to run the test file using flutter test
  final result = await Process.run(
      'flutter', ['test', 'test/test_usm_import_test.dart'],
      runInShell: true);

  // Clean up test file
  await testFile.delete();

  if (result.exitCode != 0) {
    print('❌ USM import validation failed');
    print('Error output:');
    print(result.stderr);
    print(
        '\n💡 Check that USM package path is correct and run flutter pub get');
    exit(1);
  }

  print('✅ USM imports work correctly');
  print('Output: ${result.stdout.toString().trim()}');
}
