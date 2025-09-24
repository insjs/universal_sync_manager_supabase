// lib/src/services/usm_interactive_conflict_ui.dart

import 'dart:async';

import '../config/usm_sync_enums.dart';
import 'usm_enhanced_conflict_resolver.dart';
import 'usm_custom_merge_strategies.dart';

/// Interactive conflict resolution result
class InteractiveResolutionResult {
  final String conflictId;
  final Map<String, dynamic> resolvedData;
  final Map<String, String> fieldResolutions;
  final bool userAccepted;
  final String? userNotes;
  final Duration interactionTime;

  const InteractiveResolutionResult({
    required this.conflictId,
    required this.resolvedData,
    required this.fieldResolutions,
    required this.userAccepted,
    this.userNotes,
    required this.interactionTime,
  });
}

/// Field resolution choice for interactive UI
class FieldResolutionChoice {
  final String fieldName;
  final dynamic localValue;
  final dynamic remoteValue;
  final dynamic suggestedValue;
  final List<String> availableStrategies;
  final String recommendedStrategy;
  final double confidence;

  const FieldResolutionChoice({
    required this.fieldName,
    required this.localValue,
    required this.remoteValue,
    required this.suggestedValue,
    required this.availableStrategies,
    required this.recommendedStrategy,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
        'fieldName': fieldName,
        'localValue': localValue,
        'remoteValue': remoteValue,
        'suggestedValue': suggestedValue,
        'availableStrategies': availableStrategies,
        'recommendedStrategy': recommendedStrategy,
        'confidence': confidence,
      };
}

/// Interactive conflict resolution UI helper
class InteractiveConflictUIService {
  final Map<String, CustomMergeStrategy> _mergeStrategies = {};
  final StreamController<EnhancedSyncConflict> _conflictPresentedController =
      StreamController<EnhancedSyncConflict>.broadcast();
  final StreamController<InteractiveResolutionResult>
      _resolutionCompletedController =
      StreamController<InteractiveResolutionResult>.broadcast();

  InteractiveConflictUIService() {
    _initializeMergeStrategies();
  }

  void _initializeMergeStrategies() {
    final strategies = [
      ArrayMergeStrategy(),
      NumericMergeStrategy(),
      TextMergeStrategy(),
      JsonObjectMergeStrategy(),
      BooleanMergeStrategy(),
      TimestampMergeStrategy(),
    ];

    for (final strategy in strategies) {
      _mergeStrategies[strategy.name] = strategy;
    }
  }

  /// Stream of conflicts presented to user
  Stream<EnhancedSyncConflict> get conflictPresented =>
      _conflictPresentedController.stream;

  /// Stream of completed resolutions
  Stream<InteractiveResolutionResult> get resolutionCompleted =>
      _resolutionCompletedController.stream;

  /// Prepares conflict data for interactive UI presentation
  Map<String, dynamic> prepareConflictForUI(EnhancedSyncConflict conflict) {
    final choices = <FieldResolutionChoice>[];
    final summary = _generateConflictSummary(conflict);

    for (final entry in conflict.fieldConflicts.entries) {
      final fieldName = entry.key;
      final conflictInfo = entry.value;

      final choice = _createFieldChoice(
        fieldName,
        conflictInfo.localValue,
        conflictInfo.remoteValue,
        conflict.localData,
        conflict.remoteData,
      );

      choices.add(choice);
    }

    _conflictPresentedController.add(conflict);

    return {
      'conflictId': conflict.conflictId,
      'entityId': conflict.entityId,
      'collection': conflict.collection,
      'summary': summary,
      'fieldChoices': choices.map((c) => c.toJson()).toList(),
      'metadata': {
        'priority': conflict.priority.name,
        'detectedAt': conflict.detectedAt.toIso8601String(),
        'localVersion': conflict.localVersion,
        'remoteVersion': conflict.remoteVersion,
        'tags': conflict.tags,
        'requiresManualIntervention': conflict.requiresManualIntervention,
      },
    };
  }

  /// Processes user resolution choices
  InteractiveResolutionResult processUserResolution(
    EnhancedSyncConflict conflict,
    Map<String, dynamic> userChoices,
    DateTime startTime,
  ) {
    final resolvedData = <String, dynamic>{};
    final fieldResolutions = <String, String>{};

    // Start with one of the data sets as base
    resolvedData.addAll(conflict.remoteData);

    // Apply user choices for each field
    for (final entry in userChoices.entries) {
      final fieldName = entry.key;
      final userChoice = entry.value;

      if (userChoice is Map<String, dynamic>) {
        final strategy = userChoice['strategy'] as String?;
        final customValue = userChoice['customValue'];

        if (customValue != null) {
          // User provided custom value
          resolvedData[fieldName] = customValue;
          fieldResolutions[fieldName] = 'custom';
        } else if (strategy != null) {
          // User selected a strategy
          final resolvedValue = _applyStrategy(
            strategy,
            fieldName,
            conflict.localData[fieldName],
            conflict.remoteData[fieldName],
            conflict.localData,
          );

          resolvedData[fieldName] = resolvedValue;
          fieldResolutions[fieldName] = strategy;
        }
      }
    }

    final interactionTime = DateTime.now().difference(startTime);
    final userAccepted = userChoices['_userAccepted'] as bool? ?? true;
    final userNotes = userChoices['_userNotes'] as String?;

    final result = InteractiveResolutionResult(
      conflictId: conflict.conflictId,
      resolvedData: resolvedData,
      fieldResolutions: fieldResolutions,
      userAccepted: userAccepted,
      userNotes: userNotes,
      interactionTime: interactionTime,
    );

    _resolutionCompletedController.add(result);
    return result;
  }

  /// Creates resolution choice for a field
  FieldResolutionChoice _createFieldChoice(
    String fieldName,
    dynamic localValue,
    dynamic remoteValue,
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    final availableStrategies =
        _getAvailableStrategiesForField(fieldName, localValue, remoteValue);
    final recommendedStrategy =
        _getRecommendedStrategy(fieldName, localValue, remoteValue);
    final suggestedValue = _applyStrategy(
        recommendedStrategy, fieldName, localValue, remoteValue, localData);
    final confidence = _calculateConfidence(
        fieldName, localValue, remoteValue, recommendedStrategy);

    return FieldResolutionChoice(
      fieldName: fieldName,
      localValue: localValue,
      remoteValue: remoteValue,
      suggestedValue: suggestedValue,
      availableStrategies: availableStrategies,
      recommendedStrategy: recommendedStrategy,
      confidence: confidence,
    );
  }

  /// Gets available strategies for a field based on its type and value
  List<String> _getAvailableStrategiesForField(
      String fieldName, dynamic localValue, dynamic remoteValue) {
    final strategies = <String>['useLocal', 'useRemote'];

    // Add type-specific strategies
    if (localValue is List && remoteValue is List) {
      strategies.add('ArrayMerge');
    }

    if (localValue is num && remoteValue is num) {
      strategies.add('NumericMerge');
    }

    if (localValue is String && remoteValue is String) {
      strategies.add('TextMerge');
    }

    if (localValue is Map && remoteValue is Map) {
      strategies.add('JsonObjectMerge');
    }

    if (localValue is bool && remoteValue is bool) {
      strategies.add('BooleanMerge');
    }

    // Check for timestamp fields
    if (_isTimestampField(fieldName) ||
        _isTimestampValue(localValue) ||
        _isTimestampValue(remoteValue)) {
      strategies.add('TimestampMerge');
    }

    strategies.add('custom'); // Always allow custom input
    return strategies;
  }

  /// Gets recommended strategy for a field
  String _getRecommendedStrategy(
      String fieldName, dynamic localValue, dynamic remoteValue) {
    // Check for specific field patterns
    if (_isTimestampField(fieldName)) {
      return 'TimestampMerge';
    }

    if (fieldName.toLowerCase().contains('active') ||
        fieldName.toLowerCase().contains('deleted') ||
        fieldName.toLowerCase().contains('dirty')) {
      return 'BooleanMerge';
    }

    // Check by value type
    if (localValue is List && remoteValue is List) {
      return 'ArrayMerge';
    }

    if (localValue is num && remoteValue is num) {
      return 'NumericMerge';
    }

    if (localValue is String && remoteValue is String) {
      return 'TextMerge';
    }

    if (localValue is Map && remoteValue is Map) {
      return 'JsonObjectMerge';
    }

    if (localValue is bool && remoteValue is bool) {
      return 'BooleanMerge';
    }

    // Default recommendation
    return 'useRemote';
  }

  /// Applies a resolution strategy to get the resolved value
  dynamic _applyStrategy(
    String strategy,
    String fieldName,
    dynamic localValue,
    dynamic remoteValue,
    Map<String, dynamic> context,
  ) {
    switch (strategy) {
      case 'useLocal':
        return localValue;
      case 'useRemote':
        return remoteValue;
      default:
        // Use custom merge strategy
        final mergeStrategy = _mergeStrategies[strategy];
        if (mergeStrategy != null) {
          return mergeStrategy.mergeValues(
              fieldName, localValue, remoteValue, context);
        }
        return remoteValue; // Fallback
    }
  }

  /// Calculates confidence score for a strategy
  double _calculateConfidence(String fieldName, dynamic localValue,
      dynamic remoteValue, String strategy) {
    switch (strategy) {
      case 'useLocal':
      case 'useRemote':
        return 0.8; // High confidence for simple choices
      default:
        final mergeStrategy = _mergeStrategies[strategy];
        return mergeStrategy?.getConfidenceScore(
                fieldName, localValue, remoteValue) ??
            0.5;
    }
  }

  /// Generates a human-readable summary of the conflict
  Map<String, dynamic> _generateConflictSummary(EnhancedSyncConflict conflict) {
    final conflictTypes = <String, int>{};
    final criticalFields = <String>[];

    for (final entry in conflict.fieldConflicts.entries) {
      final type = entry.value.conflictType.name;
      conflictTypes[type] = (conflictTypes[type] ?? 0) + 1;

      // Mark critical fields
      if (entry.key.toLowerCase().contains('id') ||
          entry.key.toLowerCase().contains('deleted') ||
          entry.key.toLowerCase().contains('active')) {
        criticalFields.add(entry.key);
      }
    }

    return {
      'totalFields': conflict.fieldConflicts.length,
      'conflictTypes': conflictTypes,
      'criticalFields': criticalFields,
      'hasStructuralConflicts': conflict.fieldConflicts.values.any(
        (c) => c.conflictType == EnhancedConflictType.structuralConflict,
      ),
      'hasSemanticConflicts': conflict.fieldConflicts.values.any(
        (c) => c.conflictType == EnhancedConflictType.semanticConflict,
      ),
      'averageConfidence': _calculateAverageConfidence(conflict),
      'riskLevel': _assessRiskLevel(conflict),
    };
  }

  double _calculateAverageConfidence(EnhancedSyncConflict conflict) {
    if (conflict.fieldConflicts.isEmpty) return 1.0;

    final totalConfidence = conflict.fieldConflicts.values
        .fold<double>(0.0, (sum, info) => sum + info.confidenceScore);

    return totalConfidence / conflict.fieldConflicts.length;
  }

  String _assessRiskLevel(EnhancedSyncConflict conflict) {
    final criticalFields = conflict.fieldConflicts.keys
        .where((field) =>
            field.toLowerCase().contains('id') ||
            field.toLowerCase().contains('deleted') ||
            field.toLowerCase().contains('active'))
        .length;

    final semanticConflicts = conflict.fieldConflicts.values
        .where((info) =>
            info.conflictType == EnhancedConflictType.semanticConflict ||
            info.conflictType == EnhancedConflictType.referenceConflict)
        .length;

    if (criticalFields > 0 || semanticConflicts > 0) {
      return 'high';
    } else if (conflict.fieldConflicts.length > 5) {
      return 'medium';
    } else {
      return 'low';
    }
  }

  bool _isTimestampField(String fieldName) {
    final name = fieldName.toLowerCase();
    return name.contains('timestamp') ||
        name.contains('createdat') ||
        name.contains('updatedat') ||
        name.contains('deletedat') ||
        name.endsWith('at');
  }

  bool _isTimestampValue(dynamic value) {
    if (value is DateTime) return true;
    if (value is String) {
      try {
        DateTime.parse(value);
        return true;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  /// Registers a custom merge strategy
  void registerMergeStrategy(CustomMergeStrategy strategy) {
    _mergeStrategies[strategy.name] = strategy;
  }

  /// Gets all available merge strategies
  Map<String, CustomMergeStrategy> get availableMergeStrategies =>
      Map.unmodifiable(_mergeStrategies);

  /// Disposes resources
  void dispose() {
    _conflictPresentedController.close();
    _resolutionCompletedController.close();
  }
}
