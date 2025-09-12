# USM Package Validation Scripts Usage Guide

This document explains how to use the two validation scripts for testing the Universal Sync Manager (USM) package.

## 🎯 Scripts Overview

### 1. `validate_usm_structure.dart` 
**Location**: Run from USM package directory  
**Purpose**: Validates the USM package structure itself

```bash
# From USM package directory
dart validate_usm_structure.dart
```

**What it checks:**
- ✅ USM package directory structure exists
- ✅ Main export file (`lib/universal_sync_manager.dart`) contains all required exports
- ✅ All key component files exist in correct locations
- ✅ Basic structure validation

### 2. `validate_usm_package.dart`
**Location**: Run from a Flutter project that uses USM  
**Purpose**: Validates USM package integration in consumer projects

```bash
# From your Flutter project directory that uses USM
dart validate_usm_package.dart
```

**What it checks:**
- ✅ Current directory is a Flutter project
- ✅ USM dependency is present in `pubspec.yaml`
- ✅ Packages are installed correctly
- ✅ USM imports work with `flutter test`

## 🚀 Usage Workflow

### For USM Package Development:
```bash
# 1. Validate the USM package structure
cd /path/to/universal_sync_manager
dart validate_usm_structure.dart
```

### For Consumer Project Testing:
```bash
# 1. Create/navigate to test Flutter project
flutter create my_test_project
cd my_test_project

# 2. Add USM dependency to pubspec.yaml
echo "dependencies:
  flutter:
    sdk: flutter
  universal_sync_manager:
    path: ../universal_sync_manager" >> pubspec.yaml

# 3. Install dependencies
flutter pub get

# 4. Validate USM integration
dart validate_usm_package.dart
```

## ✅ Expected Results

### `validate_usm_structure.dart` Output:
```
🚀 USM Package Structure Validation
===================================

📋 Step 1: Validating USM package structure...
✅ USM package structure is valid
📋 Step 2: Validating main export file...
✅ Main export file contains all required exports
📋 Step 3: Validating component files exist...
✅ All key component files exist
📋 Step 4: Testing basic import functionality...
⚠️  Flutter not available in PATH, skipping import test
💡 Import validation should be done in a consumer project
✅ Package structure validation completed successfully

🎉 USM Package structure validation completed successfully!
```

### `validate_usm_package.dart` Output:
```
🚀 USM Package Validation Script
================================

📋 Step 1: Checking Flutter project...
✅ Flutter project detected
📋 Step 2: Checking USM dependency...
✅ USM dependency found in pubspec.yaml
📋 Step 3: Checking if packages are installed...
✅ USM package installed and available
📋 Step 4: Validating USM imports...
✅ USM imports work correctly

🎉 USM Package validation completed!
```

## 🔧 Troubleshooting

### Common Issues:

**1. "Flutter not available in PATH"**
- This is normal when running `validate_usm_structure.dart`
- Import testing should be done in consumer projects

**2. "USM package not found in pubspec.yaml"**
- Make sure you're running `validate_usm_package.dart` from a Flutter project
- Add USM dependency to your `pubspec.yaml`

**3. "Import test failed"**
- Run `flutter pub get` to ensure dependencies are installed
- Check that the path to USM package is correct

### Flutter Test vs Dart Test:
- ✅ **Use `flutter test`** for testing Flutter packages that import Flutter dependencies
- ❌ **Don't use `dart`** for running tests that import Flutter packages (will fail with missing type errors)

## 📝 Notes

- Both scripts use `flutter test` internally for proper Flutter package testing
- The scripts include proper error handling for missing Flutter SDK
- Consumer project testing provides the most accurate validation of USM functionality
- Package structure validation ensures correct file organization and exports
