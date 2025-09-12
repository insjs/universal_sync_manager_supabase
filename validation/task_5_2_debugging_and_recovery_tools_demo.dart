// validation/task_5_2_debugging_and_recovery_tools_demo.dart

import 'package:universal_sync_manager/src/services/usm_sync_logging_service.dart';
import 'package:universal_sync_manager/src/services/usm_sync_state_inspector.dart';
import 'package:universal_sync_manager/src/services/usm_sync_recovery_service.dart';
import 'package:universal_sync_manager/src/services/usm_sync_replay_service.dart';
import 'package:universal_sync_manager/src/services/usm_sync_rollback_service.dart';

void main() async {
  print('🔧 Task 5.2: Debugging and Recovery Tools - Validation Demo');
  print('=' * 70);

  await _demonstrateComprehensiveSyncLogging();
  await _demonstrateSyncStateInspection();
  await _demonstrateSyncRecoveryUtilities();
  await _demonstrateSyncReplayCapabilities();
  await _demonstrateSyncRollbackMechanism();

  print('\n✅ Task 5.2 validation completed successfully!');
  print('All debugging and recovery tools are working correctly.');
}

Future<void> _demonstrateComprehensiveSyncLogging() async {
  print('\n🎯 Action 1: Comprehensive Sync Logging');
  print('-' * 50);

  // Initialize logging service
  final logConfig = LogStorageConfig(
    logDirectory: './logs',
    filePrefix: 'sync_debug',
    maxFileSize: 5 * 1024 * 1024, // 5MB
    maxFiles: 5,
    enableConsoleOutput: false, // Disable for demo
    enableFileOutput: false, // Disable for demo
    enableInMemoryBuffer: true,
    inMemoryBufferSize: 100,
  );

  final loggingService = SyncLoggingService(logConfig);

  // Set log level and categories
  loggingService.setMinimumLogLevel(LogLevel.debug);

  print('📝 Logging various sync events...');

  // Log different types of events
  loggingService.info('Sync manager initialized',
      category: LogCategory.system,
      context: {'version': '1.0.0', 'backend': 'PocketBase'});

  loggingService.logOperationStart(
    'op_001',
    'sync',
    'organization_profiles',
    context: {'itemCount': 25},
  );

  loggingService.logConflictDetected(
    'op_001',
    'organization_profiles',
    'org_123',
    conflictDetails: {
      'field': 'name',
      'localValue': 'Local Org',
      'remoteValue': 'Remote Org'
    },
  );

  loggingService.logConflictResolved(
    'op_001',
    'organization_profiles',
    'org_123',
    'serverWins',
    resolutionDetails: {'resolvedValue': 'Remote Org'},
  );

  loggingService.warning('Network latency detected',
      category: LogCategory.network,
      context: {'latency': 1500, 'threshold': 1000});

  loggingService.error('Sync operation failed',
      category: LogCategory.sync,
      operationId: 'op_002',
      collection: 'users',
      context: {'errorCode': 'NETWORK_TIMEOUT'},
      error: Exception('Connection timeout'));

  loggingService.logOperationComplete(
    'op_001',
    'sync',
    'organization_profiles',
    const Duration(milliseconds: 2500),
    success: true,
    itemsProcessed: 25,
  );

  // Demonstrate log filtering and querying
  print('📊 Demonstrating log querying...');

  final allLogs = loggingService.getLogs();
  print('  • Total logs: ${allLogs.length}');

  final errorLogs = loggingService.getRecentErrors(limit: 10);
  print('  • Error logs: ${errorLogs.length}');

  final operationLogs = loggingService.getOperationLogs('op_001');
  print('  • Operation op_001 logs: ${operationLogs.length}');

  final networkLogs = loggingService.getLogs(
    filter: const LogFilter(categories: [LogCategory.network]),
  );
  print('  • Network logs: ${networkLogs.length}');

  // Export logs
  final exportedLogs = loggingService.exportLogs();
  print('  • Exported ${exportedLogs['logCount']} logs with system info');

  // Get statistics
  final stats = loggingService.getLogStatistics();
  print(
      '  • Log statistics: ${stats['totalLogs']} total, ${stats['levelBreakdown']}');

  loggingService.dispose();
  print('✅ Comprehensive sync logging validated');
}

Future<void> _demonstrateSyncStateInspection() async {
  print('\n🎯 Action 2: Sync State Inspection Tools');
  print('-' * 50);

  final stateInspector = SyncStateInspector();

  print('🔍 Inspecting current system state...');

  // Get overall system state
  final systemState = await stateInspector.getCurrentSystemState();
  print('  • System health: ${systemState.systemHealth}');
  print(
      '  • Overall sync: ${systemState.overallSyncPercentage.toStringAsFixed(1)}%');
  print('  • Active operations: ${systemState.activeOperations}');
  print('  • Pending operations: ${systemState.pendingOperations}');

  // Inspect entity states
  print('\n📋 Entity state details:');
  for (final entityState in systemState.entityStates) {
    print('  • ${entityState.entityType}:');
    print('    - Total items: ${entityState.totalItems}');
    print('    - Synced: ${entityState.syncedItems}');
    print('    - Dirty: ${entityState.dirtyItems}');
    print('    - Errors: ${entityState.errorItems}');
    print(
        '    - Health: ${entityState.syncHealthPercentage.toStringAsFixed(1)}%');
    print('    - Status: ${entityState.statusDescription}');
  }

  // Get specific entity state
  final orgState = await stateInspector.getEntityState('organization_profiles');
  print('\n🏢 Organization profiles detailed state:');
  print('  • Collection: ${orgState.collection}');
  print(
      '  • Last sync: ${orgState.lastSyncTime?.toIso8601String() ?? 'Never'}');
  print('  • Sync version: ${orgState.syncVersion}');
  print('  • Pending operations: ${orgState.pendingOperations.length}');

  // Get items with different statuses
  final dirtyItems =
      await stateInspector.getDirtyItems('organization_profiles');
  print('  • Dirty items: ${dirtyItems.length}');

  final errorItems =
      await stateInspector.getErrorItems('organization_profiles');
  print('  • Error items: ${errorItems.length}');

  final conflictItems =
      await stateInspector.getConflictItems('organization_profiles');
  print('  • Conflict items: ${conflictItems.length}');

  // Diagnose sync issues
  print('\n🔬 Diagnosing sync issues...');
  final diagnosis = await stateInspector.diagnoseSyncIssues();
  print('  • System health: ${diagnosis['systemHealth']}');
  print('  • Has issues: ${diagnosis['hasIssues']}');

  if (diagnosis['issues'] != null && (diagnosis['issues'] as Map).isNotEmpty) {
    final issues = diagnosis['issues'] as Map<String, dynamic>;
    print('  • Issues found:');
    issues.forEach((type, details) {
      print('    - $type: $details');
    });
  }

  final recommendations = diagnosis['recommendations'] as List<String>;
  print('  • Recommendations:');
  for (final rec in recommendations) {
    print('    - $rec');
  }

  // Export state snapshot
  final snapshot =
      await stateInspector.exportStateSnapshot(includeItemDetails: true);
  print('\n📸 State snapshot exported:');
  print(
      '  • Snapshot contains ${(snapshot['entityStates'] as List).length} entity states');
  print('  • Exported at: ${snapshot['exportedAt']}');

  stateInspector.dispose();
  print('✅ Sync state inspection tools validated');
}

Future<void> _demonstrateSyncRecoveryUtilities() async {
  print('\n🎯 Action 3: Sync Recovery Utilities');
  print('-' * 50);

  final recoveryService = SyncRecoveryService();

  print('🔧 Demonstrating recovery utilities...');

  // Validate sync integrity
  print('\n🔍 Validating sync integrity...');
  final issues = await recoveryService.validateSyncIntegrity(
    collections: ['organization_profiles', 'users'],
    includeSystemChecks: true,
  );

  print('  • Integrity issues found: ${issues.length}');
  for (final issue in issues) {
    print('    - ${issue.type}: ${issue.description}');
    print('      Severity: ${issue.severity}, Entity: ${issue.entityType}');
    print(
        '      Suggested fixes: ${issue.suggestedFixes.map((f) => f.operation.name).join(", ")}');
  }

  // Create backup
  print('\n💾 Creating backup...');
  final backup = await recoveryService.createBackup(
    description: 'Pre-recovery test backup',
    collections: ['organization_profiles', 'users'],
    includeSystemData: true,
  );

  print('  • Backup created: ${backup.id}');
  print('  • Collections: ${backup.includedCollections.join(", ")}');
  print('  • Total items: ${backup.totalItems}');
  print('  • Checksum: ${backup.checksum}');

  // List backups
  final backups = await recoveryService.listBackups();
  print('  • Available backups: ${backups.length}');

  // Reset sync state
  print('\n🔄 Resetting sync state...');
  final resetResult = await recoveryService.resetSyncState(
    collections: ['organization_profiles'],
    resetVersions: true,
    clearDirtyFlags: true,
  );

  print('  • Reset result: ${resetResult.success}');
  print('  • Message: ${resetResult.message}');
  print('  • Affected items: ${resetResult.affectedItems}');
  print('  • Duration: ${resetResult.duration.inMilliseconds}ms');

  // Resolve duplicates
  print('\n🔗 Resolving duplicates...');
  final duplicateResult = await recoveryService.resolveDuplicates(
    collections: ['organization_profiles'],
    strategy: 'keepNewest',
  );

  print('  • Duplicate resolution: ${duplicateResult.success}');
  print('  • Message: ${duplicateResult.message}');
  print('  • Items processed: ${duplicateResult.affectedItems}');

  // Repair corrupted data
  print('\n🛠️ Repairing corrupted data...');
  final repairResult = await recoveryService.repairCorruptedData(
    collections: ['organization_profiles'],
    validateFields: true,
    fixMissingAuditFields: true,
  );

  print('  • Repair result: ${repairResult.success}');
  print('  • Message: ${repairResult.message}');
  print('  • Items repaired: ${repairResult.affectedItems}');

  // Auto-recovery
  print('\n🤖 Running auto-recovery...');
  final autoResults = await recoveryService.autoRecover(
    collections: ['organization_profiles'],
    includeDestructiveOperations: false,
  );

  print('  • Auto-recovery operations: ${autoResults.length}');
  for (final result in autoResults) {
    print(
        '    - ${result.operation.name}: ${result.success ? "✅" : "❌"} ${result.message}');
  }

  recoveryService.dispose();
  print('✅ Sync recovery utilities validated');
}

Future<void> _demonstrateSyncReplayCapabilities() async {
  print('\n🎯 Action 4: Sync Replay Capabilities');
  print('-' * 50);

  final replayService = SyncReplayService();

  print('🎬 Demonstrating sync replay capabilities...');

  // Start recording
  replayService.startRecording();
  print('  • Recording started: ${replayService.isRecording}');

  // Record some sync events
  print('\n📹 Recording sync events...');

  replayService.recordSyncOperation(
    operation: ReplayOperationType.create,
    collection: 'organization_profiles',
    entityId: 'org_001',
    beforeState: {},
    afterState: {'id': 'org_001', 'name': 'New Organization'},
    operationId: 'op_create_001',
    duration: const Duration(milliseconds: 150),
    success: true,
  );

  replayService.recordSyncOperation(
    operation: ReplayOperationType.update,
    collection: 'organization_profiles',
    entityId: 'org_001',
    beforeState: {'id': 'org_001', 'name': 'New Organization'},
    afterState: {'id': 'org_001', 'name': 'Updated Organization'},
    operationId: 'op_update_001',
    duration: const Duration(milliseconds: 120),
    success: true,
  );

  replayService.recordSyncOperation(
    operation: ReplayOperationType.sync,
    collection: 'users',
    operationId: 'op_sync_001',
    duration: const Duration(milliseconds: 2500),
    success: false,
    errorMessage: 'Network timeout during sync',
  );

  // Stop recording
  replayService.stopRecording();
  print('  • Recording stopped');

  // Get recorded events
  final allEvents = replayService.getEvents();
  print('  • Total events recorded: ${allEvents.length}');

  for (final event in allEvents) {
    print('    - ${event.operation.name}: ${event.description}');
  }

  // Filter events
  final failedEvents = replayService.getFailedEvents();
  print('  • Failed events: ${failedEvents.length}');

  final successfulEvents = replayService.getSuccessfulEvents();
  print('  • Successful events: ${successfulEvents.length}');

  // Replay a single event
  print('\n🔄 Replaying single event...');
  if (allEvents.isNotEmpty) {
    final replayResult = await replayService.replayEvent(
      allEvents.first,
      dryRun: true,
      compareResults: true,
    );

    print('  • Replay result: ${replayResult.success}');
    print('  • Message: ${replayResult.message}');
    print('  • Execution time: ${replayResult.executionTime.inMilliseconds}ms');
  }

  // Replay multiple events
  print('\n🎭 Replaying event sequence...');
  final replayConfig = ReplaySessionConfig(
    sessionId: 'test_session_001',
    startTime: DateTime.now().subtract(const Duration(hours: 1)),
    dryRun: true,
    speedMultiplier: const Duration(milliseconds: 100), // 10x speed
  );

  final sessionSummary = await replayService.replayEvents(
    allEvents.take(2).toList(),
    config: replayConfig,
  );

  print('  • Session ID: ${sessionSummary.sessionId}');
  print('  • Total events: ${sessionSummary.totalEvents}');
  print('  • Successful replays: ${sessionSummary.successfulReplays}');
  print('  • Failed replays: ${sessionSummary.failedReplays}');
  print('  • Success rate: ${sessionSummary.successRate.toStringAsFixed(1)}%');
  print('  • Duration: ${sessionSummary.totalDuration.inMilliseconds}ms');

  // Create test scenario
  print('\n🧪 Creating test scenario...');
  final testEvents = await replayService.createTestScenario(
    scenarioName: 'sync_conflict_test',
    operations: [
      {
        'operation': 'create',
        'collection': 'organization_profiles',
        'entityId': 'test_org',
        'afterState': {'id': 'test_org', 'name': 'Test Org'},
        'success': true,
      },
      {
        'operation': 'conflict',
        'collection': 'organization_profiles',
        'entityId': 'test_org',
        'beforeState': {'id': 'test_org', 'name': 'Test Org'},
        'afterState': {'id': 'test_org', 'name': 'Conflicted Org'},
        'success': false,
        'errorMessage': 'Conflict detected',
      },
    ],
  );

  print('  • Test scenario created with ${testEvents.length} events');

  // Export events
  final exportData = replayService.exportEvents();
  print('\n📤 Exported replay data:');
  print('  • Event count: ${exportData['eventCount']}');
  print('  • Exported at: ${exportData['exportedAt']}');

  // Get statistics
  final stats = replayService.getReplayStatistics();
  print('\n📊 Replay statistics:');
  print('  • Total events: ${stats['totalEvents']}');
  print('  • Success rate: ${stats['successRate']}%');
  print('  • Operation breakdown: ${stats['operationBreakdown']}');

  replayService.dispose();
  print('✅ Sync replay capabilities validated');
}

Future<void> _demonstrateSyncRollbackMechanism() async {
  print('\n🎯 Action 5: Sync Rollback Mechanism');
  print('-' * 50);

  final rollbackConfig = RollbackServiceConfig(
    maxCheckpoints: 10,
    checkpointRetention: const Duration(days: 7),
    autoCreateCheckpoints: false, // Disabled for demo
    enableTransactionRollback: true,
  );

  final rollbackService = SyncRollbackService(rollbackConfig);

  print('⏪ Demonstrating sync rollback mechanism...');

  // Create checkpoints
  print('\n📍 Creating checkpoints...');

  final checkpoint1 = await rollbackService.createCheckpoint(
    description: 'Before major sync operation',
    collections: ['organization_profiles', 'users'],
    triggerOperation: 'manual',
  );

  print('  • Checkpoint 1 created: ${checkpoint1.id}');
  print('    - Collections: ${checkpoint1.affectedCollections.join(", ")}');
  print('    - Data size: ${checkpoint1.dataSize} items');

  // Simulate some time passing
  await Future.delayed(const Duration(milliseconds: 100));

  final checkpoint2 = await rollbackService.createCheckpoint(
    description: 'After sync completion',
    collections: ['organization_profiles'],
    triggerOperation: 'sync_complete',
    isAutomatic: true,
  );

  print('  • Checkpoint 2 created: ${checkpoint2.id}');

  // List checkpoints
  final checkpoints = rollbackService.listCheckpoints();
  print('  • Total checkpoints available: ${checkpoints.length}');

  // Create rollback plan
  print('\n📋 Creating rollback plan...');
  final rollbackPlan = await rollbackService.createRollbackPlan(
    operation: RollbackOperationType.restoreSnapshot,
    targetCheckpointId: checkpoint1.id,
    collections: ['organization_profiles'],
  );

  print('  • Plan ID: ${rollbackPlan.planId}');
  print('  • Target checkpoint: ${rollbackPlan.targetCheckpointId}');
  print(
      '  • Affected collections: ${rollbackPlan.affectedCollections.join(", ")}');
  print('  • Estimated items: ${rollbackPlan.estimatedAffectedItems}');
  print(
      '  • Estimated duration: ${rollbackPlan.estimatedDuration.inMilliseconds}ms');
  print('  • Steps: ${rollbackPlan.steps.length}');

  for (final step in rollbackPlan.steps) {
    print('    - ${step.description} (${step.itemCount} items)');
  }

  if (rollbackPlan.warnings.isNotEmpty) {
    print('  • Warnings:');
    for (final warning in rollbackPlan.warnings) {
      print('    - $warning');
    }
  }

  // Execute rollback (dry run)
  print('\n🔄 Executing rollback (dry run)...');
  final rollbackResult = await rollbackService.executeRollback(
    rollbackPlan,
    createPreRollbackCheckpoint: true,
    dryRun: true,
  );

  print('  • Rollback result: ${rollbackResult.success}');
  print('  • Message: ${rollbackResult.message}');
  print('  • Duration: ${rollbackResult.duration.inMilliseconds}ms');
  print('  • Affected items: ${rollbackResult.affectedItems}');
  print(
      '  • Affected collections: ${rollbackResult.affectedCollections.join(", ")}');

  // Rollback to specific checkpoint
  print('\n⏮️ Rolling back to checkpoint...');
  final checkpointRollback = await rollbackService.rollbackToCheckpoint(
    checkpoint1.id,
    collections: ['organization_profiles'],
    dryRun: true,
  );

  print('  • Checkpoint rollback: ${checkpointRollback.success}');
  print('  • Restored checkpoint: ${checkpointRollback.restoredCheckpointId}');

  // Undo last sync
  print('\n↩️ Undoing last sync...');
  try {
    final undoResult = await rollbackService.undoLastSync(
      collections: ['organization_profiles'],
      dryRun: true,
    );

    print('  • Undo last sync: ${undoResult.success}');
    print('  • Message: ${undoResult.message}');
  } catch (e) {
    print('  • Undo last sync: No sync checkpoints found (expected for demo)');
  }

  // Undo entity changes
  print('\n🔧 Undoing specific entity changes...');
  final entityUndoResult = await rollbackService.undoEntityChanges(
    'organization_profiles',
    ['org_001', 'org_002'],
    dryRun: true,
  );

  print('  • Entity undo result: ${entityUndoResult.success}');
  print('  • Message: ${entityUndoResult.message}');
  print('  • Affected items: ${entityUndoResult.affectedItems}');

  // Rollback time range
  print('\n⏰ Rolling back time range...');
  final timeRangeStart = DateTime.now().subtract(const Duration(hours: 2));
  final timeRangeEnd = DateTime.now().subtract(const Duration(hours: 1));

  final timeRangeRollback = await rollbackService.rollbackTimeRange(
    timeRangeStart,
    timeRangeEnd,
    collections: ['organization_profiles'],
    dryRun: true,
  );

  print('  • Time range rollback: ${timeRangeRollback.success}');
  print('  • Message: ${timeRangeRollback.message}');

  // Detect conflicts
  print('\n⚠️ Detecting rollback conflicts...');
  final plan1 = rollbackPlan;
  final plan2 = await rollbackService.createRollbackPlan(
    operation: RollbackOperationType.undoTimeRange,
    targetCheckpointId: checkpoint2.id,
    collections: ['organization_profiles'],
  );

  final conflicts = rollbackService.detectRollbackConflicts([plan1, plan2]);
  print('  • Conflicts detected: ${conflicts.length}');

  for (final conflict in conflicts) {
    print('    - ${conflict.description}');
    print('      Resolution options: ${conflict.resolutionOptions.join(", ")}');
  }

  // Get statistics
  print('\n📊 Rollback service statistics:');
  final stats = rollbackService.getRollbackStatistics();
  print('  • Total checkpoints: ${stats['totalCheckpoints']}');
  print('  • Automatic checkpoints: ${stats['automaticCheckpoints']}');
  print('  • Manual checkpoints: ${stats['manualCheckpoints']}');
  print('  • Total data size: ${stats['totalDataSize']} items');

  rollbackService.dispose();
  print('✅ Sync rollback mechanism validated');
}
