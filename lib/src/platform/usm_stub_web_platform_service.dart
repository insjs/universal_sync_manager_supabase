/// Stub Web Platform Service for non-web environments
///
/// This stub is used when running on non-web platforms where
/// the web-specific implementations are not available.
library usm_stub_web_platform_service;

import 'dart:async';

import '../interfaces/usm_sync_platform_service.dart';

/// Stub implementation of web platform service for non-web environments
class WebSyncPlatformService implements ISyncPlatformService {
  @override
  SyncPlatformType get platformType => SyncPlatformType.web;

  @override
  String get platformVersion => 'Stub Web Platform';

  @override
  String get documentsPath => '/stub/documents';

  @override
  String get cachePath => '/stub/cache';

  @override
  String get tempPath => '/stub/temp';

  @override
  bool get isInitialized => false;

  @override
  Stream<PlatformNetworkInfo> get networkStream =>
      Stream<PlatformNetworkInfo>.empty();

  @override
  Stream<PlatformBatteryInfo> get batteryStream =>
      Stream<PlatformBatteryInfo>.empty();

  @override
  Future<bool> initialize({
    String? customDatabasePath,
    Map<String, dynamic> platformOptions = const {},
  }) async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<void> dispose() async {
    // No-op for stub
  }

  @override
  Future<FileOperationResult> readFile(String filePath) async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<FileOperationResult> readFileAsBytes(String filePath) async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<FileOperationResult> writeFile(String filePath, String content) async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<FileOperationResult> writeFileAsBytes(
      String filePath, List<int> bytes) async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<FileOperationResult> deleteFile(String filePath) async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<FileOperationResult> fileExists(String filePath) async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<FileOperationResult> createDirectory(String directoryPath) async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<FileOperationResult> listDirectory(String directoryPath) async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<int?> getFileSize(String filePath) async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<DateTime?> getFileModificationTime(String filePath) async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<String> createSyncCacheDirectory(String organizationId) async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<void> cleanupOldCacheFiles({Duration? maxAge}) async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<PlatformNetworkInfo> getNetworkInfo() async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<bool> isNetworkSuitableForSync() async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<double?> estimateNetworkSpeed() async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<PlatformBatteryInfo> getBatteryInfo() async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<bool> isPowerSavingMode() async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<Duration> getRecommendedSyncInterval() async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<PlatformDatabaseConfig> getDatabaseConfig(
      String organizationId) async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<bool> initializeDatabase(PlatformDatabaseConfig config) async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<bool> vacuumDatabase() async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<int?> getDatabaseSize() async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<String?> backupDatabase(String backupName) async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<bool> restoreDatabase(String backupPath) async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<bool> isRunningInBackground() async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<bool> requestBackgroundPermission() async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<int?> getAvailableStorageSpace() async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<bool> hasResourcesForSync() async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<Map<String, dynamic>> getOptimizationRecommendations() async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<bool> scheduleBackgroundSync({
    required Duration interval,
    required String taskId,
    Map<String, dynamic> parameters = const {},
  }) async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<bool> cancelBackgroundSync(String taskId) async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<bool> hasRequiredPermissions() async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<bool> requestPermissions() async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<String?> encryptData(String data, String keyId) async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<String?> decryptData(String encryptedData, String keyId) async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<bool> storeSecureValue(String key, String value) async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<String?> getSecureValue(String key) async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<bool> deleteSecureValue(String key) async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<void> logDiagnosticInfo(
    String message, {
    Map<String, dynamic>? metadata,
    String level = 'info',
  }) async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<Map<String, dynamic>> getDiagnosticReport() async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }

  @override
  Future<String?> exportLogs({
    DateTime? since,
    String level = 'info',
  }) async {
    throw UnsupportedError(
        'Web platform service not available in this environment');
  }
}
