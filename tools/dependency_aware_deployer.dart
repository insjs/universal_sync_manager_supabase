import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';

/// Dependency-Aware PocketBase Schema Deployer
///
/// This deployer validates that target collections exist before creating relationships,
/// ensuring that relation fields are created successfully.
///
/// Usage:
/// dart tools/dependency_aware_deployer.dart <schema_file> [pocketbase_url] [admin_email] [admin_password]
class DependencyAwareDeployer {
  final String baseUrl;
  final String adminEmail;
  final String adminPassword;
  String? _authToken;

  DependencyAwareDeployer({
    required this.baseUrl,
    required this.adminEmail,
    required this.adminPassword,
  });

  /// Main deployment method with dependency checking
  Future<void> deploySchemaWithDependencies(String schemaPath) async {
    print('🚀 Dependency-Aware Schema Deployer');
    print('📄 Schema: $schemaPath');
    print('🌐 PocketBase URL: $baseUrl');
    print('👤 Admin email: $adminEmail');
    print('---');

    // Authenticate
    if (!await _authenticate()) {
      throw Exception('❌ Authentication failed');
    }
    print('✅ Authenticated with PocketBase');

    // Load and validate schema
    final schema = await _loadSchema(schemaPath);

    // Check dependencies
    final relationFields = _extractRelationFields(schema);
    if (relationFields.isNotEmpty) {
      print('🔍 Checking relationship dependencies...');
      await _validateDependencies(relationFields);
      print('✅ All dependencies validated');
    } else {
      print('ℹ️  No relationship fields found');
    }

    // Deploy schema
    await _deploySchema(schema);
    print('✅ Schema deployment completed successfully');
  }

  /// Load YAML schema file
  Future<Map<String, dynamic>> _loadSchema(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('Schema file not found: $filePath');
    }

    final yamlString = await file.readAsString();
    final yamlDoc = loadYaml(yamlString);
    return Map<String, dynamic>.from(yamlDoc);
  }

  /// Extract relation fields from schema
  List<Map<String, dynamic>> _extractRelationFields(
      Map<String, dynamic> schema) {
    final fields = schema['fields'] as List? ?? [];
    final relationFields = <Map<String, dynamic>>[];

    for (final field in fields) {
      final fieldMap = Map<String, dynamic>.from(field);
      if (fieldMap['relationship'] != null || fieldMap['type'] == 'relation') {
        relationFields.add(fieldMap);
      }
    }

    return relationFields;
  }

  /// Validate that all target collections exist
  Future<void> _validateDependencies(
      List<Map<String, dynamic>> relationFields) async {
    final requiredCollections = <String>{};

    // Extract target collections
    for (final field in relationFields) {
      String? targetCollection;

      if (field['relationship'] != null) {
        final relationship = field['relationship'] as Map<dynamic, dynamic>;
        targetCollection = relationship['collectionId'] as String?;
      } else if (field['targetCollection'] != null) {
        targetCollection = field['targetCollection'] as String?;
      }

      if (targetCollection != null && targetCollection.isNotEmpty) {
        requiredCollections.add(targetCollection);
      }
    }

    // Check each required collection
    for (final collectionName in requiredCollections) {
      final exists = await _collectionExists(collectionName);
      if (!exists) {
        throw Exception(
            '❌ Missing dependency: Collection "$collectionName" does not exist.\n'
            '   Deploy this collection first before creating relationships to it.');
      }
      print('   ✅ $collectionName - exists');
    }
  }

  /// Check if a collection exists
  Future<bool> _collectionExists(String collectionName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/collections/$collectionName'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Deploy the schema using enhanced logic
  Future<void> _deploySchema(Map<String, dynamic> schema) async {
    final tableName = schema['table'] as String;
    final fields = schema['fields'] as List? ?? [];

    // Check if collection exists
    final collectionExists = await _collectionExists(tableName);

    if (collectionExists) {
      print('📝 Updating existing collection: $tableName');
      await _updateCollection(tableName, fields);
    } else {
      print('📄 Creating new collection: $tableName');
      await _createCollection(schema);
    }
  }

  /// Create new collection with all fields
  Future<void> _createCollection(Map<String, dynamic> schema) async {
    final tableName = schema['table'] as String;
    final fields = schema['fields'] as List? ?? [];

    final collectionData = {
      'name': tableName,
      'type': 'base',
      'system': false,
      'fields': await _convertFieldsToSchema(fields),
      'indexes': [],
      'listRule': null,
      'viewRule': null,
      'createRule': null,
      'updateRule': null,
      'deleteRule': null,
      'options': {},
    };

    final response = await http.post(
      Uri.parse('$baseUrl/api/collections'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_authToken',
      },
      body: jsonEncode(collectionData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create collection: ${response.body}');
    }
  }

  /// Update existing collection fields
  Future<void> _updateCollection(String tableName, List fields) async {
    // Get current collection info
    final currentCollection = await _getCollection(tableName);
    if (currentCollection == null) {
      throw Exception('Collection not found: $tableName');
    }

    // Convert new fields to schema
    final newSchema = await _convertFieldsToSchema(fields);

    final updateData = {
      'name': tableName,
      'type': currentCollection['type'],
      'system': currentCollection['system'],
      'fields': newSchema,
      'indexes': currentCollection['indexes'] ?? [],
      'listRule': currentCollection['listRule'],
      'viewRule': currentCollection['viewRule'],
      'createRule': currentCollection['createRule'],
      'updateRule': currentCollection['updateRule'],
      'deleteRule': currentCollection['deleteRule'],
      'options': currentCollection['options'] ?? {},
    };

    final collectionId = currentCollection['id'] as String;
    final response = await http.patch(
      Uri.parse('$baseUrl/api/collections/$collectionId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_authToken',
      },
      body: jsonEncode(updateData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update collection: ${response.body}');
    }
  }

  /// Get collection details
  Future<Map<String, dynamic>?> _getCollection(String collectionName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/collections/$collectionName'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Convert YAML fields to PocketBase schema format
  Future<List<Map<String, dynamic>>> _convertFieldsToSchema(List fields) async {
    final schema = <Map<String, dynamic>>[];

    for (final field in fields) {
      final fieldMap = Map<String, dynamic>.from(field);
      final pbField = await _convertYamlFieldToPocketBase(fieldMap);
      if (pbField != null) {
        schema.add(pbField);
      }
    }

    return schema;
  }

  /// Convert individual YAML field to PocketBase format
  Future<Map<String, dynamic>?> _convertYamlFieldToPocketBase(
      Map<String, dynamic> field) async {
    final name = field['name'] as String;
    final type = field['type'] as String;
    final isRequired = field['required'] == true;

    // Skip ID field (auto-generated)
    if (name == 'id') return null;

    // Handle relationship fields
    if (field['relationship'] != null || type == 'relation') {
      return await _createRelationField(field);
    }

    switch (type) {
      case 'text':
        return {
          'name': name,
          'type': 'text',
          'required': isRequired,
          'presentable': false,
          'options': {
            'max': field['validation']?['max'] ?? 0,
            'min': field['validation']?['min'] ?? 0,
            'pattern': field['validation']?['pattern'] ?? '',
          },
        };

      case 'integer':
        return {
          'name': name,
          'type': 'number',
          'required': isRequired,
          'presentable': false,
          'options': {
            'max': field['validation']?['max'],
            'min': field['validation']?['min'],
            'noDecimal': true,
          },
        };

      case 'real':
      case 'float':
        return {
          'name': name,
          'type': 'number',
          'required': isRequired,
          'presentable': false,
          'options': {
            'max': field['validation']?['max'],
            'min': field['validation']?['min'],
            'noDecimal': false,
          },
        };

      case 'boolean':
        return {
          'name': name,
          'type': 'bool',
          'required': isRequired,
          'presentable': false,
          'options': {},
        };

      case 'datetime':
        return {
          'name': name,
          'type': 'date',
          'required': isRequired,
          'presentable': false,
          'options': {
            'max': '',
            'min': '',
          },
        };

      case 'json':
        return {
          'name': name,
          'type': 'json',
          'required': isRequired,
          'presentable': false,
          'options': {
            'maxSize': 2000000,
          },
        };

      default:
        print(
            '⚠️  Unknown field type: $type for field: $name - treating as text');
        return {
          'name': name,
          'type': 'text',
          'required': isRequired,
          'presentable': false,
          'options': {
            'max': 0,
            'min': 0,
            'pattern': '',
          },
        };
    }
  }

  /// Create relationship field
  Future<Map<String, dynamic>> _createRelationField(
      Map<String, dynamic> field) async {
    final name = field['name'] as String;
    final isRequired = field['required'] == true;

    print('🔧 Processing relation field: $name');

    String? targetCollection;
    int maxSelect = 1;
    int minSelect = 0;
    bool cascadeDelete = false;

    if (field['relationship'] != null) {
      final relationship = field['relationship'] as Map<dynamic, dynamic>;
      targetCollection = relationship['collectionId'] as String?;
      maxSelect = relationship['maxSelect'] ?? 1;
      minSelect = relationship['minSelect'] ?? 0;
      cascadeDelete = relationship['cascadeDelete'] ?? false;
      print('   Relationship config: $relationship');
    } else {
      targetCollection = field['targetCollection'] as String?;
      maxSelect = field['maxSelect'] ?? 1;
      minSelect = field['minSelect'] ?? 0;
      cascadeDelete = field['cascadeDelete'] ?? false;
    }

    if (targetCollection == null || targetCollection.isEmpty) {
      throw Exception('Relation field "$name" missing target collection');
    }

    print('   Target collection: $targetCollection');

    // Get target collection ID
    final targetCollectionData = await _getCollection(targetCollection);
    if (targetCollectionData == null) {
      throw Exception(
          'Target collection "$targetCollection" not found for field "$name"');
    }

    final collectionId = targetCollectionData['id'] as String;
    print('   Resolved collection ID: $collectionId');

    final relationField = {
      'name': name,
      'type': 'relation',
      'required': isRequired,
      'presentable': false,
      'collectionId': collectionId,
      'cascadeDelete': cascadeDelete,
      'minSelect': minSelect,
      'maxSelect': maxSelect,
      'displayFields': null,
    };

    print('   Generated field: ${jsonEncode(relationField)}');
    return relationField;
  }

  /// Authenticate with PocketBase
  Future<bool> _authenticate() async {
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/api/collections/_superusers/auth-with-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identity': adminEmail,
          'password': adminPassword,
        }),
      );

      // If that fails, try the older admin endpoint
      if (response.statusCode == 404) {
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
        _authToken = data['token'] as String;
        return true;
      }

      print('❌ Authentication failed: ${response.body}');
      return false;
    } catch (e) {
      print('❌ Authentication error: $e');
      return false;
    }
  }
}

/// Main function for command line usage
Future<void> main(List<String> args) async {
  print('🚀 Dependency-Aware PocketBase Schema Deployer');

  if (args.isEmpty) {
    print(
        'Usage: dart dependency_aware_deployer.dart <schema_file> [pocketbase_url] [admin_email] [admin_password]');
    print('');
    print('Examples:');
    print(
        '  dart dependency_aware_deployer.dart schema/ost_managed_users_test_with_relations.yaml');
    print(
        '  dart dependency_aware_deployer.dart schema/test.yaml http://localhost:8090 admin@example.com password123');
    print('');
    print('Default values:');
    print('  pocketbase_url: http://localhost:8090');
    print('  admin_email: admin@example.com');
    print('  admin_password: password123');
    exit(1);
  }

  final schemaFile = args[0];
  final pocketbaseUrl = args.length > 1 ? args[1] : 'http://localhost:8090';
  final adminEmail = args.length > 2 ? args[2] : 'admin@example.com';
  final adminPassword = args.length > 3 ? args[3] : 'password123';

  try {
    final deployer = DependencyAwareDeployer(
      baseUrl: pocketbaseUrl,
      adminEmail: adminEmail,
      adminPassword: adminPassword,
    );

    await deployer.deploySchemaWithDependencies(schemaFile);
  } catch (e) {
    print('❌ Deployment failed: $e');
    exit(1);
  }
}
