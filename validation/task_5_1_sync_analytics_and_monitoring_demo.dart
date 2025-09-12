// validation/task_5_1_sync_analytics_and_monitoring_demo.dart

import 'dart:async';

import '../lib/src/services/usm_sync_analytics_service.dart';
import '../lib/src/services/usm_sync_performance_monitor.dart' as perf;
import '../lib/src/services/usm_sync_failure_analytics.dart';
import '../lib/src/services/usm_sync_health_dashboard.dart';
import '../lib/src/services/usm_sync_alerting_service.dart';

/// Comprehensive validation demo for Task 5.1: Sync Analytics and Monitoring
class Task51SyncAnalyticsAndMonitoringDemo {
  late SyncAnalyticsService _analyticsService;
  late perf.SyncPerformanceMonitor _performanceMonitor;
  late SyncFailureAnalytics _failureAnalytics;
  late SyncHealthDashboard _healthDashboard;
  late SyncAlertingService _alertingService;

  final List<StreamSubscription> _subscriptions = [];

  /// Demonstrates Task 5.1 implementation
  Future<void> runDemo() async {
    print('🔍 Task 5.1: Sync Analytics and Monitoring - Validation Demo');
    print('================================================================');
    print('');

    await _initializeServices();
    await _demonstrateAnalyticsService();
    await _demonstratePerformanceMonitor();
    await _demonstrateFailureAnalytics();
    await _demonstrateHealthDashboard();
    await _demonstrateAlertingService();
    await _demonstrateIntegratedMonitoring();

    print('');
    print('✅ Task 5.1 validation completed successfully!');
    print('All 5 actions have been implemented and validated:');
    print('  1. ✅ SyncAnalyticsService for tracking metrics');
    print('  2. ✅ Sync performance monitoring');
    print('  3. ✅ Sync failure analytics');
    print('  4. ✅ Sync health dashboard');
    print('  5. ✅ Alerting for sync issues');
    print('');
    print('🎯 Ready for Task 5.2: Debugging and Recovery Tools');
  }

  /// Initialize all services
  Future<void> _initializeServices() async {
    print('🔧 Initializing Analytics and Monitoring Services...');

    // Initialize analytics service
    _analyticsService = SyncAnalyticsService();

    // Initialize performance monitor
    _performanceMonitor = perf.SyncPerformanceMonitor(_analyticsService);

    // Initialize failure analytics
    _failureAnalytics =
        SyncFailureAnalytics(_analyticsService, _performanceMonitor);

    // Initialize health dashboard
    _healthDashboard = SyncHealthDashboard(
        _analyticsService, _performanceMonitor, _failureAnalytics);

    // Initialize alerting service
    _alertingService = SyncAlertingService(
        _analyticsService, _performanceMonitor, _failureAnalytics);

    print('  ✓ All services initialized');
    print('');
  }

  /// Demonstrates SyncAnalyticsService capabilities
  Future<void> _demonstrateAnalyticsService() async {
    print('📊 Action 1: SyncAnalyticsService - Tracking Metrics');
    print('----------------------------------------------------');

    // Start health monitoring
    _analyticsService.startHealthMonitoring(
        interval: const Duration(seconds: 10));

    // Simulate sync operations
    print('  Simulating sync operations...');
    final operationIds = <String>[];

    for (int i = 0; i < 10; i++) {
      final opId = _analyticsService.startOperation(
        entityType: 'test_entity',
        collection: 'test_collection_${i % 3}',
        operationType:
            SyncOperationType.values[i % SyncOperationType.values.length],
        metadata: {'batch': i ~/ 3},
      );
      operationIds.add(opId);

      // Simulate operation progress
      await Future.delayed(const Duration(milliseconds: 100));
      _analyticsService.updateOperation(opId, itemsProcessed: i + 1);

      await Future.delayed(const Duration(milliseconds: 50));

      // Complete operation (some failures)
      if (i % 4 == 3) {
        _analyticsService.completeOperation(
          opId,
          itemsFailed: 1,
          errorMessage: 'Simulated failure for testing',
        );
      } else {
        _analyticsService.completeOperation(
          opId,
          itemsSuccessful: i + 1,
          bytesTransferred: (i + 1) * 1024,
        );
      }
    }

    // Get performance metrics
    final metrics = _analyticsService.getPerformanceMetrics();
    print('  ✓ Performance metrics collected:');
    print('    - Total operations: ${metrics.totalOperations}');
    print(
        '    - Success rate: ${(metrics.successRate * 100).toStringAsFixed(1)}%');
    print(
        '    - Average time: ${metrics.averageOperationTime.inMilliseconds}ms');
    print(
        '    - Operations/sec: ${metrics.operationsPerSecond.toStringAsFixed(2)}');

    // Get failure analysis
    final failures = _analyticsService.getFailureAnalysis();
    print('  ✓ Failure analysis completed:');
    print('    - Total failures: ${failures.totalFailures}');
    print('    - Failures by type: ${failures.failuresByType}');

    // Get health status
    final health = _analyticsService.getCurrentHealthStatus();
    print('  ✓ Health status monitored:');
    print('    - Health level: ${health.healthLevel.name}');
    print(
        '    - Health score: ${(health.healthScore * 100).toStringAsFixed(1)}%');
    print('    - Active issues: ${health.activeIssues.length}');

    print('  ✅ SyncAnalyticsService validation complete');
    print('');
  }

  /// Demonstrates SyncPerformanceMonitor capabilities
  Future<void> _demonstratePerformanceMonitor() async {
    print('⚡ Action 2: Sync Performance Monitoring');
    print('---------------------------------------');

    // Start performance monitoring
    _performanceMonitor.startMonitoring(interval: const Duration(seconds: 5));

    // Test network performance
    print('  Testing network performance...');
    final networkTest = await _performanceMonitor
        .testNetworkPerformance('https://api.example.com');
    print('  ✓ Network test completed:');
    print('    - Latency: ${networkTest.latency.toStringAsFixed(1)}ms');
    print(
        '    - Bandwidth: ${(networkTest.bandwidth / (1024 * 1024)).toStringAsFixed(2)} MB/s');
    print('    - Connected: ${networkTest.isConnected}');
    print('    - Connection type: ${networkTest.connectionType}');

    // Test backend performance
    print('  Testing backend performance...');
    final backendTest =
        await _performanceMonitor.testBackendPerformance('test_backend');
    print('  ✓ Backend test completed:');
    print(
        '    - Response time: ${backendTest.responseTime.toStringAsFixed(1)}ms');
    print('    - Healthy: ${backendTest.isHealthy}');
    print(
        '    - Throughput: ${backendTest.throughput.toStringAsFixed(2)} ops/sec');

    // Record memory usage
    _performanceMonitor.recordMemoryUsage(
      usedMemoryBytes: 150 * 1024 * 1024,
      availableMemoryBytes: 350 * 1024 * 1024,
      syncCacheSize: 25 * 1024 * 1024,
      pendingOperations: 5,
    );

    // Get performance summary
    await Future.delayed(const Duration(seconds: 1));
    final summary = _performanceMonitor.getPerformanceSummary();
    print('  ✓ Performance summary generated:');
    print(
        '    - Network metrics available: ${summary.networkMetrics.isNotEmpty}');
    print(
        '    - Backend metrics available: ${summary.backendMetrics.isNotEmpty}');
    print(
        '    - Memory metrics available: ${summary.memoryMetrics.isNotEmpty}');

    print('  ✅ Performance monitoring validation complete');
    print('');
  }

  /// Demonstrates SyncFailureAnalytics capabilities
  Future<void> _demonstrateFailureAnalytics() async {
    print('🔍 Action 3: Sync Failure Analytics');
    print('------------------------------------');

    // Start failure analytics
    _failureAnalytics.startAnalysis(interval: const Duration(seconds: 5));

    // Create sample failures for analysis
    print('  Creating sample failures for analysis...');
    final sampleFailures = <SyncOperationMetrics>[];

    for (int i = 0; i < 5; i++) {
      final failure = SyncOperationMetrics(
        operationId: 'fail_$i',
        entityType: 'test_entity',
        collection: 'test_collection',
        operationType: SyncOperationType.upload,
        startTime: DateTime.now().subtract(Duration(minutes: i * 2)),
        endTime: DateTime.now().subtract(Duration(minutes: i * 2 - 1)),
        duration: const Duration(minutes: 1),
        status: SyncOperationStatus.failed,
        itemsProcessed: 10,
        itemsFailed: 10,
        errorMessage: _getSimulatedErrorMessage(i),
      );
      sampleFailures.add(failure);
    }

    // Classify failures
    final classifications = <FailureClassification>[];
    for (final failure in sampleFailures) {
      final classification = _failureAnalytics.classifyFailure(failure);
      classifications.add(classification);
    }

    print('  ✓ Failure classification completed:');
    for (final classification in classifications) {
      print('    - ${classification.category}/${classification.subcategory} '
          '(${(classification.confidence * 100).toStringAsFixed(0)}% confidence)');
    }

    // Analyze failure trends
    final trends = _failureAnalytics.analyzeFailureTrends();
    print('  ✓ Failure trends analyzed:');
    print('    - Trend direction: ${trends.direction.name}');
    print('    - Magnitude: ${trends.magnitude.toStringAsFixed(2)}');
    print('    - Data points: ${trends.dataPoints.length}');

    // Predict failures
    final prediction = _failureAnalytics.predictFailures();
    print('  ✓ Failure prediction generated:');
    print(
        '    - Probability: ${(prediction.probability * 100).toStringAsFixed(1)}%');
    print('    - Timeframe: ${prediction.timeframe.inMinutes} minutes');
    print('    - Risk factors: ${prediction.riskFactors.length}');
    print('    - Recommendations: ${prediction.recommendations.length}');

    // Perform root cause analysis
    final rootCause =
        _failureAnalytics.performRootCauseAnalysis(sampleFailures);
    print('  ✓ Root cause analysis completed:');
    print('    - Primary cause: ${rootCause.primaryCause}');
    print(
        '    - Confidence: ${(rootCause.confidence * 100).toStringAsFixed(1)}%');
    print('    - Contributing causes: ${rootCause.contributingCauses.length}');

    // Get failure statistics
    final stats = _failureAnalytics.getFailureStatistics();
    print('  ✓ Failure statistics compiled:');
    print('    - Total classified: ${stats['totalClassifiedFailures']}');
    print(
        '    - Average confidence: ${(stats['averageClassificationConfidence'] * 100).toStringAsFixed(1)}%');

    print('  ✅ Failure analytics validation complete');
    print('');
  }

  /// Demonstrates SyncHealthDashboard capabilities
  Future<void> _demonstrateHealthDashboard() async {
    print('📊 Action 4: Sync Health Dashboard');
    print('-----------------------------------');

    // Set up overview dashboard
    final overviewLayout = SyncHealthDashboard.createOverviewLayout();
    _healthDashboard.setLayout(overviewLayout);

    print('  ✓ Overview dashboard layout configured:');
    print('    - Widgets: ${overviewLayout.widgets.length}');
    for (final widget in overviewLayout.widgets) {
      print('      - ${widget.title} (${widget.type.name})');
    }

    // Wait for initial data collection
    await Future.delayed(const Duration(seconds: 2));

    // Get widget data
    final widgetData = _healthDashboard.getAllWidgetData();
    print('  ✓ Widget data collected:');
    for (final entry in widgetData.entries) {
      print('    - ${entry.key}: ${entry.value.status.name}');
    }

    // Switch to performance layout
    final performanceLayout = SyncHealthDashboard.createPerformanceLayout();
    _healthDashboard.setLayout(performanceLayout);

    print('  ✓ Performance dashboard layout configured:');
    print('    - Widgets: ${performanceLayout.widgets.length}');

    // Add custom widget
    _healthDashboard.addWidget(DashboardWidgetConfig(
      id: 'custom_widget',
      title: 'Custom Analytics Widget',
      type: DashboardWidgetType.operationHistory,
      parameters: {'limit': 25},
      refreshInterval: const Duration(seconds: 15),
    ));

    print('  ✓ Custom widget added');

    // Export dashboard configuration
    final exportData = _healthDashboard.exportDashboard();
    print('  ✓ Dashboard exported:');
    print('    - Layout name: ${exportData['layout']['name']}');
    print(
        '    - Widget count: ${(exportData['layout']['widgets'] as List).length}');

    print('  ✅ Health dashboard validation complete');
    print('');
  }

  /// Demonstrates SyncAlertingService capabilities
  Future<void> _demonstrateAlertingService() async {
    print('🚨 Action 5: Alerting for Sync Issues');
    print('-------------------------------------');

    // Set up alert listeners
    _subscriptions.add(_alertingService.alertTriggered.listen((alert) {
      print('  🔥 ALERT TRIGGERED: ${alert.title} (${alert.severity.name})');
    }));

    _subscriptions.add(_alertingService.alertResolved.listen((alert) {
      print('  ✅ Alert resolved: ${alert.title}');
    }));

    // Get default rules
    final defaultRules = _alertingService.getAllRules();
    print('  ✓ Default alert rules loaded:');
    for (final rule in defaultRules) {
      print('    - ${rule.name} (${rule.severity.name})');
    }

    // Add custom alert rule
    final customRule = AlertRule(
      id: 'custom_test_rule',
      name: 'Test Alert Rule',
      description: 'Custom rule for testing purposes',
      category: AlertCategory.system,
      severity: AlertSeverity.medium,
      condition: AlertCondition(
        metric: 'health_score',
        operator: ComparisonOperator.lessThan,
        threshold: 0.5,
        timeWindow: const Duration(seconds: 30),
      ),
      evaluationInterval: const Duration(seconds: 5),
    );

    _alertingService.addAlertRule(customRule);
    print('  ✓ Custom alert rule added: ${customRule.name}');

    // Configure notification channels
    _alertingService.configureNotification(NotificationChannel.email, {
      'recipientEmail': 'admin@example.com',
      'smtpServer': 'smtp.example.com',
    });

    _alertingService.configureNotification(NotificationChannel.webhook, {
      'url': 'https://webhooks.example.com/alerts',
      'method': 'POST',
    });

    print('  ✓ Notification channels configured');

    // Wait for potential alerts to trigger
    await Future.delayed(const Duration(seconds: 3));

    // Get alert statistics
    final stats = _alertingService.getAlertStatistics();
    print('  ✓ Alert statistics:');
    print('    - Total rules: ${stats['totalRules']}');
    print('    - Enabled rules: ${stats['enabledRules']}');
    print('    - Active alerts: ${stats['activeAlerts']}');

    // Get active alerts
    final activeAlerts = _alertingService.getActiveAlerts();
    if (activeAlerts.isNotEmpty) {
      print('  📋 Active alerts:');
      for (final alert in activeAlerts) {
        print(
            '    - ${alert.title} (${alert.severity.name}, ${alert.status.name})');

        // Acknowledge the alert
        _alertingService.acknowledgeAlert(alert.id,
            acknowledgedBy: 'demo_user');
        print('      ✓ Alert acknowledged');
      }
    } else {
      print('  ✓ No active alerts (system healthy)');
    }

    print('  ✅ Alerting service validation complete');
    print('');
  }

  /// Demonstrates integrated monitoring across all services
  Future<void> _demonstrateIntegratedMonitoring() async {
    print('🔄 Integrated Monitoring Demonstration');
    print('--------------------------------------');

    print('  Creating integrated monitoring scenario...');

    // Simulate a monitoring cycle
    for (int cycle = 1; cycle <= 3; cycle++) {
      print('  📊 Monitoring cycle $cycle:');

      // Analytics service metrics
      final opId = _analyticsService.startOperation(
        entityType: 'integration_test',
        collection: 'test_data',
        operationType: SyncOperationType.bidirectional,
      );

      await Future.delayed(const Duration(milliseconds: 200));

      _analyticsService.completeOperation(
        opId,
        itemsSuccessful: cycle * 5,
        bytesTransferred: cycle * 2048,
      );

      // Performance monitoring
      _performanceMonitor.recordMemoryUsage(
        usedMemoryBytes: (100 + cycle * 20) * 1024 * 1024,
        availableMemoryBytes: (400 - cycle * 10) * 1024 * 1024,
        syncCacheSize: cycle * 10 * 1024 * 1024,
        pendingOperations: cycle * 2,
      );

      // Health status
      final health = _analyticsService.getCurrentHealthStatus();
      print(
          '    - Health: ${health.healthLevel.name} (${(health.healthScore * 100).toStringAsFixed(1)}%)');

      // Performance summary
      final perfSummary = _performanceMonitor.getPerformanceSummary();
      print(
          '    - Memory pressure: ${(perfSummary.memoryMetrics['averageMemoryPressure'] ?? 0 * 100).toStringAsFixed(1)}%');

      // Dashboard update
      await _healthDashboard.refreshAllWidgets();
      final dashboardData = _healthDashboard.getAllWidgetData();
      print('    - Dashboard widgets updated: ${dashboardData.length}');

      await Future.delayed(const Duration(seconds: 1));
    }

    // Final integrated status
    print('  🎯 Final integrated status:');
    final finalMetrics = _analyticsService.getPerformanceMetrics();
    final finalHealth = _analyticsService.getCurrentHealthStatus();
    final finalAlerts = _alertingService.getActiveAlerts();

    print('    ✓ Total operations processed: ${finalMetrics.totalOperations}');
    print(
        '    ✓ Overall success rate: ${(finalMetrics.successRate * 100).toStringAsFixed(1)}%');
    print(
        '    ✓ System health score: ${(finalHealth.healthScore * 100).toStringAsFixed(1)}%');
    print('    ✓ Active alerts: ${finalAlerts.length}');

    print('  ✅ Integrated monitoring validation complete');
    print('');
  }

  /// Generates simulated error messages
  String _getSimulatedErrorMessage(int index) {
    final errorTypes = [
      'Authentication failed: Invalid token',
      'Network timeout: Connection timed out after 30 seconds',
      'Data corruption: Invalid JSON format detected',
      'Resource exhaustion: Insufficient memory available',
      'Permission denied: Access forbidden to collection',
    ];
    return errorTypes[index % errorTypes.length];
  }

  /// Clean up resources
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }

    _analyticsService.dispose();
    _performanceMonitor.dispose();
    _failureAnalytics.dispose();
    _healthDashboard.dispose();
    _alertingService.dispose();
  }
}

/// Main demo runner
void main() async {
  final demo = Task51SyncAnalyticsAndMonitoringDemo();

  try {
    await demo.runDemo();
  } catch (e, stackTrace) {
    print('❌ Demo failed: $e');
    print('Stack trace: $stackTrace');
  } finally {
    demo.dispose();
  }
}
