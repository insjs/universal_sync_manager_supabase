import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';

/// PocketBase Schema Manager
///
/// This script reads YAML schema files and creates/updates collections in PocketBase.
///
/// Usage:
/// dart tools/pocketbase_schema_manager.dart <schema_file.yaml> [pocketbase_url] [admin_email] [admin_password]
///
/// Example:
/// dart tools/pocketbase_schema_manager.dart tools/schema/audit_items.yaml http://localhost:8090 admin@example.com password123
class PocketBaseSchemaManager {
  final String baseUrl;
  final String adminEmail;
  final String adminPassword;
  String? _authToken;

  PocketBaseSchemaManager({
    required this.baseUrl,
    required this.adminEmail,
    required this.adminPassword,
  });

  /// Authenticate with PocketBase admin
  Future<bool> authenticate() async {
    try {
      // Try the newer _superusers authentication endpoint first
      var response = await http.post(
        Uri.parse('$baseUrl/api/collections/_superusers/auth-with-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identity': adminEmail, // Using 'identity' as per PocketBase docs
          'password': adminPassword,
        }),
      );

      // If that fails, try the older admin endpoint for backwards compatibility
      if (response.statusCode == 404) {
        print('🔄 Trying legacy admin authentication endpoint...');
        response = await http.post(
          Uri.parse('$baseUrl/api/admins/auth-with-password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'identity': adminEmail,
            'password': adminPassword,
          }),
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _authToken = data['token'];
        print('✅ Authenticated with PocketBase');
        return true;
      } else {
        print('❌ Authentication failed: ${response.body}');
        print(
            '💡 Make sure your PocketBase admin credentials are correct and the admin user exists.');
        print(
            '💡 You may need to create an admin user first via the PocketBase admin UI.');
        return false;
      }
    } catch (e) {
      print('❌ Authentication error: $e');
      return false;
    }
  }

  /// Get headers with authentication
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': _authToken!,
      };

  /// Check if collection exists
  Future<Map<String, dynamic>?> getCollection(String collectionName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/collections/$collectionName'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        return null; // Collection doesn't exist
      } else {
        throw Exception('Failed to get collection: ${response.body}');
      }
    } catch (e) {
      print('❌ Error getting collection: $e');
      return null;
    }
  }

  /// Convert YAML field type to PocketBase field type
  String _convertFieldType(String yamlType) {
    switch (yamlType.toLowerCase()) {
      case 'text':
        return 'text';
      case 'integer':
        return 'number';
      case 'real':
      case 'float':
        return 'number';
      case 'boolean':
        return 'bool';
      case 'datetime':
        return 'date';
      case 'json':
        return 'json';
      default:
        return 'text'; // Default fallback
    }
  }

  /// Create PocketBase field schema from YAML field
  Map<String, dynamic> _createFieldSchema(Map<dynamic, dynamic> field) {
    final fieldName = field['name'] as String;
    final isRequired = field['required'] == true;

    // Check if this is a relationship field
    if (field['relationship'] != null) {
      return _createRelationshipSchema(field);
    }

    final fieldType = _convertFieldType(field['type'] ?? 'text');

    Map<String, dynamic> schema = {
      'name': fieldName,
      'type': fieldType,
      'required': isRequired,
      'presentable': false,
    };

    // Add options based on field type
    Map<String, dynamic> options = {};

    if (fieldType == 'text') {
      options['max'] = 0; // No limit
      options['min'] = 0;
      options['pattern'] = '';

      // Apply validation constraints if present
      if (field['validation'] != null) {
        final validation = field['validation'] as Map<dynamic, dynamic>;
        if (validation['max'] != null) options['max'] = validation['max'];
        if (validation['min'] != null) options['min'] = validation['min'];
        if (validation['pattern'] != null)
          options['pattern'] = validation['pattern'];
      }
    } else if (fieldType == 'number') {
      options['max'] = null;
      options['min'] = null;
      options['noDecimal'] = field['type'] == 'integer';

      // Apply validation constraints if present
      if (field['validation'] != null) {
        final validation = field['validation'] as Map<dynamic, dynamic>;
        if (validation['max'] != null) options['max'] = validation['max'];
        if (validation['min'] != null) options['min'] = validation['min'];
      }
    } else if (fieldType == 'date') {
      options['max'] = '';
      options['min'] = '';
    } else if (fieldType == 'select') {
      // Handle select options from enhanced YAML
      if (field['options'] != null) {
        final fieldOptions = field['options'] as Map<dynamic, dynamic>;
        options['values'] = fieldOptions['values'] ?? [];
        options['maxSelect'] = fieldOptions['maxSelect'] ?? 1;
      }
    } else if (fieldType == 'file') {
      // Handle file options from enhanced YAML
      if (field['fileOptions'] != null) {
        final fileOptions = field['fileOptions'] as Map<dynamic, dynamic>;
        options['maxSelect'] = fileOptions['maxSelect'] ?? 1;
        options['maxSize'] = fileOptions['maxSize'] ?? 5242880; // 5MB default
        options['mimeTypes'] = fileOptions['mimeTypes'] ?? [];
      }
    }

    schema['options'] = options;

    return schema;
  }

  /// Create relationship field schema for PocketBase
  Map<String, dynamic> _createRelationshipSchema(Map<dynamic, dynamic> field) {
    final fieldName = field['name'] as String;
    final isRequired = field['required'] == true;
    final relationship = field['relationship'] as Map<dynamic, dynamic>;

    Map<String, dynamic> schema = {
      'name': fieldName,
      'type': 'relation',
      'required': isRequired,
      'presentable': false,
    };

    Map<String, dynamic> options = {
      'collectionId': relationship['collectionId'] ?? '',
      'cascadeDelete': relationship['cascadeDelete'] ?? false,
      'minSelect': relationship['minSelect'] ?? 0,
      'maxSelect': relationship['maxSelect'] ?? 1,
      'displayFields': null,
    };

    schema['options'] = options;
    return schema;
  }

  /// Create new collection in PocketBase
  Future<bool> createCollection(
      String collectionName, List<dynamic> fields) async {
    try {
      // Build schema
      List<Map<String, dynamic>> schema = [];

      for (var field in fields) {
        if (field is Map<dynamic, dynamic>) {
          // Skip the ID field as PocketBase creates it automatically
          if (field['name'] == 'id') continue;

          schema.add(_createFieldSchema(field));
        }
      }

      final collectionData = {
        'name': collectionName,
        'type': 'base',
        'system': false,
        'fields': schema,
        'indexes': [],
        'listRule': null,
        'viewRule': null,
        'createRule': null,
        'updateRule': null,
        'deleteRule': null,
        'options': {}
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/collections'),
        headers: _headers,
        body: jsonEncode(collectionData),
      );

      if (response.statusCode == 200) {
        print('✅ Created collection: $collectionName');
        return true;
      } else {
        print('❌ Failed to create collection: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error creating collection: $e');
      return false;
    }
  }

  /// Update existing collection in PocketBase
  Future<bool> updateCollection(
      String collectionId, String collectionName, List<dynamic> fields) async {
    try {
      // Get current collection to preserve existing settings
      final currentCollection = await getCollection(collectionName);
      if (currentCollection == null) {
        print('❌ Collection not found for update');
        return false;
      }

      // Build new schema
      List<Map<String, dynamic>> schema = [];

      for (var field in fields) {
        if (field is Map<dynamic, dynamic>) {
          // Skip the ID field as PocketBase manages it
          if (field['name'] == 'id') continue;

          schema.add(_createFieldSchema(field));
        }
      }

      final updateData = {
        'name': collectionName,
        'type': currentCollection['type'],
        'system': currentCollection['system'],
        'fields': schema,
        'indexes': currentCollection['indexes'] ?? [],
        'listRule': currentCollection['listRule'],
        'viewRule': currentCollection['viewRule'],
        'createRule': currentCollection['createRule'],
        'updateRule': currentCollection['updateRule'],
        'deleteRule': currentCollection['deleteRule'],
        'options': currentCollection['options'] ?? {}
      };

      final response = await http.patch(
        Uri.parse('$baseUrl/api/collections/$collectionId'),
        headers: _headers,
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        print('✅ Updated collection: $collectionName');
        return true;
      } else {
        print('❌ Failed to update collection: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error updating collection: $e');
      return false;
    }
  }

  /// Process YAML schema file
  Future<bool> processSchemaFile(String filePath) async {
    try {
      // Read and parse YAML file
      final file = File(filePath);
      if (!file.existsSync()) {
        print('❌ Schema file not found: $filePath');
        return false;
      }

      final yamlContent = file.readAsStringSync();
      final dynamic yamlData = loadYaml(yamlContent);

      if (yamlData is! Map) {
        print('❌ Invalid YAML format');
        return false;
      }

      final tableName = yamlData['table'] as String?;
      final fields = yamlData['fields'] as List<dynamic>?;

      if (tableName == null || fields == null) {
        print('❌ Missing table name or fields in schema');
        return false;
      }

      print('📋 Processing schema for table: $tableName');

      // Check if collection exists
      final existingCollection = await getCollection(tableName);

      if (existingCollection == null) {
        // Create new collection
        return await createCollection(tableName, fields);
      } else {
        // Update existing collection
        return await updateCollection(
            existingCollection['id'], tableName, fields);
      }
    } catch (e) {
      print('❌ Error processing schema file: $e');
      return false;
    }
  }
}

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    print('''
Usage: dart tools/pocketbase_schema_manager.dart <schema_file.yaml> [pocketbase_url] [admin_email] [admin_password]

Examples:
  dart tools/pocketbase_schema_manager.dart tools/schema/audit_items.yaml
  dart tools/pocketbase_schema_manager.dart tools/schema/audit_items.yaml http://localhost:8090 admin@example.com password123

Default values:
  pocketbase_url: http://localhost:8090
  admin_email: admin@example.com  
  admin_password: password123
''');
    exit(1);
  }

  final schemaFile = arguments[0];
  final pocketbaseUrl =
      arguments.length > 1 ? arguments[1] : 'http://localhost:8090';
  final adminEmail = arguments.length > 2 ? arguments[2] : 'admin@example.com';
  final adminPassword = arguments.length > 3 ? arguments[3] : 'password123';

  print('🚀 PocketBase Schema Manager');
  print('📁 Schema file: $schemaFile');
  print('🌐 PocketBase URL: $pocketbaseUrl');
  print('👤 Admin email: $adminEmail');
  print('---');

  final manager = PocketBaseSchemaManager(
    baseUrl: pocketbaseUrl,
    adminEmail: adminEmail,
    adminPassword: adminPassword,
  );

  // Authenticate
  final authenticated = await manager.authenticate();
  if (!authenticated) {
    print('❌ Failed to authenticate with PocketBase');
    exit(1);
  }

  // Process schema file
  final success = await manager.processSchemaFile(schemaFile);
  if (success) {
    print('✅ Schema processing completed successfully');
  } else {
    print('❌ Schema processing failed');
    exit(1);
  }
}
