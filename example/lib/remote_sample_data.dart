import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class RemoteSampleDataManager {
  static const _uuid = Uuid();

  /// Create sample data in remote Supabase tables
  static Future<void> createAllRemoteSampleData() async {
    print('☁️ Creating all remote sample data...');
    await createRemoteAppSettings();
    await createRemoteOrganizationProfiles();
    await createRemoteAuditItems();
    print('✅ All remote sample data created successfully');
  }

  /// Create sample app_settings in Supabase
  static Future<void> createRemoteAppSettings() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      print('☁️ Creating remote app_settings...');

      // Check if settings already exist
      final existing =
          await supabase.from('app_settings').select('setting_key').limit(1);

      if (existing.isNotEmpty) {
        print('☁️ App settings already exist, skipping creation');
        return;
      }

      final sampleSettings = [
        {
          'setting_key': 'app_name',
          'setting_value': 'Universal Sync Manager Test',
          'category': 'application',
          'is_active': true,
          'created_by': userId,
          'updated_by': userId,
          'sync_version': 1,
        },
        {
          'setting_key': 'version',
          'setting_value': '1.0.0',
          'category': 'application',
          'is_active': true,
          'created_by': userId,
          'updated_by': userId,
          'sync_version': 1,
        },
        {
          'setting_key': 'max_sync_batch_size',
          'setting_value': '100',
          'category': 'sync',
          'is_active': true,
          'created_by': userId,
          'updated_by': userId,
          'sync_version': 1,
        },
        {
          'setting_key': 'sync_interval_seconds',
          'setting_value': '30',
          'category': 'sync',
          'is_active': true,
          'created_by': userId,
          'updated_by': userId,
          'sync_version': 1,
        },
        {
          'setting_key': 'debug_mode',
          'setting_value': 'true',
          'category': 'development',
          'is_active': true,
          'created_by': userId,
          'updated_by': userId,
          'sync_version': 1,
        },
      ];

      final response =
          await supabase.from('app_settings').insert(sampleSettings).select();

      print('☁️ Created ${response.length} app_settings records');
      for (final setting in response) {
        print(
            '☁️ Setting: ${setting['setting_key']} = ${setting['setting_value']}');
      }
    } catch (e) {
      print('❌ Error creating remote app_settings: $e');
    }
  }

  /// Create sample organization_profiles in Supabase
  static Future<void> createRemoteOrganizationProfiles() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        print('❌ User must be authenticated to create organization_profiles');
        return;
      }

      print('☁️ Creating remote organization_profiles...');

      final sampleProfiles = [
        {
          'organization_id': _uuid.v4(),
          'name': 'Remote Test Organization Alpha',
          'description':
              'First test organization created remotely for testing remote to local sync',
          'is_active': true,
          'settings': {'theme': 'dark', 'notifications': true},
          'created_by': userId,
          'updated_by': userId,
          'sync_version': 1,
        },
        {
          'organization_id': _uuid.v4(),
          'name': 'Remote Test Organization Beta',
          'description':
              'Second test organization with different properties for sync validation',
          'is_active': true,
          'settings': {'theme': 'light', 'notifications': false},
          'created_by': userId,
          'updated_by': userId,
          'sync_version': 1,
        },
        {
          'organization_id': _uuid.v4(),
          'name': 'Remote Test Organization Gamma',
          'description':
              'Third test organization for comprehensive sync testing',
          'is_active': false, // Inactive organization
          'settings': {'theme': 'auto', 'notifications': true},
          'created_by': userId,
          'updated_by': userId,
          'sync_version': 1,
        },
        {
          'organization_id': _uuid.v4(),
          'name': 'Remote Test Organization Delta',
          'description': 'Fourth test organization for bulk data testing',
          'is_active': true,
          'settings': {
            'theme': 'dark',
            'notifications': true,
            'advanced': true
          },
          'created_by': userId,
          'updated_by': userId,
          'sync_version': 2, // Different sync version
        },
      ];

      final response = await supabase
          .from('organization_profiles')
          .insert(sampleProfiles)
          .select();

      print('☁️ Created ${response.length} organization_profiles records');
      for (final profile in response) {
        print('☁️ Profile: ${profile['name']} (ID: ${profile['id']})');
      }
    } catch (e) {
      print('❌ Error creating remote organization_profiles: $e');
    }
  }

  /// Create sample audit_items in Supabase
  static Future<void> createRemoteAuditItems() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        print('❌ User must be authenticated to create audit_items');
        return;
      }

      print('☁️ Creating remote audit_items...');

      final orgId = _uuid.v4();
      final dueDate = DateTime.now().add(Duration(days: 7));

      final sampleAudits = [
        {
          'organization_id': orgId,
          'title': 'Remote Security Audit - Alpha',
          'description':
              'Comprehensive security audit for remote organization systems and protocols',
          'status': 'pending',
          'priority': 1,
          'due_date': dueDate.toIso8601String(),
          'metadata': {
            'audit_type': 'security',
            'compliance_framework': 'SOC2',
            'estimated_hours': 40
          },
          'created_by': userId,
          'updated_by': userId,
          'sync_version': 1,
        },
        {
          'organization_id': orgId,
          'title': 'Remote Data Quality Review',
          'description':
              'Review data quality and integrity across all remote systems and databases',
          'status': 'in_progress',
          'priority': 2,
          'due_date': dueDate.add(Duration(days: 3)).toIso8601String(),
          'metadata': {
            'audit_type': 'data_quality',
            'systems': ['database', 'api', 'cache'],
            'estimated_hours': 24
          },
          'created_by': userId,
          'updated_by': userId,
          'sync_version': 1,
        },
        {
          'organization_id': orgId,
          'title': 'Remote Access Control Audit',
          'description':
              'Audit user access controls and permission management for remote systems',
          'status': 'completed',
          'priority': 3,
          'due_date': dueDate.subtract(Duration(days: 2)).toIso8601String(),
          'metadata': {
            'audit_type': 'access_control',
            'users_reviewed': 150,
            'issues_found': 3,
            'estimated_hours': 16
          },
          'created_by': userId,
          'updated_by': userId,
          'sync_version': 2,
        },
        {
          'organization_id': orgId,
          'title': 'Remote Performance Optimization',
          'description':
              'Performance audit and optimization recommendations for remote infrastructure',
          'status': 'pending',
          'priority': 0,
          'due_date': dueDate.add(Duration(days: 14)).toIso8601String(),
          'metadata': {
            'audit_type': 'performance',
            'focus_areas': ['database', 'network', 'application'],
            'estimated_hours': 32
          },
          'created_by': userId,
          'updated_by': userId,
          'sync_version': 1,
        },
      ];

      final response =
          await supabase.from('audit_items').insert(sampleAudits).select();

      print('☁️ Created ${response.length} audit_items records');
      for (final audit in response) {
        print(
            '☁️ Audit: ${audit['title']} - ${audit['status']} (ID: ${audit['id']})');
      }
    } catch (e) {
      print('❌ Error creating remote audit_items: $e');
    }
  }

  /// Get all remote organization profiles
  static Future<List<Map<String, dynamic>>>
      getRemoteOrganizationProfiles() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('organization_profiles')
          .select()
          .order('created_at');

      print('☁️ Retrieved ${response.length} remote organization profiles');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting remote organization_profiles: $e');
      return [];
    }
  }

  /// Get all remote audit items
  static Future<List<Map<String, dynamic>>> getRemoteAuditItems() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('audit_items')
          .select()
          .order('created_at', ascending: false);

      print('☁️ Retrieved ${response.length} remote audit items');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting remote audit_items: $e');
      return [];
    }
  }

  /// Clear all remote test data
  static Future<void> clearAllRemoteTestData() async {
    try {
      final supabase = Supabase.instance.client;

      print('🗑️ Clearing all remote test data...');

      // Clear organization_profiles (only test data)
      await supabase
          .from('organization_profiles')
          .delete()
          .like('name', '%Test%');

      // Clear audit_items (only test data)
      await supabase.from('audit_items').delete().like('new_values', '%Test%');

      // Clear app_settings (only test data)
      await supabase
          .from('app_settings')
          .delete()
          .like('description', '%USM testing%');

      // Clear public_announcements (only test data)
      await supabase
          .from('public_announcements')
          .delete()
          .like('title', '%USM%');

      print('🗑️ Cleared all remote test data');
    } catch (e) {
      print('❌ Error clearing remote test data: $e');
    }
  }
}
