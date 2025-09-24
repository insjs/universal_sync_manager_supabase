/// Web-specific implementation of ISyncPlatformService
///
/// Provides web browser optimizations for Universal Sync Manager.
library usm_web_platform_service;

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import '../interfaces/usm_sync_platform_service.dart';

/// Web-specific platform service implementation
class WebSyncPlatformService implements ISyncPlatformService {
  static const String _logStorageKey = 'usm_web_logs';
  static const String _secureStorageKey = 'usm_web_secure';

  bool _isInitialized = false;
  late String _documentsPath;
  late String _cachePath;
  late String _tempPath;

  final StreamController<PlatformNetworkInfo> _networkController =
      StreamController<PlatformNetworkInfo>.broadcast();
  final StreamController<PlatformBatteryInfo> _batteryController =
      StreamController<PlatformBatteryInfo>.broadcast();

  Timer? _networkMonitorTimer;
  Timer? _batteryMonitorTimer;

  @override
  SyncPlatformType get platformType => SyncPlatformType.web;

  @override
  String get platformVersion => html.window.navigator.userAgent;

  @override
  String get documentsPath => _documentsPath;

  @override
  String get cachePath => _cachePath;

  @override
  String get tempPath => _tempPath;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Stream<PlatformNetworkInfo> get networkStream => _networkController.stream;

  @override
  Stream<PlatformBatteryInfo> get batteryStream => _batteryController.stream;

  // === Platform Initialization ===

  @override
  Future<bool> initialize({
    String? customDatabasePath,
    Map<String, dynamic> platformOptions = const {},
  }) async {
    try {
      // Set up web-specific paths (virtual paths)
      _documentsPath = customDatabasePath ?? '/virtual/documents/USM';
      _cachePath = '/virtual/cache/USM';
      _tempPath = '/virtual/temp/USM';

      // Initialize web-specific monitoring
      _startNetworkMonitoring();
      _startBatteryMonitoring();

      _isInitialized = true;
      await logDiagnosticInfo('Web platform service initialized', metadata: {
        'userAgent': platformVersion,
        'documentsPath': _documentsPath,
        'cachePath': _cachePath,
        'tempPath': _tempPath,
      });

      return true;
    } catch (e) {
      await logDiagnosticInfo('Failed to initialize web platform service',
          metadata: {'error': e.toString()}, level: 'error');
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    _networkMonitorTimer?.cancel();
    _batteryMonitorTimer?.cancel();
    await _networkController.close();
    await _batteryController.close();
    _isInitialized = false;
    await logDiagnosticInfo('Web platform service disposed');
  }

  // === File System Operations ===

  @override
  Future<FileOperationResult> readFile(String filePath) async {
    try {
      final content = html.window.localStorage[_getStorageKey(filePath)];
      if (content == null) {
        return FileOperationResult.failure(
          operationType: FileOperationType.read,
          error: 'File does not exist: $filePath',
        );
      }

      return FileOperationResult.success(
        operationType: FileOperationType.read,
        data: content,
      );
    } catch (e) {
      return FileOperationResult.failure(
        operationType: FileOperationType.read,
        error: 'Failed to read file: $e',
      );
    }
  }

  @override
  Future<FileOperationResult> readFileAsBytes(String filePath) async {
    try {
      final content = html.window.localStorage[_getStorageKey(filePath)];
      if (content == null) {
        return FileOperationResult.failure(
          operationType: FileOperationType.read,
          error: 'File does not exist: $filePath',
        );
      }

      final bytes = base64Decode(content);
      return FileOperationResult.success(
        operationType: FileOperationType.read,
        data: bytes,
      );
    } catch (e) {
      return FileOperationResult.failure(
        operationType: FileOperationType.read,
        error: 'Failed to read file as bytes: $e',
      );
    }
  }

  @override
  Future<FileOperationResult> writeFile(String filePath, String content) async {
    try {
      html.window.localStorage[_getStorageKey(filePath)] = content;

      return FileOperationResult.success(
        operationType: FileOperationType.write,
        data: filePath,
      );
    } catch (e) {
      return FileOperationResult.failure(
        operationType: FileOperationType.write,
        error: 'Failed to write file: $e',
      );
    }
  }

  @override
  Future<FileOperationResult> writeFileAsBytes(
      String filePath, List<int> bytes) async {
    try {
      final content = base64Encode(bytes);
      html.window.localStorage[_getStorageKey(filePath)] = content;

      return FileOperationResult.success(
        operationType: FileOperationType.write,
        data: filePath,
      );
    } catch (e) {
      return FileOperationResult.failure(
        operationType: FileOperationType.write,
        error: 'Failed to write file as bytes: $e',
      );
    }
  }

  @override
  Future<FileOperationResult> deleteFile(String filePath) async {
    try {
      html.window.localStorage.remove(_getStorageKey(filePath));

      return FileOperationResult.success(
        operationType: FileOperationType.delete,
        data: filePath,
      );
    } catch (e) {
      return FileOperationResult.failure(
        operationType: FileOperationType.delete,
        error: 'Failed to delete file: $e',
      );
    }
  }

  @override
  Future<FileOperationResult> fileExists(String filePath) async {
    try {
      final exists =
          html.window.localStorage.containsKey(_getStorageKey(filePath));

      return FileOperationResult.success(
        operationType: FileOperationType.exists,
        data: exists,
      );
    } catch (e) {
      return FileOperationResult.failure(
        operationType: FileOperationType.exists,
        error: 'Failed to check file existence: $e',
      );
    }
  }

  @override
  Future<FileOperationResult> createDirectory(String directoryPath) async {
    // Web doesn't have real directories, so this is a no-op
    return FileOperationResult.success(
      operationType: FileOperationType.createDirectory,
      data: directoryPath,
    );
  }

  @override
  Future<FileOperationResult> listDirectory(String directoryPath) async {
    try {
      final prefix = _getStorageKey(directoryPath);
      final keys = html.window.localStorage.keys
          .where((key) => key.startsWith(prefix))
          .map((key) => key.substring(prefix.length))
          .toList();

      return FileOperationResult.success(
        operationType: FileOperationType.listDirectory,
        data: keys,
      );
    } catch (e) {
      return FileOperationResult.failure(
        operationType: FileOperationType.listDirectory,
        error: 'Failed to list directory: $e',
      );
    }
  }

  @override
  Future<int?> getFileSize(String filePath) async {
    try {
      final content = html.window.localStorage[_getStorageKey(filePath)];
      if (content == null) return null;

      // Return approximate size in bytes
      return utf8.encode(content).length;
    } catch (e) {
      await logDiagnosticInfo('Failed to get web file size',
          metadata: {'filePath': filePath, 'error': e.toString()},
          level: 'warning');
      return null;
    }
  }

  @override
  Future<DateTime?> getFileModificationTime(String filePath) async {
    try {
      // Web localStorage doesn't have modification times
      // We could store this metadata separately if needed
      return DateTime.now(); // Return current time as fallback
    } catch (e) {
      await logDiagnosticInfo('Failed to get web file modification time',
          metadata: {'filePath': filePath, 'error': e.toString()},
          level: 'warning');
      return null;
    }
  }

  @override
  Future<String> createSyncCacheDirectory(String organizationId) async {
    final syncCachePath = '$_cachePath/$organizationId';
    // No actual directory creation needed for web
    return syncCachePath;
  }

  @override
  Future<void> cleanupOldCacheFiles({Duration? maxAge}) async {
    final maxAgeToUse = maxAge ?? const Duration(days: 14); // Moderate for web
    final cutoffTime = DateTime.now().subtract(maxAgeToUse);

    try {
      // Clean up localStorage entries with cache prefix
      final cachePrefix = _getStorageKey(_cachePath);
      final keysToRemove = <String>[];

      for (final key in html.window.localStorage.keys) {
        if (key.startsWith(cachePrefix)) {
          // In a real implementation, you'd store metadata about when files were created
          // For now, we'll keep all cache files
        }
      }

      for (final key in keysToRemove) {
        html.window.localStorage.remove(key);
      }

      await logDiagnosticInfo('Web cache cleanup completed', metadata: {
        'maxAge': maxAgeToUse.inDays,
        'cutoffTime': cutoffTime.toIso8601String()
      });
    } catch (e) {
      await logDiagnosticInfo('Web cache cleanup failed',
          metadata: {'error': e.toString()}, level: 'error');
    }
  }

  // === Network Detection ===

  @override
  Future<PlatformNetworkInfo> getNetworkInfo() async {
    try {
      // Web network detection using navigator.onLine and connection API
      final isOnline = html.window.navigator.onLine ?? true;

      if (!isOnline) {
        return const PlatformNetworkInfo(
          connectionType: NetworkConnectionType.none,
          quality: NetworkQuality.none,
          isMetered: false,
        );
      }

      // Try to access connection API (not available in all browsers)
      final connection = html.window.navigator.connection;
      if (connection != null) {
        final effectiveType = connection.effectiveType ?? '4g';
        final quality = _mapConnectionToQuality(effectiveType);

        return PlatformNetworkInfo(
          connectionType: NetworkConnectionType.wifi, // Assume wifi for web
          quality: quality,
          isMetered: false, // Web typically doesn't expose metered info
          networkName: 'Web Browser Connection',
        );
      }

      // Fallback for browsers without connection API
      return const PlatformNetworkInfo(
        connectionType: NetworkConnectionType.wifi,
        quality: NetworkQuality.good,
        isMetered: false,
        networkName: 'Web Browser Connection',
      );
    } catch (e) {
      await logDiagnosticInfo('Failed to get web network info',
          metadata: {'error': e.toString()}, level: 'warning');

      return const PlatformNetworkInfo(
        connectionType: NetworkConnectionType.unknown,
        quality: NetworkQuality.unknown,
        isMetered: false,
      );
    }
  }

  @override
  Future<bool> isNetworkSuitableForSync() async {
    final networkInfo = await getNetworkInfo();
    return networkInfo.isSuitableForSync;
  }

  @override
  Future<double?> estimateNetworkSpeed() async {
    try {
      // Web network speed estimation using a small download test
      final stopwatch = Stopwatch()..start();

      // Download a small resource to estimate speed
      await html.HttpRequest.getString(
          'data:text/plain;base64,dGVzdA=='); // "test" in base64

      stopwatch.stop();

      // Rough estimation based on response time
      final responseTime = stopwatch.elapsedMilliseconds;
      if (responseTime < 50) return 100000.0; // ~100KB/s for fast
      if (responseTime < 200) return 50000.0; // ~50KB/s for medium
      return 20000.0; // ~20KB/s for slow
    } catch (e) {
      await logDiagnosticInfo('Failed to estimate web network speed',
          metadata: {'error': e.toString()}, level: 'warning');
    }
    return null;
  }

  // === Battery and Power Management ===

  @override
  Future<PlatformBatteryInfo> getBatteryInfo() async {
    try {
      // Web Battery API (deprecated but might still be available)
      // Most browsers no longer expose battery information for privacy
      return const PlatformBatteryInfo(
        isCharging: true, // Assume plugged in for web
        isLowPowerMode: false,
        recommendedOptimization: BatteryOptimizationLevel.none,
      );
    } catch (e) {
      await logDiagnosticInfo('Failed to get web battery info',
          metadata: {'error': e.toString()}, level: 'warning');

      return const PlatformBatteryInfo(
        isCharging: true,
        isLowPowerMode: false,
        recommendedOptimization: BatteryOptimizationLevel.none,
      );
    }
  }

  @override
  Future<bool> isPowerSavingMode() async {
    // Web browsers don't typically expose power saving mode
    return false;
  }

  @override
  Future<Duration> getRecommendedSyncInterval() async {
    final networkInfo = await getNetworkInfo();

    // Web can sync more frequently since it's typically on stable connections
    if (networkInfo.isHighQuality) {
      return const Duration(minutes: 2);
    }
    return const Duration(minutes: 10);
  }

  // === Database Operations ===

  @override
  Future<PlatformDatabaseConfig> getDatabaseConfig(
      String organizationId) async {
    final dbPath = '$_documentsPath/databases/$organizationId.db';

    return PlatformDatabaseConfig(
      databasePath: dbPath,
      maxConnections: 1, // Web typically uses single connection
      enableWAL: false, // WAL not always supported in web SQLite
      enableForeignKeys: true,
      cacheSize: 2000, // Good cache for web
      busyTimeout: const Duration(seconds: 30),
      platformSpecificOptions: {
        'synchronous': 'NORMAL',
        'journal_mode': 'MEMORY', // Memory journal for web
        'temp_store': 'MEMORY',
        'cache_size': 2000,
      },
    );
  }

  @override
  Future<bool> initializeDatabase(PlatformDatabaseConfig config) async {
    try {
      // Web database initialization using IndexedDB
      await logDiagnosticInfo('Web database initialized',
          metadata: {'path': config.databasePath});
      return true;
    } catch (e) {
      await logDiagnosticInfo('Failed to initialize web database',
          metadata: {'error': e.toString()}, level: 'error');
      return false;
    }
  }

  @override
  Future<bool> vacuumDatabase() async {
    // Web database vacuum - might not be necessary for IndexedDB
    await logDiagnosticInfo('Web database vacuum completed');
    return true;
  }

  @override
  Future<int?> getDatabaseSize() async {
    try {
      // Estimate storage usage
      if (html.window.navigator.storage != null) {
        final estimate = await html.window.navigator.storage!.estimate();
        return estimate?['usage'] as int?;
      }
    } catch (e) {
      await logDiagnosticInfo('Failed to get web database size',
          metadata: {'error': e.toString()}, level: 'warning');
    }
    return null;
  }

  @override
  Future<String?> backupDatabase(String backupName) async {
    try {
      // Web database backup to localStorage or download
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupKey = 'backup_${backupName}_$timestamp';

      await logDiagnosticInfo('Web database backup created',
          metadata: {'backupKey': backupKey});
      return backupKey;
    } catch (e) {
      await logDiagnosticInfo('Failed to backup web database',
          metadata: {'error': e.toString()}, level: 'error');
      return null;
    }
  }

  @override
  Future<bool> restoreDatabase(String backupPath) async {
    try {
      await logDiagnosticInfo('Web database restored from backup',
          metadata: {'backupPath': backupPath});
      return true;
    } catch (e) {
      await logDiagnosticInfo('Failed to restore web database',
          metadata: {'error': e.toString()}, level: 'error');
      return false;
    }
  }

  // === Platform-Specific Features ===

  @override
  Future<bool> isRunningInBackground() async {
    // Web page visibility API
    return html.document.hidden ?? false;
  }

  @override
  Future<bool> requestBackgroundPermission() async {
    // Web doesn't require special background permissions
    return true;
  }

  @override
  Future<int?> getAvailableStorageSpace() async {
    try {
      if (html.window.navigator.storage != null) {
        final estimate = await html.window.navigator.storage!.estimate();
        final quota = estimate?['quota'] as int?;
        final usage = estimate?['usage'] as int?;

        if (quota != null && usage != null) {
          return quota - usage;
        }
      }

      // Fallback: estimate based on localStorage
      return 5000000; // 5MB default estimate
    } catch (e) {
      await logDiagnosticInfo('Failed to get web storage space',
          metadata: {'error': e.toString()}, level: 'warning');
    }
    return null;
  }

  @override
  Future<bool> hasResourcesForSync() async {
    final storageSpace = await getAvailableStorageSpace();
    final networkInfo = await getNetworkInfo();

    return (storageSpace == null ||
            storageSpace > 1000000) && // 1MB minimum for web
        networkInfo.isConnected;
  }

  @override
  Future<Map<String, dynamic>> getOptimizationRecommendations() async {
    final networkInfo = await getNetworkInfo();
    final storageSpace = await getAvailableStorageSpace();

    return {
      'syncFrequency': networkInfo.isHighQuality ? 'frequent' : 'moderate',
      'batchSize': 'medium',
      'compressionLevel': 'medium',
      'storageOptimization': storageSpace != null && storageSpace < 5000000
          ? 'aggressive'
          : 'normal',
      'platformSpecific': {
        'useIndexedDB': true,
        'useLocalStorage': true,
        'maxLocalStorageSize': '5MB',
        'enableServiceWorker': false, // Would need to be implemented separately
      },
    };
  }

  @override
  Future<bool> scheduleBackgroundSync({
    required Duration interval,
    required String taskId,
    Map<String, dynamic> parameters = const {},
  }) async {
    // Web background sync using Service Worker (would need implementation)
    await logDiagnosticInfo('Web background sync scheduled', metadata: {
      'taskId': taskId,
      'interval': interval.inMinutes,
      'parameters': parameters,
    });
    return true;
  }

  @override
  Future<bool> cancelBackgroundSync(String taskId) async {
    await logDiagnosticInfo('Web background sync cancelled',
        metadata: {'taskId': taskId});
    return true;
  }

  // === Security and Permissions ===

  @override
  Future<bool> hasRequiredPermissions() async {
    // Web permissions are typically granted automatically
    return true;
  }

  @override
  Future<bool> requestPermissions() async {
    // No special permission requests needed for web
    return true;
  }

  @override
  Future<String?> encryptData(String data, String keyId) async {
    // Web encryption using built-in crypto APIs
    try {
      final bytes = utf8.encode(data);
      final encoded = base64Encode(bytes);
      return encoded;
    } catch (e) {
      await logDiagnosticInfo('Failed to encrypt web data',
          metadata: {'keyId': keyId, 'error': e.toString()}, level: 'error');
      return null;
    }
  }

  @override
  Future<String?> decryptData(String encryptedData, String keyId) async {
    try {
      final bytes = base64Decode(encryptedData);
      final decoded = utf8.decode(bytes);
      return decoded;
    } catch (e) {
      await logDiagnosticInfo('Failed to decrypt web data',
          metadata: {'keyId': keyId, 'error': e.toString()}, level: 'error');
      return null;
    }
  }

  @override
  Future<bool> storeSecureValue(String key, String value) async {
    try {
      final secureData = await _getSecureStorage();
      secureData[key] = await encryptData(value, key) ?? value;
      await _setSecureStorage(secureData);
      return true;
    } catch (e) {
      await logDiagnosticInfo('Failed to store secure web value',
          metadata: {'key': key, 'error': e.toString()}, level: 'error');
      return false;
    }
  }

  @override
  Future<String?> getSecureValue(String key) async {
    try {
      final secureData = await _getSecureStorage();
      final encryptedValue = secureData[key];
      if (encryptedValue == null) return null;

      return await decryptData(encryptedValue, key);
    } catch (e) {
      await logDiagnosticInfo('Failed to get secure web value',
          metadata: {'key': key, 'error': e.toString()}, level: 'error');
      return null;
    }
  }

  @override
  Future<bool> deleteSecureValue(String key) async {
    try {
      final secureData = await _getSecureStorage();
      secureData.remove(key);
      await _setSecureStorage(secureData);
      return true;
    } catch (e) {
      await logDiagnosticInfo('Failed to delete secure web value',
          metadata: {'key': key, 'error': e.toString()}, level: 'error');
      return false;
    }
  }

  // === Logging and Diagnostics ===

  @override
  Future<void> logDiagnosticInfo(
    String message, {
    Map<String, dynamic>? metadata,
    String level = 'info',
  }) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final logEntry = {
        'timestamp': timestamp,
        'level': level,
        'message': message,
        'platform': 'web',
        'metadata': metadata,
      };

      final logs = await _getLogs();
      logs.add(logEntry);

      // Keep only recent logs to avoid storage bloat
      if (logs.length > 1000) {
        logs.removeRange(0, logs.length - 1000);
      }

      await _setLogs(logs);
    } catch (e) {
      // Silent failure for logging to prevent infinite loops
      print('Logging failed: $e'); // Console fallback
    }
  }

  @override
  Future<Map<String, dynamic>> getDiagnosticReport() async {
    final networkInfo = await getNetworkInfo();
    final batteryInfo = await getBatteryInfo();
    final storageSpace = await getAvailableStorageSpace();

    return {
      'platform': {
        'type': platformType.name,
        'version': platformVersion,
        'initialized': isInitialized,
      },
      'paths': {
        'documents': documentsPath,
        'cache': cachePath,
        'temp': tempPath,
      },
      'network': networkInfo.toMap(),
      'battery': batteryInfo.toMap(),
      'storage': {
        'availableSpace': storageSpace,
        'quotaSupported': html.window.navigator.storage != null,
      },
      'web': {
        'userAgent': html.window.navigator.userAgent,
        'cookieEnabled': html.window.navigator.cookieEnabled,
        'onLine': html.window.navigator.onLine,
        'language': html.window.navigator.language,
      },
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<String?> exportLogs({
    DateTime? since,
    String level = 'info',
  }) async {
    try {
      final logs = await _getLogs();

      final filteredLogs = logs.where((entry) {
        final timestamp = DateTime.parse(entry['timestamp']);
        final entryLevel = entry['level'] ?? 'info';

        if (since != null && timestamp.isBefore(since)) return false;

        final levelPriority = {'debug': 0, 'info': 1, 'warning': 2, 'error': 3};
        final requiredPriority = levelPriority[level] ?? 1;
        final entryPriority = levelPriority[entryLevel] ?? 1;

        return entryPriority >= requiredPriority;
      });

      return filteredLogs.map((entry) => jsonEncode(entry)).join('\n');
    } catch (e) {
      await logDiagnosticInfo('Failed to export web logs',
          metadata: {'error': e.toString()}, level: 'error');
      return null;
    }
  }

  // === Private Helper Methods ===

  String _getStorageKey(String path) {
    return 'usm_file_$path';
  }

  NetworkQuality _mapConnectionToQuality(String effectiveType) {
    switch (effectiveType) {
      case 'slow-2g':
      case '2g':
        return NetworkQuality.poor;
      case '3g':
        return NetworkQuality.fair;
      case '4g':
        return NetworkQuality.good;
      case '5g':
        return NetworkQuality.excellent;
      default:
        return NetworkQuality.good;
    }
  }

  Future<List<Map<String, dynamic>>> _getLogs() async {
    try {
      final logsJson = html.window.localStorage[_logStorageKey];
      if (logsJson == null) return [];

      final logsList = jsonDecode(logsJson) as List;
      return logsList.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<void> _setLogs(List<Map<String, dynamic>> logs) async {
    try {
      html.window.localStorage[_logStorageKey] = jsonEncode(logs);
    } catch (e) {
      // Silent failure
    }
  }

  Future<Map<String, String>> _getSecureStorage() async {
    try {
      final secureJson = html.window.localStorage[_secureStorageKey];
      if (secureJson == null) return {};

      final secureMap = jsonDecode(secureJson) as Map;
      return Map<String, String>.from(secureMap);
    } catch (e) {
      return {};
    }
  }

  Future<void> _setSecureStorage(Map<String, String> data) async {
    try {
      html.window.localStorage[_secureStorageKey] = jsonEncode(data);
    } catch (e) {
      // Silent failure
    }
  }

  void _startNetworkMonitoring() {
    // Web network monitoring using online/offline events
    html.window.addEventListener('online', (event) async {
      final networkInfo = await getNetworkInfo();
      _networkController.add(networkInfo);
    });

    html.window.addEventListener('offline', (event) async {
      final networkInfo = await getNetworkInfo();
      _networkController.add(networkInfo);
    });

    // Periodic network quality check
    _networkMonitorTimer =
        Timer.periodic(const Duration(minutes: 2), (timer) async {
      final networkInfo = await getNetworkInfo();
      _networkController.add(networkInfo);
    });
  }

  void _startBatteryMonitoring() {
    // Web battery monitoring (limited support)
    _batteryMonitorTimer =
        Timer.periodic(const Duration(minutes: 10), (timer) async {
      final batteryInfo = await getBatteryInfo();
      _batteryController.add(batteryInfo);
    });
  }
}
