# Schema Management Helper Script for PowerShell
# 
# Usage:
#   .\schema-deploy.ps1 pocketbase schema/audit_items.yaml
#   .\schema-deploy.ps1 supabase schema/audit_items.yaml
#   .\schema-deploy.ps1 both schema/audit_items.yaml
#   .\schema-deploy.ps1 extract

param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet("pocketbase", "supabase", "both", "extract")]
    [string]$Target,
    
    [Parameter(Mandatory=$false, Position=1)]
    [string]$SchemaFile
)

function Write-ColoredText {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Deploy-ToPocketBase {
    param([string]$SchemaFile)
    
    Write-ColoredText "📦 Deploying to PocketBase..." "Cyan"
    $result = & dart tools/pocketbase_schema_manager.dart tools/$SchemaFile
    return $LASTEXITCODE -eq 0
}

function Deploy-ToSupabase {
    param([string]$SchemaFile)
    
    Write-ColoredText "🐘 Deploying to Supabase..." "Cyan"
    
    # Check if environment variables are set
    if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_SERVICE_ROLE_KEY) {
        Write-ColoredText "⚠️  Warning: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY environment variables not set" "Yellow"
        Write-ColoredText "   You can set them with:" "Yellow"
        Write-ColoredText "   `$env:SUPABASE_URL = 'https://your-project.supabase.co'" "Yellow"
        Write-ColoredText "   `$env:SUPABASE_SERVICE_ROLE_KEY = 'your-service-role-key'" "Yellow"
        Write-Host ""
    }
    
    $result = & dart tools/supabase_schema_manager.dart tools/$SchemaFile
    return $LASTEXITCODE -eq 0
}

function Extract-FromPocketBase {
    Write-ColoredText "🔍 Extracting schemas from PocketBase..." "Cyan"
    $result = & dart tools/pocketbase_schema_extractor.dart
    return $LASTEXITCODE -eq 0
}

# Main execution
Write-ColoredText "🚀 Schema Management Tool" "Green"

if ($Target -eq "extract") {
    Write-ColoredText "🎯 Target: Extract from PocketBase" "White"
    Write-Host ""
    
    $success = Extract-FromPocketBase
    if (-not $success) {
        Write-ColoredText "❌ Schema extraction failed" "Red"
        exit 1
    }
    
    Write-ColoredText "✅ Schema extraction completed successfully" "Green"
    exit 0
}

# For deploy operations, SchemaFile is required
if (-not $SchemaFile) {
    Write-ColoredText "❌ Schema file is required for deploy operations" "Red"
    Write-ColoredText "Usage: .\schema-deploy.ps1 [pocketbase|supabase|both] <schema_file>" "Yellow"
    exit 1
}

Write-ColoredText "📁 Schema file: $SchemaFile" "White"
Write-ColoredText "🎯 Target: $Target" "White"
Write-Host ""

# Check if schema file exists
if (-not (Test-Path "tools/$SchemaFile")) {
    Write-ColoredText "❌ Schema file not found: tools/$SchemaFile" "Red"
    exit 1
}

switch ($Target) {
    "pocketbase" {
        $success = Deploy-ToPocketBase $SchemaFile
        if (-not $success) {
            Write-ColoredText "❌ PocketBase deployment failed" "Red"
            exit 1
        }
    }
    
    "supabase" {
        $success = Deploy-ToSupabase $SchemaFile
        if (-not $success) {
            Write-ColoredText "❌ Supabase deployment failed" "Red"
            exit 1
        }
    }
    
    "both" {
        $pbSuccess = Deploy-ToPocketBase $SchemaFile
        if (-not $pbSuccess) {
            Write-ColoredText "❌ PocketBase deployment failed" "Red"
            exit 1
        }
        
        Write-Host ""
        $sbSuccess = Deploy-ToSupabase $SchemaFile
        if (-not $sbSuccess) {
            Write-ColoredText "❌ Supabase deployment failed" "Red"
            exit 1
        }
        
        Write-Host ""
        Write-ColoredText "✅ Both deployments completed successfully" "Green"
    }
}

Write-ColoredText "✅ Operation completed successfully" "Green"
