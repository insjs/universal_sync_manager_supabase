@echo off
REM test/live_tests/phase1_pocketbase/run_tests_sdk.bat

echo 🚀 USM Live Tests - Phase 1: PocketBase Integration (SDK)
echo ========================================================
echo.

REM Check if Dart is available
dart --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Dart is not available. Please install Dart SDK.
    exit /b 1
)

echo ✅ Dart SDK is available

REM Check if config file exists
if not exist "setup\config.yaml" (
    echo ⚠️ Configuration file not found. Please run setup first.
    exit /b 1
)

echo ✅ Configuration file found

REM Step 1: Setup PocketBase schemas using existing tools
echo.
echo 📋 Step 1: Setting up PocketBase schemas...
echo.

cd ..\..\..\tools
dart pocketbase_schema_manager.dart
if %errorlevel% neq 0 (
    echo ❌ Schema setup failed
    cd ..\test\live_tests\phase1_pocketbase
    exit /b 1
)

cd ..\test\live_tests\phase1_pocketbase
echo ✅ Schema setup completed

REM Step 2: Run live sync tests with PocketBase SDK
echo.
echo 🧪 Step 2: Running live sync tests with PocketBase SDK...
echo.

dart tests\sync_tests_with_sdk.dart
if %errorlevel% neq 0 (
    echo ❌ Sync tests failed
    exit /b 1
)

echo ✅ All tests completed successfully!

echo.
echo 🎯 Summary:
echo ✓ Schema management using existing tools
echo ✓ Live sync tests using PocketBase SDK
echo ✓ HTTPS/TLS support built-in
echo ✓ Better error handling and authentication
echo.

pause
