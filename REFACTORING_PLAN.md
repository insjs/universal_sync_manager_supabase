# Universal Sync Manager Refactoring Plan

## Current Issues

The Universal Sync Manager library has several structural issues that need to be addressed:

1. **Duplicate Enum Definitions**:
   - `SyncEventType` in both `usm_sync_event.dart` and `usm_sync_enums.dart`
   - `SyncPriority` in both `usm_sync_enums.dart` and `usm_sync_queue.dart`
   - `ConflictResolutionStrategy` in both `usm_sync_enums.dart` and `usm_conflict_resolver.dart`
   - `SyncMode` in both `usm_sync_enums.dart` and `usm_sync_scheduler.dart`
   - `SyncDirection` in both `usm_sync_enums.dart` and `usm_universal_sync_manager.dart`

2. **Classes Defined in Inappropriate Files**:
   - `SyncCollection` is defined in `usm_universal_sync_manager.dart` but should be in its own file
   - `AppSyncAuthConfiguration` is defined in `usm_universal_sync_manager.dart` but should be in its own file

3. **Missing Exports**:
   - Critical classes and enums used by clients aren't properly exported

## Refactoring Plan

### Phase 1: Standardize Enum Definitions (Break Changes) [Complete]

1. Move all enum definitions to `src/config/usm_sync_enums.dart`:
   - Update `SyncDirection` to use values: `bidirectional`, `uploadOnly`, `downloadOnly`
   - Standardize `ConflictResolutionStrategy` to use values: `localWins`, `serverWins`, `timestampWins`, etc.
   - Standardize `SyncMode`, `SyncPriority`, and `SyncEventType` 

2. Remove duplicate enum definitions from:
   - `src/core/usm_universal_sync_manager.dart`
   - `src/services/usm_sync_queue.dart`
   - `src/services/usm_conflict_resolver.dart`
   - `src/services/usm_sync_scheduler.dart`
   - `src/models/usm_sync_event.dart`

3. Update all references to use the standardized enums

### Phase 2: Extract Classes to Dedicated Files

1. Create a new file `src/models/usm_sync_collection.dart`:
   - Move `SyncCollection` class from `usm_universal_sync_manager.dart`
   - Update it to use the standardized `SyncDirection` enum

2. Create a new file `src/models/usm_app_sync_auth_configuration.dart`:
   - Move `AppSyncAuthConfiguration` class from `usm_universal_sync_manager.dart`
   - Update it to follow project patterns

3. Update `universal_sync_manager.dart` exports to include these new files

### Phase 3: Update Client Code

1. Update any client code that directly references the old enum values
2. Provide migration guide for clients
3. Add version compatibility notes

## Implementation Notes

- This refactoring will require a breaking change version bump (e.g., 1.0.0 → 2.0.0)
- Will need to update all tests to use the standardized enums
- Documentation should be updated to reflect the new structure
- Consider adding a backward compatibility layer for a transition period

## Future Improvements

- Move all data models to dedicated files in the `models` directory
- Standardize naming conventions across all files
- Improve documentation of exported APIs
- Add more comprehensive examples
