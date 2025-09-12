// test/task_4_2_enhanced_conflict_resolution_test.dart

import 'package:test/test.dart';

import '../lib/src/services/usm_enhanced_conflict_resolver.dart';
import '../lib/src/services/usm_enhanced_conflict_resolution_manager.dart';
import '../lib/src/services/usm_custom_merge_strategies.dart';
import '../lib/src/services/usm_conflict_history_service.dart';
import '../lib/src/services/usm_interactive_conflict_ui.dart';

void main() {
  group('Task 4.2: Enhanced Conflict Resolution Tests', () {
    late EnhancedConflictResolutionManager conflictManager;

    setUp(() {
      conflictManager = EnhancedConflictResolutionManager();
    });

    tearDown(() {
      conflictManager.dispose();
    });

    test('Action 1: Pluggable conflict resolution strategies', () {
      // Test registering custom resolver
      final customResolver = TestConflictResolver();
      conflictManager.registerResolver('test_collection', customResolver);

      // Create test conflict
      final conflict = conflictManager.detectConflict(
        entityId: 'test_1',
        collection: 'test_collection',
        localData: {'name': 'Local Name'},
        remoteData: {'name': 'Remote Name'},
        localVersion: 1,
        remoteVersion: 2,
      );

      expect(conflict, isNotNull);
      expect(customResolver.canResolve(conflict!), isTrue);

      // Test resolution
      final resolution = conflictManager.resolveConflict(conflict);
      expect(resolution.strategy,
          equals(EnhancedConflictResolutionStrategy.custom));
      expect(resolution.resolvedBy, equals('TestResolver'));
    });

    test('Action 2: Field-level conflict detection with enhanced metadata', () {
      final conflict = conflictManager.detectConflict(
        entityId: 'user_1',
        collection: 'users',
        localData: {
          'name': 'John Smith',
          'age': 25,
          'isActive': true,
          'tags': ['user', 'premium'],
          'lastLoginAt': '2024-01-15T10:00:00Z',
        },
        remoteData: {
          'name': 'John M. Smith',
          'age': 26,
          'isActive': false,
          'tags': ['user', 'admin'],
          'lastLoginAt': '2024-01-15T14:00:00Z',
          'department': 'Engineering',
        },
        localVersion: 1,
        remoteVersion: 2,
      );

      expect(conflict, isNotNull);
      expect(conflict!.fieldConflicts.length, equals(6));

      // Test field conflict analysis
      final nameConflict = conflict.fieldConflicts['name']!;
      expect(nameConflict.conflictType,
          equals(EnhancedConflictType.valueDifference));
      expect(nameConflict.possibleResolutions, contains('TextMerge'));
      expect(nameConflict.confidenceScore, greaterThan(0.5));

      final isActiveConflict = conflict.fieldConflicts['isActive']!;
      expect(isActiveConflict.conflictType,
          equals(EnhancedConflictType.semanticConflict));
      expect(isActiveConflict.semanticReason, isNotNull);

      final tagsConflict = conflict.fieldConflicts['tags']!;
      expect(tagsConflict.conflictType,
          equals(EnhancedConflictType.arrayElementConflict));

      final departmentConflict = conflict.fieldConflicts['department']!;
      expect(departmentConflict.conflictType,
          equals(EnhancedConflictType.remoteOnly));
    });

    test('Action 3: User-interactive conflict resolution UI', () {
      final conflict = EnhancedSyncConflict(
        entityId: 'doc_1',
        collection: 'documents',
        localData: {'title': 'Document Title', 'content': 'Local content'},
        remoteData: {'title': 'Updated Title', 'content': 'Remote content'},
        fieldConflicts: {
          'title': FieldConflictInfo(
            fieldName: 'title',
            conflictType: EnhancedConflictType.valueDifference,
            localValue: 'Document Title',
            remoteValue: 'Updated Title',
          ),
          'content': FieldConflictInfo(
            fieldName: 'content',
            conflictType: EnhancedConflictType.valueDifference,
            localValue: 'Local content',
            remoteValue: 'Remote content',
          ),
        },
        detectedAt: DateTime.now(),
        localVersion: 1,
        remoteVersion: 2,
      );

      // Test UI preparation
      final uiData =
          conflictManager.prepareConflictForInteractiveResolution(conflict);

      expect(uiData['conflictId'], equals(conflict.conflictId));
      expect(uiData['fieldChoices'], isA<List>());

      final fieldChoices = uiData['fieldChoices'] as List;
      expect(fieldChoices.length, equals(2));

      final titleChoice =
          fieldChoices.firstWhere((c) => c['fieldName'] == 'title');
      expect(titleChoice['availableStrategies'], contains('TextMerge'));
      expect(titleChoice['recommendedStrategy'], isNotNull);

      // Test user resolution processing
      final userChoices = {
        'title': {'strategy': 'useRemote'},
        'content': {'strategy': 'useLocal'},
        '_userAccepted': true,
        '_userNotes': 'Test resolution',
      };

      final startTime = DateTime.now();
      final result = conflictManager.processInteractiveResolution(
        conflict,
        userChoices,
        startTime,
      );

      expect(result.userAccepted, isTrue);
      expect(result.userNotes, equals('Test resolution'));
      expect(result.fieldResolutions['title'], equals('useRemote'));
      expect(result.fieldResolutions['content'], equals('useLocal'));
    });

    test('Action 4: Conflict history tracking and analytics', () {
      // Generate some conflicts for history
      for (int i = 0; i < 3; i++) {
        final conflict = conflictManager.detectConflict(
          entityId: 'entity_$i',
          collection: 'test_collection',
          localData: {'field': 'local_value_$i'},
          remoteData: {'field': 'remote_value_$i'},
          localVersion: 1,
          remoteVersion: 2,
        );

        if (conflict != null) {
          conflictManager.resolveConflict(conflict);
        }
      }

      // Test statistics
      final stats = conflictManager.getStatistics();
      expect(stats.totalConflicts, equals(3));
      expect(stats.resolvedConflicts, equals(3));
      expect(stats.pendingConflicts, equals(0));
      expect(stats.strategyUsage, isNotEmpty);
      expect(stats.collectionConflicts['test_collection'], equals(3));

      // Test history export/import
      final exportData = conflictManager.exportConflictHistory();
      expect(exportData['totalEntries'], equals(3));
      expect(exportData['history'], isA<List>());

      // Test strategy suggestion
      final testConflict = EnhancedSyncConflict(
        entityId: 'test_entity',
        collection: 'test_collection',
        localData: {'field': 'test_local'},
        remoteData: {'field': 'test_remote'},
        fieldConflicts: {
          'field': FieldConflictInfo(
            fieldName: 'field',
            conflictType: EnhancedConflictType.valueDifference,
            localValue: 'test_local',
            remoteValue: 'test_remote',
          ),
        },
        detectedAt: DateTime.now(),
        localVersion: 1,
        remoteVersion: 2,
      );

      final suggestion =
          conflictManager.suggestStrategyForConflict(testConflict);
      expect(suggestion, isA<EnhancedConflictResolutionStrategy>());
    });

    test('Action 5: Custom merge strategies for complex data types', () {
      // Test all custom merge strategies
      final arrayStrategy = ArrayMergeStrategy();
      final numericStrategy = NumericMergeStrategy();
      final textStrategy = TextMergeStrategy();
      final booleanStrategy = BooleanMergeStrategy();
      final timestampStrategy = TimestampMergeStrategy();
      final jsonStrategy = JsonObjectMergeStrategy();

      // Register all strategies
      conflictManager.registerMergeStrategy(arrayStrategy);
      conflictManager.registerMergeStrategy(numericStrategy);
      conflictManager.registerMergeStrategy(textStrategy);
      conflictManager.registerMergeStrategy(booleanStrategy);
      conflictManager.registerMergeStrategy(timestampStrategy);
      conflictManager.registerMergeStrategy(jsonStrategy);

      // Test array merge
      final localArray = ['a', 'b', 'c'];
      final remoteArray = ['b', 'c', 'd'];
      final mergedArray =
          arrayStrategy.mergeValues('items', localArray, remoteArray, {});
      expect(mergedArray, hasLength(greaterThan(localArray.length)));

      // Test numeric merge
      final localCount = 10;
      final remoteCount = 15;
      final mergedCount =
          numericStrategy.mergeValues('count', localCount, remoteCount, {});
      expect(mergedCount, equals(15.0)); // Should use max for counts

      // Test text merge
      final localText = 'Short';
      final remoteText = 'Longer text';
      final mergedText =
          textStrategy.mergeValues('name', localText, remoteText, {});
      expect(
          mergedText, equals('Longer text')); // Should prefer longer for names

      // Test boolean merge
      final localActive = true;
      final remoteActive = false;
      final mergedActive = booleanStrategy
          .mergeValues('isActive', localActive, remoteActive, {});
      expect(mergedActive, isTrue); // Should OR for active flags

      // Test timestamp merge
      final localTime = '2024-01-15T10:00:00Z';
      final remoteTime = '2024-01-15T14:00:00Z';
      final mergedTime =
          timestampStrategy.mergeValues('updatedAt', localTime, remoteTime, {});
      expect(mergedTime, equals(remoteTime)); // Should use newer for updatedAt

      // Test JSON merge
      final localObj = {'a': 1, 'b': 2};
      final remoteObj = {'b': 3, 'c': 4};
      final mergedObj =
          jsonStrategy.mergeValues('config', localObj, remoteObj, {});
      expect(mergedObj['a'], equals(1)); // Local only field
      expect(mergedObj['b'], equals(3)); // Remote wins for conflicts
      expect(mergedObj['c'], equals(4)); // Remote only field
    });

    test('Integration: Complete enhanced conflict resolution workflow', () {
      var conflictDetectedCount = 0;
      var conflictResolvedCount = 0;

      // Listen to streams
      conflictManager.conflictDetected.listen((_) => conflictDetectedCount++);
      conflictManager.conflictResolved.listen((_) => conflictResolvedCount++);

      // Create and resolve complex conflict
      final conflict = conflictManager.detectConflict(
        entityId: 'integration_test',
        collection: 'test_entities',
        localData: {
          'name': 'Test Entity',
          'count': 10,
          'isActive': true,
          'tags': ['local', 'test'],
          'updatedAt': '2024-01-15T10:00:00Z',
          'metadata': {'version': 1, 'author': 'local_user'},
        },
        remoteData: {
          'name': 'Test Entity Updated',
          'count': 15,
          'isActive': false,
          'tags': ['remote', 'test'],
          'updatedAt': '2024-01-15T14:00:00Z',
          'metadata': {'version': 2, 'author': 'remote_user'},
        },
        localVersion: 1,
        remoteVersion: 2,
      );

      expect(conflict, isNotNull);
      expect(conflictDetectedCount, equals(1));

      // Resolve conflict
      final resolution = conflictManager.resolveConflict(conflict!);

      expect(resolution.strategy,
          equals(EnhancedConflictResolutionStrategy.intelligentMerge));
      expect(resolution.confidenceScore, greaterThan(0.0));
      expect(conflictResolvedCount, equals(1));

      // Verify history tracking
      final stats = conflictManager.getStatistics();
      expect(stats.totalConflicts, greaterThan(0));
      expect(stats.resolvedConflicts, greaterThan(0));
    });
  });
}

/// Test resolver for demonstration
class TestConflictResolver extends EnhancedConflictResolver {
  @override
  String get name => 'TestResolver';

  @override
  int get priority => 200;

  @override
  bool canResolve(EnhancedSyncConflict conflict) {
    return conflict.collection == 'test_collection';
  }

  @override
  EnhancedSyncConflictResolution resolveConflict(
      EnhancedSyncConflict conflict) {
    return EnhancedSyncConflictResolution(
      conflictId: conflict.conflictId,
      resolvedData: conflict.remoteData,
      strategy: EnhancedConflictResolutionStrategy.custom,
      resolvedAt: DateTime.now(),
      resolvedBy: 'TestResolver',
      confidenceScore: 1.0,
      auditTrail: {
        'strategy': 'custom',
        'resolver': 'TestResolver',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}
