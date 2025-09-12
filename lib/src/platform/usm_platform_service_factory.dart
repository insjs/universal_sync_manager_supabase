/// Platform Service Factory for Universal Sync Manager
///
/// Creates platform-specific implementations of ISyncPlatformService.
library usm_platform_service_factory;

import 'dart:io' show Platform;

import '../interfaces/usm_sync_platform_service.dart';
import 'usm_windows_platform_service.dart';
import 'usm_mobile_platform_service.dart';

// Import web service conditionally
import 'usm_web_platform_service.dart'
    if (dart.library.io) 'usm_stub_web_platform_service.dart';

/// Factory for creating platform-specific sync platform services
class SyncPlatformServiceFactory {
  /// Create platform service for current platform
  static ISyncPlatformService createForCurrentPlatform() {
    final platformType = getCurrentPlatform();
    return createForPlatform(platformType);
  }

  /// Create platform service for specific platform type
  static ISyncPlatformService createForPlatform(SyncPlatformType platformType) {
    switch (platformType) {
      case SyncPlatformType.windows:
        return WindowsSyncPlatformService();

      case SyncPlatformType.android:
      case SyncPlatformType.ios:
        return MobileSyncPlatformService();

      case SyncPlatformType.web:
        return _createWebPlatformService();

      case SyncPlatformType.macos:
        // macOS can use Windows service for now, or implement separately
        return WindowsSyncPlatformService();

      case SyncPlatformType.linux:
        // Linux can use Windows service for now, or implement separately
        return WindowsSyncPlatformService();

      case SyncPlatformType.unknown:
        // Fallback to Windows service for unknown platforms
        return WindowsSyncPlatformService();
    }
  }

  /// Get current platform type
  static SyncPlatformType getCurrentPlatform() {
    // Check if running in web environment
    if (identical(0, 0.0)) {
      // This is a web-specific check
      return SyncPlatformType.web;
    }

    // Check dart:io availability for native platforms
    try {
      if (Platform.isWindows) {
        return SyncPlatformType.windows;
      } else if (Platform.isAndroid) {
        return SyncPlatformType.android;
      } else if (Platform.isIOS) {
        return SyncPlatformType.ios;
      } else if (Platform.isMacOS) {
        return SyncPlatformType.macos;
      } else if (Platform.isLinux) {
        return SyncPlatformType.linux;
      }
    } catch (e) {
      // Platform detection failed, likely web environment
      return SyncPlatformType.web;
    }

    return SyncPlatformType.unknown;
  }

  /// Check if current platform supports background sync
  static bool supportsBackgroundSync() {
    final platformType = getCurrentPlatform();
    switch (platformType) {
      case SyncPlatformType.android:
      case SyncPlatformType.ios:
        return true; // Mobile platforms support background sync
      case SyncPlatformType.windows:
      case SyncPlatformType.macos:
      case SyncPlatformType.linux:
        return true; // Desktop platforms support background sync
      case SyncPlatformType.web:
        return false; // Web has limited background sync support
      case SyncPlatformType.unknown:
        return false;
    }
  }

  /// Check if current platform supports battery management
  static bool supportsBatteryManagement() {
    final platformType = getCurrentPlatform();
    switch (platformType) {
      case SyncPlatformType.android:
      case SyncPlatformType.ios:
        return true; // Mobile platforms have battery management
      case SyncPlatformType.windows:
      case SyncPlatformType.macos:
      case SyncPlatformType.linux:
        return false; // Desktop platforms typically don't need battery management
      case SyncPlatformType.web:
        return false; // Web platforms don't expose battery information
      case SyncPlatformType.unknown:
        return false;
    }
  }

  /// Check if current platform supports real file system operations
  static bool supportsFileSystem() {
    final platformType = getCurrentPlatform();
    switch (platformType) {
      case SyncPlatformType.android:
      case SyncPlatformType.ios:
      case SyncPlatformType.windows:
      case SyncPlatformType.macos:
      case SyncPlatformType.linux:
        return true; // Native platforms support file system
      case SyncPlatformType.web:
        return false; // Web uses localStorage/IndexedDB instead
      case SyncPlatformType.unknown:
        return false;
    }
  }

  /// Get recommended sync interval for current platform
  static Duration getRecommendedSyncInterval() {
    final platformType = getCurrentPlatform();
    switch (platformType) {
      case SyncPlatformType.android:
      case SyncPlatformType.ios:
        return const Duration(minutes: 15); // Conservative for mobile
      case SyncPlatformType.windows:
      case SyncPlatformType.macos:
      case SyncPlatformType.linux:
        return const Duration(minutes: 5); // More frequent for desktop
      case SyncPlatformType.web:
        return const Duration(minutes: 2); // Frequent for web
      case SyncPlatformType.unknown:
        return const Duration(minutes: 10); // Safe default
    }
  }

  /// Get platform-specific optimization recommendations
  static Map<String, dynamic> getPlatformOptimizations() {
    final platformType = getCurrentPlatform();
    switch (platformType) {
      case SyncPlatformType.android:
      case SyncPlatformType.ios:
        return {
          'batchSize': 'small',
          'compressionLevel': 'high',
          'backgroundSync': true,
          'batteryOptimization': true,
          'maxConnections': 1,
          'cacheSize': 1000,
        };

      case SyncPlatformType.windows:
      case SyncPlatformType.macos:
      case SyncPlatformType.linux:
        return {
          'batchSize': 'large',
          'compressionLevel': 'medium',
          'backgroundSync': true,
          'batteryOptimization': false,
          'maxConnections': 4,
          'cacheSize': 4000,
        };

      case SyncPlatformType.web:
        return {
          'batchSize': 'medium',
          'compressionLevel': 'medium',
          'backgroundSync': false,
          'batteryOptimization': false,
          'maxConnections': 1,
          'cacheSize': 2000,
        };

      case SyncPlatformType.unknown:
        return {
          'batchSize': 'medium',
          'compressionLevel': 'medium',
          'backgroundSync': false,
          'batteryOptimization': false,
          'maxConnections': 1,
          'cacheSize': 2000,
        };
    }
  }

  /// Create diagnostic report for platform capabilities
  static Map<String, dynamic> getPlatformCapabilities() {
    final platformType = getCurrentPlatform();

    return {
      'platformType': platformType.name,
      'supportsBackgroundSync': supportsBackgroundSync(),
      'supportsBatteryManagement': supportsBatteryManagement(),
      'supportsFileSystem': supportsFileSystem(),
      'recommendedSyncInterval': getRecommendedSyncInterval().inSeconds,
      'optimizations': getPlatformOptimizations(),
      'detectedAt': DateTime.now().toIso8601String(),
    };
  }

  // Private helper method for web platform service creation
  static ISyncPlatformService _createWebPlatformService() {
    try {
      return WebSyncPlatformService();
    } catch (e) {
      // Fallback if web service is not available
      throw UnsupportedError('Web platform service not available: $e');
    }
  }
}

/// Extension methods for SyncPlatformType enum
extension SyncPlatformTypeExtension on SyncPlatformType {
  /// Check if this is a mobile platform
  bool get isMobile =>
      this == SyncPlatformType.android || this == SyncPlatformType.ios;

  /// Check if this is a desktop platform
  bool get isDesktop =>
      this == SyncPlatformType.windows ||
      this == SyncPlatformType.macos ||
      this == SyncPlatformType.linux;

  /// Check if this is a web platform
  bool get isWeb => this == SyncPlatformType.web;

  /// Get display name for this platform
  String get displayName {
    switch (this) {
      case SyncPlatformType.android:
        return 'Android';
      case SyncPlatformType.ios:
        return 'iOS';
      case SyncPlatformType.windows:
        return 'Windows';
      case SyncPlatformType.macos:
        return 'macOS';
      case SyncPlatformType.linux:
        return 'Linux';
      case SyncPlatformType.web:
        return 'Web';
      case SyncPlatformType.unknown:
        return 'Unknown';
    }
  }
}
