# SQLite-First Schema Implementation Guide

## 📋 **Schema Translation: YAML → SQLite → PocketBase**

Based on your **Backend-Agnostic Database Strategy (SQLite-First)**, here's how our test schema translates:

### **1. YAML Schema Definition** (Source of Truth)
```yaml
table: managed_users_test_relations
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
  # ... etc
```

### **2. SQLite DDL Generated** (Primary Backend)
```sql
CREATE TABLE IF NOT EXISTS managed_users_test_relations (
  id TEXT PRIMARY KEY,
  organizationId TEXT NOT NULL,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  password TEXT NOT NULL,
  isActive INTEGER NOT NULL DEFAULT 1,
  status TEXT DEFAULT 'active',
  roleId TEXT,
  emailVisibility INTEGER NOT NULL DEFAULT 0,
  verified INTEGER NOT NULL DEFAULT 0,
  tokenKey TEXT NOT NULL,
  userName TEXT,
  
  -- REQUIRED AUDIT FIELDS
  createdBy TEXT NOT NULL,
  updatedBy TEXT NOT NULL,
  createdAt TEXT,
  updatedAt TEXT,
  deletedAt TEXT,
  
  -- REQUIRED SYNC FIELDS  
  lastSyncedAt TEXT,
  isDirty INTEGER NOT NULL DEFAULT 1,
  syncVersion INTEGER NOT NULL DEFAULT 0,
  isDeleted INTEGER NOT NULL DEFAULT 0,
  
  -- Performance indexes
  FOREIGN KEY (organizationId) REFERENCES ost_organizations(id),
  FOREIGN KEY (roleId) REFERENCES rbac_organization_roles(id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_managed_users_organizationId ON managed_users_test_relations (organizationId);
CREATE INDEX IF NOT EXISTS idx_managed_users_email ON managed_users_test_relations (email);
CREATE INDEX IF NOT EXISTS idx_managed_users_active_status ON managed_users_test_relations (isActive, isDeleted);
CREATE INDEX IF NOT EXISTS idx_managed_users_sync_dirty ON managed_users_test_relations (isDirty);
```

### **3. PocketBase Collection** (Sync Target)
- **Collection Name**: `managed_users_test_relations`
- **Field Types**: Automatically converted from SQLite types
- **Relationships**: `organizationId` → relation to `ost_organizations`
- **Validation**: Applied from YAML validation rules

### **4. Dart Model Class** (Generated from Schema)
```dart
class ManagedUserTestRelation extends SyncableModel {
  final String id;
  final String organizationId;
  final String name;
  final String email;
  final String password;
  final int isActive;
  final String status;
  final String? roleId;
  final int emailVisibility;
  final int verified;
  final String tokenKey;
  final String? userName;
  
  // AUDIT FIELDS
  final String createdBy;
  final String updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  
  // SYNC FIELDS
  final DateTime? lastSyncedAt;
  final int isDirty;
  final int syncVersion;
  final int isDeleted;
  
  const ManagedUserTestRelation({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.email,
    required this.password,
    required this.isActive,
    required this.status,
    this.roleId,
    required this.emailVisibility,
    required this.verified,
    required this.tokenKey,
    this.userName,
    required this.createdBy,
    required this.updatedBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.lastSyncedAt,
    required this.isDirty,
    required this.syncVersion,
    required this.isDeleted,
  });
  
  @override
  Map<String, dynamic> toSqlite() {
    return {
      'id': id,
      'organizationId': organizationId,
      'name': name,
      'email': email,
      'password': password,
      'isActive': isActive,
      'status': status,
      'roleId': roleId,
      'emailVisibility': emailVisibility,
      'verified': verified,
      'tokenKey': tokenKey,
      'userName': userName,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'isDirty': isDirty,
      'syncVersion': syncVersion,
      'isDeleted': isDeleted,
    };
  }
  
  factory ManagedUserTestRelation.fromSqlite(Map<String, dynamic> map) {
    return ManagedUserTestRelation(
      id: map['id'] as String,
      organizationId: map['organizationId'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      isActive: map['isActive'] as int,
      status: map['status'] as String? ?? 'active',
      roleId: map['roleId'] as String?,
      emailVisibility: map['emailVisibility'] as int,
      verified: map['verified'] as int,
      tokenKey: map['tokenKey'] as String,
      userName: map['userName'] as String?,
      createdBy: map['createdBy'] as String,
      updatedBy: map['updatedBy'] as String,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      deletedAt: map['deletedAt'] != null ? DateTime.parse(map['deletedAt']) : null,
      lastSyncedAt: map['lastSyncedAt'] != null ? DateTime.parse(map['lastSyncedAt']) : null,
      isDirty: map['isDirty'] as int,
      syncVersion: map['syncVersion'] as int,
      isDeleted: map['isDeleted'] as int,
    );
  }
  
  // Implement SyncableModel requirements
  @override String get id => this.id;
  @override bool get isDirty => this.isDirty == 1;
  @override DateTime? get lastSyncedAt => this.lastSyncedAt;
  @override int get syncVersion => this.syncVersion;
  @override DateTime? get updatedAt => this.updatedAt;
  @override bool get isDeleted => this.isDeleted == 1;
}
```

## ✅ **Benefits of This SQLite-First Approach**

### **1. Single Source of Truth**
- ✅ One YAML schema defines all backends
- ✅ No field mapping inconsistencies
- ✅ Consistent field types across platforms

### **2. Offline-First Compatibility**
- ✅ SQLite as primary data store
- ✅ All operations work offline immediately
- ✅ Sync happens when online

### **3. Type Safety**
- ✅ `INTEGER` for booleans (0/1) across all backends
- ✅ `TEXT` for all string data and foreign keys
- ✅ ISO 8601 strings for dates
- ✅ No boolean conversion issues

### **4. Sync Metadata Built-In**
- ✅ `isDirty`, `syncVersion`, `lastSyncedAt` fields
- ✅ Optimistic concurrency control
- ✅ Delta sync capabilities
- ✅ Multi-tenant isolation with `organizationId`

### **5. Relationship Handling**
- ✅ **SQLite**: Foreign key constraints for integrity
- ✅ **PocketBase**: Relation fields for API rules
- ✅ **Application**: Manual relationship resolution

## 🚀 **Next Steps for Your HAS Project**

1. **Update Existing Schemas**: Convert to this SQLite-first format
2. **Generate Migration Scripts**: Create ALTER TABLE statements for existing data
3. **Update Dart Models**: Implement proper `SyncableModel` interface
4. **Test Sync Operations**: Verify Universal Sync Manager works with new schema
5. **Performance Testing**: Validate indexes improve query performance

This approach ensures your HAS project has a **rock-solid, backend-agnostic foundation** that can sync to any backend while maintaining offline-first capabilities!
