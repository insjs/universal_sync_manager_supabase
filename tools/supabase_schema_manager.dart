import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';

/// Supabase Schema Manager
///
/// This script reads YAML schema files and creates/updates tables in Supabase.
///
/// Usage:
/// dart tools/supabase_schema_manager.dart <schema_file.yaml> [supabase_url] [service_role_key]
///
/// Example:
/// dart tools/supabase_schema_manager.dart tools/schema/audit_items.yaml https://your-project.supabase.co your-service-role-key
class SupabaseSchemaManager {
  final String baseUrl;
  final String serviceRoleKey;

  SupabaseSchemaManager({
    required this.baseUrl,
    required this.serviceRoleKey,
  });

  /// Get headers with authentication
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serviceRoleKey',
        'apikey': serviceRoleKey,
      };

  /// Check if table exists
  Future<bool> tableExists(String tableName) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rest/v1/rpc/check_table_exists'),
        headers: _headers,
        body: jsonEncode({'table_name': tableName}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data == true;
      } else {
        // Fallback: try to query the table
        final queryResponse = await http.get(
          Uri.parse('$baseUrl/rest/v1/$tableName?limit=0'),
          headers: _headers,
        );
        return queryResponse.statusCode == 200;
      }
    } catch (e) {
      print('❌ Error checking table existence: $e');
      return false;
    }
  }

  /// Convert YAML field type to SQL data type
  String _convertFieldType(String yamlType) {
    switch (yamlType.toLowerCase()) {
      case 'text':
        return 'TEXT';
      case 'integer':
        return 'INTEGER';
      case 'real':
      case 'float':
        return 'REAL';
      case 'boolean':
        return 'BOOLEAN';
      case 'datetime':
        return 'TIMESTAMPTZ';
      case 'json':
        return 'JSONB';
      default:
        return 'TEXT'; // Default fallback
    }
  }

  /// Generate CREATE TABLE SQL from YAML schema
  String _generateCreateTableSQL(String tableName, List<dynamic> fields) {
    List<String> columnDefinitions = [];
    List<String> foreignKeyConstraints = [];

    for (var field in fields) {
      if (field is Map<dynamic, dynamic>) {
        final name = field['name'] as String;
        final isRequired = field['required'] == true;
        final isPrimaryKey = field['primaryKey'] == true;
        final defaultValue = field['default'];

        String columnDef;

        // Handle relationship fields
        if (field['relationship'] != null) {
          final relationship = field['relationship'] as Map<dynamic, dynamic>;
          final referencedCollection = relationship['collectionId'] as String?;

          if (referencedCollection != null && referencedCollection.isNotEmpty) {
            // For relationships, use UUID or TEXT depending on the referenced table
            columnDef = '$name TEXT';

            // Add foreign key constraint (skip system collections)
            if (!referencedCollection.startsWith('_pb_')) {
              foreignKeyConstraints.add(
                  'CONSTRAINT fk_${tableName}_${name} FOREIGN KEY ($name) REFERENCES $referencedCollection(id)');
            }
          } else {
            columnDef = '$name TEXT';
          }
        } else {
          // Regular field
          final type = _convertFieldType(field['type'] ?? 'text');
          columnDef = '$name $type';
        }

        if (isPrimaryKey) {
          columnDef += ' PRIMARY KEY';
        } else if (isRequired) {
          columnDef += ' NOT NULL';
        }

        if (defaultValue != null) {
          final fieldType = field['relationship'] != null
              ? 'TEXT'
              : _convertFieldType(field['type'] ?? 'text');
          if (fieldType == 'TEXT') {
            columnDef += " DEFAULT '$defaultValue'";
          } else {
            columnDef += ' DEFAULT $defaultValue';
          }
        }

        columnDefinitions.add(columnDef);
      }
    }

    // Combine column definitions and foreign key constraints
    List<String> allDefinitions = [
      ...columnDefinitions,
      ...foreignKeyConstraints
    ];

    return '''
CREATE TABLE IF NOT EXISTS $tableName (
  ${allDefinitions.join(',\n  ')}
);
''';
  }

  /// Generate ALTER TABLE SQL to add missing columns
  Future<List<String>> _generateAlterTableSQL(
      String tableName, List<dynamic> fields) async {
    List<String> alterStatements = [];

    // Get existing columns
    final existingColumns = await _getTableColumns(tableName);

    for (var field in fields) {
      if (field is Map<dynamic, dynamic>) {
        final name = field['name'] as String;
        final isRequired = field['required'] == true;
        final defaultValue = field['default'];

        // Check if column exists
        if (!existingColumns.contains(name)) {
          String columnType;

          // Handle relationship fields
          if (field['relationship'] != null) {
            columnType = 'TEXT';
          } else {
            columnType = _convertFieldType(field['type'] ?? 'text');
          }

          String alterStatement =
              'ALTER TABLE $tableName ADD COLUMN $name $columnType';

          if (defaultValue != null) {
            if (columnType == 'TEXT') {
              alterStatement += " DEFAULT '$defaultValue'";
            } else {
              alterStatement += ' DEFAULT $defaultValue';
            }
          }

          if (isRequired) {
            alterStatement += ' NOT NULL';
          }

          alterStatements.add('$alterStatement;');

          // Add foreign key constraint for relationship fields
          if (field['relationship'] != null) {
            final relationship = field['relationship'] as Map<dynamic, dynamic>;
            final referencedCollection =
                relationship['collectionId'] as String?;

            if (referencedCollection != null &&
                referencedCollection.isNotEmpty &&
                !referencedCollection.startsWith('_pb_')) {
              alterStatements.add(
                  'ALTER TABLE $tableName ADD CONSTRAINT fk_${tableName}_${name} '
                  'FOREIGN KEY ($name) REFERENCES $referencedCollection(id);');
            }
          }
        }
      }
    }

    return alterStatements;
  }

  /// Get existing table columns
  Future<Set<String>> _getTableColumns(String tableName) async {
    try {
      final sql = '''
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = '$tableName' 
AND table_schema = 'public';
''';

      final response = await http.post(
        Uri.parse('$baseUrl/rest/v1/rpc/execute_sql'),
        headers: _headers,
        body: jsonEncode({'sql': sql}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((row) => row['column_name'] as String).toSet();
        }
      }
    } catch (e) {
      print('❌ Error getting table columns: $e');
    }

    return <String>{};
  }

  /// Execute SQL statement
  Future<bool> executeSql(String sql) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rest/v1/rpc/execute_sql'),
        headers: _headers,
        body: jsonEncode({'sql': sql}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('❌ SQL execution failed: ${response.body}');
        print('📝 SQL: $sql');
        return false;
      }
    } catch (e) {
      print('❌ Error executing SQL: $e');
      print('📝 SQL: $sql');
      return false;
    }
  }

  /// Create indexes from YAML schema
  Future<bool> createIndexes(String tableName, List<dynamic>? indexes) async {
    if (indexes == null || indexes.isEmpty) {
      return true;
    }

    for (var index in indexes) {
      if (index is Map<dynamic, dynamic>) {
        final indexName = index['name'] as String?;
        final fields = index['fields'] as List<dynamic>?;

        if (indexName != null && fields != null) {
          final fieldList = fields.map((f) => f.toString()).join(', ');
          final sql =
              'CREATE INDEX IF NOT EXISTS $indexName ON $tableName ($fieldList);';

          final success = await executeSql(sql);
          if (success) {
            print('✅ Created index: $indexName');
          } else {
            print('❌ Failed to create index: $indexName');
            return false;
          }
        }
      }
    }

    return true;
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
      final indexes = yamlData['indexes'] as List<dynamic>?;

      if (tableName == null || fields == null) {
        print('❌ Missing table name or fields in schema');
        return false;
      }

      print('📋 Processing schema for table: $tableName');

      // Check if table exists
      final exists = await tableExists(tableName);

      if (!exists) {
        // Create new table
        print('🔨 Creating new table: $tableName');
        final createSQL = _generateCreateTableSQL(tableName, fields);

        final success = await executeSql(createSQL);
        if (!success) {
          return false;
        }

        print('✅ Created table: $tableName');
      } else {
        // Update existing table (add missing columns)
        print('🔧 Updating existing table: $tableName');
        final alterStatements = await _generateAlterTableSQL(tableName, fields);

        if (alterStatements.isNotEmpty) {
          for (final statement in alterStatements) {
            final success = await executeSql(statement);
            if (!success) {
              return false;
            }
          }
          print('✅ Updated table: $tableName');
        } else {
          print('ℹ️ Table $tableName is already up to date');
        }
      }

      // Create indexes
      final indexSuccess = await createIndexes(tableName, indexes);
      if (!indexSuccess) {
        return false;
      }

      return true;
    } catch (e) {
      print('❌ Error processing schema file: $e');
      return false;
    }
  }
}

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    print('''
Usage: dart tools/supabase_schema_manager.dart <schema_file.yaml> [supabase_url] [service_role_key]

Examples:
  dart tools/supabase_schema_manager.dart tools/schema/audit_items.yaml
  dart tools/supabase_schema_manager.dart tools/schema/audit_items.yaml https://your-project.supabase.co your-service-role-key

Environment Variables (alternative to command line args):
  SUPABASE_URL: Your Supabase project URL
  SUPABASE_SERVICE_ROLE_KEY: Your Supabase service role key

Note: You need the service role key (not anon key) to execute DDL statements.
''');
    exit(1);
  }

  final schemaFile = arguments[0];

  // Try to get URL and key from arguments or environment
  String? supabaseUrl = arguments.length > 1
      ? arguments[1]
      : Platform.environment['SUPABASE_URL'];
  String? serviceRoleKey = arguments.length > 2
      ? arguments[2]
      : Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];

  if (supabaseUrl == null || serviceRoleKey == null) {
    print('❌ Missing Supabase URL or Service Role Key');
    print(
        '💡 Provide them as arguments or set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY environment variables');
    exit(1);
  }

  // Remove trailing slash from URL
  if (supabaseUrl.endsWith('/')) {
    supabaseUrl = supabaseUrl.substring(0, supabaseUrl.length - 1);
  }

  print('🚀 Supabase Schema Manager');
  print('📁 Schema file: $schemaFile');
  print('🌐 Supabase URL: $supabaseUrl');
  print('🔑 Service Role Key: ${serviceRoleKey.substring(0, 10)}...');
  print('---');

  final manager = SupabaseSchemaManager(
    baseUrl: supabaseUrl,
    serviceRoleKey: serviceRoleKey,
  );

  // Process schema file
  final success = await manager.processSchemaFile(schemaFile);
  if (success) {
    print('✅ Schema processing completed successfully');
  } else {
    print('❌ Schema processing failed');
    exit(1);
  }
}
