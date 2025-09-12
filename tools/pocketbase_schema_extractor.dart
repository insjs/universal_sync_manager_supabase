import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// PocketBase Schema Extractor
///
/// This script connects to PocketBase and extracts existing collections to YAML schema files.
///
/// Usage:
/// dart tools/pocketbase_schema_extractor.dart [pocketbase_url] [admin_email] [admin_password] [output_dir]
///
/// Example:
/// dart tools/pocketbase_schema_extractor.dart http://localhost:8090 admin@example.com password123 tools/schema
class PocketBaseSchemaExtractor {
  final String baseUrl;
  final String adminEmail;
  final String adminPassword;
  final String outputDir;
  String? _authToken;

  PocketBaseSchemaExtractor({
    required this.baseUrl,
    required this.adminEmail,
    required this.adminPassword,
    required this.outputDir,
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

  /// Get all collections from PocketBase
  Future<List<Map<String, dynamic>>> getAllCollections() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/collections'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🔍 Full API response: ${jsonEncode(data)}');

        if (data['items'] is List) {
          final collections = List<Map<String, dynamic>>.from(data['items']);
          print('📋 Raw API response: Found ${collections.length} collections');

          // Debug: Print first collection's full structure
          if (collections.isNotEmpty) {
            print(
                '🔬 Sample collection structure: ${jsonEncode(collections.first)}');
          }

          // Debug: Print collection details
          for (var collection in collections) {
            final name = collection['name'];
            final schema = collection['schema'] as List<dynamic>? ?? [];
            print('   📄 Collection: $name (${schema.length} fields)');

            // Check if we have fields but no schema - maybe they're stored differently
            final keys = collection.keys.toList();
            if (schema.isEmpty) {
              print('      🔍 Collection keys: $keys');
            }
          }

          return collections;
        }
      } else {
        print('❌ Failed to get collections: ${response.body}');
      }
    } catch (e) {
      print('❌ Error getting collections: $e');
    }
    return [];
  }

  /// Get detailed collection info including schema
  Future<Map<String, dynamic>?> getCollectionDetails(
      String collectionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/collections/$collectionId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🔍 Detailed collection data: ${jsonEncode(data)}');
        return data;
      } else {
        print(
            '❌ Failed to get collection details for $collectionId: ${response.body}');
      }
    } catch (e) {
      print('❌ Error getting collection details for $collectionId: $e');
    }
    return null;
  }

  /// Convert PocketBase field type to YAML field type
  String _convertPocketBaseFieldType(String pocketBaseType) {
    switch (pocketBaseType.toLowerCase()) {
      case 'text':
        return 'text';
      case 'number':
        return 'integer'; // Default to integer, could be real
      case 'bool':
        return 'integer'; // Following the strategy of using 0/1 for booleans
      case 'date':
        return 'text'; // Store as ISO string
      case 'json':
        return 'text'; // Store as JSON string
      case 'email':
        return 'text';
      case 'url':
        return 'text';
      case 'file':
        return 'text';
      case 'relation':
        return 'text'; // Store as foreign key ID
      case 'select':
        return 'text'; // Store as string value
      case 'user':
        return 'text'; // Store as user ID
      case 'editor':
        return 'text'; // Rich text as string
      default:
        return 'text'; // Default fallback
    }
  }

  /// Extract field information from PocketBase schema
  Map<String, dynamic> _extractFieldInfo(Map<String, dynamic> field) {
    final name = field['name'] as String;
    final type = field['type'] as String;
    final required = field['required'] as bool? ?? false;
    final options = field['options'] as Map<String, dynamic>? ?? {};

    Map<String, dynamic> yamlField = {
      'name': name,
      'type': _convertPocketBaseFieldType(type),
      'description': _generateFieldDescription(field),
    };

    // Handle special cases
    if (name == 'id') {
      yamlField['primaryKey'] = true;
    }

    if (required) {
      yamlField['required'] = true;
    }

    // Extract default values if available
    if (options['default'] != null) {
      yamlField['default'] = options['default'];
    }

    // Handle number types - check if it should be real vs integer
    if (type == 'number' && options['noDecimal'] == false) {
      yamlField['type'] = 'real';
    }

    // Handle relationship fields
    if (type == 'relation') {
      yamlField['relationship'] = {
        'type': 'relation',
        'collectionId': options['collectionId'] ?? '',
        'maxSelect': options['maxSelect'] ?? 1,
        'minSelect': options['minSelect'] ?? 0,
        'cascadeDelete': options['cascadeDelete'] ?? false,
      };
    }

    // Handle select fields
    if (type == 'select') {
      yamlField['options'] = {
        'values': options['values'] ?? [],
        'maxSelect': options['maxSelect'] ?? 1,
      };
    }

    // Handle file fields
    if (type == 'file') {
      yamlField['fileOptions'] = {
        'maxSelect': options['maxSelect'] ?? 1,
        'maxSize': options['maxSize'] ?? 5242880, // 5MB default
        'mimeTypes': options['mimeTypes'] ?? [],
      };
    }

    // Add validation constraints
    if (options['min'] != null ||
        options['max'] != null ||
        options['pattern'] != null) {
      yamlField['validation'] = {};
      if (options['min'] != null)
        yamlField['validation']['min'] = options['min'];
      if (options['max'] != null)
        yamlField['validation']['max'] = options['max'];
      if (options['pattern'] != null)
        yamlField['validation']['pattern'] = options['pattern'];
    }

    return yamlField;
  }

  /// Generate a descriptive table description based on naming conventions
  String _generateTableDescription(String tableName, String type) {
    // Generate descriptions based on common naming patterns
    if (tableName.startsWith('cfg_')) {
      return 'Configuration table for ${tableName.substring(4).replaceAll('_', ' ')}';
    } else if (tableName.startsWith('ost_')) {
      return 'Operational service table for ${tableName.substring(4).replaceAll('_', ' ')}';
    } else if (tableName.startsWith('rbac_')) {
      return 'Role-based access control table for ${tableName.substring(5).replaceAll('_', ' ')}';
    } else if (tableName.startsWith('bak_')) {
      return 'Backup/archive table for ${tableName.substring(4).replaceAll('_', ' ')}';
    } else if (tableName.startsWith('app_')) {
      return 'Application data table for ${tableName.substring(4).replaceAll('_', ' ')}';
    } else if (tableName.contains('_')) {
      return 'Data table for ${tableName.replaceAll('_', ' ')}';
    } else {
      return 'Data collection for $tableName';
    }
  }

  /// Generate detailed field description
  String _generateFieldDescription(Map<String, dynamic> field) {
    final name = field['name'] as String;
    final type = field['type'] as String;
    final required = field['required'] as bool? ?? false;
    final options = field['options'] as Map<String, dynamic>? ?? {};

    String description = '';

    // Base description from field type and name
    switch (type.toLowerCase()) {
      case 'text':
        if (name.toLowerCase().contains('email')) {
          description = 'Email address field';
        } else if (name.toLowerCase().contains('name')) {
          description = 'Name or title field';
        } else if (name.toLowerCase().contains('description')) {
          description = 'Descriptive text field';
        } else if (name.toLowerCase().contains('key')) {
          description = 'Key or identifier field';
        } else if (name.toLowerCase().contains('code')) {
          description = 'Code or identifier field';
        } else {
          description = 'Text field';
        }
        break;
      case 'number':
        description = 'Numeric field';
        break;
      case 'bool':
        description = 'Boolean flag field';
        break;
      case 'date':
        description = 'Date/time field';
        break;
      case 'autodate':
        if (name.contains('created')) {
          description = 'Automatic creation timestamp';
        } else if (name.contains('updated')) {
          description = 'Automatic update timestamp';
        } else {
          description = 'Automatic date/time field';
        }
        break;
      case 'relation':
        final collectionId = options['collectionId'] as String? ?? '';
        final maxSelect = options['maxSelect'] as int? ?? 1;
        description =
            'Relationship field (${maxSelect == 1 ? 'single' : 'multiple'} selection)';
        if (collectionId.isNotEmpty) {
          description += ' -> Collection ID: $collectionId';
        }
        break;
      case 'select':
        final values = options['values'] as List<dynamic>? ?? [];
        description = 'Selection field with options: ${values.join(', ')}';
        break;
      case 'file':
        final maxSelect = options['maxSelect'] as int? ?? 1;
        description = 'File upload field (max: $maxSelect)';
        break;
      case 'json':
        description = 'JSON data field';
        break;
      case 'email':
        description = 'Email address field with validation';
        break;
      case 'url':
        description = 'URL field with validation';
        break;
      case 'editor':
        description = 'Rich text editor field';
        break;
      default:
        description =
            '${type.toLowerCase().replaceFirst(type[0], type[0].toUpperCase())} field';
    }

    // Add constraints information
    List<String> constraints = [];
    if (required) constraints.add('required');
    if (options['min'] != null) constraints.add('min: ${options['min']}');
    if (options['max'] != null) constraints.add('max: ${options['max']}');
    if (options['pattern'] != null)
      constraints.add('pattern: ${options['pattern']}');

    if (constraints.isNotEmpty) {
      description += ' (${constraints.join(', ')})';
    }

    return description;
  }

  /// Generate YAML content for a collection
  String _generateYamlContent(Map<String, dynamic> collection) {
    final name = collection['name'] as String;
    final created = collection['created'] as String? ?? '';
    final updated = collection['updated'] as String? ?? '';
    final collectionType = collection['type'] as String? ?? 'base';

    // Try both 'schema' (old format) and 'fields' (new format)
    var schema = collection['schema'] as List<dynamic>? ?? [];
    var fields = collection['fields'] as List<dynamic>? ?? [];

    // Use whichever has data, prefer 'fields' if both exist
    final fieldsList = fields.isNotEmpty ? fields : schema;

    print('🔍 Processing collection: $name');
    print('   Schema fields count: ${schema.length}');
    print('   Fields count: ${fields.length}');
    print(
        '   Using: ${fields.isNotEmpty ? 'fields' : 'schema'} (${fieldsList.length} items)');

    StringBuffer yaml = StringBuffer();

    // Schema metadata header
    yaml.writeln('# ==========================================');
    yaml.writeln('# Schema: $name');
    yaml.writeln('# Type: $collectionType');
    yaml.writeln(
        '# Description: ${_generateTableDescription(name, collectionType)}');
    yaml.writeln('# Created: $created');
    yaml.writeln('# Updated: $updated');
    yaml.writeln('# Extracted: ${DateTime.now().toIso8601String()}');
    yaml.writeln('# ==========================================');
    yaml.writeln();

    yaml.writeln('table: $name');
    yaml.writeln(
        'description: "${_generateTableDescription(name, collectionType)}"');
    yaml.writeln('type: $collectionType');
    yaml.writeln();
    yaml.writeln('fields:');

    // Always add ID field first (PocketBase creates it automatically)
    yaml.writeln('  # Primary identifier');
    yaml.writeln('  - name: id');
    yaml.writeln('    type: text');
    yaml.writeln('    primaryKey: true');
    yaml.writeln(
        '    description: "Unique identifier for records in this table"');
    yaml.writeln('    primaryKey: true');
    yaml.writeln();

    // Group fields by category for better organization
    List<Map<String, dynamic>> businessFields = [];
    List<Map<String, dynamic>> auditFields = [];
    List<Map<String, dynamic>> syncFields = [];
    List<Map<String, dynamic>> otherFields = [];

    for (var field in fieldsList) {
      if (field is Map<String, dynamic>) {
        final fieldInfo = _extractFieldInfo(field);
        final fieldName = fieldInfo['name'] as String;

        // Skip the ID field as we already added it
        if (fieldName == 'id') continue;

        // Categorize fields
        if (_isAuditField(fieldName)) {
          auditFields.add(fieldInfo);
        } else if (_isSyncField(fieldName)) {
          syncFields.add(fieldInfo);
        } else if (_isBusinessField(fieldName)) {
          businessFields.add(fieldInfo);
        } else {
          otherFields.add(fieldInfo);
        }
      }
    }

    // Multi-tenant isolation (if organizationId exists)
    final hasOrgId = [...businessFields, ...otherFields]
        .any((f) => f['name'] == 'organizationId');
    if (hasOrgId) {
      yaml.writeln('  # Multi-tenant isolation');
      _writeFieldsToYaml(yaml,
          businessFields.where((f) => f['name'] == 'organizationId').toList());
      yaml.writeln();
      businessFields.removeWhere((f) => f['name'] == 'organizationId');
    }

    // Business logic fields
    if (businessFields.isNotEmpty || otherFields.isNotEmpty) {
      yaml.writeln('  # Business logic fields');
      _writeFieldsToYaml(yaml, [...businessFields, ...otherFields]);
      yaml.writeln();
    }

    // Audit trail fields
    if (auditFields.isNotEmpty) {
      yaml.writeln('  # Audit trail fields');
      _writeFieldsToYaml(yaml, auditFields);
      yaml.writeln();
    }

    // Sync metadata fields
    if (syncFields.isNotEmpty) {
      yaml.writeln('  # Sync metadata fields');
      _writeFieldsToYaml(yaml, syncFields);
    }

    // Add suggested indexes based on common patterns
    _addSuggestedIndexes(
        yaml, name, [...businessFields, ...otherFields, ...auditFields]);

    return yaml.toString();
  }

  /// Write fields to YAML format
  void _writeFieldsToYaml(
      StringBuffer yaml, List<Map<String, dynamic>> fields) {
    for (var field in fields) {
      yaml.writeln('  - name: ${field['name']}');
      yaml.writeln('    type: ${field['type']}');

      if (field['description'] != null) {
        yaml.writeln('    description: "${field['description']}"');
      }

      if (field['primaryKey'] == true) {
        yaml.writeln('    primaryKey: true');
      }

      if (field['required'] == true) {
        yaml.writeln('    required: true');
      }

      if (field['default'] != null) {
        yaml.writeln('    default: ${field['default']}');
      }

      // Add relationship information
      if (field['relationship'] != null) {
        final rel = field['relationship'] as Map<String, dynamic>;
        yaml.writeln('    relationship:');
        yaml.writeln('      type: ${rel['type']}');
        yaml.writeln('      collectionId: "${rel['collectionId']}"');
        yaml.writeln('      maxSelect: ${rel['maxSelect']}');
        yaml.writeln('      minSelect: ${rel['minSelect']}');
        yaml.writeln('      cascadeDelete: ${rel['cascadeDelete']}');
      }

      // Add select options
      if (field['options'] != null) {
        final opts = field['options'] as Map<String, dynamic>;
        yaml.writeln('    options:');
        if (opts['values'] != null) {
          yaml.writeln('      values: ${opts['values']}');
        }
        if (opts['maxSelect'] != null) {
          yaml.writeln('      maxSelect: ${opts['maxSelect']}');
        }
      }

      // Add file options
      if (field['fileOptions'] != null) {
        final fileOpts = field['fileOptions'] as Map<String, dynamic>;
        yaml.writeln('    fileOptions:');
        yaml.writeln('      maxSelect: ${fileOpts['maxSelect']}');
        yaml.writeln('      maxSize: ${fileOpts['maxSize']}');
        if (fileOpts['mimeTypes'] != null &&
            (fileOpts['mimeTypes'] as List).isNotEmpty) {
          yaml.writeln('      mimeTypes: ${fileOpts['mimeTypes']}');
        }
      }

      // Add validation constraints
      if (field['validation'] != null) {
        final validation = field['validation'] as Map<String, dynamic>;
        yaml.writeln('    validation:');
        if (validation['min'] != null)
          yaml.writeln('      min: ${validation['min']}');
        if (validation['max'] != null)
          yaml.writeln('      max: ${validation['max']}');
        if (validation['pattern'] != null)
          yaml.writeln('      pattern: "${validation['pattern']}"');
      }

      yaml.writeln();
    }
  }

  /// Check if field is an audit field
  bool _isAuditField(String fieldName) {
    return ['createdBy', 'updatedBy', 'createdAt', 'updatedAt', 'deletedAt']
        .contains(fieldName);
  }

  /// Check if field is a sync field
  bool _isSyncField(String fieldName) {
    return ['lastSyncedAt', 'isDirty', 'syncVersion', 'isDeleted']
        .contains(fieldName);
  }

  /// Check if field is a business field (high priority)
  bool _isBusinessField(String fieldName) {
    return [
      'organizationId',
      'name',
      'title',
      'description',
      'isActive',
      'status'
    ].contains(fieldName);
  }

  /// Add suggested indexes based on common patterns
  void _addSuggestedIndexes(
      StringBuffer yaml, String tableName, List<Map<String, dynamic>> fields) {
    List<String> indexes = [];

    // Check for common indexable fields
    bool hasOrgId = fields.any((f) => f['name'] == 'organizationId');
    bool hasCreatedBy = fields.any((f) => f['name'] == 'createdBy');
    bool hasIsActive = fields.any((f) => f['name'] == 'isActive');
    bool hasIsDeleted = fields.any((f) => f['name'] == 'isDeleted');
    bool hasStatus = fields.any((f) => f['name'] == 'status');

    if (hasOrgId) {
      indexes
          .add('  - fields: [organizationId]\n    name: idx_${tableName}_org');
    }

    if (hasOrgId && hasIsActive) {
      indexes.add(
          '  - fields: [organizationId, isActive]\n    name: idx_${tableName}_org_active');
    }

    if (hasIsActive && hasIsDeleted) {
      indexes.add(
          '  - fields: [isActive, isDeleted]\n    name: idx_${tableName}_active_status');
    }

    if (hasCreatedBy) {
      indexes.add(
          '  - fields: [createdBy]\n    name: idx_${tableName}_created_by');
    }

    if (hasStatus) {
      indexes.add('  - fields: [status]\n    name: idx_${tableName}_status');
    }

    if (indexes.isNotEmpty) {
      yaml.writeln('# Suggested indexes for performance');
      yaml.writeln('indexes:');
      for (var index in indexes) {
        yaml.writeln(index);
      }
    }
  }

  /// Save YAML content to file
  Future<bool> saveYamlFile(String filename, String content) async {
    try {
      // Ensure output directory exists
      final dir = Directory(outputDir);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      final file = File('$outputDir/$filename');
      await file.writeAsString(content);
      print('✅ Saved: $filename');
      return true;
    } catch (e) {
      print('❌ Error saving $filename: $e');
      return false;
    }
  }

  /// Extract all collections to YAML files
  Future<bool> extractAllCollections() async {
    try {
      final collections = await getAllCollections();

      if (collections.isEmpty) {
        print('ℹ️ No collections found in PocketBase');
        return true;
      }

      print('📋 Found ${collections.length} collections');
      print('---');

      int successCount = 0;
      for (var collection in collections) {
        final name = collection['name'] as String;
        final collectionId = collection['id'] as String;
        final isSystem = collection['system'] as bool? ?? false;

        // Skip system collections unless explicitly requested
        if (isSystem) {
          print('⏭️  Skipping system collection: $name');
          continue;
        }

        print('📄 Processing collection: $name (ID: $collectionId)');

        // Try to get detailed collection info if schema/fields are empty
        var collectionData = collection;
        final schema = collection['schema'] as List<dynamic>? ?? [];
        final fields = collection['fields'] as List<dynamic>? ?? [];

        if (schema.isEmpty && fields.isEmpty) {
          print(
              '   🔍 Schema and fields empty, fetching detailed collection info...');
          final detailedData = await getCollectionDetails(collectionId);
          if (detailedData != null) {
            collectionData = detailedData;
          }
        }
        final yamlContent = _generateYamlContent(collectionData);
        final filename = '$name.yaml';

        final success = await saveYamlFile(filename, yamlContent);
        if (success) {
          successCount++;
        }
      }

      print('---');
      print('✅ Successfully extracted $successCount collections to YAML files');
      print('📁 Output directory: $outputDir');

      return true;
    } catch (e) {
      print('❌ Error extracting collections: $e');
      return false;
    }
  }
}

void main(List<String> arguments) async {
  // Default values
  String pocketbaseUrl = 'http://localhost:8090';
  String adminEmail = 'admin@example.com';
  String adminPassword = 'password123';
  String outputDir = 'tools/schema';

  // Parse command line arguments
  if (arguments.isNotEmpty) pocketbaseUrl = arguments[0];
  if (arguments.length > 1) adminEmail = arguments[1];
  if (arguments.length > 2) adminPassword = arguments[2];
  if (arguments.length > 3) outputDir = arguments[3];

  if (arguments.isEmpty) {
    print('''
Usage: dart tools/pocketbase_schema_extractor.dart [pocketbase_url] [admin_email] [admin_password] [output_dir]

Examples:
  dart tools/pocketbase_schema_extractor.dart
  dart tools/pocketbase_schema_extractor.dart http://localhost:8090 admin@example.com password123 tools/schema

For passwords with special characters, use quotes:
  dart tools/pocketbase_schema_extractor.dart http://localhost:8090 'admin@example.com' 'complex^password' tools/schema

Default values:
  pocketbase_url: http://localhost:8090
  admin_email: admin@example.com  
  admin_password: password123
  output_dir: tools/schema

This script will extract all non-system collections from PocketBase and create YAML schema files.
''');
  }

  print('🔍 PocketBase Schema Extractor');
  print('🌐 PocketBase URL: $pocketbaseUrl');
  print('👤 Admin email: $adminEmail');
  print('🔑 Password length: ${adminPassword.length} characters');
  print('📁 Output directory: $outputDir');
  print('---');

  final extractor = PocketBaseSchemaExtractor(
    baseUrl: pocketbaseUrl,
    adminEmail: adminEmail,
    adminPassword: adminPassword,
    outputDir: outputDir,
  );

  // Authenticate
  final authenticated = await extractor.authenticate();
  if (!authenticated) {
    print('❌ Failed to authenticate with PocketBase');
    exit(1);
  }

  // Extract collections
  final success = await extractor.extractAllCollections();
  if (success) {
    print('✅ Schema extraction completed successfully');
  } else {
    print('❌ Schema extraction failed');
    exit(1);
  }
}
