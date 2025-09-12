// lib/src/services/usm_sync_logging_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/usm_sync_enums.dart';

/// Comprehensive sync log entry
class SyncLogEntry {
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final LogCategory category;
  final String message;
  final String? operationId;
  final String? entityType;
  final String? collection;
  final Map<String, dynamic> context;
  final String? stackTrace;
  final Duration? duration;
  final Map<String, dynamic> metadata;

  const SyncLogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.category,
    required this.message,
    this.operationId,
    this.entityType,
    this.collection,
    this.context = const {},
    this.stackTrace,
    this.duration,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'level': level.name,
        'category': category.name,
        'message': message,
        'operationId': operationId,
        'entityType': entityType,
        'collection': collection,
        'context': context,
        'stackTrace': stackTrace,
        'durationMs': duration?.inMilliseconds,
        'metadata': metadata,
      };

  factory SyncLogEntry.fromJson(Map<String, dynamic> json) {
    return SyncLogEntry(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      level: LogLevel.values.firstWhere((l) => l.name == json['level']),
      category:
          LogCategory.values.firstWhere((c) => c.name == json['category']),
      message: json['message'],
      operationId: json['operationId'],
      entityType: json['entityType'],
      collection: json['collection'],
      context: Map<String, dynamic>.from(json['context'] ?? {}),
      stackTrace: json['stackTrace'],
      duration: json['durationMs'] != null
          ? Duration(milliseconds: json['durationMs'])
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Creates a formatted string representation
  String toFormattedString() {
    final buffer = StringBuffer();
    buffer.write('[${timestamp.toIso8601String()}] ');
    buffer.write('${level.name.toUpperCase().padRight(8)} ');
    buffer.write('${category.name.toUpperCase().padRight(12)} ');

    if (operationId != null) {
      buffer.write('[$operationId] ');
    }

    if (collection != null) {
      buffer.write('$collection: ');
    }

    buffer.write(message);

    if (duration != null) {
      buffer.write(' (${duration!.inMilliseconds}ms)');
    }

    if (context.isNotEmpty) {
      buffer.write('\n  Context: ${jsonEncode(context)}');
    }

    if (stackTrace != null) {
      buffer.write(
          '\n  Stack Trace:\n${stackTrace!.split('\n').map((line) => '    $line').join('\n')}');
    }

    return buffer.toString();
  }
}

/// Log filter configuration
class LogFilter {
  final List<LogLevel>? levels;
  final List<LogCategory>? categories;
  final String? operationId;
  final String? entityType;
  final String? collection;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? searchText;
  final int? limit;

  const LogFilter({
    this.levels,
    this.categories,
    this.operationId,
    this.entityType,
    this.collection,
    this.startTime,
    this.endTime,
    this.searchText,
    this.limit,
  });

  /// Checks if a log entry matches this filter
  bool matches(SyncLogEntry entry) {
    if (levels != null && !levels!.contains(entry.level)) return false;
    if (categories != null && !categories!.contains(entry.category))
      return false;
    if (operationId != null && entry.operationId != operationId) return false;
    if (entityType != null && entry.entityType != entityType) return false;
    if (collection != null && entry.collection != collection) return false;
    if (startTime != null && entry.timestamp.isBefore(startTime!)) return false;
    if (endTime != null && entry.timestamp.isAfter(endTime!)) return false;

    if (searchText != null && searchText!.isNotEmpty) {
      final searchLower = searchText!.toLowerCase();
      if (!entry.message.toLowerCase().contains(searchLower) &&
          !entry.toJson().toString().toLowerCase().contains(searchLower)) {
        return false;
      }
    }

    return true;
  }
}

/// Log storage configuration
class LogStorageConfig {
  final String logDirectory;
  final String filePrefix;
  final int maxFileSize; // bytes
  final int maxFiles;
  final Duration retentionPeriod;
  final bool enableConsoleOutput;
  final bool enableFileOutput;
  final bool enableInMemoryBuffer;
  final int inMemoryBufferSize;

  const LogStorageConfig({
    required this.logDirectory,
    this.filePrefix = 'sync_log',
    this.maxFileSize = 10 * 1024 * 1024, // 10MB
    this.maxFiles = 10,
    this.retentionPeriod = const Duration(days: 30),
    this.enableConsoleOutput = true,
    this.enableFileOutput = true,
    this.enableInMemoryBuffer = true,
    this.inMemoryBufferSize = 1000,
  });
}

/// Comprehensive sync logging service
class SyncLoggingService {
  final LogStorageConfig _config;
  final List<SyncLogEntry> _inMemoryBuffer = [];
  final StreamController<SyncLogEntry> _logStreamController =
      StreamController<SyncLogEntry>.broadcast();

  File? _currentLogFile;
  int _entryCounter = 0;
  LogLevel _minimumLogLevel = LogLevel.debug;
  final Set<LogCategory> _enabledCategories = Set.from(LogCategory.values);

  SyncLoggingService(this._config) {
    _initializeLogging();
  }

  /// Stream of log entries
  Stream<SyncLogEntry> get logStream => _logStreamController.stream;

  /// Sets minimum log level
  void setMinimumLogLevel(LogLevel level) {
    _minimumLogLevel = level;
  }

  /// Enables or disables specific log categories
  void setCategoryEnabled(LogCategory category, bool enabled) {
    if (enabled) {
      _enabledCategories.add(category);
    } else {
      _enabledCategories.remove(category);
    }
  }

  /// Logs a debug message
  void debug(
    String message, {
    LogCategory category = LogCategory.debug,
    String? operationId,
    String? entityType,
    String? collection,
    Map<String, dynamic> context = const {},
    Duration? duration,
  }) {
    _log(LogLevel.debug, category, message,
        operationId: operationId,
        entityType: entityType,
        collection: collection,
        context: context,
        duration: duration);
  }

  /// Logs an info message
  void info(
    String message, {
    LogCategory category = LogCategory.sync,
    String? operationId,
    String? entityType,
    String? collection,
    Map<String, dynamic> context = const {},
    Duration? duration,
  }) {
    _log(LogLevel.info, category, message,
        operationId: operationId,
        entityType: entityType,
        collection: collection,
        context: context,
        duration: duration);
  }

  /// Logs a warning message
  void warning(
    String message, {
    LogCategory category = LogCategory.sync,
    String? operationId,
    String? entityType,
    String? collection,
    Map<String, dynamic> context = const {},
    Duration? duration,
  }) {
    _log(LogLevel.warning, category, message,
        operationId: operationId,
        entityType: entityType,
        collection: collection,
        context: context,
        duration: duration);
  }

  /// Logs an error message
  void error(
    String message, {
    LogCategory category = LogCategory.sync,
    String? operationId,
    String? entityType,
    String? collection,
    Map<String, dynamic> context = const {},
    Duration? duration,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final contextWithError = Map<String, dynamic>.from(context);
    if (error != null) {
      contextWithError['error'] = error.toString();
    }

    _log(LogLevel.error, category, message,
        operationId: operationId,
        entityType: entityType,
        collection: collection,
        context: contextWithError,
        duration: duration,
        stackTrace: stackTrace?.toString());
  }

  /// Logs a critical message
  void critical(
    String message, {
    LogCategory category = LogCategory.system,
    String? operationId,
    String? entityType,
    String? collection,
    Map<String, dynamic> context = const {},
    Duration? duration,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final contextWithError = Map<String, dynamic>.from(context);
    if (error != null) {
      contextWithError['error'] = error.toString();
    }

    _log(LogLevel.critical, category, message,
        operationId: operationId,
        entityType: entityType,
        collection: collection,
        context: contextWithError,
        duration: duration,
        stackTrace: stackTrace?.toString());
  }

  /// Logs sync operation start
  void logOperationStart(
    String operationId,
    String operationType,
    String collection, {
    String? entityType,
    Map<String, dynamic> context = const {},
  }) {
    info(
      'Starting $operationType operation',
      category: LogCategory.sync,
      operationId: operationId,
      entityType: entityType,
      collection: collection,
      context: {
        'operationType': operationType,
        ...context,
      },
    );
  }

  /// Logs sync operation completion
  void logOperationComplete(
    String operationId,
    String operationType,
    String collection,
    Duration duration, {
    String? entityType,
    bool success = true,
    int? itemsProcessed,
    Map<String, dynamic> context = const {},
  }) {
    final level = success ? LogLevel.info : LogLevel.error;
    final message = success
        ? 'Completed $operationType operation successfully'
        : 'Failed $operationType operation';

    _log(level, LogCategory.sync, message,
        operationId: operationId,
        entityType: entityType,
        collection: collection,
        context: {
          'operationType': operationType,
          'success': success,
          'itemsProcessed': itemsProcessed,
          ...context,
        },
        duration: duration);
  }

  /// Logs conflict detection
  void logConflictDetected(
    String operationId,
    String collection,
    String entityId, {
    String? entityType,
    Map<String, dynamic> conflictDetails = const {},
  }) {
    warning(
      'Conflict detected for entity $entityId',
      category: LogCategory.conflict,
      operationId: operationId,
      entityType: entityType,
      collection: collection,
      context: {
        'entityId': entityId,
        'conflictDetails': conflictDetails,
      },
    );
  }

  /// Logs conflict resolution
  void logConflictResolved(
    String operationId,
    String collection,
    String entityId,
    String resolutionStrategy, {
    String? entityType,
    Map<String, dynamic> resolutionDetails = const {},
  }) {
    info(
      'Conflict resolved for entity $entityId using $resolutionStrategy',
      category: LogCategory.conflict,
      operationId: operationId,
      entityType: entityType,
      collection: collection,
      context: {
        'entityId': entityId,
        'resolutionStrategy': resolutionStrategy,
        'resolutionDetails': resolutionDetails,
      },
    );
  }

  /// Logs network events
  void logNetworkEvent(
    String event,
    bool success, {
    String? operationId,
    Duration? duration,
    Map<String, dynamic> context = const {},
  }) {
    final level = success ? LogLevel.info : LogLevel.warning;

    _log(level, LogCategory.network, event,
        operationId: operationId,
        context: {
          'success': success,
          ...context,
        },
        duration: duration);
  }

  /// Logs performance metrics
  void logPerformanceMetric(
    String metric,
    dynamic value, {
    String? operationId,
    String? entityType,
    String? collection,
    Map<String, dynamic> context = const {},
  }) {
    debug(
      'Performance metric: $metric = $value',
      category: LogCategory.performance,
      operationId: operationId,
      entityType: entityType,
      collection: collection,
      context: {
        'metric': metric,
        'value': value,
        ...context,
      },
    );
  }

  /// Logs recovery operations
  void logRecoveryOperation(
    String operation,
    String details, {
    String? operationId,
    String? collection,
    bool success = true,
    Map<String, dynamic> context = const {},
  }) {
    final level = success ? LogLevel.info : LogLevel.error;

    _log(level, LogCategory.recovery, '$operation: $details',
        operationId: operationId,
        collection: collection,
        context: {
          'recoveryOperation': operation,
          'success': success,
          ...context,
        });
  }

  /// Gets filtered log entries
  List<SyncLogEntry> getLogs({LogFilter? filter}) {
    var logs = List<SyncLogEntry>.from(_inMemoryBuffer);

    if (filter != null) {
      logs = logs.where(filter.matches).toList();
    }

    // Sort by timestamp descending (most recent first)
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (filter?.limit != null) {
      logs = logs.take(filter!.limit!).toList();
    }

    return logs;
  }

  /// Gets logs for a specific operation
  List<SyncLogEntry> getOperationLogs(String operationId) {
    return getLogs(filter: LogFilter(operationId: operationId));
  }

  /// Gets recent error logs
  List<SyncLogEntry> getRecentErrors({int limit = 50}) {
    return getLogs(
        filter: LogFilter(
      levels: [LogLevel.error, LogLevel.critical],
      limit: limit,
    ));
  }

  /// Gets logs for a specific time range
  List<SyncLogEntry> getLogsByTimeRange(DateTime start, DateTime end) {
    return getLogs(
        filter: LogFilter(
      startTime: start,
      endTime: end,
    ));
  }

  /// Exports logs to JSON format
  Map<String, dynamic> exportLogs({
    LogFilter? filter,
    bool includeSystemInfo = true,
  }) {
    final logs = getLogs(filter: filter);

    final export = <String, dynamic>{
      'exportedAt': DateTime.now().toIso8601String(),
      'logCount': logs.length,
      'logs': logs.map((log) => log.toJson()).toList(),
    };

    if (includeSystemInfo) {
      export['systemInfo'] = {
        'platform': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
        'logLevel': _minimumLogLevel.name,
        'enabledCategories': _enabledCategories.map((c) => c.name).toList(),
      };
    }

    return export;
  }

  /// Exports logs to formatted text
  String exportLogsAsText({LogFilter? filter}) {
    final logs = getLogs(filter: filter);
    final buffer = StringBuffer();

    buffer.writeln('=== Sync Logs Export ===');
    buffer.writeln('Exported at: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Log count: ${logs.length}');
    buffer.writeln('');

    for (final log in logs) {
      buffer.writeln(log.toFormattedString());
      buffer.writeln('');
    }

    return buffer.toString();
  }

  /// Clears in-memory logs
  void clearLogs() {
    _inMemoryBuffer.clear();
    info('Log buffer cleared', category: LogCategory.system);
  }

  /// Gets log statistics
  Map<String, dynamic> getLogStatistics({Duration? period}) {
    final now = DateTime.now();
    final since = period != null ? now.subtract(period) : null;

    final relevantLogs = since != null
        ? _inMemoryBuffer.where((log) => log.timestamp.isAfter(since)).toList()
        : _inMemoryBuffer;

    final levelCounts = <String, int>{};
    final categoryCounts = <String, int>{};

    for (final log in relevantLogs) {
      levelCounts[log.level.name] = (levelCounts[log.level.name] ?? 0) + 1;
      categoryCounts[log.category.name] =
          (categoryCounts[log.category.name] ?? 0) + 1;
    }

    return {
      'totalLogs': relevantLogs.length,
      'levelBreakdown': levelCounts,
      'categoryBreakdown': categoryCounts,
      'periodHours': period?.inHours,
      'oldestLog': relevantLogs.isNotEmpty
          ? relevantLogs
              .map((l) => l.timestamp)
              .reduce((a, b) => a.isBefore(b) ? a : b)
              .toIso8601String()
          : null,
      'newestLog': relevantLogs.isNotEmpty
          ? relevantLogs
              .map((l) => l.timestamp)
              .reduce((a, b) => a.isAfter(b) ? a : b)
              .toIso8601String()
          : null,
    };
  }

  /// Core logging method
  void _log(
    LogLevel level,
    LogCategory category,
    String message, {
    String? operationId,
    String? entityType,
    String? collection,
    Map<String, dynamic> context = const {},
    Duration? duration,
    String? stackTrace,
  }) {
    // Check if logging is enabled for this level and category
    if (level.index < _minimumLogLevel.index) return;
    if (!_enabledCategories.contains(category)) return;

    final entry = SyncLogEntry(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}_${_entryCounter++}',
      timestamp: DateTime.now(),
      level: level,
      category: category,
      message: message,
      operationId: operationId,
      entityType: entityType,
      collection: collection,
      context: context,
      stackTrace: stackTrace,
      duration: duration,
      metadata: {
        'entryNumber': _entryCounter,
        'pid': pid,
      },
    );

    // Add to in-memory buffer
    if (_config.enableInMemoryBuffer) {
      _inMemoryBuffer.add(entry);

      // Maintain buffer size
      while (_inMemoryBuffer.length > _config.inMemoryBufferSize) {
        _inMemoryBuffer.removeAt(0);
      }
    }

    // Output to console
    if (_config.enableConsoleOutput) {
      print(entry.toFormattedString());
    }

    // Write to file
    if (_config.enableFileOutput) {
      _writeToFile(entry);
    }

    // Emit to stream
    _logStreamController.add(entry);
  }

  /// Initializes logging system
  void _initializeLogging() {
    // Create log directory if it doesn't exist
    final logDir = Directory(_config.logDirectory);
    if (!logDir.existsSync()) {
      logDir.createSync(recursive: true);
    }

    // Clean up old log files
    _cleanupOldLogFiles();

    // Initialize current log file
    _initializeLogFile();

    info('Sync logging service initialized', category: LogCategory.system);
  }

  /// Initializes current log file
  void _initializeLogFile() {
    if (!_config.enableFileOutput) return;

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = '${_config.filePrefix}_$timestamp.log';
    final filePath = '${_config.logDirectory}/$fileName';

    _currentLogFile = File(filePath);
  }

  /// Writes log entry to file
  void _writeToFile(SyncLogEntry entry) {
    if (_currentLogFile == null) return;

    try {
      // Check if we need to rotate the log file
      if (_currentLogFile!.existsSync() &&
          _currentLogFile!.lengthSync() > _config.maxFileSize) {
        _rotateLogFile();
      }

      // Write to file
      _currentLogFile!.writeAsStringSync(
        '${entry.toFormattedString()}\n',
        mode: FileMode.append,
      );
    } catch (e) {
      // If file writing fails, at least log to console
      print('Failed to write to log file: $e');
    }
  }

  /// Rotates log file when size limit is reached
  void _rotateLogFile() {
    _cleanupOldLogFiles();
    _initializeLogFile();
  }

  /// Cleans up old log files
  void _cleanupOldLogFiles() {
    try {
      final logDir = Directory(_config.logDirectory);
      if (!logDir.existsSync()) return;

      final logFiles = logDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.contains(_config.filePrefix))
          .toList();

      // Sort by modification time (oldest first)
      logFiles
          .sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

      // Remove files beyond retention period
      final cutoffTime = DateTime.now().subtract(_config.retentionPeriod);
      final expiredFiles = logFiles
          .where((file) => file.lastModifiedSync().isBefore(cutoffTime))
          .toList();

      for (final file in expiredFiles) {
        file.deleteSync();
      }

      // Remove excess files beyond max count
      final remainingFiles =
          logFiles.where((file) => !expiredFiles.contains(file)).toList();

      if (remainingFiles.length > _config.maxFiles) {
        final filesToDelete =
            remainingFiles.take(remainingFiles.length - _config.maxFiles);
        for (final file in filesToDelete) {
          file.deleteSync();
        }
      }
    } catch (e) {
      print('Failed to cleanup old log files: $e');
    }
  }

  /// Disposes the logging service
  void dispose() {
    info('Sync logging service shutting down', category: LogCategory.system);
    _logStreamController.close();
  }
}
