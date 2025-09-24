// lib/src/services/usm_conflict_history_service.dart

import 'dart:async';

import '../config/usm_sync_enums.dart';
import 'usm_enhanced_conflict_resolver.dart';

/// Conflict history entry for tracking resolution decisions
class ConflictHistoryEntry {
  final String id;
  final String conflictId;
  final String entityId;
  final String collection;
  final DateTime occurredAt;
  final DateTime? resolvedAt;
  final EnhancedConflictResolutionStrategy strategy;
  final String? resolvedBy;
  final Map<String, dynamic> originalLocalData;
  final Map<String, dynamic> originalRemoteData;
  final Map<String, dynamic> resolvedData;
  final Map<String, FieldConflictInfo> fieldConflicts;
  final double confidenceScore;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final String? notes;
  final bool wasManuallyResolved;

  const ConflictHistoryEntry({
    required this.id,
    required this.conflictId,
    required this.entityId,
    required this.collection,
    required this.occurredAt,
    this.resolvedAt,
    required this.strategy,
    this.resolvedBy,
    required this.originalLocalData,
    required this.originalRemoteData,
    required this.resolvedData,
    required this.fieldConflicts,
    this.confidenceScore = 1.0,
    this.tags = const [],
    this.metadata = const {},
    this.notes,
    this.wasManuallyResolved = false,
  });

  factory ConflictHistoryEntry.fromConflictAndResolution(
    EnhancedSyncConflict conflict,
    EnhancedSyncConflictResolution resolution,
  ) {
    return ConflictHistoryEntry(
      id: 'history_${DateTime.now().millisecondsSinceEpoch}',
      conflictId: conflict.conflictId,
      entityId: conflict.entityId,
      collection: conflict.collection,
      occurredAt: conflict.detectedAt,
      resolvedAt: resolution.resolvedAt,
      strategy: resolution.strategy,
      resolvedBy: resolution.resolvedBy,
      originalLocalData: Map.from(conflict.localData),
      originalRemoteData: Map.from(conflict.remoteData),
      resolvedData: Map.from(resolution.resolvedData),
      fieldConflicts: Map.from(conflict.fieldConflicts),
      confidenceScore: resolution.confidenceScore,
      tags: List.from(conflict.tags),
      metadata: Map.from(resolution.metadata),
      wasManuallyResolved: resolution.requiresUserIntervention,
    );
  }

  /// Creates a copy with updated notes
  ConflictHistoryEntry withNotes(String notes) {
    return ConflictHistoryEntry(
      id: id,
      conflictId: conflictId,
      entityId: entityId,
      collection: collection,
      occurredAt: occurredAt,
      resolvedAt: resolvedAt,
      strategy: strategy,
      resolvedBy: resolvedBy,
      originalLocalData: originalLocalData,
      originalRemoteData: originalRemoteData,
      resolvedData: resolvedData,
      fieldConflicts: fieldConflicts,
      confidenceScore: confidenceScore,
      tags: tags,
      metadata: metadata,
      notes: notes,
      wasManuallyResolved: wasManuallyResolved,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conflictId': conflictId,
        'entityId': entityId,
        'collection': collection,
        'occurredAt': occurredAt.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
        'strategy': strategy.name,
        'resolvedBy': resolvedBy,
        'originalLocalData': originalLocalData,
        'originalRemoteData': originalRemoteData,
        'resolvedData': resolvedData,
        'fieldConflicts': fieldConflicts.map((k, v) => MapEntry(k, v.toJson())),
        'confidenceScore': confidenceScore,
        'tags': tags,
        'metadata': metadata,
        'notes': notes,
        'wasManuallyResolved': wasManuallyResolved,
      };

  factory ConflictHistoryEntry.fromJson(Map<String, dynamic> json) {
    final fieldConflictsMap = <String, FieldConflictInfo>{};
    final fieldConflictsJson =
        json['fieldConflicts'] as Map<String, dynamic>? ?? {};

    for (final entry in fieldConflictsJson.entries) {
      fieldConflictsMap[entry.key] = FieldConflictInfo.fromJson(entry.value);
    }

    return ConflictHistoryEntry(
      id: json['id'],
      conflictId: json['conflictId'],
      entityId: json['entityId'],
      collection: json['collection'],
      occurredAt: DateTime.parse(json['occurredAt']),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'])
          : null,
      strategy: EnhancedConflictResolutionStrategy.values.firstWhere(
        (s) => s.name == json['strategy'],
      ),
      resolvedBy: json['resolvedBy'],
      originalLocalData: Map<String, dynamic>.from(json['originalLocalData']),
      originalRemoteData: Map<String, dynamic>.from(json['originalRemoteData']),
      resolvedData: Map<String, dynamic>.from(json['resolvedData']),
      fieldConflicts: fieldConflictsMap,
      confidenceScore: (json['confidenceScore'] ?? 1.0).toDouble(),
      tags: List<String>.from(json['tags'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      notes: json['notes'],
      wasManuallyResolved: json['wasManuallyResolved'] ?? false,
    );
  }
}

/// Statistics about conflict resolution patterns
class ConflictResolutionStats {
  final int totalConflicts;
  final int resolvedConflicts;
  final int pendingConflicts;
  final Map<EnhancedConflictResolutionStrategy, int> strategyUsage;
  final Map<String, int> collectionConflicts;
  final Map<EnhancedConflictType, int> conflictTypeFrequency;
  final double averageConfidenceScore;
  final double manualResolutionRate;
  final Duration averageResolutionTime;
  final Map<String, int> topConflictedFields;

  const ConflictResolutionStats({
    required this.totalConflicts,
    required this.resolvedConflicts,
    required this.pendingConflicts,
    required this.strategyUsage,
    required this.collectionConflicts,
    required this.conflictTypeFrequency,
    required this.averageConfidenceScore,
    required this.manualResolutionRate,
    required this.averageResolutionTime,
    required this.topConflictedFields,
  });

  Map<String, dynamic> toJson() => {
        'totalConflicts': totalConflicts,
        'resolvedConflicts': resolvedConflicts,
        'pendingConflicts': pendingConflicts,
        'strategyUsage': strategyUsage.map((k, v) => MapEntry(k.name, v)),
        'collectionConflicts': collectionConflicts,
        'conflictTypeFrequency':
            conflictTypeFrequency.map((k, v) => MapEntry(k.name, v)),
        'averageConfidenceScore': averageConfidenceScore,
        'manualResolutionRate': manualResolutionRate,
        'averageResolutionTimeMs': averageResolutionTime.inMilliseconds,
        'topConflictedFields': topConflictedFields,
      };
}

/// Service for tracking and analyzing conflict resolution history
class ConflictHistoryService {
  final List<ConflictHistoryEntry> _history = [];
  final Map<String, List<ConflictHistoryEntry>> _entityHistory = {};
  final Map<String, List<ConflictHistoryEntry>> _collectionHistory = {};

  final StreamController<ConflictHistoryEntry> _historyAddedController =
      StreamController<ConflictHistoryEntry>.broadcast();

  /// Stream of new history entries
  Stream<ConflictHistoryEntry> get historyAdded =>
      _historyAddedController.stream;

  /// Adds a conflict and its resolution to history
  void recordConflictResolution(
    EnhancedSyncConflict conflict,
    EnhancedSyncConflictResolution resolution,
  ) {
    final entry =
        ConflictHistoryEntry.fromConflictAndResolution(conflict, resolution);

    _history.add(entry);

    // Index by entity
    _entityHistory.putIfAbsent(entry.entityId, () => []).add(entry);

    // Index by collection
    _collectionHistory.putIfAbsent(entry.collection, () => []).add(entry);

    _historyAddedController.add(entry);
  }

  /// Adds notes to an existing history entry
  void addNotesToEntry(String historyId, String notes) {
    final index = _history.indexWhere((entry) => entry.id == historyId);
    if (index != -1) {
      final updatedEntry = _history[index].withNotes(notes);
      _history[index] = updatedEntry;

      // Update in indexes
      _updateEntryInIndexes(updatedEntry);
    }
  }

  void _updateEntryInIndexes(ConflictHistoryEntry entry) {
    // Update entity index
    final entityIndex =
        _entityHistory[entry.entityId]?.indexWhere((e) => e.id == entry.id);
    if (entityIndex != null && entityIndex != -1) {
      _entityHistory[entry.entityId]![entityIndex] = entry;
    }

    // Update collection index
    final collectionIndex = _collectionHistory[entry.collection]
        ?.indexWhere((e) => e.id == entry.id);
    if (collectionIndex != null && collectionIndex != -1) {
      _collectionHistory[entry.collection]![collectionIndex] = entry;
    }
  }

  /// Gets all history entries
  List<ConflictHistoryEntry> getAllHistory() => List.unmodifiable(_history);

  /// Gets history for a specific entity
  List<ConflictHistoryEntry> getEntityHistory(String entityId) {
    return List.unmodifiable(_entityHistory[entityId] ?? []);
  }

  /// Gets history for a specific collection
  List<ConflictHistoryEntry> getCollectionHistory(String collection) {
    return List.unmodifiable(_collectionHistory[collection] ?? []);
  }

  /// Gets recent history entries
  List<ConflictHistoryEntry> getRecentHistory({int limit = 50}) {
    final sorted = List<ConflictHistoryEntry>.from(_history)
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    return sorted.take(limit).toList();
  }

  /// Gets unresolved conflicts
  List<ConflictHistoryEntry> getUnresolvedConflicts() {
    return _history.where((entry) => entry.resolvedAt == null).toList();
  }

  /// Gets manually resolved conflicts
  List<ConflictHistoryEntry> getManuallyResolvedConflicts() {
    return _history.where((entry) => entry.wasManuallyResolved).toList();
  }

  /// Gets conflicts resolved with specific strategy
  List<ConflictHistoryEntry> getConflictsByStrategy(
      EnhancedConflictResolutionStrategy strategy) {
    return _history.where((entry) => entry.strategy == strategy).toList();
  }

  /// Gets conflicts in date range
  List<ConflictHistoryEntry> getConflictsInDateRange(
      DateTime start, DateTime end) {
    return _history
        .where((entry) =>
            entry.occurredAt.isAfter(start) && entry.occurredAt.isBefore(end))
        .toList();
  }

  /// Generates comprehensive statistics
  ConflictResolutionStats generateStats() {
    if (_history.isEmpty) {
      return ConflictResolutionStats(
        totalConflicts: 0,
        resolvedConflicts: 0,
        pendingConflicts: 0,
        strategyUsage: {},
        collectionConflicts: {},
        conflictTypeFrequency: {},
        averageConfidenceScore: 0.0,
        manualResolutionRate: 0.0,
        averageResolutionTime: Duration.zero,
        topConflictedFields: {},
      );
    }

    final resolved = _history.where((e) => e.resolvedAt != null).toList();
    final pending = _history.where((e) => e.resolvedAt == null).toList();
    final manual = _history.where((e) => e.wasManuallyResolved).toList();

    // Strategy usage
    final strategyUsage = <EnhancedConflictResolutionStrategy, int>{};
    for (final entry in _history) {
      strategyUsage[entry.strategy] = (strategyUsage[entry.strategy] ?? 0) + 1;
    }

    // Collection conflicts
    final collectionConflicts = <String, int>{};
    for (final entry in _history) {
      collectionConflicts[entry.collection] =
          (collectionConflicts[entry.collection] ?? 0) + 1;
    }

    // Conflict type frequency
    final conflictTypeFrequency = <EnhancedConflictType, int>{};
    for (final entry in _history) {
      for (final fieldConflict in entry.fieldConflicts.values) {
        final type = fieldConflict.conflictType;
        conflictTypeFrequency[type] = (conflictTypeFrequency[type] ?? 0) + 1;
      }
    }

    // Top conflicted fields
    final fieldConflicts = <String, int>{};
    for (final entry in _history) {
      for (final fieldName in entry.fieldConflicts.keys) {
        fieldConflicts[fieldName] = (fieldConflicts[fieldName] ?? 0) + 1;
      }
    }
    final topConflictedFields = Map.fromEntries(fieldConflicts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value))
      ..take(10));

    // Average confidence score
    final totalConfidence =
        _history.fold<double>(0.0, (sum, e) => sum + e.confidenceScore);
    final averageConfidenceScore = totalConfidence / _history.length;

    // Manual resolution rate
    final manualResolutionRate = manual.length / _history.length;

    // Average resolution time
    final resolutionTimes = resolved
        .where((e) => e.resolvedAt != null)
        .map((e) => e.resolvedAt!.difference(e.occurredAt))
        .toList();

    final averageResolutionTime = resolutionTimes.isNotEmpty
        ? Duration(
            milliseconds: (resolutionTimes.fold<int>(
                        0, (sum, d) => sum + d.inMilliseconds) /
                    resolutionTimes.length)
                .round())
        : Duration.zero;

    return ConflictResolutionStats(
      totalConflicts: _history.length,
      resolvedConflicts: resolved.length,
      pendingConflicts: pending.length,
      strategyUsage: strategyUsage,
      collectionConflicts: collectionConflicts,
      conflictTypeFrequency: conflictTypeFrequency,
      averageConfidenceScore: averageConfidenceScore,
      manualResolutionRate: manualResolutionRate,
      averageResolutionTime: averageResolutionTime,
      topConflictedFields: topConflictedFields,
    );
  }

  /// Learns from past resolutions to suggest strategies
  EnhancedConflictResolutionStrategy suggestStrategyForConflict(
      EnhancedSyncConflict conflict) {
    // Get similar conflicts (same collection and field types)
    final similarConflicts =
        _collectionHistory[conflict.collection]?.where((entry) {
              final commonFields = conflict.fieldConflicts.keys
                  .toSet()
                  .intersection(entry.fieldConflicts.keys.toSet());
              return commonFields.isNotEmpty;
            }).toList() ??
            [];

    if (similarConflicts.isEmpty) {
      return EnhancedConflictResolutionStrategy.intelligentMerge;
    }

    // Find most successful strategy for similar conflicts
    final strategySuccess = <EnhancedConflictResolutionStrategy, double>{};
    for (final entry in similarConflicts) {
      final success = entry.confidenceScore;
      strategySuccess[entry.strategy] =
          (strategySuccess[entry.strategy] ?? 0.0) + success;
    }

    // Return strategy with highest average success rate
    final bestStrategy =
        strategySuccess.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    return bestStrategy;
  }

  /// Exports history to JSON
  Map<String, dynamic> exportToJson() {
    return {
      'exportedAt': DateTime.now().toIso8601String(),
      'totalEntries': _history.length,
      'history': _history.map((e) => e.toJson()).toList(),
      'statistics': generateStats().toJson(),
    };
  }

  /// Imports history from JSON
  void importFromJson(Map<String, dynamic> json) {
    final historyList = json['history'] as List? ?? [];

    for (final entryJson in historyList) {
      final entry = ConflictHistoryEntry.fromJson(entryJson);
      _history.add(entry);
      _entityHistory.putIfAbsent(entry.entityId, () => []).add(entry);
      _collectionHistory.putIfAbsent(entry.collection, () => []).add(entry);
    }
  }

  /// Clears all history
  void clearHistory() {
    _history.clear();
    _entityHistory.clear();
    _collectionHistory.clear();
  }

  /// Disposes resources
  void dispose() {
    _historyAddedController.close();
  }
}
