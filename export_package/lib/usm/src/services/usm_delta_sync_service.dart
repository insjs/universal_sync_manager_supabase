/// Delta Sync Service for Universal Sync Manager
///
/// This service implements delta synchronization to minimize data transfer
/// by only sending/receiving changed fields and records. This is crucial
/// for performance optimization with large datasets.
library;

import 'dart:convert';

/// Service for handling delta synchronization operations
///
/// This service is responsible for:
/// - Calculating deltas between local and remote data
/// - Generating delta patches for efficient sync
/// - Applying delta patches to reconstruct data
/// - Managing delta metadata and checksums
class DeltaSyncService {
  /// Creates a new delta sync service instance
  const DeltaSyncService();

  /// Calculate delta between two data objects
  ///
  /// Returns a [DeltaPatch] containing only the changed fields and metadata
  /// needed to transform [oldData] into [newData].
  ///
  /// Example:
  /// ```dart
  /// final oldData = {'name': 'John', 'age': 30, 'city': 'New York'};
  /// final newData = {'name': 'John', 'age': 31, 'city': 'Boston'};
  /// final patch = service.calculateDelta(oldData, newData);
  /// // patch.changes will contain: {'age': 31, 'city': 'Boston'}
  /// ```
  DeltaPatch calculateDelta(
    Map<String, dynamic> oldData,
    Map<String, dynamic> newData, {
    String? entityId,
    String? entityType,
  }) {
    final changes = <String, dynamic>{};
    final deletions = <String>[];

    // Find changed and new fields
    for (final entry in newData.entries) {
      final key = entry.key;
      final newValue = entry.value;
      final oldValue = oldData[key];

      if (!_deepEquals(oldValue, newValue)) {
        changes[key] = newValue;
      }
    }

    // Find deleted fields
    for (final key in oldData.keys) {
      if (!newData.containsKey(key)) {
        deletions.add(key);
      }
    }

    return DeltaPatch(
      entityId: entityId,
      entityType: entityType,
      changes: changes,
      deletions: deletions,
      sourceChecksum: _calculateChecksum(oldData),
      targetChecksum: _calculateChecksum(newData),
      timestamp: DateTime.now(),
    );
  }

  /// Apply a delta patch to existing data
  ///
  /// Takes [baseData] and applies the [patch] to produce the updated data.
  /// Optionally validates checksums if [validateChecksum] is true.
  ///
  /// Throws [DeltaValidationException] if checksum validation fails.
  Map<String, dynamic> applyDelta(
    Map<String, dynamic> baseData,
    DeltaPatch patch, {
    bool validateChecksum = true,
  }) {
    if (validateChecksum && patch.sourceChecksum != null) {
      final baseChecksum = _calculateChecksum(baseData);
      if (baseChecksum != patch.sourceChecksum) {
        throw DeltaValidationException(
          'Source checksum mismatch. Expected: ${patch.sourceChecksum}, Got: $baseChecksum',
        );
      }
    }

    final result = Map<String, dynamic>.from(baseData);

    // Apply changes
    for (final entry in patch.changes.entries) {
      result[entry.key] = entry.value;
    }

    // Apply deletions
    for (final key in patch.deletions) {
      result.remove(key);
    }

    // Validate target checksum if provided
    if (validateChecksum && patch.targetChecksum != null) {
      final resultChecksum = _calculateChecksum(result);
      if (resultChecksum != patch.targetChecksum) {
        throw DeltaValidationException(
          'Target checksum mismatch. Expected: ${patch.targetChecksum}, Got: $resultChecksum',
        );
      }
    }

    return result;
  }

  /// Calculate delta for a collection of records
  ///
  /// Compares [oldRecords] with [newRecords] and returns a [CollectionDelta]
  /// containing all changes needed to transform the old collection to the new one.
  CollectionDelta calculateCollectionDelta(
    List<Map<String, dynamic>> oldRecords,
    List<Map<String, dynamic>> newRecords, {
    String idField = 'id',
    String? collectionName,
  }) {
    final oldMap = <String, Map<String, dynamic>>{};
    final newMap = <String, Map<String, dynamic>>{};

    // Build maps for efficient lookup
    for (final record in oldRecords) {
      final id = record[idField]?.toString();
      if (id != null) {
        oldMap[id] = record;
      }
    }

    for (final record in newRecords) {
      final id = record[idField]?.toString();
      if (id != null) {
        newMap[id] = record;
      }
    }

    final patches = <DeltaPatch>[];
    final deletedIds = <String>[];
    final addedRecords = <Map<String, dynamic>>[];

    // Find changes and updates
    for (final entry in newMap.entries) {
      final id = entry.key;
      final newRecord = entry.value;
      final oldRecord = oldMap[id];

      if (oldRecord != null) {
        // Record exists in both - check for changes
        final patch = calculateDelta(
          oldRecord,
          newRecord,
          entityId: id,
          entityType: collectionName,
        );
        if (patch.hasChanges) {
          patches.add(patch);
        }
      } else {
        // New record
        addedRecords.add(newRecord);
      }
    }

    // Find deletions
    for (final id in oldMap.keys) {
      if (!newMap.containsKey(id)) {
        deletedIds.add(id);
      }
    }

    return CollectionDelta(
      collectionName: collectionName,
      patches: patches,
      addedRecords: addedRecords,
      deletedIds: deletedIds,
      timestamp: DateTime.now(),
    );
  }

  /// Apply a collection delta to existing records
  ///
  /// Takes [baseRecords] and applies the [delta] to produce the updated collection.
  List<Map<String, dynamic>> applyCollectionDelta(
    List<Map<String, dynamic>> baseRecords,
    CollectionDelta delta, {
    String idField = 'id',
    bool validateChecksums = true,
  }) {
    final recordMap = <String, Map<String, dynamic>>{};

    // Build map from base records
    for (final record in baseRecords) {
      final id = record[idField]?.toString();
      if (id != null) {
        recordMap[id] = Map<String, dynamic>.from(record);
      }
    }

    // Apply patches
    for (final patch in delta.patches) {
      if (patch.entityId != null && recordMap.containsKey(patch.entityId)) {
        recordMap[patch.entityId!] = applyDelta(
          recordMap[patch.entityId!]!,
          patch,
          validateChecksum: validateChecksums,
        );
      }
    }

    // Remove deleted records
    for (final deletedId in delta.deletedIds) {
      recordMap.remove(deletedId);
    }

    // Add new records
    for (final newRecord in delta.addedRecords) {
      final id = newRecord[idField]?.toString();
      if (id != null) {
        recordMap[id] = Map<String, dynamic>.from(newRecord);
      }
    }

    return recordMap.values.toList();
  }

  /// Calculate checksum for data integrity verification
  String _calculateChecksum(Map<String, dynamic> data) {
    final jsonString = jsonEncode(_sortMapRecursively(data));
    final bytes = utf8.encode(jsonString);

    // Simple hash calculation (in production, consider using crypto package)
    var hash = 0;
    for (final byte in bytes) {
      hash = ((hash << 5) - hash + byte) & 0xFFFFFFFF;
    }

    return hash.toRadixString(16);
  }

  /// Sort map keys recursively for consistent serialization
  Map<String, dynamic> _sortMapRecursively(Map<String, dynamic> map) {
    final sortedMap = <String, dynamic>{};
    final sortedKeys = map.keys.toList()..sort();

    for (final key in sortedKeys) {
      final value = map[key];
      if (value is Map<String, dynamic>) {
        sortedMap[key] = _sortMapRecursively(value);
      } else if (value is List) {
        sortedMap[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _sortMapRecursively(item);
          }
          return item;
        }).toList();
      } else {
        sortedMap[key] = value;
      }
    }

    return sortedMap;
  }

  /// Deep equality check for complex objects
  bool _deepEquals(dynamic a, dynamic b) {
    if (identical(a, b)) return true;
    if (a.runtimeType != b.runtimeType) return false;

    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) {
          return false;
        }
      }
      return true;
    }

    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    }

    return a == b;
  }
}

/// Represents a delta patch for a single entity
class DeltaPatch {
  /// ID of the entity this patch applies to
  final String? entityId;

  /// Type/collection name of the entity
  final String? entityType;

  /// Map of changed fields and their new values
  final Map<String, dynamic> changes;

  /// List of fields that were deleted
  final List<String> deletions;

  /// Checksum of the source data (for validation)
  final String? sourceChecksum;

  /// Checksum of the target data (for validation)
  final String? targetChecksum;

  /// Timestamp when this patch was created
  final DateTime timestamp;

  /// Creates a new delta patch
  const DeltaPatch({
    this.entityId,
    this.entityType,
    required this.changes,
    required this.deletions,
    this.sourceChecksum,
    this.targetChecksum,
    required this.timestamp,
  });

  /// Whether this patch contains any changes
  bool get hasChanges => changes.isNotEmpty || deletions.isNotEmpty;

  /// Size estimate of this patch in bytes
  int get estimatedSize {
    final changesSize = jsonEncode(changes).length;
    final deletionsSize = jsonEncode(deletions).length;
    return changesSize + deletionsSize;
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'entityId': entityId,
      'entityType': entityType,
      'changes': changes,
      'deletions': deletions,
      'sourceChecksum': sourceChecksum,
      'targetChecksum': targetChecksum,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON
  factory DeltaPatch.fromJson(Map<String, dynamic> json) {
    return DeltaPatch(
      entityId: json['entityId'] as String?,
      entityType: json['entityType'] as String?,
      changes: Map<String, dynamic>.from(json['changes'] as Map),
      deletions: List<String>.from(json['deletions'] as List),
      sourceChecksum: json['sourceChecksum'] as String?,
      targetChecksum: json['targetChecksum'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() {
    return 'DeltaPatch(entityId: $entityId, changes: ${changes.length}, deletions: ${deletions.length})';
  }
}

/// Represents a delta for an entire collection
class CollectionDelta {
  /// Name of the collection
  final String? collectionName;

  /// List of patches for updated records
  final List<DeltaPatch> patches;

  /// List of newly added records
  final List<Map<String, dynamic>> addedRecords;

  /// List of IDs for deleted records
  final List<String> deletedIds;

  /// Timestamp when this delta was created
  final DateTime timestamp;

  /// Creates a new collection delta
  const CollectionDelta({
    this.collectionName,
    required this.patches,
    required this.addedRecords,
    required this.deletedIds,
    required this.timestamp,
  });

  /// Whether this delta contains any changes
  bool get hasChanges =>
      patches.isNotEmpty || addedRecords.isNotEmpty || deletedIds.isNotEmpty;

  /// Total number of affected records
  int get affectedRecordCount =>
      patches.length + addedRecords.length + deletedIds.length;

  /// Estimated size of this delta in bytes
  int get estimatedSize {
    var size = 0;

    // Size of patches
    for (final patch in patches) {
      size += patch.estimatedSize;
    }

    // Size of added records
    size += jsonEncode(addedRecords).length;

    // Size of deleted IDs
    size += jsonEncode(deletedIds).length;

    return size;
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'collectionName': collectionName,
      'patches': patches.map((p) => p.toJson()).toList(),
      'addedRecords': addedRecords,
      'deletedIds': deletedIds,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON
  factory CollectionDelta.fromJson(Map<String, dynamic> json) {
    return CollectionDelta(
      collectionName: json['collectionName'] as String?,
      patches: (json['patches'] as List)
          .map((p) => DeltaPatch.fromJson(p as Map<String, dynamic>))
          .toList(),
      addedRecords: List<Map<String, dynamic>>.from(
        (json['addedRecords'] as List)
            .map((r) => Map<String, dynamic>.from(r as Map)),
      ),
      deletedIds: List<String>.from(json['deletedIds'] as List),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() {
    return 'CollectionDelta(collection: $collectionName, patches: ${patches.length}, '
        'added: ${addedRecords.length}, deleted: ${deletedIds.length})';
  }
}

/// Exception thrown when delta validation fails
class DeltaValidationException implements Exception {
  /// The error message
  final String message;

  /// Creates a new delta validation exception
  const DeltaValidationException(this.message);

  @override
  String toString() => 'DeltaValidationException: $message';
}
