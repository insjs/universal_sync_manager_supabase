/// Universal Sync Manager Platform Service Interface
///
/// Provides platform-independent abstractions for file system operations,
/// network detection, and database operations across all supported platforms.
library usm_sync_platform_service;

import 'dart:async';

/// Platform types supported by Universal Sync Manager
enum SyncPlatformType {
  android,
  ios,
  windows,
  macos,
  linux,
  web,
  unknown,
}

/// Network connection types for platform-specific handling
enum NetworkConnectionType {
  wifi,
  cellular,
  ethernet,
  bluetooth,
  none,
  unknown,
}

/// Network connection quality indicators
enum NetworkQuality {
  excellent,
  good,
  fair,
  poor,
  none,
  unknown,
}

/// Battery optimization levels for sync operations
enum BatteryOptimizationLevel {
  none,
  basic,
  moderate,
  aggressive,
}

/// Platform-specific network information
class PlatformNetworkInfo {
  final NetworkConnectionType connectionType;
  final NetworkQuality quality;
  final bool isMetered;
  final double? signalStrength;
  final String? networkName;
  final bool isRoaming;

  const PlatformNetworkInfo({
    required this.connectionType,
    required this.quality,
    required this.isMetered,
    this.signalStrength,
    this.networkName,
    this.isRoaming = false,
  });

  bool get isConnected => connectionType != NetworkConnectionType.none;
  bool get isHighQuality =>
      quality == NetworkQuality.excellent || quality == NetworkQuality.good;
  bool get isSuitableForSync => isConnected && !isMetered && isHighQuality;

  Map<String, dynamic> toMap() {
    return {
      'connectionType': connectionType.name,
      'quality': quality.name,
      'isMetered': isMetered,
      'signalStrength': signalStrength,
      'networkName': networkName,
      'isRoaming': isRoaming,
    };
  }

  factory PlatformNetworkInfo.fromMap(Map<String, dynamic> map) {
    return PlatformNetworkInfo(
      connectionType: NetworkConnectionType.values.firstWhere(
        (type) => type.name == map['connectionType'],
        orElse: () => NetworkConnectionType.unknown,
      ),
      quality: NetworkQuality.values.firstWhere(
        (quality) => quality.name == map['quality'],
        orElse: () => NetworkQuality.unknown,
      ),
      isMetered: map['isMetered'] ?? false,
      signalStrength: map['signalStrength']?.toDouble(),
      networkName: map['networkName'],
      isRoaming: map['isRoaming'] ?? false,
    );
  }
}

/// Platform-specific battery information
class PlatformBatteryInfo {
  final double? batteryLevel;
  final bool isCharging;
  final bool isLowPowerMode;
  final BatteryOptimizationLevel recommendedOptimization;

  const PlatformBatteryInfo({
    this.batteryLevel,
    required this.isCharging,
    required this.isLowPowerMode,
    required this.recommendedOptimization,
  });

  bool get isBatteryOptimal =>
      (batteryLevel == null || batteryLevel! > 0.2) && !isLowPowerMode;

  Map<String, dynamic> toMap() {
    return {
      'batteryLevel': batteryLevel,
      'isCharging': isCharging,
      'isLowPowerMode': isLowPowerMode,
      'recommendedOptimization': recommendedOptimization.name,
    };
  }

  factory PlatformBatteryInfo.fromMap(Map<String, dynamic> map) {
    return PlatformBatteryInfo(
      batteryLevel: map['batteryLevel']?.toDouble(),
      isCharging: map['isCharging'] ?? false,
      isLowPowerMode: map['isLowPowerMode'] ?? false,
      recommendedOptimization: BatteryOptimizationLevel.values.firstWhere(
        (level) => level.name == map['recommendedOptimization'],
        orElse: () => BatteryOptimizationLevel.none,
      ),
    );
  }
}

/// Platform-specific database configuration
class PlatformDatabaseConfig {
  final String databasePath;
  final int maxConnections;
  final bool enableWAL;
  final bool enableForeignKeys;
  final int cacheSize;
  final Duration busyTimeout;
  final Map<String, dynamic> platformSpecificOptions;

  const PlatformDatabaseConfig({
    required this.databasePath,
    this.maxConnections = 1,
    this.enableWAL = true,
    this.enableForeignKeys = true,
    this.cacheSize = 2000,
    this.busyTimeout = const Duration(seconds: 30),
    this.platformSpecificOptions = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'databasePath': databasePath,
      'maxConnections': maxConnections,
      'enableWAL': enableWAL,
      'enableForeignKeys': enableForeignKeys,
      'cacheSize': cacheSize,
      'busyTimeout': busyTimeout.inMilliseconds,
      'platformSpecificOptions': platformSpecificOptions,
    };
  }

  factory PlatformDatabaseConfig.fromMap(Map<String, dynamic> map) {
    return PlatformDatabaseConfig(
      databasePath: map['databasePath'] ?? '',
      maxConnections: map['maxConnections'] ?? 1,
      enableWAL: map['enableWAL'] ?? true,
      enableForeignKeys: map['enableForeignKeys'] ?? true,
      cacheSize: map['cacheSize'] ?? 2000,
      busyTimeout: Duration(milliseconds: map['busyTimeout'] ?? 30000),
      platformSpecificOptions:
          Map<String, dynamic>.from(map['platformSpecificOptions'] ?? {}),
    );
  }
}

/// File system operation types for platform abstraction
enum FileOperationType {
  read,
  write,
  delete,
  exists,
  createDirectory,
  listDirectory,
}

/// File system operation result
class FileOperationResult {
  final bool success;
  final String? error;
  final dynamic data;
  final FileOperationType operationType;

  const FileOperationResult({
    required this.success,
    this.error,
    this.data,
    required this.operationType,
  });

  factory FileOperationResult.success({
    required FileOperationType operationType,
    dynamic data,
  }) {
    return FileOperationResult(
      success: true,
      operationType: operationType,
      data: data,
    );
  }

  factory FileOperationResult.failure({
    required FileOperationType operationType,
    required String error,
  }) {
    return FileOperationResult(
      success: false,
      error: error,
      operationType: operationType,
    );
  }
}

/// Core platform service interface for Universal Sync Manager
///
/// This interface provides platform-independent abstractions that allow
/// the sync system to work consistently across all supported platforms.
abstract class ISyncPlatformService {
  /// Current platform type
  SyncPlatformType get platformType;

  /// Platform version information
  String get platformVersion;

  /// Application document directory path
  String get documentsPath;

  /// Application cache directory path
  String get cachePath;

  /// Application temporary directory path
  String get tempPath;

  // === Platform Initialization ===

  /// Initialize the platform service with configuration
  Future<bool> initialize({
    String? customDatabasePath,
    Map<String, dynamic> platformOptions = const {},
  });

  /// Dispose of platform resources
  Future<void> dispose();

  /// Check if the platform service is initialized
  bool get isInitialized;

  // === File System Operations ===

  /// Read file contents as string
  Future<FileOperationResult> readFile(String filePath);

  /// Read file contents as bytes
  Future<FileOperationResult> readFileAsBytes(String filePath);

  /// Write string content to file
  Future<FileOperationResult> writeFile(String filePath, String content);

  /// Write bytes to file
  Future<FileOperationResult> writeFileAsBytes(
      String filePath, List<int> bytes);

  /// Delete file
  Future<FileOperationResult> deleteFile(String filePath);

  /// Check if file exists
  Future<FileOperationResult> fileExists(String filePath);

  /// Create directory (recursive)
  Future<FileOperationResult> createDirectory(String directoryPath);

  /// List directory contents
  Future<FileOperationResult> listDirectory(String directoryPath);

  /// Get file size
  Future<int?> getFileSize(String filePath);

  /// Get file modification time
  Future<DateTime?> getFileModificationTime(String filePath);

  /// Create secure cache directory for sync metadata
  Future<String> createSyncCacheDirectory(String organizationId);

  /// Clean up old cache files
  Future<void> cleanupOldCacheFiles({Duration? maxAge});

  // === Network Detection ===

  /// Current network information
  Future<PlatformNetworkInfo> getNetworkInfo();

  /// Stream of network connectivity changes
  Stream<PlatformNetworkInfo> get networkStream;

  /// Check if network is suitable for syncing
  Future<bool> isNetworkSuitableForSync();

  /// Estimate network speed (bytes per second)
  Future<double?> estimateNetworkSpeed();

  // === Battery and Power Management ===

  /// Current battery information
  Future<PlatformBatteryInfo> getBatteryInfo();

  /// Stream of battery status changes
  Stream<PlatformBatteryInfo> get batteryStream;

  /// Check if device is in power saving mode
  Future<bool> isPowerSavingMode();

  /// Get recommended sync frequency based on battery/power state
  Future<Duration> getRecommendedSyncInterval();

  // === Database Operations ===

  /// Get platform-optimized database configuration
  Future<PlatformDatabaseConfig> getDatabaseConfig(String organizationId);

  /// Initialize database with platform-specific optimizations
  Future<bool> initializeDatabase(PlatformDatabaseConfig config);

  /// Execute platform-optimized database vacuum
  Future<bool> vacuumDatabase();

  /// Get database file size
  Future<int?> getDatabaseSize();

  /// Backup database to secure location
  Future<String?> backupDatabase(String backupName);

  /// Restore database from backup
  Future<bool> restoreDatabase(String backupPath);

  // === Platform-Specific Features ===

  /// Check if running in background mode
  Future<bool> isRunningInBackground();

  /// Request permission for background execution
  Future<bool> requestBackgroundPermission();

  /// Get available storage space
  Future<int?> getAvailableStorageSpace();

  /// Check if device has sufficient resources for sync
  Future<bool> hasResourcesForSync();

  /// Get platform-specific optimization recommendations
  Future<Map<String, dynamic>> getOptimizationRecommendations();

  /// Schedule platform-native background sync task
  Future<bool> scheduleBackgroundSync({
    required Duration interval,
    required String taskId,
    Map<String, dynamic> parameters = const {},
  });

  /// Cancel scheduled background sync task
  Future<bool> cancelBackgroundSync(String taskId);

  // === Security and Permissions ===

  /// Check if app has required permissions
  Future<bool> hasRequiredPermissions();

  /// Request necessary permissions for sync operations
  Future<bool> requestPermissions();

  /// Encrypt sensitive data using platform keystore/keychain
  Future<String?> encryptData(String data, String keyId);

  /// Decrypt data using platform keystore/keychain
  Future<String?> decryptData(String encryptedData, String keyId);

  /// Store secure value in platform keystore/keychain
  Future<bool> storeSecureValue(String key, String value);

  /// Retrieve secure value from platform keystore/keychain
  Future<String?> getSecureValue(String key);

  /// Delete secure value from platform keystore/keychain
  Future<bool> deleteSecureValue(String key);

  // === Logging and Diagnostics ===

  /// Log platform-specific diagnostic information
  Future<void> logDiagnosticInfo(
    String message, {
    Map<String, dynamic>? metadata,
    String level = 'info',
  });

  /// Get platform diagnostic report
  Future<Map<String, dynamic>> getDiagnosticReport();

  /// Export logs for debugging
  Future<String?> exportLogs({
    DateTime? since,
    String level = 'info',
  });
}
