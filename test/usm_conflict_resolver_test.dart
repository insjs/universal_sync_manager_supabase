import 'package:universal_sync_manager/src/services/usm_conflict_resolver.dart';
import 'package:universal_sync_manager/src/config/usm_sync_enums.dart';

void main() {
  // Create an instance of DefaultConflictResolver
  final resolver = DefaultConflictResolver(
    defaultStrategy: ConflictResolutionStrategy.intelligentMerge,
  );

  // Create a test conflict
  final conflict = SyncConflict(
    entityId: 'test-123',
    collection: 'test_collection',
    localData: {
      'name': 'Local Name',
      'description': 'Local Description',
      'updatedAt': '2023-06-01T12:00:00Z',
    },
    remoteData: {
      'name': 'Remote Name',
      'description': 'Remote Description',
      'status': 'active',
      'updatedAt': '2023-06-02T12:00:00Z',
    },
    fieldConflicts: {
      'name': ConflictType.valueDifference,
      'description': ConflictType.valueDifference,
      'status': ConflictType.remoteOnly,
    },
    detectedAt: DateTime.now(),
    localVersion: 1,
    remoteVersion: 2,
  );

  // Resolve the conflict
  final resolution = resolver.resolveConflict(conflict);

  // Print resolution details
  print('Conflict resolution strategy: ${resolution.strategy}');
  print('Fields used from local: ${resolution.fieldsUsedFromLocal}');
  print('Fields used from remote: ${resolution.fieldsUsedFromRemote}');
  print('Resolved data: ${resolution.resolvedData}');

  // Create a conflict manager
  final manager = ConflictManager(defaultResolver: resolver);

  // Try detecting a conflict
  final detectedConflict = manager.detectConflict(
    entityId: 'test-456',
    collection: 'test_collection',
    localData: {
      'name': 'Local Name',
      'description': 'Local Description',
      'updatedAt': '2023-06-01T12:00:00Z',
    },
    remoteData: {
      'name': 'Remote Name',
      'description': 'Remote Description',
      'status': 'active',
      'updatedAt': '2023-06-02T12:00:00Z',
    },
    localVersion: 1,
    remoteVersion: 2,
  );

  if (detectedConflict != null) {
    print(
        'Detected conflict: ${detectedConflict.fieldConflicts.length} fields in conflict');

    // Resolve the detected conflict
    final detectedResolution = manager.resolveConflict(detectedConflict);
    print('Detected conflict resolution: ${detectedResolution.strategy}');
  } else {
    print('No conflict detected');
  }
}
