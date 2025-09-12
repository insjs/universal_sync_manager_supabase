/// Defines the capabilities and features supported by a backend adapter
///
/// This class allows the sync manager to detect what features are available
/// in the current backend and adapt its behavior accordingly.
class SyncBackendCapabilities {
  /// Basic CRUD operation support
  final bool supportsCrud;

  /// Batch operation support for performance optimization
  final bool supportsBatchOperations;

  /// Real-time subscription support for live updates
  final bool supportsRealTimeSubscriptions;

  /// Transaction support for atomic operations
  final bool supportsTransactions;

  /// Full-text search capabilities
  final bool supportsFullTextSearch;

  /// File/blob storage support
  final bool supportsFileStorage;

  /// Custom query language support (SQL, GraphQL, etc.)
  final bool supportsCustomQueries;

  /// Authentication and authorization support
  final bool supportsAuthentication;

  /// Conflict resolution mechanisms
  final bool supportsConflictResolution;

  /// Offline queue support for when connection is lost
  final bool supportsOfflineQueue;

  /// Delta sync support for incremental updates
  final bool supportsDeltaSync;

  /// Data compression support
  final bool supportsCompression;

  /// Field-level encryption support
  final bool supportsEncryption;

  /// Cross-table relationships/joins
  final bool supportsRelationships;

  /// Pagination support for large datasets
  final bool supportsPagination;

  /// Aggregation operations (count, sum, avg, etc.)
  final bool supportsAggregation;

  /// Maximum batch size for bulk operations
  final int maxBatchSize;

  /// Maximum query result size
  final int maxQueryLimit;

  /// Supported data types by the backend
  final List<SyncDataType> supportedDataTypes;

  /// Backend-specific feature flags
  final Map<String, bool> customFeatures;

  const SyncBackendCapabilities({
    this.supportsCrud = true,
    this.supportsBatchOperations = false,
    this.supportsRealTimeSubscriptions = false,
    this.supportsTransactions = false,
    this.supportsFullTextSearch = false,
    this.supportsFileStorage = false,
    this.supportsCustomQueries = false,
    this.supportsAuthentication = false,
    this.supportsConflictResolution = false,
    this.supportsOfflineQueue = false,
    this.supportsDeltaSync = false,
    this.supportsCompression = false,
    this.supportsEncryption = false,
    this.supportsRelationships = false,
    this.supportsPagination = false,
    this.supportsAggregation = false,
    this.maxBatchSize = 100,
    this.maxQueryLimit = 1000,
    this.supportedDataTypes = const [
      SyncDataType.text,
      SyncDataType.integer,
      SyncDataType.real,
      SyncDataType.boolean,
      SyncDataType.datetime,
    ],
    this.customFeatures = const {},
  });

  /// Creates capabilities for a basic CRUD-only backend
  factory SyncBackendCapabilities.basic() {
    return const SyncBackendCapabilities(
      supportsCrud: true,
      maxBatchSize: 50,
      maxQueryLimit: 500,
    );
  }

  /// Creates capabilities for a full-featured backend (like Firebase/Supabase)
  factory SyncBackendCapabilities.fullFeatured() {
    return const SyncBackendCapabilities(
      supportsCrud: true,
      supportsBatchOperations: true,
      supportsRealTimeSubscriptions: true,
      supportsTransactions: true,
      supportsFullTextSearch: true,
      supportsFileStorage: true,
      supportsAuthentication: true,
      supportsConflictResolution: true,
      supportsDeltaSync: true,
      supportsCompression: true,
      supportsRelationships: true,
      supportsPagination: true,
      supportsAggregation: true,
      maxBatchSize: 500,
      maxQueryLimit: 10000,
      supportedDataTypes: SyncDataType.values,
    );
  }

  /// Creates capabilities for PocketBase
  factory SyncBackendCapabilities.pocketBase() {
    return const SyncBackendCapabilities(
      supportsCrud: true,
      supportsBatchOperations:
          false, // PocketBase doesn't support batch operations
      supportsRealTimeSubscriptions: true,
      supportsAuthentication: true,
      supportsFileStorage: true,
      supportsFullTextSearch: true,
      supportsRelationships: true,
      supportsPagination: true,
      maxBatchSize: 1, // No batch support
      maxQueryLimit: 500,
      customFeatures: {
        'pocketbase_realtime': true,
        'pocketbase_admin_api': true,
      },
    );
  }

  /// Creates capabilities for Supabase
  factory SyncBackendCapabilities.supabase() {
    return const SyncBackendCapabilities(
      supportsCrud: true,
      supportsBatchOperations: true,
      supportsRealTimeSubscriptions: true,
      supportsTransactions: true,
      supportsAuthentication: true,
      supportsFileStorage: true,
      supportsFullTextSearch: true,
      supportsCustomQueries: true,
      supportsRelationships: true,
      supportsPagination: true,
      supportsConflictResolution: false, // Needs custom implementation
      supportsDeltaSync: false, // Needs custom implementation
      maxBatchSize: 1000,
      maxQueryLimit: 1000,
      customFeatures: {
        'supabase_realtime': true,
        'supabase_edge_functions': true,
        'supabase_auth': true,
        'supabase_storage': true,
        'postgresql_features': true,
        'row_level_security': true,
      },
      supportedDataTypes: SyncDataType.values,
    );
  }

  /// Checks if a specific feature is supported
  bool hasFeature(String featureName) {
    switch (featureName.toLowerCase()) {
      case 'crud':
        return supportsCrud;
      case 'batch':
        return supportsBatchOperations;
      case 'realtime':
        return supportsRealTimeSubscriptions;
      case 'transactions':
        return supportsTransactions;
      case 'search':
        return supportsFullTextSearch;
      case 'files':
        return supportsFileStorage;
      case 'auth':
        return supportsAuthentication;
      case 'conflicts':
        return supportsConflictResolution;
      case 'offline':
        return supportsOfflineQueue;
      case 'delta':
        return supportsDeltaSync;
      case 'compression':
        return supportsCompression;
      case 'encryption':
        return supportsEncryption;
      case 'relations':
        return supportsRelationships;
      case 'pagination':
        return supportsPagination;
      case 'aggregation':
        return supportsAggregation;
      default:
        return customFeatures[featureName] ?? false;
    }
  }

  /// Returns a summary of enabled features
  Map<String, bool> get featureSummary {
    return {
      'crud': supportsCrud,
      'batch': supportsBatchOperations,
      'realtime': supportsRealTimeSubscriptions,
      'transactions': supportsTransactions,
      'search': supportsFullTextSearch,
      'files': supportsFileStorage,
      'auth': supportsAuthentication,
      'conflicts': supportsConflictResolution,
      'offline': supportsOfflineQueue,
      'delta': supportsDeltaSync,
      'compression': supportsCompression,
      'encryption': supportsEncryption,
      'relations': supportsRelationships,
      'pagination': supportsPagination,
      'aggregation': supportsAggregation,
      ...customFeatures,
    };
  }
}

/// Supported data types for sync operations
/// Following SQLite-first strategy from the database guide
enum SyncDataType {
  text, // SQLite TEXT - strings, JSON, UUIDs
  integer, // SQLite INTEGER - numbers, booleans (0/1)
  real, // SQLite REAL - floating point numbers
  boolean, // Logical boolean (mapped to INTEGER 0/1)
  datetime, // ISO 8601 timestamp strings
  json, // JSON objects stored as TEXT
  blob, // Binary data (for file storage backends)
}

/// Extension to provide type information
extension SyncDataTypeExtension on SyncDataType {
  /// Returns the SQLite storage class for this data type
  String get sqliteType {
    switch (this) {
      case SyncDataType.text:
      case SyncDataType.datetime:
      case SyncDataType.json:
        return 'TEXT';
      case SyncDataType.integer:
      case SyncDataType.boolean:
        return 'INTEGER';
      case SyncDataType.real:
        return 'REAL';
      case SyncDataType.blob:
        return 'BLOB';
    }
  }

  /// Returns the Dart type for this data type
  Type get dartType {
    switch (this) {
      case SyncDataType.text:
      case SyncDataType.datetime:
      case SyncDataType.json:
        return String;
      case SyncDataType.integer:
        return int;
      case SyncDataType.boolean:
        return bool;
      case SyncDataType.real:
        return double;
      case SyncDataType.blob:
        return List<int>;
    }
  }
}
