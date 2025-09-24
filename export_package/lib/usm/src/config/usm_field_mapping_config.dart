/// Field mapping configuration for Universal Sync Manager
///
/// This class provides field mapping, transformation, and validation
/// capabilities for entity synchronization across different backends.
///
/// Following USM naming conventions:
/// - File: usm_field_mapping_config.dart (snake_case with usm_ prefix)
/// - Class: SyncFieldMappingConfig (PascalCase)
class SyncFieldMappingConfig {
  const SyncFieldMappingConfig({
    this.fieldMappings = const {},
    this.fieldTransformations = const {},
    this.fieldValidations = const {},
    this.excludedFields = const [],
    this.requiredFields = const [],
    this.encryptedFields = const [],
    this.defaultValues = const {},
    this.fieldTypes = const {},
    this.customRules = const {},
    this.enableAutoMapping = true,
    this.strictTypeChecking = false,
    this.allowNullValues = true,
    this.preserveCase = false,
  });

  /// Mapping from local field names to remote field names
  final Map<String, String> fieldMappings;

  /// Field transformations for data conversion
  final Map<String, FieldTransformation> fieldTransformations;

  /// Field validation rules
  final Map<String, FieldValidation> fieldValidations;

  /// Fields to exclude from synchronization
  final List<String> excludedFields;

  /// Fields that are required for synchronization
  final List<String> requiredFields;

  /// Fields that should be encrypted
  final List<String> encryptedFields;

  /// Default values for fields
  final Map<String, dynamic> defaultValues;

  /// Field type mappings
  final Map<String, FieldType> fieldTypes;

  /// Custom mapping rules
  final Map<String, CustomMappingRule> customRules;

  /// Enable automatic field mapping based on conventions
  final bool enableAutoMapping;

  /// Enable strict type checking during mapping
  final bool strictTypeChecking;

  /// Allow null values in field mappings
  final bool allowNullValues;

  /// Preserve field name case during mapping
  final bool preserveCase;

  /// Create a copy with modified properties
  SyncFieldMappingConfig copyWith({
    Map<String, String>? fieldMappings,
    Map<String, FieldTransformation>? fieldTransformations,
    Map<String, FieldValidation>? fieldValidations,
    List<String>? excludedFields,
    List<String>? requiredFields,
    List<String>? encryptedFields,
    Map<String, dynamic>? defaultValues,
    Map<String, FieldType>? fieldTypes,
    Map<String, CustomMappingRule>? customRules,
    bool? enableAutoMapping,
    bool? strictTypeChecking,
    bool? allowNullValues,
    bool? preserveCase,
  }) {
    return SyncFieldMappingConfig(
      fieldMappings: fieldMappings ?? this.fieldMappings,
      fieldTransformations: fieldTransformations ?? this.fieldTransformations,
      fieldValidations: fieldValidations ?? this.fieldValidations,
      excludedFields: excludedFields ?? this.excludedFields,
      requiredFields: requiredFields ?? this.requiredFields,
      encryptedFields: encryptedFields ?? this.encryptedFields,
      defaultValues: defaultValues ?? this.defaultValues,
      fieldTypes: fieldTypes ?? this.fieldTypes,
      customRules: customRules ?? this.customRules,
      enableAutoMapping: enableAutoMapping ?? this.enableAutoMapping,
      strictTypeChecking: strictTypeChecking ?? this.strictTypeChecking,
      allowNullValues: allowNullValues ?? this.allowNullValues,
      preserveCase: preserveCase ?? this.preserveCase,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'fieldMappings': fieldMappings,
      'fieldTransformations': fieldTransformations.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'fieldValidations': fieldValidations.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'excludedFields': excludedFields,
      'requiredFields': requiredFields,
      'encryptedFields': encryptedFields,
      'defaultValues': defaultValues,
      'fieldTypes': fieldTypes.map(
        (key, value) => MapEntry(key, value.name),
      ),
      'customRules': customRules.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'enableAutoMapping': enableAutoMapping,
      'strictTypeChecking': strictTypeChecking,
      'allowNullValues': allowNullValues,
      'preserveCase': preserveCase,
    };
  }

  /// Create from JSON
  factory SyncFieldMappingConfig.fromJson(Map<String, dynamic> json) {
    return SyncFieldMappingConfig(
      fieldMappings: Map<String, String>.from(json['fieldMappings'] ?? {}),
      fieldTransformations:
          (json['fieldTransformations'] as Map<String, dynamic>? ?? {})
              .map((key, value) => MapEntry(
                    key,
                    FieldTransformation.fromJson(value as Map<String, dynamic>),
                  )),
      fieldValidations:
          (json['fieldValidations'] as Map<String, dynamic>? ?? {})
              .map((key, value) => MapEntry(
                    key,
                    FieldValidation.fromJson(value as Map<String, dynamic>),
                  )),
      excludedFields: List<String>.from(json['excludedFields'] ?? []),
      requiredFields: List<String>.from(json['requiredFields'] ?? []),
      encryptedFields: List<String>.from(json['encryptedFields'] ?? []),
      defaultValues: Map<String, dynamic>.from(json['defaultValues'] ?? {}),
      fieldTypes: (json['fieldTypes'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(
                key,
                FieldType.values.firstWhere((e) => e.name == value),
              )),
      customRules: (json['customRules'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(
                key,
                CustomMappingRule.fromJson(value as Map<String, dynamic>),
              )),
      enableAutoMapping: json['enableAutoMapping'] as bool? ?? true,
      strictTypeChecking: json['strictTypeChecking'] as bool? ?? false,
      allowNullValues: json['allowNullValues'] as bool? ?? true,
      preserveCase: json['preserveCase'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'SyncFieldMappingConfig(mappings: ${fieldMappings.length}, '
        'transformations: ${fieldTransformations.length}, '
        'validations: ${fieldValidations.length})';
  }
}

/// Field transformation configuration
class FieldTransformation {
  const FieldTransformation({
    required this.type,
    this.parameters = const {},
    this.customFunction,
    this.reverseFunction,
    this.applyOnRead = true,
    this.applyOnWrite = true,
  });

  /// Type of transformation to apply
  final TransformationType type;

  /// Parameters for the transformation
  final Map<String, dynamic> parameters;

  /// Custom transformation function
  final dynamic Function(dynamic value)? customFunction;

  /// Reverse transformation function
  final dynamic Function(dynamic value)? reverseFunction;

  /// Apply transformation when reading from backend
  final bool applyOnRead;

  /// Apply transformation when writing to backend
  final bool applyOnWrite;

  /// Apply transformation to value
  dynamic transform(dynamic value, {bool reverse = false}) {
    if (reverse && reverseFunction != null) {
      return reverseFunction!(value);
    }

    if (!reverse && customFunction != null) {
      return customFunction!(value);
    }

    return _applyBuiltInTransformation(value, reverse: reverse);
  }

  /// Apply built-in transformation based on type
  dynamic _applyBuiltInTransformation(dynamic value, {bool reverse = false}) {
    if (value == null) return null;

    switch (type) {
      case TransformationType.uppercase:
        return reverse
            ? value.toString().toLowerCase()
            : value.toString().toUpperCase();

      case TransformationType.lowercase:
        return reverse
            ? value.toString().toUpperCase()
            : value.toString().toLowerCase();

      case TransformationType.trim:
        return value.toString().trim();

      case TransformationType.dateToString:
        if (reverse) {
          return DateTime.tryParse(value.toString());
        }
        return value is DateTime ? value.toIso8601String() : value.toString();

      case TransformationType.stringToDate:
        if (reverse) {
          return value is DateTime ? value.toIso8601String() : value.toString();
        }
        return DateTime.tryParse(value.toString());

      case TransformationType.encrypt:
        // Placeholder for encryption logic
        return reverse ? _decrypt(value) : _encrypt(value);

      case TransformationType.hash:
        return _hash(value);

      case TransformationType.prefix:
        final prefix = parameters['prefix'] as String? ?? '';
        return reverse
            ? value.toString().replaceFirst(prefix, '')
            : '$prefix$value';

      case TransformationType.suffix:
        final suffix = parameters['suffix'] as String? ?? '';
        return reverse
            ? value.toString().replaceFirst(RegExp('$suffix\$'), '')
            : '$value$suffix';

      case TransformationType.replace:
        final find = parameters['find'] as String? ?? '';
        final replace = parameters['replace'] as String? ?? '';
        if (reverse) {
          return value.toString().replaceAll(replace, find);
        }
        return value.toString().replaceAll(find, replace);

      case TransformationType.custom:
        return value; // Custom function should handle this
    }
  }

  /// Placeholder encryption method
  String _encrypt(dynamic value) {
    // Implement encryption logic here
    return 'encrypted:$value';
  }

  /// Placeholder decryption method
  String _decrypt(dynamic value) {
    // Implement decryption logic here
    return value.toString().replaceFirst('encrypted:', '');
  }

  /// Placeholder hash method
  String _hash(dynamic value) {
    // Implement hashing logic here
    return 'hash:${value.hashCode}';
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'parameters': parameters,
      'applyOnRead': applyOnRead,
      'applyOnWrite': applyOnWrite,
    };
  }

  /// Create from JSON
  factory FieldTransformation.fromJson(Map<String, dynamic> json) {
    return FieldTransformation(
      type: TransformationType.values.firstWhere((e) => e.name == json['type']),
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
      applyOnRead: json['applyOnRead'] as bool? ?? true,
      applyOnWrite: json['applyOnWrite'] as bool? ?? true,
    );
  }
}

/// Field validation configuration
class FieldValidation {
  const FieldValidation({
    this.required = false,
    this.minLength,
    this.maxLength,
    this.pattern,
    this.allowedValues,
    this.customValidator,
    this.errorMessage,
  });

  /// Field is required
  final bool required;

  /// Minimum length for string fields
  final int? minLength;

  /// Maximum length for string fields
  final int? maxLength;

  /// Regular expression pattern for validation
  final String? pattern;

  /// Allowed values for the field
  final List<dynamic>? allowedValues;

  /// Custom validation function
  final bool Function(dynamic value)? customValidator;

  /// Custom error message
  final String? errorMessage;

  /// Validate a field value
  ValidationResult validate(dynamic value) {
    final errors = <String>[];

    // Required check
    if (required && (value == null || value.toString().isEmpty)) {
      errors.add(errorMessage ?? 'Field is required');
      return ValidationResult(isValid: false, errors: errors);
    }

    // Skip other validations if value is null and not required
    if (value == null) {
      return ValidationResult(isValid: true);
    }

    final stringValue = value.toString();

    // Length checks
    if (minLength != null && stringValue.length < minLength!) {
      errors.add('Minimum length is $minLength');
    }

    if (maxLength != null && stringValue.length > maxLength!) {
      errors.add('Maximum length is $maxLength');
    }

    // Pattern check
    if (pattern != null && !RegExp(pattern!).hasMatch(stringValue)) {
      errors.add('Value does not match required pattern');
    }

    // Allowed values check
    if (allowedValues != null && !allowedValues!.contains(value)) {
      errors
          .add('Value is not in allowed values: ${allowedValues!.join(', ')}');
    }

    // Custom validation
    if (customValidator != null && !customValidator!(value)) {
      errors.add(errorMessage ?? 'Custom validation failed');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'required': required,
      'minLength': minLength,
      'maxLength': maxLength,
      'pattern': pattern,
      'allowedValues': allowedValues,
      'errorMessage': errorMessage,
    };
  }

  /// Create from JSON
  factory FieldValidation.fromJson(Map<String, dynamic> json) {
    return FieldValidation(
      required: json['required'] as bool? ?? false,
      minLength: json['minLength'] as int?,
      maxLength: json['maxLength'] as int?,
      pattern: json['pattern'] as String?,
      allowedValues: json['allowedValues'] as List<dynamic>?,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

/// Custom mapping rule
class CustomMappingRule {
  const CustomMappingRule({
    required this.name,
    required this.description,
    this.conditions = const {},
    this.actions = const {},
    this.enabled = true,
  });

  /// Rule name
  final String name;

  /// Rule description
  final String description;

  /// Conditions for applying the rule
  final Map<String, dynamic> conditions;

  /// Actions to perform when rule matches
  final Map<String, dynamic> actions;

  /// Rule is enabled
  final bool enabled;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'conditions': conditions,
      'actions': actions,
      'enabled': enabled,
    };
  }

  /// Create from JSON
  factory CustomMappingRule.fromJson(Map<String, dynamic> json) {
    return CustomMappingRule(
      name: json['name'] as String,
      description: json['description'] as String,
      conditions: Map<String, dynamic>.from(json['conditions'] ?? {}),
      actions: Map<String, dynamic>.from(json['actions'] ?? {}),
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

/// Validation result
class ValidationResult {
  const ValidationResult({
    required this.isValid,
    this.errors = const [],
  });

  /// Validation passed
  final bool isValid;

  /// Validation errors
  final List<String> errors;

  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, errors: $errors)';
  }
}

/// Field transformation types
enum TransformationType {
  uppercase,
  lowercase,
  trim,
  dateToString,
  stringToDate,
  encrypt,
  hash,
  prefix,
  suffix,
  replace,
  custom,
}

/// Field data types
enum FieldType {
  string,
  integer,
  double,
  boolean,
  dateTime,
  uuid,
  json,
  blob,
  custom,
}
