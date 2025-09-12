import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocalSampleDataManager {
  static Database? _database;
  static const _uuid = Uuid();

  /// Gets the current authenticated user ID from Supabase, or generates a fallback UUID
  static Future<String> _getAuthenticatedUserId() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        return user.id;
      }
    } catch (e) {
      print('⚠️ Failed to get authenticated user ID: $e');
    }

    // Fallback to a consistent test user ID if not authenticated
    print('⚠️ No authenticated user found, using fallback test user ID');
    return 'test-user-${_uuid.v4()}';
  }

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'usm_test.db');
    return await openDatabase(
      path,
      version: 3, // Incremented to force recreation with correct schema
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Drop and recreate tables to ensure correct schema
      try {
        await db.execute('DROP TABLE IF EXISTS organization_profiles');
        await db.execute('DROP TABLE IF EXISTS audit_items');
        await db.execute('DROP TABLE IF EXISTS app_settings');
        print('📱 Dropped existing tables for schema update');

        // Recreate tables with correct schema
        await _onCreate(db, newVersion);
      } catch (e) {
        print('📱 Table recreation failed: $e');
      }
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Create app_settings table (UPDATED: UUID primary key to match Supabase)
    await db.execute('''
      CREATE TABLE app_settings (
        id TEXT PRIMARY KEY, -- UUID as TEXT in SQLite to match Supabase
        setting_key TEXT NOT NULL UNIQUE,
        setting_value TEXT,
        category TEXT DEFAULT 'general',
        is_active INTEGER DEFAULT 1,
        created_by TEXT,
        updated_by TEXT,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT,
        is_dirty INTEGER DEFAULT 1,
        last_synced_at TEXT,
        sync_version INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // Create organization_profiles table (UPDATED: UUID primary key to match Supabase)
    await db.execute('''
      CREATE TABLE organization_profiles (
        id TEXT PRIMARY KEY, -- UUID as TEXT in SQLite to match Supabase
        organization_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        is_active INTEGER DEFAULT 1,
        settings TEXT, -- JSON as TEXT in SQLite
        created_by TEXT NOT NULL,
        updated_by TEXT NOT NULL,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT,
        is_dirty INTEGER DEFAULT 1,
        last_synced_at TEXT,
        sync_version INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // Create audit_items table (UPDATED: UUID primary key to match Supabase)
    await db.execute('''
      CREATE TABLE audit_items (
        id TEXT PRIMARY KEY, -- UUID as TEXT in SQLite to match Supabase
        organization_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT DEFAULT 'pending',
        priority INTEGER DEFAULT 0,
        due_date TEXT,
        metadata TEXT, -- JSON as TEXT in SQLite
        created_by TEXT NOT NULL,
        updated_by TEXT NOT NULL,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT,
        is_dirty INTEGER DEFAULT 1,
        last_synced_at TEXT,
        sync_version INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    print('📱 Local database tables created successfully');
  }

  /// Create sample organization profiles in local database
  static Future<void> createSampleOrganizationProfiles() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Use the authenticated user ID from Supabase instead of random UUID
    final userId = await _getAuthenticatedUserId();

    final sampleProfiles = [
      {
        'id': _uuid.v4(), // UUID primary key to match Supabase
        'organization_id': _uuid.v4(),
        'name': 'Local Test Organization 1',
        'description':
            'First test organization created locally for sync testing',
        'is_active': 1,
        'settings': jsonEncode({
          "theme": "dark",
          "notifications": true
        }), // Ensure it's a JSON string
        'created_by': userId,
        'updated_by': userId,
        'created_at': now,
        'updated_at': now,
        'sync_version': 1,
        'is_dirty': 1, // Needs to be synced
        'last_synced_at': null,
      },
      {
        'id': _uuid.v4(), // UUID primary key to match Supabase
        'organization_id': _uuid.v4(),
        'name': 'Local Test Organization 2',
        'description':
            'Second test organization for testing local to remote sync',
        'is_active': 1,
        'settings': jsonEncode({
          "theme": "light",
          "notifications": false
        }), // Ensure it's a JSON string
        'created_by': userId,
        'updated_by': userId,
        'created_at': now,
        'updated_at': now,
        'sync_version': 1,
        'is_dirty': 1,
        'last_synced_at': null,
      },
      {
        'id': _uuid.v4(), // UUID primary key to match Supabase
        'organization_id': _uuid.v4(),
        'name': 'Local Test Organization 3',
        'description':
            'Third test organization for comprehensive local to remote testing',
        'is_active': 0, // Inactive organization
        'settings': jsonEncode({
          "theme": "auto",
          "notifications": true
        }), // Ensure it's a JSON string
        'created_by': userId,
        'updated_by': userId,
        'created_at': now,
        'updated_at': now,
        'sync_version': 1,
        'is_dirty': 1,
        'last_synced_at': null,
      },
    ];

    print(
        '📱 Starting to insert ${sampleProfiles.length} organization profiles...');
    for (int i = 0; i < sampleProfiles.length; i++) {
      final profile = sampleProfiles[i];
      try {
        print(
            '📱 Inserting profile ${i + 1}/${sampleProfiles.length}: ${profile['name']}');
        await db.insert('organization_profiles', profile);
        print('📱 ✅ Created local organization profile: ${profile['name']}');
      } catch (e) {
        print('📱 ❌ Failed to insert profile ${profile['name']}: $e');
        rethrow;
      }
    }

    print(
        '✅ Created ${sampleProfiles.length} sample organization profiles locally');
  }

  /// Create sample audit items in local database
  static Future<void> createSampleAuditItems() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Use the authenticated user ID from Supabase instead of random UUID
    final userId = await _getAuthenticatedUserId();
    final orgId = _uuid.v4();
    final dueDate = DateTime.now().add(Duration(days: 7)).toIso8601String();

    final sampleAudits = [
      {
        'id': _uuid.v4(), // UUID primary key to match Supabase
        'organization_id': orgId,
        'title': 'Local Security Audit - Alpha',
        'description':
            'Comprehensive security audit for local organization systems',
        'status': 'pending',
        'priority': 1,
        'due_date': dueDate,
        'metadata': jsonEncode({
          "audit_type": "security",
          "estimated_hours": 24
        }), // Ensure it's a JSON string
        'created_by': userId,
        'updated_by': userId,
        'created_at': now,
        'updated_at': now,
        'sync_version': 1,
        'is_dirty': 1,
        'last_synced_at': null,
      },
      {
        'id': _uuid.v4(), // UUID primary key to match Supabase
        'organization_id': orgId,
        'title': 'Local Data Quality Review',
        'description': 'Review data quality and integrity across local systems',
        'status': 'in_progress',
        'priority': 2,
        'due_date': DateTime.now().add(Duration(days: 3)).toIso8601String(),
        'metadata': jsonEncode({
          "audit_type": "data_quality",
          "systems": ["database", "cache"]
        }), // Ensure it's a JSON string
        'created_by': userId,
        'updated_by': userId,
        'created_at': now,
        'updated_at': now,
        'sync_version': 1,
        'is_dirty': 1,
        'last_synced_at': null,
      },
      {
        'id': _uuid.v4(), // UUID primary key to match Supabase
        'organization_id': orgId,
        'title': 'Local Access Control Audit',
        'description': 'Audit local user access controls and permissions',
        'status': 'completed',
        'priority': 3,
        'due_date':
            DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
        'metadata': jsonEncode({
          "audit_type": "access_control",
          "users_reviewed": 50
        }), // Ensure it's a JSON string
        'created_by': userId,
        'updated_by': userId,
        'created_at': now,
        'updated_at': now,
        'sync_version': 1,
        'is_dirty': 1,
        'last_synced_at': null,
      },
    ];

    for (final audit in sampleAudits) {
      await db.insert('audit_items', audit);
      print('📱 Created local audit item: ${audit['title']}');
    }

    print('✅ Created ${sampleAudits.length} sample audit items locally');
  }

  /// Get all local organization profiles
  static Future<List<Map<String, dynamic>>>
      getLocalOrganizationProfiles() async {
    final db = await database;
    final results = await db.query('organization_profiles');
    print('📱 Retrieved ${results.length} local organization profiles');
    return results;
  }

  /// Get all local audit items
  static Future<List<Map<String, dynamic>>> getLocalAuditItems() async {
    final db = await database;
    final results = await db.query('audit_items');
    print('📱 Retrieved ${results.length} local audit items');
    return results;
  }

  /// Get dirty (unsynced) organization profiles with schema mapping for sync
  static Future<List<Map<String, dynamic>>>
      getDirtyOrganizationProfiles() async {
    final db = await database;
    final results = await db.query(
      'organization_profiles',
      where: 'is_dirty = ?',
      whereArgs: [1],
    );

    // Map local fields to remote fields for sync compatibility
    final mappedResults = results.map((item) {
      final mapped = <String, dynamic>{
        'organization_id': item['organization_id'],
        'name': item['name'],
        'description': item['description'],
        'is_active': item['is_active'] == 1, // Convert INTEGER to BOOLEAN
        'created_by': item['created_by'],
        'updated_by': item['updated_by'],
        'sync_version': item['sync_version'],
        // Don't include 'id' - let Supabase auto-generate
        // Don't include local-only fields
      };

      // Handle settings JSON field
      if (item['settings'] != null) {
        mapped['settings'] =
            item['settings']; // Keep as string, adapter will parse
      }

      return mapped;
    }).toList();

    print(
        '📱 Retrieved ${mappedResults.length} dirty organization profiles for sync');
    return mappedResults;
  }

  /// Get dirty (unsynced) audit items with schema mapping for sync
  static Future<List<Map<String, dynamic>>> getDirtyAuditItems() async {
    final db = await database;
    final results = await db.query(
      'audit_items',
      where: 'is_dirty = ?',
      whereArgs: [1],
    );

    // Map local fields to remote fields for sync compatibility
    final mappedResults = results.map((item) {
      final mapped = <String, dynamic>{
        'organization_id': item['organization_id'],
        'title': item['title'],
        'description': item['description'],
        'status': item['status'],
        'priority': item['priority'], // Keep as integer, adapter will validate
        'due_date': item['due_date'],
        'created_by': item['created_by'],
        'updated_by': item['updated_by'],
        'sync_version': item['sync_version'],
        // Don't include 'id' - let Supabase auto-generate
        // Don't include local-only fields
      };

      // Handle metadata JSON field
      if (item['metadata'] != null) {
        mapped['metadata'] =
            item['metadata']; // Keep as string, adapter will parse
      }

      return mapped;
    }).toList();

    print('📱 Retrieved ${mappedResults.length} dirty audit items for sync');
    return mappedResults;
  }

  /// Get dirty (unsynced) organization profiles with IDs for sync tracking
  static Future<List<Map<String, dynamic>>>
      getDirtyOrganizationProfilesWithIds() async {
    final db = await database;
    final results = await db.query(
      'organization_profiles',
      where: 'is_dirty = ?',
      whereArgs: [1],
    );
    print(
        '📱 Retrieved ${results.length} dirty organization profiles with IDs');
    return results;
  }

  /// Get dirty (unsynced) audit items with IDs for sync tracking
  static Future<List<Map<String, dynamic>>> getDirtyAuditItemsWithIds() async {
    final db = await database;
    final results = await db.query(
      'audit_items',
      where: 'is_dirty = ?',
      whereArgs: [1],
    );
    print('📱 Retrieved ${results.length} dirty audit items with IDs');
    return results;
  }

  /// Mark a record as synced
  static Future<void> markAsSynced(String table, String id) async {
    final db = await database;
    await db.update(
      table,
      {
        'is_dirty': 0,
        'last_synced_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    print('📱 Marked $table record $id as synced');
  }

  /// Clear all local data
  static Future<void> clearAllLocalData() async {
    try {
      final db = await database;
      await db.delete('organization_profiles');
      await db.delete('audit_items');
      await db.delete('app_settings');
      print('📱 Cleared all local data');
    } catch (e) {
      print('📱 Error clearing local data (might be expected): $e');
    }
  }

  /// Force database recreation with correct schema
  static Future<void> recreateDatabase() async {
    try {
      // Close existing database if open
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      String path = join(await getDatabasesPath(), 'usm_test.db');
      await deleteDatabase(path);
      print('📱 Deleted existing database for recreation');

      // Initialize fresh database and keep it cached
      _database = await _initDatabase();
      print('📱 Recreated database with correct schema');
    } catch (e) {
      print('📱 Error recreating database: $e');
    }
  }

  /// Create all local sample data
  static Future<void> createAllSampleData() async {
    print('📱 Creating all local sample data...');

    try {
      // Force database recreation to ensure correct schema
      await recreateDatabase();

      // Create sample data using the same database connection
      await createSampleOrganizationProfiles();
      await createSampleAuditItems();
      print('✅ All local sample data created successfully');
    } catch (e) {
      print('❌ Error creating local sample data: $e');
      rethrow;
    }
  }
}
