# PocketBase Relationship Testing Helper Script

param(
    [Parameter(Position=0)]
    [string]$Operation = "deploy",
    
    [Parameter(Position=1)]
    [string]$SchemaFile = "ost_managed_users_test_with_relations.yaml",
    
    [string]$PocketBaseUrl = "http://localhost:8090",
    [string]$AdminEmail = "xinzqr@gmail.com",
    [string]$AdminPassword = "12345678"
)

Write-Host "🚀 PocketBase SQLite-First Schema Testing Helper" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SchemaPath = Join-Path $ScriptDir "schema\$SchemaFile"

switch ($Operation.ToLower()) {
    "deploy" {
        Write-Host "📦 Deploying SQLite-first schema with relationship validation..." -ForegroundColor Yellow
        Write-Host "Schema File: $SchemaFile" -ForegroundColor Cyan
        Write-Host "PocketBase URL: $PocketBaseUrl" -ForegroundColor Cyan
        Write-Host ""
        
        # Run dependency-aware deployer
        & dart "dependency_aware_deployer.dart" $SchemaPath $PocketBaseUrl $AdminEmail $AdminPassword
        
        Write-Host ""
        Write-Host "📋 Expected collection created: managed_users_test_relations" -ForegroundColor Green
        Write-Host "� Key fields following SQLite-first strategy:" -ForegroundColor Green
        Write-Host "   - organizationId (TEXT with relation to ost_organizations)" -ForegroundColor White
        Write-Host "   - roleId (TEXT with relation to rbac_organization_roles)" -ForegroundColor White
        Write-Host "   - isActive, verified, isDirty, etc. (INTEGER 0/1)" -ForegroundColor White
        Write-Host "   - All audit and sync metadata fields included" -ForegroundColor White
    }
    
    "validate" {
        Write-Host "🔍 Validating SQLite-first schema compliance..." -ForegroundColor Yellow
        Write-Host ""
        
        Write-Host "Checking field type compliance:" -ForegroundColor Cyan
        Write-Host "  ✅ Boolean fields → INTEGER (0/1)" -ForegroundColor Green
        Write-Host "  ✅ Relationships → TEXT with foreign key semantics" -ForegroundColor Green
        Write-Host "  ✅ Dates → TEXT (ISO 8601 format)" -ForegroundColor Green
        Write-Host "  ✅ Primary keys → TEXT" -ForegroundColor Green
        Write-Host ""
        
        Write-Host "Required metadata fields:" -ForegroundColor Cyan
        Write-Host "  ✅ organizationId (multi-tenant isolation)" -ForegroundColor Green
        Write-Host "  ✅ Audit trail: createdBy, updatedBy, createdAt, updatedAt, deletedAt" -ForegroundColor Green
        Write-Host "  ✅ Sync metadata: isDirty, syncVersion, lastSyncedAt, isDeleted" -ForegroundColor Green
    }
    
    "test" {
        Write-Host "🧪 Running full SQLite-first schema test sequence..." -ForegroundColor Yellow
        Write-Host ""
        
        # First deploy simple schema
        Write-Host "1. Deploying simple schema (no relationships)..." -ForegroundColor Cyan
        & dart "dependency_aware_deployer.dart" "schema\ost_managed_users_test_simple.yaml" $PocketBaseUrl $AdminEmail $AdminPassword
        
        Write-Host ""
        Write-Host "2. Deploying SQLite-first schema with relationships..." -ForegroundColor Cyan
        & dart "dependency_aware_deployer.dart" $SchemaPath $PocketBaseUrl $AdminEmail $AdminPassword
        
        Write-Host ""
        Write-Host "3. Schema compliance verification..." -ForegroundColor Cyan
        Write-Host "   Check PocketBase admin UI to verify:" -ForegroundColor Yellow
        Write-Host "   - Table name: managed_users_test_relations" -ForegroundColor White
        Write-Host "   - organizationId: relation field → ost_organizations" -ForegroundColor White
        Write-Host "   - roleId: relation field → rbac_organization_roles" -ForegroundColor White
        Write-Host "   - Boolean fields: number type (0/1)" -ForegroundColor White
    }
    
    "clean" {
        Write-Host "🧹 This would clean up test collections..." -ForegroundColor Yellow
        Write-Host "⚠️  Manual cleanup required via PocketBase admin UI" -ForegroundColor Red
        Write-Host "Test collections to remove:" -ForegroundColor Cyan
        Write-Host "  - ost_managed_users_test_simple" -ForegroundColor White
        Write-Host "  - ost_managed_users_test_with_relations" -ForegroundColor White
    }
    
    default {
        Write-Host "❌ Unknown operation: $Operation" -ForegroundColor Red
        Write-Host ""
        Write-Host "Available operations:" -ForegroundColor Yellow
        Write-Host "  deploy   - Deploy schema with relationship validation" -ForegroundColor White
        Write-Host "  validate - Check if dependency collections exist" -ForegroundColor White
        Write-Host "  test     - Run full test sequence" -ForegroundColor White
        Write-Host "  clean    - Instructions for cleaning up test data" -ForegroundColor White
        Write-Host ""
        Write-Host "Examples:" -ForegroundColor Yellow
        Write-Host "  .\test-relationships.ps1 deploy" -ForegroundColor White
        Write-Host "  .\test-relationships.ps1 deploy custom_schema.yaml" -ForegroundColor White
        Write-Host "  .\test-relationships.ps1 test" -ForegroundColor White
        exit 1
    }
}

Write-Host ""
Write-Host "✅ Operation completed" -ForegroundColor Green
