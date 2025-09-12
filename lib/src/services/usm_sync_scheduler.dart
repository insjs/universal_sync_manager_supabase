import 'dart:async';
import 'dart:math';
import '../config/usm_sync_enums.dart';

/// Battery conditions affecting sync scheduling
enum BatteryCondition {
  /// Battery is charging
  charging,

  /// High battery level (>70%)
  high,

  /// Medium battery level (30-70%)
  medium,

  /// Low battery level (<30%)
  low,

  /// Critical battery level (<10%)
  critical,

  /// Unknown battery state
  unknown,
}

/// Sync schedule configuration
class SyncScheduleConfig {
  final SyncMode mode;
  final Duration interval;
  final Duration retryDelay;
  final int maxRetries;
  final bool syncOnlyOnWifi;
  final bool syncOnlyWhenCharging;
  final bool enableIntelligentScheduling;
  final Duration intelligentSyncWindow;
  final List<TimeOfDay> scheduledTimes;
  final Map<String, Duration> collectionIntervals;
  final Duration backoffMultiplier;
  final Duration maxBackoffDelay;

  const SyncScheduleConfig({
    this.mode = SyncMode.automatic,
    this.interval = const Duration(minutes: 15),
    this.retryDelay = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.syncOnlyOnWifi = false,
    this.syncOnlyWhenCharging = false,
    this.enableIntelligentScheduling = true,
    this.intelligentSyncWindow = const Duration(hours: 1),
    this.scheduledTimes = const [],
    this.collectionIntervals = const {},
    this.backoffMultiplier = const Duration(seconds: 30),
    this.maxBackoffDelay = const Duration(minutes: 30),
  });

  SyncScheduleConfig copyWith({
    SyncMode? mode,
    Duration? interval,
    Duration? retryDelay,
    int? maxRetries,
    bool? syncOnlyOnWifi,
    bool? syncOnlyWhenCharging,
    bool? enableIntelligentScheduling,
    Duration? intelligentSyncWindow,
    List<TimeOfDay>? scheduledTimes,
    Map<String, Duration>? collectionIntervals,
    Duration? backoffMultiplier,
    Duration? maxBackoffDelay,
  }) {
    return SyncScheduleConfig(
      mode: mode ?? this.mode,
      interval: interval ?? this.interval,
      retryDelay: retryDelay ?? this.retryDelay,
      maxRetries: maxRetries ?? this.maxRetries,
      syncOnlyOnWifi: syncOnlyOnWifi ?? this.syncOnlyOnWifi,
      syncOnlyWhenCharging: syncOnlyWhenCharging ?? this.syncOnlyWhenCharging,
      enableIntelligentScheduling:
          enableIntelligentScheduling ?? this.enableIntelligentScheduling,
      intelligentSyncWindow:
          intelligentSyncWindow ?? this.intelligentSyncWindow,
      scheduledTimes: scheduledTimes ?? this.scheduledTimes,
      collectionIntervals: collectionIntervals ?? this.collectionIntervals,
      backoffMultiplier: backoffMultiplier ?? this.backoffMultiplier,
      maxBackoffDelay: maxBackoffDelay ?? this.maxBackoffDelay,
    );
  }
}

/// Time of day for scheduled syncs
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  /// Creates a TimeOfDay from the current time
  factory TimeOfDay.now() {
    final now = DateTime.now();
    return TimeOfDay(hour: now.hour, minute: now.minute);
  }

  /// Converts to DateTime for today
  DateTime toDateTime([DateTime? date]) {
    final baseDate = date ?? DateTime.now();
    return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
  }

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) {
    return other is TimeOfDay && other.hour == hour && other.minute == minute;
  }

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;
}

/// Sync trigger information
class SyncTrigger {
  final String id;
  final SyncTriggerType type;
  final DateTime scheduledAt;
  final Duration? delay;
  final String? collection;
  final Map<String, dynamic> metadata;

  const SyncTrigger({
    required this.id,
    required this.type,
    required this.scheduledAt,
    this.delay,
    this.collection,
    this.metadata = const {},
  });

  @override
  String toString() {
    return 'SyncTrigger(id: $id, type: $type, scheduledAt: $scheduledAt, collection: $collection)';
  }
}

/// Types of sync triggers
enum SyncTriggerType {
  /// Regular interval-based sync
  interval,

  /// Scheduled time-based sync
  scheduled,

  /// Retry after failure
  retry,

  /// Data change triggered sync
  dataChange,

  /// Manual user-initiated sync
  manual,

  /// Network connectivity restored
  networkRestore,

  /// App foreground/background change
  appStateChange,

  /// Intelligent scheduling decision
  intelligent,
}

/// Manages sync scheduling with various strategies
class SyncScheduler {
  SyncScheduleConfig _config;
  Timer? _intervalTimer;
  Timer? _retryTimer;
  final Map<String, Timer> _collectionTimers = {};
  final Map<String, int> _retryCounters = {};
  final Map<String, DateTime> _lastSyncTimes = {};
  final Map<String, List<DateTime>> _syncHistory = {};

  bool _isPaused = false;
  NetworkCondition _networkCondition = NetworkCondition.unknown;
  BatteryCondition _batteryCondition = BatteryCondition.unknown;

  final StreamController<SyncTrigger> _syncTriggerController =
      StreamController<SyncTrigger>.broadcast();
  final StreamController<SyncScheduleConfig> _configChangedController =
      StreamController<SyncScheduleConfig>.broadcast();

  /// Stream of sync triggers
  Stream<SyncTrigger> get syncTriggers => _syncTriggerController.stream;

  /// Stream of configuration changes
  Stream<SyncScheduleConfig> get configChanged =>
      _configChangedController.stream;

  SyncScheduler({SyncScheduleConfig? config})
      : _config = config ?? const SyncScheduleConfig();

  /// Updates the scheduler configuration
  void updateConfig(SyncScheduleConfig config) {
    _config = config;
    _configChangedController.add(_config);
    _reschedule();
  }

  /// Gets the current configuration
  SyncScheduleConfig get config => _config;

  /// Starts the scheduler
  void start() {
    _isPaused = false;
    _reschedule();
  }

  /// Pauses the scheduler
  void pause() {
    _isPaused = true;
    _cancelAllTimers();
  }

  /// Resumes the scheduler
  void resume() {
    _isPaused = false;
    _reschedule();
  }

  /// Stops the scheduler
  void stop() {
    _isPaused = true;
    _cancelAllTimers();
  }

  /// Schedules a manual sync
  void triggerManualSync({String? collection}) {
    _triggerSync(
      SyncTriggerType.manual,
      collection: collection,
    );
  }

  /// Schedules a sync with specific delay
  void scheduleSync({
    required Duration delay,
    String? collection,
    SyncTriggerType type = SyncTriggerType.scheduled,
  }) {
    if (_isPaused) return;

    final triggerId = _generateTriggerId();

    Timer(delay, () {
      if (!_isPaused) {
        _triggerSync(type, collection: collection, triggerId: triggerId);
      }
    });
  }

  /// Schedules a retry after sync failure
  void scheduleRetry({
    required String collection,
    int? retryCount,
  }) {
    final currentRetryCount = retryCount ?? (_retryCounters[collection] ?? 0);

    if (currentRetryCount >= _config.maxRetries) {
      _retryCounters.remove(collection);
      return;
    }

    _retryCounters[collection] = currentRetryCount + 1;

    // Calculate exponential backoff delay
    final baseDelay = _config.retryDelay;
    final exponentialDelay = Duration(
      milliseconds:
          (baseDelay.inMilliseconds * pow(2, currentRetryCount)).round(),
    );

    final actualDelay = exponentialDelay > _config.maxBackoffDelay
        ? _config.maxBackoffDelay
        : exponentialDelay;

    scheduleSync(
      delay: actualDelay,
      collection: collection,
      type: SyncTriggerType.retry,
    );
  }

  /// Notifies about successful sync (resets retry counter)
  void notifySyncSuccess(String collection) {
    _retryCounters.remove(collection);
    _lastSyncTimes[collection] = DateTime.now();
    _recordSyncHistory(collection);
  }

  /// Updates network condition
  void updateNetworkCondition(NetworkCondition condition) {
    final oldCondition = _networkCondition;
    _networkCondition = condition;

    // If network was restored, trigger sync
    if (oldCondition == NetworkCondition.offline &&
        condition != NetworkCondition.offline &&
        !_isPaused) {
      _triggerSync(SyncTriggerType.networkRestore);
    }

    _rescheduleIfNeeded();
  }

  /// Updates battery condition
  void updateBatteryCondition(BatteryCondition condition) {
    _batteryCondition = condition;
    _rescheduleIfNeeded();
  }

  /// Notifies about data changes
  void notifyDataChange(String collection) {
    if (_isPaused) return;

    if (_config.mode == SyncMode.realtime) {
      _triggerSync(SyncTriggerType.dataChange, collection: collection);
    } else if (_config.enableIntelligentScheduling) {
      _scheduleIntelligentSync(collection);
    }
  }

  /// Gets the next scheduled sync time
  DateTime? getNextSyncTime({String? collection}) {
    if (_isPaused || _config.mode == SyncMode.manual) {
      return null;
    }

    switch (_config.mode) {
      case SyncMode.automatic:
        final lastSync = _lastSyncTimes[collection] ?? DateTime.now();
        final interval = collection != null
            ? _config.collectionIntervals[collection] ?? _config.interval
            : _config.interval;
        return lastSync.add(interval);

      case SyncMode.scheduled:
        return _getNextScheduledTime();

      case SyncMode.intelligent:
        return _getIntelligentSyncTime(collection);

      case SyncMode.realtime:
        return DateTime.now(); // Immediate

      case SyncMode.manual:
        return null;

      case SyncMode.hybrid:
      case SyncMode.offline:
        return null;
    }
  }

  void _reschedule() {
    if (_isPaused) return;

    _cancelAllTimers();

    switch (_config.mode) {
      case SyncMode.automatic:
        _scheduleIntervalSync();
        break;
      case SyncMode.scheduled:
        _scheduleTimedSyncs();
        break;
      case SyncMode.intelligent:
        _scheduleIntelligentSyncs();
        break;
      case SyncMode.realtime:
        // Real-time syncs are triggered by data changes
        break;
      case SyncMode.manual:
        // Manual mode doesn't schedule automatic syncs
        break;
      case SyncMode.hybrid:
      case SyncMode.offline:
        // No automatic scheduling for these modes
        break;
    }
  }

  void _scheduleIntervalSync() {
    if (!_shouldSyncNow()) return;

    _intervalTimer = Timer.periodic(_config.interval, (timer) {
      if (_shouldSyncNow()) {
        _triggerSync(SyncTriggerType.interval);
      }
    });

    // Schedule collection-specific intervals
    for (final entry in _config.collectionIntervals.entries) {
      final collection = entry.key;
      final interval = entry.value;

      _collectionTimers[collection] = Timer.periodic(interval, (timer) {
        if (_shouldSyncNow()) {
          _triggerSync(SyncTriggerType.interval, collection: collection);
        }
      });
    }
  }

  void _scheduleTimedSyncs() {
    for (final timeOfDay in _config.scheduledTimes) {
      _scheduleNextOccurrence(timeOfDay);
    }
  }

  void _scheduleNextOccurrence(TimeOfDay timeOfDay) {
    final now = DateTime.now();
    DateTime scheduledTime = timeOfDay.toDateTime(now);

    // If the time has already passed today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final delay = scheduledTime.difference(now);

    Timer(delay, () {
      if (_shouldSyncNow()) {
        _triggerSync(SyncTriggerType.scheduled);
      }
      // Schedule the next occurrence
      _scheduleNextOccurrence(timeOfDay);
    });
  }

  void _scheduleIntelligentSyncs() {
    // Analyze sync patterns and schedule intelligently
    Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_isPaused) return;

      for (final collection in _syncHistory.keys) {
        if (_shouldScheduleIntelligentSync(collection)) {
          _triggerSync(SyncTriggerType.intelligent, collection: collection);
        }
      }
    });
  }

  void _scheduleIntelligentSync(String collection) {
    // Schedule sync based on usage patterns
    final delay = _calculateIntelligentDelay(collection);

    scheduleSync(
      delay: delay,
      collection: collection,
      type: SyncTriggerType.intelligent,
    );
  }

  Duration _calculateIntelligentDelay(String collection) {
    final history = _syncHistory[collection] ?? [];

    if (history.isEmpty) {
      return _config.interval;
    }

    // Calculate average interval between syncs
    if (history.length < 2) {
      return _config.interval;
    }

    var totalInterval = Duration.zero;
    for (int i = 1; i < history.length; i++) {
      totalInterval += history[i].difference(history[i - 1]);
    }

    final averageInterval = Duration(
      milliseconds: totalInterval.inMilliseconds ~/ (history.length - 1),
    );

    // Use average interval but cap it within reasonable bounds
    if (averageInterval < const Duration(minutes: 1)) {
      return const Duration(minutes: 1);
    } else if (averageInterval > const Duration(hours: 4)) {
      return const Duration(hours: 4);
    }

    return averageInterval;
  }

  bool _shouldSyncNow() {
    if (_isPaused) return false;

    // Check network condition
    if (_config.syncOnlyOnWifi &&
        _networkCondition != NetworkCondition.highSpeed) {
      return false;
    }

    if (_networkCondition == NetworkCondition.offline) {
      return false;
    }

    // Check battery condition
    if (_config.syncOnlyWhenCharging &&
        _batteryCondition != BatteryCondition.charging) {
      return false;
    }

    if (_batteryCondition == BatteryCondition.critical) {
      return false;
    }

    return true;
  }

  bool _shouldScheduleIntelligentSync(String collection) {
    final lastSync = _lastSyncTimes[collection];
    if (lastSync == null) return true;

    final timeSinceLastSync = DateTime.now().difference(lastSync);
    final intelligentDelay = _calculateIntelligentDelay(collection);

    return timeSinceLastSync >= intelligentDelay;
  }

  DateTime? _getNextScheduledTime() {
    if (_config.scheduledTimes.isEmpty) return null;

    final now = DateTime.now();
    DateTime? nextTime;

    for (final timeOfDay in _config.scheduledTimes) {
      final todayTime = timeOfDay.toDateTime(now);
      final candidateTime = todayTime.isAfter(now)
          ? todayTime
          : todayTime.add(const Duration(days: 1));

      if (nextTime == null || candidateTime.isBefore(nextTime)) {
        nextTime = candidateTime;
      }
    }

    return nextTime;
  }

  DateTime? _getIntelligentSyncTime(String? collection) {
    if (collection == null) return null;

    final delay = _calculateIntelligentDelay(collection);
    final lastSync = _lastSyncTimes[collection] ?? DateTime.now();
    return lastSync.add(delay);
  }

  void _rescheduleIfNeeded() {
    if (_config.enableIntelligentScheduling) {
      _reschedule();
    }
  }

  void _triggerSync(SyncTriggerType type,
      {String? collection, String? triggerId}) {
    final trigger = SyncTrigger(
      id: triggerId ?? _generateTriggerId(),
      type: type,
      scheduledAt: DateTime.now(),
      collection: collection,
    );

    _syncTriggerController.add(trigger);
  }

  void _recordSyncHistory(String collection) {
    if (!_syncHistory.containsKey(collection)) {
      _syncHistory[collection] = [];
    }

    _syncHistory[collection]!.add(DateTime.now());

    // Keep only last 50 sync times to avoid memory issues
    if (_syncHistory[collection]!.length > 50) {
      _syncHistory[collection] = _syncHistory[collection]!.sublist(
        _syncHistory[collection]!.length - 50,
      );
    }
  }

  void _cancelAllTimers() {
    _intervalTimer?.cancel();
    _intervalTimer = null;

    _retryTimer?.cancel();
    _retryTimer = null;

    for (final timer in _collectionTimers.values) {
      timer.cancel();
    }
    _collectionTimers.clear();
  }

  String _generateTriggerId() {
    return 'trigger_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  /// Dispose method to clean up resources
  void dispose() {
    stop();
    _syncTriggerController.close();
    _configChangedController.close();
  }
}
