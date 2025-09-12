# Schema Management Tools

This directory contains tools for managing database schemas across different backends using YAML schema definitions.

## Overview

These scripts follow the **SQLite-First Backend-Agnostic Strategy** outlined in your documentation. They read YAML schema files and automatically create/update tables and collections in:

- **PocketBase** - Creates collections with appropriate field types
- **Supabase** - Creates PostgreSQL tables with proper SQL DDL

## Files

- `pocketbase_schema_manager.dart` - Manages PocketBase collections (create/update)
- `pocketbase_schema_extractor.dart` - Extracts existing PocketBase collections to YAML
- `supabase_schema_manager.dart` - Manages Supabase tables (create/update)
- `schema-deploy.ps1` - PowerShell helper script
- `schema-deploy.bat` - Batch file helper script
- `schema/` - Directory containing YAML schema definitions
- `schema/audit_items.yaml` - Example schema file
- `schema/audit_templates.yaml` - Additional example schema file

## Schema File Format

YAML files should follow this structure:

```yaml
table: table_name
fields:
  - name: id
    type: text
    primaryKey: true
  
  - name: organizationId
    type: text
    required: true
  
  - name: isActive
    type: integer
    default: 1

# Optional: Indexes for performance
indexes:
  - fields: [organizationId]
    name: idx_table_name_org
  - fields: [isActive, isDeleted]
    name: idx_table_name_active
```

### Supported Field Types

| YAML Type  | SQLite Type | PocketBase Type | Supabase Type |
|------------|-------------|-----------------|---------------|
| `text`     | `TEXT`      | `text`          | `TEXT`        |
| `integer`  | `INTEGER`   | `number`        | `INTEGER`     |
| `real`     | `REAL`      | `number`        | `REAL`        |
| `boolean`  | `INTEGER`   | `bool`          | `BOOLEAN`     |
| `datetime` | `TEXT`      | `date`          | `TIMESTAMPTZ` |
| `json`     | `TEXT`      | `json`          | `JSONB`       |

### Field Properties

- `name` - Field name (required)
- `type` - Data type (required)
- `primaryKey` - Boolean, marks as primary key
- `required` - Boolean, marks as NOT NULL
- `default` - Default value for the field

## Usage

### Prerequisites

Add these dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.1.0
  yaml: ^3.1.2
```

Run: `dart pub get`

### Windows Helper Scripts

For Windows users, we provide convenient helper scripts:

**PowerShell (Recommended):**
```powershell
# Deploy to PocketBase
.\tools\schema-deploy.ps1 pocketbase schema/audit_items.yaml

# Deploy to Supabase  
.\tools\schema-deploy.ps1 supabase schema/audit_items.yaml

# Deploy to both
.\tools\schema-deploy.ps1 both schema/audit_items.yaml

# Extract existing PocketBase collections to YAML
.\tools\schema-deploy.ps1 extract
```

**Batch File:**
```cmd
# Deploy to PocketBase
tools\schema-deploy.bat pocketbase schema/audit_items.yaml

# Deploy to Supabase
tools\schema-deploy.bat supabase schema/audit_items.yaml

# Deploy to both  
tools\schema-deploy.bat both schema/audit_items.yaml

# Extract existing PocketBase collections to YAML
tools\schema-deploy.bat extract
```

### PocketBase Schema Extractor

Extract existing PocketBase collections to YAML schema files:

```bash
# Basic usage with defaults
dart tools/pocketbase_schema_extractor.dart

# With custom PocketBase settings
dart tools/pocketbase_schema_extractor.dart http://localhost:8090 admin@example.com password123 tools/schema
```

**Default values:**
- PocketBase URL: `http://localhost:8090`
- Admin email: `admin@example.com`
- Admin password: `password123`
- Output directory: `tools/schema`

**Features:**
- ✅ Connects to existing PocketBase instance
- ✅ Extracts all non-system collections
- ✅ Converts PocketBase field types to YAML format
- ✅ Organizes fields by category (business, audit, sync)
- ✅ Suggests performance indexes
- ✅ Creates properly formatted YAML files

### PocketBase Schema Manager

```bash
# Basic usage with defaults
dart tools/pocketbase_schema_manager.dart tools/schema/audit_items.yaml

# With custom PocketBase settings
dart tools/pocketbase_schema_manager.dart tools/schema/audit_items.yaml http://localhost:8090 admin@example.com password123
```

**Default values:**
- PocketBase URL: `http://localhost:8090`
- Admin email: `admin@example.com`
- Admin password: `password123`

### Supabase Schema Manager

```bash
# Using environment variables (recommended)
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_SERVICE_ROLE_KEY="your-service-role-key"
dart tools/supabase_schema_manager.dart tools/schema/audit_items.yaml

# Using command line arguments
dart tools/supabase_schema_manager.dart tools/schema/audit_items.yaml https://your-project.supabase.co your-service-role-key
```

**Important:** You need the **service role key** (not anon key) to execute DDL statements in Supabase.

## Features

### PocketBase Extractor
- ✅ Authenticates with admin credentials
- ✅ Extracts all non-system collections
- ✅ Converts PocketBase types to YAML types
- ✅ Organizes fields by category (business, audit, sync)
- ✅ Suggests performance indexes based on field patterns
- ✅ Creates well-structured YAML files following the SQLite-first strategy

### PocketBase Manager
- ✅ Authenticates with admin credentials
- ✅ Creates new collections
- ✅ Updates existing collections (adds missing fields)
- ✅ Converts YAML types to PocketBase field types
- ✅ Preserves existing collection settings

### Supabase Manager
- ✅ Creates new tables with proper SQL DDL
- ✅ Updates existing tables (adds missing columns)
- ✅ Creates indexes for performance
- ✅ Converts YAML types to PostgreSQL types
- ✅ Uses environment variables for security

### Both Managers
- ✅ Validate YAML schema files
- ✅ Handle errors gracefully
- ✅ Provide detailed logging
- ✅ Support the sync metadata fields strategy

## Example Workflow

### Extracting from Existing PocketBase
1. **Extract existing collections** to YAML files:
   ```bash
   .\tools\schema-deploy.ps1 extract
   ```
2. **Review generated YAML files** in `tools/schema/`
3. **Modify as needed** for your SQLite-first strategy
4. **Deploy to other backends** as needed

### Creating New Schemas
1. **Define your schema** in `tools/schema/your_table.yaml`
2. **Test locally** with SQLite first
3. **Deploy to PocketBase**:
   ```bash
   .\tools\schema-deploy.ps1 pocketbase schema/your_table.yaml
   ```
4. **Deploy to Supabase**:
   ```bash
   .\tools\schema-deploy.ps1 supabase schema/your_table.yaml
   ```

## Sync Metadata Fields

All schemas should include the standard sync metadata fields for the backend-agnostic strategy:

```yaml
# Audit trail fields
- name: createdBy
  type: text
  required: true
- name: updatedBy
  type: text
  required: true
- name: createdAt
  type: text
- name: updatedAt
  type: text
- name: deletedAt
  type: text

# Sync metadata fields  
- name: lastSyncedAt
  type: text
- name: isDirty
  type: integer
  default: 1
- name: syncVersion
  type: integer
  default: 0
- name: isDeleted
  type: integer
  default: 0
```

## Security Notes

- **PocketBase**: Uses admin authentication with email/password
- **Supabase**: Requires service role key with DDL permissions
- **Never commit** credentials to version control
- **Use environment variables** for production deployments

## Error Handling

Both scripts include comprehensive error handling:
- Authentication failures
- Network connectivity issues
- Invalid YAML schemas
- SQL/API execution errors
- Missing permissions

### Common Issues

#### PocketBase Authentication Failed (404 Error)
If you get a 404 error during authentication, this usually means:
1. **Admin user doesn't exist** - Create a superuser via the PocketBase admin UI first
2. **Wrong credentials** - Double-check your email and password
3. **PocketBase version differences** - The scripts automatically try both new (`_superusers`) and legacy (`admins`) auth endpoints

**Solution:**
1. Open your PocketBase admin UI (usually `http://localhost:8090/_/`)
2. Create a superuser account if you haven't already (this replaces the old "admin" concept)
3. Use those exact credentials in the script
4. Make sure PocketBase is running and accessible

**Note:** Modern PocketBase uses `_superusers` collection for admin authentication instead of the old `/api/admins/` endpoint.

#### Complex Passwords with Special Characters
If your password contains special characters like `^`, `&`, `|`, etc., you may need to escape them or use quotes:

**PowerShell:**
```powershell
# Use single quotes to prevent PowerShell interpretation
dart tools/pocketbase_schema_extractor.dart http://localhost:8090 'your-email@example.com' '8PisxRwj43^Do^V2^V' tools/schema

# Or use double quotes with backtick escaping
dart tools/pocketbase_schema_extractor.dart http://localhost:8090 "your-email@example.com" "8PisxRwj43`^Do`^V2`^V" tools/schema
```

**Alternative:** Use a simpler temporary password for the extraction process.

#### Missing Fields in Extracted Schema
If extracted YAML files only contain the `id` field but your collections have more fields, this indicates:
1. **Authentication may have partially failed** - Check for any auth warnings
2. **Collection permissions** - Ensure the superuser has access to view collection schemas
3. **PocketBase API changes** - Check the debug output for collection field counts

#### Supabase Service Role Key Issues
- Make sure you're using the **service role key** (not anon key)
- The key must have DDL permissions to create/modify tables
- Set environment variables or pass as command line arguments

Check the console output for detailed error messages and troubleshooting information.

----

🚀 Usage Examples:
Extract Existing Collections:

# Using PowerShell helper (recommended)
.\tools\schema-deploy.ps1 extract

# Direct command
dart tools/pocketbase_schema_extractor.dart

# With custom settings
dart tools/pocketbase_schema_extractor.dart http://localhost:8090 admin@example.com password123 tools/schema

Updated Helper Scripts:
Both PowerShell and batch scripts now support extraction:

# Extract from PocketBase
.\tools\schema-deploy.ps1 extract

# Still supports deploy operations  
.\tools\schema-deploy.ps1 pocketbase schema/audit_items.yaml
.\tools\schema-deploy.ps1 supabase schema/audit_items.yaml
.\tools\schema-deploy.ps1 both schema/audit_items.yaml