# USM Package Testing Checklist for Claude Sonnet

## 🎯 Quick Testing Checklist

Use this checklist to systematically test USM package integration:

### Phase 1: Setup ✅
- [ ] Navigate to test project directory
- [ ] Add USM dependency to `pubspec.yaml`:
  ```yaml
  dependencies:
    universal_sync_manager:
      path: ../universal_sync_manager  # Adjust path
  ```
- [ ] Run `flutter pub get`
- [ ] Verify no errors in pub get output

### Phase 2: Basic Import Test ✅
- [ ] Create test file with USM import:
  ```dart
  import 'package:universal_sync_manager/universal_sync_manager.dart';
  ```
- [ ] Try to compile/analyze the file
- [ ] Confirm no import errors

### Phase 3: Component Instantiation Test ✅
Test each component type:
- [ ] **Configuration**: `SyncBackendConfiguration` with required params
- [ ] **Enums**: `SyncMode.manual`, `ConflictResolutionStrategy.localWins`  
- [ ] **Adapters**: `PocketBaseSyncAdapter`, `SupabaseSyncAdapter`
- [ ] **Services**: `SyncQueue`, `ConflictResolver`

### Phase 4: Integration Test ✅
- [ ] Create complete test file (use code from guide)
- [ ] Run via `flutter run` or `flutter test`
- [ ] Verify all console outputs show ✅
- [ ] Confirm no runtime errors

## 🚨 Common Issues & Quick Fixes

| Issue | Quick Fix |
|-------|-----------|
| Package not found | Check path in pubspec.yaml, run `flutter pub get` |
| Import errors | Verify USM package exports, check file exists |
| Class not defined | Run `flutter clean && flutter pub get` |
| Runtime errors | Check USM package version compatibility |

## ✅ Success Indicators

When everything works correctly, you should see:
1. No compilation errors
2. All classes can be imported
3. Components instantiate without exceptions
4. Console shows success messages (✅)
5. Tests complete in under 10 seconds

## 🔧 Claude Sonnet Command Sequence

Follow this exact sequence for reliable testing:

```bash
# 1. Setup
cd /path/to/test/project
flutter pub get

# 2. Quick validation (if validation script available)
dart ../universal_sync_manager/validate_usm_package.dart

# 3. Run integration tests
flutter run
# OR
flutter test

# 4. Check results
# Look for ✅ symbols in console output
# Verify no ❌ error messages
```

## 📋 Expected Output Pattern

Success output should follow this pattern:
```
🚀 Starting USM Package Integration Tests...
🧪 Testing USM Basic Components...
✅ [Component] created successfully
✅ [Component] created successfully
🎉 [Test Group] test PASSED
... (repeat for each test group)
🎉 ALL USM INTEGRATION TESTS COMPLETED SUCCESSFULLY! 🎉
```

## 🎯 One-Command Test

For quick validation, create and run this minimal test:

```dart
// minimal_usm_test.dart
import 'package:universal_sync_manager/universal_sync_manager.dart';

void main() {
  try {
    final config = SyncBackendConfiguration(
      configId: 'test', displayName: 'Test', backendType: 'test',
      baseUrl: 'http://test.com', projectId: 'test'
    );
    print('✅ USM package works! Config: ${config.displayName}');
  } catch (e) {
    print('❌ USM package failed: $e');
  }
}
```

Run with: `dart minimal_usm_test.dart`

If this works, the full integration will work too.
