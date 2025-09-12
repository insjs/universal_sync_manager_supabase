import 'dart:async';
import '../config/usm_sync_enums.dart';

/// Represents a conflict between local and remote data
class SyncConflict {
  final String entityId;
  final String collection;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final Map<String, ConflictType> fieldConflicts;
  final DateTime detectedAt;
  final int localVersion;
  final int remoteVersion;
  final Map<String, dynamic> metadata;

  SyncConflict({
    required this.entityId,
    required this.collection,
    required this.localData,
    required this.remoteData,
    required this.fieldConflicts,
    required this.detectedAt,
    required this.localVersion,
    required this.remoteVersion,
    this.metadata = const {},
  });

  /// Get the list of all affected fields with conflicts
  List<String> get affectedFields => fieldConflicts.keys.toList();

  @override
  String toString() {
    return 'SyncConflict(entityId: $entityId, collection: $collection, fieldConflicts: ${fieldConflicts.length})';
  }
}

/// Result of conflict resolution
class SyncConflictResolution {
  final Map<String, dynamic> resolvedData;
  final ConflictResolutionStrategy strategy;
  final List<String> fieldsUsedFromLocal;
  final List<String> fieldsUsedFromRemote;
  final List<String> fieldsRequiringManualReview;
  final bool requiresUserIntervention;
  final Map<String, dynamic> metadata;

  SyncConflictResolution({
    required this.resolvedData,
    required this.strategy,
    required this.fieldsUsedFromLocal,
    required this.fieldsUsedFromRemote,
    this.fieldsRequiringManualReview = const [],
    this.requiresUserIntervention = false,
    this.metadata = const {},
  });

  /// Factory for local wins resolution
  factory SyncConflictResolution.useLocal(Map<String, dynamic> localData) {
    return SyncConflictResolution(
      resolvedData: Map<String, dynamic>.from(localData),
      strategy: ConflictResolutionStrategy.localWins,
      fieldsUsedFromLocal: localData.keys.toList(),
      fieldsUsedFromRemote: [],
    );
  }

  /// Factory for remote wins resolution
  factory SyncConflictResolution.useRemote(Map<String, dynamic> remoteData) {
    return SyncConflictResolution(
      resolvedData: Map<String, dynamic>.from(remoteData),
      strategy: ConflictResolutionStrategy.remoteWins,
      fieldsUsedFromLocal: [],
      fieldsUsedFromRemote: remoteData.keys.toList(),
    );
  }

  /// Factory for manual resolution required
  factory SyncConflictResolution.requiresManual(
    SyncConflict conflict, {
    List<String> fieldsNeedingReview = const [],
  }) {
    return SyncConflictResolution(
      resolvedData: Map<String, dynamic>.from(conflict.localData),
      strategy: ConflictResolutionStrategy.manual,
      fieldsUsedFromLocal: [],
      fieldsUsedFromRemote: [],
      fieldsRequiringManualReview: fieldsNeedingReview,
      requiresUserIntervention: true,
    );
  }

  @override
  String toString() {
    return 'SyncConflictResolution(strategy: $strategy, requiresUserIntervention: $requiresUserIntervention)';
  }
}

/// Abstract base class for conflict resolvers
abstract class ConflictResolver {
  /// Resolves a conflict between local and remote data
  SyncConflictResolution resolveConflict(SyncConflict conflict);

  /// Returns the name of this resolver
  String get name;

  /// Returns whether this resolver can handle the given conflict
  bool canResolve(SyncConflict conflict);
}

/// Default conflict resolver that uses configurable strategies
class DefaultConflictResolver implements ConflictResolver {
  final ConflictResolutionStrategy _defaultStrategy;
  final Map<String, ConflictResolutionStrategy> _fieldStrategies = {};
  final Map<String, ConflictResolutionStrategy> _collectionStrategies = {};

  DefaultConflictResolver({
    ConflictResolutionStrategy defaultStrategy =
        ConflictResolutionStrategy.remoteWins,
    Map<String, ConflictResolutionStrategy>? fieldStrategies,
    Map<String, ConflictResolutionStrategy>? collectionStrategies,
  }) : _defaultStrategy = defaultStrategy {
    if (fieldStrategies != null) {
      _fieldStrategies.addAll(fieldStrategies);
    }
    if (collectionStrategies != null) {
      _collectionStrategies.addAll(collectionStrategies);
    }
  }

  /// Set a strategy for a specific field
  void setFieldStrategy(String fieldName, ConflictResolutionStrategy strategy) {
    _fieldStrategies[fieldName] = strategy;
  }

  /// Set a strategy for a specific collection
  void setCollectionStrategy(
      String collection, ConflictResolutionStrategy strategy) {
    _collectionStrategies[collection] = strategy;
  }

  @override
  String get name => 'DefaultConflictResolver';

  @override
  bool canResolve(SyncConflict conflict) => true;

  @override
  SyncConflictResolution resolveConflict(SyncConflict conflict) {
    // Check for collection-specific strategy
    final collectionStrategy = _collectionStrategies[conflict.collection];
    final strategy = collectionStrategy ?? _defaultStrategy;

    switch (strategy) {
      case ConflictResolutionStrategy.localWins:
        return SyncConflictResolution.useLocal(conflict.localData);

      case ConflictResolutionStrategy.serverWins:
      case ConflictResolutionStrategy.remoteWins:
        return SyncConflictResolution.useRemote(conflict.remoteData);

      case ConflictResolutionStrategy.newestWins:
      case ConflictResolutionStrategy.timestampWins:
        return _resolveByTimestamp(conflict, preferNewer: true);

      case ConflictResolutionStrategy.oldestWins:
        return _resolveByTimestamp(conflict, preferNewer: false);

      case ConflictResolutionStrategy.intelligentMerge:
        return _intelligentMerge(conflict);

      case ConflictResolutionStrategy.manualResolution:
      case ConflictResolutionStrategy.manual:
        return SyncConflictResolution.requiresManual(
          conflict,
          fieldsNeedingReview: conflict.fieldConflicts.keys.toList(),
        );

      case ConflictResolutionStrategy.custom:
        return _customResolve(conflict);

      case ConflictResolutionStrategy.mergeOrPrompt:
        try {
          return _intelligentMerge(conflict);
        } catch (e) {
          return SyncConflictResolution.requiresManual(
            conflict,
            fieldsNeedingReview: conflict.fieldConflicts.keys.toList(),
          );
        }
    }
  }

  /// Resolve based on timestamps
  SyncConflictResolution _resolveByTimestamp(
    SyncConflict conflict, {
    required bool preferNewer,
  }) {
    final localUpdatedAt = _getTimestamp(conflict.localData, 'updatedAt');
    final remoteUpdatedAt = _getTimestamp(conflict.remoteData, 'updatedAt');

    if (localUpdatedAt == null && remoteUpdatedAt == null) {
      // No timestamps available, use version numbers
      if (preferNewer) {
        return conflict.localVersion >= conflict.remoteVersion
            ? SyncConflictResolution.useLocal(conflict.localData)
            : SyncConflictResolution.useRemote(conflict.remoteData);
      } else {
        return conflict.localVersion <= conflict.remoteVersion
            ? SyncConflictResolution.useLocal(conflict.localData)
            : SyncConflictResolution.useRemote(conflict.remoteData);
      }
    }

    if (localUpdatedAt == null) {
      return SyncConflictResolution.useRemote(conflict.remoteData);
    }

    if (remoteUpdatedAt == null) {
      return SyncConflictResolution.useLocal(conflict.localData);
    }

    if (preferNewer) {
      return localUpdatedAt.isAfter(remoteUpdatedAt)
          ? SyncConflictResolution.useLocal(conflict.localData)
          : SyncConflictResolution.useRemote(conflict.remoteData);
    } else {
      return localUpdatedAt.isBefore(remoteUpdatedAt)
          ? SyncConflictResolution.useLocal(conflict.localData)
          : SyncConflictResolution.useRemote(conflict.remoteData);
    }
  }

  /// Intelligently merge data from both sources
  SyncConflictResolution _intelligentMerge(SyncConflict conflict) {
    final resolvedData = <String, dynamic>{};
    final localFields = <String>[];
    final remoteFields = <String>[];

    // Start with remote data as base
    resolvedData.addAll(conflict.remoteData);
    remoteFields.addAll(conflict.remoteData.keys);

    // Apply field-specific strategies
    for (final fieldName in conflict.fieldConflicts.keys) {
      final fieldStrategy = _fieldStrategies[fieldName];

      if (fieldStrategy != null) {
        switch (fieldStrategy) {
          case ConflictResolutionStrategy.localWins:
            if (conflict.localData.containsKey(fieldName)) {
              resolvedData[fieldName] = conflict.localData[fieldName];
              localFields.add(fieldName);
              remoteFields.remove(fieldName);
            }
            break;
          case ConflictResolutionStrategy.remoteWins:
          case ConflictResolutionStrategy.serverWins:
            // Already using remote data as base
            break;
          case ConflictResolutionStrategy.newestWins:
          case ConflictResolutionStrategy.timestampWins:
            // Use timestamp comparison for this field
            final localTime = _getTimestamp(conflict.localData, 'updatedAt');
            final remoteTime = _getTimestamp(conflict.remoteData, 'updatedAt');
            if (localTime != null &&
                remoteTime != null &&
                localTime.isAfter(remoteTime)) {
              resolvedData[fieldName] = conflict.localData[fieldName];
              localFields.add(fieldName);
              remoteFields.remove(fieldName);
            }
            break;
          default:
            // For other strategies, stick with remote
            break;
        }
      } else if (_shouldPreferLocalField(fieldName, conflict)) {
        // Apply intelligent logic for fields without specific strategy
        if (conflict.localData.containsKey(fieldName)) {
          resolvedData[fieldName] = conflict.localData[fieldName];
          localFields.add(fieldName);
          remoteFields.remove(fieldName);
        }
      }
    }

    return SyncConflictResolution(
      resolvedData: resolvedData,
      strategy: ConflictResolutionStrategy.intelligentMerge,
      fieldsUsedFromLocal: localFields,
      fieldsUsedFromRemote: remoteFields,
    );
  }

  /// Custom conflict resolution logic
  SyncConflictResolution _customResolve(SyncConflict conflict) {
    // This is a placeholder for custom resolution logic
    // By default, use intelligent merge
    return _intelligentMerge(conflict);
  }

  /// Helper to parse timestamp string to DateTime
  DateTime? _getTimestamp(Map<String, dynamic> data, String fieldName) {
    final timestamp = data[fieldName];
    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Determines if local field should be preferred based on field type/name
  bool _shouldPreferLocalField(String field, SyncConflict conflict) {
    // Example implementation - override in subclasses for custom logic
    // For example, prefer local for user preferences
    return field.contains('preference') ||
        field.contains('setting') ||
        field.contains('userConfig');
  }
}

/// Class to detect and manage conflicts
class ConflictManager {
  final Map<String, ConflictResolver> _resolvers = {};
  final ConflictResolver _defaultResolver;

  final StreamController<SyncConflict> _conflictDetectedController =
      StreamController<SyncConflict>.broadcast();

  final StreamController<SyncConflictResolution> _conflictResolvedController =
      StreamController<SyncConflictResolution>.broadcast();

  ConflictManager({
    ConflictResolver? defaultResolver,
  }) : _defaultResolver = defaultResolver ?? DefaultConflictResolver();

  /// Stream of detected conflicts
  Stream<SyncConflict> get conflictDetected =>
      _conflictDetectedController.stream;

  /// Stream of resolved conflicts
  Stream<SyncConflictResolution> get conflictResolved =>
      _conflictResolvedController.stream;

  /// Register a conflict resolver for a specific collection
  void registerResolver(String collection, ConflictResolver resolver) {
    _resolvers[collection] = resolver;
  }

  /// Detect potential conflicts between local and remote data
  /// Returns a conflict object if detected, null otherwise
  SyncConflict? detectConflict({
    required String entityId,
    required String collection,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
    required int localVersion,
    required int remoteVersion,
  }) {
    // Skip conflict detection if versions match
    if (localVersion == remoteVersion) {
      return null;
    }

    final fieldConflicts = <String, ConflictType>{};

    // Check all fields in both data objects
    final allFields = <String>{
      ...localData.keys,
      ...remoteData.keys,
    };

    for (final field in allFields) {
      // Skip standard audit fields that don't need conflict resolution
      if (_isAuditField(field)) continue;

      // If field exists in both and values differ, mark as conflict
      if (localData.containsKey(field) && remoteData.containsKey(field)) {
        if (!_areValuesEqual(localData[field], remoteData[field])) {
          fieldConflicts[field] = ConflictType.valueDifference;
        }
      }
      // Field exists only in local data
      else if (localData.containsKey(field) && !remoteData.containsKey(field)) {
        fieldConflicts[field] = ConflictType.localOnly;
      }
      // Field exists only in remote data
      else if (!localData.containsKey(field) && remoteData.containsKey(field)) {
        fieldConflicts[field] = ConflictType.remoteOnly;
      }
    }

    // If no field conflicts, return null
    if (fieldConflicts.isEmpty) {
      return null;
    }

    // Create conflict object
    final conflict = SyncConflict(
      entityId: entityId,
      collection: collection,
      localData: localData,
      remoteData: remoteData,
      fieldConflicts: fieldConflicts,
      detectedAt: DateTime.now(),
      localVersion: localVersion,
      remoteVersion: remoteVersion,
    );

    // Notify listeners
    _conflictDetectedController.add(conflict);

    return conflict;
  }

  /// Resolve a conflict using the appropriate resolver
  SyncConflictResolution resolveConflict(SyncConflict conflict) {
    // Get collection-specific resolver or use default
    final resolver = _resolvers[conflict.collection] ?? _defaultResolver;

    // Check if resolver can handle this conflict
    if (resolver.canResolve(conflict)) {
      final resolution = resolver.resolveConflict(conflict);
      _conflictResolvedController.add(resolution);
      return resolution;
    } else {
      // Fallback to default resolver if the specific one can't handle it
      final resolution = _defaultResolver.resolveConflict(conflict);
      _conflictResolvedController.add(resolution);
      return resolution;
    }
  }

  /// Check if a field is a standard audit field
  bool _isAuditField(String field) {
    return [
      'createdAt',
      'createdBy',
      'updatedAt',
      'updatedBy',
      'deletedAt',
      'syncVersion',
      'lastSyncedAt',
    ].contains(field);
  }

  /// Compare values for equality, handling different types
  bool _areValuesEqual(dynamic value1, dynamic value2) {
    // Exact equality
    if (value1 == value2) return true;

    // Handle null values
    if (value1 == null || value2 == null) return false;

    // Handle different types by converting to string
    return value1.toString() == value2.toString();
  }

  /// Clean up resources
  void dispose() {
    _conflictDetectedController.close();
    _conflictResolvedController.close();
  }
}
