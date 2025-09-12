import 'usm_sync_enums.dart';

/// Custom sync strategies for Universal Sync Manager
///
/// This class provides customizable synchronization strategies that can be
/// applied per entity or globally to control sync behavior.
///
/// Following USM naming conventions:
/// - File: usm_sync_strategies.dart (snake_case with usm_ prefix)
/// - Class: SyncStrategy (PascalCase)
abstract class SyncStrategy {
  const SyncStrategy({
    required this.name,
    required this.description,
    this.priority = SyncPriority.normal,
    this.enabled = true,
  });

  /// Strategy name
  final String name;

  /// Strategy description
  final String description;

  /// Strategy priority
  final SyncPriority priority;

  /// Strategy is enabled
  final bool enabled;

  /// Determine if sync should proceed
  Future<bool> shouldSync(SyncContext context);

  /// Prepare data before sync
  Future<Map<String, dynamic>> prepareData(
    Map<String, dynamic> data,
    SyncContext context,
  );

  /// Handle sync result
  Future<SyncStrategyResult> handleResult(
    SyncResult result,
    SyncContext context,
  );

  /// Handle sync conflict
  Future<ConflictResolution> resolveConflict(
    SyncConflict conflict,
    SyncContext context,
  );

  /// Get strategy configuration
  Map<String, dynamic> getConfiguration();

  /// Update strategy configuration
  void updateConfiguration(Map<String, dynamic> config);
}

/// Timestamp-based sync strategy
class TimestampSyncStrategy extends SyncStrategy {
  TimestampSyncStrategy({
    this.syncIntervalMinutes = 5,
    this.maxRetries = 3,
    this.batchSize = 100,
    super.priority = SyncPriority.normal,
  }) : super(
          name: 'timestamp',
          description: 'Sync based on timestamp comparison',
        );

  int syncIntervalMinutes;
  int maxRetries;
  int batchSize;

  @override
  Future<bool> shouldSync(SyncContext context) async {
    final lastSync = context.lastSyncTime;
    if (lastSync == null) return true;

    final now = DateTime.now();
    final interval = Duration(minutes: syncIntervalMinutes);

    return now.difference(lastSync) >= interval;
  }

  @override
  Future<Map<String, dynamic>> prepareData(
    Map<String, dynamic> data,
    SyncContext context,
  ) async {
    // Add timestamp for comparison
    data['lastModified'] = DateTime.now().toIso8601String();
    return data;
  }

  @override
  Future<SyncStrategyResult> handleResult(
    SyncResult result,
    SyncContext context,
  ) async {
    if (result.isSuccess) {
      return SyncStrategyResult.success(
        message: 'Timestamp sync completed successfully',
      );
    }

    // Implement retry logic
    final retryCount = context.retryCount ?? 0;
    if (retryCount < maxRetries) {
      return SyncStrategyResult.retry(
        message: 'Retrying sync (attempt ${retryCount + 1}/$maxRetries)',
        delay: Duration(seconds: (retryCount + 1) * 2),
      );
    }

    return SyncStrategyResult.failure(
      message: 'Timestamp sync failed after $maxRetries attempts',
      error: result.error,
    );
  }

  @override
  Future<ConflictResolution> resolveConflict(
    SyncConflict conflict,
    SyncContext context,
  ) async {
    // Use timestamp to resolve conflicts
    final localTime = conflict.localData['lastModified'] as String?;
    final remoteTime = conflict.remoteData['lastModified'] as String?;

    if (localTime != null && remoteTime != null) {
      final localDateTime = DateTime.parse(localTime);
      final remoteDateTime = DateTime.parse(remoteTime);

      if (localDateTime.isAfter(remoteDateTime)) {
        return ConflictResolution.useLocal();
      } else {
        return ConflictResolution.useRemote();
      }
    }

    // Default to remote if timestamps are missing
    return ConflictResolution.useRemote();
  }

  @override
  Map<String, dynamic> getConfiguration() {
    return {
      'syncIntervalMinutes': syncIntervalMinutes,
      'maxRetries': maxRetries,
      'batchSize': batchSize,
    };
  }

  @override
  void updateConfiguration(Map<String, dynamic> config) {
    syncIntervalMinutes =
        config['syncIntervalMinutes'] as int? ?? syncIntervalMinutes;
    maxRetries = config['maxRetries'] as int? ?? maxRetries;
    batchSize = config['batchSize'] as int? ?? batchSize;
  }
}

/// Priority-based sync strategy
class PrioritySyncStrategy extends SyncStrategy {
  PrioritySyncStrategy({
    this.highPriorityFirst = true,
    this.priorityWeights = const {
      SyncPriority.critical: 10,
      SyncPriority.high: 5,
      SyncPriority.normal: 1,
      SyncPriority.low: 0.5,
    },
    super.priority = SyncPriority.high,
  }) : super(
          name: 'priority',
          description: 'Sync based on data priority',
        );

  bool highPriorityFirst;
  Map<SyncPriority, double> priorityWeights;

  @override
  Future<bool> shouldSync(SyncContext context) async {
    final entityPriority = context.entityPriority ?? SyncPriority.normal;
    final weight = priorityWeights[entityPriority] ?? 1.0;

    // Higher weight = more likely to sync
    return weight >= 1.0;
  }

  @override
  Future<Map<String, dynamic>> prepareData(
    Map<String, dynamic> data,
    SyncContext context,
  ) async {
    // Add priority information
    data['syncPriority'] = context.entityPriority?.name ?? 'normal';
    return data;
  }

  @override
  Future<SyncStrategyResult> handleResult(
    SyncResult result,
    SyncContext context,
  ) async {
    if (result.isSuccess) {
      return SyncStrategyResult.success(
        message: 'Priority sync completed successfully',
      );
    }

    // High priority items get more retries
    final entityPriority = context.entityPriority ?? SyncPriority.normal;
    final maxRetries = _getMaxRetriesForPriority(entityPriority);
    final retryCount = context.retryCount ?? 0;

    if (retryCount < maxRetries) {
      return SyncStrategyResult.retry(
        message: 'Retrying high priority sync',
        delay: Duration(seconds: 1),
      );
    }

    return SyncStrategyResult.failure(
      message: 'Priority sync failed',
      error: result.error,
    );
  }

  @override
  Future<ConflictResolution> resolveConflict(
    SyncConflict conflict,
    SyncContext context,
  ) async {
    // High priority entities prefer local data
    final entityPriority = context.entityPriority ?? SyncPriority.normal;

    if (entityPriority == SyncPriority.critical ||
        entityPriority == SyncPriority.high) {
      return ConflictResolution.useLocal();
    }

    return ConflictResolution.useRemote();
  }

  int _getMaxRetriesForPriority(SyncPriority priority) {
    switch (priority) {
      case SyncPriority.critical:
        return 5;
      case SyncPriority.high:
        return 3;
      case SyncPriority.normal:
        return 2;
      case SyncPriority.low:
        return 1;
    }
  }

  @override
  Map<String, dynamic> getConfiguration() {
    return {
      'highPriorityFirst': highPriorityFirst,
      'priorityWeights': priorityWeights.map(
        (key, value) => MapEntry(key.name, value),
      ),
    };
  }

  @override
  void updateConfiguration(Map<String, dynamic> config) {
    highPriorityFirst =
        config['highPriorityFirst'] as bool? ?? highPriorityFirst;

    if (config['priorityWeights'] != null) {
      final weights = config['priorityWeights'] as Map<String, dynamic>;
      priorityWeights = weights.map(
        (key, value) => MapEntry(
          SyncPriority.values.firstWhere((e) => e.name == key),
          (value as num).toDouble(),
        ),
      );
    }
  }
}

/// Conflict-aware sync strategy
class ConflictAwareSyncStrategy extends SyncStrategy {
  ConflictAwareSyncStrategy({
    this.defaultResolution = ConflictResolutionStrategy.timestampWins,
    this.fieldLevelResolution = false,
    this.preserveLocalChanges = true,
    super.priority = SyncPriority.normal,
  }) : super(
          name: 'conflict_aware',
          description: 'Advanced conflict detection and resolution',
        );

  ConflictResolutionStrategy defaultResolution;
  bool fieldLevelResolution;
  bool preserveLocalChanges;

  @override
  Future<bool> shouldSync(SyncContext context) async {
    // Always sync but handle conflicts carefully
    return true;
  }

  @override
  Future<Map<String, dynamic>> prepareData(
    Map<String, dynamic> data,
    SyncContext context,
  ) async {
    // Add conflict detection metadata
    data['conflictHash'] = _generateHash(data);
    data['sync_version'] = (data['sync_version'] as int? ?? 0) + 1;
    return data;
  }

  @override
  Future<SyncStrategyResult> handleResult(
    SyncResult result,
    SyncContext context,
  ) async {
    if (result.isSuccess) {
      return SyncStrategyResult.success(
        message: 'Conflict-aware sync completed',
      );
    }

    if (result.hasConflict) {
      return SyncStrategyResult.conflict(
        message: 'Conflict detected, resolution required',
        conflict: result.conflict,
      );
    }

    return SyncStrategyResult.failure(
      message: 'Sync failed',
      error: result.error,
    );
  }

  @override
  Future<ConflictResolution> resolveConflict(
    SyncConflict conflict,
    SyncContext context,
  ) async {
    switch (defaultResolution) {
      case ConflictResolutionStrategy.localWins:
        return ConflictResolution.useLocal();

      case ConflictResolutionStrategy.serverWins:
      case ConflictResolutionStrategy.remoteWins:
        return ConflictResolution.useRemote();

      case ConflictResolutionStrategy.timestampWins:
        return _resolveByTimestamp(conflict);

      case ConflictResolutionStrategy.mergeOrPrompt:
        return _mergeConflict(conflict);

      case ConflictResolutionStrategy.manualResolution:
      case ConflictResolutionStrategy.manual:
        return ConflictResolution.manual(
          message: 'Manual resolution required',
        );

      case ConflictResolutionStrategy.custom:
        return _resolveByTimestamp(conflict); // Default fallback

      case ConflictResolutionStrategy.newestWins:
        return _resolveByVersion(conflict);

      case ConflictResolutionStrategy.oldestWins:
        return _resolveByVersion(conflict, preferOlder: true);

      case ConflictResolutionStrategy.intelligentMerge:
        return _intelligentMerge(conflict);
    }
  }

  Future<ConflictResolution> _resolveByTimestamp(SyncConflict conflict) async {
    final localTime = conflict.localData['updated_at'] as String?;
    final remoteTime = conflict.remoteData['updated_at'] as String?;

    if (localTime != null && remoteTime != null) {
      final localDateTime = DateTime.parse(localTime);
      final remoteDateTime = DateTime.parse(remoteTime);

      return localDateTime.isAfter(remoteDateTime)
          ? ConflictResolution.useLocal()
          : ConflictResolution.useRemote();
    }

    return ConflictResolution.useRemote();
  }

  Future<ConflictResolution> _resolveByVersion(SyncConflict conflict,
      {bool preferOlder = false}) async {
    final localVersion = conflict.localData['sync_version'] as int?;
    final remoteVersion = conflict.remoteData['sync_version'] as int?;

    if (localVersion != null && remoteVersion != null) {
      if (preferOlder) {
        return localVersion < remoteVersion
            ? ConflictResolution.useLocal()
            : ConflictResolution.useRemote();
      } else {
        return localVersion > remoteVersion
            ? ConflictResolution.useLocal()
            : ConflictResolution.useRemote();
      }
    }

    return ConflictResolution.useRemote();
  }

  Future<ConflictResolution> _intelligentMerge(SyncConflict conflict) async {
    // Start with all fields from remote
    final mergedData = Map<String, dynamic>.from(conflict.remoteData);

    // Field-level inspection to determine the best values
    for (final field in conflict.fieldConflicts.keys) {
      // Use local value for specific fields based on business logic
      if (_shouldPreferLocalField(
          field, conflict.localData[field], conflict.remoteData[field])) {
        mergedData[field] = conflict.localData[field];
      }
    }

    return ConflictResolution.merge(mergedData);
  }

  bool _shouldPreferLocalField(
      String field, dynamic localValue, dynamic remoteValue) {
    // Example logic: prefer local version for description fields
    if (field == 'description' || field.endsWith('Notes')) {
      return true;
    }

    // Always take the non-null value if one side is null
    if (localValue != null && remoteValue == null) {
      return true;
    }

    // Default to remote values
    return false;
  }

  Future<ConflictResolution> _mergeConflict(SyncConflict conflict) async {
    if (!fieldLevelResolution) {
      return ConflictResolution.useLocal();
    }

    final mergedData = <String, dynamic>{};
    final localData = conflict.localData;
    final remoteData = conflict.remoteData;

    // Merge field by field
    final allKeys = {...localData.keys, ...remoteData.keys};

    for (final key in allKeys) {
      if (preserveLocalChanges && localData.containsKey(key)) {
        mergedData[key] = localData[key];
      } else if (remoteData.containsKey(key)) {
        mergedData[key] = remoteData[key];
      }
    }

    return ConflictResolution.merge(mergedData);
  }

  String _generateHash(Map<String, dynamic> data) {
    // Simple hash generation for conflict detection
    return data.toString().hashCode.toString();
  }

  @override
  Map<String, dynamic> getConfiguration() {
    return {
      'defaultResolution': defaultResolution.name,
      'fieldLevelResolution': fieldLevelResolution,
      'preserveLocalChanges': preserveLocalChanges,
    };
  }

  @override
  void updateConfiguration(Map<String, dynamic> config) {
    if (config['defaultResolution'] != null) {
      defaultResolution = ConflictResolutionStrategy.values
          .firstWhere((e) => e.name == config['defaultResolution']);
    }

    fieldLevelResolution =
        config['fieldLevelResolution'] as bool? ?? fieldLevelResolution;
    preserveLocalChanges =
        config['preserveLocalChanges'] as bool? ?? preserveLocalChanges;
  }
}

/// Custom sync strategy that can be configured with functions
class CustomSyncStrategy extends SyncStrategy {
  CustomSyncStrategy({
    required String name,
    required String description,
    this.shouldSyncFunction,
    this.prepareDataFunction,
    this.handleResultFunction,
    this.resolveConflictFunction,
    this.configuration = const {},
    super.priority = SyncPriority.normal,
  }) : super(name: name, description: description);

  final Future<bool> Function(SyncContext context)? shouldSyncFunction;
  final Future<Map<String, dynamic>> Function(
      Map<String, dynamic> data, SyncContext context)? prepareDataFunction;
  final Future<SyncStrategyResult> Function(
      SyncResult result, SyncContext context)? handleResultFunction;
  final Future<ConflictResolution> Function(
      SyncConflict conflict, SyncContext context)? resolveConflictFunction;

  Map<String, dynamic> configuration;

  @override
  Future<bool> shouldSync(SyncContext context) async {
    return shouldSyncFunction?.call(context) ?? true;
  }

  @override
  Future<Map<String, dynamic>> prepareData(
    Map<String, dynamic> data,
    SyncContext context,
  ) async {
    return prepareDataFunction?.call(data, context) ?? data;
  }

  @override
  Future<SyncStrategyResult> handleResult(
    SyncResult result,
    SyncContext context,
  ) async {
    return handleResultFunction?.call(result, context) ??
        (result.isSuccess
            ? SyncStrategyResult.success(message: 'Custom sync completed')
            : SyncStrategyResult.failure(
                message: 'Custom sync failed', error: result.error));
  }

  @override
  Future<ConflictResolution> resolveConflict(
    SyncConflict conflict,
    SyncContext context,
  ) async {
    return resolveConflictFunction?.call(conflict, context) ??
        ConflictResolution.useRemote();
  }

  @override
  Map<String, dynamic> getConfiguration() => configuration;

  @override
  void updateConfiguration(Map<String, dynamic> config) {
    configuration = {...configuration, ...config};
  }
}

/// Sync strategy manager
class SyncStrategyManager {
  final Map<String, SyncStrategy> _strategies = {};
  final Map<String, String> _entityStrategies = {};

  /// Register a sync strategy
  void registerStrategy(SyncStrategy strategy) {
    _strategies[strategy.name] = strategy;
  }

  /// Set strategy for specific entity
  void setEntityStrategy(String entityName, String strategyName) {
    if (_strategies.containsKey(strategyName)) {
      _entityStrategies[entityName] = strategyName;
    }
  }

  /// Get strategy for entity
  SyncStrategy? getEntityStrategy(String entityName) {
    final strategyName = _entityStrategies[entityName];
    return strategyName != null ? _strategies[strategyName] : null;
  }

  /// Get all registered strategies
  Map<String, SyncStrategy> getAllStrategies() => Map.unmodifiable(_strategies);

  /// Remove strategy
  void removeStrategy(String strategyName) {
    _strategies.remove(strategyName);
    _entityStrategies.removeWhere((key, value) => value == strategyName);
  }

  /// Clear all strategies
  void clear() {
    _strategies.clear();
    _entityStrategies.clear();
  }
}

/// Sync context for strategy execution
class SyncContext {
  const SyncContext({
    this.entityName,
    this.entityPriority,
    this.lastSyncTime,
    this.retryCount,
    this.userId,
    this.organizationId,
    this.metadata = const {},
  });

  final String? entityName;
  final SyncPriority? entityPriority;
  final DateTime? lastSyncTime;
  final int? retryCount;
  final String? userId;
  final String? organizationId;
  final Map<String, dynamic> metadata;

  SyncContext copyWith({
    String? entityName,
    SyncPriority? entityPriority,
    DateTime? lastSyncTime,
    int? retryCount,
    String? userId,
    String? organizationId,
    Map<String, dynamic>? metadata,
  }) {
    return SyncContext(
      entityName: entityName ?? this.entityName,
      entityPriority: entityPriority ?? this.entityPriority,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      retryCount: retryCount ?? this.retryCount,
      userId: userId ?? this.userId,
      organizationId: organizationId ?? this.organizationId,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Sync strategy result
class SyncStrategyResult {
  const SyncStrategyResult({
    required this.status,
    this.message,
    this.error,
    this.conflict,
    this.delay,
  });

  final SyncStrategyStatus status;
  final String? message;
  final dynamic error;
  final SyncConflict? conflict;
  final Duration? delay;

  factory SyncStrategyResult.success({String? message}) {
    return SyncStrategyResult(
      status: SyncStrategyStatus.success,
      message: message,
    );
  }

  factory SyncStrategyResult.failure({String? message, dynamic error}) {
    return SyncStrategyResult(
      status: SyncStrategyStatus.failure,
      message: message,
      error: error,
    );
  }

  factory SyncStrategyResult.retry({String? message, Duration? delay}) {
    return SyncStrategyResult(
      status: SyncStrategyStatus.retry,
      message: message,
      delay: delay,
    );
  }

  factory SyncStrategyResult.conflict(
      {String? message, SyncConflict? conflict}) {
    return SyncStrategyResult(
      status: SyncStrategyStatus.conflict,
      message: message,
      conflict: conflict,
    );
  }

  bool get isSuccess => status == SyncStrategyStatus.success;
  bool get isFailure => status == SyncStrategyStatus.failure;
  bool get shouldRetry => status == SyncStrategyStatus.retry;
  bool get hasConflict => status == SyncStrategyStatus.conflict;
}

/// Conflict resolution result
class ConflictResolution {
  const ConflictResolution({
    required this.action,
    this.data,
    this.message,
  });

  final ConflictResolutionAction action;
  final Map<String, dynamic>? data;
  final String? message;

  factory ConflictResolution.useLocal() {
    return const ConflictResolution(action: ConflictResolutionAction.useLocal);
  }

  factory ConflictResolution.useRemote() {
    return const ConflictResolution(action: ConflictResolutionAction.useRemote);
  }

  factory ConflictResolution.merge(Map<String, dynamic> mergedData) {
    return ConflictResolution(
      action: ConflictResolutionAction.merge,
      data: mergedData,
    );
  }

  factory ConflictResolution.manual({String? message}) {
    return ConflictResolution(
      action: ConflictResolutionAction.manual,
      message: message,
    );
  }
}

/// Supporting enums and classes
enum SyncStrategyStatus {
  success,
  failure,
  retry,
  conflict,
}

enum ConflictResolutionAction {
  useLocal,
  useRemote,
  merge,
  manual,
}

/// Placeholder classes for integration
class SyncResult {
  const SyncResult({
    required this.isSuccess,
    this.error,
    this.conflict,
  });

  final bool isSuccess;
  final dynamic error;
  final SyncConflict? conflict;

  bool get hasConflict => conflict != null;
}

class SyncConflict {
  const SyncConflict({
    required this.localData,
    required this.remoteData,
    this.fieldConflicts = const {},
  });

  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final Map<String, dynamic> fieldConflicts;
}
