import 'package:universal_sync_manager/universal_sync_manager.dart';

/// Service class that manages test configuration and constants
/// for the Universal Sync Manager Supabase example application.
class TestConfigurationService {
  // Test configuration - UPDATE THESE WITH YOUR SUPABASE VALUES
  static const String supabaseUrl = 'https://rsuuacugtplmuhlevbbq.supabase.co';
  static const String supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJzdXVhY3VndHBsbXVobGV2YmJxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzMyNDgxOSwiZXhwIjoyMDY4OTAwODE5fQ.xRvyXnhEnSOOFbowixaZuub0OdG8mEYBwL6-Y7c9E_I';

  // Test credentials
  static const String testEmail = 'test@example.com';
  static const String testPassword = 'test123456';

  /// Creates a SyncBackendConfiguration for Supabase testing
  static SyncBackendConfiguration createSupabaseConfig() {
    return SyncBackendConfiguration(
      configId: 'test-config',
      displayName: 'Supabase Test',
      backendType: 'supabase',
      baseUrl: supabaseUrl,
      projectId: 'test-project',
    );
  }

  /// Creates a SupabaseSyncAdapter with the test configuration
  static SupabaseSyncAdapter createAdapter() {
    return SupabaseSyncAdapter(
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseKey,
    );
  }

  /// Test collections used in the USM tests
  static const List<String> testCollections = [
    'app_settings',
    'organization_profiles',
    'user_profiles',
  ];

  /// Sample test data templates
  static Map<String, dynamic> createSampleAppSetting({
    required String key,
    required String value,
    String? description,
  }) {
    return {
      'setting_key': key,
      'setting_value': value,
      'description': description ?? 'Test setting: $key',
    };
  }

  static Map<String, dynamic> createSampleOrganizationProfile({
    required String name,
    String? description,
  }) {
    return {
      'name': name,
      'description': description ?? 'Test organization: $name',
    };
  }

  static Map<String, dynamic> createSampleUserProfile({
    required String displayName,
    String? email,
  }) {
    return {
      'display_name': displayName,
      'email': email ?? '$displayName@example.com'.toLowerCase(),
    };
  }
}
