# Universal Sync Manager API Reference

Generated on: 2025-08-13T14:34:53.299209

## Classes

### MyApp

**Source:** `lib\main.dart`

#### Methods

- **MyApp** (const)
- **build** (Widget)
- **MaterialApp** (return)
- **MyHomePage** (const)

---

### MyHomePage

**Source:** `lib\main.dart`

#### Methods

- **MyHomePage** (const)
- **object** (State)
- **values** (the)
- **parent** (the)
- **createState** (State<MyHomePage>)

---

### CustomApiSyncAdapter

Custom API implementation of the Universal Sync Manager backend adapter  TODO: This adapter is a placeholder for future implementation  This adapter provides a generic implementation for custom REST/GraphQL APIs, implementing the standard ISyncBackendAdapter interface to enable seamless integration with any custom backend service.  Planned Features: - Configurable REST API endpoints with custom mapping - GraphQL query and mutation support - Custom authentication strategies (API keys, OAuth, JWT, etc.) - Flexible field mapping and data transformation - Custom error handling and response parsing - Real-time subscriptions via WebSocket, SSE, or polling - Rate limiting and retry mechanisms - Custom request/response interceptors - Batch operation optimization - Caching strategies for offline support - Custom conflict resolution strategies - Plugin architecture for extending functionality  Configuration Examples: ```dart // REST API configuration final restConfig = CustomApiConfiguration.rest( baseUrl: 'https://api.example.com', endpoints: { 'create': (collection) => '/api/v1/$collection', 'read': (collection, id) => '/api/v1/$collection/$id', 'update': (collection, id) => '/api/v1/$collection/$id', 'delete': (collection, id) => '/api/v1/$collection/$id', 'query': (collection) => '/api/v1/$collection/search', }, authentication: ApiKeyAuthentication(headerName: 'X-API-Key'), );  // GraphQL configuration final graphqlConfig = CustomApiConfiguration.graphql( endpoint: 'https://api.example.com/graphql', mutations: { 'create': (collection) => ''' mutation Create${collection}(\$input: ${collection}Input!) { create${collection}(input: \$input) { id, ...fields } } ''', }, queries: { 'read': (collection) => ''' query Get${collection}(\$id: ID!) { get${collection}(id: \$id) { id, ...fields } } ''', }, subscriptions: { 'subscribe': (collection) => ''' subscription Subscribe${collection} { ${collection}Changed { action, record { id, ...fields } } } ''', }, ); ```  Following USM naming conventions: - File: usm_custom_api_sync_adapter.dart (snake_case with usm_ prefix) - Class: CustomApiSyncAdapter (PascalCase) - Collections: configurable naming strategy - Fields: configurable field mapping

**Source:** `lib\src\adapters\usm_custom_api_sync_adapter.dart`

#### Methods

- **CustomApiSyncAdapter** (configuration)
  - Creates a new Custom API sync adapter  TODO: Add proper constructor with API
- **Duration** (const)
- **UnimplementedError** (throw)
- **UnimplementedError** (throw)
- **UnimplementedError** (throw)
- **UnimplementedError** (throw)
- **UnimplementedError** (throw)
- **connect** (Future<bool>)
- **UnimplementedError** (throw)
- **disconnect** (Future<void>)
- **UnimplementedError** (throw)
- **create** (Future<SyncResult>)
- **UnimplementedError** (throw)
- **read** (Future<SyncResult>)
- **UnimplementedError** (throw)
- **update** (Future<SyncResult>)
- **UnimplementedError** (throw)
- **delete** (Future<SyncResult>)
- **UnimplementedError** (throw)
- **UnimplementedError** (throw)
- **UnimplementedError** (throw)
- **UnimplementedError** (throw)
- **UnimplementedError** (throw)
- **subscribe** (Stream<SyncEvent>)
- **UnimplementedError** (throw)
- **unsubscribe** (Future<void>)
- **UnimplementedError** (throw)

---

### FirebaseSyncAdapter

Firebase/Firestore implementation of the Universal Sync Manager backend adapter  TODO: This adapter is a placeholder for future implementation  This adapter will provide integration with Firebase/Firestore backend services, implementing the standard ISyncBackendAdapter interface to enable seamless switching between different backend providers.  Planned Features: - Full CRUD operations with Firestore collections and documents - Real-time subscriptions using Firestore snapshots - Firebase Authentication integration - Automatic field mapping for USM conventions - Error handling with proper USM error types - Connection management and health monitoring - Batch operations for optimized performance - Offline support with Firestore cache - Firebase Security Rules integration - Cloud Functions integration for server-side operations  Dependencies to add: - firebase_core: ^2.24.2 - cloud_firestore: ^4.13.6 - firebase_auth: ^4.15.3  Following USM naming conventions: - File: usm_firebase_sync_adapter.dart (snake_case with usm_ prefix) - Class: FirebaseSyncAdapter (PascalCase) - Collections: snake_case naming (audit_items, organization_profiles) - Fields: camelCase naming (organizationId, createdBy, updatedAt)

**Source:** `lib\src\adapters\usm_firebase_sync_adapter.dart`

#### Methods

- **FirebaseSyncAdapter** (configuration)
  - Creates a new Firebase sync adapter  TODO: Add proper constructor with Firebase
- **Duration** (const)
- **UnimplementedError** (throw)
- **UnimplementedError** (throw)
- **UnimplementedError** (throw)
- **UnimplementedError** (throw)
- **UnimplementedError** (throw)
- **connect** (Future<bool>)
- **UnimplementedError** (throw)
- **disconnect** (Future<void>)
- **UnimplementedError** (throw)
- **create** (Future<SyncResult>)
- **UnimplementedError** (throw)
- **read** (Future<SyncResult>)
- **UnimplementedError** (throw)
- **update** (Future<SyncResult>)
- **UnimplementedError** (throw)
- **delete** (Future<SyncResult>)
- **UnimplementedError** (throw)
- **UnimplementedError** (throw)
- **UnimplementedError** (throw)
- **UnimplementedError** (throw)
- **UnimplementedError** (throw)
- **subscribe** (Stream<SyncEvent>)
- **UnimplementedError** (throw)
- **unsubscribe** (Future<void>)
- **UnimplementedError** (throw)

---

### PocketBaseSyncAdapter

PocketBase implementation of the Universal Sync Manager backend adapter  This adapter provides integration with PocketBase backend services, implementing the standard ISyncBackendAdapter interface to enable seamless switching between different backend providers.  Key Features: - Full CRUD operations with PocketBase collections - Real-time subscriptions using PocketBase API - Authentication integration with PocketBase auth - Automatic field mapping for USM conventions - Error handling with proper USM error types - Connection management and health monitoring  Following USM naming conventions: - File: usm_pocketbase_sync_adapter.dart (snake_case with usm_ prefix) - Class: PocketBaseSyncAdapter (PascalCase)

**Source:** `lib\src\adapters\usm_pocketbase_sync_adapter.dart`

#### Methods

- **PocketBaseSyncAdapter** (adapter)
  - Creates a new PocketBase sync
- **Duration** (const)
- **connect** (Future<bool>)
- **if** (configuration)
- **_makeRequest** (await)
- **if** (provided)
- **_authenticateWithCredentials** (await)
- **disconnect** (Future<void>)
- **create** (Future<SyncResult>)
- **_makeRequest** (await)
- **_parseErrorResponse** (await)
- **read** (Future<SyncResult>)
- **_makeRequest** (await)
- **if** (else)
- **_parseErrorResponse** (await)
- **update** (Future<SyncResult>)
- **_makeRequest** (await)
- **_parseErrorResponse** (await)
- **delete** (Future<SyncResult>)
- **_makeRequest** (await)
- **_parseErrorResponse** (await)
- **_makeRequest** (await)
- **_parseErrorResponse** (await)
- **create** (await)
- **Duration** (const)
- **update** (await)
- **Duration** (const)
- **delete** (await)
- **Duration** (const)
- **subscribe** (Stream<SyncEvent>)
- **unsubscribe** (Future<void>)
- **_ensureConnected** (void)
- **connect** (Call)
- **_makeRequest** (Future<HttpClientResponse>)
- **_mapToBackendFormat** (Map<String, dynamic>)
- **_mapFromBackendFormat** (Map<String, dynamic>)
- **_isDateTimeField** (bool)
- **_buildQueryParams** (Map<String, String>)
- **if** (else)
- **if** (else)
- **if** (else)
- **_parseErrorResponse** (Future<SyncError>)
- **_mapHttpStatusToSyncError** (return)
- **_mapHttpStatusToSyncError** (return)
- **_mapHttpStatusToSyncError** (SyncError)
- **_authenticateWithCredentials** (Future<void>)
- **_makeRequest** (await)
- **Duration** (const)
- **_parseErrorResponse** (await)
- **_startHeartbeat** (void)
- **Duration** (const)
- **_makeRequest** (await)
- **_startRealtimeSubscription** (Future<void>)
- **LineSplitter** (const)
- **SyncEvent** (return)

---

### SupabaseSyncAdapter

Supabase implementation of the Universal Sync Manager backend adapter  This adapter provides integration with Supabase backend services, implementing the standard ISyncBackendAdapter interface to enable seamless switching between different backend providers.  Key Features: - Full CRUD operations with Supabase tables - Real-time subscriptions using Supabase Realtime - Authentication integration with Supabase Auth - Automatic field mapping for USM conventions - Error handling with proper USM error types - Connection management and health monitoring - Row Level Security (RLS) support - PostgreSQL advanced features (JSON, arrays, etc.) - Edge Functions integration - Storage bucket operations  Following USM naming conventions: - File: usm_supabase_sync_adapter.dart (snake_case with usm_ prefix) - Class: SupabaseSyncAdapter (PascalCase) - Tables: snake_case naming (audit_items, organization_profiles) - Fields: camelCase naming (organizationId, createdBy, updatedAt)

**Source:** `lib\src\adapters\usm_supabase_sync_adapter.dart`

#### Methods

- **SupabaseSyncAdapter** (adapter)
  - Creates a new Supabase sync
- **Duration** (const)
- **connect** (Future<bool>)
- **if** (configuration)
- **if** (provided)
- **_authenticateWithCredentials** (await)
- **disconnect** (Future<void>)
- **for** (subscriptions)
- **for** (controllers)
- **if** (authenticated)
- **create** (Future<SyncResult>)
- **catch** (PostgrestException)
- **read** (Future<SyncResult>)
- **catch** (PostgrestException)
- **returned** (rows)
- **update** (Future<SyncResult>)
- **catch** (PostgrestException)
- **delete** (Future<SyncResult>)
- **catch** (PostgrestException)
- **for** (filters)
- **for** (ordering)
- **if** (pagination)
- **catch** (PostgrestException)
- **catch** (PostgrestException)
- **for** (updates)
- **update** (await)
- **if** (server)
- **Duration** (const)
- **catch** (PostgrestException)
- **subscribe** (Stream<SyncEvent>)
- **unsubscribe** (Future<void>)
- **_ensureConnected** (void)
- **connect** (Call)
- **_mapToBackendFormat** (Map<String, dynamic>)
- **for** (strings)
- **_mapFromBackendFormat** (Map<String, dynamic>)
- **if** (conventions)
- **for** (objects)
- **_isDateTimeField** (bool)
- **_mapPostgrestErrorToSyncError** (SyncError)
- **_authenticateWithCredentials** (Future<void>)
- **catch** (AuthException)
- **_startRealtimeSubscription** (Future<void>)
- **SyncEvent** (return)

---

### SyncEntityDiscovery

Automatic entity discovery system for Universal Sync Manager  This class provides automatic discovery and registration of syncable entities based on annotations, database schema, and naming conventions. Uses a practical approach that works across all platforms without mirrors.  Following USM naming conventions: - File: usm_entity_discovery.dart (snake_case with usm_ prefix) - Class: SyncEntityDiscovery (PascalCase)

**Source:** `lib\src\config\usm_entity_discovery.dart`

#### Methods

- **discoverFromDefinitions** (List<DiscoveredEntity>)
- **getTableInfo** (await)
- **if** (tables)
- **discoverFromTableNames** (List<DiscoveredEntity>)
- **autoRegisterEntities** (void)
- **createConventionBasedConfig** (SyncEntityConfig)
- **if** (overrides)
- **discoverAndRegister** (Future<int>)
- **Function** (SyncEntityConfig)
- **if** (definitions)
- **if** (names)
- **if** (database)
- **discoverFromDatabase** (await)
- **autoRegisterEntities** (entities)
- **_buildDefaultConfig** (SyncEntityConfig)
- **createConventionBasedConfig** (return)
- **_tableNameToClassName** (String)
- **_isSystemTable** (bool)
- **_isPublicTable** (bool)
- **_hasAuditFields** (bool)
- **_hasSyncFields** (bool)
- **_hasAuditFieldsInClass** (bool)
- **_hasSyncFieldsInClass** (bool)
- **_requiresAuth** (bool)
- **_determinePriority** (SyncPriority)
- **_determineSyncDirection** (SyncDirection)
- **_applyConfigOverrides** (SyncEntityConfig)

---

### DiscoveredEntity

Represents a discovered entity

**Source:** `lib\src\config\usm_entity_discovery.dart`

#### Methods

- **DiscoveredEntity** (const)
- **toString** (String)

---

### EntityDefinition

Manual entity definition for discovery

**Source:** `lib\src\config\usm_entity_discovery.dart`

#### Methods

- **EntityDefinition** (const)

---

### EntityAnnotation

**Source:** `lib\src\config\usm_entity_discovery.dart`

#### Methods

- **EntityAnnotation** (const)

---

### SyncEntityAnnotation

Annotation for marking syncable entities

**Source:** `lib\src\config\usm_entity_discovery.dart`

#### Methods

- **SyncEntityAnnotation** (const)

---

### SyncTableAnnotation

Annotation for table configuration

**Source:** `lib\src\config\usm_entity_discovery.dart`

#### Methods

- **SyncTableAnnotation** (const)

---

### SyncFieldAnnotation

Annotation for field configuration

**Source:** `lib\src\config\usm_entity_discovery.dart`

#### Methods

- **SyncFieldAnnotation** (const)

---

### FieldInfo

Information about a discovered field

**Source:** `lib\src\config\usm_entity_discovery.dart`

#### Methods

- **FieldInfo** (const)
- **toString** (String)

---

### TableInfo

Database table information

**Source:** `lib\src\config\usm_entity_discovery.dart`

#### Methods

- **TableInfo** (const)

---

### ColumnInfo

Database column information

**Source:** `lib\src\config\usm_entity_discovery.dart`

#### Methods

- **ColumnInfo** (const)

---

### SyncFieldMappingConfig

Field mapping configuration for Universal Sync Manager  This class provides field mapping, transformation, and validation capabilities for entity synchronization across different backends.  Following USM naming conventions: - File: usm_field_mapping_config.dart (snake_case with usm_ prefix) - Class: SyncFieldMappingConfig (PascalCase)

**Source:** `lib\src\config\usm_field_mapping_config.dart`

#### Methods

- **SyncFieldMappingConfig** (const)
- **copyWith** (SyncFieldMappingConfig)
  - Create a copy with modified properties
- **SyncFieldMappingConfig** (return)
- **toJson** (Map<String, dynamic>)
  - Convert to JSON for serialization
- **SyncFieldMappingConfig** (return)
- **toString** (String)

---

### FieldTransformation

Field transformation configuration

**Source:** `lib\src\config\usm_field_mapping_config.dart`

#### Methods

- **FieldTransformation** (const)
- **Function** (dynamic)
- **Function** (dynamic)
- **transform** (dynamic)
  - Apply transformation to value
- **_applyBuiltInTransformation** (return)
- **_applyBuiltInTransformation** (dynamic)
  - Apply built-in transformation based on type
- **_hash** (return)
- **_encrypt** (String)
  - Placeholder encryption method
- **_decrypt** (String)
  - Placeholder decryption method
- **_hash** (String)
  - Placeholder hash method
- **toJson** (Map<String, dynamic>)
  - Convert to JSON
- **FieldTransformation** (return)

---

### FieldValidation

Field validation configuration

**Source:** `lib\src\config\usm_field_mapping_config.dart`

#### Methods

- **FieldValidation** (const)
- **Function** (bool)
- **validate** (ValidationResult)
  - Validate a field value
- **if** (check)
- **ValidationResult** (return)
- **if** (required)
- **ValidationResult** (return)
- **if** (checks)
- **if** (check)
- **if** (check)
- **if** (validation)
- **ValidationResult** (return)
- **toJson** (Map<String, dynamic>)
  - Convert to JSON
- **FieldValidation** (return)

---

### CustomMappingRule

Custom mapping rule

**Source:** `lib\src\config\usm_field_mapping_config.dart`

#### Methods

- **CustomMappingRule** (const)
- **toJson** (Map<String, dynamic>)
  - Convert to JSON
- **CustomMappingRule** (return)

---

### ValidationResult

Validation result

**Source:** `lib\src\config\usm_field_mapping_config.dart`

#### Methods

- **ValidationResult** (const)
- **toString** (String)

---

### SyncConfigSerializer

Configuration serialization and persistence system for Universal Sync Manager  This class provides comprehensive serialization, deserialization, and persistence capabilities for USM configurations with support for JSON, migration, and validation.  Following USM naming conventions: - File: usm_sync_config_serializer.dart (snake_case with usm_ prefix) - Class: SyncConfigSerializer (PascalCase)

**Source:** `lib\src\config\usm_sync_config_serializer.dart`

#### Methods

- **serializeSyncSystem** (Map<String, dynamic>)
- **deserializeSyncSystem** (SyncSystemConfig)
- **SyncSystemConfig** (return)
- **saveToFile** (Future<void>)
- **if** (saving)
- **SyncConfigSerializationException** (throw)
- **if** (exists)
- **loadFromFile** (Future<SyncSystemConfig>)
- **SyncConfigSerializationException** (throw)
- **if** (loading)
- **SyncConfigSerializationException** (throw)
- **SyncConfigSerializationException** (throw)
- **exportToJsonString** (String)
- **jsonEncode** (return)
- **importFromJsonString** (SyncSystemConfig)
- **deserializeSyncSystem** (return)
- **SyncConfigSerializationException** (throw)
- **createTemplate** (SyncSystemConfig)
- **for** (entities)
- **SyncSystemConfig** (return)
- **mergeConfigurations** (SyncSystemConfig)
- **SyncSystemConfig** (return)
- **applyOverrides** (SyncSystemConfig)
- **_applyOverridesRecursive** (recursively)
- **deserializeSyncSystem** (return)
- **validateConfigFile** (Future<SyncConfigFileValidationResult>)
- **if** (exists)
- **SyncConfigFileValidationResult** (return)
- **if** (else)
- **version** (Configuration)
- **supported** (than)
- **if** (fields)
- **if** (deserialize)
- **SyncConfigFileValidationResult** (return)
- **_migrateConfiguration** (Map<String, dynamic>)
- **for** (sequence)
- **_applyMigration** (void)
- **switch** (needed)
- **_mergeUniversalConfigs** (UniversalSyncConfig)
- **_mergeEntityRegistries** (SyncEntityRegistry)
- **for** (base)
- **for** (registry)
- **_applyOverridesRecursive** (void)

---

### SyncSystemConfig

Container class for a complete sync system configuration

**Source:** `lib\src\config\usm_sync_config_serializer.dart`

#### Methods

- **SyncSystemConfig** (const)
- **toJson** (Map<String, dynamic>)
  - Converts this configuration to JSON
- **copyWith** (SyncSystemConfig)
  - Creates a copy with specified overrides
- **SyncSystemConfig** (return)
- **toString** (String)

---

### SyncConfigFileValidationResult

Validation result for configuration files

**Source:** `lib\src\config\usm_sync_config_serializer.dart`

#### Methods

- **SyncConfigFileValidationResult** (const)
- **toString** (String)

---

### SyncConfigSerializationException

Exception thrown during configuration serialization/deserialization

**Source:** `lib\src\config\usm_sync_config_serializer.dart`

#### Methods

- **SyncConfigSerializationException** (const)
- **toString** (String)

---

### SyncConfigValidator

Configuration validation system for Universal Sync Manager  This class provides comprehensive validation for all USM configuration components to ensure they are properly configured before use.  Following USM naming conventions: - File: usm_sync_config_validator.dart (snake_case with usm_ prefix) - Class: SyncConfigValidator (PascalCase)

**Source:** `lib\src\config\usm_sync_config_validator.dart`

#### Methods

- **validateUniversalConfig** (SyncConfigValidationResult)
- **if** (ID)
- **if** (else)
- **if** (interval)
- **if** (else)
- **if** (configuration)
- **if** (else)
- **if** (size)
- **if** (else)
- **if** (timeouts)
- **if** (operations)
- **if** (else)
- **_validateEnvironmentSettings** (settings)
- **_validateNetworkSettings** (settings)
- **_validateSecuritySettings** (settings)
- **_validateOfflineSettings** (settings)
- **_validatePlatformOptimizations** (optimizations)
- **SyncConfigValidationResult** (return)
- **validateEntityConfig** (SyncEntityConfigValidationResult)
- **if** (name)
- **if** (name)
- **if** (else)
- **if** (size)
- **if** (interval)
- **if** (age)
- **if** (expiration)
- **for** (mappings)
- **if** (settings)
- **if** (time)
- **if** (time)
- **SyncEntityConfigValidationResult** (return)
- **validateEntityRegistry** (SyncEntityRegistryValidationResult)
- **for** (configurations)
- **SyncEntityRegistryValidationResult** (return)
- **validateSyncSystem** (SyncSystemValidationResult)
- **for** (lists)
- **if** (it)
- **if** (implications)
- **SyncSystemValidationResult** (return)
- **_validateEnvironmentSettings** (void)
- **_validateNetworkSettings** (void)
- **_validateSecuritySettings** (void)
- **_validateOfflineSettings** (void)
- **_validatePlatformOptimizations** (void)
- **_isValidTableName** (bool)

---

### ValidationIssue

**Source:** `lib\src\config\usm_sync_config_validator.dart`

#### Methods

- **ValidationIssue** (const)
- **toString** (String)

---

### class

Validation error

**Source:** `lib\src\config\usm_sync_config_validator.dart`

---

### class

Validation warning

**Source:** `lib\src\config\usm_sync_config_validator.dart`

---

### SyncConfigValidationResult

Validation result for UniversalSyncConfig

**Source:** `lib\src\config\usm_sync_config_validator.dart`

#### Methods

- **SyncConfigValidationResult** (const)
- **toString** (String)

---

### SyncEntityConfigValidationResult

Validation result for SyncEntityConfig

**Source:** `lib\src\config\usm_sync_config_validator.dart`

#### Methods

- **SyncEntityConfigValidationResult** (const)
- **toString** (String)

---

### SyncEntityRegistryValidationResult

Validation result for SyncEntityRegistry

**Source:** `lib\src\config\usm_sync_config_validator.dart`

#### Methods

- **SyncEntityRegistryValidationResult** (const)
- **toString** (String)

---

### SyncSystemValidationResult

Validation result for complete sync system

**Source:** `lib\src\config\usm_sync_config_validator.dart`

#### Methods

- **SyncSystemValidationResult** (const)
- **toString** (String)

---

### SyncEntityConfig

Configuration for a specific syncable entity/table  This class defines entity-specific sync behavior and settings that override the global Universal Sync Manager configuration.  Following USM naming conventions: - File: usm_sync_entity_config.dart (snake_case with usm_ prefix) - Class: SyncEntityConfig (PascalCase)

**Source:** `lib\src\config\usm_sync_entity_config.dart`

#### Methods

- **entity** (this)
  - Custom sync interval for
- **SyncEntityConfig** (const)
  - Creates a new sync entity configuration
- **entities** (public)
  - Creates a configuration for
- **SyncEntityConfig** (return)
- **entities** (protected)
  - Creates a configuration for
- **SyncEntityConfig** (return)
- **SyncEntityConfig** (return)
- **SyncEntityConfig** (return)
- **copyWith** (SyncEntityConfig)
  - Creates a copy of this configuration with specified overrides
- **SyncEntityConfig** (return)
- **toJson** (Map<String, dynamic>)
  - Converts this configuration to a JSON map
- **SyncEntityConfig** (return)
- **validate** (List<String>)
  - Validates the configuration and returns any validation errors
- **for** (mappings)
- **toString** (String)

---

### SyncEntityRegistry

Registry for managing entity configurations  This class provides a centralized way to register and manage sync configurations for different entities in the application.

**Source:** `lib\src\config\usm_sync_entity_config.dart`

#### Methods

- **register** (void)
  - Register a new entity configuration
- **unregister** (void)
  - Remove an entity configuration
- **clear** (void)
  - Clear all entity configurations
- **getEntitiesByPriority** (Map<String, SyncEntityConfig>)
  - Get configurations by priority level
- **toJson** (Map<String, dynamic>)
  - Convert all configurations to JSON
- **fromJson** (void)
  - Load configurations from JSON

---

### SyncStrategy

**Source:** `lib\src\config\usm_sync_strategies.dart`

#### Methods

- **SyncStrategy** (const)
- **shouldSync** (Future<bool>)
  - Determine if sync should proceed
- **handleResult** (Future<SyncStrategyResult>)
  - Handle sync result
- **resolveConflict** (Future<ConflictResolution>)
  - Handle sync conflict
- **getConfiguration** (Map<String, dynamic>)
  - Get strategy configuration
- **updateConfiguration** (void)
  - Update strategy configuration

---

### TimestampSyncStrategy

Timestamp-based sync strategy

**Source:** `lib\src\config\usm_sync_strategies.dart`

#### Methods

- **shouldSync** (Future<bool>)
- **handleResult** (Future<SyncStrategyResult>)
- **sync** (Retrying)
- **resolveConflict** (Future<ConflictResolution>)
- **getConfiguration** (Map<String, dynamic>)
- **updateConfiguration** (void)

---

### PrioritySyncStrategy

Priority-based sync strategy

**Source:** `lib\src\config\usm_sync_strategies.dart`

#### Methods

- **shouldSync** (Future<bool>)
- **handleResult** (Future<SyncStrategyResult>)
- **resolveConflict** (Future<ConflictResolution>)
- **_getMaxRetriesForPriority** (int)
- **getConfiguration** (Map<String, dynamic>)
- **updateConfiguration** (void)

---

### ConflictAwareSyncStrategy

Conflict-aware sync strategy

**Source:** `lib\src\config\usm_sync_strategies.dart`

#### Methods

- **shouldSync** (Future<bool>)
- **handleResult** (Future<SyncStrategyResult>)
- **resolveConflict** (Future<ConflictResolution>)
- **_resolveByTimestamp** (return)
- **_mergeConflict** (return)
- **_resolveByTimestamp** (return)
- **_resolveByTimestamp** (Future<ConflictResolution>)
- **_mergeConflict** (Future<ConflictResolution>)
- **if** (else)
- **_generateHash** (String)
- **getConfiguration** (Map<String, dynamic>)
- **updateConfiguration** (void)

---

### CustomSyncStrategy

Custom sync strategy that can be configured with functions

**Source:** `lib\src\config\usm_sync_strategies.dart`

#### Methods

- **Function** (Future<bool>)
- **Function** (Future<SyncStrategyResult>)
- **Function** (Future<ConflictResolution>)
- **shouldSync** (Future<bool>)
- **handleResult** (Future<SyncStrategyResult>)
- **resolveConflict** (Future<ConflictResolution>)
- **getConfiguration** (Map<String, dynamic>)
- **updateConfiguration** (void)

---

### SyncStrategyManager

Sync strategy manager

**Source:** `lib\src\config\usm_sync_strategies.dart`

#### Methods

- **registerStrategy** (void)
  - Register a sync strategy
- **setEntityStrategy** (void)
  - Set strategy for specific entity
- **getAllStrategies** (Map<String, SyncStrategy>)
  - Get all registered strategies
- **removeStrategy** (void)
  - Remove strategy
- **clear** (void)
  - Clear all strategies

---

### SyncContext

Sync context for strategy execution

**Source:** `lib\src\config\usm_sync_strategies.dart`

#### Methods

- **SyncContext** (const)
- **copyWith** (SyncContext)
- **SyncContext** (return)

---

### SyncStrategyResult

Sync strategy result

**Source:** `lib\src\config\usm_sync_strategies.dart`

#### Methods

- **SyncStrategyResult** (const)
- **SyncStrategyResult** (return)
- **SyncStrategyResult** (return)
- **SyncStrategyResult** (return)
- **SyncStrategyResult** (return)

---

### ConflictResolution

Conflict resolution result

**Source:** `lib\src\config\usm_sync_strategies.dart`

#### Methods

- **ConflictResolution** (const)
- **ConflictResolution** (const)
- **ConflictResolution** (const)
- **ConflictResolution** (return)
- **ConflictResolution** (return)

---

### SyncResult

Placeholder classes for integration

**Source:** `lib\src\config\usm_sync_strategies.dart`

#### Methods

- **SyncResult** (const)

---

### SyncConflict

**Source:** `lib\src\config\usm_sync_strategies.dart`

#### Methods

- **SyncConflict** (const)

---

### UniversalSyncConfig

Universal Sync Manager configuration class  This class contains all the settings needed to configure and operate the Universal Sync Manager. It provides a centralized configuration system that works across all backends and platforms.  Following USM naming conventions: - File: usm_universal_sync_config.dart (snake_case with usm_ prefix) - Class: UniversalSyncConfig (PascalCase)

**Source:** `lib\src\config\usm_universal_sync_config.dart`

#### Methods

- **UniversalSyncConfig** (const)
  - Creates a new Universal Sync Configuration
- **Duration** (const)
- **PlatformOptimizations** (const)
- **Duration** (const)
- **Duration** (const)
- **NetworkSettings** (const)
- **SecuritySettings** (const)
- **OfflineSettings** (const)
- **UniversalSyncConfig** (return)
- **Duration** (const)
- **UniversalSyncConfig** (return)
- **Duration** (const)
- **Duration** (const)
- **UniversalSyncConfig** (return)
- **Duration** (const)
- **Duration** (const)
- **copyWith** (UniversalSyncConfig)
  - Creates a copy of this configuration with specified overrides
- **UniversalSyncConfig** (return)
- **toJson** (Map<String, dynamic>)
  - Converts this configuration to a JSON map
- **UniversalSyncConfig** (return)
- **validate** (List<String>)
  - Validates the configuration and returns any validation errors
- **if** (environment)
- **toString** (String)

---

### PlatformOptimizations

Platform-specific optimization settings

**Source:** `lib\src\config\usm_universal_sync_config.dart`

#### Methods

- **caching** (for)
  - Maximum memory usage
- **PlatformOptimizations** (const)
- **toJson** (Map<String, dynamic>)

---

### NetworkSettings

Network-specific configuration settings

**Source:** `lib\src\config\usm_universal_sync_config.dart`

#### Methods

- **operation** (sync)
  - Maximum bandwidth usage per
- **NetworkSettings** (const)
- **toJson** (Map<String, dynamic>)

---

### SecuritySettings

Security-related configuration settings

**Source:** `lib\src\config\usm_universal_sync_config.dart`

#### Methods

- **SecuritySettings** (const)
- **toJson** (Map<String, dynamic>)

---

### OfflineSettings

Offline mode configuration settings

**Source:** `lib\src\config\usm_universal_sync_config.dart`

#### Methods

- **OfflineSettings** (const)
- **toJson** (Map<String, dynamic>)

---

### Task32Demo

Simple demonstration of Task 3.2: Entity Registration System

**Source:** `lib\src\demos\usm_task3_2_simple_demo.dart`

#### Methods

- **run** (Future<void>)
- **_demonstrateEntityRegistry** (await)
- **_demonstrateEntityDiscovery** (await)
- **_demonstrateFieldMapping** (await)
- **_demonstrateSyncStrategies** (await)
- **_demonstrateEntityRegistry** (Future<void>)
- **_demonstrateEntityDiscovery** (Future<void>)
- **_demonstrateFieldMapping** (Future<void>)
- **_demonstrateSyncStrategies** (Future<void>)

---

### Task41Demo

Comprehensive demo for Task 4.1: Intelligent Sync Optimization

**Source:** `lib\src\demos\usm_task4_1_demo.dart`

#### Methods

- **run** (Future<void>)
- **_demonstrateDeltaSync** (await)
- **_demonstrateCompression** (await)
- **_demonstrateBatchSync** (await)
- **_demonstrateSmartScheduling** (await)
- **_demonstratePriorityQueues** (await)
- **_demonstrateDeltaSync** (Future<void>)
- **_demonstrateCompression** (Future<void>)
- **_demonstrateBatchSync** (Future<void>)
- **if** (UI)
- **_demonstrateSmartScheduling** (Future<void>)
- **_demonstratePriorityQueues** (Future<void>)
- **processing** (queue)
- **if** (any)
- **print** (enqueueing)

---

### ISyncBackendAdapter

**Source:** `lib\src\interfaces\usm_sync_backend_adapter.dart`

#### Methods

- **connect** (Future<bool>)
  - Connection management  Establishes connection to the backend service using provided configuration. Returns true if connection is successful, false otherwise.
- **disconnect** (Future<void>)
  - Disconnects from the backend service and cleans up resources
- **convention** (snake_case)
  - CRUD operations  Creates a new record in the specified collection. Collection names follow
- **create** (Future<SyncResult>)
  - CRUD operations  Creates a new record in the specified collection. Collection names follow snake_case convention (e.g., 'audit_items')
- **read** (Future<SyncResult>)
  - Reads a specific record by ID from the collection
- **update** (Future<SyncResult>)
  - Updates an existing record in the collection
- **collection** (the)
  - Deletes a record from
- **delete** (Future<SyncResult>)
  - Deletes a record from the collection (soft delete preferred)
- **subscribe** (Stream<SyncEvent>)
  - Real-time subscriptions  Subscribes to real-time changes in a collection. Returns a stream of sync events for live updates.
- **unsubscribe** (Future<void>)
  - Unsubscribes from real-time updates for a specific subscription

---

### SyncQuery

Represents a query for filtering and sorting data

**Source:** `lib\src\interfaces\usm_sync_backend_adapter.dart`

#### Methods

- **SyncQuery** (const)
- **organizationId** (by)
  - Creates a query that filters
- **SyncQuery** (return)
- **records** (dirty)
  - Creates a query for
- **SyncQuery** (return)

---

### SyncOrderBy

Represents sorting criteria for queries

**Source:** `lib\src\interfaces\usm_sync_backend_adapter.dart`

#### Methods

- **SyncOrderBy** (const)

---

### SyncSubscriptionOptions

Options for configuring real-time subscriptions

**Source:** `lib\src\interfaces\usm_sync_backend_adapter.dart`

#### Methods

- **SyncSubscriptionOptions** (const)
- **SyncSubscriptionOptions** (return)

---

### PlatformNetworkInfo

Platform-specific network information

**Source:** `lib\src\interfaces\usm_sync_platform_service.dart`

#### Methods

- **PlatformNetworkInfo** (const)
- **toMap** (Map<String, dynamic>)
- **PlatformNetworkInfo** (return)

---

### PlatformBatteryInfo

Platform-specific battery information

**Source:** `lib\src\interfaces\usm_sync_platform_service.dart`

#### Methods

- **PlatformBatteryInfo** (const)
- **toMap** (Map<String, dynamic>)
- **PlatformBatteryInfo** (return)

---

### PlatformDatabaseConfig

Platform-specific database configuration

**Source:** `lib\src\interfaces\usm_sync_platform_service.dart`

#### Methods

- **PlatformDatabaseConfig** (const)
- **toMap** (Map<String, dynamic>)
- **PlatformDatabaseConfig** (return)

---

### FileOperationResult

File system operation result

**Source:** `lib\src\interfaces\usm_sync_platform_service.dart`

#### Methods

- **FileOperationResult** (const)
- **FileOperationResult** (return)
- **FileOperationResult** (return)

---

### ISyncPlatformService

**Source:** `lib\src\interfaces\usm_sync_platform_service.dart`

#### Methods

- **initialize** (Future<bool>)
  - Initialize the platform service with configuration
- **dispose** (Future<void>)
  - Dispose of platform resources
- **readFile** (Future<FileOperationResult>)
  - Read file contents as string
- **readFileAsBytes** (Future<FileOperationResult>)
  - Read file contents as bytes
- **writeFile** (Future<FileOperationResult>)
  - Write string content to file
- **writeFileAsBytes** (Future<FileOperationResult>)
  - Write bytes to file
- **deleteFile** (Future<FileOperationResult>)
  - Delete file
- **fileExists** (Future<FileOperationResult>)
  - Check if file exists
- **directory** (Create)
- **createDirectory** (Future<FileOperationResult>)
  - Create directory (recursive)
- **listDirectory** (Future<FileOperationResult>)
  - List directory contents
- **getFileSize** (Future<int?>)
  - Get file size
- **getFileModificationTime** (Future<DateTime?>)
  - Get file modification time
- **createSyncCacheDirectory** (Future<String>)
  - Create secure cache directory for sync metadata
- **cleanupOldCacheFiles** (Future<void>)
  - Clean up old cache files
- **getNetworkInfo** (Future<PlatformNetworkInfo>)
  - Current network information
- **isNetworkSuitableForSync** (Future<bool>)
  - Check if network is suitable for syncing
- **speed** (network)
  - Estimate
- **estimateNetworkSpeed** (Future<double?>)
  - Estimate network speed (bytes per second)
- **getBatteryInfo** (Future<PlatformBatteryInfo>)
  - Current battery information
- **isPowerSavingMode** (Future<bool>)
  - Check if device is in power saving mode
- **getRecommendedSyncInterval** (Future<Duration>)
  - Get recommended sync frequency based on battery/power state
- **getDatabaseConfig** (Future<PlatformDatabaseConfig>)
  - Get platform-optimized database configuration
- **initializeDatabase** (Future<bool>)
  - Initialize database with platform-specific optimizations
- **vacuumDatabase** (Future<bool>)
  - Execute platform-optimized database vacuum
- **getDatabaseSize** (Future<int?>)
  - Get database file size
- **backupDatabase** (Future<String?>)
  - Backup database to secure location
- **restoreDatabase** (Future<bool>)
  - Restore database from backup
- **isRunningInBackground** (Future<bool>)
  - Check if running in background mode
- **requestBackgroundPermission** (Future<bool>)
  - Request permission for background execution
- **getAvailableStorageSpace** (Future<int?>)
  - Get available storage space
- **hasResourcesForSync** (Future<bool>)
  - Check if device has sufficient resources for sync
- **scheduleBackgroundSync** (Future<bool>)
  - Schedule platform-native background sync task
- **cancelBackgroundSync** (Future<bool>)
  - Cancel scheduled background sync task
- **hasRequiredPermissions** (Future<bool>)
  - Check if app has required permissions
- **requestPermissions** (Future<bool>)
  - Request necessary permissions for sync operations
- **encryptData** (Future<String?>)
  - Encrypt sensitive data using platform keystore/keychain
- **decryptData** (Future<String?>)
  - Decrypt data using platform keystore/keychain
- **storeSecureValue** (Future<bool>)
  - Store secure value in platform keystore/keychain
- **getSecureValue** (Future<String?>)
  - Retrieve secure value from platform keystore/keychain
- **deleteSecureValue** (Future<bool>)
  - Delete secure value from platform keystore/keychain
- **logDiagnosticInfo** (Future<void>)
  - Log platform-specific diagnostic information
- **exportLogs** (Future<String?>)
  - Export logs for debugging

---

### SyncBackendCapabilities

Defines the capabilities and features supported by a backend adapter  This class allows the sync manager to detect what features are available in the current backend and adapt its behavior accordingly.

**Source:** `lib\src\models\usm_sync_backend_capabilities.dart`

#### Methods

- **support** (language)
  - Custom query
- **operations** (Aggregation)
- **SyncBackendCapabilities** (const)
- **SyncBackendCapabilities** (const)
- **backend** (featured)
  - Creates capabilities for a full-
- **SyncBackendCapabilities** (const)
- **SyncBackendCapabilities** (const)
- **SyncBackendCapabilities** (const)
- **hasFeature** (bool)
  - Checks if a specific feature is supported

---

### SyncBackendConfiguration

Configuration class for backend adapter connections  This class encapsulates all the configuration needed to connect to a backend service, including authentication, endpoints, and backend-specific settings.

**Source:** `lib\src\models\usm_sync_backend_configuration.dart`

#### Methods

- **identifier** (type)
  - Backend
- **settings** (specific)
  - Environment-
- **use** (to)
  - API version
- **SyncBackendConfiguration** (const)
- **Duration** (const)
- **Duration** (const)
- **SyncBackendConfiguration** (return)
- **SyncBackendConfiguration** (return)
- **SyncBackendConfiguration** (return)
- **SyncBackendConfiguration** (return)
- **getEndpointUrl** (String)
  - Gets the full URL for a specific endpoint
- **copyWith** (SyncBackendConfiguration)
  - Creates a copy with modified values
- **SyncBackendConfiguration** (return)
- **toJson** (Map<String, dynamic>)
  - Converts to JSON for serialization
- **SyncBackendConfiguration** (return)

---

### SyncAuthConfiguration

Authentication configuration for backend connections

**Source:** `lib\src\models\usm_sync_backend_configuration.dart`

#### Methods

- **SyncAuthConfiguration** (const)
- **SyncAuthConfiguration** (return)
- **SyncAuthConfiguration** (return)
- **SyncAuthConfiguration** (return)
- **SyncAuthConfiguration** (return)
- **SyncAuthConfiguration** (return)
- **JSON** (to)
  - Converts
- **toJson** (Map<String, dynamic>)
  - Converts to JSON (excluding sensitive data in production)
- **SyncAuthConfiguration** (return)

---

### SyncConnectionPoolConfig

Connection pool configuration for managing multiple connections

**Source:** `lib\src\models\usm_sync_backend_configuration.dart`

#### Methods

- **SyncConnectionPoolConfig** (const)
- **Duration** (const)
- **toJson** (Map<String, dynamic>)
  - Converts to JSON
- **SyncConnectionPoolConfig** (return)

---

### IRealtimeSubscription

**Source:** `lib\src\models\usm_sync_event.dart`

#### Methods

- **cancel** (Future<void>)
  - Cancels the subscription and stops receiving events
- **pause** (Future<void>)
  - Pauses the subscription temporarily
- **resume** (Future<void>)
  - Resumes a paused subscription
- **updateOptions** (Future<void>)
  - Updates the subscription options/filters

---

### RealtimeSubscription

Implementation of real-time subscription

**Source:** `lib\src\models\usm_sync_event.dart`

#### Methods

- **Function** (Future<void>)
- **Function** (Future<void>)
- **addEvent** (void)
  - Adds an event to the stream
- **addError** (void)
  - Adds an error to the stream
- **cancel** (Future<void>)
- **_cancelCallback** (await)
- **pause** (Future<void>)
- **resume** (Future<void>)
- **updateOptions** (Future<void>)

---

### SyncEvent

Represents a real-time sync event from the backend

**Source:** `lib\src\models\usm_sync_event.dart`

#### Methods

- **data** (Previous)
- **SyncEvent** (const)
- **SyncEvent** (return)
- **SyncEvent** (return)
- **SyncEvent** (return)
- **SyncEvent** (return)
- **SyncEvent** (return)
- **affectsOrganization** (bool)
  - Checks if this event affects the specified organization
- **toJson** (Map<String, dynamic>)
  - Converts to JSON for serialization
- **SyncEvent** (return)
- **toString** (String)

---

### SyncEventBatch

Aggregated sync event for batch processing

**Source:** `lib\src\models\usm_sync_event.dart`

#### Methods

- **SyncEventBatch** (const)
- **eventsForOrganization** (List<SyncEvent>)
  - Filters events by organization

---

### SubscriptionManager

Manager for handling real-time subscription lifecycle

**Source:** `lib\src\models\usm_sync_event.dart`

#### Methods

- **addSubscription** (void)
  - Adds a subscription
- **removeSubscription** (Future<void>)
  - Removes a subscription
- **cancelAllSubscriptions** (Future<void>)
  - Cancels all subscriptions
- **getSubscriptionsForCollection** (List<IRealtimeSubscription>)
  - Gets subscriptions for a specific collection

---

### SyncResult

Represents the result of a sync operation  This class encapsulates the outcome of any sync operation, whether successful or failed, along with relevant metadata for tracking and debugging.

**Source:** `lib\src\models\usm_sync_result.dart`

#### Methods

- **operation** (the)
  - The data returned from
- **information** (Error)
- **operation** (this)
  - Unique identifier for
- **affected** (was)
  - The record ID that
- **affected** (records)
  - Number of
- **operation** (the)
  - Sync version after
- **SyncResult** (const)
- **SyncResult** (return)
- **SyncResult** (return)
- **SyncResult** (return)
- **toJson** (Map<String, dynamic>)
  - Converts to JSON for logging and debugging
- **SyncResult** (return)
- **_generateOperationId** (String)

---

### SyncError

Represents an error that occurred during a sync operation

**Source:** `lib\src\models\usm_sync_result.dart`

#### Methods

- **backend** (the)
  - Error code from
- **code** (status)
  - HTTP
- **SyncError** (return)
- **SyncError** (return)
- **SyncError** (return)
- **SyncError** (return)
- **SyncError** (return)
- **SyncError** (return)
- **SyncError** (return)
- **SyncError** (return)
- **SyncError** (return)
- **duration** (after)
  - Gets retry
- **Duration** (return)
- **toJson** (Map<String, dynamic>)
  - Converts to JSON for logging
- **SyncError** (return)
- **toString** (String)

---

### MobileSyncPlatformService

Mobile-specific platform service implementation

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

#### Methods

- **initialize** (Future<bool>)
- **if** (paths)
- **_initializeIOSPaths** (await)
- **if** (else)
- **_initializeAndroidPaths** (await)
- **_initializeFallbackPaths** (await)
- **_ensureDirectoryExists** (await)
- **_ensureDirectoryExists** (await)
- **_ensureDirectoryExists** (await)
- **_startNetworkMonitoring** (intervals)
- **logDiagnosticInfo** (await)
- **logDiagnosticInfo** (await)
- **dispose** (Future<void>)
- **logDiagnosticInfo** (await)
- **readFile** (Future<FileOperationResult>)
- **readFileAsBytes** (Future<FileOperationResult>)
- **writeFile** (Future<FileOperationResult>)
- **writeFileAsBytes** (Future<FileOperationResult>)
- **deleteFile** (Future<FileOperationResult>)
- **fileExists** (Future<FileOperationResult>)
- **createDirectory** (Future<FileOperationResult>)
- **listDirectory** (Future<FileOperationResult>)
- **getFileSize** (Future<int?>)
- **logDiagnosticInfo** (await)
- **getFileModificationTime** (Future<DateTime?>)
- **logDiagnosticInfo** (await)
- **createSyncCacheDirectory** (Future<String>)
- **_ensureDirectoryExists** (await)
- **cleanupOldCacheFiles** (Future<void>)
- **Duration** (const)
- **for** (await)
- **logDiagnosticInfo** (await)
- **logDiagnosticInfo** (await)
- **getNetworkInfo** (Future<PlatformNetworkInfo>)
- **PlatformNetworkInfo** (const)
- **PlatformNetworkInfo** (const)
- **logDiagnosticInfo** (await)
- **PlatformNetworkInfo** (const)
- **isNetworkSuitableForSync** (Future<bool>)
- **getNetworkInfo** (await)
- **getBatteryInfo** (await)
- **estimateNetworkSpeed** (Future<double?>)
- **if** (estimation)
- **if** (mobile)
- **logDiagnosticInfo** (await)
- **getBatteryInfo** (Future<PlatformBatteryInfo>)
- **PlatformBatteryInfo** (const)
- **logDiagnosticInfo** (await)
- **PlatformBatteryInfo** (const)
- **isPowerSavingMode** (Future<bool>)
- **getBatteryInfo** (await)
- **getRecommendedSyncInterval** (Future<Duration>)
- **getNetworkInfo** (await)
- **getBatteryInfo** (await)
- **if** (intervals)
- **Duration** (const)
- **Duration** (const)
- **Duration** (const)
- **Duration** (const)
- **getDatabaseConfig** (Future<PlatformDatabaseConfig>)
- **PlatformDatabaseConfig** (return)
- **initializeDatabase** (Future<bool>)
- **logDiagnosticInfo** (await)
- **logDiagnosticInfo** (await)
- **vacuumDatabase** (Future<bool>)
- **logDiagnosticInfo** (await)
- **getDatabaseSize** (Future<int?>)
- **backupDatabase** (Future<String?>)
- **_ensureDirectoryExists** (await)
- **logDiagnosticInfo** (await)
- **logDiagnosticInfo** (await)
- **restoreDatabase** (Future<bool>)
- **logDiagnosticInfo** (await)
- **logDiagnosticInfo** (await)
- **isRunningInBackground** (Future<bool>)
- **requestBackgroundPermission** (Future<bool>)
- **logDiagnosticInfo** (await)
- **getAvailableStorageSpace** (Future<int?>)
- **logDiagnosticInfo** (await)
- **hasResourcesForSync** (Future<bool>)
- **getAvailableStorageSpace** (await)
- **getNetworkInfo** (await)
- **getBatteryInfo** (await)
- **getNetworkInfo** (await)
- **getBatteryInfo** (await)
- **getAvailableStorageSpace** (await)
- **scheduleBackgroundSync** (Future<bool>)
- **scheduling** (sync)
- **logDiagnosticInfo** (await)
- **cancelBackgroundSync** (Future<bool>)
- **logDiagnosticInfo** (await)
- **hasRequiredPermissions** (Future<bool>)
- **requestPermissions** (Future<bool>)
- **logDiagnosticInfo** (await)
- **encryptData** (Future<String?>)
- **logDiagnosticInfo** (await)
- **decryptData** (Future<String?>)
- **logDiagnosticInfo** (await)
- **storeSecureValue** (Future<bool>)
- **encryptData** (await)
- **logDiagnosticInfo** (await)
- **getSecureValue** (Future<String?>)
- **decryptData** (await)
- **logDiagnosticInfo** (await)
- **deleteSecureValue** (Future<bool>)
- **logDiagnosticInfo** (await)
- **logDiagnosticInfo** (Future<void>)
- **getNetworkInfo** (await)
- **getBatteryInfo** (await)
- **getAvailableStorageSpace** (await)
- **hasRequiredPermissions** (await)
- **isRunningInBackground** (await)
- **exportLogs** (Future<String?>)
- **logDiagnosticInfo** (await)
- **_initializeIOSPaths** (Future<void>)
- **_initializeAndroidPaths** (Future<void>)
- **_initializeFallbackPaths** (Future<void>)
- **_ensureDirectoryExists** (Future<void>)
- **_startNetworkMonitoring** (void)
- **Duration** (const)
- **getNetworkInfo** (await)
- **_startBatteryMonitoring** (void)
- **Duration** (const)
- **getBatteryInfo** (await)

---

### SyncPlatformServiceFactory

Factory for creating platform-specific sync platform services

**Source:** `lib\src\platform\usm_platform_service_factory.dart`

#### Methods

- **createForCurrentPlatform** (ISyncPlatformService)
- **createForPlatform** (return)
- **createForPlatform** (ISyncPlatformService)
- **WindowsSyncPlatformService** (return)
- **MobileSyncPlatformService** (return)
- **_createWebPlatformService** (return)
- **WindowsSyncPlatformService** (return)
- **WindowsSyncPlatformService** (return)
- **WindowsSyncPlatformService** (return)
- **getCurrentPlatform** (SyncPlatformType)
- **if** (environment)
- **if** (else)
- **if** (else)
- **if** (else)
- **if** (else)
- **supportsBackgroundSync** (bool)
- **supportsBatteryManagement** (bool)
- **supportsFileSystem** (bool)
- **getRecommendedSyncInterval** (Duration)
- **Duration** (const)
- **Duration** (const)
- **Duration** (const)
- **Duration** (const)
- **getPlatformOptimizations** (Map<String, dynamic>)
- **getPlatformCapabilities** (Map<String, dynamic>)
- **_createWebPlatformService** (ISyncPlatformService)
- **WebSyncPlatformService** (return)
- **UnsupportedError** (throw)

---

### WebSyncPlatformService

Stub implementation of web platform service for non-web environments

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

#### Methods

- **initialize** (Future<bool>)
- **UnsupportedError** (throw)
- **dispose** (Future<void>)
- **readFile** (Future<FileOperationResult>)
- **UnsupportedError** (throw)
- **readFileAsBytes** (Future<FileOperationResult>)
- **UnsupportedError** (throw)
- **writeFile** (Future<FileOperationResult>)
- **UnsupportedError** (throw)
- **writeFileAsBytes** (Future<FileOperationResult>)
- **UnsupportedError** (throw)
- **deleteFile** (Future<FileOperationResult>)
- **UnsupportedError** (throw)
- **fileExists** (Future<FileOperationResult>)
- **UnsupportedError** (throw)
- **createDirectory** (Future<FileOperationResult>)
- **UnsupportedError** (throw)
- **listDirectory** (Future<FileOperationResult>)
- **UnsupportedError** (throw)
- **getFileSize** (Future<int?>)
- **UnsupportedError** (throw)
- **getFileModificationTime** (Future<DateTime?>)
- **UnsupportedError** (throw)
- **createSyncCacheDirectory** (Future<String>)
- **UnsupportedError** (throw)
- **cleanupOldCacheFiles** (Future<void>)
- **UnsupportedError** (throw)
- **getNetworkInfo** (Future<PlatformNetworkInfo>)
- **UnsupportedError** (throw)
- **isNetworkSuitableForSync** (Future<bool>)
- **UnsupportedError** (throw)
- **estimateNetworkSpeed** (Future<double?>)
- **UnsupportedError** (throw)
- **getBatteryInfo** (Future<PlatformBatteryInfo>)
- **UnsupportedError** (throw)
- **isPowerSavingMode** (Future<bool>)
- **UnsupportedError** (throw)
- **getRecommendedSyncInterval** (Future<Duration>)
- **UnsupportedError** (throw)
- **getDatabaseConfig** (Future<PlatformDatabaseConfig>)
- **UnsupportedError** (throw)
- **initializeDatabase** (Future<bool>)
- **UnsupportedError** (throw)
- **vacuumDatabase** (Future<bool>)
- **UnsupportedError** (throw)
- **getDatabaseSize** (Future<int?>)
- **UnsupportedError** (throw)
- **backupDatabase** (Future<String?>)
- **UnsupportedError** (throw)
- **restoreDatabase** (Future<bool>)
- **UnsupportedError** (throw)
- **isRunningInBackground** (Future<bool>)
- **UnsupportedError** (throw)
- **requestBackgroundPermission** (Future<bool>)
- **UnsupportedError** (throw)
- **getAvailableStorageSpace** (Future<int?>)
- **UnsupportedError** (throw)
- **hasResourcesForSync** (Future<bool>)
- **UnsupportedError** (throw)
- **UnsupportedError** (throw)
- **scheduleBackgroundSync** (Future<bool>)
- **UnsupportedError** (throw)
- **cancelBackgroundSync** (Future<bool>)
- **UnsupportedError** (throw)
- **hasRequiredPermissions** (Future<bool>)
- **UnsupportedError** (throw)
- **requestPermissions** (Future<bool>)
- **UnsupportedError** (throw)
- **encryptData** (Future<String?>)
- **UnsupportedError** (throw)
- **decryptData** (Future<String?>)
- **UnsupportedError** (throw)
- **storeSecureValue** (Future<bool>)
- **UnsupportedError** (throw)
- **getSecureValue** (Future<String?>)
- **UnsupportedError** (throw)
- **deleteSecureValue** (Future<bool>)
- **UnsupportedError** (throw)
- **logDiagnosticInfo** (Future<void>)
- **UnsupportedError** (throw)
- **UnsupportedError** (throw)
- **exportLogs** (Future<String?>)
- **UnsupportedError** (throw)

---

### WebSyncPlatformService

Web-specific platform service implementation

**Source:** `lib\src\platform\usm_web_platform_service.dart`

#### Methods

- **initialize** (Future<bool>)
- **paths** (specific)
- **_startNetworkMonitoring** (monitoring)
- **logDiagnosticInfo** (await)
- **logDiagnosticInfo** (await)
- **dispose** (Future<void>)
- **logDiagnosticInfo** (await)
- **readFile** (Future<FileOperationResult>)
- **readFileAsBytes** (Future<FileOperationResult>)
- **writeFile** (Future<FileOperationResult>)
- **writeFileAsBytes** (Future<FileOperationResult>)
- **deleteFile** (Future<FileOperationResult>)
- **fileExists** (Future<FileOperationResult>)
- **createDirectory** (Future<FileOperationResult>)
- **listDirectory** (Future<FileOperationResult>)
- **getFileSize** (Future<int?>)
- **logDiagnosticInfo** (await)
- **getFileModificationTime** (Future<DateTime?>)
- **logDiagnosticInfo** (await)
- **createSyncCacheDirectory** (Future<String>)
- **cleanupOldCacheFiles** (Future<void>)
- **Duration** (const)
- **logDiagnosticInfo** (await)
- **logDiagnosticInfo** (await)
- **getNetworkInfo** (Future<PlatformNetworkInfo>)
- **PlatformNetworkInfo** (const)
- **API** (connection)
- **PlatformNetworkInfo** (return)
- **PlatformNetworkInfo** (const)
- **logDiagnosticInfo** (await)
- **PlatformNetworkInfo** (const)
- **isNetworkSuitableForSync** (Future<bool>)
- **getNetworkInfo** (await)
- **estimateNetworkSpeed** (Future<double?>)
- **if** (fast)
- **logDiagnosticInfo** (await)
- **getBatteryInfo** (Future<PlatformBatteryInfo>)
- **API** (Battery)
- **PlatformBatteryInfo** (const)
- **logDiagnosticInfo** (await)
- **PlatformBatteryInfo** (const)
- **isPowerSavingMode** (Future<bool>)
- **getRecommendedSyncInterval** (Future<Duration>)
- **getNetworkInfo** (await)
- **if** (connections)
- **Duration** (const)
- **Duration** (const)
- **getDatabaseConfig** (Future<PlatformDatabaseConfig>)
- **PlatformDatabaseConfig** (return)
- **initializeDatabase** (Future<bool>)
- **logDiagnosticInfo** (await)
- **logDiagnosticInfo** (await)
- **vacuumDatabase** (Future<bool>)
- **logDiagnosticInfo** (await)
- **getDatabaseSize** (Future<int?>)
- **if** (usage)
- **logDiagnosticInfo** (await)
- **backupDatabase** (Future<String?>)
- **logDiagnosticInfo** (await)
- **logDiagnosticInfo** (await)
- **restoreDatabase** (Future<bool>)
- **logDiagnosticInfo** (await)
- **logDiagnosticInfo** (await)
- **isRunningInBackground** (Future<bool>)
- **requestBackgroundPermission** (Future<bool>)
- **getAvailableStorageSpace** (Future<int?>)
- **logDiagnosticInfo** (await)
- **hasResourcesForSync** (Future<bool>)
- **getAvailableStorageSpace** (await)
- **getNetworkInfo** (await)
- **getNetworkInfo** (await)
- **getAvailableStorageSpace** (await)
- **scheduleBackgroundSync** (Future<bool>)
- **Worker** (Service)
- **logDiagnosticInfo** (await)
- **cancelBackgroundSync** (Future<bool>)
- **logDiagnosticInfo** (await)
- **hasRequiredPermissions** (Future<bool>)
- **requestPermissions** (Future<bool>)
- **encryptData** (Future<String?>)
- **logDiagnosticInfo** (await)
- **decryptData** (Future<String?>)
- **logDiagnosticInfo** (await)
- **storeSecureValue** (Future<bool>)
- **_getSecureStorage** (await)
- **encryptData** (await)
- **_setSecureStorage** (await)
- **logDiagnosticInfo** (await)
- **getSecureValue** (Future<String?>)
- **_getSecureStorage** (await)
- **decryptData** (await)
- **logDiagnosticInfo** (await)
- **deleteSecureValue** (Future<bool>)
- **_getSecureStorage** (await)
- **_setSecureStorage** (await)
- **logDiagnosticInfo** (await)
- **logDiagnosticInfo** (Future<void>)
- **_getLogs** (await)
- **if** (bloat)
- **_setLogs** (await)
- **print** (loops)
- **getNetworkInfo** (await)
- **getBatteryInfo** (await)
- **getAvailableStorageSpace** (await)
- **exportLogs** (Future<String?>)
- **_getLogs** (await)
- **logDiagnosticInfo** (await)
- **_getStorageKey** (String)
- **_mapConnectionToQuality** (NetworkQuality)
- **_setLogs** (Future<void>)
- **_setSecureStorage** (Future<void>)
- **_startNetworkMonitoring** (void)
- **getNetworkInfo** (await)
- **getNetworkInfo** (await)
- **Duration** (const)
- **getNetworkInfo** (await)
- **_startBatteryMonitoring** (void)
- **monitoring** (battery)
- **Duration** (const)
- **getBatteryInfo** (await)

---

### WindowsSyncPlatformService

Windows-specific platform service implementation

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

#### Methods

- **initialize** (Future<bool>)
- **_ensureDirectoryExists** (await)
- **_ensureDirectoryExists** (await)
- **_ensureDirectoryExists** (await)
- **_startNetworkMonitoring** (timers)
- **logDiagnosticInfo** (await)
- **logDiagnosticInfo** (await)
- **dispose** (Future<void>)
- **logDiagnosticInfo** (await)
- **readFile** (Future<FileOperationResult>)
- **readFileAsBytes** (Future<FileOperationResult>)
- **writeFile** (Future<FileOperationResult>)
- **writeFileAsBytes** (Future<FileOperationResult>)
- **deleteFile** (Future<FileOperationResult>)
- **fileExists** (Future<FileOperationResult>)
- **createDirectory** (Future<FileOperationResult>)
- **listDirectory** (Future<FileOperationResult>)
- **getFileSize** (Future<int?>)
- **logDiagnosticInfo** (await)
- **getFileModificationTime** (Future<DateTime?>)
- **logDiagnosticInfo** (await)
- **createSyncCacheDirectory** (Future<String>)
- **_ensureDirectoryExists** (await)
- **cleanupOldCacheFiles** (Future<void>)
- **Duration** (const)
- **for** (await)
- **logDiagnosticInfo** (await)
- **logDiagnosticInfo** (await)
- **getNetworkInfo** (Future<PlatformNetworkInfo>)
- **PlatformNetworkInfo** (const)
- **PlatformNetworkInfo** (const)
- **logDiagnosticInfo** (await)
- **PlatformNetworkInfo** (const)
- **isNetworkSuitableForSync** (Future<bool>)
- **getNetworkInfo** (await)
- **estimateNetworkSpeed** (Future<double?>)
- **if** (connection)
- **logDiagnosticInfo** (await)
- **getBatteryInfo** (Future<PlatformBatteryInfo>)
- **PlatformBatteryInfo** (const)
- **isPowerSavingMode** (Future<bool>)
- **getRecommendedSyncInterval** (Future<Duration>)
- **getNetworkInfo** (await)
- **Duration** (const)
- **Duration** (const)
- **getDatabaseConfig** (Future<PlatformDatabaseConfig>)
- **PlatformDatabaseConfig** (return)
- **initializeDatabase** (Future<bool>)
- **logDiagnosticInfo** (await)
- **logDiagnosticInfo** (await)
- **vacuumDatabase** (Future<bool>)
- **logDiagnosticInfo** (await)
- **getDatabaseSize** (Future<int?>)
- **backupDatabase** (Future<String?>)
- **_ensureDirectoryExists** (await)
- **logDiagnosticInfo** (await)
- **logDiagnosticInfo** (await)
- **restoreDatabase** (Future<bool>)
- **logDiagnosticInfo** (await)
- **logDiagnosticInfo** (await)
- **isRunningInBackground** (Future<bool>)
- **requestBackgroundPermission** (Future<bool>)
- **getAvailableStorageSpace** (Future<int?>)
- **logDiagnosticInfo** (await)
- **hasResourcesForSync** (Future<bool>)
- **getAvailableStorageSpace** (await)
- **getNetworkInfo** (await)
- **getNetworkInfo** (await)
- **getAvailableStorageSpace** (await)
- **scheduleBackgroundSync** (Future<bool>)
- **logDiagnosticInfo** (await)
- **cancelBackgroundSync** (Future<bool>)
- **logDiagnosticInfo** (await)
- **hasRequiredPermissions** (Future<bool>)
- **requestPermissions** (Future<bool>)
- **encryptData** (Future<String?>)
- **logDiagnosticInfo** (await)
- **decryptData** (Future<String?>)
- **logDiagnosticInfo** (await)
- **storeSecureValue** (Future<bool>)
- **encryptData** (await)
- **logDiagnosticInfo** (await)
- **getSecureValue** (Future<String?>)
- **decryptData** (await)
- **logDiagnosticInfo** (await)
- **deleteSecureValue** (Future<bool>)
- **logDiagnosticInfo** (await)
- **logDiagnosticInfo** (Future<void>)
- **getNetworkInfo** (await)
- **getBatteryInfo** (await)
- **getAvailableStorageSpace** (await)
- **exportLogs** (Future<String?>)
- **filtering** (level)
- **logDiagnosticInfo** (await)
- **_ensureDirectoryExists** (Future<void>)
- **_startNetworkMonitoring** (void)
- **Duration** (const)
- **getNetworkInfo** (await)
- **_startBatteryMonitoring** (void)
- **Duration** (const)
- **getBatteryInfo** (await)

---

### BatchSyncService

Service for handling batch synchronization operations  This service provides efficient batch processing capabilities including: - Batch creation, update, and deletion operations - Intelligent batching strategies based on data characteristics - Progress tracking and error handling for batch operations - Automatic retry mechanisms for failed batch items

**Source:** `lib\src\services\usm_batch_sync_service.dart`

#### Methods

- **BatchSyncService** (const)
  - Creates a new batch sync service
- **executeBatch** (Future<BatchSyncResult>)
  - Execute a batch of sync operations  Processes multiple [operations] in batches, optimizing for performance and network efficiency. Returns a [BatchSyncResult] with detailed results for each operation.  Example: ```dart final operations = [ BatchSyncOperation.create('users', userData1), BatchSyncOperation.update('users', 'id1', userData2), BatchSyncOperation.delete('users', 'id2'), ];  final result = await service.executeBatch( operations, strategy: BatchStrategy.parallel(), ); ```
- **_executeSequential** (await)
- **_executeParallel** (await)
- **_executeChunked** (await)
- **_executeAdaptive** (await)
- **BatchTimeoutException** (throw)
- **BatchSyncResult** (return)
- **optimizeBatchStrategy** (BatchStrategy)
  - Optimize batching strategy based on operation characteristics  Analyzes the [operations] and returns a recommended [BatchStrategy] based on factors like operation types, data sizes, and system resources.
- **if** (simplicity)
- **if** (approach)
- **if** (parallel)
- **createBatch** (List<BatchSyncOperation>)
  - Create a batch of create operations  Helper method to easily create multiple records of the same type.
- **updateBatch** (List<BatchSyncOperation>)
  - Create a batch of update operations  Helper method to easily update multiple records of the same type.
- **deleteBatch** (List<BatchSyncOperation>)
  - Create a batch of delete operations  Helper method to easily delete multiple records of the same type.
- **_executeSequential** (Future<void>)
- **_executeSingleOperation** (await)
- **if** (enabled)
- **_retryFailedOperations** (await)
- **_executeParallel** (Future<void>)
- **_executeSingleOperation** (await)
- **if** (enabled)
- **_retryFailedOperations** (await)
- **_executeChunked** (Future<void>)
- **_executeSequential** (await)
- **_executeAdaptive** (Future<void>)
- **_executeParallel** (await)
- **_executeSequential** (await)
- **if** (performance)
- **if** (size)
- **if** (else)
- **_retryFailedOperations** (Future<void>)
- **_executeSingleOperation** (await)
- **_executeSingleOperation** (Future<SyncResult>)
- **if** (failures)
- **Exception** (throw)
- **_calculateOptimalChunkSize** (int)
- **if** (size)
- **max** (return)
- **if** (else)
- **max** (return)
- **min** (return)
- **_calculateMaxConcurrency** (int)
- **switch** (return)

---

### BatchSyncOperation

Represents a single operation in a batch

**Source:** `lib\src\services\usm_batch_sync_service.dart`

#### Methods

- **ID** (Entity)
- **payload** (Data)
- **BatchSyncOperation** (const)
  - Creates a new batch sync operation
- **BatchSyncOperation** (return)
- **BatchSyncOperation** (return)
- **BatchSyncOperation** (return)
- **toString** (String)

---

### BatchStrategy

Strategy for executing batch operations

**Source:** `lib\src\services\usm_batch_sync_service.dart`

#### Methods

- **operations** (concurrent)
  - Maximum number of
- **chunk** (each)
  - Size of
- **chunks** (concurrent)
  - Maximum number of
- **BatchStrategy** (const)
  - Creates a new batch strategy
- **BatchStrategy** (return)
- **BatchStrategy** (return)
- **BatchStrategy** (return)
- **BatchStrategy** (return)
- **toString** (String)

---

### BatchProgress

Progress information for batch operations

**Source:** `lib\src\services\usm_batch_sync_service.dart`

#### Methods

- **BatchProgress** (const)
  - Creates new batch progress information
- **percentage** (a)
  - Progress as
- **toString** (String)

---

### BatchSyncResult

Result of a batch sync operation

**Source:** `lib\src\services\usm_batch_sync_service.dart`

#### Methods

- **BatchSyncResult** (const)
  - Creates a new batch sync result
- **Duration** (return)
- **toString** (String)

---

### Semaphore

Simple semaphore implementation for concurrency control

**Source:** `lib\src\services\usm_batch_sync_service.dart`

#### Methods

- **acquire** (Future<void>)
- **release** (void)
- **if** (else)

---

### BatchTimeoutException

Exception thrown when batch operations timeout

**Source:** `lib\src\services\usm_batch_sync_service.dart`

#### Methods

- **BatchTimeoutException** (const)
  - Creates a new batch timeout exception
- **toString** (String)

---

### ConflictHistoryEntry

Conflict history entry for tracking resolution decisions

**Source:** `lib\src\services\usm_conflict_history_service.dart`

#### Methods

- **ConflictHistoryEntry** (const)
- **ConflictHistoryEntry** (return)
- **withNotes** (ConflictHistoryEntry)
  - Creates a copy with updated notes
- **ConflictHistoryEntry** (return)
- **toJson** (Map<String, dynamic>)
- **ConflictHistoryEntry** (return)

---

### ConflictResolutionStats

Statistics about conflict resolution patterns

**Source:** `lib\src\services\usm_conflict_history_service.dart`

#### Methods

- **ConflictResolutionStats** (const)
- **toJson** (Map<String, dynamic>)

---

### ConflictHistoryService

Service for tracking and analyzing conflict resolution history

**Source:** `lib\src\services\usm_conflict_history_service.dart`

#### Methods

- **recordConflictResolution** (void)
  - Adds a conflict and its resolution to history
- **addNotesToEntry** (void)
  - Adds notes to an existing history entry
- **_updateEntryInIndexes** (indexes)
- **_updateEntryInIndexes** (void)
- **getAllHistory** (List<ConflictHistoryEntry>)
  - Gets all history entries
- **getEntityHistory** (List<ConflictHistoryEntry>)
  - Gets history for a specific entity
- **getCollectionHistory** (List<ConflictHistoryEntry>)
  - Gets history for a specific collection
- **getRecentHistory** (List<ConflictHistoryEntry>)
  - Gets recent history entries
- **getUnresolvedConflicts** (List<ConflictHistoryEntry>)
  - Gets unresolved conflicts
- **getManuallyResolvedConflicts** (List<ConflictHistoryEntry>)
  - Gets manually resolved conflicts
- **getConflictsByStrategy** (List<ConflictHistoryEntry>)
  - Gets conflicts resolved with specific strategy
- **getConflictsInDateRange** (List<ConflictHistoryEntry>)
  - Gets conflicts in date range
- **generateStats** (ConflictResolutionStats)
  - Generates comprehensive statistics
- **ConflictResolutionStats** (return)
- **ConflictResolutionStats** (return)
- **suggestStrategyForConflict** (EnhancedConflictResolutionStrategy)
  - Learns from past resolutions to suggest strategies
- **conflicts** (similar)
- **exportToJson** (Map<String, dynamic>)
  - Exports history to JSON
- **importFromJson** (void)
  - Imports history from JSON
- **clearHistory** (void)
  - Clears all history
- **dispose** (void)
  - Disposes resources

---

### SyncConflict

Represents a conflict between local and remote data

**Source:** `lib\src\services\usm_conflict_resolver.dart`

#### Methods

- **SyncConflict** (const)
- **toString** (String)

---

### SyncConflictResolution

Result of conflict resolution

**Source:** `lib\src\services\usm_conflict_resolver.dart`

#### Methods

- **SyncConflictResolution** (const)
- **SyncConflictResolution** (return)
- **SyncConflictResolution** (return)
- **for** (fields)
- **SyncConflictResolution** (return)
- **SyncConflictResolution** (return)
- **toString** (String)

---

### ConflictResolver

**Source:** `lib\src\services\usm_conflict_resolver.dart`

#### Methods

- **resolveConflict** (SyncConflictResolution)
  - Resolves a conflict between local and remote data
- **canResolve** (bool)
  - Returns whether this resolver can handle the given conflict

---

### DefaultConflictResolver

Default conflict resolver that uses configurable strategies

**Source:** `lib\src\services\usm_conflict_resolver.dart`

#### Methods

- **canResolve** (bool)
- **resolveConflict** (SyncConflictResolution)
- **_resolveByTimestamp** (return)
- **_resolveByTimestamp** (return)
- **_intelligentMerge** (return)
- **_customResolve** (return)
- **_resolveByTimestamp** (SyncConflictResolution)
- **if** (numbers)
- **_intelligentMerge** (SyncConflictResolution)
- **for** (strategies)
- **_applyIntelligentFieldMerge** (logic)
- **SyncConflictResolution** (return)
- **_applyIntelligentFieldMerge** (void)
- **if** (types)
- **if** (else)
- **if** (that)
- **if** (else)
- **remote** (with)
- **_customResolve** (SyncConflictResolution)
- **_parseDateTime** (return)

---

### ConflictResolverManager

Manager for conflict resolution with pluggable resolvers

**Source:** `lib\src\services\usm_conflict_resolver.dart`

#### Methods

- **setDefaultResolver** (void)
  - Sets the default resolver
- **registerResolver** (void)
  - Registers a resolver for a specific collection
- **removeResolver** (void)
  - Removes a resolver for a collection
- **if** (else)
- **if** (else)
- **if** (mismatch)
- **if** (differences)
- **resolveConflict** (SyncConflictResolution)
  - Resolves a conflict using the appropriate resolver
- **if** (else)
- **dispose** (void)
  - Dispose method to clean up resources

---

### ArrayMergeStrategy

Array merge strategy for handling list conflicts

**Source:** `lib\src\services\usm_custom_merge_strategies.dart`

#### Methods

- **mergeValues** (dynamic)
- **if** (characteristics)
- **_mergeIdLists** (return)
- **if** (else)
- **_mergeTimestampOrderedLists** (return)
- **_mergeGenericLists** (return)
- **getConfidenceScore** (double)
- **if** (lists)
- **if** (else)
- **validateMergedValue** (bool)
- **_isIdList** (bool)
- **ID** (an)
- **_isTimestampOrderedList** (bool)
- **_mergeIdLists** (List<dynamic>)
- **lists** (ID)
- **_mergeTimestampOrderedLists** (List<dynamic>)
- **_mergeGenericLists** (List<dynamic>)
- **for** (first)
- **for** (duplicates)
- **if** (else)

---

### NumericMergeStrategy

Numeric merge strategy for handling numerical conflicts

**Source:** `lib\src\services\usm_custom_merge_strategies.dart`

#### Methods

- **mergeValues** (dynamic)
- **if** (logic)
- **if** (else)
- **return** (average)
- **if** (else)
- **getConfidenceScore** (double)
- **if** (patterns)
- **validateMergedValue** (bool)
- **_toNumber** (return)

---

### TextMergeStrategy

Text merge strategy for handling string conflicts

**Source:** `lib\src\services\usm_custom_merge_strategies.dart`

#### Methods

- **mergeValues** (dynamic)
- **if** (logic)
- **_mergeDescriptiveText** (return)
- **if** (else)
- **if** (else)
- **remote** (prefer)
- **getConfidenceScore** (double)
- **if** (text)
- **if** (else)
- **validateMergedValue** (bool)
- **_mergeDescriptiveText** (String)
- **if** (other)
- **if** (them)
- **_calculateSimilarity** (double)

---

### JsonObjectMergeStrategy

JSON object merge strategy for handling complex object conflicts

**Source:** `lib\src\services\usm_custom_merge_strategies.dart`

#### Methods

- **mergeValues** (dynamic)
- **_deepMerge** (return)
- **getConfidenceScore** (double)
- **validateMergedValue** (bool)
- **_deepMerge** (Map<String, dynamic>)
- **for** (base)
- **if** (else)
- **if** (else)

---

### BooleanMergeStrategy

Boolean merge strategy for handling boolean conflicts

**Source:** `lib\src\services\usm_custom_merge_strategies.dart`

#### Methods

- **mergeValues** (dynamic)
- **if** (logic)
- **true** (prefer)
- **if** (else)
- **true** (prefer)
- **if** (else)
- **true** (prefer)
- **getConfidenceScore** (double)
- **if** (patterns)
- **validateMergedValue** (bool)

---

### TimestampMergeStrategy

Timestamp merge strategy for handling date/time conflicts

**Source:** `lib\src\services\usm_custom_merge_strategies.dart`

#### Methods

- **mergeValues** (dynamic)
- **if** (else)
- **if** (else)
- **if** (logic)
- **if** (else)
- **getConfidenceScore** (double)
- **if** (fields)
- **validateMergedValue** (bool)
- **_parseTimestamp** (return)

---

### DeltaSyncService

Service for handling delta synchronization operations  This service is responsible for: - Calculating deltas between local and remote data - Generating delta patches for efficient sync - Applying delta patches to reconstruct data - Managing delta metadata and checksums

**Source:** `lib\src\services\usm_delta_sync_service.dart`

#### Methods

- **DeltaSyncService** (const)
  - Creates a new delta sync service instance
- **calculateDelta** (DeltaPatch)
  - Calculate delta between two data objects  Returns a [DeltaPatch] containing only the changed fields and metadata needed to transform [oldData] into [newData].  Example: ```dart final oldData = {'name': 'John', 'age': 30, 'city': 'New York'}; final newData = {'name': 'John', 'age': 31, 'city': 'Boston'}; final patch = service.calculateDelta(oldData, newData); // patch.changes will contain: {'age': 31, 'city': 'Boston'} ```
- **for** (fields)
- **for** (fields)
- **DeltaPatch** (return)
- **applyDelta** (Map<String, dynamic>)
  - Apply a delta patch to existing data  Takes [baseData] and applies the [patch] to produce the updated data. Optionally validates checksums if [validateChecksum] is true.  Throws [DeltaValidationException] if checksum validation fails.
- **DeltaValidationException** (throw)
- **for** (changes)
- **for** (deletions)
- **if** (provided)
- **DeltaValidationException** (throw)
- **calculateCollectionDelta** (CollectionDelta)
  - Calculate delta for a collection of records  Compares [oldRecords] with [newRecords] and returns a [CollectionDelta] containing all changes needed to transform the old collection to the new one.
- **for** (lookup)
- **for** (updates)
- **for** (deletions)
- **CollectionDelta** (return)
- **for** (records)
- **for** (patches)
- **for** (records)
- **for** (records)
- **_calculateChecksum** (String)
  - Calculate checksum for data integrity verification
- **calculation** (hash)
- **_sortMapRecursively** (Map<String, dynamic>)
  - Sort map keys recursively for consistent serialization
- **if** (else)
- **_sortMapRecursively** (return)
- **_deepEquals** (bool)
  - Deep equality check for complex objects

---

### DeltaPatch

Represents a delta patch for a single entity

**Source:** `lib\src\services\usm_delta_sync_service.dart`

#### Methods

- **data** (source)
  - Checksum of the
- **data** (target)
  - Checksum of the
- **DeltaPatch** (const)
  - Creates a new delta patch
- **toJson** (Map<String, dynamic>)
  - Convert to JSON for serialization
- **DeltaPatch** (return)
- **toString** (String)

---

### CollectionDelta

Represents a delta for an entire collection

**Source:** `lib\src\services\usm_delta_sync_service.dart`

#### Methods

- **CollectionDelta** (const)
  - Creates a new collection delta
- **for** (patches)
- **toJson** (Map<String, dynamic>)
  - Convert to JSON for serialization
- **CollectionDelta** (return)
- **toString** (String)

---

### DeltaValidationException

Exception thrown when delta validation fails

**Source:** `lib\src\services\usm_delta_sync_service.dart`

#### Methods

- **DeltaValidationException** (const)
  - Creates a new delta validation exception
- **toString** (String)

---

### IntelligentConflictResolver

Enhanced conflict resolver with intelligent merge strategies

**Source:** `lib\src\services\usm_enhanced_conflict_resolution_manager.dart`

#### Methods

- **_initializeDefaultMergeStrategies** (void)
- **canResolve** (bool)
- **getConfidenceScore** (double)
- **resolveConflict** (EnhancedSyncConflictResolution)
- **_performIntelligentMerge** (return)
- **_resolveByTimestamp** (return)
- **_resolveByTimestamp** (return)
- **_performIntelligentMerge** (return)
- **_performIntelligentMerge** (EnhancedSyncConflictResolution)
- **for** (field)
- **if** (merges)
- **_getFieldStrategy** (String)
- **if** (selection)
- **if** (else)
- **if** (else)
- **if** (else)
- **if** (else)
- **if** (else)
- **_applyFieldStrategy** (dynamic)
- **_getStrategyConfidence** (double)
- **_resolveByTimestamp** (EnhancedSyncConflictResolution)
- **if** (numbers)
- **_isTimestampField** (bool)
- **registerMergeStrategy** (void)
  - Registers a custom merge strategy
- **setFieldStrategy** (void)
  - Sets field-specific strategy
- **setCollectionStrategy** (void)
  - Sets collection-specific strategy

---

### EnhancedConflictResolutionManager

Enhanced conflict resolution manager that coordinates all conflict resolution services

**Source:** `lib\src\services\usm_enhanced_conflict_resolution_manager.dart`

#### Methods

- **setDefaultResolver** (void)
  - Sets the default resolver
- **registerResolver** (void)
  - Registers a resolver for a specific collection
- **registerMergeStrategy** (void)
  - Registers a custom merge strategy globally
- **if** (exists)
- **for** (resolvers)
- **if** (else)
- **if** (else)
- **if** (differences)
- **_analyzeFieldConflict** (FieldConflictInfo)
- **if** (type)
- **if** (else)
- **if** (else)
- **if** (else)
- **if** (strategies)
- **FieldConflictInfo** (return)
- **_isBusinessCriticalField** (bool)
- **_isTimestampField** (bool)
- **resolveConflict** (EnhancedSyncConflictResolution)
  - Resolves a conflict using the best available resolver
- **if** (else)
- **prepareConflictForInteractiveResolution** (Map<String, dynamic>)
  - Prepares conflict for interactive resolution
- **processInteractiveResolution** (InteractiveResolutionResult)
  - Processes user resolution from interactive UI
- **getStatistics** (ConflictResolutionStats)
  - Gets conflict resolution statistics
- **suggestStrategyForConflict** (EnhancedConflictResolutionStrategy)
  - Suggests strategy for a conflict based on history
- **exportConflictHistory** (Map<String, dynamic>)
  - Exports conflict history
- **importConflictHistory** (void)
  - Imports conflict history
- **dispose** (void)
  - Disposes all resources

---

### FieldConflictInfo

Field-level conflict information with enhanced metadata

**Source:** `lib\src\services\usm_enhanced_conflict_resolver.dart`

#### Methods

- **FieldConflictInfo** (const)
- **toJson** (Map<String, dynamic>)
- **FieldConflictInfo** (return)

---

### EnhancedSyncConflict

Enhanced conflict with detailed field-level information

**Source:** `lib\src\services\usm_enhanced_conflict_resolver.dart`

#### Methods

- **getConflictsByType** (List<FieldConflictInfo>)
  - Gets conflicts by type
- **getHighConfidenceConflicts** (List<FieldConflictInfo>)
  - Gets high-confidence conflicts
- **toJson** (Map<String, dynamic>)
- **EnhancedSyncConflict** (return)

---

### EnhancedSyncConflictResolution

Result of enhanced conflict resolution

**Source:** `lib\src\services\usm_enhanced_conflict_resolver.dart`

#### Methods

- **EnhancedSyncConflictResolution** (const)
- **EnhancedSyncConflictResolution** (return)
- **EnhancedSyncConflictResolution** (return)
- **EnhancedSyncConflictResolution** (return)
- **EnhancedSyncConflictResolution** (return)
- **toJson** (Map<String, dynamic>)
- **EnhancedSyncConflictResolution** (return)
- **toString** (String)

---

### EnhancedConflictResolver

**Source:** `lib\src\services\usm_enhanced_conflict_resolver.dart`

#### Methods

- **resolveConflict** (EnhancedSyncConflictResolution)
  - Resolves a conflict between local and remote data
- **resolver** (this)
  - Returns the priority of
- **canResolve** (bool)
  - Returns whether this resolver can handle the given conflict
- **getConfidenceScore** (double)
  - Returns confidence score for handling this conflict type
- **preprocessConflict** (EnhancedSyncConflict)
  - Pre-processes conflict for better resolution
- **postprocessResolution** (EnhancedSyncConflictResolution)
  - Post-processes resolution for validation

---

### CustomMergeStrategy

**Source:** `lib\src\services\usm_enhanced_conflict_resolver.dart`

#### Methods

- **mergeValues** (dynamic)
  - Merges two values for a specific field
- **getConfidenceScore** (double)
  - Returns confidence score for merging these values
- **validateMergedValue** (bool)
  - Validates the merged result

---

### InteractiveResolutionResult

Interactive conflict resolution result

**Source:** `lib\src\services\usm_interactive_conflict_ui.dart`

#### Methods

- **InteractiveResolutionResult** (const)

---

### FieldResolutionChoice

Field resolution choice for interactive UI

**Source:** `lib\src\services\usm_interactive_conflict_ui.dart`

#### Methods

- **FieldResolutionChoice** (const)
- **toJson** (Map<String, dynamic>)

---

### InteractiveConflictUIService

Interactive conflict resolution UI helper

**Source:** `lib\src\services\usm_interactive_conflict_ui.dart`

#### Methods

- **_initializeMergeStrategies** (void)
- **prepareConflictForUI** (Map<String, dynamic>)
  - Prepares conflict data for interactive UI presentation
- **processUserResolution** (InteractiveResolutionResult)
  - Processes user resolution choices
- **for** (field)
- **if** (else)
- **_createFieldChoice** (FieldResolutionChoice)
  - Creates resolution choice for a field
- **FieldResolutionChoice** (return)
- **_getAvailableStrategiesForField** (List<String>)
  - Gets available strategies for a field based on its type and value
- **if** (strategies)
- **if** (fields)
- **_getRecommendedStrategy** (String)
  - Gets recommended strategy for a field
- **if** (patterns)
- **if** (type)
- **_applyStrategy** (dynamic)
  - Applies a resolution strategy to get the resolved value
- **_calculateConfidence** (double)
  - Calculates confidence score for a strategy
- **_generateConflictSummary** (Map<String, dynamic>)
  - Generates a human-readable summary of the conflict
- **if** (fields)
- **_calculateAverageConfidence** (double)
- **_assessRiskLevel** (String)
- **if** (else)
- **_isTimestampField** (bool)
- **_isTimestampValue** (bool)
- **registerMergeStrategy** (void)
  - Registers a custom merge strategy
- **dispose** (void)
  - Disposes resources

---

### SmartSyncScheduler

Service for intelligent sync scheduling and optimization  This service analyzes usage patterns and system conditions to automatically adjust sync timing and frequency for optimal performance and user experience.

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

#### Methods

- **SmartSyncScheduler** (scheduler)
  - Creates a new smart sync
- **scheduleEntity** (SyncSchedule)
  - Schedule sync for an entity with smart optimization  Analyzes the entity's sync patterns and current conditions to determine the optimal sync schedule. Returns a [SyncSchedule] describing when syncs will occur.  Example: ```dart final schedule = scheduler.scheduleEntity( 'user_profiles', priority: SyncPriority.high, strategy: EntitySyncStrategy.adaptive, ); ```
- **_cancelEntityTimer** (any)
- **_scheduleEntitySync** (sync)
- **updateStrategy** (void)
  - Update scheduling strategy dynamically  Changes the global scheduling approach and recalculates all active schedules using the new strategy.
- **_recalculateAllSchedules** (schedules)
- **recordSyncCompletion** (void)
  - Record successful sync completion  Updates metrics and usage patterns based on sync results to improve future scheduling decisions.
- **history** (to)
- **_adjustSchedulingBasedOnResult** (results)
- **pauseEntity** (void)
  - Pause scheduling for an entity  Temporarily stops automatic sync scheduling while preserving metrics and configuration for later resumption.
- **resumeEntity** (void)
  - Resume scheduling for an entity  Restarts automatic sync scheduling using the previously configured or optimized settings.
- **if** (settings)
- **getRecommendations** (List<SyncRecommendation>)
  - Get sync recommendations based on current patterns  Analyzes recent sync history and usage patterns to provide recommendations for optimizing sync schedules.
- **recalculateSchedules** (void)
  - Force sync schedule recalculation  Manually triggers recalculation of all sync schedules based on current conditions and patterns.
- **dispose** (void)
  - Dispose of the scheduler and clean up resources
- **for** (timers)
- **_initializeScheduler** (void)
- **Duration** (const)
- **_getOrCreateEntityMetrics** (EntitySyncMetrics)
- **_calculateOptimalInterval** (Duration)
- **switch** (strategy)
- **_applyIntervalBounds** (return)
- **_getBaseIntervalForPriority** (Duration)
- **Duration** (const)
- **Duration** (const)
- **Duration** (const)
- **Duration** (const)
- **_adjustIntervalForPatterns** (Duration)
- **Duration** (return)
- **if** (else)
- **Duration** (return)
- **_adjustIntervalForMetrics** (Duration)
- **Duration** (return)
- **if** (else)
- **Duration** (return)
- **_adjustIntervalForSystemConditions** (Duration)
- **switch** (conditions)
- **switch** (resources)
- **Duration** (return)
- **_applyIntervalBounds** (Duration)
- **_scheduleEntitySync** (void)
- **_cancelEntityTimer** (void)
- **_executeSyncForEntity** (void)
- **_notifyScheduleEvent** (occur)
- **_adjustSchedulingBasedOnResult** (void)
- **if** (else)
- **_recalculateAllSchedules** (void)
- **_optimizeStrategy** (void)
- **if** (performance)
- **if** (strategy)
- **if** (else)
- **if** (aggressive)
- **_generateEntityRecommendations** (List<SyncRecommendation>)
- **if** (changes)
- **Duration** (const)
- **if** (rate)
- **rate** (success)
- **_generateGlobalRecommendations** (List<SyncRecommendation>)
- **high** (is)
- **_calculateRecentFailureRate** (double)
- **Duration** (const)
- **_cleanupOldData** (void)
- **_updateAverage** (Duration)
- **Duration** (return)
- **_notifyScheduleEvent** (void)

---

### SmartSchedulerConfig

Configuration for the smart sync scheduler

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

#### Methods

- **SmartSchedulerConfig** (const)
  - Creates a new smart scheduler configuration
- **Duration** (const)
- **Duration** (const)
- **Duration** (const)
- **SmartSchedulerConfig** (const)
- **SmartSchedulerConfig** (const)
- **SmartSchedulerConfig** (const)

---

### EntitySyncMetrics

Metrics for tracking entity sync performance

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

#### Methods

- **EntitySyncMetrics** (metrics)
  - Creates new entity sync
- **percentage** (a)
  - Success rate as
- **percentage** (a)
  - Failure rate as
- **toString** (String)

---

### SyncSchedule

Represents a scheduled sync operation

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

#### Methods

- **SyncSchedule** (const)
  - Creates a new sync schedule
- **toString** (String)

---

### ScheduledSyncEvent

Events related to sync scheduling

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

#### Methods

- **name** (Entity)
- **schedule** (Associated)
- **ScheduledSyncEvent** (const)
  - Creates a new scheduled sync event
- **toString** (String)

---

### SyncEvent

Historical sync event for analysis

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

#### Methods

- **SyncEvent** (const)
  - Creates a new sync event

---

### UsagePattern

Usage pattern analysis for an entity

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

#### Methods

- **changes** (data)
  - How frequently
- **hours** (usage)
  - Peak
- **UsagePattern** (const)
  - Creates a new usage pattern

---

### SyncRecommendation

Recommendation for optimizing sync behavior

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

#### Methods

- **name** (Entity)
- **SyncRecommendation** (const)
  - Creates a new sync recommendation
- **toString** (String)

---

### SchedulingStrategy

Strategy for scheduling syncs

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

#### Methods

- **SchedulingStrategy** (const)
  - Creates a new scheduling strategy
- **SchedulingStrategy** (const)
- **SchedulingStrategy** (const)
- **SchedulingStrategy** (const)
- **toString** (String)

---

### SystemResourceMonitor

Monitors system resource usage

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

#### Methods

- **startMonitoring** (void)
- **dispose** (void)

---

### NetworkConditionMonitor

Monitors network conditions

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

#### Methods

- **startMonitoring** (void)
- **dispose** (void)

---

### UsagePatternAnalyzer

Analyzes usage patterns

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

#### Methods

- **recordSyncEvent** (void)
- **analyzeEntity** (UsagePattern)
- **UsagePattern** (const)
- **UsagePattern** (return)

---

### AlertRule

Alert configuration

**Source:** `lib\src\services\usm_sync_alerting_service.dart`

#### Methods

- **AlertRule** (const)
- **Duration** (const)
- **toJson** (Map<String, dynamic>)
- **AlertRule** (return)

---

### AlertCondition

Alert condition configuration

**Source:** `lib\src\services\usm_sync_alerting_service.dart`

#### Methods

- **AlertCondition** (const)
- **toJson** (Map<String, dynamic>)
- **AlertCondition** (return)

---

### SyncAlert

Alert instance

**Source:** `lib\src\services\usm_sync_alerting_service.dart`

#### Methods

- **SyncAlert** (const)
- **resolve** (SyncAlert)
  - Creates resolved version of alert
- **SyncAlert** (return)
- **acknowledge** (SyncAlert)
  - Creates acknowledged version of alert
- **SyncAlert** (return)
- **toJson** (Map<String, dynamic>)

---

### NotificationConfig

Notification configuration

**Source:** `lib\src\services\usm_sync_alerting_service.dart`

#### Methods

- **NotificationConfig** (const)
- **toJson** (Map<String, dynamic>)

---

### SyncAlertingService

Comprehensive sync alerting service

**Source:** `lib\src\services\usm_sync_alerting_service.dart`

#### Methods

- **addAlertRule** (void)
  - Adds or updates an alert rule
- **removeAlertRule** (void)
  - Removes an alert rule
- **setRuleEnabled** (void)
  - Enables or disables an alert rule
- **getAllRules** (List<AlertRule>)
  - Gets all alert rules
- **getActiveAlerts** (List<SyncAlert>)
  - Gets active alerts
- **getAlertHistory** (List<SyncAlert>)
  - Gets alert history
- **acknowledgeAlert** (void)
  - Acknowledges an alert
- **resolveAlert** (void)
  - Resolves an alert
- **suppressRule** (void)
  - Suppresses alerts for a rule temporarily
- **configureNotification** (void)
  - Configures notification channel
- **setNotificationEnabled** (void)
  - Enables or disables notification channel
- **getAlertStatistics** (Map<String, dynamic>)
  - Gets alert statistics
- **Duration** (const)
- **createDefaultRules** (List<AlertRule>)
- **AlertRule** (rate)
- **AlertRule** (rate)
- **AlertRule** (time)
- **AlertRule** (issues)
- **AlertRule** (usage)
- **AlertRule** (failures)
- **AlertRule** (backup)
- **_initializeDefaultRules** (void)
  - Initialize default alert rules
- **createDefaultRules** (in)
- **_startEvaluationLoop** (void)
  - Starts evaluation loop for all rules
- **_startRuleEvaluation** (void)
  - Starts evaluation for a specific rule
- **_evaluateRule** (evaluation)
- **_stopRuleEvaluation** (void)
  - Stops evaluation for a specific rule
- **_evaluateRule** (void)
  - Evaluates a specific alert rule
- **if** (else)
- **print** (error)
- **_evaluateCondition** (bool)
  - Evaluates an alert condition
- **_compareNumbers** (return)
- **_compareNumbers** (return)
- **_compareNumbers** (return)
- **_compareNumbers** (return)
- **_compareNumbers** (bool)
  - Compares two values numerically
- **compareFn** (return)
- **_getMetricValue** (dynamic)
  - Gets metric value for evaluation
- **_triggerAlert** (void)
  - Triggers a new alert
- **_sendNotifications** (notifications)
- **_generateAlertDescription** (String)
  - Generates alert description
- **_gatherAlertContext** (Map<String, dynamic>)
  - Gathers alert context
- **_sendNotifications** (void)
  - Sends notifications for an alert
- **_sendNotification** (void)
  - Sends notification via specific channel
- **notification** (Email)
- **_sendEmailNotification** (void)
  - Email notification (placeholder)
- **print** (service)
- **notification** (Push)
- **_sendPushNotification** (void)
  - Push notification (placeholder)
- **print** (service)
- **notification** (Webhook)
- **_sendWebhookNotification** (void)
  - Webhook notification (placeholder)
- **print** (URL)
- **notification** (SMS)
- **_sendSmsNotification** (void)
  - SMS notification (placeholder)
- **print** (service)
- **notification** (Slack)
- **_sendSlackNotification** (void)
  - Slack notification (placeholder)
- **print** (webhook)
- **dispose** (void)
  - Disposes the alerting service

---

### SyncOperationMetrics

Sync operation metrics for detailed tracking

**Source:** `lib\src\services\usm_sync_analytics_service.dart`

#### Methods

- **SyncOperationMetrics** (const)
- **complete** (SyncOperationMetrics)
  - Creates completed metrics
- **SyncOperationMetrics** (return)
- **toJson** (Map<String, dynamic>)
- **SyncOperationMetrics** (return)

---

### SyncPerformanceMetrics

Performance metrics for sync operations

**Source:** `lib\src\services\usm_sync_analytics_service.dart`

#### Methods

- **SyncPerformanceMetrics** (const)
- **toJson** (Map<String, dynamic>)

---

### SyncFailureAnalysis

Sync failure analysis data

**Source:** `lib\src\services\usm_sync_analytics_service.dart`

#### Methods

- **SyncFailureAnalysis** (const)
- **toJson** (Map<String, dynamic>)

---

### SyncHealthStatus

Real-time sync health status

**Source:** `lib\src\services\usm_sync_analytics_service.dart`

#### Methods

- **SyncHealthStatus** (const)
- **toJson** (Map<String, dynamic>)

---

### SyncAnalyticsService

Comprehensive sync analytics service

**Source:** `lib\src\services\usm_sync_analytics_service.dart`

#### Methods

- **Duration** (const)
- **startOperation** (String)
  - Starts tracking a new sync operation
- **updateOperation** (void)
  - Updates an active operation with progress
- **completeOperation** (void)
  - Completes an operation and moves it to history
- **cancelOperation** (void)
  - Cancels an active operation
- **getPerformanceMetrics** (SyncPerformanceMetrics)
  - Gets current performance metrics
- **Duration** (const)
- **SyncPerformanceMetrics** (return)
- **SyncPerformanceMetrics** (return)
- **getFailureAnalysis** (SyncFailureAnalysis)
  - Gets failure analysis
- **Duration** (const)
- **SyncFailureAnalysis** (return)
- **SyncFailureAnalysis** (return)
- **getCurrentHealthStatus** (SyncHealthStatus)
  - Gets current health status
- **Duration** (const)
- **Duration** (const)
- **impact** (rate)
- **impact** (Performance)
- **impact** (frequency)
- **if** (else)
- **if** (impact)
- **if** (else)
- **if** (else)
- **if** (else)
- **SyncHealthStatus** (return)
- **startHealthMonitoring** (void)
  - Starts automatic health monitoring
- **stopHealthMonitoring** (void)
  - Stops health monitoring
- **getActiveOperations** (List<SyncOperationMetrics>)
  - Gets all active operations
- **getOperationHistory** (List<SyncOperationMetrics>)
  - Gets operation history
- **descending** (time)
- **exportAnalytics** (Map<String, dynamic>)
  - Exports analytics data
- **_cleanupHistory** (void)
  - Cleans up old history based on retention policy
- **_updateHealthStatus** (void)
  - Updates health status when operations complete
- **if** (active)
- **setRetentionPolicy** (void)
  - Sets retention policy
- **dispose** (void)
  - Disposes the service

---

### SyncCompressionService

Service for handling compression and decompression of sync data  This service supports multiple compression algorithms and provides automatic compression strategy selection based on data characteristics and network conditions.

**Source:** `lib\src\services\usm_sync_compression_service.dart`

#### Methods

- **SyncCompressionService** (const)
  - Creates a new sync compression service
- **compress** (Future<CompressionResult>)
  - Compress data using the specified compression type  Returns a [CompressionResult] containing the compressed data, compression ratio, and metadata about the compression operation.  Example: ```dart final data = {'large': 'data' * 1000}; final result = await service.compress(data, CompressionType.gzip); print('Compression ratio: ${result.compressionRatio}'); ```
- **CompressionResult** (return)
- **_compressGzip** (await)
- **_compressBrotli** (await)
- **_compressLz4** (await)
- **CompressionResult** (return)
- **_decompressGzip** (await)
- **_decompressBrotli** (await)
- **_decompressLz4** (await)
- **size** (Data)
  - Automatically select the best compression type for the given data  Analyzes the data characteristics and selects the most appropriate compression algorithm based on size, content type, and performance requirements.  Factors considered: -
- **type** (Data)
  - Automatically select the best compression type for the given data  Analyzes the data characteristics and selects the most appropriate compression algorithm based on size, content type, and performance requirements.  Factors considered: - Data size (small data may not benefit from compression) -
- **requirements** (Speed)
  - Automatically select the best compression type for the given data  Analyzes the data characteristics and selects the most appropriate compression algorithm based on size, content type, and performance requirements.  Factors considered: - Data size (small data may not benefit from compression) - Data type (text vs binary-like data) -
- **conditions** (Network)
  - Automatically select the best compression type for the given data  Analyzes the data characteristics and selects the most appropriate compression algorithm based on size, content type, and performance requirements.  Factors considered: - Data size (small data may not benefit from compression) - Data type (text vs binary-like data) - Speed requirements (real-time vs batch operations) -
- **selectCompressionStrategy** (CompressionStrategy)
  - Automatically select the best compression type for the given data  Analyzes the data characteristics and selects the most appropriate compression algorithm based on size, content type, and performance requirements.  Factors considered: - Data size (small data may not benefit from compression) - Data type (text vs binary-like data) - Speed requirements (real-time vs batch operations) - Network conditions (slow networks benefit more from compression)
- **if** (it)
- **CompressionStrategy** (return)
- **if** (ratio)
- **CompressionStrategy** (return)
- **if** (operations)
- **CompressionStrategy** (return)
- **CompressionStrategy** (return)
- **CompressionStrategy** (return)
- **CompressionStrategy** (return)
- **benchmark** (Future<CompressionBenchmark>)
  - Benchmark different compression algorithms on sample data  Useful for performance testing and algorithm selection. Returns results for all supported compression types.
- **compress** (await)
- **CompressionBenchmark** (return)
- **_compressGzip** (Future<Uint8List>)
- **_decompressGzip** (Future<Uint8List>)
- **_compressBrotli** (Future<Uint8List>)
- **_compressGzip** (return)
- **_decompressBrotli** (Future<Uint8List>)
- **_decompressGzip** (return)
- **_compressLz4** (Future<Uint8List>)
- **_compressGzip** (return)
- **_decompressLz4** (Future<Uint8List>)
- **_decompressGzip** (return)
- **_getDefaultLevel** (int)
- **is** (data)
  - Analyze how compressible the
- **_analyzeCompressibility** (double)
  - Analyze how compressible the data is (0.0 = not compressible, 1.0 = highly compressible)
- **entropy** (Calculate)
- **scale** (1)
- **return** (data)

---

### CompressionResult

Result of a compression operation

**Source:** `lib\src\services\usm_sync_compression_service.dart`

#### Methods

- **CompressionResult** (const)
  - Creates a new compression result
- **ratio** (Compression)
- **toJson** (Map<String, dynamic>)
  - Convert to JSON for serialization
- **CompressionResult** (return)
- **toString** (String)

---

### CompressionStrategy

Strategy recommendation for compression

**Source:** `lib\src\services\usm_sync_compression_service.dart`

#### Methods

- **CompressionStrategy** (const)
  - Creates a new compression strategy
- **toString** (String)

---

### CompressionBenchmark

Benchmark results comparing compression algorithms

**Source:** `lib\src\services\usm_sync_compression_service.dart`

#### Methods

- **CompressionBenchmark** (const)
  - Creates a new compression benchmark
- **Duration** (const)
- **recommendation** (balanced)
  - Get a
- **speed** (and)
- **toString** (String)

---

### SyncBusEvent

**Source:** `lib\src\services\usm_sync_event_bus.dart`

#### Methods

- **SyncBusEvent** (const)

---

### SyncOperationStartedEvent

Sync operation started event

**Source:** `lib\src\services\usm_sync_event_bus.dart`

#### Methods

- **SyncOperationStartedEvent** (const)

---

### SyncOperationCompletedEvent

Sync operation completed event

**Source:** `lib\src\services\usm_sync_event_bus.dart`

#### Methods

- **SyncOperationCompletedEvent** (const)

---

### SyncConflictDetectedEvent

Sync conflict detected event

**Source:** `lib\src\services\usm_sync_event_bus.dart`

#### Methods

- **SyncConflictDetectedEvent** (const)

---

### SyncConflictResolvedEvent

Sync conflict resolved event

**Source:** `lib\src\services\usm_sync_event_bus.dart`

#### Methods

- **SyncConflictResolvedEvent** (const)

---

### NetworkStatusChangedEvent

Network status changed event

**Source:** `lib\src\services\usm_sync_event_bus.dart`

#### Methods

- **NetworkStatusChangedEvent** (const)

---

### SyncQueueStatusChangedEvent

Sync queue status changed event

**Source:** `lib\src\services\usm_sync_event_bus.dart`

#### Methods

- **SyncQueueStatusChangedEvent** (const)

---

### SyncTriggerFiredEvent

Sync trigger fired event

**Source:** `lib\src\services\usm_sync_event_bus.dart`

#### Methods

- **SyncTriggerFiredEvent** (const)

---

### BackendConnectionStatusChangedEvent

Backend connection status changed event

**Source:** `lib\src\services\usm_sync_event_bus.dart`

#### Methods

- **BackendConnectionStatusChangedEvent** (const)

---

### DataChangeDetectedEvent

Data change detected event

**Source:** `lib\src\services\usm_sync_event_bus.dart`

#### Methods

- **DataChangeDetectedEvent** (const)

---

### SyncErrorOccurredEvent

Sync error occurred event

**Source:** `lib\src\services\usm_sync_event_bus.dart`

#### Methods

- **SyncErrorOccurredEvent** (const)

---

### EventSubscription

Event subscription information

**Source:** `lib\src\services\usm_sync_event_bus.dart`

#### Methods

- **EventSubscription** (const)

---

### SyncEventBus

Central event bus for sync operations

**Source:** `lib\src\services\usm_sync_event_bus.dart`

#### Methods

- **publish** (void)
  - Publishes an event to all subscribers
- **_publishError** (handlers)
- **subscribers** (wildcard)
- **StateError** (throw)
- **subscribeToAll** (String)
  - Subscribes to all events
- **unsubscribe** (bool)
  - Unsubscribes from events
- **clearAllSubscriptions** (void)
  - Clears all subscriptions
- **getEventHistory** (List<SyncBusEvent>)
  - Gets event history
- **if** (type)
- **if** (priority)
- **if** (time)
- **if** (limit)
- **getActiveSubscriptions** (Map<Type, int>)
  - Gets all active subscriptions
- **clearEventHistory** (void)
  - Clears event history
- **publishSyncOperationStarted** (void)
  - Convenience methods for common events
- **publishSyncOperationCompleted** (void)
- **publishSyncConflictDetected** (void)
- **publishSyncConflictResolved** (void)
- **publishNetworkStatusChanged** (void)
- **publishSyncQueueStatusChanged** (void)
- **publishSyncTriggerFired** (void)
- **publishBackendConnectionStatusChanged** (void)
- **publishDataChangeDetected** (void)
- **publishSyncErrorOccurred** (void)
- **_shouldNotifySubscriber** (bool)
- **if** (filter)
- **_priorityValue** (int)
- **_publishError** (void)
- **_generateEventId** (String)
- **_generateSubscriptionId** (String)
- **dispose** (void)
  - Dispose method to clean up resources

---

### FailureClassification

Detailed failure classification

**Source:** `lib\src\services\usm_sync_failure_analytics.dart`

#### Methods

- **FailureClassification** (const)
- **toJson** (Map<String, dynamic>)

---

### FailurePrediction

Failure prediction model

**Source:** `lib\src\services\usm_sync_failure_analytics.dart`

#### Methods

- **FailurePrediction** (const)
- **toJson** (Map<String, dynamic>)

---

### FailureTrendAnalysis

Failure trend analysis

**Source:** `lib\src\services\usm_sync_failure_analytics.dart`

#### Methods

- **FailureTrendAnalysis** (const)
- **toJson** (Map<String, dynamic>)

---

### DataPoint

Data point for trend analysis

**Source:** `lib\src\services\usm_sync_failure_analytics.dart`

#### Methods

- **DataPoint** (const)
- **toJson** (Map<String, dynamic>)

---

### RootCauseAnalysis

Root cause analysis result

**Source:** `lib\src\services\usm_sync_failure_analytics.dart`

#### Methods

- **RootCauseAnalysis** (const)
- **toJson** (Map<String, dynamic>)

---

### SyncFailureAnalytics

Comprehensive sync failure analytics service

**Source:** `lib\src\services\usm_sync_failure_analytics.dart`

#### Methods

- **Duration** (const)
- **SyncFailureAnalytics** (seconds)
- **startAnalysis** (void)
  - Starts automatic failure analysis
- **_performAnalysis** (analysis)
- **stopAnalysis** (void)
  - Stops automatic analysis
- **classifyFailure** (FailureClassification)
  - Classifies a specific failure
- **if** (failures)
- **if** (failures)
- **if** (failures)
- **if** (failures)
- **if** (exhaustion)
- **_analyzeFailurePattern** (analysis)
- **analyzeFailureTrends** (FailureTrendAnalysis)
  - Analyzes failure trends over time
- **Duration** (const)
- **for** (bucket)
- **FailureTrendAnalysis** (return)
- **predictFailures** (FailurePrediction)
  - Predicts future failures based on current patterns
- **Duration** (const)
- **Duration** (const)
- **if** (probability)
- **if** (else)
- **performRootCauseAnalysis** (RootCauseAnalysis)
  - Performs root cause analysis for a failure pattern
- **if** (else)
- **if** (analysis)
- **if** (else)
- **getFailureStatistics** (Map<String, dynamic>)
  - Gets failure statistics by category
- **Duration** (const)
- **_initializeAnalysis** (void)
  - Initialize analysis components
- **_performAnalysis** (void)
  - Performs periodic analysis
- **predictFailures** (predictions)
- **analyzeFailureTrends** (trends)
- **_isAuthFailure** (bool)
  - Checks if failure is authentication related
- **_isTimeoutFailure** (bool)
  - Checks if failure is timeout related
- **_isNetworkFailure** (bool)
  - Checks if failure is network related
- **_isDataCorruptionFailure** (bool)
  - Checks if failure is data corruption related
- **_isResourceExhaustionFailure** (bool)
  - Checks if failure is resource exhaustion related
- **_analyzeFailurePattern** (void)
  - Analyzes failure patterns
- **_calculateTrendDirection** (TrendDirection)
  - Calculates trend direction from data points
- **if** (else)
- **if** (else)
- **_calculateTrendMagnitude** (double)
  - Calculates trend magnitude
- **_calculateVariance** (double)
  - Calculates variance of values
- **_assessNetworkRisk** (double)
  - Assesses network risk
- **_assessResourceRisk** (double)
  - Assesses resource risk
- **_findCommonErrorPatterns** (List<String>)
  - Finds common patterns in error messages
- **dispose** (void)
  - Disposes the analytics service

---

### DashboardWidgetConfig

Dashboard widget configuration

**Source:** `lib\src\services\usm_sync_health_dashboard.dart`

#### Methods

- **DashboardWidgetConfig** (const)
- **toJson** (Map<String, dynamic>)

---

### DashboardLayout

Dashboard layout configuration

**Source:** `lib\src\services\usm_sync_health_dashboard.dart`

#### Methods

- **DashboardLayout** (const)
- **toJson** (Map<String, dynamic>)

---

### DashboardData

Real-time dashboard data

**Source:** `lib\src\services\usm_sync_health_dashboard.dart`

#### Methods

- **DashboardData** (const)
- **toJson** (Map<String, dynamic>)

---

### SyncHealthDashboard

Comprehensive sync health dashboard

**Source:** `lib\src\services\usm_sync_health_dashboard.dart`

#### Methods

- **setLayout** (void)
  - Sets dashboard layout and starts data collection
- **addWidget** (void)
  - Adds a widget to current layout
- **removeWidget** (void)
  - Removes a widget from current layout
- **updateWidget** (void)
  - Updates a widget configuration
- **getAllWidgetData** (Map<String, DashboardData>)
  - Gets current data for all widgets
- **refreshWidget** (Future<void>)
  - Manually refreshes a widget
- **_updateWidgetData** (await)
- **refreshAllWidgets** (Future<void>)
  - Refreshes all widgets
- **_updateWidgetData** (await)
- **exportDashboard** (Map<String, dynamic>)
  - Exports dashboard configuration
- **importDashboard** (void)
  - Imports dashboard configuration
- **_initializeDefaultLayout** (layout)
- **createOverviewLayout** (DashboardLayout)
- **createPerformanceLayout** (DashboardLayout)
- **createFailureAnalysisLayout** (DashboardLayout)
- **_initializeDefaultLayout** (void)
  - Initialize default dashboard layout
- **_startAllWidgets** (void)
  - Starts data collection for all widgets
- **_stopAllWidgets** (void)
  - Stops data collection for all widgets
- **_startWidget** (void)
  - Starts data collection for a specific widget
- **_updateWidgetData** (collection)
- **_stopWidget** (void)
  - Stops data collection for a specific widget
- **_updateWidgetData** (Future<void>)
  - Updates data for a specific widget
- **_collectWidgetData** (await)
- **_collectHealthOverviewData** (return)
- **_collectPerformanceMetricsData** (return)
- **_collectFailureAnalysisData** (return)
- **_collectSyncStatusData** (return)
- **_collectNetworkStatusData** (return)
- **_collectTrendChartData** (return)
- **_collectAlertListData** (return)
- **_collectTopFailuresData** (return)
- **_collectResourceUsageData** (return)
- **_collectOperationHistoryData** (return)
- **_collectHealthOverviewData** (Map<String, dynamic>)
  - Collects health overview data
- **Duration** (const)
- **_collectPerformanceMetricsData** (Map<String, dynamic>)
  - Collects performance metrics data
- **_collectFailureAnalysisData** (Map<String, dynamic>)
  - Collects failure analysis data
- **_collectSyncStatusData** (Map<String, dynamic>)
  - Collects sync status data
- **_collectNetworkStatusData** (Map<String, dynamic>)
  - Collects network status data
- **_collectTrendChartData** (Map<String, dynamic>)
  - Collects trend chart data
- **_collectAlertListData** (Map<String, dynamic>)
  - Collects alert list data
- **_collectTopFailuresData** (Map<String, dynamic>)
  - Collects top failures data
- **_collectResourceUsageData** (Map<String, dynamic>)
  - Collects resource usage data
- **_collectOperationHistoryData** (Map<String, dynamic>)
  - Collects operation history data
- **_parsePeriod** (Duration)
  - Parses period string into Duration
- **Duration** (const)
- **Duration** (const)
- **Duration** (const)
- **Duration** (const)
- **Duration** (const)
- **Duration** (const)
- **_parseWidgetConfig** (DashboardWidgetConfig)
  - Parses widget configuration from JSON
- **DashboardWidgetConfig** (return)
- **dispose** (void)
  - Disposes the dashboard

---

### SyncLogEntry

Comprehensive sync log entry

**Source:** `lib\src\services\usm_sync_logging_service.dart`

#### Methods

- **SyncLogEntry** (const)
- **toJson** (Map<String, dynamic>)
- **SyncLogEntry** (return)
- **toFormattedString** (String)
  - Creates a formatted string representation

---

### LogFilter

Log filter configuration

**Source:** `lib\src\services\usm_sync_logging_service.dart`

#### Methods

- **LogFilter** (const)
- **matches** (bool)
  - Checks if a log entry matches this filter

---

### LogStorageConfig

Log storage configuration

**Source:** `lib\src\services\usm_sync_logging_service.dart`

#### Methods

- **LogStorageConfig** (const)

---

### SyncLoggingService

Comprehensive sync logging service

**Source:** `lib\src\services\usm_sync_logging_service.dart`

#### Methods

- **setMinimumLogLevel** (void)
  - Sets minimum log level
- **setCategoryEnabled** (void)
  - Enables or disables specific log categories
- **debug** (void)
  - Logs a debug message
- **info** (void)
  - Logs an info message
- **warning** (void)
  - Logs a warning message
- **error** (void)
  - Logs an error message
- **critical** (void)
  - Logs a critical message
- **logOperationStart** (void)
  - Logs sync operation start
- **logOperationComplete** (void)
  - Logs sync operation completion
- **logConflictDetected** (void)
  - Logs conflict detection
- **logConflictResolved** (void)
  - Logs conflict resolution
- **logNetworkEvent** (void)
  - Logs network events
- **logPerformanceMetric** (void)
  - Logs performance metrics
- **logRecoveryOperation** (void)
  - Logs recovery operations
- **getLogs** (List<SyncLogEntry>)
  - Gets filtered log entries
- **descending** (timestamp)
- **getOperationLogs** (List<SyncLogEntry>)
  - Gets logs for a specific operation
- **getLogs** (return)
- **getRecentErrors** (List<SyncLogEntry>)
  - Gets recent error logs
- **getLogs** (return)
- **getLogsByTimeRange** (List<SyncLogEntry>)
  - Gets logs for a specific time range
- **getLogs** (return)
- **exportLogs** (Map<String, dynamic>)
  - Exports logs to JSON format
- **exportLogsAsText** (String)
  - Exports logs to formatted text
- **clearLogs** (void)
  - Clears in-memory logs
- **getLogStatistics** (Map<String, dynamic>)
  - Gets log statistics
- **_log** (void)
  - Core logging method
- **if** (category)
- **if** (buffer)
- **while** (size)
- **if** (console)
- **if** (file)
- **_initializeLogging** (void)
  - Initializes logging system
- **_cleanupOldLogFiles** (files)
- **_initializeLogFile** (file)
- **_initializeLogFile** (void)
  - Initializes current log file
- **_writeToFile** (void)
  - Writes log entry to file
- **if** (file)
- **print** (console)
- **_rotateLogFile** (void)
  - Rotates log file when size limit is reached
- **_cleanupOldLogFiles** (void)
  - Cleans up old log files
- **time** (modification)
- **dispose** (void)
  - Disposes the logging service

---

### NetworkPerformanceMetrics

Network performance metrics

**Source:** `lib\src\services\usm_sync_performance_monitor.dart`

#### Methods

- **NetworkPerformanceMetrics** (const)
- **toJson** (Map<String, dynamic>)

---

### BackendPerformanceMetrics

Backend performance metrics

**Source:** `lib\src\services\usm_sync_performance_monitor.dart`

#### Methods

- **BackendPerformanceMetrics** (const)
- **toJson** (Map<String, dynamic>)

---

### MemoryUsageMetrics

Memory usage metrics for sync operations

**Source:** `lib\src\services\usm_sync_performance_monitor.dart`

#### Methods

- **MemoryUsageMetrics** (const)
- **toJson** (Map<String, dynamic>)

---

### SyncPerformanceMonitor

Comprehensive sync performance monitoring

**Source:** `lib\src\services\usm_sync_performance_monitor.dart`

#### Methods

- **Duration** (const)
- **Duration** (const)
- **SyncPerformanceMonitor** (seconds)
- **startMonitoring** (void)
  - Starts continuous performance monitoring
- **_collectMetrics** (metrics)
- **stopMonitoring** (void)
  - Stops performance monitoring
- **recordNetworkTest** (void)
  - Records network performance test result
- **recordBackendTest** (void)
  - Records backend performance test result
- **recordMemoryUsage** (void)
  - Records memory usage metrics
- **testNetworkPerformance** (Future<NetworkPerformanceMetrics>)
  - Performs network latency test
- **test** (network)
- **testBackendPerformance** (Future<BackendPerformanceMetrics>)
  - Performs backend health check
- **getPerformanceSummary** (PerformanceSummary)
  - Gets performance summary for a time period
- **Duration** (const)
- **PerformanceSummary** (return)
- **updateThresholds** (void)
  - Updates performance thresholds
- **_collectMetrics** (void)
  - Collects current system metrics
- **_collectNetworkMetrics** (metrics)
- **_collectNetworkMetrics** (void)
  - Collects network metrics
- **recordNetworkTest** (collection)
- **_collectMemoryMetrics** (void)
  - Collects memory metrics
- **_checkNetworkThresholds** (void)
  - Checks network performance thresholds
- **if** (else)
- **_checkBackendThresholds** (void)
  - Checks backend performance thresholds
- **if** (else)
- **_checkMemoryThresholds** (void)
  - Checks memory usage thresholds
- **_summarizeNetworkMetrics** (Map<String, dynamic>)
  - Summarizes network metrics
- **_summarizeBackendMetrics** (Map<String, dynamic>)
  - Summarizes backend metrics
- **_summarizeMemoryMetrics** (Map<String, dynamic>)
  - Summarizes memory metrics
- **_cleanupNetworkHistory** (void)
  - Cleanup old metrics
- **_cleanupBackendHistory** (void)
- **_cleanupMemoryHistory** (void)
- **dispose** (void)
  - Disposes the monitor

---

### PerformanceSummary

Performance summary for a specific time period

**Source:** `lib\src\services\usm_sync_performance_monitor.dart`

#### Methods

- **PerformanceSummary** (const)
- **toJson** (Map<String, dynamic>)

---

### PerformanceAlert

Performance alert

**Source:** `lib\src\services\usm_sync_performance_monitor.dart`

#### Methods

- **PerformanceAlert** (const)
- **toJson** (Map<String, dynamic>)

---

### SyncPriorityQueueService

Service for managing priority-based sync queues  This service provides: - Priority-based queue management for sync operations - Resource allocation optimization based on priorities - Dead letter queue handling for failed operations - Queue analytics and monitoring - Dynamic priority adjustment based on conditions

**Source:** `lib\src\services\usm_sync_priority_queue_service.dart`

#### Methods

- **SyncPriorityQueueService** (service)
  - Creates a new sync priority queue
- **enqueue** (Future<void>)
  - Enqueue a sync operation with specified priority  Adds a sync operation to the appropriate priority queue. Higher priority items are processed first, with intelligent resource allocation to prevent priority inversion.  Example: ```dart final item = SyncQueueItem.create( entityName: 'user_profiles', operation: SyncOperationType.update, data: updatedUserData, priority: SyncPriority.high, );  await queueService.enqueue(item); ```
- **if** (item)
- **ArgumentError** (throw)
- **if** (capacity)
- **_makeRoom** (await)
- **QueueCapacityException** (throw)
- **_emitEvent** (event)
- **_tryProcessNext** (available)
- **enqueueBatch** (Future<void>)
  - Enqueue multiple items in a batch  Efficiently adds multiple sync operations to their respective priority queues with batch optimization.
- **enqueue** (await)
- **dequeue** (Future<SyncQueueItem?>)
  - Dequeue and process the next highest priority item  Removes and returns the next item to be processed based on priority and queue management strategy.
- **for** (order)
- **completeItem** (Future<void>)
  - Complete processing of an item  Marks an item as completed and updates queue state. Successful items are removed from tracking, failed items may be retried or moved to dead letter queue.
- **_handleFailedItem** (await)
- **_tryProcessNext** (item)
- **failItem** (Future<void>)
  - Fail an item and handle retry or dead letter queue logic  Handles items that failed processing, implementing retry logic or moving to dead letter queue based on configuration.
- **_handleFailedItem** (await)
- **_tryProcessNext** (item)
- **getQueueStatus** (QueueStatus)
  - Get current queue status for all priorities  Returns detailed status information about all priority queues including counts, processing status, and performance metrics.
- **QueueStatus** (return)
- **clearQueues** (void)
  - Clear all queues  Removes all pending items from all priority queues. Processing items are allowed to complete.
- **pauseProcessing** (void)
  - Pause queue processing  Stops automatic processing of queue items. Currently processing items will complete.
- **resumeProcessing** (void)
  - Resume queue processing  Restarts automatic processing of queue items.
- **getDeadLetterItems** (List<SyncQueueItem>)
  - Get items from dead letter queue  Returns items that failed processing and were moved to the dead letter queue for manual review or reprocessing.
- **requeueDeadLetterItems** (Future<void>)
  - Requeue items from dead letter queue  Moves items from dead letter queue back to appropriate priority queues for retry processing.
- **for** (requeue)
- **for** (count)
- **enqueue** (await)
- **dispose** (void)
  - Dispose the service and clean up resources
- **for** (queues)
- **_initializeSemaphores** (void)
- **_getMaxConcurrencyForPriority** (int)
- **_startProcessing** (void)
- **_tryProcessNext** (void)
- **if** (occur)
- **_validateQueueItem** (bool)
- **if** (validation)
- **_hasCapacity** (bool)
- **_getMaxQueueSizeForPriority** (int)
- **_makeRoom** (Future<void>)
- **for** (immediately)
- **dequeue** (await)
- **if** (items)
- **completeItem** (await)
- **_adjustPriorityDynamically** (SyncPriority)
- **if** (items)
- **if** (overloaded)
- **_handleFailedItem** (Future<void>)
- **Timer** (retry)
- **enqueue** (await)
- **_calculateRetryDelay** (Duration)
- **jitter** (Add)
- **Duration** (return)
- **_calculateAverageWaitTimes** (Map<SyncPriority, Duration>)
- **_calculateThroughputRates** (Map<SyncPriority, double>)
- **_emitEvent** (void)

---

### PriorityQueueConfig

Configuration for priority queue service

**Source:** `lib\src\services\usm_sync_priority_queue_service.dart`

#### Methods

- **PriorityQueueConfig** (const)
  - Creates a new priority queue configuration
- **Duration** (const)
- **Duration** (const)
- **Duration** (const)
- **PriorityQueueConfig** (const)
- **PriorityQueueConfig** (const)
- **PriorityQueueConfig** (const)

---

### SyncQueueItem

Item in the sync priority queue

**Source:** `lib\src\services\usm_sync_priority_queue_service.dart`

#### Methods

- **failure** (last)
  - Reason for
- **SyncQueueItem** (const)
  - Creates a new sync queue item
- **SyncQueueItem** (return)
- **SyncQueueItem** (return)
- **SyncQueueItem** (return)
- **copyWith** (SyncQueueItem)
  - Create a copy with modified properties
- **SyncQueueItem** (return)
- **toString** (String)

---

### QueueEvent

Event emitted by the priority queue service

**Source:** `lib\src\services\usm_sync_priority_queue_service.dart`

#### Methods

- **item** (queue)
  - Associated
- **QueueEvent** (const)
  - Creates a new queue event
- **toString** (String)

---

### QueueStatus

Current status of the priority queues

**Source:** `lib\src\services\usm_sync_priority_queue_service.dart`

#### Methods

- **priority** (by)
  - Throughput rates
- **QueueStatus** (const)
  - Creates a new queue status
- **toString** (String)

---

### QueueStatistics

Statistics for queue operations

**Source:** `lib\src\services\usm_sync_priority_queue_service.dart`

#### Methods

- **reset** (void)
  - Reset all statistics
- **toString** (String)

---

### Semaphore

Simple semaphore implementation for concurrency control

**Source:** `lib\src\services\usm_sync_priority_queue_service.dart`

#### Methods

- **Semaphore** (permits)
  - Creates a new semaphore with the specified number of
- **permit** (a)
  - Acquire
- **acquire** (Future<void>)
  - Acquire a permit (wait if none available)
- **release** (void)
  - Release a permit
- **if** (else)

---

### QueueCapacityException

Exception thrown when queue capacity is exceeded

**Source:** `lib\src\services\usm_sync_priority_queue_service.dart`

#### Methods

- **QueueCapacityException** (const)
  - Creates a new queue capacity exception
- **toString** (String)

---

### SyncOperation

Represents a pending sync operation in the queue

**Source:** `lib\src\services\usm_sync_queue.dart`

#### Methods

- **SyncOperation** (const)
- **copyWith** (SyncOperation)
- **SyncOperation** (return)
- **toString** (String)

---

### SyncQueue

Manages a queue of pending sync operations with priority-based processing

**Source:** `lib\src\services\usm_sync_queue.dart`

#### Methods

- **enqueue** (void)
  - Adds an operation to the queue based on its priority
- **if** (exists)
- **process** (to)
  - Removes and returns the next operation
- **if** (else)
- **if** (else)
- **if** (else)
- **if** (else)
- **if** (else)
- **if** (else)
- **removeOperation** (bool)
  - Removes an operation by ID from the queue
- **_removeOperationById** (return)
- **_removeOperationById** (bool)
- **_removeFromQueue** (bool)
- **for** (removed)
- **queue** (the)
  - Returns all operations in
- **getAllOperations** (List<SyncOperation>)
  - Returns all operations in the queue (prioritized order)
- **getOperationsForCollection** (List<SyncOperation>)
  - Returns operations for a specific collection
- **getOperationsByPriority** (List<SyncOperation>)
  - Returns operations by priority
- **clear** (void)
  - Clears all operations from the queue
- **clearCollection** (void)
  - Clears operations for a specific collection
- **dispose** (void)
  - Dispose method to clean up resources

---

### RecoveryOperationResult

Recovery operation result

**Source:** `lib\src\services\usm_sync_recovery_service.dart`

#### Methods

- **RecoveryOperationResult** (const)
- **toJson** (Map<String, dynamic>)

---

### RecoveryStrategy

Recovery strategy configuration

**Source:** `lib\src\services\usm_sync_recovery_service.dart`

#### Methods

- **RecoveryStrategy** (const)

---

### SyncIntegrityIssue

Sync integrity issue

**Source:** `lib\src\services\usm_sync_recovery_service.dart`

#### Methods

- **SyncIntegrityIssue** (const)
- **toJson** (Map<String, dynamic>)

---

### SyncBackupMetadata

Backup metadata

**Source:** `lib\src\services\usm_sync_recovery_service.dart`

#### Methods

- **SyncBackupMetadata** (const)
- **toJson** (Map<String, dynamic>)
- **SyncBackupMetadata** (return)

---

### SyncRecoveryService

Comprehensive sync recovery service

**Source:** `lib\src\services\usm_sync_recovery_service.dart`

#### Methods

- **_checkOrphanedRecords** (await)
- **_checkInconsistentSyncStates** (await)
- **_checkCorruptedData** (await)
- **_checkDuplicateRecords** (await)
- **_checkVersionMismatches** (await)
- **if** (checks)
- **_checkSystemIntegrity** (await)
- **createBackup** (Future<SyncBackupMetadata>)
  - Creates a backup of sync data
- **_getAllCollections** (await)
- **_getCollectionItemCount** (await)
- **_getCollectionData** (await)
- **_getSystemData** (await)
- **_storeBackup** (await)
- **_getSystemInfo** (await)
- **_storeBackupMetadata** (await)
- **_getBackupMetadataList** (await)
- **restoreFromBackup** (Future<RecoveryOperationResult>)
  - Restores from backup
- **_getBackupMetadata** (await)
- **RecoveryOperationResult** (return)
- **if** (requested)
- **createBackup** (await)
- **_loadBackup** (await)
- **if** (requested)
- **RecoveryOperationResult** (return)
- **for** (collection)
- **_restoreCollectionData** (await)
- **if** (present)
- **_restoreSystemData** (await)
- **resetSyncState** (Future<RecoveryOperationResult>)
  - Resets sync state for entities
- **_getAllCollections** (await)
- **_resetCollectionSyncState** (await)
- **resolveDuplicates** (Future<RecoveryOperationResult>)
  - Resolves duplicate records
- **_getAllCollections** (await)
- **_findDuplicates** (await)
- **_resolveDuplicatesInCollection** (await)
- **repairCorruptedData** (Future<RecoveryOperationResult>)
  - Repairs corrupted data
- **_getAllCollections** (await)
- **_repairCollectionData** (await)
- **forceCompleteResync** (Future<RecoveryOperationResult>)
  - Forces a complete resync
- **_getAllCollections** (await)
- **resetSyncState** (await)
- **if** (requested)
- **_clearCollectionData** (await)
- **_triggerFullSync** (await)
- **validateSyncIntegrity** (await)
- **createBackup** (await)
- **if** (data)
- **repairCorruptedData** (await)
- **if** (duplicates)
- **resolveDuplicates** (await)
- **if** (states)
- **resetSyncState** (await)
- **records** (orphaned)
- **_getCollectionItemCount** (Future<int>)
- **_calculateChecksum** (String)
- **_storeBackup** (Future<void>)
- **_storeBackupMetadata** (Future<void>)
- **_getBackupMetadata** (Future<SyncBackupMetadata?>)
- **_restoreCollectionData** (Future<int>)
- **_restoreSystemData** (Future<void>)
- **_resetCollectionSyncState** (Future<int>)
- **_resolveDuplicatesInCollection** (Future<int>)
- **_clearCollectionData** (Future<void>)
- **_triggerFullSync** (Future<int>)
- **dispose** (void)
  - Disposes the recovery service

---

### ReplayEvent

Replay event representing a sync operation that can be replayed

**Source:** `lib\src\services\usm_sync_replay_service.dart`

#### Methods

- **ReplayEvent** (const)
- **toJson** (Map<String, dynamic>)
- **ReplayEvent** (return)
- **copyWith** (ReplayEvent)
  - Creates a copy of this event with modifications
- **ReplayEvent** (return)

---

### ReplaySessionConfig

Replay session configuration

**Source:** `lib\src\services\usm_sync_replay_service.dart`

#### Methods

- **ReplaySessionConfig** (const)
- **toJson** (Map<String, dynamic>)

---

### ReplayExecutionResult

Replay execution result

**Source:** `lib\src\services\usm_sync_replay_service.dart`

#### Methods

- **ReplayExecutionResult** (const)
- **toJson** (Map<String, dynamic>)

---

### ReplaySessionSummary

Replay session summary

**Source:** `lib\src\services\usm_sync_replay_service.dart`

#### Methods

- **ReplaySessionSummary** (const)
- **toJson** (Map<String, dynamic>)

---

### ReplayEventFilter

Event filter for replay queries

**Source:** `lib\src\services\usm_sync_replay_service.dart`

#### Methods

- **ReplayEventFilter** (const)
- **matches** (bool)
  - Checks if an event matches this filter

---

### SyncReplayService

Comprehensive sync replay service

**Source:** `lib\src\services\usm_sync_replay_service.dart`

#### Methods

- **startRecording** (void)
  - Starts recording sync events
- **stopRecording** (void)
  - Stops recording sync events
- **recordEvent** (void)
  - Records a sync event
- **recordSyncOperation** (void)
  - Records a sync operation for replay
- **getEvents** (List<ReplayEvent>)
  - Gets replay events with optional filtering
- **if** (pagination)
- **getOperationEvents** (List<ReplayEvent>)
  - Gets events for a specific operation ID
- **getEvents** (return)
- **getEventsByTimeRange** (List<ReplayEvent>)
  - Gets events for a specific time range
- **getEvents** (return)
- **getFailedEvents** (List<ReplayEvent>)
  - Gets failed events only
- **getEvents** (return)
- **getSuccessfulEvents** (List<ReplayEvent>)
  - Gets successful events only
- **getEvents** (return)
- **replayEvent** (Future<ReplayExecutionResult>)
  - Replays a single event
- **_executeReplayEvent** (await)
- **_compareEventResults** (await)
- **replayEvents** (Future<ReplaySessionSummary>)
  - Replays multiple events in sequence
- **if** (provided)
- **if** (control)
- **replayEvent** (await)
- **replayTimeRange** (Future<ReplaySessionSummary>)
  - Replays events from a specific time range
- **replayEvents** (return)
- **replayFailedEvents** (Future<ReplaySessionSummary>)
  - Replays failed events only
- **replayEvents** (return)
- **replayOperation** (Future<ReplaySessionSummary>)
  - Replays events for a specific operation
- **replayEvents** (return)
- **exportEvents** (Map<String, dynamic>)
  - Exports replay events to JSON
- **importEvents** (void)
  - Imports replay events from JSON
- **getReplayStatistics** (Map<String, dynamic>)
  - Gets replay statistics
- **clearHistory** (void)
  - Clears replay history
- **_shouldReplayEvent** (bool)
- **if** (result)
- **Duration** (const)
- **dispose** (void)
  - Disposes the replay service

---

### RollbackCheckpoint

Rollback checkpoint representing a state that can be restored

**Source:** `lib\src\services\usm_sync_rollback_service.dart`

#### Methods

- **RollbackCheckpoint** (const)
- **toJson** (Map<String, dynamic>)
- **RollbackCheckpoint** (return)

---

### RollbackOperationResult

Rollback operation result

**Source:** `lib\src\services\usm_sync_rollback_service.dart`

#### Methods

- **RollbackOperationResult** (const)
- **toJson** (Map<String, dynamic>)

---

### RollbackPlan

Rollback plan describing what will be rolled back

**Source:** `lib\src\services\usm_sync_rollback_service.dart`

#### Methods

- **RollbackPlan** (const)
- **toJson** (Map<String, dynamic>)

---

### RollbackStep

Individual step in a rollback plan

**Source:** `lib\src\services\usm_sync_rollback_service.dart`

#### Methods

- **RollbackStep** (const)
- **toJson** (Map<String, dynamic>)

---

### RollbackConflict

Rollback conflict when multiple rollbacks overlap

**Source:** `lib\src\services\usm_sync_rollback_service.dart`

#### Methods

- **RollbackConflict** (const)
- **toJson** (Map<String, dynamic>)

---

### RollbackServiceConfig

Rollback service configuration

**Source:** `lib\src\services\usm_sync_rollback_service.dart`

#### Methods

- **RollbackServiceConfig** (const)
- **Duration** (const)

---

### SyncRollbackService

Comprehensive sync rollback service

**Source:** `lib\src\services\usm_sync_rollback_service.dart`

#### Methods

- **createCheckpoint** (Future<RollbackCheckpoint>)
  - Creates a new rollback checkpoint
- **_captureSystemState** (await)
- **_captureEntityStates** (await)
- **_getAllCollections** (await)
- **_cleanupOldCheckpoints** (await)
- **listCheckpoints** (List<RollbackCheckpoint>)
  - Lists available checkpoints
- **descending** (timestamp)
- **createRollbackPlan** (Future<RollbackPlan>)
  - Creates a rollback plan
- **Exception** (throw)
- **if** (else)
- **Exception** (throw)
- **Exception** (throw)
- **_generateRollbackSteps** (await)
- **if** (issues)
- **RollbackPlan** (return)
- **executeRollback** (Future<RollbackOperationResult>)
  - Executes a rollback plan
- **if** (requested)
- **createCheckpoint** (await)
- **_captureSystemState** (await)
- **for** (execution)
- **Duration** (const)
- **for** (rollback)
- **_executeRollbackStep** (await)
- **_captureSystemState** (await)
- **rollbackToCheckpoint** (Future<RollbackOperationResult>)
  - Rolls back to a specific checkpoint
- **createRollbackPlan** (await)
- **executeRollback** (return)
- **rollbackTimeRange** (Future<RollbackOperationResult>)
  - Rolls back changes within a time range
- **Exception** (throw)
- **createRollbackPlan** (await)
- **executeRollback** (return)
- **undoLastSync** (Future<RollbackOperationResult>)
  - Undoes the last sync operation
- **Exception** (throw)
- **rollbackToCheckpoint** (return)
- **undoEntityChanges** (Future<RollbackOperationResult>)
  - Undoes changes to specific entities
- **createRollbackPlan** (await)
- **Duration** (const)
- **executeRollback** (return)
- **detectRollbackConflicts** (List<RollbackConflict>)
  - Detects conflicts between multiple rollback operations
- **deleteCheckpoint** (Future<bool>)
  - Deletes a specific checkpoint
- **getRollbackStatistics** (Map<String, dynamic>)
  - Gets rollback service statistics
- **Duration** (const)
- **_initializeService** (void)
- **_getAllCollections** (await)
- **_getCollectionEntities** (await)
- **_executeRollbackStep** (Future<int>)
- **Duration** (const)
- **_cleanupOldCheckpoints** (Future<void>)
- **dispose** (void)
  - Disposes the rollback service

---

### SyncScheduleConfig

Sync schedule configuration

**Source:** `lib\src\services\usm_sync_scheduler.dart`

#### Methods

- **SyncScheduleConfig** (const)
- **Duration** (const)
- **Duration** (const)
- **Duration** (const)
- **Duration** (const)
- **copyWith** (SyncScheduleConfig)
- **SyncScheduleConfig** (return)

---

### TimeOfDay

Time of day for scheduled syncs

**Source:** `lib\src\services\usm_sync_scheduler.dart`

#### Methods

- **TimeOfDay** (const)
- **TimeOfDay** (return)
- **toDateTime** (DateTime)
  - Converts to DateTime for today
- **DateTime** (return)
- **toString** (String)

---

### SyncTrigger

Sync trigger information

**Source:** `lib\src\services\usm_sync_scheduler.dart`

#### Methods

- **SyncTrigger** (const)
- **toString** (String)

---

### SyncScheduler

Manages sync scheduling with various strategies

**Source:** `lib\src\services\usm_sync_scheduler.dart`

#### Methods

- **SyncScheduleConfig** (const)
- **updateConfig** (void)
  - Updates the scheduler configuration
- **start** (void)
  - Starts the scheduler
- **pause** (void)
  - Pauses the scheduler
- **resume** (void)
  - Resumes the scheduler
- **stop** (void)
  - Stops the scheduler
- **triggerManualSync** (void)
  - Schedules a manual sync
- **scheduleSync** (void)
  - Schedules a sync with specific delay
- **scheduleRetry** (void)
  - Schedules a retry after sync failure
- **sync** (successful)
  - Notifies about
- **notifySyncSuccess** (void)
  - Notifies about successful sync (resets retry counter)
- **updateNetworkCondition** (void)
  - Updates network condition
- **if** (sync)
- **updateBatteryCondition** (void)
  - Updates battery condition
- **notifyDataChange** (void)
  - Notifies about data changes
- **if** (else)
- **_getNextScheduledTime** (return)
- **_getIntelligentSyncTime** (return)
- **_reschedule** (void)
- **_scheduleIntervalSync** (void)
- **for** (intervals)
- **_scheduleTimedSyncs** (void)
- **_scheduleNextOccurrence** (void)
- **if** (tomorrow)
- **Duration** (const)
- **_scheduleNextOccurrence** (occurrence)
- **_scheduleIntelligentSyncs** (void)
- **Duration** (const)
- **_scheduleIntelligentSync** (void)
- **_calculateIntelligentDelay** (Duration)
- **if** (syncs)
- **if** (bounds)
- **Duration** (const)
- **if** (else)
- **Duration** (const)
- **_shouldSyncNow** (bool)
- **if** (condition)
- **if** (condition)
- **_shouldScheduleIntelligentSync** (bool)
- **Duration** (const)
- **_rescheduleIfNeeded** (void)
- **_triggerSync** (void)
- **_recordSyncHistory** (void)
- **if** (issues)
- **_cancelAllTimers** (void)
- **_generateTriggerId** (String)
- **dispose** (void)
  - Dispose method to clean up resources

---

### SyncEntityState

Sync entity state information

**Source:** `lib\src\services\usm_sync_state_inspector.dart`

#### Methods

- **SyncEntityState** (const)
- **toJson** (Map<String, dynamic>)

---

### SyncItemState

Individual item sync state

**Source:** `lib\src\services\usm_sync_state_inspector.dart`

#### Methods

- **SyncItemState** (const)
- **toJson** (Map<String, dynamic>)

---

### SyncConflictInfo

Sync conflict information

**Source:** `lib\src\services\usm_sync_state_inspector.dart`

#### Methods

- **SyncConflictInfo** (const)
- **toJson** (Map<String, dynamic>)
- **SyncConflictInfo** (return)

---

### SyncOperationState

Sync operation state

**Source:** `lib\src\services\usm_sync_state_inspector.dart`

#### Methods

- **SyncOperationState** (const)
- **toJson** (Map<String, dynamic>)

---

### SyncSystemState

Overall sync system state

**Source:** `lib\src\services\usm_sync_state_inspector.dart`

#### Methods

- **SyncSystemState** (const)
- **toJson** (Map<String, dynamic>)

---

### SyncStateInspector

Sync state inspection service

**Source:** `lib\src\services\usm_sync_state_inspector.dart`

#### Methods

- **getCurrentSystemState** (Future<SyncSystemState>)
  - Gets current system state
- **SyncSystemState** (return)
- **Duration** (const)
- **_getEntityStates** (await)
- **_getRecentOperations** (await)
- **_getSystemMetrics** (await)
- **getEntityState** (Future<SyncEntityState>)
  - Gets state for a specific entity type
- **SyncEntityState** (return)
- **Duration** (const)
- **Duration** (const)
- **Duration** (const)
- **Duration** (const)
- **Duration** (const)
- **getItemStates** (await)
- **dirty** (Gets)
- **getItemStates** (await)
- **_getEntityStates** (await)
- **getDirtyItems** (await)
- **getItemStates** (await)
- **_getEntityStates** (await)
- **getErrorItems** (await)
- **getItemStates** (await)
- **_getEntityStates** (await)
- **getConflictItems** (await)
- **_getRecentOperations** (return)
- **_getRecentOperations** (await)
- **getCompletedOperations** (await)
- **getCurrentSystemState** (await)
- **if** (connectivity)
- **if** (else)
- **if** (operations)
- **getFailedOperations** (await)
- **getConflictItems** (await)
- **getCurrentSystemState** (await)
- **getItemStates** (await)
- **diagnoseSyncIssues** (await)
- **startStateMonitoring** (void)
  - Monitors state changes
- **getCurrentSystemState** (await)
- **print** (monitoring)
- **Duration** (const)
- **Duration** (const)
- **Duration** (const)
- **Duration** (const)
- **Duration** (const)
- **Duration** (const)
- **_generateRecommendations** (List<String>)
- **dispose** (void)
  - Disposes the inspector

---

### SyncOperationConfig

Configuration for sync operations

**Source:** `lib\src\services\usm_universal_sync_operation_service.dart`

#### Methods

- **SyncOperationConfig** (const)
- **Duration** (const)
- **copyWith** (SyncOperationConfig)
- **SyncOperationConfig** (return)

---

### SyncProgress

Progress information for sync operations

**Source:** `lib\src\services\usm_universal_sync_operation_service.dart`

#### Methods

- **SyncProgress** (const)
- **copyWith** (SyncProgress)
- **SyncProgress** (return)
- **toString** (String)

---

### SyncEntityConfig

Entity configuration for sync operations

**Source:** `lib\src\services\usm_universal_sync_operation_service.dart`

#### Methods

- **SyncEntityConfig** (const)
- **copyWith** (SyncEntityConfig)
- **SyncEntityConfig** (return)

---

### UniversalSyncOperationService

Core sync orchestrator that coordinates all sync operations

**Source:** `lib\src\services\usm_universal_sync_operation_service.dart`

#### Methods

- **SyncOperationConfig** (const)
- **_initialize** (void)
- **_startProcessing** (processing)
- **updateConfig** (void)
  - Updates the operation configuration
- **registerEntity** (void)
  - Registers an entity for sync operations
- **if** (specified)
- **if** (intervals)
- **unregisterEntity** (void)
  - Unregisters an entity
- **queueOperation** (Future<SyncResult>)
  - Queues a sync operation
- **syncCollection** (Future<SyncResult>)
  - Performs a manual sync for a specific collection
- **_syncSingleItem** (await)
- **_completeOperation** (return)
- **_completeOperation** (return)
- **syncCollection** (await)
- **pause** (void)
  - Pauses sync operations
- **resume** (void)
  - Resumes sync operations
- **stop** (void)
  - Stops all sync operations
- **getStatus** (Map<String, dynamic>)
  - Gets current sync status
- **getAllProgress** (Map<String, SyncProgress>)
  - Gets all active progress trackers
- **_handleSyncTrigger** (void)
- **_handleOperationAdded** (void)
- **_handleQueueSizeChanged** (void)
- **_handleConflictDetected** (void)
- **_handleConflictResolved** (void)
- **_syncSingleItem** (Future<SyncResult>)
- **if** (enabled)
- **_startProcessing** (void)
- **Duration** (const)
- **_stopProcessing** (void)
- **_restartProcessing** (void)
- **_processQueue** (void)
- **_processOperation** (Future<SyncResult>)
- **_processBatchOperation** (return)
- **_processBatchOperation** (return)
- **_processBatchOperation** (Future<SyncResult>)
- **Exception** (throw)
- **_completeQueuedOperation** (void)
- **_completeOperation** (SyncResult)
- **_startProgressTracking** (void)
- **_stopProgressTracking** (void)
- **_updateProgress** (void)
- **_generateOperationId** (String)
- **_convertOperationType** (SyncAction)
  - Converts SyncOperationType to SyncAction
- **_convertSyncAction** (SyncOperationType)
  - Converts SyncAction to SyncOperationType
- **dispose** (void)
  - Dispose method to clean up resources
- **for** (timers)
- **for** (error)

---

## Functions

### main

**Returns:** `void`

**Source:** `lib\main.dart`

---

### build

**Returns:** `Widget`

**Source:** `lib\main.dart`

---

### createState

**Returns:** `State<MyHomePage>`

**Source:** `lib\main.dart`

---

### build

**Returns:** `Widget`

**Source:** `lib\main.dart`

---

### connect

**Returns:** `Future<bool>`

**Source:** `lib\src\adapters\usm_custom_api_sync_adapter.dart`

---

### disconnect

**Returns:** `Future<void>`

**Source:** `lib\src\adapters\usm_custom_api_sync_adapter.dart`

---

### create

**Returns:** `Future<SyncResult>`

**Source:** `lib\src\adapters\usm_custom_api_sync_adapter.dart`

---

### read

**Returns:** `Future<SyncResult>`

**Source:** `lib\src\adapters\usm_custom_api_sync_adapter.dart`

---

### update

**Returns:** `Future<SyncResult>`

**Source:** `lib\src\adapters\usm_custom_api_sync_adapter.dart`

---

### delete

**Returns:** `Future<SyncResult>`

**Source:** `lib\src\adapters\usm_custom_api_sync_adapter.dart`

---

### subscribe

**Returns:** `Stream<SyncEvent>`

**Source:** `lib\src\adapters\usm_custom_api_sync_adapter.dart`

---

### unsubscribe

**Returns:** `Future<void>`

**Source:** `lib\src\adapters\usm_custom_api_sync_adapter.dart`

---

### connect

**Returns:** `Future<bool>`

**Source:** `lib\src\adapters\usm_firebase_sync_adapter.dart`

---

### disconnect

**Returns:** `Future<void>`

**Source:** `lib\src\adapters\usm_firebase_sync_adapter.dart`

---

### create

**Returns:** `Future<SyncResult>`

**Source:** `lib\src\adapters\usm_firebase_sync_adapter.dart`

---

### read

**Returns:** `Future<SyncResult>`

**Source:** `lib\src\adapters\usm_firebase_sync_adapter.dart`

---

### update

**Returns:** `Future<SyncResult>`

**Source:** `lib\src\adapters\usm_firebase_sync_adapter.dart`

---

### delete

**Returns:** `Future<SyncResult>`

**Source:** `lib\src\adapters\usm_firebase_sync_adapter.dart`

---

### subscribe

**Returns:** `Stream<SyncEvent>`

**Source:** `lib\src\adapters\usm_firebase_sync_adapter.dart`

---

### unsubscribe

**Returns:** `Future<void>`

**Source:** `lib\src\adapters\usm_firebase_sync_adapter.dart`

---

### connect

**Returns:** `Future<bool>`

**Source:** `lib\src\adapters\usm_pocketbase_sync_adapter.dart`

---

### disconnect

**Returns:** `Future<void>`

**Source:** `lib\src\adapters\usm_pocketbase_sync_adapter.dart`

---

### create

**Returns:** `Future<SyncResult>`

**Source:** `lib\src\adapters\usm_pocketbase_sync_adapter.dart`

---

### read

**Returns:** `Future<SyncResult>`

**Source:** `lib\src\adapters\usm_pocketbase_sync_adapter.dart`

---

### update

**Returns:** `Future<SyncResult>`

**Source:** `lib\src\adapters\usm_pocketbase_sync_adapter.dart`

---

### delete

**Returns:** `Future<SyncResult>`

**Source:** `lib\src\adapters\usm_pocketbase_sync_adapter.dart`

---

### subscribe

**Returns:** `Stream<SyncEvent>`

**Source:** `lib\src\adapters\usm_pocketbase_sync_adapter.dart`

---

### unsubscribe

**Returns:** `Future<void>`

**Source:** `lib\src\adapters\usm_pocketbase_sync_adapter.dart`

---

### connect

**Returns:** `Future<bool>`

**Source:** `lib\src\adapters\usm_supabase_sync_adapter.dart`

---

### disconnect

**Returns:** `Future<void>`

**Source:** `lib\src\adapters\usm_supabase_sync_adapter.dart`

---

### create

**Returns:** `Future<SyncResult>`

**Source:** `lib\src\adapters\usm_supabase_sync_adapter.dart`

---

### read

**Returns:** `Future<SyncResult>`

**Source:** `lib\src\adapters\usm_supabase_sync_adapter.dart`

---

### update

**Returns:** `Future<SyncResult>`

**Source:** `lib\src\adapters\usm_supabase_sync_adapter.dart`

---

### delete

**Returns:** `Future<SyncResult>`

**Source:** `lib\src\adapters\usm_supabase_sync_adapter.dart`

---

### subscribe

**Returns:** `Stream<SyncEvent>`

**Source:** `lib\src\adapters\usm_supabase_sync_adapter.dart`

---

### unsubscribe

**Returns:** `Future<void>`

**Source:** `lib\src\adapters\usm_supabase_sync_adapter.dart`

---

### discoverFromDefinitions

Discovers entities from a provided list of entity definitions

**Returns:** `List<DiscoveredEntity>`

**Source:** `lib\src\config\usm_entity_discovery.dart`

---

### discoverFromTableNames

Discovers entities from table name patterns

**Returns:** `List<DiscoveredEntity>`

**Source:** `lib\src\config\usm_entity_discovery.dart`

---

### createConventionBasedConfig

Creates entity configurations based on conventions

**Returns:** `SyncEntityConfig`

**Source:** `lib\src\config\usm_entity_discovery.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\config\usm_entity_discovery.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\config\usm_entity_discovery.dart`

---

### copyWith

Create a copy with modified properties

**Returns:** `SyncFieldMappingConfig`

**Source:** `lib\src\config\usm_field_mapping_config.dart`

---

### toJson

Convert to JSON for serialization

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\config\usm_field_mapping_config.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\config\usm_field_mapping_config.dart`

---

### transform

Apply transformation to value

**Returns:** `dynamic`

**Source:** `lib\src\config\usm_field_mapping_config.dart`

---

### toJson

Convert to JSON

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\config\usm_field_mapping_config.dart`

---

### FieldTransformation

**Returns:** `return`

**Source:** `lib\src\config\usm_field_mapping_config.dart`

#### Parameters

- **Map<String** (`dynamic`) (required)
- **json** (`dynamic>`) (required)

---

### validate

Validate a field value

**Returns:** `ValidationResult`

**Source:** `lib\src\config\usm_field_mapping_config.dart`

---

### toJson

Convert to JSON

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\config\usm_field_mapping_config.dart`

---

### toJson

Convert to JSON

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\config\usm_field_mapping_config.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\config\usm_field_mapping_config.dart`

---

### serializeSyncSystem

Serializes a complete sync configuration to JSON

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\config\usm_sync_config_serializer.dart`

---

### deserializeSyncSystem

Deserializes a complete sync configuration from JSON

**Returns:** `SyncSystemConfig`

**Source:** `lib\src\config\usm_sync_config_serializer.dart`

---

### saveToFile

Saves configuration to a JSON file

**Returns:** `Future<void>`

**Source:** `lib\src\config\usm_sync_config_serializer.dart`

---

### loadFromFile

Loads configuration from a JSON file

**Returns:** `Future<SyncSystemConfig>`

**Source:** `lib\src\config\usm_sync_config_serializer.dart`

---

### exportToJsonString

Exports configuration to a formatted JSON string

**Returns:** `String`

**Source:** `lib\src\config\usm_sync_config_serializer.dart`

---

### importFromJsonString

Imports configuration from a JSON string

**Returns:** `SyncSystemConfig`

**Source:** `lib\src\config\usm_sync_config_serializer.dart`

---

### createTemplate

Creates a configuration template with common settings

**Returns:** `SyncSystemConfig`

**Source:** `lib\src\config\usm_sync_config_serializer.dart`

---

### mergeConfigurations

Merges two configurations, with the second taking precedence

**Returns:** `SyncSystemConfig`

**Source:** `lib\src\config\usm_sync_config_serializer.dart`

---

### applyOverrides

Applies configuration overrides to a base configuration

**Returns:** `SyncSystemConfig`

**Source:** `lib\src\config\usm_sync_config_serializer.dart`

---

### validateConfigFile

Validates configuration file format

**Returns:** `Future<SyncConfigFileValidationResult>`

**Source:** `lib\src\config\usm_sync_config_serializer.dart`

---

### toJson

Converts this configuration to JSON

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\config\usm_sync_config_serializer.dart`

---

### copyWith

Creates a copy with specified overrides

**Returns:** `SyncSystemConfig`

**Source:** `lib\src\config\usm_sync_config_serializer.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\config\usm_sync_config_serializer.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\config\usm_sync_config_serializer.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\config\usm_sync_config_serializer.dart`

---

### validateUniversalConfig

Validates a UniversalSyncConfig and returns validation results

**Returns:** `SyncConfigValidationResult`

**Source:** `lib\src\config\usm_sync_config_validator.dart`

---

### validateEntityConfig

Validates a SyncEntityConfig and returns validation results

**Returns:** `SyncEntityConfigValidationResult`

**Source:** `lib\src\config\usm_sync_config_validator.dart`

---

### validateEntityRegistry

Validates multiple entity configurations

**Returns:** `SyncEntityRegistryValidationResult`

**Source:** `lib\src\config\usm_sync_config_validator.dart`

---

### SyncEntityRegistryValidationResult

**Returns:** `return`

**Source:** `lib\src\config\usm_sync_config_validator.dart`

---

### validateSyncSystem

Validates complete sync system configuration

**Returns:** `SyncSystemValidationResult`

**Source:** `lib\src\config\usm_sync_config_validator.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\config\usm_sync_config_validator.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\config\usm_sync_config_validator.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\config\usm_sync_config_validator.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\config\usm_sync_config_validator.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\config\usm_sync_config_validator.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\config\usm_sync_config_validator.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\config\usm_sync_config_validator.dart`

---

### copyWith

Creates a copy of this configuration with specified overrides

**Returns:** `SyncEntityConfig`

**Source:** `lib\src\config\usm_sync_entity_config.dart`

---

### toJson

Converts this configuration to a JSON map

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\config\usm_sync_entity_config.dart`

---

### validate

Validates the configuration and returns any validation errors

**Returns:** `List<String>`

**Source:** `lib\src\config\usm_sync_entity_config.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\config\usm_sync_entity_config.dart`

---

### register

Register a new entity configuration

**Returns:** `void`

**Source:** `lib\src\config\usm_sync_entity_config.dart`

---

### unregister

Remove an entity configuration

**Returns:** `void`

**Source:** `lib\src\config\usm_sync_entity_config.dart`

---

### clear

Clear all entity configurations

**Returns:** `void`

**Source:** `lib\src\config\usm_sync_entity_config.dart`

---

### getEntitiesByPriority

Get configurations by priority level

**Returns:** `Map<String, SyncEntityConfig>`

**Source:** `lib\src\config\usm_sync_entity_config.dart`

---

### toJson

Convert all configurations to JSON

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\config\usm_sync_entity_config.dart`

---

### fromJson

Load configurations from JSON

**Returns:** `void`

**Source:** `lib\src\config\usm_sync_entity_config.dart`

---

### shouldLog

Check if this level should log a specific message type

**Returns:** `bool`

**Source:** `lib\src\config\usm_sync_enums.dart`

---

### shouldSync

**Returns:** `Future<bool>`

**Source:** `lib\src\config\usm_sync_strategies.dart`

---

### handleResult

**Returns:** `Future<SyncStrategyResult>`

**Source:** `lib\src\config\usm_sync_strategies.dart`

---

### resolveConflict

**Returns:** `Future<ConflictResolution>`

**Source:** `lib\src\config\usm_sync_strategies.dart`

---

### getConfiguration

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\config\usm_sync_strategies.dart`

---

### updateConfiguration

**Returns:** `void`

**Source:** `lib\src\config\usm_sync_strategies.dart`

---

### shouldSync

**Returns:** `Future<bool>`

**Source:** `lib\src\config\usm_sync_strategies.dart`

---

### handleResult

**Returns:** `Future<SyncStrategyResult>`

**Source:** `lib\src\config\usm_sync_strategies.dart`

---

### resolveConflict

**Returns:** `Future<ConflictResolution>`

**Source:** `lib\src\config\usm_sync_strategies.dart`

---

### getConfiguration

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\config\usm_sync_strategies.dart`

---

### updateConfiguration

**Returns:** `void`

**Source:** `lib\src\config\usm_sync_strategies.dart`

---

### shouldSync

**Returns:** `Future<bool>`

**Source:** `lib\src\config\usm_sync_strategies.dart`

---

### handleResult

**Returns:** `Future<SyncStrategyResult>`

**Source:** `lib\src\config\usm_sync_strategies.dart`

---

### resolveConflict

**Returns:** `Future<ConflictResolution>`

**Source:** `lib\src\config\usm_sync_strategies.dart`

---

### getConfiguration

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\config\usm_sync_strategies.dart`

---

### updateConfiguration

**Returns:** `void`

**Source:** `lib\src\config\usm_sync_strategies.dart`

---

### shouldSync

**Returns:** `Future<bool>`

**Source:** `lib\src\config\usm_sync_strategies.dart`

---

### handleResult

**Returns:** `Future<SyncStrategyResult>`

**Source:** `lib\src\config\usm_sync_strategies.dart`

---

### resolveConflict

**Returns:** `Future<ConflictResolution>`

**Source:** `lib\src\config\usm_sync_strategies.dart`

---

### getConfiguration

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\config\usm_sync_strategies.dart`

---

### updateConfiguration

**Returns:** `void`

**Source:** `lib\src\config\usm_sync_strategies.dart`

---

### registerStrategy

Register a sync strategy

**Returns:** `void`

**Source:** `lib\src\config\usm_sync_strategies.dart`

---

### setEntityStrategy

Set strategy for specific entity

**Returns:** `void`

**Source:** `lib\src\config\usm_sync_strategies.dart`

---

### getAllStrategies

Get all registered strategies

**Returns:** `Map<String, SyncStrategy>`

**Source:** `lib\src\config\usm_sync_strategies.dart`

---

### removeStrategy

Remove strategy

**Returns:** `void`

**Source:** `lib\src\config\usm_sync_strategies.dart`

---

### clear

Clear all strategies

**Returns:** `void`

**Source:** `lib\src\config\usm_sync_strategies.dart`

---

### copyWith

**Returns:** `SyncContext`

**Source:** `lib\src\config\usm_sync_strategies.dart`

---

### copyWith

Creates a copy of this configuration with specified overrides

**Returns:** `UniversalSyncConfig`

**Source:** `lib\src\config\usm_universal_sync_config.dart`

---

### toJson

Converts this configuration to a JSON map

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\config\usm_universal_sync_config.dart`

---

### validate

Validates the configuration and returns any validation errors

**Returns:** `List<String>`

**Source:** `lib\src\config\usm_universal_sync_config.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\config\usm_universal_sync_config.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\config\usm_universal_sync_config.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\config\usm_universal_sync_config.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\config\usm_universal_sync_config.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\config\usm_universal_sync_config.dart`

---

### run

**Returns:** `Future<void>`

**Source:** `lib\src\demos\usm_task3_2_simple_demo.dart`

---

### run

Run the complete demo showing all optimization features

**Returns:** `Future<void>`

**Source:** `lib\src\demos\usm_task4_1_demo.dart`

---

### toMap

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\interfaces\usm_sync_platform_service.dart`

---

### PlatformNetworkInfo

**Returns:** `return`

**Source:** `lib\src\interfaces\usm_sync_platform_service.dart`

#### Parameters

- **Map<String** (`dynamic`) (required)
- **map** (`dynamic>`) (required)

---

### toMap

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\interfaces\usm_sync_platform_service.dart`

#### Parameters

- **0.2** (`batteryLevel`) (optional)

---

### toMap

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\interfaces\usm_sync_platform_service.dart`

---

### hasFeature

Checks if a specific feature is supported

**Returns:** `bool`

**Source:** `lib\src\models\usm_sync_backend_capabilities.dart`

---

### getEndpointUrl

Gets the full URL for a specific endpoint

**Returns:** `String`

**Source:** `lib\src\models\usm_sync_backend_configuration.dart`

---

### copyWith

Creates a copy with modified values

**Returns:** `SyncBackendConfiguration`

**Source:** `lib\src\models\usm_sync_backend_configuration.dart`

---

### toJson

Converts to JSON for serialization

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\models\usm_sync_backend_configuration.dart`

---

### toJson

Converts to JSON (excluding sensitive data in production)

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\models\usm_sync_backend_configuration.dart`

#### Parameters

- **production** (`excluding`) (required)

---

### SyncAuthConfiguration

**Returns:** `return`

**Source:** `lib\src\models\usm_sync_backend_configuration.dart`

#### Parameters

- **Map<String** (`dynamic`) (required)
- **json** (`dynamic>`) (required)

---

### toJson

Converts to JSON

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\models\usm_sync_backend_configuration.dart`

---

### addEvent

Adds an event to the stream

**Returns:** `void`

**Source:** `lib\src\models\usm_sync_event.dart`

---

### addError

Adds an error to the stream

**Returns:** `void`

**Source:** `lib\src\models\usm_sync_event.dart`

---

### cancel

**Returns:** `Future<void>`

**Source:** `lib\src\models\usm_sync_event.dart`

---

### pause

**Returns:** `Future<void>`

**Source:** `lib\src\models\usm_sync_event.dart`

---

### resume

**Returns:** `Future<void>`

**Source:** `lib\src\models\usm_sync_event.dart`

---

### updateOptions

**Returns:** `Future<void>`

**Source:** `lib\src\models\usm_sync_event.dart`

---

### affectsOrganization

Checks if this event affects the specified organization

**Returns:** `bool`

**Source:** `lib\src\models\usm_sync_event.dart`

---

### toJson

Converts to JSON for serialization

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\models\usm_sync_event.dart`

---

### SyncEvent

**Returns:** `return`

**Source:** `lib\src\models\usm_sync_event.dart`

#### Parameters

- **Map<String** (`dynamic`) (required)
- **json** (`dynamic>`) (required)

---

### toString

**Returns:** `String`

**Source:** `lib\src\models\usm_sync_event.dart`

---

### eventsForOrganization

Filters events by organization

**Returns:** `List<SyncEvent>`

**Source:** `lib\src\models\usm_sync_event.dart`

---

### addSubscription

Adds a subscription

**Returns:** `void`

**Source:** `lib\src\models\usm_sync_event.dart`

---

### removeSubscription

Removes a subscription

**Returns:** `Future<void>`

**Source:** `lib\src\models\usm_sync_event.dart`

---

### cancelAllSubscriptions

Cancels all subscriptions

**Returns:** `Future<void>`

**Source:** `lib\src\models\usm_sync_event.dart`

---

### getSubscriptionsForCollection

Gets subscriptions for a specific collection

**Returns:** `List<IRealtimeSubscription>`

**Source:** `lib\src\models\usm_sync_event.dart`

---

### toJson

Converts to JSON for logging and debugging

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\models\usm_sync_result.dart`

---

### toJson

Converts to JSON for logging

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\models\usm_sync_result.dart`

---

### SyncError

**Returns:** `return`

**Source:** `lib\src\models\usm_sync_result.dart`

#### Parameters

- **Map<String** (`dynamic`) (required)
- **json** (`dynamic>`) (required)

---

### toString

**Returns:** `String`

**Source:** `lib\src\models\usm_sync_result.dart`

---

### initialize

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### dispose

**Returns:** `Future<void>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### readFile

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### readFileAsBytes

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### writeFile

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### writeFileAsBytes

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### deleteFile

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### fileExists

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### createDirectory

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### listDirectory

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### getFileSize

**Returns:** `Future<int?>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### getFileModificationTime

**Returns:** `Future<DateTime?>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### createSyncCacheDirectory

**Returns:** `Future<String>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### cleanupOldCacheFiles

**Returns:** `Future<void>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### getNetworkInfo

**Returns:** `Future<PlatformNetworkInfo>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### isNetworkSuitableForSync

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### estimateNetworkSpeed

**Returns:** `Future<double?>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### getBatteryInfo

**Returns:** `Future<PlatformBatteryInfo>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### isPowerSavingMode

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### getRecommendedSyncInterval

**Returns:** `Future<Duration>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### getDatabaseConfig

**Returns:** `Future<PlatformDatabaseConfig>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### initializeDatabase

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### vacuumDatabase

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### getDatabaseSize

**Returns:** `Future<int?>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### backupDatabase

**Returns:** `Future<String?>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### restoreDatabase

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### isRunningInBackground

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### requestBackgroundPermission

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### getAvailableStorageSpace

**Returns:** `Future<int?>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### hasResourcesForSync

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### scheduleBackgroundSync

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### cancelBackgroundSync

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### hasRequiredPermissions

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### requestPermissions

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### encryptData

**Returns:** `Future<String?>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### decryptData

**Returns:** `Future<String?>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### storeSecureValue

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### getSecureValue

**Returns:** `Future<String?>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### deleteSecureValue

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### logDiagnosticInfo

**Returns:** `Future<void>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### exportLogs

**Returns:** `Future<String?>`

**Source:** `lib\src\platform\usm_mobile_platform_service.dart`

---

### createForCurrentPlatform

Create platform service for current platform

**Returns:** `ISyncPlatformService`

**Source:** `lib\src\platform\usm_platform_service_factory.dart`

---

### createForPlatform

Create platform service for specific platform type

**Returns:** `ISyncPlatformService`

**Source:** `lib\src\platform\usm_platform_service_factory.dart`

---

### getCurrentPlatform

Get current platform type

**Returns:** `SyncPlatformType`

**Source:** `lib\src\platform\usm_platform_service_factory.dart`

---

### supportsBackgroundSync

Check if current platform supports background sync

**Returns:** `bool`

**Source:** `lib\src\platform\usm_platform_service_factory.dart`

---

### supportsBatteryManagement

Check if current platform supports battery management

**Returns:** `bool`

**Source:** `lib\src\platform\usm_platform_service_factory.dart`

---

### supportsFileSystem

Check if current platform supports real file system operations

**Returns:** `bool`

**Source:** `lib\src\platform\usm_platform_service_factory.dart`

---

### getRecommendedSyncInterval

Get recommended sync interval for current platform

**Returns:** `Duration`

**Source:** `lib\src\platform\usm_platform_service_factory.dart`

---

### getPlatformOptimizations

Get platform-specific optimization recommendations

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\platform\usm_platform_service_factory.dart`

---

### getPlatformCapabilities

Create diagnostic report for platform capabilities

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\platform\usm_platform_service_factory.dart`

---

### initialize

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### dispose

**Returns:** `Future<void>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### readFile

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### readFileAsBytes

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### writeFile

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### writeFileAsBytes

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### deleteFile

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### fileExists

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### createDirectory

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### listDirectory

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### getFileSize

**Returns:** `Future<int?>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### getFileModificationTime

**Returns:** `Future<DateTime?>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### createSyncCacheDirectory

**Returns:** `Future<String>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### cleanupOldCacheFiles

**Returns:** `Future<void>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### getNetworkInfo

**Returns:** `Future<PlatformNetworkInfo>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### isNetworkSuitableForSync

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### estimateNetworkSpeed

**Returns:** `Future<double?>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### getBatteryInfo

**Returns:** `Future<PlatformBatteryInfo>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### isPowerSavingMode

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### getRecommendedSyncInterval

**Returns:** `Future<Duration>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### getDatabaseConfig

**Returns:** `Future<PlatformDatabaseConfig>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### initializeDatabase

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### vacuumDatabase

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### getDatabaseSize

**Returns:** `Future<int?>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### backupDatabase

**Returns:** `Future<String?>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### restoreDatabase

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### isRunningInBackground

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### requestBackgroundPermission

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### getAvailableStorageSpace

**Returns:** `Future<int?>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### hasResourcesForSync

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### scheduleBackgroundSync

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### cancelBackgroundSync

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### hasRequiredPermissions

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### requestPermissions

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### encryptData

**Returns:** `Future<String?>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### decryptData

**Returns:** `Future<String?>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### storeSecureValue

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### getSecureValue

**Returns:** `Future<String?>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### deleteSecureValue

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### logDiagnosticInfo

**Returns:** `Future<void>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### exportLogs

**Returns:** `Future<String?>`

**Source:** `lib\src\platform\usm_stub_web_platform_service.dart`

---

### initialize

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### dispose

**Returns:** `Future<void>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### readFile

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### readFileAsBytes

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### writeFile

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### writeFileAsBytes

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### deleteFile

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### fileExists

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### createDirectory

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### listDirectory

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### getFileSize

**Returns:** `Future<int?>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### getFileModificationTime

**Returns:** `Future<DateTime?>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### createSyncCacheDirectory

**Returns:** `Future<String>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### cleanupOldCacheFiles

**Returns:** `Future<void>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### getNetworkInfo

**Returns:** `Future<PlatformNetworkInfo>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### isNetworkSuitableForSync

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### estimateNetworkSpeed

**Returns:** `Future<double?>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### getBatteryInfo

**Returns:** `Future<PlatformBatteryInfo>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### isPowerSavingMode

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### getRecommendedSyncInterval

**Returns:** `Future<Duration>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### getDatabaseConfig

**Returns:** `Future<PlatformDatabaseConfig>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### initializeDatabase

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### vacuumDatabase

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### getDatabaseSize

**Returns:** `Future<int?>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### backupDatabase

**Returns:** `Future<String?>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### restoreDatabase

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### isRunningInBackground

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### requestBackgroundPermission

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### getAvailableStorageSpace

**Returns:** `Future<int?>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### hasResourcesForSync

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### scheduleBackgroundSync

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### cancelBackgroundSync

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### hasRequiredPermissions

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### requestPermissions

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### encryptData

**Returns:** `Future<String?>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### decryptData

**Returns:** `Future<String?>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### storeSecureValue

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### getSecureValue

**Returns:** `Future<String?>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### deleteSecureValue

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### logDiagnosticInfo

**Returns:** `Future<void>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### exportLogs

**Returns:** `Future<String?>`

**Source:** `lib\src\platform\usm_web_platform_service.dart`

---

### initialize

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### dispose

**Returns:** `Future<void>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### readFile

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### readFileAsBytes

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### writeFile

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### writeFileAsBytes

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### deleteFile

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### fileExists

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### createDirectory

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### listDirectory

**Returns:** `Future<FileOperationResult>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### getFileSize

**Returns:** `Future<int?>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### getFileModificationTime

**Returns:** `Future<DateTime?>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### createSyncCacheDirectory

**Returns:** `Future<String>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### cleanupOldCacheFiles

**Returns:** `Future<void>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### getNetworkInfo

**Returns:** `Future<PlatformNetworkInfo>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### isNetworkSuitableForSync

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### estimateNetworkSpeed

**Returns:** `Future<double?>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### getBatteryInfo

**Returns:** `Future<PlatformBatteryInfo>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### isPowerSavingMode

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### getRecommendedSyncInterval

**Returns:** `Future<Duration>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### getDatabaseConfig

**Returns:** `Future<PlatformDatabaseConfig>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### initializeDatabase

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### vacuumDatabase

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### getDatabaseSize

**Returns:** `Future<int?>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### backupDatabase

**Returns:** `Future<String?>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### restoreDatabase

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### isRunningInBackground

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### requestBackgroundPermission

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### getAvailableStorageSpace

**Returns:** `Future<int?>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### hasResourcesForSync

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### scheduleBackgroundSync

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### cancelBackgroundSync

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### hasRequiredPermissions

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### requestPermissions

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### encryptData

**Returns:** `Future<String?>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### decryptData

**Returns:** `Future<String?>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### storeSecureValue

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### getSecureValue

**Returns:** `Future<String?>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### deleteSecureValue

**Returns:** `Future<bool>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### logDiagnosticInfo

**Returns:** `Future<void>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### exportLogs

**Returns:** `Future<String?>`

**Source:** `lib\src\platform\usm_windows_platform_service.dart`

---

### optimizeBatchStrategy

Optimize batching strategy based on operation characteristics  Analyzes the [operations] and returns a recommended [BatchStrategy] based on factors like operation types, data sizes, and system resources.

**Returns:** `BatchStrategy`

**Source:** `lib\src\services\usm_batch_sync_service.dart`

---

### createBatch

Create a batch of create operations  Helper method to easily create multiple records of the same type.

**Returns:** `List<BatchSyncOperation>`

**Source:** `lib\src\services\usm_batch_sync_service.dart`

---

### updateBatch

Create a batch of update operations  Helper method to easily update multiple records of the same type.

**Returns:** `List<BatchSyncOperation>`

**Source:** `lib\src\services\usm_batch_sync_service.dart`

---

### deleteBatch

Create a batch of delete operations  Helper method to easily delete multiple records of the same type.

**Returns:** `List<BatchSyncOperation>`

**Source:** `lib\src\services\usm_batch_sync_service.dart`

---

### if

**Returns:** `else`

**Source:** `lib\src\services\usm_batch_sync_service.dart`

---

### switch

**Returns:** `return`

**Source:** `lib\src\services\usm_batch_sync_service.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\services\usm_batch_sync_service.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\services\usm_batch_sync_service.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\services\usm_batch_sync_service.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\services\usm_batch_sync_service.dart`

---

### acquire

**Returns:** `Future<void>`

**Source:** `lib\src\services\usm_batch_sync_service.dart`

#### Parameters

- **this._maxCount** (`dynamic`) (required)

---

### release

**Returns:** `void`

**Source:** `lib\src\services\usm_batch_sync_service.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\services\usm_batch_sync_service.dart`

---

### withNotes

Creates a copy with updated notes

**Returns:** `ConflictHistoryEntry`

**Source:** `lib\src\services\usm_conflict_history_service.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_conflict_history_service.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_conflict_history_service.dart`

---

### recordConflictResolution

Adds a conflict and its resolution to history

**Returns:** `void`

**Source:** `lib\src\services\usm_conflict_history_service.dart`

---

### addNotesToEntry

Adds notes to an existing history entry

**Returns:** `void`

**Source:** `lib\src\services\usm_conflict_history_service.dart`

---

### getAllHistory

Gets all history entries

**Returns:** `List<ConflictHistoryEntry>`

**Source:** `lib\src\services\usm_conflict_history_service.dart`

---

### getEntityHistory

Gets history for a specific entity

**Returns:** `List<ConflictHistoryEntry>`

**Source:** `lib\src\services\usm_conflict_history_service.dart`

---

### getCollectionHistory

Gets history for a specific collection

**Returns:** `List<ConflictHistoryEntry>`

**Source:** `lib\src\services\usm_conflict_history_service.dart`

---

### getRecentHistory

Gets recent history entries

**Returns:** `List<ConflictHistoryEntry>`

**Source:** `lib\src\services\usm_conflict_history_service.dart`

---

### getUnresolvedConflicts

Gets unresolved conflicts

**Returns:** `List<ConflictHistoryEntry>`

**Source:** `lib\src\services\usm_conflict_history_service.dart`

---

### getManuallyResolvedConflicts

Gets manually resolved conflicts

**Returns:** `List<ConflictHistoryEntry>`

**Source:** `lib\src\services\usm_conflict_history_service.dart`

---

### getConflictsByStrategy

Gets conflicts resolved with specific strategy

**Returns:** `List<ConflictHistoryEntry>`

**Source:** `lib\src\services\usm_conflict_history_service.dart`

---

### getConflictsInDateRange

Gets conflicts in date range

**Returns:** `List<ConflictHistoryEntry>`

**Source:** `lib\src\services\usm_conflict_history_service.dart`

---

### generateStats

Generates comprehensive statistics

**Returns:** `ConflictResolutionStats`

**Source:** `lib\src\services\usm_conflict_history_service.dart`

---

### suggestStrategyForConflict

Learns from past resolutions to suggest strategies

**Returns:** `EnhancedConflictResolutionStrategy`

**Source:** `lib\src\services\usm_conflict_history_service.dart`

---

### exportToJson

Exports history to JSON

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_conflict_history_service.dart`

---

### importFromJson

Imports history from JSON

**Returns:** `void`

**Source:** `lib\src\services\usm_conflict_history_service.dart`

---

### clearHistory

Clears all history

**Returns:** `void`

**Source:** `lib\src\services\usm_conflict_history_service.dart`

---

### dispose

Disposes resources

**Returns:** `void`

**Source:** `lib\src\services\usm_conflict_history_service.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\services\usm_conflict_resolver.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\services\usm_conflict_resolver.dart`

---

### canResolve

**Returns:** `bool`

**Source:** `lib\src\services\usm_conflict_resolver.dart`

---

### resolveConflict

**Returns:** `SyncConflictResolution`

**Source:** `lib\src\services\usm_conflict_resolver.dart`

---

### setDefaultResolver

Sets the default resolver

**Returns:** `void`

**Source:** `lib\src\services\usm_conflict_resolver.dart`

---

### registerResolver

Registers a resolver for a specific collection

**Returns:** `void`

**Source:** `lib\src\services\usm_conflict_resolver.dart`

---

### removeResolver

Removes a resolver for a collection

**Returns:** `void`

**Source:** `lib\src\services\usm_conflict_resolver.dart`

---

### resolveConflict

Resolves a conflict using the appropriate resolver

**Returns:** `SyncConflictResolution`

**Source:** `lib\src\services\usm_conflict_resolver.dart`

---

### dispose

Dispose method to clean up resources

**Returns:** `void`

**Source:** `lib\src\services\usm_conflict_resolver.dart`

---

### mergeValues

**Returns:** `dynamic`

**Source:** `lib\src\services\usm_custom_merge_strategies.dart`

---

### getConfidenceScore

**Returns:** `double`

**Source:** `lib\src\services\usm_custom_merge_strategies.dart`

---

### validateMergedValue

**Returns:** `bool`

**Source:** `lib\src\services\usm_custom_merge_strategies.dart`

---

### mergeValues

**Returns:** `dynamic`

**Source:** `lib\src\services\usm_custom_merge_strategies.dart`

---

### getConfidenceScore

**Returns:** `double`

**Source:** `lib\src\services\usm_custom_merge_strategies.dart`

---

### validateMergedValue

**Returns:** `bool`

**Source:** `lib\src\services\usm_custom_merge_strategies.dart`

---

### mergeValues

**Returns:** `dynamic`

**Source:** `lib\src\services\usm_custom_merge_strategies.dart`

---

### getConfidenceScore

**Returns:** `double`

**Source:** `lib\src\services\usm_custom_merge_strategies.dart`

---

### validateMergedValue

**Returns:** `bool`

**Source:** `lib\src\services\usm_custom_merge_strategies.dart`

---

### mergeValues

**Returns:** `dynamic`

**Source:** `lib\src\services\usm_custom_merge_strategies.dart`

---

### getConfidenceScore

**Returns:** `double`

**Source:** `lib\src\services\usm_custom_merge_strategies.dart`

---

### validateMergedValue

**Returns:** `bool`

**Source:** `lib\src\services\usm_custom_merge_strategies.dart`

---

### mergeValues

**Returns:** `dynamic`

**Source:** `lib\src\services\usm_custom_merge_strategies.dart`

---

### getConfidenceScore

**Returns:** `double`

**Source:** `lib\src\services\usm_custom_merge_strategies.dart`

---

### validateMergedValue

**Returns:** `bool`

**Source:** `lib\src\services\usm_custom_merge_strategies.dart`

---

### mergeValues

**Returns:** `dynamic`

**Source:** `lib\src\services\usm_custom_merge_strategies.dart`

---

### getConfidenceScore

**Returns:** `double`

**Source:** `lib\src\services\usm_custom_merge_strategies.dart`

---

### validateMergedValue

**Returns:** `bool`

**Source:** `lib\src\services\usm_custom_merge_strategies.dart`

---

### calculateDelta

Calculate delta between two data objects  Returns a [DeltaPatch] containing only the changed fields and metadata needed to transform [oldData] into [newData].  Example: ```dart final oldData = {'name': 'John', 'age': 30, 'city': 'New York'}; final newData = {'name': 'John', 'age': 31, 'city': 'Boston'}; final patch = service.calculateDelta(oldData, newData); // patch.changes will contain: {'age': 31, 'city': 'Boston'} ```

**Returns:** `DeltaPatch`

**Source:** `lib\src\services\usm_delta_sync_service.dart`

---

### applyDelta

Apply a delta patch to existing data  Takes [baseData] and applies the [patch] to produce the updated data. Optionally validates checksums if [validateChecksum] is true.  Throws [DeltaValidationException] if checksum validation fails.

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_delta_sync_service.dart`

---

### calculateCollectionDelta

Calculate delta for a collection of records  Compares [oldRecords] with [newRecords] and returns a [CollectionDelta] containing all changes needed to transform the old collection to the new one.

**Returns:** `CollectionDelta`

**Source:** `lib\src\services\usm_delta_sync_service.dart`

---

### toJson

Convert to JSON for serialization

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_delta_sync_service.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\services\usm_delta_sync_service.dart`

---

### toJson

Convert to JSON for serialization

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_delta_sync_service.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\services\usm_delta_sync_service.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\services\usm_delta_sync_service.dart`

---

### canResolve

**Returns:** `bool`

**Source:** `lib\src\services\usm_enhanced_conflict_resolution_manager.dart`

---

### getConfidenceScore

**Returns:** `double`

**Source:** `lib\src\services\usm_enhanced_conflict_resolution_manager.dart`

---

### resolveConflict

**Returns:** `EnhancedSyncConflictResolution`

**Source:** `lib\src\services\usm_enhanced_conflict_resolution_manager.dart`

---

### registerMergeStrategy

Registers a custom merge strategy

**Returns:** `void`

**Source:** `lib\src\services\usm_enhanced_conflict_resolution_manager.dart`

---

### setFieldStrategy

Sets field-specific strategy

**Returns:** `void`

**Source:** `lib\src\services\usm_enhanced_conflict_resolution_manager.dart`

---

### setCollectionStrategy

Sets collection-specific strategy

**Returns:** `void`

**Source:** `lib\src\services\usm_enhanced_conflict_resolution_manager.dart`

---

### setDefaultResolver

Sets the default resolver

**Returns:** `void`

**Source:** `lib\src\services\usm_enhanced_conflict_resolution_manager.dart`

---

### registerResolver

Registers a resolver for a specific collection

**Returns:** `void`

**Source:** `lib\src\services\usm_enhanced_conflict_resolution_manager.dart`

---

### registerMergeStrategy

Registers a custom merge strategy globally

**Returns:** `void`

**Source:** `lib\src\services\usm_enhanced_conflict_resolution_manager.dart`

---

### resolveConflict

Resolves a conflict using the best available resolver

**Returns:** `EnhancedSyncConflictResolution`

**Source:** `lib\src\services\usm_enhanced_conflict_resolution_manager.dart`

---

### prepareConflictForInteractiveResolution

Prepares conflict for interactive resolution

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_enhanced_conflict_resolution_manager.dart`

---

### processInteractiveResolution

Processes user resolution from interactive UI

**Returns:** `InteractiveResolutionResult`

**Source:** `lib\src\services\usm_enhanced_conflict_resolution_manager.dart`

---

### getStatistics

Gets conflict resolution statistics

**Returns:** `ConflictResolutionStats`

**Source:** `lib\src\services\usm_enhanced_conflict_resolution_manager.dart`

---

### suggestStrategyForConflict

Suggests strategy for a conflict based on history

**Returns:** `EnhancedConflictResolutionStrategy`

**Source:** `lib\src\services\usm_enhanced_conflict_resolution_manager.dart`

---

### exportConflictHistory

Exports conflict history

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_enhanced_conflict_resolution_manager.dart`

---

### importConflictHistory

Imports conflict history

**Returns:** `void`

**Source:** `lib\src\services\usm_enhanced_conflict_resolution_manager.dart`

---

### dispose

Disposes all resources

**Returns:** `void`

**Source:** `lib\src\services\usm_enhanced_conflict_resolution_manager.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_enhanced_conflict_resolver.dart`

---

### FieldConflictInfo

**Returns:** `return`

**Source:** `lib\src\services\usm_enhanced_conflict_resolver.dart`

#### Parameters

- **Map<String** (`dynamic`) (required)
- **json** (`dynamic>`) (required)

---

### getConflictsByType

Gets conflicts by type

**Returns:** `List<FieldConflictInfo>`

**Source:** `lib\src\services\usm_enhanced_conflict_resolver.dart`

---

### getHighConfidenceConflicts

Gets high-confidence conflicts

**Returns:** `List<FieldConflictInfo>`

**Source:** `lib\src\services\usm_enhanced_conflict_resolver.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_enhanced_conflict_resolver.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_enhanced_conflict_resolver.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\services\usm_enhanced_conflict_resolver.dart`

---

### getConfidenceScore

Returns confidence score for handling this conflict type

**Returns:** `double`

**Source:** `lib\src\services\usm_enhanced_conflict_resolver.dart`

---

### preprocessConflict

Pre-processes conflict for better resolution

**Returns:** `EnhancedSyncConflict`

**Source:** `lib\src\services\usm_enhanced_conflict_resolver.dart`

---

### postprocessResolution

Post-processes resolution for validation

**Returns:** `EnhancedSyncConflictResolution`

**Source:** `lib\src\services\usm_enhanced_conflict_resolver.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_interactive_conflict_ui.dart`

---

### prepareConflictForUI

Prepares conflict data for interactive UI presentation

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_interactive_conflict_ui.dart`

---

### processUserResolution

Processes user resolution choices

**Returns:** `InteractiveResolutionResult`

**Source:** `lib\src\services\usm_interactive_conflict_ui.dart`

---

### registerMergeStrategy

Registers a custom merge strategy

**Returns:** `void`

**Source:** `lib\src\services\usm_interactive_conflict_ui.dart`

---

### dispose

Disposes resources

**Returns:** `void`

**Source:** `lib\src\services\usm_interactive_conflict_ui.dart`

---

### scheduleEntity

Schedule sync for an entity with smart optimization  Analyzes the entity's sync patterns and current conditions to determine the optimal sync schedule. Returns a [SyncSchedule] describing when syncs will occur.  Example: ```dart final schedule = scheduler.scheduleEntity( 'user_profiles', priority: SyncPriority.high, strategy: EntitySyncStrategy.adaptive, ); ```

**Returns:** `SyncSchedule`

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

---

### updateStrategy

Update scheduling strategy dynamically  Changes the global scheduling approach and recalculates all active schedules using the new strategy.

**Returns:** `void`

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

---

### recordSyncCompletion

Record successful sync completion  Updates metrics and usage patterns based on sync results to improve future scheduling decisions.

**Returns:** `void`

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

---

### pauseEntity

Pause scheduling for an entity  Temporarily stops automatic sync scheduling while preserving metrics and configuration for later resumption.

**Returns:** `void`

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

---

### resumeEntity

Resume scheduling for an entity  Restarts automatic sync scheduling using the previously configured or optimized settings.

**Returns:** `void`

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

---

### getRecommendations

Get sync recommendations based on current patterns  Analyzes recent sync history and usage patterns to provide recommendations for optimizing sync schedules.

**Returns:** `List<SyncRecommendation>`

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

---

### recalculateSchedules

Force sync schedule recalculation  Manually triggers recalculation of all sync schedules based on current conditions and patterns.

**Returns:** `void`

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

---

### dispose

Dispose of the scheduler and clean up resources

**Returns:** `void`

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

---

### startMonitoring

**Returns:** `void`

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

---

### dispose

**Returns:** `void`

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

---

### startMonitoring

**Returns:** `void`

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

---

### dispose

**Returns:** `void`

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

---

### recordSyncEvent

**Returns:** `void`

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

---

### analyzeEntity

**Returns:** `UsagePattern`

**Source:** `lib\src\services\usm_smart_sync_scheduler.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_alerting_service.dart`

---

### AlertRule

**Returns:** `return`

**Source:** `lib\src\services\usm_sync_alerting_service.dart`

#### Parameters

- **Map<String** (`dynamic`) (required)
- **json** (`dynamic>`) (required)

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_alerting_service.dart`

---

### AlertCondition

**Returns:** `return`

**Source:** `lib\src\services\usm_sync_alerting_service.dart`

#### Parameters

- **Map<String** (`dynamic`) (required)
- **json** (`dynamic>`) (required)

---

### resolve

Creates resolved version of alert

**Returns:** `SyncAlert`

**Source:** `lib\src\services\usm_sync_alerting_service.dart`

---

### acknowledge

Creates acknowledged version of alert

**Returns:** `SyncAlert`

**Source:** `lib\src\services\usm_sync_alerting_service.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_alerting_service.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_alerting_service.dart`

---

### addAlertRule

Adds or updates an alert rule

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_alerting_service.dart`

---

### removeAlertRule

Removes an alert rule

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_alerting_service.dart`

---

### setRuleEnabled

Enables or disables an alert rule

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_alerting_service.dart`

---

### getAllRules

Gets all alert rules

**Returns:** `List<AlertRule>`

**Source:** `lib\src\services\usm_sync_alerting_service.dart`

---

### getActiveAlerts

Gets active alerts

**Returns:** `List<SyncAlert>`

**Source:** `lib\src\services\usm_sync_alerting_service.dart`

---

### getAlertHistory

Gets alert history

**Returns:** `List<SyncAlert>`

**Source:** `lib\src\services\usm_sync_alerting_service.dart`

---

### acknowledgeAlert

Acknowledges an alert

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_alerting_service.dart`

---

### resolveAlert

Resolves an alert

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_alerting_service.dart`

---

### suppressRule

Suppresses alerts for a rule temporarily

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_alerting_service.dart`

---

### configureNotification

Configures notification channel

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_alerting_service.dart`

---

### setNotificationEnabled

Enables or disables notification channel

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_alerting_service.dart`

---

### getAlertStatistics

Gets alert statistics

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_alerting_service.dart`

---

### createDefaultRules

Creates predefined alert rules

**Returns:** `List<AlertRule>`

**Source:** `lib\src\services\usm_sync_alerting_service.dart`

---

### dispose

Disposes the alerting service

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_alerting_service.dart`

---

### complete

Creates completed metrics

**Returns:** `SyncOperationMetrics`

**Source:** `lib\src\services\usm_sync_analytics_service.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_analytics_service.dart`

---

### SyncOperationMetrics

**Returns:** `return`

**Source:** `lib\src\services\usm_sync_analytics_service.dart`

#### Parameters

- **Map<String** (`dynamic`) (required)
- **json** (`dynamic>`) (required)

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_analytics_service.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_analytics_service.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_analytics_service.dart`

---

### startOperation

Starts tracking a new sync operation

**Returns:** `String`

**Source:** `lib\src\services\usm_sync_analytics_service.dart`

---

### updateOperation

Updates an active operation with progress

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_analytics_service.dart`

---

### completeOperation

Completes an operation and moves it to history

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_analytics_service.dart`

---

### cancelOperation

Cancels an active operation

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_analytics_service.dart`

---

### getPerformanceMetrics

Gets current performance metrics

**Returns:** `SyncPerformanceMetrics`

**Source:** `lib\src\services\usm_sync_analytics_service.dart`

---

### getFailureAnalysis

Gets failure analysis

**Returns:** `SyncFailureAnalysis`

**Source:** `lib\src\services\usm_sync_analytics_service.dart`

---

### SyncFailureAnalysis

**Returns:** `return`

**Source:** `lib\src\services\usm_sync_analytics_service.dart`

---

### getCurrentHealthStatus

Gets current health status

**Returns:** `SyncHealthStatus`

**Source:** `lib\src\services\usm_sync_analytics_service.dart`

---

### stopHealthMonitoring

Stops health monitoring

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_analytics_service.dart`

---

### getActiveOperations

Gets all active operations

**Returns:** `List<SyncOperationMetrics>`

**Source:** `lib\src\services\usm_sync_analytics_service.dart`

---

### getOperationHistory

Gets operation history

**Returns:** `List<SyncOperationMetrics>`

**Source:** `lib\src\services\usm_sync_analytics_service.dart`

---

### exportAnalytics

Exports analytics data

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_analytics_service.dart`

---

### setRetentionPolicy

Sets retention policy

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_analytics_service.dart`

---

### dispose

Disposes the service

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_analytics_service.dart`

---

### compress

Compress data using the specified compression type  Returns a [CompressionResult] containing the compressed data, compression ratio, and metadata about the compression operation.  Example: ```dart final data = {'large': 'data' * 1000}; final result = await service.compress(data, CompressionType.gzip); print('Compression ratio: ${result.compressionRatio}'); ```

**Returns:** `Future<CompressionResult>`

**Source:** `lib\src\services\usm_sync_compression_service.dart`

---

### selectCompressionStrategy

Automatically select the best compression type for the given data  Analyzes the data characteristics and selects the most appropriate compression algorithm based on size, content type, and performance requirements.  Factors considered: - Data size (small data may not benefit from compression) - Data type (text vs binary-like data) - Speed requirements (real-time vs batch operations) - Network conditions (slow networks benefit more from compression)

**Returns:** `CompressionStrategy`

**Source:** `lib\src\services\usm_sync_compression_service.dart`

#### Parameters

- **compression** (`slow`) (required)

---

### benchmark

Benchmark different compression algorithms on sample data  Useful for performance testing and algorithm selection. Returns results for all supported compression types.

**Returns:** `Future<CompressionBenchmark>`

**Source:** `lib\src\services\usm_sync_compression_service.dart`

---

### toJson

Convert to JSON for serialization

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_compression_service.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\services\usm_sync_compression_service.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\services\usm_sync_compression_service.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\services\usm_sync_compression_service.dart`

---

### publish

Publishes an event to all subscribers

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_event_bus.dart`

---

### subscribeToAll

Subscribes to all events

**Returns:** `String`

**Source:** `lib\src\services\usm_sync_event_bus.dart`

---

### unsubscribe

Unsubscribes from events

**Returns:** `bool`

**Source:** `lib\src\services\usm_sync_event_bus.dart`

---

### clearAllSubscriptions

Clears all subscriptions

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_event_bus.dart`

---

### getEventHistory

Gets event history

**Returns:** `List<SyncBusEvent>`

**Source:** `lib\src\services\usm_sync_event_bus.dart`

---

### getActiveSubscriptions

Gets all active subscriptions

**Returns:** `Map<Type, int>`

**Source:** `lib\src\services\usm_sync_event_bus.dart`

---

### clearEventHistory

Clears event history

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_event_bus.dart`

---

### publishSyncOperationStarted

Convenience methods for common events

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_event_bus.dart`

---

### publishSyncOperationCompleted

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_event_bus.dart`

---

### publishSyncConflictDetected

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_event_bus.dart`

---

### publishSyncConflictResolved

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_event_bus.dart`

---

### publishNetworkStatusChanged

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_event_bus.dart`

---

### publishSyncQueueStatusChanged

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_event_bus.dart`

---

### publishSyncTriggerFired

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_event_bus.dart`

---

### publishBackendConnectionStatusChanged

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_event_bus.dart`

---

### publishDataChangeDetected

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_event_bus.dart`

---

### publishSyncErrorOccurred

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_event_bus.dart`

---

### dispose

Dispose method to clean up resources

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_event_bus.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_failure_analytics.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_failure_analytics.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_failure_analytics.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_failure_analytics.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_failure_analytics.dart`

---

### startAnalysis

Starts automatic failure analysis

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_failure_analytics.dart`

---

### stopAnalysis

Stops automatic analysis

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_failure_analytics.dart`

---

### classifyFailure

Classifies a specific failure

**Returns:** `FailureClassification`

**Source:** `lib\src\services\usm_sync_failure_analytics.dart`

---

### analyzeFailureTrends

Analyzes failure trends over time

**Returns:** `FailureTrendAnalysis`

**Source:** `lib\src\services\usm_sync_failure_analytics.dart`

---

### FailureTrendAnalysis

**Returns:** `return`

**Source:** `lib\src\services\usm_sync_failure_analytics.dart`

#### Parameters

- **dataPoints** (`dynamic`) (required)

---

### predictFailures

Predicts future failures based on current patterns

**Returns:** `FailurePrediction`

**Source:** `lib\src\services\usm_sync_failure_analytics.dart`

---

### performRootCauseAnalysis

Performs root cause analysis for a failure pattern

**Returns:** `RootCauseAnalysis`

**Source:** `lib\src\services\usm_sync_failure_analytics.dart`

---

### getFailureStatistics

Gets failure statistics by category

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_failure_analytics.dart`

---

### dispose

Disposes the analytics service

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_failure_analytics.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_health_dashboard.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_health_dashboard.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_health_dashboard.dart`

---

### setLayout

Sets dashboard layout and starts data collection

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_health_dashboard.dart`

---

### addWidget

Adds a widget to current layout

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_health_dashboard.dart`

---

### removeWidget

Removes a widget from current layout

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_health_dashboard.dart`

---

### updateWidget

Updates a widget configuration

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_health_dashboard.dart`

---

### getAllWidgetData

Gets current data for all widgets

**Returns:** `Map<String, DashboardData>`

**Source:** `lib\src\services\usm_sync_health_dashboard.dart`

---

### refreshWidget

Manually refreshes a widget

**Returns:** `Future<void>`

**Source:** `lib\src\services\usm_sync_health_dashboard.dart`

---

### refreshAllWidgets

Refreshes all widgets

**Returns:** `Future<void>`

**Source:** `lib\src\services\usm_sync_health_dashboard.dart`

---

### exportDashboard

Exports dashboard configuration

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_health_dashboard.dart`

---

### importDashboard

Imports dashboard configuration

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_health_dashboard.dart`

---

### createOverviewLayout

Creates predefined dashboard layouts

**Returns:** `DashboardLayout`

**Source:** `lib\src\services\usm_sync_health_dashboard.dart`

---

### createPerformanceLayout

**Returns:** `DashboardLayout`

**Source:** `lib\src\services\usm_sync_health_dashboard.dart`

---

### createFailureAnalysisLayout

**Returns:** `DashboardLayout`

**Source:** `lib\src\services\usm_sync_health_dashboard.dart`

---

### DashboardWidgetConfig

**Returns:** `return`

**Source:** `lib\src\services\usm_sync_health_dashboard.dart`

#### Parameters

- **Map<String** (`dynamic`) (required)
- **json** (`dynamic>`) (required)

---

### dispose

Disposes the dashboard

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_health_dashboard.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_logging_service.dart`

---

### toFormattedString

Creates a formatted string representation

**Returns:** `String`

**Source:** `lib\src\services\usm_sync_logging_service.dart`

---

### matches

Checks if a log entry matches this filter

**Returns:** `bool`

**Source:** `lib\src\services\usm_sync_logging_service.dart`

---

### setMinimumLogLevel

Sets minimum log level

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_logging_service.dart`

---

### setCategoryEnabled

Enables or disables specific log categories

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_logging_service.dart`

---

### debug

Logs a debug message

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_logging_service.dart`

---

### info

Logs an info message

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_logging_service.dart`

---

### warning

Logs a warning message

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_logging_service.dart`

---

### error

Logs an error message

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_logging_service.dart`

---

### critical

Logs a critical message

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_logging_service.dart`

---

### logOperationStart

Logs sync operation start

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_logging_service.dart`

---

### logOperationComplete

Logs sync operation completion

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_logging_service.dart`

---

### logConflictDetected

Logs conflict detection

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_logging_service.dart`

---

### logConflictResolved

Logs conflict resolution

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_logging_service.dart`

---

### logNetworkEvent

Logs network events

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_logging_service.dart`

---

### logPerformanceMetric

Logs performance metrics

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_logging_service.dart`

---

### logRecoveryOperation

Logs recovery operations

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_logging_service.dart`

---

### getLogs

Gets filtered log entries

**Returns:** `List<SyncLogEntry>`

**Source:** `lib\src\services\usm_sync_logging_service.dart`

---

### getOperationLogs

Gets logs for a specific operation

**Returns:** `List<SyncLogEntry>`

**Source:** `lib\src\services\usm_sync_logging_service.dart`

---

### getRecentErrors

Gets recent error logs

**Returns:** `List<SyncLogEntry>`

**Source:** `lib\src\services\usm_sync_logging_service.dart`

---

### getLogsByTimeRange

Gets logs for a specific time range

**Returns:** `List<SyncLogEntry>`

**Source:** `lib\src\services\usm_sync_logging_service.dart`

---

### exportLogs

Exports logs to JSON format

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_logging_service.dart`

---

### exportLogsAsText

Exports logs to formatted text

**Returns:** `String`

**Source:** `lib\src\services\usm_sync_logging_service.dart`

---

### clearLogs

Clears in-memory logs

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_logging_service.dart`

---

### getLogStatistics

Gets log statistics

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_logging_service.dart`

---

### dispose

Disposes the logging service

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_logging_service.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_performance_monitor.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_performance_monitor.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_performance_monitor.dart`

---

### startMonitoring

Starts continuous performance monitoring

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_performance_monitor.dart`

---

### stopMonitoring

Stops performance monitoring

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_performance_monitor.dart`

---

### recordNetworkTest

Records network performance test result

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_performance_monitor.dart`

---

### recordBackendTest

Records backend performance test result

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_performance_monitor.dart`

---

### recordMemoryUsage

Records memory usage metrics

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_performance_monitor.dart`

---

### testNetworkPerformance

Performs network latency test

**Returns:** `Future<NetworkPerformanceMetrics>`

**Source:** `lib\src\services\usm_sync_performance_monitor.dart`

---

### testBackendPerformance

Performs backend health check

**Returns:** `Future<BackendPerformanceMetrics>`

**Source:** `lib\src\services\usm_sync_performance_monitor.dart`

---

### getPerformanceSummary

Gets performance summary for a time period

**Returns:** `PerformanceSummary`

**Source:** `lib\src\services\usm_sync_performance_monitor.dart`

---

### updateThresholds

Updates performance thresholds

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_performance_monitor.dart`

---

### dispose

Disposes the monitor

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_performance_monitor.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_performance_monitor.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_performance_monitor.dart`

---

### enqueue

Enqueue a sync operation with specified priority  Adds a sync operation to the appropriate priority queue. Higher priority items are processed first, with intelligent resource allocation to prevent priority inversion.  Example: ```dart final item = SyncQueueItem.create( entityName: 'user_profiles', operation: SyncOperationType.update, data: updatedUserData, priority: SyncPriority.high, );  await queueService.enqueue(item); ```

**Returns:** `Future<void>`

**Source:** `lib\src\services\usm_sync_priority_queue_service.dart`

---

### enqueueBatch

Enqueue multiple items in a batch  Efficiently adds multiple sync operations to their respective priority queues with batch optimization.

**Returns:** `Future<void>`

**Source:** `lib\src\services\usm_sync_priority_queue_service.dart`

---

### dequeue

Dequeue and process the next highest priority item  Removes and returns the next item to be processed based on priority and queue management strategy.

**Returns:** `Future<SyncQueueItem?>`

**Source:** `lib\src\services\usm_sync_priority_queue_service.dart`

---

### completeItem

Complete processing of an item  Marks an item as completed and updates queue state. Successful items are removed from tracking, failed items may be retried or moved to dead letter queue.

**Returns:** `Future<void>`

**Source:** `lib\src\services\usm_sync_priority_queue_service.dart`

---

### failItem

Fail an item and handle retry or dead letter queue logic  Handles items that failed processing, implementing retry logic or moving to dead letter queue based on configuration.

**Returns:** `Future<void>`

**Source:** `lib\src\services\usm_sync_priority_queue_service.dart`

---

### getQueueStatus

Get current queue status for all priorities  Returns detailed status information about all priority queues including counts, processing status, and performance metrics.

**Returns:** `QueueStatus`

**Source:** `lib\src\services\usm_sync_priority_queue_service.dart`

---

### clearQueues

Clear all queues  Removes all pending items from all priority queues. Processing items are allowed to complete.

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_priority_queue_service.dart`

---

### pauseProcessing

Pause queue processing  Stops automatic processing of queue items. Currently processing items will complete.

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_priority_queue_service.dart`

---

### resumeProcessing

Resume queue processing  Restarts automatic processing of queue items.

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_priority_queue_service.dart`

---

### getDeadLetterItems

Get items from dead letter queue  Returns items that failed processing and were moved to the dead letter queue for manual review or reprocessing.

**Returns:** `List<SyncQueueItem>`

**Source:** `lib\src\services\usm_sync_priority_queue_service.dart`

---

### requeueDeadLetterItems

Requeue items from dead letter queue  Moves items from dead letter queue back to appropriate priority queues for retry processing.

**Returns:** `Future<void>`

**Source:** `lib\src\services\usm_sync_priority_queue_service.dart`

---

### dispose

Dispose the service and clean up resources

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_priority_queue_service.dart`

---

### copyWith

Create a copy with modified properties

**Returns:** `SyncQueueItem`

**Source:** `lib\src\services\usm_sync_priority_queue_service.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\services\usm_sync_priority_queue_service.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\services\usm_sync_priority_queue_service.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\services\usm_sync_priority_queue_service.dart`

---

### reset

Reset all statistics

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_priority_queue_service.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\services\usm_sync_priority_queue_service.dart`

---

### acquire

Acquire a permit (wait if none available)

**Returns:** `Future<void>`

**Source:** `lib\src\services\usm_sync_priority_queue_service.dart`

#### Parameters

- **available** (`wait`) (required)

---

### release

Release a permit

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_priority_queue_service.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\services\usm_sync_priority_queue_service.dart`

---

### copyWith

**Returns:** `SyncOperation`

**Source:** `lib\src\services\usm_sync_queue.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\services\usm_sync_queue.dart`

---

### enqueue

Adds an operation to the queue based on its priority

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_queue.dart`

---

### removeOperation

Removes an operation by ID from the queue

**Returns:** `bool`

**Source:** `lib\src\services\usm_sync_queue.dart`

---

### getAllOperations

Returns all operations in the queue (prioritized order)

**Returns:** `List<SyncOperation>`

**Source:** `lib\src\services\usm_sync_queue.dart`

#### Parameters

- **order** (`prioritized`) (required)

---

### getOperationsForCollection

Returns operations for a specific collection

**Returns:** `List<SyncOperation>`

**Source:** `lib\src\services\usm_sync_queue.dart`

---

### getOperationsByPriority

Returns operations by priority

**Returns:** `List<SyncOperation>`

**Source:** `lib\src\services\usm_sync_queue.dart`

---

### clear

Clears all operations from the queue

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_queue.dart`

---

### clearCollection

Clears operations for a specific collection

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_queue.dart`

---

### dispose

Dispose method to clean up resources

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_queue.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_recovery_service.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_recovery_service.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_recovery_service.dart`

---

### createBackup

Creates a backup of sync data

**Returns:** `Future<SyncBackupMetadata>`

**Source:** `lib\src\services\usm_sync_recovery_service.dart`

---

### restoreFromBackup

Restores from backup

**Returns:** `Future<RecoveryOperationResult>`

**Source:** `lib\src\services\usm_sync_recovery_service.dart`

---

### resetSyncState

Resets sync state for entities

**Returns:** `Future<RecoveryOperationResult>`

**Source:** `lib\src\services\usm_sync_recovery_service.dart`

---

### resolveDuplicates

Resolves duplicate records

**Returns:** `Future<RecoveryOperationResult>`

**Source:** `lib\src\services\usm_sync_recovery_service.dart`

---

### repairCorruptedData

Repairs corrupted data

**Returns:** `Future<RecoveryOperationResult>`

**Source:** `lib\src\services\usm_sync_recovery_service.dart`

---

### forceCompleteResync

Forces a complete resync

**Returns:** `Future<RecoveryOperationResult>`

**Source:** `lib\src\services\usm_sync_recovery_service.dart`

---

### dispose

Disposes the recovery service

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_recovery_service.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_replay_service.dart`

---

### copyWith

Creates a copy of this event with modifications

**Returns:** `ReplayEvent`

**Source:** `lib\src\services\usm_sync_replay_service.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_replay_service.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_replay_service.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_replay_service.dart`

---

### matches

Checks if an event matches this filter

**Returns:** `bool`

**Source:** `lib\src\services\usm_sync_replay_service.dart`

---

### startRecording

Starts recording sync events

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_replay_service.dart`

---

### stopRecording

Stops recording sync events

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_replay_service.dart`

---

### recordEvent

Records a sync event

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_replay_service.dart`

---

### recordSyncOperation

Records a sync operation for replay

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_replay_service.dart`

---

### getEvents

Gets replay events with optional filtering

**Returns:** `List<ReplayEvent>`

**Source:** `lib\src\services\usm_sync_replay_service.dart`

---

### getOperationEvents

Gets events for a specific operation ID

**Returns:** `List<ReplayEvent>`

**Source:** `lib\src\services\usm_sync_replay_service.dart`

---

### getEventsByTimeRange

Gets events for a specific time range

**Returns:** `List<ReplayEvent>`

**Source:** `lib\src\services\usm_sync_replay_service.dart`

---

### getFailedEvents

Gets failed events only

**Returns:** `List<ReplayEvent>`

**Source:** `lib\src\services\usm_sync_replay_service.dart`

---

### getSuccessfulEvents

Gets successful events only

**Returns:** `List<ReplayEvent>`

**Source:** `lib\src\services\usm_sync_replay_service.dart`

---

### replayEvent

Replays a single event

**Returns:** `Future<ReplayExecutionResult>`

**Source:** `lib\src\services\usm_sync_replay_service.dart`

---

### replayEvents

Replays multiple events in sequence

**Returns:** `Future<ReplaySessionSummary>`

**Source:** `lib\src\services\usm_sync_replay_service.dart`

---

### replayTimeRange

Replays events from a specific time range

**Returns:** `Future<ReplaySessionSummary>`

**Source:** `lib\src\services\usm_sync_replay_service.dart`

---

### replayFailedEvents

Replays failed events only

**Returns:** `Future<ReplaySessionSummary>`

**Source:** `lib\src\services\usm_sync_replay_service.dart`

---

### replayOperation

Replays events for a specific operation

**Returns:** `Future<ReplaySessionSummary>`

**Source:** `lib\src\services\usm_sync_replay_service.dart`

---

### exportEvents

Exports replay events to JSON

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_replay_service.dart`

---

### importEvents

Imports replay events from JSON

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_replay_service.dart`

---

### getReplayStatistics

Gets replay statistics

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_replay_service.dart`

---

### clearHistory

Clears replay history

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_replay_service.dart`

---

### dispose

Disposes the replay service

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_replay_service.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_rollback_service.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_rollback_service.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_rollback_service.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_rollback_service.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_rollback_service.dart`

---

### createCheckpoint

Creates a new rollback checkpoint

**Returns:** `Future<RollbackCheckpoint>`

**Source:** `lib\src\services\usm_sync_rollback_service.dart`

---

### listCheckpoints

Lists available checkpoints

**Returns:** `List<RollbackCheckpoint>`

**Source:** `lib\src\services\usm_sync_rollback_service.dart`

---

### createRollbackPlan

Creates a rollback plan

**Returns:** `Future<RollbackPlan>`

**Source:** `lib\src\services\usm_sync_rollback_service.dart`

---

### executeRollback

Executes a rollback plan

**Returns:** `Future<RollbackOperationResult>`

**Source:** `lib\src\services\usm_sync_rollback_service.dart`

---

### rollbackToCheckpoint

Rolls back to a specific checkpoint

**Returns:** `Future<RollbackOperationResult>`

**Source:** `lib\src\services\usm_sync_rollback_service.dart`

---

### rollbackTimeRange

Rolls back changes within a time range

**Returns:** `Future<RollbackOperationResult>`

**Source:** `lib\src\services\usm_sync_rollback_service.dart`

---

### undoLastSync

Undoes the last sync operation

**Returns:** `Future<RollbackOperationResult>`

**Source:** `lib\src\services\usm_sync_rollback_service.dart`

---

### undoEntityChanges

Undoes changes to specific entities

**Returns:** `Future<RollbackOperationResult>`

**Source:** `lib\src\services\usm_sync_rollback_service.dart`

---

### detectRollbackConflicts

Detects conflicts between multiple rollback operations

**Returns:** `List<RollbackConflict>`

**Source:** `lib\src\services\usm_sync_rollback_service.dart`

---

### deleteCheckpoint

Deletes a specific checkpoint

**Returns:** `Future<bool>`

**Source:** `lib\src\services\usm_sync_rollback_service.dart`

---

### getRollbackStatistics

Gets rollback service statistics

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_rollback_service.dart`

---

### dispose

Disposes the rollback service

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_rollback_service.dart`

---

### copyWith

**Returns:** `SyncScheduleConfig`

**Source:** `lib\src\services\usm_sync_scheduler.dart`

---

### toDateTime

Converts to DateTime for today

**Returns:** `DateTime`

**Source:** `lib\src\services\usm_sync_scheduler.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\services\usm_sync_scheduler.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\services\usm_sync_scheduler.dart`

---

### updateConfig

Updates the scheduler configuration

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_scheduler.dart`

---

### start

Starts the scheduler

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_scheduler.dart`

---

### pause

Pauses the scheduler

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_scheduler.dart`

---

### resume

Resumes the scheduler

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_scheduler.dart`

---

### stop

Stops the scheduler

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_scheduler.dart`

---

### triggerManualSync

Schedules a manual sync

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_scheduler.dart`

---

### scheduleSync

Schedules a sync with specific delay

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_scheduler.dart`

---

### scheduleRetry

Schedules a retry after sync failure

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_scheduler.dart`

---

### notifySyncSuccess

Notifies about successful sync (resets retry counter)

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_scheduler.dart`

#### Parameters

- **counter** (`resets`) (required)

---

### updateNetworkCondition

Updates network condition

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_scheduler.dart`

---

### updateBatteryCondition

Updates battery condition

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_scheduler.dart`

---

### notifyDataChange

Notifies about data changes

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_scheduler.dart`

---

### dispose

Dispose method to clean up resources

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_scheduler.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_state_inspector.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_state_inspector.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_state_inspector.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_state_inspector.dart`

---

### toJson

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_sync_state_inspector.dart`

---

### getCurrentSystemState

Gets current system state

**Returns:** `Future<SyncSystemState>`

**Source:** `lib\src\services\usm_sync_state_inspector.dart`

---

### getEntityState

Gets state for a specific entity type

**Returns:** `Future<SyncEntityState>`

**Source:** `lib\src\services\usm_sync_state_inspector.dart`

---

### dispose

Disposes the inspector

**Returns:** `void`

**Source:** `lib\src\services\usm_sync_state_inspector.dart`

---

### copyWith

**Returns:** `SyncOperationConfig`

**Source:** `lib\src\services\usm_universal_sync_operation_service.dart`

---

### copyWith

**Returns:** `SyncProgress`

**Source:** `lib\src\services\usm_universal_sync_operation_service.dart`

---

### toString

**Returns:** `String`

**Source:** `lib\src\services\usm_universal_sync_operation_service.dart`

---

### copyWith

**Returns:** `SyncEntityConfig`

**Source:** `lib\src\services\usm_universal_sync_operation_service.dart`

---

### updateConfig

Updates the operation configuration

**Returns:** `void`

**Source:** `lib\src\services\usm_universal_sync_operation_service.dart`

---

### registerEntity

Registers an entity for sync operations

**Returns:** `void`

**Source:** `lib\src\services\usm_universal_sync_operation_service.dart`

---

### unregisterEntity

Unregisters an entity

**Returns:** `void`

**Source:** `lib\src\services\usm_universal_sync_operation_service.dart`

---

### queueOperation

Queues a sync operation

**Returns:** `Future<SyncResult>`

**Source:** `lib\src\services\usm_universal_sync_operation_service.dart`

---

### syncCollection

Performs a manual sync for a specific collection

**Returns:** `Future<SyncResult>`

**Source:** `lib\src\services\usm_universal_sync_operation_service.dart`

---

### pause

Pauses sync operations

**Returns:** `void`

**Source:** `lib\src\services\usm_universal_sync_operation_service.dart`

---

### resume

Resumes sync operations

**Returns:** `void`

**Source:** `lib\src\services\usm_universal_sync_operation_service.dart`

---

### stop

Stops all sync operations

**Returns:** `void`

**Source:** `lib\src\services\usm_universal_sync_operation_service.dart`

---

### getStatus

Gets current sync status

**Returns:** `Map<String, dynamic>`

**Source:** `lib\src\services\usm_universal_sync_operation_service.dart`

---

### getAllProgress

Gets all active progress trackers

**Returns:** `Map<String, SyncProgress>`

**Source:** `lib\src\services\usm_universal_sync_operation_service.dart`

---

### dispose

Dispose method to clean up resources

**Returns:** `void`

**Source:** `lib\src\services\usm_universal_sync_operation_service.dart`

---

### main

**Returns:** `void`

**Source:** `lib\usm_task3_2_test.dart`

---

### main

Main entry point for Task 4.1 demo

**Returns:** `Future<void>`

**Source:** `lib\usm_task4_1_test.dart`

---

