// lib/src/services/usm_enhanced_conflict_resolver.dart

import 'dart:async';
import 'dart:convert';

import 'usm_sync_queue.dart';
import '../config/usm_sync_enums.dart';

/// Field-level conflict information with enhanced metadata
class FieldConflictInfo {
  final String fieldName;
  final EnhancedConflictType conflictType;
  final dynamic localValue;
  final dynamic remoteValue;
  final Map<String, dynamic> metadata;
  final String? semanticReason;
  final double confidenceScore;
  final List<String> possibleResolutions;

  const FieldConflictInfo({
    required this.fieldName,
    required this.conflictType,
    this.localValue,
    this.remoteValue,
    this.metadata = const {},
    this.semanticReason,
    this.confidenceScore = 1.0,
    this.possibleResolutions = const [],
  });

  Map<String, dynamic> toJson() => {
        'fieldName': fieldName,
        'conflictType': conflictType.name,
        'localValue': localValue,
        'remoteValue': remoteValue,
        'metadata': metadata,
        'semanticReason': semanticReason,
        'confidenceScore': confidenceScore,
        'possibleResolutions': possibleResolutions,
      };

  factory FieldConflictInfo.fromJson(Map<String, dynamic> json) {
    return FieldConflictInfo(
      fieldName: json['fieldName'],
      conflictType: EnhancedConflictType.values.firstWhere(
        (e) => e.name == json['conflictType'],
      ),
      localValue: json['localValue'],
      remoteValue: json['remoteValue'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      semanticReason: json['semanticReason'],
      confidenceScore: (json['confidenceScore'] ?? 1.0).toDouble(),
      possibleResolutions: List<String>.from(json['possibleResolutions'] ?? []),
    );
  }
}

/// Enhanced conflict with detailed field-level information
class EnhancedSyncConflict {
  final String entityId;
  final String collection;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final Map<String, FieldConflictInfo> fieldConflicts;
  final DateTime detectedAt;
  final int localVersion;
  final int remoteVersion;
  final String conflictId;
  final SyncPriority priority;
  final Map<String, dynamic> context;
  final List<String> tags;

  EnhancedSyncConflict({
    required this.entityId,
    required this.collection,
    required this.localData,
    required this.remoteData,
    required this.fieldConflicts,
    required this.detectedAt,
    required this.localVersion,
    required this.remoteVersion,
    String? conflictId,
    this.priority = SyncPriority.normal,
    this.context = const {},
    this.tags = const [],
  }) : conflictId =
            conflictId ?? 'conflict_${DateTime.now().millisecondsSinceEpoch}';

  /// Gets conflicts by type
  List<FieldConflictInfo> getConflictsByType(EnhancedConflictType type) {
    return fieldConflicts.values.where((c) => c.conflictType == type).toList();
  }

  /// Gets high-confidence conflicts
  List<FieldConflictInfo> getHighConfidenceConflicts({double threshold = 0.8}) {
    return fieldConflicts.values
        .where((c) => c.confidenceScore >= threshold)
        .toList();
  }

  /// Checks if conflict requires manual intervention
  bool get requiresManualIntervention {
    return fieldConflicts.values.any((c) =>
        c.conflictType == EnhancedConflictType.semanticConflict ||
        c.conflictType == EnhancedConflictType.referenceConflict ||
        c.confidenceScore < 0.5);
  }

  Map<String, dynamic> toJson() => {
        'conflictId': conflictId,
        'entityId': entityId,
        'collection': collection,
        'localData': localData,
        'remoteData': remoteData,
        'fieldConflicts': fieldConflicts.map((k, v) => MapEntry(k, v.toJson())),
        'detectedAt': detectedAt.toIso8601String(),
        'localVersion': localVersion,
        'remoteVersion': remoteVersion,
        'priority': priority.name,
        'context': context,
        'tags': tags,
      };

  factory EnhancedSyncConflict.fromJson(Map<String, dynamic> json) {
    final fieldConflictsMap = <String, FieldConflictInfo>{};
    final fieldConflictsJson =
        json['fieldConflicts'] as Map<String, dynamic>? ?? {};

    for (final entry in fieldConflictsJson.entries) {
      fieldConflictsMap[entry.key] = FieldConflictInfo.fromJson(entry.value);
    }

    return EnhancedSyncConflict(
      conflictId: json['conflictId'],
      entityId: json['entityId'],
      collection: json['collection'],
      localData: Map<String, dynamic>.from(json['localData']),
      remoteData: Map<String, dynamic>.from(json['remoteData']),
      fieldConflicts: fieldConflictsMap,
      detectedAt: DateTime.parse(json['detectedAt']),
      localVersion: json['localVersion'],
      remoteVersion: json['remoteVersion'],
      priority: SyncPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => SyncPriority.normal,
      ),
      context: Map<String, dynamic>.from(json['context'] ?? {}),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}

/// Enhanced conflict resolution result with detailed metadata
class EnhancedSyncConflictResolution {
  final String conflictId;
  final Map<String, dynamic> resolvedData;
  final EnhancedConflictResolutionStrategy strategy;
  final Map<String, String> fieldResolutionStrategies;
  final List<String> fieldsUsedFromLocal;
  final List<String> fieldsUsedFromRemote;
  final List<String> fieldsRequiringManualReview;
  final bool requiresUserIntervention;
  final Map<String, dynamic> metadata;
  final DateTime resolvedAt;
  final String? resolvedBy;
  final double confidenceScore;
  final List<String> warnings;
  final Map<String, dynamic> auditTrail;

  const EnhancedSyncConflictResolution({
    required this.conflictId,
    required this.resolvedData,
    required this.strategy,
    this.fieldResolutionStrategies = const {},
    this.fieldsUsedFromLocal = const [],
    this.fieldsUsedFromRemote = const [],
    this.fieldsRequiringManualReview = const [],
    this.requiresUserIntervention = false,
    this.metadata = const {},
    required this.resolvedAt,
    this.resolvedBy,
    this.confidenceScore = 1.0,
    this.warnings = const [],
    this.auditTrail = const {},
  });

  factory EnhancedSyncConflictResolution.useLocal(
    String conflictId,
    Map<String, dynamic> localData, {
    String? resolvedBy,
  }) {
    return EnhancedSyncConflictResolution(
      conflictId: conflictId,
      resolvedData: Map.from(localData),
      strategy: EnhancedConflictResolutionStrategy.localWins,
      fieldsUsedFromLocal: localData.keys.toList(),
      resolvedAt: DateTime.now(),
      resolvedBy: resolvedBy,
      auditTrail: {
        'strategy': 'localWins',
        'reason': 'Used local version for all fields',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  factory EnhancedSyncConflictResolution.useRemote(
    String conflictId,
    Map<String, dynamic> remoteData, {
    String? resolvedBy,
  }) {
    return EnhancedSyncConflictResolution(
      conflictId: conflictId,
      resolvedData: Map.from(remoteData),
      strategy: EnhancedConflictResolutionStrategy.remoteWins,
      fieldsUsedFromRemote: remoteData.keys.toList(),
      resolvedAt: DateTime.now(),
      resolvedBy: resolvedBy,
      auditTrail: {
        'strategy': 'remoteWins',
        'reason': 'Used remote version for all fields',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  factory EnhancedSyncConflictResolution.intelligentMerge(
    String conflictId, {
    required Map<String, dynamic> mergedData,
    required Map<String, String> fieldStrategies,
    required List<String> localFields,
    required List<String> remoteFields,
    String? resolvedBy,
    double confidenceScore = 1.0,
    List<String> warnings = const [],
  }) {
    return EnhancedSyncConflictResolution(
      conflictId: conflictId,
      resolvedData: mergedData,
      strategy: EnhancedConflictResolutionStrategy.intelligentMerge,
      fieldResolutionStrategies: fieldStrategies,
      fieldsUsedFromLocal: localFields,
      fieldsUsedFromRemote: remoteFields,
      resolvedAt: DateTime.now(),
      resolvedBy: resolvedBy,
      confidenceScore: confidenceScore,
      warnings: warnings,
      auditTrail: {
        'strategy': 'intelligentMerge',
        'fieldStrategies': fieldStrategies,
        'confidenceScore': confidenceScore,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  factory EnhancedSyncConflictResolution.requiresManual(
    String conflictId,
    EnhancedSyncConflict conflict, {
    List<String> fieldsNeedingReview = const [],
    String? reason,
  }) {
    return EnhancedSyncConflictResolution(
      conflictId: conflictId,
      resolvedData: conflict.localData,
      strategy: EnhancedConflictResolutionStrategy.manual,
      fieldsRequiringManualReview: fieldsNeedingReview.isEmpty
          ? conflict.fieldConflicts.keys.toList()
          : fieldsNeedingReview,
      requiresUserIntervention: true,
      resolvedAt: DateTime.now(),
      metadata: {'reason': reason ?? 'Complex conflict requires manual review'},
      auditTrail: {
        'strategy': 'manual',
        'reason': reason ?? 'Complex conflict requires manual review',
        'fieldsNeedingReview': fieldsNeedingReview,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Map<String, dynamic> toJson() => {
        'conflictId': conflictId,
        'resolvedData': resolvedData,
        'strategy': strategy.name,
        'fieldResolutionStrategies': fieldResolutionStrategies,
        'fieldsUsedFromLocal': fieldsUsedFromLocal,
        'fieldsUsedFromRemote': fieldsUsedFromRemote,
        'fieldsRequiringManualReview': fieldsRequiringManualReview,
        'requiresUserIntervention': requiresUserIntervention,
        'metadata': metadata,
        'resolvedAt': resolvedAt.toIso8601String(),
        'resolvedBy': resolvedBy,
        'confidenceScore': confidenceScore,
        'warnings': warnings,
        'auditTrail': auditTrail,
      };

  factory EnhancedSyncConflictResolution.fromJson(Map<String, dynamic> json) {
    return EnhancedSyncConflictResolution(
      conflictId: json['conflictId'],
      resolvedData: Map<String, dynamic>.from(json['resolvedData']),
      strategy: EnhancedConflictResolutionStrategy.values.firstWhere(
        (s) => s.name == json['strategy'],
      ),
      fieldResolutionStrategies:
          Map<String, String>.from(json['fieldResolutionStrategies'] ?? {}),
      fieldsUsedFromLocal: List<String>.from(json['fieldsUsedFromLocal'] ?? []),
      fieldsUsedFromRemote:
          List<String>.from(json['fieldsUsedFromRemote'] ?? []),
      fieldsRequiringManualReview:
          List<String>.from(json['fieldsRequiringManualReview'] ?? []),
      requiresUserIntervention: json['requiresUserIntervention'] ?? false,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      resolvedAt: DateTime.parse(json['resolvedAt']),
      resolvedBy: json['resolvedBy'],
      confidenceScore: (json['confidenceScore'] ?? 1.0).toDouble(),
      warnings: List<String>.from(json['warnings'] ?? []),
      auditTrail: Map<String, dynamic>.from(json['auditTrail'] ?? {}),
    );
  }

  @override
  String toString() {
    return 'EnhancedSyncConflictResolution(conflictId: $conflictId, strategy: $strategy, confidence: $confidenceScore)';
  }
}

/// Abstract base class for enhanced conflict resolvers
abstract class EnhancedConflictResolver {
  /// Resolves a conflict between local and remote data
  EnhancedSyncConflictResolution resolveConflict(EnhancedSyncConflict conflict);

  /// Returns the name of this resolver
  String get name;

  /// Returns the priority of this resolver (higher = more preferred)
  int get priority => 0;

  /// Returns whether this resolver can handle the given conflict
  bool canResolve(EnhancedSyncConflict conflict);

  /// Returns confidence score for handling this conflict type
  double getConfidenceScore(EnhancedSyncConflict conflict) => 1.0;

  /// Pre-processes conflict for better resolution
  EnhancedSyncConflict preprocessConflict(EnhancedSyncConflict conflict) =>
      conflict;

  /// Post-processes resolution for validation
  EnhancedSyncConflictResolution postprocessResolution(
    EnhancedSyncConflictResolution resolution,
  ) =>
      resolution;
}

/// Custom merge strategy interface
abstract class CustomMergeStrategy {
  /// Name of the merge strategy
  String get name;

  /// Merges two values for a specific field
  dynamic mergeValues(
    String fieldName,
    dynamic localValue,
    dynamic remoteValue,
    Map<String, dynamic> context,
  );

  /// Returns confidence score for merging these values
  double getConfidenceScore(
    String fieldName,
    dynamic localValue,
    dynamic remoteValue,
  );

  /// Validates the merged result
  bool validateMergedValue(dynamic mergedValue, Map<String, dynamic> context);
}
