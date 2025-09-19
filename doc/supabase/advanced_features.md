# Advanced Features Guide

Advanced features and optimization techniques for Universal Sync Manager with Supabase integration.

## 📋 Overview

This guide covers advanced USM features including performance optimization, queue management, state management integration, and enterprise-level capabilities.

## ⚡ Performance Optimization

### 1. Large Dataset Handling

```dart
class PerformanceOptimization {
  final UniversalSyncManager _syncManager;

  PerformanceOptimization(this._syncManager);

  // Configure for large datasets
  Future<void> configureForLargeDatasets() async {
    final config = UniversalSyncConfig(
      projectId: 'your-project-id',
      syncMode: SyncMode.automatic,
      syncInterval: Duration(minutes: 30), // Less frequent for large datasets
      enableConflictResolution: true,
      enableRealTimeSync: false, // Disable real-time for large datasets
      batchSize: 100, // Process in batches
      maxConcurrentOperations: 3, // Limit concurrency
      enableCompression: true, // Compress data transfers
    );

    await _syncManager.initialize(config);
  }

  // Optimized sync for large datasets
  Future<void> syncLargeDataset() async {
    print('🏋️ Starting large dataset sync...');

    final startTime = DateTime.now();

    // Monitor memory usage
    final memoryMonitor = MemoryMonitor();
    memoryMonitor.startMonitoring();

    try {
      // Sync in smaller batches to avoid memory issues
      final result = await _syncManager.syncEntity(
        'user_profiles',
        SyncOptions(
          batchSize: 50,
          enableProgressTracking: true,
          timeout: Duration(minutes: 20), // Extended timeout for large datasets
        ),
      );

      final duration = DateTime.now().difference(startTime);

      print('✅ Large dataset sync completed:');
      print('   - Duration: ${duration.inSeconds}s');
      print('   - Records processed: ${result.affectedItems}');
      print('   - Memory peak: ${memoryMonitor.peakMemoryUsage}MB');
      print('   - Average speed: ${(result.affectedItems / duration.inSeconds).round()} records/sec');

    } finally {
      memoryMonitor.stopMonitoring();
    }
  }

  // Background sync for large datasets
  Future<void> scheduleBackgroundSync() async {
    // Use work manager or similar for background processing
    // This prevents UI blocking during large syncs

    await _syncManager.syncEntityInBackground(
      'user_profiles',
      BackgroundSyncOptions(
        priority: SyncPriority.low,
        requiresNetwork: true,
        retryOnFailure: true,
        maxRetries: 3,
      ),
    );
  }
}

// Memory monitoring utility
class MemoryMonitor {
  bool _isMonitoring = false;
  int _peakMemoryUsage = 0;

  void startMonitoring() {
    _isMonitoring = true;
    _peakMemoryUsage = 0;

    // Monitor memory usage periodically
    Timer.periodic(Duration(seconds: 5), (timer) {
      if (!_isMonitoring) {
        timer.cancel();
        return;
      }

      // In a real implementation, you'd use platform-specific APIs
      // For now, we'll simulate memory monitoring
      final currentMemory = _simulateMemoryUsage();
      _peakMemoryUsage = max(_peakMemoryUsage, currentMemory);
    });
  }

  void stopMonitoring() {
    _isMonitoring = false;
  }

  int get peakMemoryUsage => _peakMemoryUsage;

  int _simulateMemoryUsage() {
    // Simulate memory usage between 50-200MB
    return 50 + (DateTime.now().millisecondsSinceEpoch % 150);
  }
}
```

### 2. Query Optimization

```dart
class QueryOptimization {
  final UniversalSyncManager _syncManager;

  // Optimized queries for performance
  Future<List<UserProfile>> getActiveUsersOptimized({
    required String organizationId,
    int limit = 100,
  }) async {
    // Use specific filters to reduce data transfer
    final result = await _syncManager.query(
      'user_profiles',
      SyncQuery(
        filters: {
          'organization_id': organizationId,
          'is_active': true,
          'is_deleted': false,
        },
        limit: limit,
        orderBy: 'updated_at DESC', // Most recently updated first
      ),
    );

    if (result.isSuccess && result.data != null) {
      return result.data!.map((json) => UserProfile.fromJson(json)).toList();
    }

    return [];
  }

  // Paginated queries for large result sets
  Future<PaginatedResult<UserProfile>> getUsersPaginated({
    required String organizationId,
    required int page,
    required int pageSize,
  }) async {
    final offset = (page - 1) * pageSize;

    final result = await _syncManager.query(
      'user_profiles',
      SyncQuery(
        filters: {'organization_id': organizationId},
        limit: pageSize,
        offset: offset,
        orderBy: 'created_at DESC',
      ),
    );

    final users = result.isSuccess && result.data != null
        ? result.data!.map((json) => UserProfile.fromJson(json)).toList()
        : <UserProfile>[];

    return PaginatedResult(
      data: users,
      page: page,
      pageSize: pageSize,
      hasMore: users.length == pageSize,
    );
  }

  // Cached queries for frequently accessed data
  final Map<String, CacheEntry<List<UserProfile>>> _queryCache = {};

  Future<List<UserProfile>> getCachedActiveUsers(String organizationId) async {
    final cacheKey = 'active_users_$organizationId';
    final cached = _queryCache[cacheKey];

    // Return cached data if still valid
    if (cached != null && !cached.isExpired) {
      return cached.data;
    }

    // Fetch fresh data
    final users = await getActiveUsersOptimized(organizationId);

    // Cache for 5 minutes
    _queryCache[cacheKey] = CacheEntry(
      data: users,
      timestamp: DateTime.now(),
      ttl: Duration(minutes: 5),
    );

    return users;
  }
}

class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.ttl,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;
}

class PaginatedResult<T> {
  final List<T> data;
  final int page;
  final int pageSize;
  final bool hasMore;

  PaginatedResult({
    required this.data,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });
}
```

### 3. Background Processing

```dart
class BackgroundProcessor {
  final UniversalSyncManager _syncManager;

  // Queue for background operations
  final Queue<BackgroundOperation> _operationQueue = Queue();
  bool _isProcessing = false;

  // Add operation to background queue
  void addToQueue(BackgroundOperation operation) {
    _operationQueue.add(operation);
    _processQueue();
  }

  // Process queue in background
  Future<void> _processQueue() async {
    if (_isProcessing || _operationQueue.isEmpty) return;

    _isProcessing = true;

    while (_operationQueue.isNotEmpty) {
      final operation = _operationQueue.removeFirst();

      try {
        await _executeOperation(operation);
      } catch (e) {
        print('Background operation failed: $e');
        // Handle failure (retry, log, etc.)
      }
    }

    _isProcessing = false;
  }

  Future<void> _executeOperation(BackgroundOperation operation) async {
    switch (operation.type) {
      case OperationType.sync:
        await _syncManager.syncEntity(operation.entityName);
        break;
      case OperationType.create:
        await _syncManager.create(operation.entityName, operation.data!);
        break;
      case OperationType.update:
        await _syncManager.update(operation.entityName, operation.id!, operation.data!);
        break;
      case OperationType.delete:
        await _syncManager.delete(operation.entityName, operation.id!);
        break;
    }
  }

  // Schedule recurring background tasks
  void scheduleRecurringTasks() {
    // Sync every 15 minutes
    Timer.periodic(Duration(minutes: 15), (timer) {
      addToQueue(BackgroundOperation(
        type: OperationType.sync,
        entityName: 'user_profiles',
      ));
    });

    // Cleanup old data daily
    Timer.periodic(Duration(days: 1), (timer) {
      addToQueue(BackgroundOperation(
        type: OperationType.cleanup,
        entityName: 'user_profiles',
      ));
    });
  }
}

enum OperationType { sync, create, update, delete, cleanup }

class BackgroundOperation {
  final OperationType type;
  final String entityName;
  final String? id;
  final Map<String, dynamic>? data;

  BackgroundOperation({
    required this.type,
    required this.entityName,
    this.id,
    this.data,
  });
}
```

## 🎭 State Management Integration

### 1. Riverpod Integration

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Repository provider
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  return UserProfileRepository(syncManager);
});

// Sync manager provider
final syncManagerProvider = Provider<UniversalSyncManager>((ref) {
  throw UnimplementedError('SyncManager must be initialized in main.dart');
});

// User profiles state notifier
class UserProfilesNotifier extends StateNotifier<AsyncValue<List<UserProfile>>> {
  final UserProfileRepository _repository;
  final UniversalSyncManager _syncManager;

  UserProfilesNotifier(this._repository, this._syncManager)
      : super(const AsyncValue.loading()) {
    _initialize();
    _setupSyncListeners();
  }

  Future<void> _initialize() async {
    try {
      final profiles = await _repository.getAll();
      state = AsyncValue.data(profiles);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _setupSyncListeners() {
    // Listen for sync events to update state
    _syncManager.syncEventStream.listen((event) {
      if (event.collection == 'user_profiles') {
        _refreshData();
      }
    });

    // Listen for real-time updates
    _syncManager.subscribe('user_profiles', SyncSubscriptionOptions())
        .listen((event) {
      _handleRealTimeEvent(event);
    });
  }

  Future<void> _refreshData() async {
    state = const AsyncValue.loading();
    try {
      final profiles = await _repository.getAll();
      state = AsyncValue.data(profiles);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _handleRealTimeEvent(SyncEvent event) {
    state.maybeWhen(
      data: (profiles) {
        switch (event.type) {
          case 'INSERT':
            final newProfile = UserProfile.fromJson(event.data);
            state = AsyncValue.data([...profiles, newProfile]);
            break;
          case 'UPDATE':
            final updatedProfile = UserProfile.fromJson(event.data);
            final updatedProfiles = profiles.map((p) =>
                p.id == updatedProfile.id ? updatedProfile : p).toList();
            state = AsyncValue.data(updatedProfiles);
            break;
          case 'DELETE':
            final filteredProfiles = profiles.where((p) => p.id != event.id).toList();
            state = AsyncValue.data(filteredProfiles);
            break;
        }
      },
      orElse: () => _refreshData(),
    );
  }

  Future<void> createProfile(UserProfile profile) async {
    try {
      await _repository.create(profile);
      // Sync will trigger state update via listeners
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    try {
      await _repository.update(profile);
      // Sync will trigger state update via listeners
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteProfile(String id) async {
    try {
      await _repository.delete(id);
      // Sync will trigger state update via listeners
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// State notifier provider
final userProfilesProvider = StateNotifierProvider<UserProfilesNotifier, AsyncValue<List<UserProfile>>>((ref) {
  final repository = ref.watch(userProfileRepositoryProvider);
  final syncManager = ref.watch(syncManagerProvider);
  return UserProfilesNotifier(repository, syncManager);
});

// Usage in UI
class UserProfilesScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(userProfilesProvider);

    return profilesAsync.when(
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
      data: (profiles) => ListView.builder(
        itemCount: profiles.length,
        itemBuilder: (context, index) {
          final profile = profiles[index];
          return ListTile(
            title: Text(profile.name),
            subtitle: Text(profile.email),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => ref
                  .read(userProfilesProvider.notifier)
                  .deleteProfile(profile.id),
            ),
          );
        },
      ),
    );
  }
}
```

### 2. Bloc Integration

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

// Events
abstract class UserProfilesEvent {}

class LoadUserProfiles extends UserProfilesEvent {}

class CreateUserProfile extends UserProfilesEvent {
  final UserProfile profile;
  CreateUserProfile(this.profile);
}

class UpdateUserProfile extends UserProfilesEvent {
  final UserProfile profile;
  UpdateUserProfile(this.profile);
}

class DeleteUserProfile extends UserProfilesEvent {
  final String id;
  DeleteUserProfile(this.id);
}

// States
abstract class UserProfilesState {}

class UserProfilesInitial extends UserProfilesState {}

class UserProfilesLoading extends UserProfilesState {}

class UserProfilesLoaded extends UserProfilesState {
  final List<UserProfile> profiles;
  UserProfilesLoaded(this.profiles);
}

class UserProfilesError extends UserProfilesState {
  final String message;
  UserProfilesError(this.message);
}

// Bloc
class UserProfilesBloc extends Bloc<UserProfilesEvent, UserProfilesState> {
  final UserProfileRepository _repository;
  final UniversalSyncManager _syncManager;

  UserProfilesBloc(this._repository, this._syncManager)
      : super(UserProfilesInitial()) {
    on<LoadUserProfiles>(_onLoadUserProfiles);
    on<CreateUserProfile>(_onCreateUserProfile);
    on<UpdateUserProfile>(_onUpdateUserProfile);
    on<DeleteUserProfile>(_onDeleteUserProfile);

    _setupSyncListeners();
  }

  void _setupSyncListeners() {
    // Listen for sync events
    _syncManager.syncEventStream.listen((event) {
      if (event.collection == 'user_profiles') {
        add(LoadUserProfiles()); // Refresh data
      }
    });

    // Listen for real-time updates
    _syncManager.subscribe('user_profiles', SyncSubscriptionOptions())
        .listen((event) {
      _handleRealTimeEvent(event);
    });
  }

  void _handleRealTimeEvent(SyncEvent event) {
    // Handle real-time events to update state immediately
    if (state is UserProfilesLoaded) {
      final currentState = state as UserProfilesLoaded;
      List<UserProfile> updatedProfiles;

      switch (event.type) {
        case 'INSERT':
          final newProfile = UserProfile.fromJson(event.data);
          updatedProfiles = [...currentState.profiles, newProfile];
          break;
        case 'UPDATE':
          final updatedProfile = UserProfile.fromJson(event.data);
          updatedProfiles = currentState.profiles.map((p) =>
              p.id == updatedProfile.id ? updatedProfile : p).toList();
          break;
        case 'DELETE':
          updatedProfiles = currentState.profiles
              .where((p) => p.id != event.id)
              .toList();
          break;
        default:
          return;
      }

      emit(UserProfilesLoaded(updatedProfiles));
    }
  }

  Future<void> _onLoadUserProfiles(
    LoadUserProfiles event,
    Emitter<UserProfilesState> emit,
  ) async {
    emit(UserProfilesLoading());
    try {
      final profiles = await _repository.getAll();
      emit(UserProfilesLoaded(profiles));
    } catch (e) {
      emit(UserProfilesError(e.toString()));
    }
  }

  Future<void> _onCreateUserProfile(
    CreateUserProfile event,
    Emitter<UserProfilesState> emit,
  ) async {
    try {
      await _repository.create(event.profile);
      // Sync will trigger refresh via listeners
    } catch (e) {
      emit(UserProfilesError(e.toString()));
    }
  }

  Future<void> _onUpdateUserProfile(
    UpdateUserProfile event,
    Emitter<UserProfilesState> emit,
  ) async {
    try {
      await _repository.update(event.profile);
      // Sync will trigger refresh via listeners
    } catch (e) {
      emit(UserProfilesError(e.toString()));
    }
  }

  Future<void> _onDeleteUserProfile(
    DeleteUserProfile event,
    Emitter<UserProfilesState> emit,
  ) async {
    try {
      await _repository.delete(event.id);
      // Sync will trigger refresh via listeners
    } catch (e) {
      emit(UserProfilesError(e.toString()));
    }
  }
}

// Usage in UI
class UserProfilesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserProfilesBloc(
        context.read<UserProfileRepository>(),
        context.read<UniversalSyncManager>(),
      )..add(LoadUserProfiles()),
      child: BlocBuilder<UserProfilesBloc, UserProfilesState>(
        builder: (context, state) {
          if (state is UserProfilesLoading) {
            return CircularProgressIndicator();
          } else if (state is UserProfilesError) {
            return Text('Error: ${state.message}');
          } else if (state is UserProfilesLoaded) {
            return ListView.builder(
              itemCount: state.profiles.length,
              itemBuilder: (context, index) {
                final profile = state.profiles[index];
                return ListTile(
                  title: Text(profile.name),
                  subtitle: Text(profile.email),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => context
                        .read<UserProfilesBloc>()
                        .add(DeleteUserProfile(profile.id)),
                  ),
                );
              },
            );
          }
          return Container();
        },
      ),
    );
  }
}
```

## 📊 Analytics & Monitoring

### 1. Sync Analytics

```dart
class SyncAnalytics {
  final UniversalSyncManager _syncManager;
  final List<SyncMetric> _metrics = [];

  SyncAnalytics(this._syncManager) {
    _setupAnalytics();
  }

  void _setupAnalytics() {
    _syncManager.syncProgressStream.listen((progress) {
      if (progress.status == SyncStatus.completed) {
        _recordSyncMetric(progress);
      }
    });

    _syncManager.syncEventStream.listen((event) {
      _recordEventMetric(event);
    });
  }

  void _recordSyncMetric(SyncProgress progress) {
    final metric = SyncMetric(
      timestamp: DateTime.now(),
      entityName: progress.currentEntity,
      operation: 'sync',
      duration: progress.duration,
      recordsProcessed: progress.recordsProcessed,
      conflictsResolved: progress.conflictsResolved,
      success: progress.status == SyncStatus.completed,
    );

    _metrics.add(metric);
    _sendToAnalytics(metric);
  }

  void _recordEventMetric(SyncEvent event) {
    final metric = SyncMetric(
      timestamp: DateTime.now(),
      entityName: event.collection,
      operation: event.type,
      recordId: event.id,
      success: true,
    );

    _metrics.add(metric);
    _sendToAnalytics(metric);
  }

  void _sendToAnalytics(SyncMetric metric) {
    // Send to your analytics service
    // Example: FirebaseAnalytics.instance.logEvent('sync_operation', {
    //   'entity': metric.entityName,
    //   'operation': metric.operation,
    //   'duration_ms': metric.duration?.inMilliseconds,
    //   'records_processed': metric.recordsProcessed,
    //   'success': metric.success,
    // });
  }

  // Get analytics data
  List<SyncMetric> getMetrics({
    String? entityName,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _metrics.where((metric) {
      if (entityName != null && metric.entityName != entityName) return false;
      if (startDate != null && metric.timestamp.isBefore(startDate)) return false;
      if (endDate != null && metric.timestamp.isAfter(endDate)) return false;
      return true;
    }).toList();
  }

  // Performance insights
  Map<String, dynamic> getPerformanceInsights() {
    final recentMetrics = getMetrics(
      startDate: DateTime.now().subtract(Duration(days: 7)),
    );

    final avgDuration = recentMetrics
        .where((m) => m.duration != null)
        .map((m) => m.duration!.inMilliseconds)
        .average;

    final successRate = recentMetrics
        .where((m) => m.success)
        .length / recentMetrics.length;

    final totalConflicts = recentMetrics
        .fold<int>(0, (sum, m) => sum + (m.conflictsResolved ?? 0));

    return {
      'average_sync_duration_ms': avgDuration,
      'sync_success_rate': successRate,
      'total_conflicts_resolved': totalConflicts,
      'most_active_entity': _getMostActiveEntity(recentMetrics),
    };
  }

  String _getMostActiveEntity(List<SyncMetric> metrics) {
    final entityCounts = <String, int>{};
    for (final metric in metrics) {
      entityCounts[metric.entityName] = (entityCounts[metric.entityName] ?? 0) + 1;
    }

    return entityCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}

class SyncMetric {
  final DateTime timestamp;
  final String entityName;
  final String operation;
  final String? recordId;
  final Duration? duration;
  final int? recordsProcessed;
  final int? conflictsResolved;
  final bool success;

  SyncMetric({
    required this.timestamp,
    required this.entityName,
    required this.operation,
    this.recordId,
    this.duration,
    this.recordsProcessed,
    this.conflictsResolved,
    required this.success,
  });
}

extension on Iterable<num> {
  double get average => isEmpty ? 0 : reduce((a, b) => a + b) / length;
}
```

### 2. Health Monitoring

```dart
class SyncHealthMonitor {
  final UniversalSyncManager _syncManager;
  final Duration _healthCheckInterval = Duration(minutes: 5);

  Timer? _healthCheckTimer;
  bool _isHealthy = true;

  void startMonitoring() {
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (timer) {
      _performHealthCheck();
    });
  }

  void stopMonitoring() {
    _healthCheckTimer?.cancel();
  }

  Future<void> _performHealthCheck() async {
    try {
      // Quick connectivity test
      final result = await _syncManager.query(
        'app_settings',
        SyncQuery(limit: 1),
      );

      final wasHealthy = _isHealthy;
      _isHealthy = result.isSuccess;

      if (wasHealthy && !_isHealthy) {
        _onHealthDegraded();
      } else if (!wasHealthy && _isHealthy) {
        _onHealthRestored();
      }

      // Log health status
      print('🔍 Sync Health Check: ${_isHealthy ? 'HEALTHY' : 'UNHEALTHY'}');

    } catch (e) {
      _isHealthy = false;
      _onHealthDegraded();
      print('🔍 Health check failed: $e');
    }
  }

  void _onHealthDegraded() {
    print('⚠️ Sync health degraded');
    // Notify user or take corrective action
    // Example: show notification, reduce sync frequency, etc.
  }

  void _onHealthRestored() {
    print('✅ Sync health restored');
    // Resume normal operations
  }

  bool get isHealthy => _isHealthy;

  // Get detailed health status
  Future<Map<String, dynamic>> getHealthStatus() async {
    final status = {
      'overall_health': _isHealthy,
      'last_check': DateTime.now(),
      'check_interval': _healthCheckInterval.inMinutes,
    };

    // Add more detailed checks
    try {
      final authCheck = await _checkAuthentication();
      final networkCheck = await _checkNetworkConnectivity();
      final dbCheck = await _checkDatabaseConnectivity();

      status.addAll({
        'authentication': authCheck,
        'network': networkCheck,
        'database': dbCheck,
      });
    } catch (e) {
      status['error'] = e.toString();
    }

    return status;
  }

  Future<bool> _checkAuthentication() async {
    // Check if user is authenticated
    try {
      final user = Supabase.instance.client.auth.currentUser;
      return user != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkNetworkConnectivity() async {
    // Simple network check
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkDatabaseConnectivity() async {
    // Quick database connectivity test
    try {
      final result = await _syncManager.query(
        'app_settings',
        SyncQuery(limit: 1),
      );
      return result.isSuccess;
    } catch (e) {
      return false;
    }
  }
}
```

## 🧪 Advanced Testing Suite

### 1. Performance Testing

```dart
class PerformanceTestSuite {
  final UniversalSyncManager _syncManager;
  final UserProfileRepository _repository;

  PerformanceTestSuite(this._syncManager, this._repository);

  Future<void> runPerformanceTests() async {
    print('⚡ Running Performance Tests...');

    await testLargeDatasetSync();
    await testConcurrentOperations();
    await testMemoryUsage();
    await testNetworkLatency();

    print('✅ Performance Tests Complete');
  }

  Future<void> testLargeDatasetSync() async {
    print('📊 Testing large dataset sync performance...');

    final startTime = DateTime.now();

    // Create 100 test profiles
    final testProfiles = List.generate(100, (i) => UserProfile.create(
      organizationId: 'org-perf-test',
      name: 'Performance Test User $i',
      email: 'perf-test-$i@example.com',
      createdBy: 'perf-test',
    ));

    // Batch create
    for (final profile in testProfiles) {
      await _repository.create(profile);
    }

    // Sync and measure
    final syncStart = DateTime.now();
    final result = await _syncManager.syncEntity('user_profiles');
    final syncDuration = DateTime.now().difference(syncStart);

    print('✅ Large dataset sync results:');
    print('   - Records created: ${testProfiles.length}');
    print('   - Sync duration: ${syncDuration.inSeconds}s');
    print('   - Records/sec: ${(testProfiles.length / syncDuration.inSeconds).round()}');
    print('   - Success: ${result.isSuccess}');

    final totalDuration = DateTime.now().difference(startTime);
    print('   - Total test duration: ${totalDuration.inSeconds}s');
  }

  Future<void> testConcurrentOperations() async {
    print('🔄 Testing concurrent operations...');

    final operations = List.generate(10, (i) => _performConcurrentOperation(i));
    final startTime = DateTime.now();

    await Future.wait(operations);

    final duration = DateTime.now().difference(startTime);
    print('✅ Concurrent operations completed in ${duration.inSeconds}s');
  }

  Future<void> _performConcurrentOperation(int index) async {
    final profile = UserProfile.create(
      organizationId: 'org-concurrent-test',
      name: 'Concurrent Test User $index',
      email: 'concurrent-test-$index@example.com',
      createdBy: 'concurrent-test',
    );

    await _repository.create(profile);
    await _syncManager.syncEntity('user_profiles');
  }

  Future<void> testMemoryUsage() async {
    print('💾 Testing memory usage...');

    // This would require platform-specific memory monitoring
    // For now, we'll simulate the test
    print('✅ Memory usage test placeholder');
  }

  Future<void> testNetworkLatency() async {
    print('🌐 Testing network latency...');

    final latencies = <int>[];

    for (int i = 0; i < 5; i++) {
      final start = DateTime.now();
      await _syncManager.query('app_settings', SyncQuery(limit: 1));
      final latency = DateTime.now().difference(start).inMilliseconds;
      latencies.add(latency);
    }

    final avgLatency = latencies.reduce((a, b) => a + b) ~/ latencies.length;
    print('✅ Average network latency: ${avgLatency}ms');
  }
}
```

## 📋 Next Steps

1. **[Code Examples](../examples/)** - Copy-paste code for common scenarios
2. **[Testing Guide](../testing.md)** - Comprehensive testing of advanced features
3. **[Troubleshooting](../troubleshooting.md)** - Advanced issues and solutions

## 🆘 Troubleshooting

**Performance Issues:**
- Check database indexes
- Review query optimization
- Monitor memory usage
- Adjust batch sizes

**State Management Issues:**
- Verify provider setup
- Check listener subscriptions
- Review error handling
- Test with smaller datasets first

**Background Processing Issues:**
- Check platform permissions
- Verify work manager setup
- Review queue implementation
- Monitor battery optimization settings