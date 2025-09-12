# Testing USM Package in Another Local Project - Guide for Claude Sonnet

## 🎯 Purpose
This guide provides step-by-step instructions for testing the Universal Sync Manager (USM) package after importing it into another local Flutter project.

## 📋 Prerequisites
- USM package converted to proper package structure (version 0.1.0)
- Flutter SDK 3.35.2 or later
- A separate Flutter project to test with

## 🚀 Step-by-Step Testing Instructions

### Step 1: Create or Navigate to Test Project
```bash
# Option A: Create new Flutter project for testing
flutter create usm_test_project
cd usm_test_project

# Option B: Use existing Flutter project
cd /path/to/your/existing/flutter/project
```

### Step 2: Add USM Package Dependency
Edit the test project's `pubspec.yaml` file:

```yaml
dependencies:
  flutter:
    sdk: flutter
  # Add USM package with local path
  universal_sync_manager:
    path: ../universal_sync_manager  # Adjust path to USM package location
```

**Important**: Adjust the path to match the actual location of the USM package relative to your test project.

### Step 3: Install Dependencies
```bash
flutter pub get
```

### Step 4: Create Test Integration File
Create `lib/usm_integration_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';

class USMIntegrationTest {
  /// Test 1: Basic component instantiation
  static void testBasicComponents() {
    print('🧪 Testing USM Basic Components...');
    
    try {
      // Test configuration creation
      final config = SyncBackendConfiguration(
        configId: 'test-config',
        displayName: 'Test Configuration',
        backendType: 'pocketbase',
        baseUrl: 'http://localhost:8090',
        projectId: 'test-project',
      );
      print('✅ SyncBackendConfiguration created successfully');
      
      // Test enum values
      final syncMode = SyncMode.manual;
      print('✅ SyncMode enum accessible: $syncMode');
      
      final strategy = ConflictResolutionStrategy.localWins;
      print('✅ ConflictResolutionStrategy enum accessible: $strategy');
      
      print('🎉 Basic components test PASSED\n');
    } catch (e) {
      print('❌ Basic components test FAILED: $e\n');
      rethrow;
    }
  }
  
  /// Test 2: Backend adapter creation
  static void testBackendAdapters() {
    print('🧪 Testing USM Backend Adapters...');
    
    try {
      // Test PocketBase adapter
      final pbAdapter = PocketBaseSyncAdapter(
        baseUrl: 'http://localhost:8090',
      );
      print('✅ PocketBaseSyncAdapter created successfully');
      
      // Test Supabase adapter  
      final sbAdapter = SupabaseSyncAdapter(
        projectUrl: 'https://test.supabase.co',
        apiKey: 'test-api-key',
      );
      print('✅ SupabaseSyncAdapter created successfully');
      
      // Test Firebase adapter
      final fbAdapter = FirebaseSyncAdapter(
        projectId: 'test-project',
      );
      print('✅ FirebaseSyncAdapter created successfully');
      
      print('🎉 Backend adapters test PASSED\n');
    } catch (e) {
      print('❌ Backend adapters test FAILED: $e\n');
      rethrow;
    }
  }
  
  /// Test 3: Service instantiation
  static void testServices() {
    print('🧪 Testing USM Services...');
    
    try {
      // Test sync operation config
      final syncConfig = SyncOperationConfig(
        batchSize: 100,
        maxRetries: 3,
      );
      print('✅ SyncOperationConfig created successfully');
      
      // Test sync queue
      final syncQueue = SyncQueue();
      print('✅ SyncQueue created successfully');
      
      // Test conflict resolver
      final resolver = ConflictResolver(
        strategy: ConflictResolutionStrategy.intelligentMerge,
      );
      print('✅ ConflictResolver created successfully');
      
      print('🎉 Services test PASSED\n');
    } catch (e) {
      print('❌ Services test FAILED: $e\n');
      rethrow;
    }
  }
  
  /// Test 4: Complete integration test
  static void testCompleteIntegration() {
    print('🧪 Testing USM Complete Integration...');
    
    try {
      // Create complete configuration
      final config = SyncBackendConfiguration(
        configId: 'integration-test',
        displayName: 'Integration Test Config',
        backendType: 'pocketbase',
        baseUrl: 'http://localhost:8090',
        projectId: 'test-integration',
      );
      
      // Create adapter with config
      final adapter = PocketBaseSyncAdapter(
        baseUrl: config.baseUrl,
      );
      
      // Create sync service
      final syncConfig = SyncOperationConfig(
        batchSize: 50,
        maxRetries: 2,
      );
      
      // Test that all components work together
      print('✅ Configuration: ${config.displayName}');
      print('✅ Adapter: ${adapter.runtimeType}');
      print('✅ Sync Config: Batch size ${syncConfig.batchSize}');
      
      print('🎉 Complete integration test PASSED\n');
    } catch (e) {
      print('❌ Complete integration test FAILED: $e\n');
      rethrow;
    }
  }
  
  /// Run all tests
  static void runAllTests() {
    print('🚀 Starting USM Package Integration Tests...\n');
    
    testBasicComponents();
    testBackendAdapters();
    testServices();
    testCompleteIntegration();
    
    print('🎉 ALL USM INTEGRATION TESTS COMPLETED SUCCESSFULLY! 🎉');
  }
}
```

### Step 5: Update Main App to Run Tests
Update `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'usm_integration_test.dart';

void main() {
  // Run USM integration tests before starting app
  try {
    USMIntegrationTest.runAllTests();
  } catch (e) {
    print('💥 USM Integration tests failed: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'USM Package Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'USM Package Integration Test'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _testStatus = 'Tap button to run USM tests';

  void _runUSMTests() {
    setState(() {
      _testStatus = 'Running USM tests...';
    });
    
    try {
      USMIntegrationTest.runAllTests();
      setState(() {
        _testStatus = '✅ All USM tests passed! Check console for details.';
      });
    } catch (e) {
      setState(() {
        _testStatus = '❌ USM tests failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'USM Package Integration Test',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _testStatus,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _runUSMTests,
        tooltip: 'Run USM Tests',
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}
```

### Step 6: Run the Tests

#### Option A: Run via Flutter App
```bash
# Run the Flutter app - tests will execute on startup and via button
flutter run
```

#### Option B: Run via Flutter Tests
Create `test/usm_package_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';

void main() {
  group('USM Package Integration Tests', () {
    test('Basic components can be instantiated', () {
      final config = SyncBackendConfiguration(
        configId: 'test',
        displayName: 'Test',
        backendType: 'test',
        baseUrl: 'http://test.com',
        projectId: 'test',
      );
      
      expect(config, isA<SyncBackendConfiguration>());
      expect(config.configId, equals('test'));
      expect(SyncMode.manual, isA<SyncMode>());
      expect(ConflictResolutionStrategy.localWins, isA<ConflictResolutionStrategy>());
    });
    
    test('Backend adapters can be created', () {
      final pbAdapter = PocketBaseSyncAdapter(baseUrl: 'http://localhost:8090');
      final sbAdapter = SupabaseSyncAdapter(
        projectUrl: 'https://test.supabase.co',
        apiKey: 'test-key',
      );
      
      expect(pbAdapter, isA<PocketBaseSyncAdapter>());
      expect(sbAdapter, isA<SupabaseSyncAdapter>());
    });
    
    test('Services can be instantiated', () {
      final syncQueue = SyncQueue();
      final resolver = ConflictResolver(
        strategy: ConflictResolutionStrategy.localWins,
      );
      
      expect(syncQueue, isA<SyncQueue>());
      expect(resolver, isA<ConflictResolver>());
    });
  });
}
```

Then run:
```bash
flutter test
```

## ✅ Expected Results

### Success Indicators
When tests pass, you should see:
- ✅ All USM components import successfully
- ✅ Configuration objects can be created
- ✅ Backend adapters instantiate without errors
- ✅ Service classes work properly
- ✅ No compilation or runtime errors

### Console Output Example
```
🚀 Starting USM Package Integration Tests...

🧪 Testing USM Basic Components...
✅ SyncBackendConfiguration created successfully
✅ SyncMode enum accessible: SyncMode.manual
✅ ConflictResolutionStrategy enum accessible: ConflictResolutionStrategy.localWins
🎉 Basic components test PASSED

🧪 Testing USM Backend Adapters...
✅ PocketBaseSyncAdapter created successfully
✅ SupabaseSyncAdapter created successfully
✅ FirebaseSyncAdapter created successfully
🎉 Backend adapters test PASSED

🧪 Testing USM Services...
✅ SyncOperationConfig created successfully
✅ SyncQueue created successfully
✅ ConflictResolver created successfully
🎉 Services test PASSED

🧪 Testing USM Complete Integration...
✅ Configuration: Integration Test Config
✅ Adapter: PocketBaseSyncAdapter
✅ Sync Config: Batch size 50
🎉 Complete integration test PASSED

🎉 ALL USM INTEGRATION TESTS COMPLETED SUCCESSFULLY! 🎉
```

## 🚨 Troubleshooting

### Common Issues & Solutions

#### 1. Package Not Found Error
```
Error: Package 'universal_sync_manager' not found
```
**Solution**: Check the path in `pubspec.yaml` is correct relative to your test project.

#### 2. Import Errors
```
Error: 'package:universal_sync_manager/universal_sync_manager.dart' not found
```
**Solution**: Run `flutter pub get` and ensure USM package has proper export structure.

#### 3. Class Not Found
```
Error: 'SyncBackendConfiguration' isn't defined
```
**Solution**: Verify USM package exports are correct in `lib/universal_sync_manager.dart`.

#### 4. Flutter SDK Version Issues
```
Error: The current Dart SDK version is...
```
**Solution**: Ensure both projects use Flutter 3.35.2 or later.

## 🎯 Success Criteria

The USM package integration is successful when:
1. ✅ Package imports without errors
2. ✅ All core classes can be instantiated
3. ✅ Backend adapters create successfully  
4. ✅ Services and configurations work
5. ✅ No compilation or runtime errors
6. ✅ Tests pass in both app and test runner

## 📝 Notes for Claude Sonnet

- Always run `flutter pub get` after modifying `pubspec.yaml`
- Check console output for detailed test results
- Verify path dependencies are correct for your file structure
- Tests should complete within 5-10 seconds
- If any test fails, check the error message for specific component issues

This guide provides comprehensive validation that the USM package works correctly when imported into other Flutter projects.
