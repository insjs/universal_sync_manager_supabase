# Database Field Names Migration (camelCase → snake_case)

**Scope**: `lib/` directory only - Focus on database field names, not Dart property names

Based on code analysis, we only need to migrate database field references from camelCase to snake_case in JSON serialization, backend adapters, and field mapping logic.

## **REVISED Phase Plan: Database Field Names Migration**
**Target**: `D:\_development\personal_projects\has_main\universal_sync_manager_supabase\lib` **ONLY**

### **Phase 1: Audit and Field Mapping** 
**Goal**: Identify all database field references in the `lib` directory

#### **Task 1.1: Database Sync Fields (Actual Database Table Fields Only)** **[DONE]** ✅

**CONFIRMED FIELDS REQUIRING MIGRATION (Based on Code Audit):**

**Multi-tenant isolation:**
- `organizationId` → `organization_id` ✅ (11 locations found)

**Audit trail fields:**
- `createdBy` → `created_by` ✅ (16 locations found)
- `updatedBy` → `updated_by` ✅ (16 locations found)
- `createdAt` → `created_at` ✅ (20+ locations found)
- `updatedAt` → `updated_at` ✅ (20+ locations found)

**Sync metadata fields:**
- `syncVersion` → `sync_version` ✅ (8 locations found)

**NOT CURRENTLY USED (Defer for now):**
- `deletedAt` → `deleted_at` ❌ (0 locations found)
- `isDirty` → `is_dirty` ❌ (0 locations found)
- `isDeleted` → `is_deleted` ❌ (0 locations found)
- `lastSyncedAt` → `last_synced_at` ❌ (0 locations found)

#### **Task 1.2: File Inventory in lib/ directory** **[DONE]** ✅

**DETAILED FILE ANALYSIS:**

**Models (`lib/src/models/`):**
- `usm_sync_event.dart` ✅
  - `organizationId`: Line 352 - `organizationId: json['organizationId'] as String?`
  - `syncVersion`: Line 353 - `syncVersion: json['syncVersion'] as int?`
  - **Impact**: JSON serialization/deserialization methods

- `usm_auth_context.dart` ✅
  - `organizationId`: Line 201 - `organizationId: json['organizationId'] as String?` 
  - `createdAt`: Line 205 - `createdAt: DateTime.parse(json['createdAt'] as String)`
  - **Impact**: Auth context JSON serialization

**Adapters (`lib/src/adapters/`):**
- `usm_supabase_sync_adapter.dart` ✅
  - Line 708: `mapped['createdAt'] = data['created_at'];` (transforms snake_case → camelCase)
  - Line 711: `mapped['updatedAt'] = data['updated_at'];` (transforms snake_case → camelCase)
  - **Impact**: Field mapping between Supabase and USM formats

- `usm_pocketbase_sync_adapter.dart` ✅
  - Line 679: `mapped['createdAt'] = data['created'];` (transforms PocketBase → camelCase)
  - Line 682: `mapped['updatedAt'] = data['updated'];` (transforms PocketBase → camelCase)
  - **Impact**: Field mapping between PocketBase and USM formats

- `usm_firebase_sync_adapter.dart` ✅
  - Line 37: Comment references `(organizationId, createdBy, updatedAt)`
  - **Impact**: Field transformation documentation

**Services (`lib/src/services/`):**
- `usm_universal_sync_operation_service.dart` ✅
  - Line 563: `localVersion: data['syncVersion'] ?? 0,`
  - Line 564: `remoteVersion: data['syncVersion'] ?? 0,`
  - **Impact**: Core sync version conflict detection

- `usm_conflict_resolver*.dart` ✅ (3 files)
  - Lines 441, 443: `'createdBy', 'updatedBy'` field references
  - **Impact**: Conflict resolution field exclusions

**Configuration (`lib/src/config/`):**
- `usm_sync_strategies.dart` ✅
  - Line 316: `data['syncVersion'] = (data['syncVersion'] as int? ?? 0) + 1;`
  - Line 384: `final localTime = conflict.localData['updatedAt'] as String?;`
  - Line 385: `final remoteTime = conflict.remoteData['updatedAt'] as String?;`
  - Line 401-402: `conflict.localData['syncVersion']` and `conflict.remoteData['syncVersion']`
  - **Impact**: Version increment and timestamp conflict resolution

- `usm_entity_discovery.dart` ✅
  - Line 235, 247: `const auditFields = {'createdBy', 'updatedBy', 'createdAt', 'updatedAt'};`
  - **Impact**: Audit field definitions and discovery

**Interfaces (`lib/src/interfaces/`):**
- `usm_sync_backend_adapter.dart` ✅
  - Line 121: `filters['organizationId'] = organizationId;`
  - **Impact**: Multi-tenant filtering logic

**MIGRATION IMPACT ANALYSIS:**
- **Critical**: Backend adapters (field mapping foundation)
- **High**: JSON serialization in models  
- **Medium**: Service layer data access
- **Low**: Configuration and discovery definitions

### **Phase 2: Backend Adapter Updates**
**Goal**: Update field transformation in adapters first (foundation)

#### **Task 2.1: Supabase Adapter**
- File: `lib/src/adapters/usm_supabase_sync_adapter.dart`
- Update field mapping: `mapped['createdAt'] = data['created_at']`
- Update all camelCase → snake_case transformations

#### **Task 2.2: PocketBase Adapter** 
- File: `lib/src/adapters/usm_pocketbase_sync_adapter.dart`
- Update field mapping: `mapped['createdAt'] = data['created']` → `mapped['created_at'] = data['created']`
- Update field mapping: `mapped['updatedAt'] = data['updated']` → `mapped['updated_at'] = data['updated']`

#### **Task 2.3: Firebase Adapter**
- File: `lib/src/adapters/usm_firebase_sync_adapter.dart`
- Update field transformations for audit and sync fields

### **Phase 3: Core Models Updates**
**Goal**: Update JSON serialization in model classes

#### **Task 3.1: Sync Event Model**
- File: `lib/src/models/usm_sync_event.dart`
- Update JSON methods: `organizationId` → `organization_id`, `syncVersion` → `sync_version`

#### **Task 3.2: Auth Context Model (for serialization consistency)**
- File: `lib/src/models/usm_auth_context.dart`
- Update JSON methods: `organizationId` → `organization_id`, `createdAt` → `created_at`

### **Phase 4: Services Updates** 
**Goal**: Update service layer field references

#### **Task 4.1: Core Sync Services**
- File: `lib/src/services/usm_universal_sync_operation_service.dart`
- Update: `data['syncVersion']` → `data['sync_version']`

#### **Task 4.2: Conflict Resolution Services**
- Files: `lib/src/services/usm_conflict_resolver*.dart`
- Update audit field references: `createdBy` → `created_by`, `updatedBy` → `updated_by`

### **Phase 6: Configuration Updates**
**Goal**: Update entity discovery and conflict resolution

#### **Task 6.1: Sync Strategies** 
- File: `lib/src/config/usm_sync_strategies.dart`
- Update conflict resolution: `syncVersion` → `sync_version`, `updatedAt` → `updated_at`

#### **Task 6.2: Entity Discovery**
- File: `lib/src/config/usm_entity_discovery.dart`
- Update audit field definitions: `createdBy` → `created_by`, `updatedBy` → `updated_by`, etc.

### **Phase 7: Interface Updates**
**Goal**: Update interface implementations

#### **Task 7.1: Backend Adapter Interface**
- File: `lib/src/interfaces/usm_sync_backend_adapter.dart`
- Update filter logic: `organizationId` → `organization_id`

### **Phase 8: Testing and Validation**
**Goal**: Ensure all changes work in `lib` directory

#### **Task 8.1: Unit Tests**
- Test field transformations in adapters
- Test JSON serialization in models
- Test backward compatibility if needed

#### **Task 8.2: Integration Tests**
- Test complete sync cycles with new field names
- Test conflict resolution with updated field names

## **Implementation Notes**
- **Scope**: Only `lib/` directory files
- **Focus**: Database field names in JSON keys, not Dart property names
- **Pattern**: Update `data['camelCase']` → `data['snake_case']`
- **Priority**: Start with backend adapters (foundation) then models, then services