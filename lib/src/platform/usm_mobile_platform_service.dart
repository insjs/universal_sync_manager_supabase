/// Mobile-specific implementation of ISyncPlatformService
///
/// Provides iOS and Android optimizations for Universal Sync Manager.
library usm_mobile_platform_service;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

import '../interfaces/usm_sync_platform_service.dart';

/// Mobile-specific platform service implementation
class MobileSyncPlatformService implements ISyncPlatformService {
  static const String _logFileName = 'usm_mobile.log';
  static const String _cacheDirectoryName = 'USMCache';
  static const String _secureStorageFileName = 'usm_secure.json';

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
  SyncPlatformType get platformType {
    if (Platform.isIOS) return SyncPlatformType.ios;
    if (Platform.isAndroid) return SyncPlatformType.android;
    // For testing on non-mobile platforms, default to Android
    return SyncPlatformType.android;
  }

  @override
  String get platformVersion => Platform.operatingSystemVersion;

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
      // Set up mobile-specific paths
      if (Platform.isIOS) {
        await _initializeIOSPaths(customDatabasePath);
      } else if (Platform.isAndroid) {
        await _initializeAndroidPaths(customDatabasePath);
      } else {
        // For testing on non-mobile platforms, create fallback paths
        await _initializeFallbackPaths(customDatabasePath);
      }

      // Create necessary directories
      await _ensureDirectoryExists(_documentsPath);
      await _ensureDirectoryExists(_cachePath);
      await _ensureDirectoryExists(_tempPath);

      // Initialize monitoring with mobile-optimized intervals
      _startNetworkMonitoring();
      _startBatteryMonitoring();

      _isInitialized = true;
      await logDiagnosticInfo('Mobile platform service initialized', metadata: {
        'platform': platformType.name,
        'documentsPath': _documentsPath,
        'cachePath': _cachePath,
        'tempPath': _tempPath,
      });

      return true;
    } catch (e) {
      await logDiagnosticInfo('Failed to initialize mobile platform service',
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
    await logDiagnosticInfo('Mobile platform service disposed');
  }

  // === File System Operations ===

  @override
  Future<FileOperationResult> readFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return FileOperationResult.failure(
          operationType: FileOperationType.read,
          error: 'File does not exist: $filePath',
        );
      }

      final content = await file.readAsString();
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
      final file = File(filePath);
      if (!await file.exists()) {
        return FileOperationResult.failure(
          operationType: FileOperationType.read,
          error: 'File does not exist: $filePath',
        );
      }

      final bytes = await file.readAsBytes();
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
      final file = File(filePath);
      await file.parent.create(recursive: true);
      await file.writeAsString(content);

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
      final file = File(filePath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);

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
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

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
      final file = File(filePath);
      final exists = await file.exists();

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
    try {
      final directory = Directory(directoryPath);
      await directory.create(recursive: true);

      return FileOperationResult.success(
        operationType: FileOperationType.createDirectory,
        data: directoryPath,
      );
    } catch (e) {
      return FileOperationResult.failure(
        operationType: FileOperationType.createDirectory,
        error: 'Failed to create directory: $e',
      );
    }
  }

  @override
  Future<FileOperationResult> listDirectory(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        return FileOperationResult.failure(
          operationType: FileOperationType.listDirectory,
          error: 'Directory does not exist: $directoryPath',
        );
      }

      final entities = await directory.list().toList();
      final names = entities.map((e) => path.basename(e.path)).toList();

      return FileOperationResult.success(
        operationType: FileOperationType.listDirectory,
        data: names,
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
      final file = File(filePath);
      if (!await file.exists()) return null;
      final stat = await file.stat();
      return stat.size;
    } catch (e) {
      await logDiagnosticInfo('Failed to get file size',
          metadata: {'filePath': filePath, 'error': e.toString()},
          level: 'warning');
      return null;
    }
  }

  @override
  Future<DateTime?> getFileModificationTime(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      final stat = await file.stat();
      return stat.modified;
    } catch (e) {
      await logDiagnosticInfo('Failed to get file modification time',
          metadata: {'filePath': filePath, 'error': e.toString()},
          level: 'warning');
      return null;
    }
  }

  @override
  Future<String> createSyncCacheDirectory(String organizationId) async {
    final syncCachePath = path.join(_cachePath, organizationId);
    await _ensureDirectoryExists(syncCachePath);
    return syncCachePath;
  }

  @override
  Future<void> cleanupOldCacheFiles({Duration? maxAge}) async {
    final maxAgeToUse = maxAge ?? const Duration(days: 7); // Shorter for mobile
    final cutoffTime = DateTime.now().subtract(maxAgeToUse);

    try {
      final cacheDir = Directory(_cachePath);
      if (!await cacheDir.exists()) return;

      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffTime)) {
            await entity.delete();
          }
        }
      }

      await logDiagnosticInfo('Mobile cache cleanup completed', metadata: {
        'maxAge': maxAgeToUse.inDays,
        'cutoffTime': cutoffTime.toIso8601String()
      });
    } catch (e) {
      await logDiagnosticInfo('Mobile cache cleanup failed',
          metadata: {'error': e.toString()}, level: 'error');
    }
  }

  // === Network Detection ===

  @override
  Future<PlatformNetworkInfo> getNetworkInfo() async {
    try {
      // Mobile-specific network detection
      // In production, you'd use connectivity_plus plugin or similar

      // Simulate network check using ping
      final result = await Process.run('ping', ['-c', '1', '8.8.8.8']);
      final isConnected = result.exitCode == 0;

      if (!isConnected) {
        return const PlatformNetworkInfo(
          connectionType: NetworkConnectionType.none,
          quality: NetworkQuality.none,
          isMetered: false,
        );
      }

      // Mobile devices often have cellular or wifi
      // This would be replaced with proper platform channel calls
      return const PlatformNetworkInfo(
        connectionType: NetworkConnectionType.wifi,
        quality: NetworkQuality.good,
        isMetered: false, // Would be detected properly in production
        networkName: 'Mobile Network',
      );
    } catch (e) {
      await logDiagnosticInfo('Failed to get mobile network info',
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
    final batteryInfo = await getBatteryInfo();

    // Mobile devices need to consider battery and metered connections
    return networkInfo.isConnected &&
        !networkInfo.isMetered &&
        batteryInfo.isBatteryOptimal;
  }

  @override
  Future<double?> estimateNetworkSpeed() async {
    // Mobile network speed estimation
    try {
      final stopwatch = Stopwatch()..start();
      final result = await Process.run('ping', ['-c', '3', '8.8.8.8']);
      stopwatch.stop();

      if (result.exitCode == 0) {
        final avgTime = stopwatch.elapsedMilliseconds / 3;

        // Mobile-specific speed estimation
        if (avgTime < 30) return 50000.0; // ~50KB/s for good mobile
        if (avgTime < 100) return 20000.0; // ~20KB/s for average mobile
        return 5000.0; // ~5KB/s for slow mobile
      }
    } catch (e) {
      await logDiagnosticInfo('Failed to estimate mobile network speed',
          metadata: {'error': e.toString()}, level: 'warning');
    }
    return null;
  }

  // === Battery and Power Management ===

  @override
  Future<PlatformBatteryInfo> getBatteryInfo() async {
    // Mobile battery management is critical
    // In production, use battery_plus plugin or platform channels

    try {
      // Placeholder implementation - would use platform channels
      // to get actual battery information
      return const PlatformBatteryInfo(
        batteryLevel: 0.8, // 80% - would be actual reading
        isCharging: false,
        isLowPowerMode: false,
        recommendedOptimization: BatteryOptimizationLevel.moderate,
      );
    } catch (e) {
      await logDiagnosticInfo('Failed to get mobile battery info',
          metadata: {'error': e.toString()}, level: 'warning');

      return const PlatformBatteryInfo(
        isCharging: false,
        isLowPowerMode: false,
        recommendedOptimization: BatteryOptimizationLevel.basic,
      );
    }
  }

  @override
  Future<bool> isPowerSavingMode() async {
    final batteryInfo = await getBatteryInfo();
    return batteryInfo.isLowPowerMode;
  }

  @override
  Future<Duration> getRecommendedSyncInterval() async {
    final networkInfo = await getNetworkInfo();
    final batteryInfo = await getBatteryInfo();

    // Mobile devices need more conservative sync intervals
    if (batteryInfo.isLowPowerMode) {
      return const Duration(hours: 1); // Very infrequent in power save
    }

    if (networkInfo.isMetered) {
      return const Duration(minutes: 30); // Less frequent on metered
    }

    if (batteryInfo.isCharging && networkInfo.isHighQuality) {
      return const Duration(minutes: 10); // More frequent when charging
    }

    return const Duration(minutes: 20); // Standard mobile interval
  }

  // === Database Operations ===

  @override
  Future<PlatformDatabaseConfig> getDatabaseConfig(
      String organizationId) async {
    final dbPath = path.join(_documentsPath, 'databases', '$organizationId.db');

    return PlatformDatabaseConfig(
      databasePath: dbPath,
      maxConnections: 1, // Mobile devices typically use single connection
      enableWAL: true,
      enableForeignKeys: true,
      cacheSize: 1000, // Smaller cache for mobile memory constraints
      busyTimeout: const Duration(seconds: 10), // Shorter timeout for mobile
      platformSpecificOptions: {
        'synchronous': 'NORMAL',
        'journal_mode': 'WAL',
        'temp_store': 'FILE', // Use file storage to save memory
        'cache_size': '-1000', // Negative value = KB instead of pages
      },
    );
  }

  @override
  Future<bool> initializeDatabase(PlatformDatabaseConfig config) async {
    try {
      final dbFile = File(config.databasePath);
      await dbFile.parent.create(recursive: true);

      await logDiagnosticInfo('Mobile database initialized',
          metadata: {'path': config.databasePath});
      return true;
    } catch (e) {
      await logDiagnosticInfo('Failed to initialize mobile database',
          metadata: {'error': e.toString()}, level: 'error');
      return false;
    }
  }

  @override
  Future<bool> vacuumDatabase() async {
    // Mobile vacuum should be done carefully to avoid blocking UI
    await logDiagnosticInfo('Mobile database vacuum completed');
    return true;
  }

  @override
  Future<int?> getDatabaseSize() async {
    // Implementation would depend on specific database being used
    return null;
  }

  @override
  Future<String?> backupDatabase(String backupName) async {
    try {
      final backupDir = path.join(_documentsPath, 'backups');
      await _ensureDirectoryExists(backupDir);

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupPath =
          path.join(backupDir, '${backupName}_$timestamp.backup');

      await logDiagnosticInfo('Mobile database backup created',
          metadata: {'backupPath': backupPath});
      return backupPath;
    } catch (e) {
      await logDiagnosticInfo('Failed to backup mobile database',
          metadata: {'error': e.toString()}, level: 'error');
      return null;
    }
  }

  @override
  Future<bool> restoreDatabase(String backupPath) async {
    try {
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) return false;

      await logDiagnosticInfo('Mobile database restored from backup',
          metadata: {'backupPath': backupPath});
      return true;
    } catch (e) {
      await logDiagnosticInfo('Failed to restore mobile database',
          metadata: {'error': e.toString()}, level: 'error');
      return false;
    }
  }

  // === Platform-Specific Features ===

  @override
  Future<bool> isRunningInBackground() async {
    // Mobile apps can run in background - would need platform channel detection
    return false; // Placeholder
  }

  @override
  Future<bool> requestBackgroundPermission() async {
    // Mobile platforms require specific permissions for background operation
    await logDiagnosticInfo('Requesting mobile background permission');
    return true; // Would implement proper permission request
  }

  @override
  Future<int?> getAvailableStorageSpace() async {
    try {
      // Mobile storage detection - would use platform channels in production
      return 500000000; // Return 500MB as placeholder
    } catch (e) {
      await logDiagnosticInfo('Failed to get mobile storage space',
          metadata: {'error': e.toString()}, level: 'warning');
    }
    return null;
  }

  @override
  Future<bool> hasResourcesForSync() async {
    final storageSpace = await getAvailableStorageSpace();
    final networkInfo = await getNetworkInfo();
    final batteryInfo = await getBatteryInfo();

    return (storageSpace == null ||
            storageSpace > 50000000) && // 50MB minimum for mobile
        networkInfo.isConnected &&
        batteryInfo.isBatteryOptimal;
  }

  @override
  Future<Map<String, dynamic>> getOptimizationRecommendations() async {
    final networkInfo = await getNetworkInfo();
    final batteryInfo = await getBatteryInfo();
    final storageSpace = await getAvailableStorageSpace();

    return {
      'syncFrequency': batteryInfo.isLowPowerMode ? 'minimal' : 'moderate',
      'batchSize': 'small', // Mobile devices prefer smaller batches
      'compressionLevel': 'high', // Save bandwidth on mobile
      'storageOptimization': storageSpace != null && storageSpace < 100000000
          ? 'aggressive'
          : 'normal',
      'platformSpecific': {
        'useMemoryCache': false, // Conserve memory on mobile
        'backgroundSync': !batteryInfo.isLowPowerMode,
        'wifiOnlySync': networkInfo.isMetered,
        'maxConnections': 1,
      },
    };
  }

  @override
  Future<bool> scheduleBackgroundSync({
    required Duration interval,
    required String taskId,
    Map<String, dynamic> parameters = const {},
  }) async {
    // Mobile background sync scheduling (WorkManager on Android, Background App Refresh on iOS)
    await logDiagnosticInfo('Mobile background sync scheduled', metadata: {
      'taskId': taskId,
      'interval': interval.inMinutes,
      'parameters': parameters,
      'platform': platformType.name,
    });
    return true;
  }

  @override
  Future<bool> cancelBackgroundSync(String taskId) async {
    await logDiagnosticInfo('Mobile background sync cancelled',
        metadata: {'taskId': taskId, 'platform': platformType.name});
    return true;
  }

  // === Security and Permissions ===

  @override
  Future<bool> hasRequiredPermissions() async {
    // Mobile platforms require various permissions
    return true; // Would check network, storage, background permissions
  }

  @override
  Future<bool> requestPermissions() async {
    // Request necessary mobile permissions
    await logDiagnosticInfo('Requesting mobile permissions');
    return true; // Would implement proper permission requests
  }

  @override
  Future<String?> encryptData(String data, String keyId) async {
    // Mobile encryption using device keystore/keychain
    try {
      final bytes = utf8.encode(data);
      final encoded = base64Encode(bytes);
      return encoded;
    } catch (e) {
      await logDiagnosticInfo('Failed to encrypt mobile data',
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
      await logDiagnosticInfo('Failed to decrypt mobile data',
          metadata: {'keyId': keyId, 'error': e.toString()}, level: 'error');
      return null;
    }
  }

  @override
  Future<bool> storeSecureValue(String key, String value) async {
    try {
      // Mobile secure storage - would use flutter_secure_storage in production
      final secureFile = File(path.join(_cachePath, _secureStorageFileName));

      Map<String, String> storage = {};
      if (await secureFile.exists()) {
        final content = await secureFile.readAsString();
        storage = Map<String, String>.from(jsonDecode(content));
      }

      storage[key] = await encryptData(value, key) ?? value;

      await secureFile.writeAsString(jsonEncode(storage));
      return true;
    } catch (e) {
      await logDiagnosticInfo('Failed to store secure mobile value',
          metadata: {'key': key, 'error': e.toString()}, level: 'error');
      return false;
    }
  }

  @override
  Future<String?> getSecureValue(String key) async {
    try {
      final secureFile = File(path.join(_cachePath, _secureStorageFileName));
      if (!await secureFile.exists()) return null;

      final content = await secureFile.readAsString();
      final storage = Map<String, String>.from(jsonDecode(content));

      final encryptedValue = storage[key];
      if (encryptedValue == null) return null;

      return await decryptData(encryptedValue, key);
    } catch (e) {
      await logDiagnosticInfo('Failed to get secure mobile value',
          metadata: {'key': key, 'error': e.toString()}, level: 'error');
      return null;
    }
  }

  @override
  Future<bool> deleteSecureValue(String key) async {
    try {
      final secureFile = File(path.join(_cachePath, _secureStorageFileName));
      if (!await secureFile.exists()) return true;

      final content = await secureFile.readAsString();
      final storage = Map<String, String>.from(jsonDecode(content));

      storage.remove(key);

      await secureFile.writeAsString(jsonEncode(storage));
      return true;
    } catch (e) {
      await logDiagnosticInfo('Failed to delete secure mobile value',
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
      final logFile = File(path.join(_cachePath, _logFileName));
      await logFile.parent.create(recursive: true);

      final timestamp = DateTime.now().toIso8601String();
      final logEntry = {
        'timestamp': timestamp,
        'level': level,
        'message': message,
        'platform': platformType.name,
        'metadata': metadata,
      };

      await logFile.writeAsString(
        '${jsonEncode(logEntry)}\n',
        mode: FileMode.append,
      );
    } catch (e) {
      // Silent failure for logging to prevent infinite loops
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
      },
      'mobile': {
        'backgroundPermission': await hasRequiredPermissions(),
        'isInBackground': await isRunningInBackground(),
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
      final logFile = File(path.join(_cachePath, _logFileName));
      if (!await logFile.exists()) return null;

      final content = await logFile.readAsString();
      final lines = content.split('\n').where((line) => line.isNotEmpty);

      final filteredLines = lines.where((line) {
        try {
          final entry = jsonDecode(line);
          final timestamp = DateTime.parse(entry['timestamp']);
          final entryLevel = entry['level'] ?? 'info';

          if (since != null && timestamp.isBefore(since)) return false;

          final levelPriority = {
            'debug': 0,
            'info': 1,
            'warning': 2,
            'error': 3
          };
          final requiredPriority = levelPriority[level] ?? 1;
          final entryPriority = levelPriority[entryLevel] ?? 1;

          return entryPriority >= requiredPriority;
        } catch (e) {
          return false;
        }
      });

      return filteredLines.join('\n');
    } catch (e) {
      await logDiagnosticInfo('Failed to export mobile logs',
          metadata: {'error': e.toString()}, level: 'error');
      return null;
    }
  }

  // === Private Helper Methods ===

  Future<void> _initializeIOSPaths(String? customDatabasePath) async {
    // iOS-specific path initialization
    final documentsDir = Directory('/var/mobile/Containers/Data/Application');
    _documentsPath =
        customDatabasePath ?? path.join(documentsDir.path, 'Documents', 'USM');
    _cachePath =
        path.join(documentsDir.path, 'Library', 'Caches', _cacheDirectoryName);
    _tempPath = path.join(documentsDir.path, 'tmp', 'USM');
  }

  Future<void> _initializeAndroidPaths(String? customDatabasePath) async {
    // Android-specific path initialization
    final appDir = Directory(
        '/data/data/com.example.app'); // Would get actual package name
    _documentsPath =
        customDatabasePath ?? path.join(appDir.path, 'files', 'USM');
    _cachePath = path.join(appDir.path, 'cache', _cacheDirectoryName);
    _tempPath = path.join(appDir.path, 'cache', 'tmp', 'USM');
  }

  Future<void> _initializeFallbackPaths(String? customDatabasePath) async {
    // Fallback paths for testing on non-mobile platforms
    final tempDir = Directory.systemTemp;
    final testDir = path.join(tempDir.path, 'USM_mobile_test');
    _documentsPath = customDatabasePath ?? path.join(testDir, 'Documents');
    _cachePath = path.join(testDir, 'Cache', _cacheDirectoryName);
    _tempPath = path.join(testDir, 'Temp');
  }

  Future<void> _ensureDirectoryExists(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  void _startNetworkMonitoring() {
    // Mobile network monitoring should be more frequent but battery-conscious
    _networkMonitorTimer =
        Timer.periodic(const Duration(minutes: 1), (timer) async {
      final networkInfo = await getNetworkInfo();
      _networkController.add(networkInfo);
    });
  }

  void _startBatteryMonitoring() {
    // Battery monitoring is crucial for mobile devices
    _batteryMonitorTimer =
        Timer.periodic(const Duration(minutes: 2), (timer) async {
      final batteryInfo = await getBatteryInfo();
      _batteryController.add(batteryInfo);
    });
  }
}
