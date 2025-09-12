@echo off
setlocal enabledelayedexpansion

REM Universal Sync Manager - Phase 1 PocketBase Live Tests (Windows)
REM This script uses the existing schema management tools for setup

echo 🚀 Universal Sync Manager - Phase 1 PocketBase Live Tests
echo =========================================================

REM Change to the setup directory
cd /d "%~dp0setup"

echo 📋 Step 1: Setting up PocketBase test schemas...
dart setup_with_schema_tools.dart

if !errorlevel! neq 0 (
    echo ❌ PocketBase setup failed. Please check the output above.
    exit /b 1
)

echo.
echo ✅ PocketBase setup completed successfully!
echo.

REM Change to tests directory
cd /d "%~dp0tests"

echo 📋 Step 2: Running live tests...
echo.

REM Run each test
echo 🧪 Running Sync Tests...
dart sync_tests.dart

if !errorlevel! equ 0 (
    echo.
    echo 🎉 All Phase 1 PocketBase live tests completed successfully!
    echo.
    echo 📊 Summary:
    echo    ✅ PocketBase setup: Success
    echo    ✅ Live sync tests: Success
    echo.
    echo 🚀 Ready for Phase 2 development!
) else (
    echo.
    echo ❌ Some tests failed. Please check the output above.
    exit /b 1
)

pause
