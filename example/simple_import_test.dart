#!/usr/bin/env dart

/// Simple test to verify that USM package imports work correctly
/// This runs as a pure Dart script without Flutter dependencies

import 'dart:io';

// Test importing USM package
void main() async {
  print('🧪 Testing Universal Sync Manager Package Imports...\n');

  try {
    // Test 1: Check if we can import the main package
    print('✅ Test 1: Importing main package...');
    // Import test - this will fail if package structure is broken
    await _testImports();

    print('\n🎉 All import tests passed!');
    print(
        '✅ USM is properly configured as a package and ready for local usage');
  } catch (e, stackTrace) {
    print('\n❌ Import test failed:');
    print('Error: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}

Future<void> _testImports() async {
  // This function tests imports by attempting to compile code that uses them
  final testCode = '''
// Test importing USM package
import 'package:universal_sync_manager/universal_sync_manager.dart';

void main() {
  // Test creating core classes
  print('Testing USM imports...');
  
  // These should compile if imports work
  print('PocketBaseSyncAdapter: \${PocketBaseSyncAdapter}');
  print('SyncResult: \${SyncResult}');
  print('MyAppSyncManager: \${MyAppSyncManager}');
  print('AuthContext: \${AuthContext}');
  print('SyncableModel: \${SyncableModel}');
  
  print('All imports successful!');
}
''';

  // Write test code to temporary file
  final tempFile = File('temp_import_test.dart');
  await tempFile.writeAsString(testCode);

  try {
    // Try to analyze the code - this will fail if imports don't work
    print('   Analyzing imports...');
    final analyzeResult = await Process.run(
      'dart',
      ['analyze', 'temp_import_test.dart'],
      workingDirectory: Directory.current.path,
    );

    if (analyzeResult.exitCode == 0) {
      print('   ✅ Static analysis passed - imports are valid');
    } else {
      print('   ⚠️  Analysis warnings (but imports work):');
      print('   ${analyzeResult.stdout}');
      print('   ${analyzeResult.stderr}');
    }

    // Try to compile (but not run) the code
    print('   Compiling test code...');
    final compileResult = await Process.run(
      'dart',
      ['compile', 'exe', 'temp_import_test.dart', '-o', 'temp_test.exe'],
      workingDirectory: Directory.current.path,
    );

    if (compileResult.exitCode == 0) {
      print('   ✅ Compilation successful - package structure is valid');

      // Clean up compiled file
      final exeFile = File('temp_test.exe');
      if (await exeFile.exists()) {
        await exeFile.delete();
      }
    } else {
      print('   ❌ Compilation failed:');
      print('   ${compileResult.stdout}');
      print('   ${compileResult.stderr}');
      throw Exception('Package compilation failed');
    }
  } finally {
    // Clean up temp file
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
  }
}
