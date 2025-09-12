// test/conflict_simulation/conflict_simulator.dart

import 'dart:math';

/// Types of conflicts that can occur during sync
enum ConflictType {
  updateUpdate, // Two parties update same field
  updateDelete, // One updates, another deletes
  deleteUpdate, // One deletes, another updates
  createCreate, // Same entity created twice
  timestampSkew, // Timestamp-based conflicts
  versionMismatch, // Version number conflicts
  fieldLevel, // Conflicts in specific fields
  structural, // Schema/structure conflicts
}

/// Conflict resolution strategies
enum ConflictResolutionStrategy {
  clientWins, // Local changes take precedence
  serverWins, // Remote/server changes take precedence
  timestampWins, // Most recent timestamp wins
  versionWins, // Highest version wins
  merge, // Attempt to merge changes
  manual, // Require manual resolution
  custom, // Custom resolution logic
}

/// Represents a conflict between two versions of data
class SyncConflict {
  final String id;
  final String entityId;
  final String collection;
  final ConflictType type;
  final Map<String, dynamic> localVersion;
  final Map<String, dynamic> remoteVersion;
  final Map<String, dynamic> baseVersion;
  final DateTime detectedAt;
  final Map<String, dynamic> metadata;
  final List<String> conflictingFields;

  const SyncConflict({
    required this.id,
    required this.entityId,
    required this.collection,
    required this.type,
    required this.localVersion,
    required this.remoteVersion,
    required this.baseVersion,
    required this.detectedAt,
    this.metadata = const {},
    this.conflictingFields = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'entityId': entityId,
        'collection': collection,
        'type': type.name,
        'localVersion': localVersion,
        'remoteVersion': remoteVersion,
        'baseVersion': baseVersion,
        'detectedAt': detectedAt.toIso8601String(),
        'metadata': metadata,
        'conflictingFields': conflictingFields,
      };

  /// Checks if conflict affects specific field
  bool affectsField(String fieldName) {
    return conflictingFields.contains(fieldName) ||
        conflictingFields.isEmpty; // Empty means all fields affected
  }

  /// Gets severity of conflict based on type
  int get severity {
    switch (type) {
      case ConflictType.deleteUpdate:
      case ConflictType.updateDelete:
        return 10; // Highest severity
      case ConflictType.structural:
        return 9;
      case ConflictType.createCreate:
        return 8;
      case ConflictType.updateUpdate:
        return 6;
      case ConflictType.versionMismatch:
        return 5;
      case ConflictType.timestampSkew:
        return 4;
      case ConflictType.fieldLevel:
        return 3; // Lowest severity
    }
  }
}

/// Result of conflict resolution
class ConflictResolution {
  final String conflictId;
  final ConflictResolutionStrategy strategy;
  final Map<String, dynamic> resolvedData;
  final bool successful;
  final String? errorMessage;
  final DateTime resolvedAt;
  final Map<String, dynamic> resolutionMetadata;

  const ConflictResolution({
    required this.conflictId,
    required this.strategy,
    required this.resolvedData,
    required this.successful,
    this.errorMessage,
    required this.resolvedAt,
    this.resolutionMetadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'conflictId': conflictId,
        'strategy': strategy.name,
        'resolvedData': resolvedData,
        'successful': successful,
        'errorMessage': errorMessage,
        'resolvedAt': resolvedAt.toIso8601String(),
        'resolutionMetadata': resolutionMetadata,
      };
}

/// Configuration for conflict simulation
class ConflictSimulationConfig {
  final List<ConflictType> enabledConflictTypes;
  final double conflictProbability;
  final ConflictResolutionStrategy defaultResolutionStrategy;
  final Map<ConflictType, double> conflictTypeWeights;
  final bool enableTimestampSkew;
  final Duration maxTimestampSkew;
  final bool enableVersionConflicts;
  final Map<String, dynamic> customParameters;

  const ConflictSimulationConfig({
    this.enabledConflictTypes = ConflictType.values,
    this.conflictProbability = 0.2,
    this.defaultResolutionStrategy = ConflictResolutionStrategy.timestampWins,
    this.conflictTypeWeights = const {
      ConflictType.updateUpdate: 0.4,
      ConflictType.updateDelete: 0.15,
      ConflictType.deleteUpdate: 0.15,
      ConflictType.createCreate: 0.1,
      ConflictType.timestampSkew: 0.1,
      ConflictType.versionMismatch: 0.05,
      ConflictType.fieldLevel: 0.03,
      ConflictType.structural: 0.02,
    },
    this.enableTimestampSkew = true,
    this.maxTimestampSkew = const Duration(minutes: 5),
    this.enableVersionConflicts = true,
    this.customParameters = const {},
  });
}

/// Simulates various types of sync conflicts for testing
class ConflictSimulator {
  final Random _random = Random();
  final ConflictSimulationConfig _config;
  final List<SyncConflict> _simulatedConflicts = [];
  final List<ConflictResolution> _resolutions = [];

  ConflictSimulator([this._config = const ConflictSimulationConfig()]);

  /// Simulates a conflict for given data
  SyncConflict? simulateConflict(
    String entityId,
    String collection,
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
    Map<String, dynamic> baseData,
  ) {
    if (_random.nextDouble() > _config.conflictProbability) {
      return null; // No conflict this time
    }

    final conflictType = _selectConflictType();
    final conflict = _createConflict(
      entityId,
      collection,
      conflictType,
      localData,
      remoteData,
      baseData,
    );

    _simulatedConflicts.add(conflict);
    return conflict;
  }

  /// Simulates multiple conflicts for batch operations
  List<SyncConflict> simulateBatchConflicts(
    List<Map<String, dynamic>> operations,
  ) {
    final conflicts = <SyncConflict>[];

    for (final operation in operations) {
      final entityId = operation['entityId'] as String? ?? _generateEntityId();
      final collection = operation['collection'] as String? ?? 'default';
      final localData = Map<String, dynamic>.from(operation['localData'] ?? {});
      final remoteData =
          Map<String, dynamic>.from(operation['remoteData'] ?? {});
      final baseData = Map<String, dynamic>.from(operation['baseData'] ?? {});

      final conflict = simulateConflict(
        entityId,
        collection,
        localData,
        remoteData,
        baseData,
      );

      if (conflict != null) {
        conflicts.add(conflict);
      }
    }

    return conflicts;
  }

  /// Simulates specific type of conflict
  SyncConflict simulateSpecificConflict(
    ConflictType type,
    String entityId,
    String collection,
    Map<String, dynamic> baseData,
  ) {
    final localData = Map<String, dynamic>.from(baseData);
    final remoteData = Map<String, dynamic>.from(baseData);

    switch (type) {
      case ConflictType.updateUpdate:
        _simulateUpdateUpdateConflict(localData, remoteData);
        break;
      case ConflictType.updateDelete:
        _simulateUpdateDeleteConflict(localData, remoteData);
        break;
      case ConflictType.deleteUpdate:
        _simulateDeleteUpdateConflict(localData, remoteData);
        break;
      case ConflictType.createCreate:
        _simulateCreateCreateConflict(localData, remoteData);
        break;
      case ConflictType.timestampSkew:
        _simulateTimestampSkewConflict(localData, remoteData);
        break;
      case ConflictType.versionMismatch:
        _simulateVersionMismatchConflict(localData, remoteData);
        break;
      case ConflictType.fieldLevel:
        _simulateFieldLevelConflict(localData, remoteData);
        break;
      case ConflictType.structural:
        _simulateStructuralConflict(localData, remoteData);
        break;
    }

    final conflict = _createConflict(
      entityId,
      collection,
      type,
      localData,
      remoteData,
      baseData,
    );

    _simulatedConflicts.add(conflict);
    return conflict;
  }

  /// Resolves a conflict using specified strategy
  ConflictResolution resolveConflict(
    SyncConflict conflict,
    ConflictResolutionStrategy strategy,
  ) {
    try {
      final resolvedData = _performResolution(conflict, strategy);

      final resolution = ConflictResolution(
        conflictId: conflict.id,
        strategy: strategy,
        resolvedData: resolvedData,
        successful: true,
        resolvedAt: DateTime.now(),
        resolutionMetadata: {
          'conflictType': conflict.type.name,
          'conflictingFields': conflict.conflictingFields,
          'resolutionComplexity':
              _calculateResolutionComplexity(conflict, strategy),
        },
      );

      _resolutions.add(resolution);
      return resolution;
    } catch (e) {
      final resolution = ConflictResolution(
        conflictId: conflict.id,
        strategy: strategy,
        resolvedData: {},
        successful: false,
        errorMessage: e.toString(),
        resolvedAt: DateTime.now(),
        resolutionMetadata: {
          'error': 'resolution_failed',
          'conflictType': conflict.type.name,
        },
      );

      _resolutions.add(resolution);
      return resolution;
    }
  }

  /// Resolves all pending conflicts
  List<ConflictResolution> resolveAllConflicts([
    ConflictResolutionStrategy? strategy,
  ]) {
    final resolutionStrategy = strategy ?? _config.defaultResolutionStrategy;
    final resolutions = <ConflictResolution>[];

    for (final conflict in _simulatedConflicts) {
      // Skip if already resolved
      if (_resolutions.any((r) => r.conflictId == conflict.id)) {
        continue;
      }

      resolutions.add(resolveConflict(conflict, resolutionStrategy));
    }

    return resolutions;
  }

  /// Gets all simulated conflicts
  List<SyncConflict> get conflicts => List.unmodifiable(_simulatedConflicts);

  /// Gets all resolutions
  List<ConflictResolution> get resolutions => List.unmodifiable(_resolutions);

  /// Gets unresolved conflicts
  List<SyncConflict> get unresolvedConflicts {
    final resolvedIds = _resolutions
        .where((r) => r.successful)
        .map((r) => r.conflictId)
        .toSet();

    return _simulatedConflicts
        .where((c) => !resolvedIds.contains(c.id))
        .toList();
  }

  /// Gets conflict statistics
  Map<String, dynamic> getConflictStatistics() {
    final stats = <String, dynamic>{
      'totalConflicts': _simulatedConflicts.length,
      'resolvedConflicts': _resolutions.where((r) => r.successful).length,
      'failedResolutions': _resolutions.where((r) => !r.successful).length,
      'unresolvedConflicts': unresolvedConflicts.length,
      'conflictsByType': <String, int>{},
      'resolutionsByStrategy': <String, int>{},
      'averageResolutionTime': 0.0,
    };

    // Count conflicts by type
    for (final conflict in _simulatedConflicts) {
      final typeName = conflict.type.name;
      stats['conflictsByType'][typeName] =
          (stats['conflictsByType'][typeName] ?? 0) + 1;
    }

    // Count resolutions by strategy
    for (final resolution in _resolutions) {
      final strategyName = resolution.strategy.name;
      stats['resolutionsByStrategy'][strategyName] =
          (stats['resolutionsByStrategy'][strategyName] ?? 0) + 1;
    }

    return stats;
  }

  /// Clears all simulated data
  void reset() {
    _simulatedConflicts.clear();
    _resolutions.clear();
  }

  // Private helper methods

  ConflictType _selectConflictType() {
    if (_config.conflictTypeWeights.isEmpty) {
      return _config.enabledConflictTypes[
          _random.nextInt(_config.enabledConflictTypes.length)];
    }

    final totalWeight = _config.conflictTypeWeights.values
        .fold(0.0, (sum, weight) => sum + weight);
    var randomValue = _random.nextDouble() * totalWeight;

    for (final entry in _config.conflictTypeWeights.entries) {
      if (_config.enabledConflictTypes.contains(entry.key)) {
        randomValue -= entry.value;
        if (randomValue <= 0) {
          return entry.key;
        }
      }
    }

    return _config.enabledConflictTypes.first;
  }

  SyncConflict _createConflict(
    String entityId,
    String collection,
    ConflictType type,
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
    Map<String, dynamic> baseData,
  ) {
    final conflictingFields = _identifyConflictingFields(localData, remoteData);

    return SyncConflict(
      id: 'conflict_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
      entityId: entityId,
      collection: collection,
      type: type,
      localVersion: localData,
      remoteVersion: remoteData,
      baseVersion: baseData,
      detectedAt: DateTime.now(),
      conflictingFields: conflictingFields,
      metadata: {
        'simulated': true,
        'severity': _getConflictSeverity(type),
        'autoResolvable': _isAutoResolvable(type),
      },
    );
  }

  void _simulateUpdateUpdateConflict(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    // Both versions update the same field with different values
    final field = 'name';
    localData[field] = 'Local Update ${_random.nextInt(100)}';
    remoteData[field] = 'Remote Update ${_random.nextInt(100)}';

    // Add timestamps to show conflict
    localData['lastModified'] = DateTime.now().millisecondsSinceEpoch - 1000;
    remoteData['lastModified'] = DateTime.now().millisecondsSinceEpoch - 500;
  }

  void _simulateUpdateDeleteConflict(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    // Local updates, remote deletes
    localData['status'] = 'updated';
    localData['lastModified'] = DateTime.now().millisecondsSinceEpoch;
    remoteData.clear();
    remoteData['_deleted'] = true;
    remoteData['deletedAt'] = DateTime.now().millisecondsSinceEpoch - 500;
  }

  void _simulateDeleteUpdateConflict(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    // Local deletes, remote updates
    localData.clear();
    localData['_deleted'] = true;
    localData['deletedAt'] = DateTime.now().millisecondsSinceEpoch;
    remoteData['status'] = 'updated';
    remoteData['lastModified'] = DateTime.now().millisecondsSinceEpoch - 500;
  }

  void _simulateCreateCreateConflict(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    // Same entity created with different data
    localData['createdBy'] = 'local_client';
    localData['createdAt'] = DateTime.now().millisecondsSinceEpoch;
    remoteData['createdBy'] = 'remote_client';
    remoteData['createdAt'] = DateTime.now().millisecondsSinceEpoch - 100;
  }

  void _simulateTimestampSkewConflict(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    // Timestamp differences that could cause conflicts
    final skewMs = _random.nextInt(_config.maxTimestampSkew.inMilliseconds);
    localData['timestamp'] = DateTime.now().millisecondsSinceEpoch;
    remoteData['timestamp'] = DateTime.now().millisecondsSinceEpoch + skewMs;
  }

  void _simulateVersionMismatchConflict(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    // Version number conflicts
    localData['version'] = 5;
    remoteData['version'] = 4; // Older version with newer timestamp
    remoteData['lastModified'] = DateTime.now().millisecondsSinceEpoch;
    localData['lastModified'] = DateTime.now().millisecondsSinceEpoch - 1000;
  }

  void _simulateFieldLevelConflict(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    // Conflicts in specific fields only
    localData['field1'] = 'local_value';
    remoteData['field1'] = 'remote_value';
    // field2 is same in both
    localData['field2'] = 'same_value';
    remoteData['field2'] = 'same_value';
  }

  void _simulateStructuralConflict(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    // Schema differences
    localData['newField'] = 'only_in_local';
    remoteData['differentField'] = 'only_in_remote';
    // Type conflicts
    localData['mixedField'] = 123;
    remoteData['mixedField'] = 'string_value';
  }

  List<String> _identifyConflictingFields(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    final conflictingFields = <String>[];
    final allKeys = {...localData.keys, ...remoteData.keys};

    for (final key in allKeys) {
      final localValue = localData[key];
      final remoteValue = remoteData[key];

      if (localValue != remoteValue) {
        conflictingFields.add(key);
      }
    }

    return conflictingFields;
  }

  Map<String, dynamic> _performResolution(
    SyncConflict conflict,
    ConflictResolutionStrategy strategy,
  ) {
    switch (strategy) {
      case ConflictResolutionStrategy.clientWins:
        return Map<String, dynamic>.from(conflict.localVersion);

      case ConflictResolutionStrategy.serverWins:
        return Map<String, dynamic>.from(conflict.remoteVersion);

      case ConflictResolutionStrategy.timestampWins:
        return _resolveByTimestamp(conflict);

      case ConflictResolutionStrategy.versionWins:
        return _resolveByVersion(conflict);

      case ConflictResolutionStrategy.merge:
        return _performMerge(conflict);

      case ConflictResolutionStrategy.manual:
        throw Exception('Manual resolution required');

      case ConflictResolutionStrategy.custom:
        return _performCustomResolution(conflict);
    }
  }

  Map<String, dynamic> _resolveByTimestamp(SyncConflict conflict) {
    final localTimestamp = conflict.localVersion['lastModified'] as int? ?? 0;
    final remoteTimestamp = conflict.remoteVersion['lastModified'] as int? ?? 0;

    return localTimestamp > remoteTimestamp
        ? Map<String, dynamic>.from(conflict.localVersion)
        : Map<String, dynamic>.from(conflict.remoteVersion);
  }

  Map<String, dynamic> _resolveByVersion(SyncConflict conflict) {
    final localVersion = conflict.localVersion['version'] as int? ?? 0;
    final remoteVersion = conflict.remoteVersion['version'] as int? ?? 0;

    return localVersion > remoteVersion
        ? Map<String, dynamic>.from(conflict.localVersion)
        : Map<String, dynamic>.from(conflict.remoteVersion);
  }

  Map<String, dynamic> _performMerge(SyncConflict conflict) {
    final merged = Map<String, dynamic>.from(conflict.baseVersion);

    // Merge non-conflicting fields from both versions
    for (final entry in conflict.localVersion.entries) {
      if (!conflict.conflictingFields.contains(entry.key)) {
        merged[entry.key] = entry.value;
      }
    }

    for (final entry in conflict.remoteVersion.entries) {
      if (!conflict.conflictingFields.contains(entry.key)) {
        merged[entry.key] = entry.value;
      }
    }

    // For conflicting fields, use timestamp resolution
    for (final field in conflict.conflictingFields) {
      final localTimestamp = conflict.localVersion['lastModified'] as int? ?? 0;
      final remoteTimestamp =
          conflict.remoteVersion['lastModified'] as int? ?? 0;

      if (localTimestamp > remoteTimestamp) {
        merged[field] = conflict.localVersion[field];
      } else {
        merged[field] = conflict.remoteVersion[field];
      }
    }

    return merged;
  }

  Map<String, dynamic> _performCustomResolution(SyncConflict conflict) {
    // Custom resolution logic can be implemented here
    // For now, fall back to merge strategy
    return _performMerge(conflict);
  }

  int _getConflictSeverity(ConflictType type) {
    switch (type) {
      case ConflictType.deleteUpdate:
      case ConflictType.updateDelete:
        return 10;
      case ConflictType.structural:
        return 9;
      case ConflictType.createCreate:
        return 8;
      case ConflictType.updateUpdate:
        return 6;
      case ConflictType.versionMismatch:
        return 5;
      case ConflictType.timestampSkew:
        return 4;
      case ConflictType.fieldLevel:
        return 3;
    }
  }

  bool _isAutoResolvable(ConflictType type) {
    switch (type) {
      case ConflictType.timestampSkew:
      case ConflictType.versionMismatch:
      case ConflictType.fieldLevel:
        return true;
      case ConflictType.updateUpdate:
        return true; // With timestamp resolution
      default:
        return false;
    }
  }

  int _calculateResolutionComplexity(
    SyncConflict conflict,
    ConflictResolutionStrategy strategy,
  ) {
    var complexity = conflict.severity;

    switch (strategy) {
      case ConflictResolutionStrategy.merge:
        complexity += 3;
        break;
      case ConflictResolutionStrategy.custom:
        complexity += 5;
        break;
      default:
        complexity += 1;
    }

    return complexity + conflict.conflictingFields.length;
  }

  String _generateEntityId() {
    return 'entity_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}';
  }

  /// Additional methods required by E2E tests
  bool _conflictDetectionEnabled = false;

  void enableConflictDetection(bool enabled) {
    _conflictDetectionEnabled = enabled;
  }

  Future<List<SyncConflict>> detectConflicts(
    String collection,
    String entityId,
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) async {
    if (!_conflictDetectionEnabled) return [];

    final conflicts = <SyncConflict>[];

    // Check for field-level conflicts
    final conflictingFields = <String>[];
    for (final key in localData.keys) {
      if (remoteData.containsKey(key) && localData[key] != remoteData[key]) {
        conflictingFields.add(key);
      }
    }

    if (conflictingFields.isNotEmpty) {
      final conflict = SyncConflict(
        id: 'conflict_${DateTime.now().millisecondsSinceEpoch}',
        entityId: entityId,
        collection: collection,
        type: ConflictType.updateUpdate,
        localVersion: localData,
        remoteVersion: remoteData,
        baseVersion: {},
        detectedAt: DateTime.now(),
        conflictingFields: conflictingFields,
      );
      conflicts.add(conflict);
      _simulatedConflicts.add(conflict);
    }

    return conflicts;
  }
}
