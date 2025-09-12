
## ✅ **Backend-Agnostic Database Strategy (SQLite-First)**

This strategy assumes:

* SQLite is your **offline-first, primary data layer**.
* Other backends (PocketBase, Firebase, Supabase) are **sync targets**.
* The goal is to minimize field mapping inconsistencies and conversion logic.

---

### 📦 **Part 1: Field Type Strategy**

| Concept       | SQLite Type | Unified Format                           | Notes                                                              |
| ------------- | ----------- | ---------------------------------------- | ------------------------------------------------------------------ |
| **ID**        | `TEXT`      | UUID / custom ID string                  | Use deterministic `TEXT` primary keys to ensure sync compatibility |
| **Boolean**   | `INTEGER`   | `0` / `1`                                | Use numeric `0/1` instead of `bool` types in all backends          |
| **Integer**   | `INTEGER`   | `INTEGER`                                | Direct mapping                                                     |
| **Float**     | `REAL`      | `REAL` or `number`                       | Consistent across backends                                         |
| **Text**      | `TEXT`      | `TEXT` or `string`                       | Can store long text, enum values, JSON                             |
| **DateTime**  | `TEXT`      | ISO 8601 string (`yyyy-MM-ddTHH:mm:ssZ`) | Use ISO format for compatibility with Firebase, Supabase, PB. save as UTC time     |
| **JSON**      | `TEXT`      | JSON-encoded `string`                    | Store as serialized JSON text, parse on usage                      |
| **Enum**      | `TEXT`      | `TEXT`                                   | Store enum as strings across systems                               |
| **Relations** | `TEXT`      | Foreign key ID                           | No auto-relations; all are manual references                       |

---

### ⚙️ **Part 2: Table Naming Conventions**

* **snake_case for ALL table names** (`audit_items`, `audit_templates`)
* Table names should be snake_case and plural for consistency

| Platform   | Recommended Table Name Format |
| ---------- | ----------------------------- |
| SQLite     | `audit_items`                 |
| PocketBase | `audit_items`                 |
| Supabase   | `audit_items`                 |
| Firebase   | `audit_items`                 |

**Note**: Always use `snake_case` for table names across all platforms and backends. This ensures consistency and compatibility.

---

### 🔄 **Part 3: Schema File Format (YAML/JSON)**

Use a **schema definition file** in YAML or JSON for each table:

```yaml
table: audit_items
fields:
  # Primary identifier
  - name: id
    type: text
    primaryKey: true

  # Multi-tenant isolation
  - name: organizationId
    type: text
    required: true

  # Business logic fields
  - name: question
    type: text

  - name: responseType
    type: text

  - name: isActive
    type: integer
    default: 1

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

From this definition, you can:

* Create SQLite schema
* Generate PocketBase or Supabase fields
* Define Dart model classes

---

### 🧱 **Part 4: Naming Rules**

| Entity      | Naming Rule       | Example               |
| ----------- | ----------------- | --------------------- |
| Table Name  | `snake_case`      | `audit_templates`     |
| Field Name  | `camelCase`       | `createdAt`           |
| Field Type  | SQLite-compatible | `text`, `integer`     |
| Primary Key | Always `text` ID  | `id TEXT PRIMARY KEY` |

---

### 🔄 **Part 5: Sync Field Requirements**

All tables should have the following **sync-related metadata fields** (based on `SyncableModel`):

| Field Name       | SQLite Type | Description                                    | Backend Handling                                |
| ---------------- | ----------- | ---------------------------------------------- | ----------------------------------------------- |
| `id`             | `TEXT`      | Unique identifier (PRIMARY KEY)               | Same across all backends                        |
| `organizationId` | `TEXT`      | Multi-tenant data isolation                    | **Pre-Auth**: TEXT field<br>**Post-Auth**: Relation to `ost_organizations` collection/table |
| `createdBy`      | `TEXT`      | User ID who created this record                | **Pre-Auth**: TEXT field<br>**Post-Auth**: Relation to `ost_managed_users` collection/table |
| `updatedBy`      | `TEXT`      | User ID who last updated this record           | **Pre-Auth**: TEXT field<br>**Post-Auth**: Relation to `ost_managed_users` collection/table |
| `createdAt`      | `TEXT`      | ISO timestamp when record was created          | Same across all backends                        |
| `updatedAt`      | `TEXT`      | ISO timestamp of last modification             | Same across all backends                        |
| `deletedAt`      | `TEXT`      | ISO timestamp when record was deleted (nullable) | Same across all backends                      |
| `lastSyncedAt`   | `TEXT`      | Last successful sync timestamp                 | Same across all backends                        |
| `isDirty`        | `INTEGER`   | `1` if pending sync, `0` if clean              | Convert to boolean in Supabase/PocketBase      |
| `syncVersion`    | `INTEGER`   | Incremental sync version number                | Same across all backends                        |
| `isDeleted`      | `INTEGER`   | `1` if soft deleted, `0` if active             | Convert to boolean in Supabase/PocketBase      |

#### **🔑 Important Relationship Handling Notes**

**1. SQLite Schema (Always TEXT)**
```sql
-- All fields remain TEXT in SQLite following SQLite-first strategy
CREATE TABLE my_table (
  id TEXT PRIMARY KEY,
  organizationId TEXT NOT NULL,
  createdBy TEXT NOT NULL,
  updatedBy TEXT NOT NULL,
  -- other fields...
  FOREIGN KEY (organizationId) REFERENCES ost_organizations(id),
  FOREIGN KEY (createdBy) REFERENCES ost_managed_users(id),
  FOREIGN KEY (updatedBy) REFERENCES ost_managed_users(id)
);
```

**2. Backend Implementation by Table Type**

**Pre-Auth Collections** (app configuration, localization, UI translations):
- Sync before user authentication
- Keep `organizationId`, `createdBy`, `updatedBy` as simple TEXT fields
- Examples: `cfg_ui_translation_keys`, `cfg_supported_locales`, `app_asset_files`

**Post-Auth Collections** (user data, organization-specific data):
- Sync after user authentication
- Convert to relationships in PocketBase/Supabase for API access rules
- Examples: `ost_managed_users`, `audit_items`, `rbac_organization_roles`

**3. YAML Schema Definition**
```yaml
# For Post-Auth tables, add relationship metadata
fields:
  - name: organizationId
    type: text
    required: true
    relationship:        # Add for Post-Auth tables only
      targetCollection: "ost_organizations"
      targetField: "id"
      cascadeDelete: false
  
  - name: createdBy
    type: text
    required: true
    relationship:        # Add for Post-Auth tables only
      targetCollection: "ost_managed_users"
      targetField: "id"
      cascadeDelete: false
```

**4. API Access Rules Benefits**
```javascript
// Enabled by Post-Auth relationships in PocketBase
"viewRule": "@request.auth.id = createdBy || @request.auth.organizationId = organizationId",
"updateRule": "@request.auth.id = createdBy",
"deleteRule": "@request.auth.id = createdBy"
```

These fields:

* Enable delta sync across all backends
* Avoid race conditions with optimistic concurrency
* Support both Pre-Auth and Post-Auth sync categories
* Maintain SQLite-first compatibility while enabling proper API access rules

---

### 🧩 **Part 6: Guidelines for Adding a New Table**

1. **Create Schema File** (YAML/JSON)
2. **Create SQLite Migration Script** using that schema
3. **Generate Dart Model** using same schema
4. **Add Sync Metadata Fields** to all tables
5. **Map Fields in PocketBase / Firebase** manually if needed
6. **Create Indexes** for any foreign key or lookup fields

---

### 🚀 Final Thought

You’ve nailed the core idea: treat SQLite as **the canonical model**, and let all other backends adapt to its rules. It will:

* Reduce friction in sync
* Keep schema evolution under control
* Ensure modular and portable data layers

Would you like a template schema file and generator script to follow this strategy?
