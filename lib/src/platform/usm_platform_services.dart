/// Universal Sync Manager Platform Services
///
/// Exports all platform-related services and abstractions.
library usm_platform_services;

// Platform service interface
export '../interfaces/usm_sync_platform_service.dart';

// Platform service implementations
export 'usm_windows_platform_service.dart';
export 'usm_mobile_platform_service.dart';

// Web platform service (conditionally exported)
export 'usm_web_platform_service.dart'
    if (dart.library.io) 'usm_stub_web_platform_service.dart';

// Platform service factory
export 'usm_platform_service_factory.dart';
