@echo off
REM Schema Management Helper Scripts for Windows
REM
REM Usage:
REM   schema-deploy.bat pocketbase schema/audit_items.yaml
REM   schema-deploy.bat supabase schema/audit_items.yaml
REM   schema-deploy.bat both schema/audit_items.yaml
REM   schema-deploy.bat extract

if "%1"=="" (
    echo Usage: schema-deploy.bat [pocketbase^|supabase^|both^|extract] [schema_file.yaml]
    echo.
    echo Examples:
    echo   schema-deploy.bat pocketbase schema/audit_items.yaml
    echo   schema-deploy.bat supabase schema/audit_items.yaml  
    echo   schema-deploy.bat both schema/audit_items.yaml
    echo   schema-deploy.bat extract
    echo.
    echo Make sure to set environment variables for Supabase:
    echo   set SUPABASE_URL=https://your-project.supabase.co
    echo   set SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
    exit /b 1
)

set TARGET=%1
set SCHEMA_FILE=%2

REM Check if this is an extract operation (no schema file needed)
if /i "%TARGET%"=="extract" (
    echo 🚀 Schema Management Tool
    echo 🎯 Target: Extract from PocketBase
    echo.
    echo 🔍 Extracting schemas from PocketBase...
    dart tools/pocketbase_schema_extractor.dart
    goto :end
)

REM For deploy operations, schema file is required
if "%2"=="" (
    echo Error: Schema file not specified for deploy operation
    exit /b 1
)

echo 🚀 Schema Management Tool
echo 📁 Schema file: %SCHEMA_FILE%
echo 🎯 Target: %TARGET%
echo.

if /i "%TARGET%"=="pocketbase" (
    echo 📦 Deploying to PocketBase...
    dart tools/pocketbase_schema_manager.dart tools/%SCHEMA_FILE%
    goto :end
)

if /i "%TARGET%"=="supabase" (
    echo 🐘 Deploying to Supabase...
    dart tools/supabase_schema_manager.dart tools/%SCHEMA_FILE%
    goto :end
)

if /i "%TARGET%"=="both" (
    echo 📦 Deploying to PocketBase...
    dart tools/pocketbase_schema_manager.dart tools/%SCHEMA_FILE%
    if errorlevel 1 (
        echo ❌ PocketBase deployment failed
        exit /b 1
    )
    
    echo.
    echo 🐘 Deploying to Supabase...
    dart tools/supabase_schema_manager.dart tools/%SCHEMA_FILE%
    if errorlevel 1 (
        echo ❌ Supabase deployment failed
        exit /b 1
    )
    
    echo.
    echo ✅ Both deployments completed successfully
    goto :end
)

echo ❌ Invalid target: %TARGET%
echo Valid targets: pocketbase, supabase, both

:end
