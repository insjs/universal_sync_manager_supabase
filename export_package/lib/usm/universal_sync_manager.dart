// Universal Sync Manager - Core Exports
//
// This file exports all the core USM components for use by applications
// and backend adapter implementations.

// Core Interfaces
export 'src/interfaces/usm_sync_backend_adapter.dart';
export 'src/interfaces/usm_simple_auth_interface.dart';

// Models
export 'src/models/usm_sync_backend_capabilities.dart';
export 'src/models/usm_sync_backend_configuration.dart';
export 'src/models/usm_sync_result.dart';
export 'src/models/usm_sync_event.dart';
export 'src/models/usm_auth_context.dart';
export 'src/models/usm_sync_collection.dart';
export 'src/models/usm_app_sync_auth_configuration.dart';

// Services
export 'src/services/usm_universal_sync_operation_service.dart';
export 'src/services/usm_sync_queue.dart';
export 'src/services/usm_conflict_resolver.dart';
export 'src/services/usm_sync_scheduler.dart';
export 'src/services/usm_sync_event_bus.dart';
export 'src/services/usm_token_manager.dart';

// Adapters
export 'src/adapters/usm_pocketbase_sync_adapter.dart';
export 'src/adapters/usm_firebase_sync_adapter.dart';
export 'src/adapters/usm_supabase_sync_adapter.dart';

// Config and Enums
export 'src/config/usm_sync_enums.dart';

// Core
export 'src/core/usm_universal_sync_manager.dart';

// Phase 3.1: App Integration Framework
export 'src/integration/my_app_sync_manager.dart';

// Phase 3.2: Popular Auth Provider Integration
export 'src/integration/auth_providers/firebase_auth_integration.dart';
export 'src/integration/auth_providers/supabase_auth_integration.dart';
export 'src/integration/auth_providers/auth0_integration.dart';

// Phase 3.3: State Management Integration
export 'src/integration/state_management/bloc_provider_integration.dart';
export 'src/integration/state_management/riverpod_integration.dart';
export 'src/integration/state_management/getx_integration.dart';

// Phase 3.4: Auth Lifecycle Management
export 'src/integration/auth_lifecycle/auth_lifecycle_manager.dart';

// Phase 4: Additional Core Components (planned for future implementation)
// Note: usm_universal_sync_manager.dart is already implemented and exported above
// export 'src/core/usm_sync_operation_service.dart';
// export 'src/models/usm_syncable_model.dart';
// export 'src/models/usm_sync_config.dart';

// Phase 5: Platform Services (planned for future implementation)
// export 'src/platform/usm_sync_platform_service.dart';
