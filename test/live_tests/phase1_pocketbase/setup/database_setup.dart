// test/live_tests/phase1_pocketbase/setup/database_setup.dart

import 'dart:io';
import 'dart:convert';
import 'package:yaml/yaml.dart';

/// SQLite Database Setup for USM Live Testing
///
/// This script creates and initializes the local SQLite database
/// for Universal Sync Manager live testing with PocketBase.
///
/// Note: This creates the SQL schema files that can be executed
/// to set up the database. For actual SQLite operations, you'll
/// need to add sqlite3 dependency to pubspec.yaml.
class DatabaseSetup {
  late Map<String, dynamic> _config;
  late Map<String, dynamic> _schema;
  String? _dbPath;

  /// Initialize database setup
  Future<void> initialize() async {
    print('🔧 Initializing SQLite Database Setup...');

    // Load configuration
    await _loadConfiguration();

    // Load schema
    await _loadSchema();

    // Generate database schema
    await _generateDatabaseSchema();

    print('✅ Database setup completed successfully!');
  }

  /// Load configuration from YAML
  Future<void> _loadConfiguration() async {
    try {
      // Try multiple possible paths for the configuration file
      final possiblePaths = [
        'config.yaml', // From setup directory
        'setup/config.yaml', // From tests directory
        'test/live_tests/phase1_pocketbase/setup/config.yaml', // From project root
      ];

      File? configFile;
      for (final path in possiblePaths) {
        final file = File(path);
        if (await file.exists()) {
          configFile = file;
          break;
        }
      }

      if (configFile == null) {
        throw Exception(
            'Configuration file not found. Tried: ${possiblePaths.join(', ')}');
      }

      final configContent = await configFile.readAsString();
      final doc = loadYaml(configContent);
      _config = _convertYamlToMap(doc);

      print('📋 Configuration loaded from: ${configFile.path}');
    } catch (e) {
      throw Exception('Failed to load configuration: $e');
    }
  }

  /// Convert YAML to Map<String, dynamic> safely
  Map<String, dynamic> _convertYamlToMap(dynamic yamlDoc) {
    return Map<String, dynamic>.from(
      json.decode(json.encode(yamlDoc)) as Map<String, dynamic>,
    );
  }

  /// Load schema definition from YAML
  Future<void> _loadSchema() async {
    try {
      // Try multiple possible paths for the schema file
      final possiblePaths = [
        'schemas/usm_test.yaml', // From setup directory
        '../schemas/usm_test.yaml', // From tests directory
        'test/live_tests/phase1_pocketbase/schemas/usm_test.yaml', // From project root
        'tools/schema/usm_test.yaml', // Tools directory
      ];

      File? schemaFile;
      for (final path in possiblePaths) {
        final file = File(path);
        if (await file.exists()) {
          schemaFile = file;
          break;
        }
      }

      if (schemaFile == null) {
        throw Exception(
            'Schema file not found. Tried: ${possiblePaths.join(', ')}');
      }

      final schemaContent = await schemaFile.readAsString();
      final doc = loadYaml(schemaContent);
      _schema = _convertYamlToMap(doc);

      print(
          '📄 Schema loaded from: ${schemaFile.path} (table: ${_schema['table']})');
    } catch (e) {
      throw Exception('Failed to load schema: $e');
    }
  }

  /// Generate SQLite database schema files
  Future<void> _generateDatabaseSchema() async {
    try {
      final dbConfig = _config['database'] as Map<String, dynamic>;
      _dbPath = dbConfig['path'] as String;

      // Generate SQL schema
      final sqlSchema = _generateSQLSchema();

      // Write schema to file
      final schemaFile = File('database_schema.sql');
      await schemaFile.writeAsString(sqlSchema);
      print('📝 SQL schema written to: ${schemaFile.path}');

      // Generate Dart model
      final dartModel = _generateDartModel();

      // Write model to file
      final modelFile = File('usm_test_model.dart');
      await modelFile.writeAsString(dartModel);
      print('📱 Dart model written to: ${modelFile.path}');

      // Generate database helper
      final dbHelper = _generateDatabaseHelper();

      // Write helper to file
      final helperFile = File('database_helper.dart');
      await helperFile.writeAsString(dbHelper);
      print('📝 Database helper written to: ${helperFile.path}');
    } catch (e) {
      throw Exception('Failed to generate database schema: $e');
    }
  }

  /// Generate SQL CREATE TABLE statement
  String _generateSQLSchema() {
    final tableName = _schema['table'] as String;
    final fields = _schema['fields'] as List;
    final indexes = _schema['indexes'] as List?;

    final sql = StringBuffer();

    // Add header comment
    sql.writeln('-- USM Live Testing Database Schema');
    sql.writeln('-- Generated on: ${DateTime.now().toIso8601String()}');
    sql.writeln('-- Table: $tableName');
    sql.writeln('');

    // Enable foreign keys
    sql.writeln('PRAGMA foreign_keys = ON;');
    sql.writeln('');

    // Build CREATE TABLE statement
    sql.writeln('-- Create main table');
    sql.writeln('CREATE TABLE IF NOT EXISTS $tableName (');

    final fieldDefinitions = <String>[];

    for (final field in fields) {
      final fieldMap = Map<String, dynamic>.from(field);
      final fieldName = fieldMap['name'] as String;
      final fieldType = fieldMap['type'] as String;
      final isPrimaryKey = fieldMap['primaryKey'] == true;
      final isRequired = fieldMap['required'] == true;
      final defaultValue = fieldMap['default'];
      final description = fieldMap['description'] as String?;

      // Convert YAML type to SQLite type
      String sqliteType = _convertToSQLiteType(fieldType);

      // Build field definition
      var fieldDef = '    $fieldName $sqliteType';

      if (isPrimaryKey) {
        fieldDef += ' PRIMARY KEY';
      }

      if (isRequired && !isPrimaryKey) {
        fieldDef += ' NOT NULL';
      }

      if (defaultValue != null) {
        if (fieldType == 'text') {
          fieldDef += " DEFAULT '$defaultValue'";
        } else {
          fieldDef += ' DEFAULT $defaultValue';
        }
      }

      if (description != null) {
        fieldDef += ' -- $description';
      }

      fieldDefinitions.add(fieldDef);
    }

    // Join field definitions with proper comma placement
    final fieldLines = <String>[];
    for (int i = 0; i < fieldDefinitions.length; i++) {
      final fieldDef = fieldDefinitions[i];
      if (i < fieldDefinitions.length - 1) {
        // Add comma before comment for all except last field
        if (fieldDef.contains(' -- ')) {
          final parts = fieldDef.split(' -- ');
          fieldLines.add('${parts[0]}, -- ${parts[1]}');
        } else {
          fieldLines.add('$fieldDef,');
        }
      } else {
        // Last field doesn't need comma
        fieldLines.add(fieldDef);
      }
    }

    sql.writeln(fieldLines.join('\n'));
    sql.writeln(');');
    sql.writeln('');

    // Create indexes
    if (indexes != null && indexes.isNotEmpty) {
      sql.writeln('-- Create indexes');
      for (final index in indexes) {
        final indexMap = Map<String, dynamic>.from(index);
        final indexName = indexMap['name'] as String;
        final indexFields = List<String>.from(indexMap['fields']);

        sql.writeln('CREATE INDEX IF NOT EXISTS $indexName ');
        sql.writeln('    ON $tableName (${indexFields.join(', ')});');
      }
      sql.writeln('');
    }

    return sql.toString();
  }

  /// Generate Dart model class
  String _generateDartModel() {
    final tableName = _schema['table'] as String;
    final fields = _schema['fields'] as List;
    final className = _toPascalCase(tableName);

    final dart = StringBuffer();

    // Add header
    dart.writeln('// USM Live Testing Model');
    dart.writeln('// Generated on: ${DateTime.now().toIso8601String()}');
    dart.writeln('// Table: $tableName');
    dart.writeln('');
    dart.writeln("import '../../../lib/src/models/usm_syncable_model.dart';");
    dart.writeln('');

    // Class definition
    dart.writeln('/// $className model for USM live testing');
    dart.writeln('class $className with SyncableModel {');

    // Fields
    for (final field in fields) {
      final fieldMap = Map<String, dynamic>.from(field);
      final fieldName = fieldMap['name'] as String;
      final fieldType = fieldMap['type'] as String;
      final isRequired = fieldMap['required'] == true;
      final description = fieldMap['description'] as String?;

      final dartType = _convertToDartType(fieldType, isRequired);

      if (description != null) {
        dart.writeln('  /// $description');
      }
      dart.writeln('  final $dartType $fieldName;');
      dart.writeln('');
    }

    // Constructor
    dart.writeln('  /// Constructor');
    dart.writeln('  const $className({');
    for (final field in fields) {
      final fieldMap = Map<String, dynamic>.from(field);
      final fieldName = fieldMap['name'] as String;
      final isRequired = fieldMap['required'] == true;

      if (isRequired) {
        dart.writeln('    required this.$fieldName,');
      } else {
        dart.writeln('    this.$fieldName,');
      }
    }
    dart.writeln('  });');
    dart.writeln('');

    // fromMap factory
    dart.writeln('  /// Create from Map');
    dart.writeln('  factory $className.fromMap(Map<String, dynamic> map) {');
    dart.writeln('    return $className(');
    for (final field in fields) {
      final fieldMap = Map<String, dynamic>.from(field);
      final fieldName = fieldMap['name'] as String;
      final fieldType = fieldMap['type'] as String;

      if (fieldType == 'integer') {
        dart.writeln("      $fieldName: map['$fieldName'] as int?,");
      } else if (fieldType == 'real') {
        dart.writeln("      $fieldName: map['$fieldName'] as double?,");
      } else {
        dart.writeln("      $fieldName: map['$fieldName'] as String?,");
      }
    }
    dart.writeln('    );');
    dart.writeln('  }');
    dart.writeln('');

    // toMap method
    dart.writeln('  /// Convert to Map');
    dart.writeln('  Map<String, dynamic> toMap() {');
    dart.writeln('    return {');
    for (final field in fields) {
      final fieldMap = Map<String, dynamic>.from(field);
      final fieldName = fieldMap['name'] as String;
      dart.writeln("      '$fieldName': $fieldName,");
    }
    dart.writeln('    };');
    dart.writeln('  }');
    dart.writeln('');

    // SyncableModel implementation
    dart.writeln('  @override');
    dart.writeln('  $className copyWith({');
    for (final field in fields) {
      final fieldMap = Map<String, dynamic>.from(field);
      final fieldName = fieldMap['name'] as String;
      final fieldType = fieldMap['type'] as String;
      final dartType = _convertToDartType(fieldType, false);
      dart.writeln('    $dartType $fieldName,');
    }
    dart.writeln('  }) {');
    dart.writeln('    return $className(');
    for (final field in fields) {
      final fieldMap = Map<String, dynamic>.from(field);
      final fieldName = fieldMap['name'] as String;
      dart.writeln('      $fieldName: $fieldName ?? this.$fieldName,');
    }
    dart.writeln('    );');
    dart.writeln('  }');
    dart.writeln('}');

    return dart.toString();
  }

  /// Generate database helper class
  String _generateDatabaseHelper() {
    final tableName = _schema['table'] as String;
    final className = _toPascalCase(tableName);

    final dart = StringBuffer();

    dart.writeln('// USM Live Testing Database Helper');
    dart.writeln('// Generated on: ${DateTime.now().toIso8601String()}');
    dart.writeln('');
    dart.writeln("import 'dart:io';");
    dart.writeln("import 'usm_test_model.dart';");
    dart.writeln('');
    dart.writeln('/// Database helper for $tableName table');
    dart.writeln('class ${className}DatabaseHelper {');
    dart.writeln("  static const String tableName = '$tableName';");
    dart.writeln(
        "  static const String dbPath = '${_dbPath ?? 'usmtest.db'}';");
    dart.writeln('');
    dart.writeln('  /// Initialize database');
    dart.writeln('  static Future<void> initializeDatabase() async {');
    dart.writeln('    // TODO: Add SQLite initialization code');
    dart.writeln(
        '    // This requires adding sqlite3 dependency to pubspec.yaml');
    dart.writeln("    print('Database initialization placeholder');");
    dart.writeln('  }');
    dart.writeln('');
    dart.writeln('  /// Insert record');
    dart.writeln('  static Future<bool> insert($className record) async {');
    dart.writeln('    // TODO: Add insert implementation');
    dart.writeln('    return true;');
    dart.writeln('  }');
    dart.writeln('');
    dart.writeln('  /// Update record');
    dart.writeln('  static Future<bool> update($className record) async {');
    dart.writeln('    // TODO: Add update implementation');
    dart.writeln('    return true;');
    dart.writeln('  }');
    dart.writeln('');
    dart.writeln('  /// Delete record');
    dart.writeln('  static Future<bool> delete(String id) async {');
    dart.writeln('    // TODO: Add delete implementation');
    dart.writeln('    return true;');
    dart.writeln('  }');
    dart.writeln('');
    dart.writeln('  /// Get all records');
    dart.writeln('  static Future<List<$className>> getAll() async {');
    dart.writeln('    // TODO: Add getAll implementation');
    dart.writeln('    return [];');
    dart.writeln('  }');
    dart.writeln('');
    dart.writeln('  /// Get by ID');
    dart.writeln('  static Future<$className?> getById(String id) async {');
    dart.writeln('    // TODO: Add getById implementation');
    dart.writeln('    return null;');
    dart.writeln('  }');
    dart.writeln('}');

    return dart.toString();
  }

  /// Convert YAML field type to SQLite type
  String _convertToSQLiteType(String yamlType) {
    switch (yamlType.toLowerCase()) {
      case 'text':
      case 'string':
        return 'TEXT';
      case 'integer':
      case 'int':
        return 'INTEGER';
      case 'real':
      case 'float':
      case 'double':
        return 'REAL';
      case 'blob':
        return 'BLOB';
      default:
        return 'TEXT'; // Default to TEXT for unknown types
    }
  }

  /// Convert YAML field type to Dart type
  String _convertToDartType(String yamlType, bool isRequired) {
    String baseType;
    switch (yamlType.toLowerCase()) {
      case 'integer':
      case 'int':
        baseType = 'int';
        break;
      case 'real':
      case 'float':
      case 'double':
        baseType = 'double';
        break;
      case 'text':
      case 'string':
      default:
        baseType = 'String';
        break;
    }

    return isRequired ? baseType : '$baseType?';
  }

  /// Convert snake_case to PascalCase
  String _toPascalCase(String snakeCase) {
    return snakeCase
        .split('_')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : '')
        .join('');
  }

  /// Get database configuration
  Map<String, dynamic> getDatabaseConfig() {
    return {
      'table_name': _schema['table'],
      'field_count': (_schema['fields'] as List).length,
      'index_count': (_schema['indexes'] as List?)?.length ?? 0,
      'database_path': _dbPath,
      'schema_generated': true,
    };
  }
}

/// Main entry point for database setup
Future<void> main(List<String> args) async {
  final setup = DatabaseSetup();

  try {
    await setup.initialize();

    // Show configuration
    final config = setup.getDatabaseConfig();
    print('');
    print('📊 Database Configuration:');
    print('   Table: ${config['table_name']}');
    print('   Fields: ${config['field_count']}');
    print('   Indexes: ${config['index_count']}');
    print('   Path: ${config['database_path']}');
    print('');
    print('📝 Generated Files:');
    print('   • database_schema.sql');
    print('   • usm_test_model.dart');
    print('   • database_helper.dart');
    print('');
    print('🎉 Database setup completed successfully!');
    print('');
    print('📋 Next Steps:');
    print('   1. Add sqlite3 dependency to pubspec.yaml');
    print('   2. Execute database_schema.sql to create database');
    print('   3. Use generated model and helper classes in tests');
  } catch (e) {
    print('❌ Database setup failed: $e');
    exit(1);
  }
}
