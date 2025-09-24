// lib/src/services/usm_enhanced_conflict_resolution_manager.dart

import 'dart:async';
import '../config/usm_sync_enums.dart';
import 'usm_enhanced_conflict_resolver.dart';
import 'usm_interactive_conflict_ui.dart';

/// Priority level for conflicts
enum EnhancedConflictPriority {
  /// Low priority conflict that can wait
  low,

  /// Medium priority conflict
  medium,

  /// High priority conflict that needs immediate attention
  high,

  /// Critical conflict that blocks operations
  critical
}

/// Source of conflict resolution
enum EnhancedResolutionSource {
  /// Resolved automatically by the system
  automatic,

  /// Resolved by a user
  manual,

  /// Resolved by AI assistance
  ai,

  /// Resolved by business rules
  businessRule
}

/// Manager for handling enhanced conflict resolution with multiple strategies
class EnhancedConflictResolutionManager {
  final Map<String, EnhancedConflictResolver> _resolvers = {};
  final EnhancedConflictResolver _defaultResolver;
  final InteractiveConflictUIService? _interactiveUIService;
  final bool _enableAIResolution;
  final bool _enableInteractiveResolution;

  final StreamController<EnhancedSyncConflict> _conflictDetectedController =
      StreamController<EnhancedSyncConflict>.broadcast();
  final StreamController<EnhancedSyncConflictResolution>
      _conflictResolvedController =
      StreamController<EnhancedSyncConflictResolution>.broadcast();

  /// Stream of detected conflicts
  Stream<EnhancedSyncConflict> get conflictDetected =>
      _conflictDetectedController.stream;

  /// Stream of resolved conflicts
  Stream<EnhancedSyncConflictResolution> get conflictResolved =>
      _conflictResolvedController.stream;

  EnhancedConflictResolutionManager({
    EnhancedConflictResolver? defaultResolver,
    InteractiveConflictUIService? interactiveUIService,
    bool enableAIResolution = false,
    bool enableInteractiveResolution = false,
  })  : _defaultResolver = defaultResolver ?? _SimpleConflictResolver(),
        _interactiveUIService = interactiveUIService,
        _enableAIResolution = enableAIResolution,
        _enableInteractiveResolution = enableInteractiveResolution;

  /// Registers a conflict resolver for a specific collection
  void registerResolver(String collection, EnhancedConflictResolver resolver) {
    _resolvers[collection] = resolver;
  }

  /// Removes a conflict resolver for a collection
  void removeResolver(String collection) {
    _resolvers.remove(collection);
  }

  /// Detects conflicts between local and remote data
  EnhancedSyncConflict? detectConflict({
    required String entityId,
    required String collection,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
    required int localVersion,
    required int remoteVersion,
    EnhancedConflictPriority priority = EnhancedConflictPriority.medium,
    List<String>? tags,
  }) {
    // Skip if versions match exactly
    if (localVersion == remoteVersion) {
      return null;
    }

    // Detect field conflicts
    final fieldConflicts = <String, FieldConflictInfo>{};
    final allFields = <String>{
      ...localData.keys,
      ...remoteData.keys,
    };

    // Skip standard sync fields from conflict detection
    allFields.removeWhere((field) =>
        field == 'lastSyncedAt' ||
        field == 'syncVersion' ||
        field == 'isDirty');

    for (final field in allFields) {
      final localValue = localData[field];
      final remoteValue = remoteData[field];

      // Skip identical values
      if (_valuesAreEqual(localValue, remoteValue)) {
        continue;
      }

      // Determine conflict type
      final conflictType =
          _determineConflictType(field, localValue, remoteValue);

      // Add field conflict
      fieldConflicts[field] = FieldConflictInfo(
        fieldName: field,
        conflictType: conflictType,
        localValue: localValue,
        remoteValue: remoteValue,
        confidenceScore:
            _calculateConfidenceScore(field, localValue, remoteValue),
        possibleResolutions:
            _getPossibleResolutions(field, localValue, remoteValue),
      );
    }

    if (fieldConflicts.isEmpty) {
      return null;
    }

    final conflict = EnhancedSyncConflict(
      conflictId:
          '${collection}_${entityId}_${DateTime.now().millisecondsSinceEpoch}',
      entityId: entityId,
      collection: collection,
      localData: Map.from(localData),
      remoteData: Map.from(remoteData),
      fieldConflicts: fieldConflicts,
      localVersion: localVersion,
      remoteVersion: remoteVersion,
      priority: SyncPriority.values[
          priority.index], // Convert EnhancedConflictPriority to SyncPriority
      detectedAt: DateTime.now(),
      tags: tags ?? [],
    );

    _conflictDetectedController.add(conflict);
    // Add method to record conflict detected
    _recordConflictDetected(conflict);

    return conflict;
  }

  // Add method to record conflict detected
  void _recordConflictDetected(EnhancedSyncConflict conflict) {
    // In a real implementation, this would save to conflict history
    // For now, just log to console
    print('Conflict detected: ${conflict.conflictId}');
  }

  /// Resolves a conflict using the appropriate resolver
  EnhancedSyncConflictResolution resolveConflict(
      EnhancedSyncConflict conflict) {
    final resolver = _resolvers[conflict.collection] ?? _defaultResolver;

    // Determine resolution approach based on settings and conflict
    if (_enableInteractiveResolution &&
        conflict.requiresManualIntervention &&
        _interactiveUIService != null) {
      return _resolveInteractively(conflict);
    } else if (_enableAIResolution && conflict.requiresManualIntervention) {
      return _resolveWithAI(conflict);
    } else {
      return _resolveAutomatically(conflict, resolver);
    }
  }

  EnhancedSyncConflictResolution _resolveAutomatically(
      EnhancedSyncConflict conflict, EnhancedConflictResolver resolver) {
    final resolution = resolver.resolveConflict(conflict);
    _recordResolution(conflict, resolution);
    return resolution;
  }

  EnhancedSyncConflictResolution _resolveInteractively(
      EnhancedSyncConflict conflict) {
    // Since this is a synchronous method but interactive resolution is
    // inherently asynchronous, we'd return a default resolution
    // and the UI would update it later through callbacks

    // In a real implementation, this would need to be redesigned as async
    // or use a callback pattern

    if (_interactiveUIService != null) {
      _interactiveUIService.prepareConflictForUI(conflict);
      // This would be handled asynchronously in a real app
    }

    // Default to automatic resolution while waiting for user input
    final resolution = _defaultResolver.resolveConflict(conflict);
    _recordResolution(conflict, resolution);
    return resolution;
  }

  EnhancedSyncConflictResolution _resolveWithAI(EnhancedSyncConflict conflict) {
    // This would integrate with an AI service in a real implementation
    // For now, fall back to automatic resolution
    final resolution = _defaultResolver.resolveConflict(conflict);
    _recordResolution(conflict, resolution);
    return resolution;
  }

  void _recordResolution(EnhancedSyncConflict conflict,
      EnhancedSyncConflictResolution resolution) {
    _conflictResolvedController.add(resolution);
    // Add method to record conflict resolution
    _recordConflictResolved(conflict, resolution);
  }

  // Add method to record conflict resolution
  void _recordConflictResolved(EnhancedSyncConflict conflict,
      EnhancedSyncConflictResolution resolution) {
    // In a real implementation, this would save to conflict history
    // For now, just log to console
    print('Conflict resolved: ${conflict.conflictId}');
  }

  bool _valuesAreEqual(dynamic value1, dynamic value2) {
    if (identical(value1, value2)) return true;
    if (value1 == null || value2 == null) return value1 == value2;

    // Handle special types like DateTime, lists, maps, etc.
    if (value1 is DateTime && value2 is DateTime) {
      return value1.isAtSameMomentAs(value2);
    }

    if (value1 is List && value2 is List) {
      if (value1.length != value2.length) return false;
      for (var i = 0; i < value1.length; i++) {
        if (!_valuesAreEqual(value1[i], value2[i])) return false;
      }
      return true;
    }

    if (value1 is Map && value2 is Map) {
      if (value1.length != value2.length) return false;
      for (var key in value1.keys) {
        if (!value2.containsKey(key) ||
            !_valuesAreEqual(value1[key], value2[key])) {
          return false;
        }
      }
      return true;
    }

    return value1 == value2;
  }

  EnhancedConflictType _determineConflictType(
      String fieldName, dynamic localValue, dynamic remoteValue) {
    // Type differences indicate structural conflict
    if (localValue != null &&
        remoteValue != null &&
        localValue.runtimeType != remoteValue.runtimeType) {
      return EnhancedConflictType.typeMismatch;
    }

    // Field present in one version but not the other
    if (localValue == null) {
      return EnhancedConflictType.remoteOnly;
    }

    if (remoteValue == null) {
      return EnhancedConflictType.localOnly;
    }

    // Check for reference conflicts (fields containing IDs)
    if (fieldName.toLowerCase().endsWith('id') &&
        fieldName.toLowerCase() != 'id') {
      return EnhancedConflictType.referenceConflict;
    }

    // Default to simple value conflict
    return EnhancedConflictType.valueDifference;
  }

  double _calculateConfidenceScore(
      String fieldName, dynamic localValue, dynamic remoteValue) {
    // Simple implementation - would be more sophisticated in real app
    // Lower scores indicate less confidence in automatic resolution

    if (localValue == null || remoteValue == null) {
      return 0.7; // Moderately confident when one side has a value
    }

    if (fieldName.toLowerCase().contains('id') ||
        fieldName.toLowerCase().contains('key')) {
      return 0.5; // Less confident with ID fields
    }

    if (localValue is Map || localValue is List) {
      return 0.6; // Complex types are harder to merge
    }

    return 0.9; // High confidence for simple value conflicts
  }

  List<String> _getPossibleResolutions(
      String fieldName, dynamic localValue, dynamic remoteValue) {
    final resolutions = <String>['useLocal', 'useRemote'];

    // Add merge options based on value types
    if (localValue is List && remoteValue is List) {
      resolutions.add('mergeLists');
    }

    if (localValue is Map && remoteValue is Map) {
      resolutions.add('mergeMaps');
    }

    if (localValue is String && remoteValue is String) {
      resolutions.add('concatenate');
    }

    if (localValue is num && remoteValue is num) {
      resolutions.add('useMax');
      resolutions.add('useMin');
      resolutions.add('useAverage');
    }

    return resolutions;
  }

  /// Disposes resources
  void dispose() {
    _conflictDetectedController.close();
    _conflictResolvedController.close();
  }
}

/// Simple implementation of the EnhancedConflictResolver
class _SimpleConflictResolver implements EnhancedConflictResolver {
  final EnhancedConflictResolutionStrategy defaultStrategy;

  _SimpleConflictResolver({
    EnhancedConflictResolutionStrategy? providedStrategy,
  }) : defaultStrategy =
            providedStrategy ?? EnhancedConflictResolutionStrategy.remoteWins;

  @override
  String get name => 'SimpleConflictResolver';

  @override
  int get priority => 0;

  @override
  bool canResolve(EnhancedSyncConflict conflict) => true;

  @override
  double getConfidenceScore(EnhancedSyncConflict conflict) => 0.8;

  @override
  EnhancedSyncConflict preprocessConflict(EnhancedSyncConflict conflict) =>
      conflict;

  @override
  EnhancedSyncConflictResolution postprocessResolution(
    EnhancedSyncConflictResolution resolution,
  ) =>
      resolution;

  @override
  EnhancedSyncConflictResolution resolveConflict(
      EnhancedSyncConflict conflict) {
    final resolvedData = <String, dynamic>{};
    final fieldResolutionStrategies = <String, String>{};
    final fieldsUsedFromLocal = <String>[];
    final fieldsUsedFromRemote = <String>[];

    // Start with a complete copy of data from one side based on strategy
    if (defaultStrategy == EnhancedConflictResolutionStrategy.localWins) {
      resolvedData.addAll(conflict.localData);
    } else {
      resolvedData.addAll(conflict.remoteData);
    }

    // Resolve each field conflict
    for (final entry in conflict.fieldConflicts.entries) {
      final fieldName = entry.key;
      final conflictInfo = entry.value;

      switch (defaultStrategy) {
        case EnhancedConflictResolutionStrategy.localWins:
          resolvedData[fieldName] = conflictInfo.localValue;
          fieldResolutionStrategies[fieldName] = 'useLocal';
          fieldsUsedFromLocal.add(fieldName);
          break;

        case EnhancedConflictResolutionStrategy.remoteWins:
          resolvedData[fieldName] = conflictInfo.remoteValue;
          fieldResolutionStrategies[fieldName] = 'useRemote';
          fieldsUsedFromRemote.add(fieldName);
          break;

        case EnhancedConflictResolutionStrategy.newestWins:
          // Assumes newer is better - would use timestamps in real implementation
          resolvedData[fieldName] = conflictInfo.remoteValue;
          fieldResolutionStrategies[fieldName] = 'useRemote';
          fieldsUsedFromRemote.add(fieldName);
          break;

        case EnhancedConflictResolutionStrategy.intelligentMerge:
          // Simplified smart merge - would be more sophisticated in real implementation
          final resolved = _smartMergeField(fieldName, conflictInfo);
          resolvedData[fieldName] = resolved.value;
          fieldResolutionStrategies[fieldName] = resolved.strategy;
          if (resolved.strategy == 'useLocal') {
            fieldsUsedFromLocal.add(fieldName);
          } else if (resolved.strategy == 'useRemote') {
            fieldsUsedFromRemote.add(fieldName);
          } else {
            // For merged fields, add to both lists
            fieldsUsedFromLocal.add(fieldName);
            fieldsUsedFromRemote.add(fieldName);
          }
          break;

        default:
          // Default to remote data for any other strategy
          resolvedData[fieldName] = conflictInfo.remoteValue;
          fieldResolutionStrategies[fieldName] = 'useRemote';
          fieldsUsedFromRemote.add(fieldName);
          break;
      }
    }

    final now = DateTime.now();
    return EnhancedSyncConflictResolution(
      conflictId: conflict.conflictId,
      resolvedData: resolvedData,
      strategy: defaultStrategy,
      fieldResolutionStrategies: fieldResolutionStrategies,
      fieldsUsedFromLocal: fieldsUsedFromLocal,
      fieldsUsedFromRemote: fieldsUsedFromRemote,
      resolvedAt: now,
      metadata: {
        'source': 'automatic',
        'resolver': 'SimpleConflictResolver',
      },
    );
  }

  _ResolvedField _smartMergeField(
      String fieldName, FieldConflictInfo conflictInfo) {
    // Handle nulls
    if (conflictInfo.localValue == null) {
      return _ResolvedField(conflictInfo.remoteValue, 'useRemote');
    }
    if (conflictInfo.remoteValue == null) {
      return _ResolvedField(conflictInfo.localValue, 'useLocal');
    }

    // Type-specific merging
    if (conflictInfo.localValue is List && conflictInfo.remoteValue is List) {
      final mergedList = <dynamic>[
        ...conflictInfo.localValue,
        ...conflictInfo.remoteValue
      ];
      return _ResolvedField(mergedList, 'mergeLists');
    }

    if (conflictInfo.localValue is Map && conflictInfo.remoteValue is Map) {
      final mergedMap = <String, dynamic>{};
      mergedMap.addAll(conflictInfo.localValue);
      mergedMap.addAll(conflictInfo.remoteValue);
      return _ResolvedField(mergedMap, 'mergeMaps');
    }

    if (conflictInfo.localValue is num && conflictInfo.remoteValue is num) {
      // For numeric fields, use the larger value
      if (conflictInfo.localValue > conflictInfo.remoteValue) {
        return _ResolvedField(conflictInfo.localValue, 'useMax');
      } else {
        return _ResolvedField(conflictInfo.remoteValue, 'useMax');
      }
    }

    // Default to remote for other types
    return _ResolvedField(conflictInfo.remoteValue, 'useRemote');
  }
}

/// Helper class for field resolution
class _ResolvedField {
  final dynamic value;
  final String strategy;

  _ResolvedField(this.value, this.strategy);
}
