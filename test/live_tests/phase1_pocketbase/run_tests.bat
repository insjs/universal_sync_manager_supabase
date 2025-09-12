@echo off
REM test/live_tests/phase1_pocketbase/run_tests.bat

echo 🚀 USM Live Tests - Phase 1: PocketBase Integration
echo ==================================================
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

echo.
echo 🔧 Phase 1: PocketBase Setup
echo ----------------------------

REM Run PocketBase setup
cd setup
dart pocketbase_setup.dart --generate-data
if %errorlevel% neq 0 (
    echo ❌ PocketBase setup failed
    exit /b 1
)
echo ✅ PocketBase setup completed
cd ..

echo.
echo 🧪 Phase 2: Live Sync Tests
echo ---------------------------

REM Run sync tests
cd tests
dart sync_tests.dart
if %errorlevel% neq 0 (
    echo ❌ Sync tests failed
    exit /b 1
)
echo ✅ Sync tests completed
cd ..

echo.
echo 📊 Phase 3: Results Analysis
echo ----------------------------

REM Show test results if they exist
if exist "tests\results\" (
    echo 📄 Test results available in tests\results\
    for /f %%i in ('dir /b /o-d tests\results\test_report_*.json 2^>nul') do (
        echo Latest report: tests\results\%%i
        goto :found_report
    )
    :found_report
) else (
    echo ⚠️ Results directory not found
)

echo.
echo 🎉 USM Live Tests Phase 1 Completed!
echo.
echo 💡 Next Steps:
echo    1. Review test results in tests\results\
echo    2. Check PocketBase Admin UI for created test data
echo    3. Run additional tests as needed
echo    4. Proceed to Phase 2 (Additional Backend Testing)

pause
