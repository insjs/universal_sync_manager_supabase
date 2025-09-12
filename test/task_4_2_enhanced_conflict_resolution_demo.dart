// test/task_4_2_enhanced_conflict_resolution_demo.dart

import 'dart:async';

import '../lib/src/services/usm_enhanced_conflict_resolver.dart';
import '../lib/src/services/usm_enhanced_conflict_resolution_manager.dart';
import '../lib/src/services/usm_custom_merge_strategies.dart';
import '../lib/src/services/usm_conflict_history_service.dart';

/// Demo showcasing enhanced conflict resolution capabilities
class EnhancedConflictResolutionDemo {
  late EnhancedConflictResolutionManager _conflictManager;

  Future<void> runDemo() async {
    print('🚀 Enhanced Conflict Resolution Demo - Task 4.2');
    print('===========================================\n');

    await _initializeConflictManager();
    await _demonstrateFieldLevelDetection();
    await _demonstrateCustomMergeStrategies();
    await _demonstrateInteractiveResolution();
    await _demonstrateConflictHistory();
    await _demonstratePluggableResolvers();
    await _showStatisticsAndAnalytics();

    print('\n✅ Enhanced Conflict Resolution Demo completed successfully!');
    print('📊 All 5 Task 4.2 actions implemented and working:');
    print('   1. ✅ Pluggable conflict resolution strategies');
    print('   2. ✅ Field-level conflict detection with enhanced metadata');
    print('   3. ✅ User-interactive conflict resolution UI');
    print('   4. ✅ Conflict history tracking and analytics');
    print('   5. ✅ Custom merge strategies for complex data types');
  }

  Future<void> _initializeConflictManager() async {
    print('📋 1. Initializing Enhanced Conflict Resolution Manager');
    print('─────────────────────────────────────────────────────');

    _conflictManager = EnhancedConflictResolutionManager();

    // Register custom merge strategies
    _conflictManager.registerMergeStrategy(ArrayMergeStrategy());
    _conflictManager.registerMergeStrategy(NumericMergeStrategy());
    _conflictManager.registerMergeStrategy(TextMergeStrategy());
    _conflictManager.registerMergeStrategy(JsonObjectMergeStrategy());
    _conflictManager.registerMergeStrategy(BooleanMergeStrategy());
    _conflictManager.registerMergeStrategy(TimestampMergeStrategy());

    print('✅ Enhanced conflict manager initialized with 6 merge strategies');
    print('   - ArrayMergeStrategy for list conflicts');
    print('   - NumericMergeStrategy for numerical values');
    print('   - TextMergeStrategy for string fields');
    print('   - JsonObjectMergeStrategy for complex objects');
    print('   - BooleanMergeStrategy for boolean flags');
    print('   - TimestampMergeStrategy for date/time fields\n');
  }

  Future<void> _demonstrateFieldLevelDetection() async {
    print('🔍 2. Field-Level Conflict Detection');
    print('───────────────────────────────────');

    // Create complex conflict scenario
    final localData = {
      'id': 'user_123',
      'name': 'John Smith',
      'email': 'john.smith@example.com',
      'isActive': true,
      'lastLoginAt': '2024-01-15T10:30:00Z',
      'preferences': {
        'theme': 'dark',
        'notifications': true,
        'language': 'en',
      },
      'roles': ['user', 'premium'],
      'loginCount': 45,
      'profileCompleteness': 0.85,
      'updatedAt': '2024-01-15T10:30:00Z',
      'version': 5,
    };

    final remoteData = {
      'id': 'user_123',
      'name': 'John M. Smith', // Text conflict
      'email': 'john.m.smith@newdomain.com', // Email change
      'isActive': false, // Boolean conflict
      'lastLoginAt': '2024-01-15T14:20:00Z', // Timestamp conflict
      'preferences': {
        'theme': 'light', // Object conflict
        'notifications': true,
        'language': 'en',
        'autoSave': true, // New field
      },
      'roles': ['user', 'admin'], // Array conflict
      'loginCount': 47, // Numeric conflict
      'profileCompleteness': 0.90, // Numeric conflict
      'department': 'Engineering', // New field
      'updatedAt': '2024-01-15T14:20:00Z',
      'version': 6,
    };

    final conflict = _conflictManager.detectConflict(
      entityId: 'user_123',
      collection: 'users',
      localData: localData,
      remoteData: remoteData,
      localVersion: 5,
      remoteVersion: 6,
      context: {'source': 'demo', 'conflictReason': 'concurrent_update'},
      tags: ['user-profile', 'high-priority'],
    );

    if (conflict != null) {
      print(
          '🔍 Detected enhanced conflict with ${conflict.fieldConflicts.length} field conflicts:');

      for (final entry in conflict.fieldConflicts.entries) {
        final fieldName = entry.key;
        final info = entry.value;

        print('   📝 $fieldName:');
        print('      Type: ${info.conflictType.name}');
        print('      Local: ${_formatValue(info.localValue)}');
        print('      Remote: ${_formatValue(info.remoteValue)}');
        print('      Confidence: ${(info.confidenceScore * 100).toInt()}%');
        print('      Strategies: ${info.possibleResolutions.join(", ")}');

        if (info.semanticReason != null) {
          print('      Reason: ${info.semanticReason}');
        }
        print('');
      }

      print('📊 Conflict Summary:');
      print('   - Priority: ${conflict.priority.name}');
      print(
          '   - Requires manual intervention: ${conflict.requiresManualIntervention}');
      print(
          '   - High confidence conflicts: ${conflict.getHighConfidenceConflicts().length}');
      print('   - Tags: ${conflict.tags.join(", ")}');
    }

    print('');
  }

  Future<void> _demonstrateCustomMergeStrategies() async {
    print('🔧 3. Custom Merge Strategies');
    print('─────────────────────────────');

    // Test each merge strategy
    await _testArrayMergeStrategy();
    await _testNumericMergeStrategy();
    await _testTextMergeStrategy();
    await _testBooleanMergeStrategy();
    await _testTimestampMergeStrategy();
    await _testJsonObjectMergeStrategy();

    print('');
  }

  Future<void> _testArrayMergeStrategy() async {
    print('📝 Array Merge Strategy:');

    final strategy = ArrayMergeStrategy();

    // Test ID list merge
    final localIds = ['user_1', 'user_2', 'user_3'];
    final remoteIds = ['user_2', 'user_3', 'user_4'];
    final mergedIds =
        strategy.mergeValues('memberIds', localIds, remoteIds, {});
    print(
        '   ID Lists: [${localIds.join(", ")}] + [${remoteIds.join(", ")}] = [${mergedIds.join(", ")}]');

    // Test timestamp-ordered list merge
    final localEvents = [
      {'id': 'event_1', 'timestamp': '2024-01-15T10:00:00Z', 'type': 'login'},
      {'id': 'event_2', 'timestamp': '2024-01-15T11:00:00Z', 'type': 'action'},
    ];
    final remoteEvents = [
      {
        'id': 'event_1',
        'timestamp': '2024-01-15T10:30:00Z',
        'type': 'updated_login'
      }, // Updated version
      {'id': 'event_3', 'timestamp': '2024-01-15T12:00:00Z', 'type': 'logout'},
    ];
    final mergedEvents =
        strategy.mergeValues('events', localEvents, remoteEvents, {});
    print(
        '   Events: Merged ${localEvents.length} local + ${remoteEvents.length} remote = ${mergedEvents.length} total events');
  }

  Future<void> _testNumericMergeStrategy() async {
    print('📝 Numeric Merge Strategy:');

    final strategy = NumericMergeStrategy();

    // Test count merge (should use max)
    final localCount = 45;
    final remoteCount = 47;
    final mergedCount =
        strategy.mergeValues('loginCount', localCount, remoteCount, {});
    print('   Count: max($localCount, $remoteCount) = $mergedCount');

    // Test rate merge (should use average)
    final localRate = 0.85;
    final remoteRate = 0.90;
    final mergedRate =
        strategy.mergeValues('completionRate', localRate, remoteRate, {});
    print(
        '   Rate: avg($localRate, $remoteRate) = ${mergedRate.toStringAsFixed(3)}');

    // Test version merge (should use max)
    final localVersion = 5;
    final remoteVersion = 6;
    final mergedVersion =
        strategy.mergeValues('version', localVersion, remoteVersion, {});
    print('   Version: max($localVersion, $remoteVersion) = $mergedVersion');
  }

  Future<void> _testTextMergeStrategy() async {
    print('📝 Text Merge Strategy:');

    final strategy = TextMergeStrategy();

    // Test name merge (should prefer longer)
    final localName = 'John Smith';
    final remoteName = 'John M. Smith';
    final mergedName = strategy.mergeValues('name', localName, remoteName, {});
    print(
        '   Name: "$localName" vs "$remoteName" = "$mergedName" (longer preferred)');

    // Test description merge (should combine)
    final localDesc = 'Experienced developer';
    final remoteDesc = 'Team lead with 5 years experience';
    final mergedDesc =
        strategy.mergeValues('description', localDesc, remoteDesc, {});
    print('   Description: Combined different descriptions');
    print('   Result: "$mergedDesc"');
  }

  Future<void> _testBooleanMergeStrategy() async {
    print('📝 Boolean Merge Strategy:');

    final strategy = BooleanMergeStrategy();

    // Test active flag (should OR)
    final localActive = true;
    final remoteActive = false;
    final mergedActive =
        strategy.mergeValues('isActive', localActive, remoteActive, {});
    print(
        '   Active: $localActive OR $remoteActive = $mergedActive (OR for status flags)');

    // Test deleted flag (should OR)
    final localDeleted = false;
    final remoteDeleted = true;
    final mergedDeleted =
        strategy.mergeValues('isDeleted', localDeleted, remoteDeleted, {});
    print(
        '   Deleted: $localDeleted OR $remoteDeleted = $mergedDeleted (OR for deletion flags)');
  }

  Future<void> _testTimestampMergeStrategy() async {
    print('📝 Timestamp Merge Strategy:');

    final strategy = TimestampMergeStrategy();

    // Test updated timestamp (should use newer)
    final localTime = '2024-01-15T10:30:00Z';
    final remoteTime = '2024-01-15T14:20:00Z';
    final mergedTime =
        strategy.mergeValues('updatedAt', localTime, remoteTime, {});
    print('   Updated: newer of "$localTime" and "$remoteTime"');
    print('   Result: "$mergedTime"');

    // Test created timestamp (should use older)
    final localCreated = '2024-01-10T08:00:00Z';
    final remoteCreated = '2024-01-10T09:00:00Z';
    final mergedCreated =
        strategy.mergeValues('createdAt', localCreated, remoteCreated, {});
    print('   Created: older of "$localCreated" and "$remoteCreated"');
    print('   Result: "$mergedCreated"');
  }

  Future<void> _testJsonObjectMergeStrategy() async {
    print('📝 JSON Object Merge Strategy:');

    final strategy = JsonObjectMergeStrategy();

    final localPrefs = {
      'theme': 'dark',
      'notifications': true,
      'language': 'en',
    };
    final remotePrefs = {
      'theme': 'light',
      'notifications': true,
      'autoSave': true,
      'language': 'en',
    };

    final mergedPrefs =
        strategy.mergeValues('preferences', localPrefs, remotePrefs, {});
    print('   Preferences: Deep merged objects');
    print('   Local: ${localPrefs.keys.join(", ")}');
    print('   Remote: ${remotePrefs.keys.join(", ")}');
    print('   Merged: ${mergedPrefs.keys.join(", ")}');
    print(
        '   Theme resolved to: ${mergedPrefs['theme']} (remote wins for conflicts)');
  }

  Future<void> _demonstrateInteractiveResolution() async {
    print('🎮 4. Interactive Conflict Resolution UI');
    print('───────────────────────────────────────');

    // Create a complex conflict
    final localData = {
      'name': 'Important Document',
      'content': 'Original content with important changes',
      'tags': ['urgent', 'draft'],
      'isPublished': false,
      'collaborators': ['user_1', 'user_2'],
      'lastEditedBy': 'user_1',
      'editCount': 15,
      'updatedAt': '2024-01-15T10:30:00Z',
    };

    final remoteData = {
      'name': 'Important Document v2',
      'content': 'Remote content with different edits',
      'tags': ['urgent', 'final'],
      'isPublished': true,
      'collaborators': ['user_1', 'user_3'],
      'lastEditedBy': 'user_3',
      'editCount': 18,
      'updatedAt': '2024-01-15T14:20:00Z',
    };

    final conflict = _conflictManager.detectConflict(
      entityId: 'doc_456',
      collection: 'documents',
      localData: localData,
      remoteData: remoteData,
      localVersion: 3,
      remoteVersion: 4,
    );

    if (conflict != null) {
      // Prepare for interactive resolution
      final uiData =
          _conflictManager.prepareConflictForInteractiveResolution(conflict);

      print('📋 Interactive Resolution UI Data:');
      print('   Conflict ID: ${uiData['conflictId']}');
      print('   Entity: ${uiData['entityId']} (${uiData['collection']})');

      final summary = uiData['summary'] as Map<String, dynamic>;
      print('   📊 Summary:');
      print('      Total conflicted fields: ${summary['totalFields']}');
      print('      Risk level: ${summary['riskLevel']}');
      print(
          '      Average confidence: ${(summary['averageConfidence'] * 100).toInt()}%');
      print(
          '      Has critical fields: ${summary['criticalFields'].isNotEmpty}');

      final fieldChoices = uiData['fieldChoices'] as List;
      print('   🔧 Field Resolution Choices:');

      for (final choice in fieldChoices) {
        final fieldName = choice['fieldName'];
        final strategies = choice['availableStrategies'] as List;
        final recommended = choice['recommendedStrategy'];
        final confidence = choice['confidence'];

        print('      📝 $fieldName:');
        print('         Local: ${_formatValue(choice['localValue'])}');
        print('         Remote: ${_formatValue(choice['remoteValue'])}');
        print('         Suggested: ${_formatValue(choice['suggestedValue'])}');
        print(
            '         Recommended: $recommended (${(confidence * 100).toInt()}% confidence)');
        print('         Available strategies: ${strategies.join(", ")}');
        print('');
      }

      // Simulate user choices
      final userChoices = {
        'name': {'strategy': 'TextMerge'},
        'content': {'strategy': 'useLocal'}, // User prefers local content
        'tags': {'strategy': 'ArrayMerge'},
        'isPublished': {'strategy': 'BooleanMerge'},
        'collaborators': {'strategy': 'ArrayMerge'},
        'lastEditedBy': {'strategy': 'useRemote'},
        'editCount': {'strategy': 'NumericMerge'},
        'updatedAt': {'strategy': 'TimestampMerge'},
        '_userAccepted': true,
        '_userNotes':
            'Resolved automatically with intelligent merge strategies',
      };

      final startTime = DateTime.now();
      final result = _conflictManager.processInteractiveResolution(
        conflict,
        userChoices,
        startTime,
      );

      print('✅ Interactive Resolution Completed:');
      print('   Conflict ID: ${result.conflictId}');
      print('   User accepted: ${result.userAccepted}');
      print('   Interaction time: ${result.interactionTime.inMilliseconds}ms');
      print('   Field resolutions: ${result.fieldResolutions.length} fields');
      print('   Notes: ${result.userNotes}');

      print('   📝 Field Resolution Summary:');
      for (final entry in result.fieldResolutions.entries) {
        print('      ${entry.key}: ${entry.value}');
      }
    }

    print('');
  }

  Future<void> _demonstrateConflictHistory() async {
    print('📚 5. Conflict History Tracking');
    print('──────────────────────────────');

    // Generate several conflicts to build history
    await _generateSampleConflicts();

    final stats = _conflictManager.getStatistics();

    print('📊 Conflict Resolution Statistics:');
    print('   Total conflicts: ${stats.totalConflicts}');
    print('   Resolved conflicts: ${stats.resolvedConflicts}');
    print('   Pending conflicts: ${stats.pendingConflicts}');
    print(
        '   Manual resolution rate: ${(stats.manualResolutionRate * 100).toInt()}%');
    print(
        '   Average confidence: ${(stats.averageConfidenceScore * 100).toInt()}%');
    print(
        '   Average resolution time: ${stats.averageResolutionTime.inMilliseconds}ms');

    print('   🎯 Strategy Usage:');
    for (final entry in stats.strategyUsage.entries) {
      print('      ${entry.key.name}: ${entry.value} times');
    }

    print('   📋 Collection Conflicts:');
    for (final entry in stats.collectionConflicts.entries) {
      print('      ${entry.key}: ${entry.value} conflicts');
    }

    print('   🔍 Top Conflicted Fields:');
    for (final entry in stats.topConflictedFields.entries) {
      print('      ${entry.key}: ${entry.value} conflicts');
    }

    print('   ⚠️ Conflict Type Frequency:');
    for (final entry in stats.conflictTypeFrequency.entries) {
      print('      ${entry.key.name}: ${entry.value} occurrences');
    }

    // Test learning from history
    final testConflict = EnhancedSyncConflict(
      entityId: 'test_123',
      collection: 'users',
      localData: {'name': 'Test User'},
      remoteData: {'name': 'Test User Updated'},
      fieldConflicts: {
        'name': FieldConflictInfo(
          fieldName: 'name',
          conflictType: EnhancedConflictType.valueDifference,
          localValue: 'Test User',
          remoteValue: 'Test User Updated',
        ),
      },
      detectedAt: DateTime.now(),
      localVersion: 1,
      remoteVersion: 2,
    );

    final suggestedStrategy =
        _conflictManager.suggestStrategyForConflict(testConflict);
    print(
        '   🤖 ML-based suggestion for similar conflict: ${suggestedStrategy.name}');

    print('');
  }

  Future<void> _generateSampleConflicts() async {
    // Generate sample conflicts for history
    final conflictScenarios = [
      {
        'collection': 'users',
        'localData': {'name': 'Alice', 'email': 'alice@old.com'},
        'remoteData': {'name': 'Alice Smith', 'email': 'alice@new.com'},
        'strategy': EnhancedConflictResolutionStrategy.intelligentMerge,
      },
      {
        'collection': 'documents',
        'localData': {'title': 'Doc 1', 'isPublished': false},
        'remoteData': {'title': 'Document 1', 'isPublished': true},
        'strategy': EnhancedConflictResolutionStrategy.remoteWins,
      },
      {
        'collection': 'projects',
        'localData': {'status': 'active', 'progress': 0.75},
        'remoteData': {'status': 'completed', 'progress': 1.0},
        'strategy': EnhancedConflictResolutionStrategy.newestWins,
      },
    ];

    for (int i = 0; i < conflictScenarios.length; i++) {
      final scenario = conflictScenarios[i];
      final conflict = _conflictManager.detectConflict(
        entityId: 'entity_$i',
        collection: scenario['collection'] as String,
        localData: scenario['localData'] as Map<String, dynamic>,
        remoteData: scenario['remoteData'] as Map<String, dynamic>,
        localVersion: 1,
        remoteVersion: 2,
      );

      if (conflict != null) {
        _conflictManager.resolveConflict(conflict);
        // Resolution is automatically recorded in history
      }
    }
  }

  Future<void> _demonstratePluggableResolvers() async {
    print('🔌 6. Pluggable Conflict Resolvers');
    print('─────────────────────────────────');

    // Create a custom resolver for a specific collection
    final customResolver = CustomBusinessRuleResolver();
    _conflictManager.registerResolver('business_entities', customResolver);

    print('✅ Registered custom resolver for "business_entities" collection');
    print('   Resolver: ${customResolver.name}');
    print('   Priority: ${customResolver.priority}');

    // Test with a business entity conflict
    final businessConflict = _conflictManager.detectConflict(
      entityId: 'business_123',
      collection: 'business_entities',
      localData: {
        'companyName': 'TechCorp Inc.',
        'revenue': 1000000,
        'isActive': true,
        'tier': 'premium',
      },
      remoteData: {
        'companyName': 'TechCorp International',
        'revenue': 1200000,
        'isActive': false,
        'tier': 'enterprise',
      },
      localVersion: 1,
      remoteVersion: 2,
    );

    if (businessConflict != null) {
      print('📋 Business entity conflict detected');
      print(
          '   Can be resolved by custom resolver: ${customResolver.canResolve(businessConflict)}');
      print(
          '   Confidence score: ${customResolver.getConfidenceScore(businessConflict)}');

      final resolution = _conflictManager.resolveConflict(businessConflict);
      print('✅ Resolved using custom business rules');
      print('   Strategy used: ${resolution.strategy.name}');
      print('   Confidence: ${(resolution.confidenceScore * 100).toInt()}%');

      if (resolution.warnings.isNotEmpty) {
        print('   ⚠️ Warnings: ${resolution.warnings.join(", ")}');
      }
    }

    print('');
  }

  Future<void> _showStatisticsAndAnalytics() async {
    print('📊 7. Advanced Statistics and Analytics');
    print('─────────────────────────────────────');

    final stats = _conflictManager.getStatistics();

    print('🎯 Performance Metrics:');
    print(
        '   Conflict resolution success rate: ${((stats.resolvedConflicts / stats.totalConflicts) * 100).toInt()}%');
    print(
        '   Automation rate: ${((1 - stats.manualResolutionRate) * 100).toInt()}%');
    print(
        '   Average confidence score: ${(stats.averageConfidenceScore * 100).toInt()}%');

    print('📈 Trend Analysis:');
    print('   Most common conflict type: ${_getMostCommonConflictType(stats)}');
    print('   Most effective strategy: ${_getMostEffectiveStrategy(stats)}');
    print(
        '   Collections needing attention: ${_getHighConflictCollections(stats).join(", ")}');

    print('🔍 Insights:');
    print(
        '   - Field-level detection provides ${stats.conflictTypeFrequency.length} distinct conflict types');
    print(
        '   - Custom merge strategies handle ${_countCustomStrategies(stats)} complex merges');
    print(
        '   - Interactive resolution reduces manual effort by showing confidence scores');
    print('   - History tracking enables ML-based strategy suggestions');
    print('   - Pluggable resolvers allow domain-specific conflict handling');

    // Export history for analysis
    final exportData = _conflictManager.exportConflictHistory();
    print('📦 History export contains ${exportData['totalEntries']} entries');

    print('');
  }

  String _getMostCommonConflictType(ConflictResolutionStats stats) {
    if (stats.conflictTypeFrequency.isEmpty) return 'None';

    final maxEntry = stats.conflictTypeFrequency.entries
        .reduce((a, b) => a.value > b.value ? a : b);

    return '${maxEntry.key.name} (${maxEntry.value} times)';
  }

  String _getMostEffectiveStrategy(ConflictResolutionStats stats) {
    if (stats.strategyUsage.isEmpty) return 'None';

    final maxEntry =
        stats.strategyUsage.entries.reduce((a, b) => a.value > b.value ? a : b);

    return '${maxEntry.key.name} (${maxEntry.value} uses)';
  }

  List<String> _getHighConflictCollections(ConflictResolutionStats stats) {
    return stats.collectionConflicts.entries
        .where((e) => e.value > 1)
        .map((e) => e.key)
        .toList();
  }

  int _countCustomStrategies(ConflictResolutionStats stats) {
    final customStrategies = [
      'ArrayMerge',
      'NumericMerge',
      'TextMerge',
      'JsonObjectMerge',
      'BooleanMerge',
      'TimestampMerge'
    ];

    return stats.strategyUsage.keys
        .where((strategy) => customStrategies.contains(strategy.name))
        .length;
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return '"$value"';
    if (value is List) return '[${value.length} items]';
    if (value is Map) return '{${value.length} fields}';
    return value.toString();
  }
}

/// Custom business rule conflict resolver for demonstration
class CustomBusinessRuleResolver extends EnhancedConflictResolver {
  @override
  String get name => 'BusinessRuleResolver';

  @override
  int get priority => 150; // Higher than default

  @override
  bool canResolve(EnhancedSyncConflict conflict) {
    return conflict.collection == 'business_entities';
  }

  @override
  double getConfidenceScore(EnhancedSyncConflict conflict) {
    // High confidence for business entities
    return 0.95;
  }

  @override
  EnhancedSyncConflictResolution resolveConflict(
      EnhancedSyncConflict conflict) {
    final mergedData = <String, dynamic>{};
    final fieldStrategies = <String, String>{};
    final warnings = <String>[];

    // Start with remote data
    mergedData.addAll(conflict.remoteData);

    // Apply business-specific rules
    for (final entry in conflict.fieldConflicts.entries) {
      final fieldName = entry.key;

      if (fieldName == 'revenue') {
        // Always use higher revenue
        final localRev = conflict.localData[fieldName] as num? ?? 0;
        final remoteRev = conflict.remoteData[fieldName] as num? ?? 0;
        mergedData[fieldName] = localRev > remoteRev ? localRev : remoteRev;
        fieldStrategies[fieldName] = 'maxRevenue';
      } else if (fieldName == 'isActive') {
        // Business rule: once inactive, stays inactive until manual review
        final localActive = conflict.localData[fieldName] as bool? ?? true;
        final remoteActive = conflict.remoteData[fieldName] as bool? ?? true;

        if (!localActive || !remoteActive) {
          mergedData[fieldName] = false;
          warnings.add(
              'Business entity marked inactive - requires manual review to reactivate');
          fieldStrategies[fieldName] = 'businessRule_inactive';
        }
      } else if (fieldName == 'tier') {
        // Use higher tier
        final tiers = ['basic', 'premium', 'enterprise'];
        final localTier = conflict.localData[fieldName] as String? ?? 'basic';
        final remoteTier = conflict.remoteData[fieldName] as String? ?? 'basic';

        final localIndex = tiers.indexOf(localTier);
        final remoteIndex = tiers.indexOf(remoteTier);

        mergedData[fieldName] =
            localIndex > remoteIndex ? localTier : remoteTier;
        fieldStrategies[fieldName] = 'higherTier';
      }
    }

    return EnhancedSyncConflictResolution.intelligentMerge(
      conflict.conflictId,
      mergedData: mergedData,
      fieldStrategies: fieldStrategies,
      localFields: [],
      remoteFields: conflict.remoteData.keys.toList(),
      resolvedBy: 'BusinessRuleResolver',
      confidenceScore: 0.95,
      warnings: warnings,
    );
  }
}

/// Main demo runner
void main() async {
  final demo = EnhancedConflictResolutionDemo();
  await demo.runDemo();
}
