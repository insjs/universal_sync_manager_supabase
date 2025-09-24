/// Enumeration definitions for Universal Sync Manager configuration
///
/// This file contains all the enum types used throughout the USM configuration
/// system to ensure type safety and consistent behavior across different
/// components.
library;

/// Defines how the sync manager operates
enum SyncMode {
  /// Manual sync only - no automatic synchronization
  manual,

  /// Automatic sync based on data changes and intervals
  automatic,

  /// Scheduled sync at specific intervals regardless of changes
  scheduled,

  /// Real-time sync with immediate propagation when possible
  realtime,

  /// Hybrid mode combining automatic and manual triggers
  hybrid,

  /// Offline-only mode with no network synchronization
  offline,

  /// Intelligent sync based on usage patterns (from usm_sync_scheduler.dart)
  intelligent,
}

/// Synchronization direction
///
/// Specifies the flow of data during sync operations.
enum SyncDirection {
  /// Data flows in both directions (local ↔ remote)
  bidirectional,

  /// Data only flows from local to remote (local → remote)
  uploadOnly,

  /// Data only flows from remote to local (remote → local)
  downloadOnly,

  /// Alias for uploadOnly (from usm_universal_sync_manager.dart)
  upload,

  /// Alias for downloadOnly (from usm_universal_sync_manager.dart)
  download,
}

/// Synchronization frequency
///
/// Defines how often sync operations should be performed
/// in automatic mode.
enum SyncFrequency {
  /// Real-time synchronization as changes occur
  realTime,

  /// Immediate synchronization after local changes
  immediate,

  /// Periodic synchronization at regular intervals
  periodic,

  /// On-demand synchronization only when requested
  onDemand,
}

/// Synchronization strategies
///
/// Defines the approach used for handling data synchronization
/// between local and remote sources.
enum SyncStrategy {
  /// Last write wins - most recent change takes precedence
  lastWriteWins,

  /// Merge changes automatically when possible
  mergeChanges,

  /// Require manual conflict resolution
  manualResolve,

  /// Keep both versions and let user decide
  keepBoth,
}

/// Strategies for resolving conflicts when the same data is modified
/// in multiple places
enum ConflictResolutionStrategy {
  /// Local changes always win over remote changes
  localWins,

  /// Remote changes always win over local changes
  serverWins,

  /// Also known as remoteWins in some implementations
  remoteWins,

  /// Use timestamps - most recent modification wins
  timestampWins,

  /// Merge changes when possible, otherwise prompt user
  mergeOrPrompt,

  /// Always prompt user to resolve conflicts manually
  manualResolution,

  /// Also known as manual in some implementations
  manual,

  /// Use custom resolution logic defined per entity
  custom,

  /// Use the most recently updated version
  newestWins,

  /// Use the oldest version
  oldestWins,

  /// Merge fields intelligently
  intelligentMerge,
}

/// Priority levels for sync operations
enum SyncPriority {
  /// Lowest priority - sync when resources are available
  low,

  /// Normal priority - default sync behavior
  normal,

  /// High priority - prioritize over normal operations
  high,

  /// Critical priority - sync immediately regardless of resources
  critical,
}

/// Environment types for different deployment scenarios
enum SyncEnvironment {
  /// Development environment with debugging features
  development,

  /// Testing environment for automated tests
  testing,

  /// Staging environment for pre-production testing
  staging,

  /// Production environment with optimized performance
  production,
}

/// Network conditions that affect sync behavior
enum NetworkCondition {
  /// No network connection available
  offline,

  /// Limited connectivity (slow or expensive)
  limited,

  /// Good connectivity for normal operations
  good,

  /// Excellent connectivity for real-time operations
  excellent,

  /// High-speed connection (WiFi, Ethernet)
  highSpeed,

  /// Medium-speed connection (4G)
  mediumSpeed,

  /// Low-speed connection (3G, slow connection)
  lowSpeed,

  /// Unknown network state
  unknown,
}

/// Types of sync operations
enum SyncOperationType {
  /// Create new records
  create,

  /// Update existing records
  update,

  /// Delete records (soft or hard delete)
  delete,

  /// Read/query operations
  read,

  /// Query operations
  query,

  /// Batch create operation
  batchCreate,

  /// Batch update operation
  batchUpdate,

  /// Batch operations involving multiple records
  batch,
}

/// Compression algorithms available for sync payloads
enum CompressionType {
  /// No compression
  none,

  /// GZIP compression
  gzip,

  /// Brotli compression
  brotli,

  /// LZ4 compression for speed
  lz4,
}

/// Security levels for different types of data
enum SecurityLevel {
  /// Public data that doesn't need encryption
  public,

  /// Internal data that needs basic protection
  internal,

  /// Sensitive data requiring encryption
  sensitive,

  /// Highly sensitive data requiring advanced encryption
  restricted,
}

/// Retry strategies for failed operations
enum RetryStrategy {
  /// No retries - fail immediately
  none,

  /// Linear backoff with fixed intervals
  linear,

  /// Exponential backoff with increasing intervals
  exponential,

  /// Custom retry logic defined per operation
  custom,
}

/// Logging levels for sync operations
enum LogLevel {
  /// No logging
  none,

  /// Only error messages
  error,

  /// Warnings and errors
  warning,

  /// Info, warnings, and errors
  info,

  /// Detailed debugging information
  debug,

  /// Extremely verbose logging
  verbose,

  /// Critical errors requiring immediate attention
  critical,
}

/// Categories for log messages
enum LogCategory {
  /// Synchronization-related logs
  sync,

  /// Conflict detection and resolution logs
  conflict,

  /// Network connectivity and requests logs
  network,

  /// Performance metrics and optimizations
  performance,

  /// Authentication and security logs
  authentication,

  /// Data operations and transformations
  data,

  /// System-level operations
  system,

  /// Recovery and error handling
  recovery,

  /// Debugging information
  debug,
}

/// Connection states for real-time subscriptions
enum SyncConnectionState {
  /// Connection is being established
  connecting,

  /// Successfully connected and receiving events
  connected,

  /// Connection was lost
  disconnected,

  /// Connection failed to establish
  failed,

  /// Connection is being reconnected
  reconnecting,
}

/// Status of a real-time subscription
enum SyncSubscriptionStatus {
  /// Subscription is active and receiving events
  active,

  /// Subscription is temporarily paused
  paused,

  /// Subscription has been cancelled
  cancelled,

  /// Subscription is in error state
  error,

  /// Subscription is being established
  connecting,
}

/// Types of batch processing strategies
enum BatchType {
  /// Process operations one by one
  sequential,

  /// Process operations in parallel
  parallel,

  /// Process operations in chunks
  chunked,

  /// Adaptively adjust strategy based on performance
  adaptive,
}

/// System resource availability
enum SystemResources {
  /// Limited system resources
  limited,

  /// Normal system resources
  normal,

  /// High system resources
  high,
}

/// Types of field conflicts
enum ConflictType {
  /// Values are different between local and remote
  valueDifference,

  /// Field exists locally but not remotely
  localOnly,

  /// Field exists remotely but not locally
  remoteOnly,

  /// Both sides have been updated since last sync
  concurrentUpdate,

  /// Data type mismatch between local and remote
  typeMismatch,
}

/// Enhanced conflict types with more granular detection
enum EnhancedConflictType {
  /// Simple value difference
  valueDifference,

  /// Field exists only locally
  localOnly,

  /// Field exists only remotely
  remoteOnly,

  /// Concurrent updates detected
  concurrentUpdate,

  /// Type mismatch between values
  typeMismatch,

  /// Semantic conflict (e.g., conflicting business rules)
  semanticConflict,

  /// Schema version mismatch
  schemaVersionMismatch,

  /// Complex object structure conflict
  structuralConflict,

  /// Array/list element conflicts
  arrayElementConflict,

  /// Reference/foreign key conflicts
  referenceConflict,
}

/// Event priority levels
enum EventPriority {
  /// Critical events that need immediate attention
  critical,

  /// High priority events
  high,

  /// Normal priority events
  normal,

  /// Low priority events (background events)
  low,
}

/// Enhanced conflict resolution strategies
enum EnhancedConflictResolutionStrategy {
  /// Always use local version
  localWins,

  /// Always use remote version
  remoteWins,

  /// Use most recently updated version
  newestWins,

  /// Use oldest version
  oldestWins,

  /// Intelligent field-by-field merge
  intelligentMerge,

  /// Require manual user intervention
  manual,

  /// Use custom resolver logic
  custom,

  /// Merge arrays intelligently
  arrayMerge,

  /// Priority-based resolution
  priorityBased,

  /// Machine learning assisted resolution
  mlAssisted,

  /// Rule-based resolution using business rules
  ruleBased,

  /// Interactive resolution with user guidance
  interactive,

  /// Conflict avoidance through optimistic locking
  optimisticLocking,

  /// Three-way merge using common ancestor
  threeWayMerge,
}

/// Types of scheduling events
enum ScheduleEventType {
  /// Entity sync was scheduled
  scheduled,

  /// Sync was triggered by schedule
  syncTriggered,

  /// Sync completed
  syncCompleted,

  /// Entity scheduling was paused
  paused,

  /// Entity scheduling was resumed
  resumed,

  /// Scheduling strategy was changed
  strategyChanged,
}

/// Types of entity sync strategies
enum EntitySyncStrategy {
  /// Fixed interval sync
  fixed,

  /// Adaptive interval based on patterns
  adaptive,

  /// More frequent syncing
  aggressive,

  /// Less frequent syncing
  conservative,
}

/// Types of scheduling strategies
enum SchedulingStrategyType {
  /// Adapts based on usage patterns
  adaptive,

  /// Conservative with longer intervals
  conservative,

  /// Aggressive with shorter intervals
  aggressive,

  /// Fixed intervals regardless of patterns
  fixed,
}

/// Types of recommendations
enum RecommendationType {
  /// Reduce sync frequency
  reduceFrequency,

  /// Increase sync frequency
  increaseFrequency,

  /// Improve sync reliability
  improveReliability,

  /// Optimize for battery usage
  batteryOptimization,

  /// System-wide optimization
  systemOptimization,
}

/// Impact level of recommendations
enum RecommendationImpact {
  /// Low impact
  low,

  /// Medium impact
  medium,

  /// High impact
  high,
}

/// System resource levels
enum SystemResourceLevel {
  /// Low system resources
  low,

  /// Normal system resources
  normal,

  /// High system resources
  high,
}

/// Types of sync events that can be subscribed to
enum SyncEventType {
  /// New record created
  create,

  /// Existing record updated
  update,

  /// Record deleted
  delete,

  /// Sync operation started
  syncStarted,

  /// Sync operation completed
  syncCompleted,

  /// Sync operation failed
  syncFailed,

  /// Conflict detected
  conflict,

  /// Connection state changed
  connectionChanged,

  /// Connection status changed (from usm_sync_event.dart)
  connection,

  /// An error occurred (from usm_sync_event.dart)
  error,

  /// Unknown event type (from usm_sync_event.dart)
  unknown,
}

/// States that a sync operation can be in
enum SyncState {
  /// Operation is idle/not running
  idle,

  /// Operation is currently running
  running,

  /// Operation completed successfully
  completed,

  /// Operation failed with errors
  failed,

  /// Operation was cancelled
  cancelled,

  /// Operation is paused
  paused,

  /// Operation is waiting to retry
  retrying,
}

/// Extension methods for enum conversion and utility functions
extension SyncModeExtension on SyncMode {
  /// Get a human-readable description of the sync mode
  String get description {
    switch (this) {
      case SyncMode.manual:
        return 'Manual synchronization only';
      case SyncMode.automatic:
        return 'Automatic synchronization based on changes';
      case SyncMode.scheduled:
        return 'Scheduled synchronization at intervals';
      case SyncMode.realtime:
        return 'Real-time synchronization';
      case SyncMode.hybrid:
        return 'Hybrid mode combining automatic and manual triggers';
      case SyncMode.offline:
        return 'Offline-only mode with no network synchronization';
      case SyncMode.intelligent:
        return 'Intelligent synchronization based on usage patterns';
    }
  }

  /// Check if this mode requires automatic scheduling
  bool get requiresScheduling {
    return this == SyncMode.automatic ||
        this == SyncMode.scheduled ||
        this == SyncMode.hybrid ||
        this == SyncMode.intelligent;
  }
}

/// Types of sync actions that can be performed
enum SyncAction {
  /// Creating a new record
  create,

  /// Reading/fetching a record
  read,

  /// Updating an existing record
  update,

  /// Deleting a record
  delete,

  /// Querying multiple records
  query,

  /// Batch create operation
  batchCreate,

  /// Batch update operation
  batchUpdate,

  /// Batch delete operation
  batchDelete,

  /// Subscribing to real-time updates
  subscribe,

  /// Unsubscribing from real-time updates
  unsubscribe,

  /// Connection establishment
  connect,

  /// Disconnection
  disconnect,

  /// Unknown action
  unknown,
}

/// Types of sync errors that can occur
enum SyncErrorType {
  /// Network connectivity issues
  network,

  /// Authentication failures
  authentication,

  /// Authorization/permission issues
  authorization,

  /// Data validation errors
  validation,

  /// Sync conflicts between local and remote data
  conflict,

  /// Operation timeout
  timeout,

  /// Rate limiting by the backend
  rateLimit,

  /// Backend service errors
  backend,

  /// Unknown or unexpected errors
  unknown,
}

extension ConflictResolutionStrategyExtension on ConflictResolutionStrategy {
  /// Get a human-readable description of the strategy
  String get description {
    switch (this) {
      case ConflictResolutionStrategy.localWins:
        return 'Local changes take precedence';
      case ConflictResolutionStrategy.serverWins:
      case ConflictResolutionStrategy.remoteWins:
        return 'Server changes take precedence';
      case ConflictResolutionStrategy.timestampWins:
        return 'Most recent changes win';
      case ConflictResolutionStrategy.mergeOrPrompt:
        return 'Merge when possible, otherwise prompt';
      case ConflictResolutionStrategy.manualResolution:
      case ConflictResolutionStrategy.manual:
        return 'Always require manual resolution';
      case ConflictResolutionStrategy.custom:
        return 'Use custom resolution logic';
      case ConflictResolutionStrategy.newestWins:
        return 'Most recent changes win (by version)';
      case ConflictResolutionStrategy.oldestWins:
        return 'Oldest changes take precedence';
      case ConflictResolutionStrategy.intelligentMerge:
        return 'Intelligently merge changes';
    }
  }

  /// Check if this strategy requires user interaction
  bool get requiresUserInteraction {
    return this == ConflictResolutionStrategy.manualResolution ||
        this == ConflictResolutionStrategy.manual ||
        this == ConflictResolutionStrategy.mergeOrPrompt;
  }
}

extension SyncPriorityExtension on SyncPriority {
  /// Get numeric value for priority comparison
  int get value {
    switch (this) {
      case SyncPriority.low:
        return 1;
      case SyncPriority.normal:
        return 2;
      case SyncPriority.high:
        return 3;
      case SyncPriority.critical:
        return 4;
    }
  }
}

extension LogLevelExtension on LogLevel {
  /// Check if this level should log a specific message type
  bool shouldLog(LogLevel messageLevel) {
    return messageLevel.index <= index;
  }
}
