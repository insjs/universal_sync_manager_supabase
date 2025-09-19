# Sync Features Guide

Complete guide for understanding and implementing synchronization features with Universal Sync Manager and Supabase.

## 📋 Overview

USM provides powerful synchronization capabilities including bidirectional sync, automatic conflict resolution, and real-time updates through Supabase's real-time subscriptions.

## 🔄 Bidirectional Synchronization

### 1. Understanding Sync Flow

```dart
class SyncFlowExplanation {
  // LOCAL → REMOTE (Upload)
  // 1. User makes changes locally
  // 2. Changes are marked as dirty (isDirty = true)
  // 3. Sync process uploads changes to Supabase
  // 4. On success, marks as clean (isDirty = false, updates syncVersion)

  // REMOTE → LOCAL (Download)
  // 1. Changes detected on Supabase (via real-time or manual sync)
  // 2. Changes downloaded and compared with local data
  // 3. Conflicts resolved automatically or manually
  // 4. Local data updated with remote changes
  // 5. Sync metadata updated (lastSyncedAt, syncVersion)
}
```

### 2. Manual Sync Operations

```dart
class SyncOperations {
  final UniversalSyncManager _syncManager;

  SyncOperations(this._syncManager);

  // Sync specific entity
  Future<void> syncUserProfiles() async {
    print('🔄 Starting user profiles sync...');

    final result = await _syncManager.syncEntity('user_profiles');

    if (result.isSuccess) {
      print('✅ User profiles sync completed:');
      print('   - Records processed: ${result.affectedItems}');
      print('   - Conflicts resolved: ${result.conflictsResolved}');
      print('   - Errors: ${result.errors?.length ?? 0}');
    } else {
      print('❌ User profiles sync failed: ${result.error?.message}');
    }
  }

  // Sync all entities
  Future<void> syncAllData() async {
    print('🔄 Starting full data sync...');

    final result = await _syncManager.syncAll();

    if (result.isSuccess) {
      print('✅ Full sync completed:');
      print('   - Total records processed: ${result.totalRecordsProcessed}');
      print('   - Entities synced: ${result.entitiesSynced}');
      print('   - Total conflicts resolved: ${result.totalConflictsResolved}');
    } else {
      print('❌ Full sync failed: ${result.error?.message}');
    }
  }

  // Sync with progress monitoring
  Future<void> syncWithProgress() async {
    print('🔄 Starting sync with progress monitoring...');

    // Listen to sync progress
    final progressSubscription = _syncManager.syncProgressStream.listen((progress) {
      print('📊 Sync Progress: ${progress.percentage}% - ${progress.currentEntity}');

      if (progress.status == SyncStatus.conflictDetected) {
        print('⚠️ Conflict detected in ${progress.currentEntity}');
      }
    });

    // Listen to sync events
    final eventSubscription = _syncManager.syncEventStream.listen((event) {
      print('📡 Sync Event: ${event.type} on ${event.collection}');

      if (event.type == SyncEventType.conflictResolved) {
        print('✅ Conflict resolved automatically');
      }
    });

    try {
      await _syncManager.syncAll();
      print('✅ Sync with progress monitoring completed');
    } finally {
      // Clean up subscriptions
      await progressSubscription.cancel();
      await eventSubscription.cancel();
    }
  }
}
```

### 3. Automatic Sync Configuration

```dart
class AutoSyncConfiguration {
  // Configure automatic sync
  Future<void> configureAutoSync() async {
    final config = UniversalSyncConfig(
      projectId: 'your-project-id',
      syncMode: SyncMode.automatic, // Enable automatic sync
      syncInterval: Duration(minutes: 15), // Sync every 15 minutes
      enableConflictResolution: true,
      enableRealTimeSync: true,
      autoSyncOnNetworkChange: true, // Sync when network comes back
      backgroundSyncEnabled: true, // Continue sync in background
    );

    await _syncManager.initialize(config);
  }

  // Handle network changes
  void setupNetworkChangeHandler() {
    // USM automatically handles network changes when autoSyncOnNetworkChange is true
    // But you can add custom logic here

    _syncManager.syncProgressStream.listen((progress) {
      if (progress.status == SyncStatus.networkRestored) {
        print('🌐 Network restored, starting sync...');
      } else if (progress.status == SyncStatus.networkLost) {
        print('📶 Network lost, sync paused');
      }
    });
  }

  // Background sync management
  void configureBackgroundSync() {
    // USM handles background sync automatically when backgroundSyncEnabled is true
    // You can monitor background sync status

    _syncManager.syncProgressStream.listen((progress) {
      if (progress.isBackground) {
        print('🔄 Background sync: ${progress.percentage}%');
      }
    });
  }
}
```

## ⚔️ Conflict Resolution

### 1. Understanding Conflicts

```dart
class ConflictUnderstanding {
  // A conflict occurs when:
  // 1. Local record: syncVersion = 5, lastModified = "2024-01-15 10:00:00"
  // 2. Remote record: syncVersion = 5, lastModified = "2024-01-15 10:05:00"
  // 3. Both have syncVersion = 5 but different timestamps = CONFLICT!

  // Conflict types:
  // - Version Conflict: Same syncVersion but different content
  // - Timestamp Conflict: Different lastModified times
  // - Content Conflict: Different field values
}
```

### 2. Automatic Conflict Resolution

```dart
class AutomaticConflictResolution {
  final UniversalSyncManager _syncManager;

  AutomaticConflictResolution(this._syncManager);

  // Configure default conflict resolution strategy
  Future<void> configureDefaultStrategy() async {
    // Strategy is configured per entity during registration
    _syncManager.registerEntity(
      'user_profiles',
      SyncEntityConfig(
        tableName: 'user_profiles',
        requiresAuthentication: true,
        conflictStrategy: ConflictResolutionStrategy.serverWins,
        // Options:
        // - serverWins: Always use remote data
        // - clientWins: Always use local data
        // - manual: Require manual resolution
        // - merge: Attempt intelligent merge
      ),
    );
  }

  // Monitor conflict resolution
  void monitorConflicts() {
    _syncManager.syncEventStream.listen((event) {
      if (event.type == SyncEventType.conflictDetected) {
        print('⚠️ Conflict detected: ${event.collection} - ${event.id}');
      } else if (event.type == SyncEventType.conflictResolved) {
        print('✅ Conflict resolved: ${event.collection} - ${event.id}');
      }
    });

    _syncManager.conflictStream.listen((conflict) {
      print('🔍 Conflict details:');
      print('   Entity: ${conflict.collection}');
      print('   Record ID: ${conflict.id}');
      print('   Local Version: ${conflict.localVersion}');
      print('   Remote Version: ${conflict.remoteVersion}');
      print('   Resolution: ${conflict.resolution}');
    });
  }
}
```

### 3. Manual Conflict Resolution

```dart
class ManualConflictResolution {
  final UniversalSyncManager _syncManager;

  ManualConflictResolution(this._syncManager);

  // Custom conflict resolver
  Future<void> setupCustomResolver() async {
    final resolver = CustomUserProfileResolver();
    _syncManager.setConflictResolver('user_profiles', resolver);
  }

  // Handle conflicts interactively
  Future<void> handleConflictsInteractively() async {
    _syncManager.conflictStream.listen((conflict) async {
      if (conflict.collection == 'user_profiles') {
        final resolution = await showConflictDialog(conflict);
        await _syncManager.resolveConflict(conflict.id, resolution);
      }
    });
  }

  // Show conflict resolution dialog (UI implementation)
  Future<ConflictResolution> showConflictDialog(SyncConflict conflict) async {
    // This would be implemented in your UI
    // For now, return a default resolution
    return ConflictResolution.useServer();
  }
}

// Custom conflict resolver implementation
class CustomUserProfileResolver implements ConflictResolver {
  @override
  Future<SyncConflictResolution> resolveConflict(SyncConflict conflict) async {
    // Custom logic for user profile conflicts

    // Example: For 'is_active' field, always use server value
    if (conflict.fieldConflicts.containsKey('is_active')) {
      return SyncConflictResolution.useServer(['is_active']);
    }

    // Example: For 'name' field, let user decide
    if (conflict.fieldConflicts.containsKey('name')) {
      // In a real app, you might show a dialog
      // For now, use a simple rule
      return SyncConflictResolution.useClient(['name']);
    }

    // Default: Use server data for other fields
    return SyncConflictResolution.useServer();
  }
}
```

### 4. Conflict Resolution Strategies

```dart
class ConflictStrategies {
  // Strategy 1: Server Always Wins
  SyncConflictResolution serverWinsStrategy() {
    return SyncConflictResolution.useServer();
  }

  // Strategy 2: Client Always Wins
  SyncConflictResolution clientWinsStrategy() {
    return SyncConflictResolution.useClient();
  }

  // Strategy 3: Field-by-Field Resolution
  SyncConflictResolution fieldByFieldStrategy() {
    return SyncConflictResolution.useServer(['created_at', 'created_by'])
           .mergeWith(SyncConflictResolution.useClient(['name', 'email']));
  }

  // Strategy 4: Timestamp-Based Resolution
  SyncConflictResolution timestampBasedStrategy(SyncConflict conflict) {
    final localData = conflict.localData;
    final remoteData = conflict.remoteData;

    final localUpdated = DateTime.parse(localData['updated_at']);
    final remoteUpdated = DateTime.parse(remoteData['updated_at']);

    return localUpdated.isAfter(remoteUpdated)
        ? SyncConflictResolution.useClient()
        : SyncConflictResolution.useServer();
  }

  // Strategy 5: Manual Resolution Required
  SyncConflictResolution manualResolution() {
    return SyncConflictResolution.manual();
  }
}
```

## 📡 Real-Time Synchronization

### 1. Real-Time Subscriptions

```dart
class RealTimeSync {
  final UniversalSyncManager _syncManager;
  StreamSubscription? _subscription;

  RealTimeSync(this._syncManager);

  // Enable real-time sync for entity
  Future<void> enableRealTimeSync() async {
    _syncManager.registerEntity(
      'user_profiles',
      SyncEntityConfig(
        tableName: 'user_profiles',
        requiresAuthentication: true,
        enableRealTimeSync: true, // Enable real-time
        realTimeSyncOptions: SyncSubscriptionOptions(
          eventTypes: ['INSERT', 'UPDATE', 'DELETE'],
          filter: {'organization_id': 'org-current-user'},
        ),
      ),
    );
  }

  // Subscribe to real-time changes
  Future<void> subscribeToChanges() async {
    _subscription = _syncManager.subscribe(
      'user_profiles',
      SyncSubscriptionOptions(
        eventTypes: ['INSERT', 'UPDATE', 'DELETE'],
        filter: {'organization_id': 'current-org-id'},
      ),
    ).listen((event) {
      print('📡 Real-time event: ${event.type}');

      switch (event.type) {
        case 'INSERT':
          handleNewRecord(event);
          break;
        case 'UPDATE':
          handleUpdatedRecord(event);
          break;
        case 'DELETE':
          handleDeletedRecord(event);
          break;
      }
    });
  }

  void handleNewRecord(SyncEvent event) {
    print('➕ New record: ${event.data}');
    // Update your UI state
    // notifyListeners();
  }

  void handleUpdatedRecord(SyncEvent event) {
    print('✏️ Updated record: ${event.data}');
    // Update your UI state
    // notifyListeners();
  }

  void handleDeletedRecord(SyncEvent event) {
    print('🗑️ Deleted record: ${event.id}');
    // Update your UI state
    // notifyListeners();
  }

  // Unsubscribe when done
  void dispose() {
    _subscription?.cancel();
  }
}
```

### 2. Real-Time Event Handling

```dart
class RealTimeEventHandler {
  final UniversalSyncManager _syncManager;

  RealTimeEventHandler(this._syncManager) {
    setupEventListeners();
  }

  void setupEventListeners() {
    // Listen to all sync events
    _syncManager.syncEventStream.listen((event) {
      handleSyncEvent(event);
    });

    // Listen to sync progress
    _syncManager.syncProgressStream.listen((progress) {
      handleSyncProgress(progress);
    });

    // Listen to conflicts
    _syncManager.conflictStream.listen((conflict) {
      handleConflict(conflict);
    });
  }

  void handleSyncEvent(SyncEvent event) {
    print('📡 Sync Event: ${event.type} - ${event.collection}:${event.id}');

    // Handle different event types
    switch (event.type) {
      case SyncEventType.recordCreated:
        onRecordCreated(event);
        break;
      case SyncEventType.recordUpdated:
        onRecordUpdated(event);
        break;
      case SyncEventType.recordDeleted:
        onRecordDeleted(event);
        break;
      case SyncEventType.syncCompleted:
        onSyncCompleted(event);
        break;
      case SyncEventType.conflictDetected:
        onConflictDetected(event);
        break;
    }
  }

  void handleSyncProgress(SyncProgress progress) {
    print('📊 Sync Progress: ${progress.percentage}% - ${progress.status}');

    // Update UI progress indicators
    switch (progress.status) {
      case SyncStatus.inProgress:
        showSyncProgress(progress.percentage);
        break;
      case SyncStatus.completed:
        hideSyncProgress();
        showSyncComplete();
        break;
      case SyncStatus.failed:
        hideSyncProgress();
        showSyncError(progress.error);
        break;
    }
  }

  void handleConflict(SyncConflict conflict) {
    print('⚠️ Conflict: ${conflict.collection}:${conflict.id}');

    // Handle conflicts based on your strategy
    // This could trigger UI to show conflict resolution dialog
  }

  // Event handlers
  void onRecordCreated(SyncEvent event) {
    // Handle new record creation
  }

  void onRecordUpdated(SyncEvent event) {
    // Handle record updates
  }

  void onRecordDeleted(SyncEvent event) {
    // Handle record deletion
  }

  void onSyncCompleted(SyncEvent event) {
    // Handle sync completion
  }

  void onConflictDetected(SyncEvent event) {
    // Handle conflict detection
  }

  // UI update methods (implement in your UI)
  void showSyncProgress(double percentage) {}
  void hideSyncProgress() {}
  void showSyncComplete() {}
  void showSyncError(String? error) {}
}
```

## 🧪 Sync Testing Suite

### 1. Comprehensive Sync Testing

```dart
class SyncTestSuite {
  final UniversalSyncManager _syncManager;
  final UserProfileRepository _repository;

  SyncTestSuite(this._syncManager, this._repository);

  Future<void> runAllSyncTests() async {
    print('🧪 Running Sync Tests...');

    await testBidirectionalSync();
    await testConflictResolution();
    await testRealTimeUpdates();
    await testNetworkScenarios();

    print('✅ Sync Tests Complete');
  }

  Future<void> testBidirectionalSync() async {
    print('🔄 Testing bidirectional sync...');

    // Create a test profile
    final testProfile = UserProfile.create(
      organizationId: 'org-test-123',
      name: 'Sync Test User',
      email: 'sync-test@example.com',
      createdBy: 'test-user',
    );

    // Create locally
    final created = await _repository.create(testProfile);
    if (created == null) {
      print('❌ Failed to create test profile');
      return;
    }

    print('✅ Created profile locally: ${created.id}');

    // Sync to remote
    final syncResult = await _syncManager.syncEntity('user_profiles');
    if (syncResult.isSuccess) {
      print('✅ Sync to remote successful');
    } else {
      print('❌ Sync to remote failed: ${syncResult.error?.message}');
    }

    // Verify sync metadata
    final syncedProfile = await _repository.getById(created.id);
    if (syncedProfile != null && !syncedProfile.isDirty) {
      print('✅ Profile marked as synced');
    } else {
      print('❌ Profile not marked as synced');
    }
  }

  Future<void> testConflictResolution() async {
    print('⚔️ Testing conflict resolution...');

    // This test would require setting up conflicting data
    // between local and remote, then testing resolution
    print('✅ Conflict resolution test placeholder');
  }

  Future<void> testRealTimeUpdates() async {
    print('📡 Testing real-time updates...');

    // Subscribe to changes
    final subscription = _syncManager.subscribe(
      'user_profiles',
      SyncSubscriptionOptions(),
    );

    bool receivedEvent = false;
    final sub = subscription.listen((event) {
      receivedEvent = true;
      print('✅ Real-time event received: ${event.type}');
    });

    // Wait a bit for subscription to establish
    await Future.delayed(Duration(seconds: 2));

    // Create a record to trigger real-time event
    final testProfile = UserProfile.create(
      organizationId: 'org-test-123',
      name: 'Real-time Test User',
      email: 'realtime-test@example.com',
      createdBy: 'test-user',
    );

    await _repository.create(testProfile);

    // Wait for real-time event
    await Future.delayed(Duration(seconds: 3));

    if (receivedEvent) {
      print('✅ Real-time update test passed');
    } else {
      print('❌ Real-time update test failed - no event received');
    }

    await sub.cancel();
  }

  Future<void> testNetworkScenarios() async {
    print('🌐 Testing network scenarios...');

    // Test offline → online sync
    // This would require network simulation
    print('✅ Network scenarios test placeholder');
  }
}
```

## 📊 Performance Monitoring

### 1. Sync Performance Metrics

```dart
class SyncPerformanceMonitor {
  final UniversalSyncManager _syncManager;

  SyncPerformanceMonitor(this._syncManager) {
    monitorSyncPerformance();
  }

  void monitorSyncPerformance() {
    _syncManager.syncProgressStream.listen((progress) {
      if (progress.status == SyncStatus.completed) {
        print('📊 Sync Performance:');
        print('   - Duration: ${progress.duration?.inSeconds}s');
        print('   - Records processed: ${progress.recordsProcessed}');
        print('   - Conflicts resolved: ${progress.conflictsResolved}');
        print('   - Average records/sec: ${progress.averageRecordsPerSecond}');

        // Log performance metrics
        logPerformanceMetrics(progress);
      }
    });
  }

  void logPerformanceMetrics(SyncProgress progress) {
    // Log to analytics service
    // Example: FirebaseAnalytics.instance.logEvent('sync_performance', {
    //   'duration_seconds': progress.duration?.inSeconds,
    //   'records_processed': progress.recordsProcessed,
    //   'conflicts_resolved': progress.conflictsResolved,
    // });
  }

  // Performance thresholds (based on testing)
  static const int maxSyncTimeSeconds = 120; // 2 minutes for large datasets
  static const int maxRecordsPerSecond = 100; // Expected performance
  static const int maxConflictsPercentage = 5; // 5% conflict rate is acceptable
}
```

## 🚨 Error Handling & Recovery

### 1. Sync Error Handling

```dart
class SyncErrorHandler {
  final UniversalSyncManager _syncManager;

  SyncErrorHandler(this._syncManager) {
    handleSyncErrors();
  }

  void handleSyncErrors() {
    _syncManager.syncProgressStream.listen((progress) {
      if (progress.status == SyncStatus.failed) {
        handleSyncFailure(progress.error);
      }
    });
  }

  void handleSyncFailure(String? error) {
    print('❌ Sync failed: $error');

    // Categorize error and handle appropriately
    if (error?.contains('network') == true) {
      handleNetworkError();
    } else if (error?.contains('auth') == true) {
      handleAuthError();
    } else if (error?.contains('conflict') == true) {
      handleConflictError();
    } else {
      handleGenericError(error);
    }
  }

  void handleNetworkError() {
    print('🌐 Network error - will retry when connection restored');
    // USM automatically handles network restoration
  }

  void handleAuthError() {
    print('🔐 Auth error - user needs to re-authenticate');
    // Trigger re-authentication flow
  }

  void handleConflictError() {
    print('⚔️ Conflict error - manual resolution may be needed');
    // Show conflict resolution UI
  }

  void handleGenericError(String? error) {
    print('❓ Generic sync error: $error');
    // Log error and notify user
  }
}
```

## 📋 Next Steps

1. **[Advanced Features](../advanced_features.md)** - Performance optimization and state management
2. **[Testing Guide](../testing.md)** - Comprehensive testing of sync features
3. **[Troubleshooting](../troubleshooting.md)** - Common sync issues and solutions

## 🆘 Troubleshooting

**Sync Not Working:**
- Check authentication status
- Verify network connectivity
- Check Supabase real-time configuration
- Review RLS policies

**Conflicts Not Resolving:**
- Verify conflict resolution strategy
- Check manual conflict resolution setup
- Review conflict resolver implementation

**Real-Time Not Working:**
- Confirm Supabase real-time is enabled
- Check subscription filters
- Verify RLS policies allow subscriptions

**Performance Issues:**
- Review database indexes
- Check query optimization
- Monitor sync frequency settings