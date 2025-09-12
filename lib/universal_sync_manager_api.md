# Universal Sync Manager API Documentation

This document provides a concise overview of all exported APIs in the Universal Sync Manager library, along with brief usage examples.

## Core Classes

### UniversalSyncManager

The main class for managing synchronization between local and remote data sources.

```dart
// Initialization
final syncManager = UniversalSyncManager(
  backendAdapter: adapter,
  syncInterval: Duration(minutes: 1),
  enableAutoSync: true,
);

// Configuration
await syncManager.configure(
  collections: [
    SyncCollection(
      name: 'collection_name',
      syncDirection: SyncDirection.bidirectional,
    ),
  ],
  backendConfig: backendConfig,
);

// Authentication
await syncManager.updateAuthConfiguration(authConfig);

// Operations
await syncManager.startSync();
await syncManager.stopSync();
await syncManager.syncNow();
await syncManager.clearAuthConfiguration();
```

## Adapters

### PocketBaseSyncAdapter

Adapter for PocketBase backend.

```dart
final adapter = PocketBaseSyncAdapter(
  baseUrl: 'http://localhost:8090',
  connectionTimeout: Duration(seconds: 30),
  requestTimeout: Duration(seconds: 15),
);
```

### FirebaseSyncAdapter

Adapter for Firebase backend.

```dart
final adapter = FirebaseSyncAdapter(
  projectId: 'your-project-id',
  region: 'us-central1',
);
```

### SupabaseSyncAdapter

Adapter for Supabase backend.

```dart
final adapter = SupabaseSyncAdapter(
  supabaseUrl: 'https://your-project.supabase.co',
  supabaseKey: 'your-key',
);
```

## Configuration Models

### SyncBackendConfiguration

Configuration for backend connection.

```dart
final backendConfig = SyncBackendConfiguration(
  configId: 'unique-config-id',
  displayName: 'My Backend',
  backendType: 'pocketbase',
  baseUrl: 'http://localhost:8090',
  projectId: 'my-project',
);
```

### AppSyncAuthConfiguration

Authentication configuration for sync operations.

```dart
final authConfig = AppSyncAuthConfiguration(
  userId: 'user123',
  token: 'auth-token',
  organizationId: 'org456',
  metadata: {'name': 'John Doe'},
);
```

### SyncCollection

Defines a collection to be synchronized.

```dart
final collection = SyncCollection(
  name: 'collection_name',
  syncDirection: SyncDirection.bidirectional,
  filters: {'status': 'active'},
);
```

## Interfaces

### ISyncBackendAdapter

Interface for backend adapters.

```dart
class CustomAdapter implements ISyncBackendAdapter {
  @override
  Future<bool> connect(SyncBackendConfiguration config) async {
    // Implementation
  }
  
  // Other required methods...
}
```

### ISimpleAuthInterface

Interface for authentication providers.

```dart
class CustomAuthProvider implements ISimpleAuthInterface {
  @override
  Future<AuthResult> authenticate(AuthCredentials credentials) async {
    // Implementation
  }
  
  // Other required methods...
}
```

## Enums

### SyncDirection

Direction of synchronization.

```dart
SyncDirection.bidirectional  // Two-way sync
SyncDirection.uploadOnly     // Local to remote only
SyncDirection.downloadOnly   // Remote to local only
SyncDirection.upload         // Alias for uploadOnly
SyncDirection.download       // Alias for downloadOnly
```

### SyncMode

Mode of synchronization operation.

```dart
SyncMode.manual        // Manual sync only
SyncMode.automatic     // Automatic sync based on changes
SyncMode.scheduled     // Sync at fixed intervals
SyncMode.realtime      // Immediate sync when possible
SyncMode.hybrid        // Combination of auto and manual
SyncMode.offline       // No network sync
SyncMode.intelligent   // Based on usage patterns
```

### ConflictResolutionStrategy

Strategies for resolving data conflicts.

```dart
ConflictResolutionStrategy.localWins      // Local changes win
ConflictResolutionStrategy.serverWins     // Server changes win
ConflictResolutionStrategy.remoteWins     // Alias for serverWins
ConflictResolutionStrategy.timestampWins  // Latest change wins
ConflictResolutionStrategy.intelligentMerge // Smart merge of fields
```

## Results and Events

### SyncResult

Result of a sync operation.

```dart
if (result.isSuccess) {
  final data = result.data;
} else {
  final error = result.error;
}
```

### SyncEvent

Event emitted during sync operations.

```dart
syncManager.eventStream.listen((event) {
  switch (event.eventType) {
    case SyncEventType.syncStarted:
      // Handle sync start
      break;
    case SyncEventType.syncCompleted:
      // Handle sync completion
      break;
    // Other event types...
  }
});
```

## Auth Integration

### FirebaseAuthIntegration

Integration with Firebase Authentication.

```dart
final firebaseAuth = FirebaseAuthIntegration();
await syncManager.setAuthProvider(firebaseAuth);
```

### SupabaseAuthIntegration

Integration with Supabase Authentication.

```dart
final supabaseAuth = SupabaseAuthIntegration();
await syncManager.setAuthProvider(supabaseAuth);
```

### Auth0Integration

Integration with Auth0 Authentication.

```dart
final auth0 = Auth0Integration(
  domain: 'your-domain.auth0.com',
  clientId: 'your-client-id',
);
await syncManager.setAuthProvider(auth0);
```

## State Management Integration

### BlocProviderIntegration

Integration with BLoC state management.

```dart
final blocIntegration = BlocProviderIntegration<SyncBloc>();
blocIntegration.attachToSyncManager(syncManager);
```

### RiverpodIntegration

Integration with Riverpod state management.

```dart
final riverpodIntegration = RiverpodIntegration();
riverpodIntegration.attachToSyncManager(syncManager);
```

### GetxIntegration

Integration with GetX state management.

```dart
final getxIntegration = GetxIntegration();
getxIntegration.attachToSyncManager(syncManager);
```

## Services

### SyncQueue

Queue for managing sync operations.

```dart
final queue = SyncQueue();
queue.enqueue(SyncOperation(...));
queue.processNext();
```

### ConflictResolver

Service for resolving data conflicts.

```dart
final resolver = ConflictResolver();
resolver.setStrategy(ConflictResolutionStrategy.intelligentMerge);
final resolution = resolver.resolveConflict(conflict);
```

### SyncScheduler

Scheduler for automatic sync operations.

```dart
final scheduler = SyncScheduler();
scheduler.schedule(Duration(minutes: 30));
scheduler.cancelScheduled();
```

### TokenManager

Manager for authentication tokens.

```dart
final tokenManager = TokenManager();
tokenManager.setToken('auth-token');
final token = tokenManager.getToken();
```

### AuthLifecycleManager

Manager for authentication lifecycle events.

```dart
final lifecycleManager = AuthLifecycleManager();
lifecycleManager.onLogin(() {
  // Handle login
});
lifecycleManager.onLogout(() {
  // Handle logout
});
```
