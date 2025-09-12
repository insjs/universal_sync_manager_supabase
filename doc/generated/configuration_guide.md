# Configuration Guide

This guide covers all configuration options available in Universal Sync Manager, including the new Phase 3 App Integration Framework.

## Phase 3: App Integration Framework Configuration

### MyAppSyncManager Configuration

The `MyAppSyncManager` provides a simplified, high-level API for easy integration.

#### Basic Configuration

```dart
await MyAppSyncManager.initialize(
  backendAdapter: PocketBaseSyncAdapter(
    configuration: SyncBackendConfiguration(
      configId: 'main-backend',
      backendType: 'pocketbase',
      baseUrl: 'https://your-backend.com',
      projectId: 'your-app-id',
    ),
  ),
  publicCollections: ['announcements', 'public_data'],
  autoSync: true,
  syncInterval: Duration(seconds: 30),
);
```

#### Configuration Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `backendAdapter` | `ISyncBackendAdapter` | Yes | - | Backend adapter instance |
| `publicCollections` | `List<String>` | No | `[]` | Collections accessible without auth |
| `autoSync` | `bool` | No | `true` | Enable automatic sync |
| `syncInterval` | `Duration` | No | `30 seconds` | Sync frequency |

---

### Backend Adapter Configuration

#### SyncBackendConfiguration

Core configuration class for all backend adapters.

```dart
final config = SyncBackendConfiguration(
  configId: 'unique-config-id',
  displayName: 'Human-readable name',
  backendType: 'pocketbase', // 'pocketbase', 'supabase', 'firebase'
  baseUrl: 'https://your-backend.com',
  projectId: 'your-project-id',
  connectionTimeout: Duration(seconds: 30),
  requestTimeout: Duration(seconds: 15),
  maxRetries: 3,
  environment: 'production', // 'development', 'staging', 'production'
  customHeaders: {
    'X-App-Version': '1.0.0',
  },
  enableLogging: true,
  logLevel: 'info', // 'debug', 'info', 'warning', 'error'
);
```

#### Configuration Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `configId` | `String` | Yes | - | Unique identifier for this config |
| `displayName` | `String` | No | - | Human-readable name |
| `backendType` | `String` | Yes | - | Backend type identifier |
| `baseUrl` | `String` | Yes | - | Backend base URL |
| `projectId` | `String` | Yes | - | Project/database identifier |
| `connectionTimeout` | `Duration` | No | `30s` | Connection timeout |
| `requestTimeout` | `Duration` | No | `15s` | Request timeout |
| `maxRetries` | `int` | No | `3` | Maximum retry attempts |
| `environment` | `String` | No | `'production'` | Environment identifier |
| `customHeaders` | `Map<String, String>` | No | `{}` | Additional HTTP headers |
| `enableLogging` | `bool` | No | `false` | Enable request logging |
| `logLevel` | `String` | No | `'info'` | Logging level |

---

### Auth Provider Integration Configuration

#### Firebase Auth Integration

```dart
// Basic Firebase integration
FirebaseAuth.instance.authStateChanges().listen((user) {
  if (user != null) {
    FirebaseAuthIntegration.syncWithUSM(user);
  } else {
    MyAppSyncManager.instance.logout();
  }
});

// Advanced Firebase integration
final integration = AdvancedFirebaseAuthIntegration(
  extractCustomClaims: (user) async {
    final idToken = await user.getIdTokenResult();
    return idToken.claims;
  },
  onAuthStateChange: (user, claims) {
    print('Firebase user: ${user?.uid}');
  },
);
```

#### Supabase Auth Integration

```dart
// Basic Supabase integration
supabase.auth.onAuthStateChange.listen((data) {
  final user = data.user;
  if (user != null) {
    SupabaseAuthIntegration.syncWithUSM(user);
  }
});

// Advanced Supabase integration with RLS
final integration = AdvancedSupabaseAuthIntegration(
  supabaseClient: Supabase.instance.client,
  onAuthStateChange: (user, session) {
    print('Supabase user: ${user?.id}');
  },
);

// Set RLS context
integration.setRLSContext({
  'organization_id': 'org123',
  'role': 'admin',
});
```

#### Auth0 Integration

```dart
final integration = AdvancedAuth0Integration(
  domain: 'your-domain.auth0.com',
  clientId: 'your-client-id',
  onTokenRefresh: (newToken) {
    print('Auth0 token refreshed: $newToken');
  },
);
```

---

### State Management Integration Configuration

#### Riverpod Configuration

```dart
// StateNotifier pattern (Riverpod 1.x)
final authProvider = StateNotifierProvider<AuthSyncNotifier, RiverpodAuthSyncState>((ref) {
  final notifier = AuthSyncNotifier();
  notifier.initialize();
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

// AsyncNotifier pattern (Riverpod 2.0+)
final authAsyncProvider = AsyncNotifierProvider<AuthSyncAsyncNotifier, RiverpodAuthSyncState>(() {
  return AuthSyncAsyncNotifier();
});
```

#### Bloc Configuration

```dart
class MyAppBloc extends Bloc<AppEvent, AppState> with AuthSyncBlocMixin {
  MyAppBloc() : super(AppInitial()) {
    initializeAuthSync(); // Initialize USM integration
  }
  
  @override
  Future<void> close() {
    disposeAuthSync(); // Clean up USM integration
    return super.close();
  }
}
```

#### GetX Configuration

```dart
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    final controller = AuthSyncController();
    controller.initialize();
    Get.put<AuthSyncController>(controller);
  }
}
```

#### Provider Configuration

```dart
Provider<AuthSyncProvider>(
  create: (context) {
    final provider = AuthSyncProvider();
    provider.initialize();
    return provider;
  },
  dispose: (context, provider) => provider.dispose(),
  child: MyApp(),
)
```

---

### Auth Lifecycle Management Configuration

#### Session Management

```dart
final lifecycleManager = AuthLifecycleManager();

await lifecycleManager.initialize(
  sessionTimeoutDuration: Duration(hours: 8),
  refreshThreshold: Duration(minutes: 5),
  warningThreshold: Duration(minutes: 10),
);

// Start automatic token refresh
lifecycleManager.startTokenRefreshCoordination();
```

#### Session Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `sessionTimeoutDuration` | `Duration` | `8 hours` | Session timeout duration |
| `refreshThreshold` | `Duration` | `5 minutes` | Token refresh threshold |
| `warningThreshold` | `Duration` | `10 minutes` | Session warning threshold |

#### Token Refresh Coordination

```dart
final coordinator = TokenRefreshCoordinator();

coordinator.initialize([
  FirebaseTokenRefreshProvider(),
  SupabaseTokenRefreshProvider(),
  Auth0TokenRefreshProvider(),
]);

coordinator.startCoordination();
```

---

### Production Configuration

#### Recommended Production Settings

```dart
await MyAppSyncManager.initialize(
  backendAdapter: PocketBaseSyncAdapter(
    configuration: SyncBackendConfiguration(
      configId: 'production-backend',
      backendType: 'pocketbase',
      baseUrl: 'https://api.yourapp.com',
      projectId: 'yourapp-prod',
      connectionTimeout: Duration(seconds: 30),
      requestTimeout: Duration(seconds: 15),
      maxRetries: 3,
      environment: 'production',
      enableLogging: false, // Disable in production
      customHeaders: {
        'X-App-Version': '1.0.0',
        'X-Platform': Platform.operatingSystem,
      },
    ),
  ),
  publicCollections: [
    'announcements',
    'app_config',
    'public_data',
  ],
  autoSync: true,
  syncInterval: Duration(minutes: 5), // Less frequent in production
);
```

#### Security Considerations

1. **Disable Logging**: Set `enableLogging: false` in production
2. **Environment Tagging**: Use `environment: 'production'` for proper tracking
3. **Custom Headers**: Include app version and platform for analytics
4. **Timeout Values**: Use conservative timeout values for reliability
5. **Public Collections**: Minimize public collections for security

---

## Auto-Generated Configuration Reference

This guide covers all configuration options available in Universal Sync Manager.

## Lib\src\config\usm Entity Discovery

### entityName

**Type:** `String`

**Required:** Yes

---

### tableName

**Type:** `String`

**Required:** Yes

**Default:** `''`

---

### className

**Type:** `String`

**Required:** Yes

---

### discoveryMethod

**Type:** `EntityDiscoveryMethod`

**Required:** Yes

---

### annotations

**Type:** `List<EntityAnnotation>`

**Required:** Yes

**Default:** `const []`

---

### fields

**Type:** `List<FieldInfo>`

**Required:** Yes

**Default:** `const []`

---

### hasAuditFields

**Type:** `bool`

**Required:** Yes

**Default:** `false`

---

### hasSyncFields

**Type:** `bool`

**Required:** Yes

**Default:** `false`

---

### requiresAuthentication

**Type:** `bool`

**Required:** Yes

**Default:** `true`

---

### tableName

**Type:** `String`

**Required:** Yes

**Default:** `''`

---

### className

**Type:** `String`

**Required:** Yes

---

### requiresAuthentication

**Type:** `bool`

**Required:** Yes

**Default:** `true`

---

### annotations

**Type:** `List<EntityAnnotation>`

**Required:** Yes

**Default:** `const []`

---

### fields

**Type:** `List<FieldInfo>`

**Required:** Yes

**Default:** `const []`

---

### tableName

**Type:** `String`

**Required:** Yes

**Default:** `''`

---

### requiresAuthentication

**Type:** `bool`

**Required:** Yes

**Default:** `true`

---

### priority

**Type:** `SyncPriority`

**Required:** Yes

**Default:** `_determinePriority(tableName)`

---

### conflictStrategy

**Type:** `ConflictResolutionStrategy`

**Required:** Yes

**Default:** `ConflictResolutionStrategy.timestampWins`

---

### tableName

**Type:** `String`

**Required:** Yes

**Default:** `''`

---

### enableRealTime

**Type:** `bool`

**Required:** Yes

**Default:** `true`

---

### enableDeltaSync

**Type:** `bool`

**Required:** Yes

**Default:** `true`

---

### exclude

**Type:** `bool`

**Required:** Yes

**Default:** `false`

---

### encrypt

**Type:** `bool`

**Required:** Yes

**Default:** `false`

---

### mapping

**Type:** `String`

**Required:** Yes

**Default:** `''`

---

### name

**Type:** `String`

**Required:** Yes

---

### type

**Type:** `String`

**Required:** Yes

---

### isNullable

**Type:** `bool`

**Required:** Yes

**Default:** `false`

---

### isPrimaryKey

**Type:** `bool`

**Required:** Yes

**Default:** `false`

---

### isForeignKey

**Type:** `bool`

**Required:** Yes

**Default:** `false`

---

### defaultValue

**Type:** `dynamic`

**Required:** Yes

---

### annotations

**Type:** `List<EntityAnnotation>`

**Required:** Yes

**Default:** `const []`

---

### name

**Type:** `String`

**Required:** Yes

---

### columns

**Type:** `List<ColumnInfo>`

**Required:** Yes

---

### name

**Type:** `String`

**Required:** Yes

---

### type

**Type:** `String`

**Required:** Yes

---

### isNullable

**Type:** `bool`

**Required:** Yes

**Default:** `false`

---

### isPrimaryKey

**Type:** `bool`

**Required:** Yes

**Default:** `false`

---

### isForeignKey

**Type:** `bool`

**Required:** Yes

**Default:** `false`

---

### defaultValue

**Type:** `dynamic`

**Required:** Yes

---

## Lib\src\config\usm Field Mapping Config

### fieldMappings

**Type:** `Map<String, String>`

**Required:** Yes

**Default:** `const {`

**Description:** Mapping from local field names to remote field names

---

### fieldTransformations

**Type:** `Map<String, FieldTransformation>`

**Required:** Yes

**Default:** `const {`

**Description:** Field transformations for data conversion

---

### fieldValidations

**Type:** `Map<String, FieldValidation>`

**Required:** Yes

**Default:** `const {`

**Description:** Field validation rules

---

### excludedFields

**Type:** `List<String>`

**Required:** Yes

**Default:** `const []`

**Description:** Fields to exclude from synchronization

---

### requiredFields

**Type:** `List<String>`

**Required:** Yes

**Default:** `const []`

**Description:** Fields that are required for synchronization

---

### encryptedFields

**Type:** `List<String>`

**Required:** Yes

**Default:** `const []`

**Description:** Fields that should be encrypted

---

### defaultValues

**Type:** `Map<String, dynamic>`

**Required:** Yes

**Default:** `const {`

**Description:** Default values for fields

---

### fieldTypes

**Type:** `Map<String, FieldType>`

**Required:** Yes

**Default:** `const {`

**Description:** Field type mappings

---

### customRules

**Type:** `Map<String, CustomMappingRule>`

**Required:** Yes

**Default:** `const {`

**Description:** Custom mapping rules

---

### enableAutoMapping

**Type:** `bool`

**Required:** Yes

**Default:** `true`

**Description:** Enable automatic field mapping based on conventions

---

### strictTypeChecking

**Type:** `bool`

**Required:** Yes

**Default:** `false`

**Description:** Enable strict type checking during mapping

---

### allowNullValues

**Type:** `bool`

**Required:** Yes

**Default:** `true`

**Description:** Allow null values in field mappings

---

### preserveCase

**Type:** `bool`

**Required:** Yes

**Default:** `false`

**Description:** Preserve field name case during mapping

---

### type

**Type:** `TransformationType`

**Required:** Yes

**Description:** Type of transformation to apply

---

### parameters

**Type:** `Map<String, dynamic>`

**Required:** Yes

**Default:** `const {`

**Description:** Parameters for the transformation

---

### applyOnRead

**Type:** `bool`

**Required:** Yes

**Default:** `true`

**Description:** Apply transformation when reading from backend

---

### applyOnWrite

**Type:** `bool`

**Required:** Yes

**Default:** `true`

**Description:** Apply transformation when writing to backend

---

### required

**Type:** `bool`

**Required:** Yes

**Default:** `false`

**Description:** Field is required

---

### name

**Type:** `String`

**Required:** Yes

**Default:** `= value)`

**Description:** Rule name

---

### description

**Type:** `String`

**Required:** Yes

**Description:** Rule description

---

### conditions

**Type:** `Map<String, dynamic>`

**Required:** Yes

**Default:** `const {`

**Description:** Conditions for applying the rule

---

### actions

**Type:** `Map<String, dynamic>`

**Required:** Yes

**Default:** `const {`

**Description:** Actions to perform when rule matches

---

### enabled

**Type:** `bool`

**Required:** Yes

**Default:** `true`

**Description:** Rule is enabled

---

### isValid

**Type:** `bool`

**Required:** Yes

**Description:** Validation passed

---

### errors

**Type:** `List<String>`

**Required:** Yes

**Default:** `<String>[]`

**Description:** Validation errors

---

## Lib\src\config\usm Sync Config Serializer

### universalConfig

**Type:** `UniversalSyncConfig`

**Required:** Yes

**Default:** `UniversalSyncConfig.fromJson(
      migratedJson['universalConfig'] as Map<String`

---

### entityRegistry

**Type:** `SyncEntityRegistry`

**Required:** Yes

**Default:** `SyncEntityRegistry()`

---

### version

**Type:** `int`

**Required:** Yes

**Default:** `json['version'] as int? ?? 1`

---

### timestamp

**Type:** `DateTime`

**Required:** Yes

---

### metadata

**Type:** `Map<String, dynamic>`

**Required:** Yes

**Default:** `const {`

---

### isValid

**Type:** `bool`

**Required:** Yes

---

### errors

**Type:** `List<String>`

**Required:** Yes

**Default:** `<String>[]`

---

### warnings

**Type:** `List<String>`

**Required:** Yes

**Default:** `<String>[]`

---

### message

**Type:** `String`

**Required:** Yes

---

## Lib\src\config\usm Sync Config Validator

### field

**Type:** `String`

**Required:** Yes

---

### message

**Type:** `String`

**Required:** Yes

---

### severity

**Type:** `ValidationSeverity`

**Required:** Yes

---

### isValid

**Type:** `bool`

**Required:** Yes

---

### errors

**Type:** `List<ValidationError>`

**Required:** Yes

**Default:** `<ValidationError>[]`

---

### warnings

**Type:** `List<ValidationWarning>`

**Required:** Yes

**Default:** `<ValidationWarning>[]`

---

### entityName

**Type:** `String`

**Required:** Yes

---

### isValid

**Type:** `bool`

**Required:** Yes

---

### errors

**Type:** `List<ValidationError>`

**Required:** Yes

**Default:** `<ValidationError>[]`

---

### warnings

**Type:** `List<ValidationWarning>`

**Required:** Yes

**Default:** `<ValidationWarning>[]`

---

### isValid

**Type:** `bool`

**Required:** Yes

---

### entityResults

**Type:** `Map<String, SyncEntityConfigValidationResult>`

**Required:** Yes

---

### globalErrors

**Type:** `List<ValidationError>`

**Required:** Yes

**Default:** `<ValidationError>[]`

---

### globalWarnings

**Type:** `List<ValidationWarning>`

**Required:** Yes

**Default:** `<ValidationWarning>[]`

---

### isValid

**Type:** `bool`

**Required:** Yes

---

### universalConfigResult

**Type:** `SyncConfigValidationResult`

**Required:** Yes

---

### entityRegistryResult

**Type:** `SyncEntityRegistryValidationResult`

**Required:** Yes

---

### systemErrors

**Type:** `List<ValidationError>`

**Required:** Yes

**Default:** `<ValidationError>[]`

---

### systemWarnings

**Type:** `List<ValidationWarning>`

**Required:** Yes

**Default:** `<ValidationWarning>[]`

---

## Lib\src\config\usm Sync Entity Config

### tableName

**Type:** `String`

**Required:** Yes

**Default:** `= tableName &&
        other.requiresAuthentication == requiresAuthentication`

**Description:** Name of the table/collection in the backend

---

### requiresAuthentication

**Type:** `bool`

**Required:** Yes

**Default:** `false`

**Description:** Whether this entity requires authentication to access

---

### enableRealTime

**Type:** `bool`

**Required:** Yes

**Default:** `true`

**Description:** Whether this entity supports real-time updates

---

### enableDeltaSync

**Type:** `bool`

**Required:** Yes

**Default:** `true`

**Description:** Whether to enable delta sync for this entity

---

### syncOffline

**Type:** `bool`

**Required:** Yes

**Default:** `true`

**Description:** Whether this entity should be synced in offline mode

---

### excludedFields

**Type:** `List<String>`

**Required:** Yes

**Default:** `const []`

**Description:** Custom fields that should be excluded from sync

---

### requiredFields

**Type:** `List<String>`

**Required:** Yes

**Default:** `const []`

**Description:** Custom fields that are required for sync

---

### validateBeforeSync

**Type:** `bool`

**Required:** Yes

**Default:** `true`

**Description:** Whether to validate data before syncing

---

### validationRules

**Type:** `Map<String, dynamic>`

**Required:** Yes

**Default:** `const {`

**Description:** Custom validation rules for this entity

---

### fieldMappings

**Type:** `Map<String, String>`

**Required:** Yes

**Default:** `const {`

**Description:** Transformation rules for field mapping

---

### enableEncryption

**Type:** `bool`

**Required:** Yes

**Default:** `false`

**Description:** Whether to enable encryption for this entity

---

### encryptionSettings

**Type:** `Map<String, dynamic>`

**Required:** Yes

**Default:** `const {`

**Description:** Custom encryption settings

---

### trackChanges

**Type:** `bool`

**Required:** Yes

**Default:** `true`

**Description:** Whether to track changes for this entity

---

### queryFilters

**Type:** `Map<String, dynamic>`

**Required:** Yes

**Default:** `const {`

**Description:** Custom query filters for this entity

---

### enableCaching

**Type:** `bool`

**Required:** Yes

**Default:** `true`

**Description:** Whether to enable caching for this entity

---

### enableCompression

**Type:** `bool`

**Required:** Yes

**Default:** `false`

**Description:** Whether to enable compression for this entity

---

### customSettings

**Type:** `Map<String, dynamic>`

**Required:** Yes

**Default:** `const {`

**Description:** Custom settings specific to this entity

---

## Lib\src\config\usm Sync Strategies

### name

**Type:** `String`

**Required:** Yes

**Default:** `= key)`

**Description:** Strategy name

---

### description

**Type:** `String`

**Required:** Yes

**Description:** Strategy description

---

### priority

**Type:** `SyncPriority`

**Required:** Yes

**Default:** `SyncPriority.normal`

**Description:** Strategy priority

---

### enabled

**Type:** `bool`

**Required:** Yes

**Default:** `true`

**Description:** Strategy is enabled

---

### metadata

**Type:** `Map<String, dynamic>`

**Required:** Yes

**Default:** `const {`

---

### status

**Type:** `SyncStrategyStatus`

**Required:** Yes

**Default:** `= SyncStrategyStatus.success`

---

### error

**Type:** `dynamic`

**Required:** Yes

---

### action

**Type:** `ConflictResolutionAction`

**Required:** Yes

---

### isSuccess

**Type:** `bool`

**Required:** Yes

**Default:** `> status == SyncStrategyStatus.success`

---

### error

**Type:** `dynamic`

**Required:** Yes

---

### localData

**Type:** `Map<String, dynamic>`

**Required:** Yes

**Default:** `conflict.localData`

---

### remoteData

**Type:** `Map<String, dynamic>`

**Required:** Yes

**Default:** `conflict.remoteData`

---

### fieldConflicts

**Type:** `Map<String, dynamic>`

**Required:** Yes

**Default:** `const {`

---

## Lib\src\config\usm Universal Sync Config

### projectId

**Type:** `String`

**Required:** Yes

**Default:** `= projectId &&
        other.syncMode == syncMode &&
        other.environment == environment`

**Description:** Unique identifier for this sync project

---

### syncMode

**Type:** `SyncMode`

**Required:** Yes

**Default:** `SyncMode.automatic`

**Description:** How the sync manager should operate

---

### syncInterval

**Type:** `Duration`

**Required:** Yes

**Default:** `const Duration(minutes: 15)`

**Description:** Interval between automatic sync operations

---

### defaultConflictStrategy

**Type:** `ConflictResolutionStrategy`

**Required:** Yes

**Default:** `ConflictResolutionStrategy.timestampWins`

**Description:** Default strategy for resolving conflicts

---

### maxRetries

**Type:** `int`

**Required:** Yes

**Default:** `3`

**Description:** Maximum number of retry attempts for failed operations

---

### retryDelay

**Type:** `Duration`

**Required:** Yes

**Default:** `const Duration(seconds: 5)`

**Description:** Delay between retry attempts

---

### retryStrategy

**Type:** `RetryStrategy`

**Required:** Yes

**Default:** `RetryStrategy.exponential`

**Description:** Strategy for retry timing

---

### enableCompression

**Type:** `bool`

**Required:** Yes

**Default:** `true`

**Description:** Whether to enable compression for sync payloads

---

### compressionType

**Type:** `CompressionType`

**Required:** Yes

**Default:** `CompressionType.gzip`

**Description:** Type of compression to use

---

### enableDeltaSync

**Type:** `bool`

**Required:** Yes

**Default:** `true`

**Description:** Whether to enable delta sync for incremental updates

---

### defaultPriority

**Type:** `SyncPriority`

**Required:** Yes

**Default:** `SyncPriority.normal`

**Description:** Default priority for sync operations

---

### backendConfig

**Type:** `Map<String, dynamic>`

**Required:** Yes

**Default:** `const {`

**Description:** Backend-specific configuration settings

---

### platformOptimizations

**Type:** `PlatformOptimizations`

**Required:** Yes

**Default:** `const PlatformOptimizations()`

**Description:** Platform-specific optimizations

---

### publicEntities

**Type:** `List<String>`

**Required:** Yes

**Default:** `const []`

**Description:** Authentication-based entity categorization

---

### protectedEntities

**Type:** `List<String>`

**Required:** Yes

**Default:** `const []`

**Description:** Entities that require authentication

---

### maxBatchSize

**Type:** `int`

**Required:** Yes

**Default:** `100`

**Description:** Maximum size for batch operations

---

### operationTimeout

**Type:** `Duration`

**Required:** Yes

**Default:** `const Duration(minutes: 5)`

**Description:** Timeout for sync operations

---

### connectionTimeout

**Type:** `Duration`

**Required:** Yes

**Default:** `const Duration(seconds: 30)`

**Description:** Timeout for connection attempts

---

### enableRealTimeSync

**Type:** `bool`

**Required:** Yes

**Default:** `true`

**Description:** Whether to enable real-time subscriptions

---

### maxConcurrentOperations

**Type:** `int`

**Required:** Yes

**Default:** `5`

**Description:** Maximum number of concurrent sync operations

---

### environment

**Type:** `SyncEnvironment`

**Required:** Yes

**Default:** `SyncEnvironment.development`

**Description:** Environment this configuration is for

---

### logLevel

**Type:** `LogLevel`

**Required:** Yes

**Default:** `LogLevel.info`

**Description:** Logging level for sync operations

---

### enablePerformanceMonitoring

**Type:** `bool`

**Required:** Yes

**Default:** `false`

**Description:** Whether to enable performance monitoring

---

### enableAnalytics

**Type:** `bool`

**Required:** Yes

**Default:** `false`

**Description:** Whether to enable sync analytics

---

### customSettings

**Type:** `Map<String, dynamic>`

**Required:** Yes

**Default:** `const {`

**Description:** Custom configuration options for specific use cases

---

### networkSettings

**Type:** `NetworkSettings`

**Required:** Yes

**Default:** `const NetworkSettings()`

**Description:** Network-specific settings

---

### securitySettings

**Type:** `SecuritySettings`

**Required:** Yes

**Default:** `const SecuritySettings()`

**Description:** Security settings

---

### offlineSettings

**Type:** `OfflineSettings`

**Required:** Yes

**Default:** `const OfflineSettings()`

**Description:** Offline mode settings

---

### enableDatabaseOptimizations

**Type:** `bool`

**Required:** Yes

**Default:** `true`

**Description:** Whether to enable platform-specific database optimizations

---

### usePlatformNetworking

**Type:** `bool`

**Required:** Yes

**Default:** `true`

**Description:** Whether to use platform-specific networking

---

### maxCacheMemoryMB

**Type:** `int`

**Required:** Yes

**Default:** `100`

**Description:** Maximum memory usage for caching (in MB)

---

### enableBackgroundSync

**Type:** `bool`

**Required:** Yes

**Default:** `false`

**Description:** Whether to enable background sync on mobile platforms

---

### respectBatteryOptimization

**Type:** `bool`

**Required:** Yes

**Default:** `true`

**Description:** Whether to respect battery optimization settings

---

### wifiOnlySync

**Type:** `bool`

**Required:** Yes

**Default:** `false`

**Description:** Whether to use WiFi-only sync mode

---

### customPlatformSettings

**Type:** `Map<String, dynamic>`

**Required:** Yes

**Default:** `const {`

**Description:** Custom platform-specific settings

---

### requestTimeout

**Type:** `Duration`

**Required:** Yes

**Default:** `const Duration(seconds: 30)`

**Description:** Maximum time to wait for network requests

---

### autoRetryOnNetworkError

**Type:** `bool`

**Required:** Yes

**Default:** `true`

**Description:** Whether to automatically retry on network errors

---

### minNetworkQuality

**Type:** `NetworkCondition`

**Required:** Yes

**Default:** `NetworkCondition.limited`

**Description:** Minimum network quality required for sync

---

### allowCellularSync

**Type:** `bool`

**Required:** Yes

**Default:** `true`

**Description:** Whether to use cellular data for sync

---

### maxBandwidthKBps

**Type:** `int`

**Required:** Yes

**Default:** `1024`

**Description:** Maximum bandwidth usage per sync operation (in KB/s)

---

### enableRequestCompression

**Type:** `bool`

**Required:** Yes

**Default:** `true`

**Description:** Whether to enable request compression

---

### enableEncryption

**Type:** `bool`

**Required:** Yes

**Default:** `false`

**Description:** Whether to enable end-to-end encryption

---

### defaultSecurityLevel

**Type:** `SecurityLevel`

**Required:** Yes

**Default:** `SecurityLevel.internal`

**Description:** Security level for sensitive data

---

### validateSSLCertificates

**Type:** `bool`

**Required:** Yes

**Default:** `true`

**Description:** Whether to validate SSL certificates

---

### enableRequestSigning

**Type:** `bool`

**Required:** Yes

**Default:** `false`

**Description:** Whether to enable request signing

---

### customSecuritySettings

**Type:** `Map<String, dynamic>`

**Required:** Yes

**Default:** `const {`

**Description:** Custom security settings

---

### enableOfflineMode

**Type:** `bool`

**Required:** Yes

**Default:** `true`

**Description:** Whether to enable offline mode

---

### maxOfflineTime

**Type:** `Duration`

**Required:** Yes

**Default:** `const Duration(days: 7)`

**Description:** Maximum time to keep data offline before forcing sync

---

### maxOfflineOperations

**Type:** `int`

**Required:** Yes

**Default:** `1000`

**Description:** Maximum number of offline operations to queue

---

### autoSyncOnReconnect

**Type:** `bool`

**Required:** Yes

**Default:** `true`

**Description:** Whether to automatically sync when connection is restored

---

### enableOfflineConflictDetection

**Type:** `bool`

**Required:** Yes

**Default:** `true`

**Description:** Whether to enable conflict detection for offline changes

---

## Lib\src\models\usm Sync Backend Configuration

### configId

**Type:** `String`

**Required:** Yes

**Description:** Unique identifier for this configuration

---

### displayName

**Type:** `String`

**Required:** Yes

**Description:** Human-readable name for this configuration

---

### backendType

**Type:** `String`

**Required:** Yes

**Description:** Backend type identifier (e.g., 'firebase', 'supabase', 'pocketbase')

---

### baseUrl

**Type:** `String`

**Required:** Yes

**Description:** Primary endpoint URL for the backend service

---

### projectId

**Type:** `String`

**Required:** Yes

**Default:** `Uri.parse(projectUrl).host.split('.').first`

**Description:** Project or database identifier

---

### connectionTimeout

**Type:** `Duration`

**Required:** Yes

**Default:** `const Duration(seconds: 30)`

**Description:** Connection timeout settings

---

### requestTimeout

**Type:** `Duration`

**Required:** Yes

**Default:** `const Duration(seconds: 15)`

**Description:** Request timeout settings

---

### maxRetries

**Type:** `int`

**Required:** Yes

**Default:** `3`

**Description:** Maximum number of retry attempts for failed requests

---

### retryDelay

**Type:** `Duration`

**Required:** Yes

**Default:** `const Duration(seconds: 2)`

**Description:** Delay between retry attempts

---

### useSSL

**Type:** `bool`

**Required:** Yes

**Default:** `true`

**Description:** Whether to use SSL/TLS for connections

---

### customSettings

**Type:** `Map<String, dynamic>`

**Required:** Yes

**Default:** `const {`

**Description:** Backend-specific configuration options

---

### environment

**Type:** `String`

**Required:** Yes

**Default:** `'production'`

**Description:** Environment-specific settings (dev, staging, prod)

---

### type

**Type:** `SyncAuthType`

**Required:** Yes

---

### credentials

**Type:** `Map<String, dynamic>`

**Required:** Yes

---

### maxConnections

**Type:** `int`

**Required:** Yes

**Default:** `10`

---

### connectionIdleTimeout

**Type:** `Duration`

**Required:** Yes

**Default:** `const Duration(minutes: 5)`

---

### connectionMaxLifetime

**Type:** `Duration`

**Required:** Yes

**Default:** `const Duration(hours: 1)`

---

### enableConnectionValidation

**Type:** `bool`

**Required:** Yes

**Default:** `true`

---

## Configuration Examples

### Basic Configuration

```dart
final config = UniversalSyncConfig(
  projectId: 'my-project',
  syncMode: SyncMode.automatic,
  batchSize: 100,
  retryAttempts: 3,
);
```

### Advanced Configuration

```dart
final config = UniversalSyncConfig(
  projectId: 'my-project',
  syncMode: SyncMode.manual,
  batchSize: 50,
  retryAttempts: 5,
  networkTimeout: Duration(seconds: 30),
  conflictResolution: ConflictResolutionStrategy.serverWins,
  enableCompression: true,
  enableEncryption: true,
);
```

### Backend-Specific Configuration

#### PocketBase Configuration

```dart
final pocketBaseConfig = PocketBaseSyncConfig(
  baseUrl: 'https://your-pocketbase.com',
  authToken: 'your-auth-token',
  enableRealtime: true,
);
```

#### Supabase Configuration

```dart
final supabaseConfig = SupabaseSyncConfig(
  url: 'https://your-project.supabase.co',
  anonKey: 'your-anon-key',
  enableRealtime: true,
);
```

