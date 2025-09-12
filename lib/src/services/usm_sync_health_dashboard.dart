// lib/src/services/usm_sync_health_dashboard.dart

import 'dart:async';
import 'dart:math' as math;

import 'usm_sync_analytics_service.dart';
import 'usm_sync_performance_monitor.dart';
import 'usm_sync_failure_analytics.dart';

/// Dashboard widget configuration
class DashboardWidgetConfig {
  final String id;
  final String title;
  final DashboardWidgetType type;
  final Map<String, dynamic> parameters;
  final Duration refreshInterval;
  final bool isEnabled;

  const DashboardWidgetConfig({
    required this.id,
    required this.title,
    required this.type,
    this.parameters = const {},
    this.refreshInterval = const Duration(seconds: 30),
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.name,
        'parameters': parameters,
        'refreshIntervalSeconds': refreshInterval.inSeconds,
        'isEnabled': isEnabled,
      };
}

/// Dashboard widget types
enum DashboardWidgetType {
  healthOverview,
  performanceMetrics,
  failureAnalysis,
  syncStatus,
  networkStatus,
  trendChart,
  alertList,
  topFailures,
  resourceUsage,
  operationHistory,
}

/// Dashboard layout configuration
class DashboardLayout {
  final String name;
  final List<DashboardWidgetConfig> widgets;
  final Map<String, dynamic> layoutOptions;

  const DashboardLayout({
    required this.name,
    required this.widgets,
    this.layoutOptions = const {},
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'widgets': widgets.map((w) => w.toJson()).toList(),
        'layoutOptions': layoutOptions,
      };
}

/// Real-time dashboard data
class DashboardData {
  final String widgetId;
  final DashboardWidgetType widgetType;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final DashboardDataStatus status;

  const DashboardData({
    required this.widgetId,
    required this.widgetType,
    required this.data,
    required this.timestamp,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'widgetId': widgetId,
        'widgetType': widgetType.name,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
        'status': status.name,
      };
}

/// Dashboard data status
enum DashboardDataStatus {
  loading,
  success,
  error,
  stale,
}

/// Comprehensive sync health dashboard
class SyncHealthDashboard {
  final SyncAnalyticsService _analyticsService;
  final SyncPerformanceMonitor? _performanceMonitor;
  final SyncFailureAnalytics? _failureAnalytics;

  DashboardLayout _currentLayout = DashboardLayout(
    name: 'default',
    widgets: [],
  );

  final Map<String, Timer> _widgetTimers = {};
  final Map<String, DashboardData> _widgetData = {};
  final StreamController<DashboardData> _dataController =
      StreamController<DashboardData>.broadcast();

  SyncHealthDashboard(
    this._analyticsService, [
    this._performanceMonitor,
    this._failureAnalytics,
  ]) {
    _initializeDefaultLayout();
  }

  /// Stream of dashboard data updates
  Stream<DashboardData> get dataUpdates => _dataController.stream;

  /// Gets current dashboard layout
  DashboardLayout get currentLayout => _currentLayout;

  /// Sets dashboard layout and starts data collection
  void setLayout(DashboardLayout layout) {
    _stopAllWidgets();
    _currentLayout = layout;
    _startAllWidgets();
  }

  /// Adds a widget to current layout
  void addWidget(DashboardWidgetConfig widget) {
    final updatedWidgets =
        List<DashboardWidgetConfig>.from(_currentLayout.widgets)..add(widget);

    _currentLayout = DashboardLayout(
      name: _currentLayout.name,
      widgets: updatedWidgets,
      layoutOptions: _currentLayout.layoutOptions,
    );

    _startWidget(widget);
  }

  /// Removes a widget from current layout
  void removeWidget(String widgetId) {
    _stopWidget(widgetId);

    final updatedWidgets =
        _currentLayout.widgets.where((w) => w.id != widgetId).toList();

    _currentLayout = DashboardLayout(
      name: _currentLayout.name,
      widgets: updatedWidgets,
      layoutOptions: _currentLayout.layoutOptions,
    );

    _widgetData.remove(widgetId);
  }

  /// Updates a widget configuration
  void updateWidget(String widgetId, DashboardWidgetConfig newConfig) {
    _stopWidget(widgetId);

    final updatedWidgets = _currentLayout.widgets.map((w) {
      return w.id == widgetId ? newConfig : w;
    }).toList();

    _currentLayout = DashboardLayout(
      name: _currentLayout.name,
      widgets: updatedWidgets,
      layoutOptions: _currentLayout.layoutOptions,
    );

    _startWidget(newConfig);
  }

  /// Gets current data for a widget
  DashboardData? getWidgetData(String widgetId) => _widgetData[widgetId];

  /// Gets current data for all widgets
  Map<String, DashboardData> getAllWidgetData() =>
      Map.unmodifiable(_widgetData);

  /// Manually refreshes a widget
  Future<void> refreshWidget(String widgetId) async {
    final widget =
        _currentLayout.widgets.where((w) => w.id == widgetId).firstOrNull;

    if (widget != null) {
      await _updateWidgetData(widget);
    }
  }

  /// Refreshes all widgets
  Future<void> refreshAllWidgets() async {
    for (final widget in _currentLayout.widgets) {
      await _updateWidgetData(widget);
    }
  }

  /// Exports dashboard configuration
  Map<String, dynamic> exportDashboard() => {
        'layout': _currentLayout.toJson(),
        'widgetData': _widgetData.map((k, v) => MapEntry(k, v.toJson())),
        'exportedAt': DateTime.now().toIso8601String(),
      };

  /// Imports dashboard configuration
  void importDashboard(Map<String, dynamic> config) {
    try {
      final layoutData = config['layout'] as Map<String, dynamic>;
      final widgets = (layoutData['widgets'] as List)
          .map((w) => _parseWidgetConfig(w as Map<String, dynamic>))
          .toList();

      final layout = DashboardLayout(
        name: layoutData['name'] as String,
        widgets: widgets,
        layoutOptions:
            layoutData['layoutOptions'] as Map<String, dynamic>? ?? {},
      );

      setLayout(layout);
    } catch (e) {
      // Handle import error - fall back to default layout
      _initializeDefaultLayout();
    }
  }

  /// Creates predefined dashboard layouts
  static DashboardLayout createOverviewLayout() => DashboardLayout(
        name: 'overview',
        widgets: [
          DashboardWidgetConfig(
            id: 'health_overview',
            title: 'Sync Health Overview',
            type: DashboardWidgetType.healthOverview,
          ),
          DashboardWidgetConfig(
            id: 'performance_summary',
            title: 'Performance Summary',
            type: DashboardWidgetType.performanceMetrics,
            parameters: {'period': 'last_hour'},
          ),
          DashboardWidgetConfig(
            id: 'sync_status',
            title: 'Current Sync Status',
            type: DashboardWidgetType.syncStatus,
          ),
          DashboardWidgetConfig(
            id: 'recent_alerts',
            title: 'Recent Alerts',
            type: DashboardWidgetType.alertList,
            parameters: {'limit': 10},
          ),
        ],
      );

  static DashboardLayout createPerformanceLayout() => DashboardLayout(
        name: 'performance',
        widgets: [
          DashboardWidgetConfig(
            id: 'perf_overview',
            title: 'Performance Overview',
            type: DashboardWidgetType.performanceMetrics,
            parameters: {'period': 'last_24_hours'},
          ),
          DashboardWidgetConfig(
            id: 'network_status',
            title: 'Network Performance',
            type: DashboardWidgetType.networkStatus,
          ),
          DashboardWidgetConfig(
            id: 'resource_usage',
            title: 'Resource Usage',
            type: DashboardWidgetType.resourceUsage,
          ),
          DashboardWidgetConfig(
            id: 'operation_history',
            title: 'Operation History',
            type: DashboardWidgetType.operationHistory,
            parameters: {'limit': 50},
          ),
        ],
      );

  static DashboardLayout createFailureAnalysisLayout() => DashboardLayout(
        name: 'failure_analysis',
        widgets: [
          DashboardWidgetConfig(
            id: 'failure_overview',
            title: 'Failure Analysis',
            type: DashboardWidgetType.failureAnalysis,
            parameters: {'period': 'last_week'},
          ),
          DashboardWidgetConfig(
            id: 'top_failures',
            title: 'Top Failure Types',
            type: DashboardWidgetType.topFailures,
            parameters: {'limit': 10},
          ),
          DashboardWidgetConfig(
            id: 'failure_trends',
            title: 'Failure Trends',
            type: DashboardWidgetType.trendChart,
            parameters: {'metric': 'failures', 'period': 'last_24_hours'},
          ),
          DashboardWidgetConfig(
            id: 'failure_alerts',
            title: 'Failure Alerts',
            type: DashboardWidgetType.alertList,
            parameters: {'type': 'failure_only'},
          ),
        ],
      );

  /// Initialize default dashboard layout
  void _initializeDefaultLayout() {
    _currentLayout = createOverviewLayout();
    _startAllWidgets();
  }

  /// Starts data collection for all widgets
  void _startAllWidgets() {
    for (final widget in _currentLayout.widgets) {
      if (widget.isEnabled) {
        _startWidget(widget);
      }
    }
  }

  /// Stops data collection for all widgets
  void _stopAllWidgets() {
    for (final timer in _widgetTimers.values) {
      timer.cancel();
    }
    _widgetTimers.clear();
    _widgetData.clear();
  }

  /// Starts data collection for a specific widget
  void _startWidget(DashboardWidgetConfig widget) {
    _stopWidget(widget.id);

    // Initial data collection
    _updateWidgetData(widget);

    // Start periodic updates
    _widgetTimers[widget.id] = Timer.periodic(widget.refreshInterval, (_) {
      _updateWidgetData(widget);
    });
  }

  /// Stops data collection for a specific widget
  void _stopWidget(String widgetId) {
    _widgetTimers[widgetId]?.cancel();
    _widgetTimers.remove(widgetId);
  }

  /// Updates data for a specific widget
  Future<void> _updateWidgetData(DashboardWidgetConfig widget) async {
    try {
      // Set loading status
      final loadingData = DashboardData(
        widgetId: widget.id,
        widgetType: widget.type,
        data: {},
        timestamp: DateTime.now(),
        status: DashboardDataStatus.loading,
      );

      _widgetData[widget.id] = loadingData;
      _dataController.add(loadingData);

      // Collect widget data based on type
      final data = await _collectWidgetData(widget);

      // Update with actual data
      final successData = DashboardData(
        widgetId: widget.id,
        widgetType: widget.type,
        data: data,
        timestamp: DateTime.now(),
        status: DashboardDataStatus.success,
      );

      _widgetData[widget.id] = successData;
      _dataController.add(successData);
    } catch (e) {
      // Handle error
      final errorData = DashboardData(
        widgetId: widget.id,
        widgetType: widget.type,
        data: {'error': e.toString()},
        timestamp: DateTime.now(),
        status: DashboardDataStatus.error,
      );

      _widgetData[widget.id] = errorData;
      _dataController.add(errorData);
    }
  }

  /// Collects data for a specific widget type
  Future<Map<String, dynamic>> _collectWidgetData(
      DashboardWidgetConfig widget) async {
    switch (widget.type) {
      case DashboardWidgetType.healthOverview:
        return _collectHealthOverviewData(widget.parameters);

      case DashboardWidgetType.performanceMetrics:
        return _collectPerformanceMetricsData(widget.parameters);

      case DashboardWidgetType.failureAnalysis:
        return _collectFailureAnalysisData(widget.parameters);

      case DashboardWidgetType.syncStatus:
        return _collectSyncStatusData(widget.parameters);

      case DashboardWidgetType.networkStatus:
        return _collectNetworkStatusData(widget.parameters);

      case DashboardWidgetType.trendChart:
        return _collectTrendChartData(widget.parameters);

      case DashboardWidgetType.alertList:
        return _collectAlertListData(widget.parameters);

      case DashboardWidgetType.topFailures:
        return _collectTopFailuresData(widget.parameters);

      case DashboardWidgetType.resourceUsage:
        return _collectResourceUsageData(widget.parameters);

      case DashboardWidgetType.operationHistory:
        return _collectOperationHistoryData(widget.parameters);
    }
  }

  /// Collects health overview data
  Map<String, dynamic> _collectHealthOverviewData(
      Map<String, dynamic> parameters) {
    final health = _analyticsService.getCurrentHealthStatus();
    final recentMetrics = _analyticsService.getPerformanceMetrics(
      period: const Duration(hours: 1),
    );

    return {
      'healthLevel': health.healthLevel.name,
      'healthScore': health.healthScore,
      'activeIssues': health.activeIssues,
      'warnings': health.warnings,
      'totalOperations': recentMetrics.totalOperations,
      'successRate': recentMetrics.successRate,
      'averageResponseTime': recentMetrics.averageOperationTime.inMilliseconds,
      'lastUpdated': health.lastUpdated.toIso8601String(),
    };
  }

  /// Collects performance metrics data
  Map<String, dynamic> _collectPerformanceMetricsData(
      Map<String, dynamic> parameters) {
    final periodStr = parameters['period'] as String? ?? 'last_hour';
    final period = _parsePeriod(periodStr);

    final metrics = _analyticsService.getPerformanceMetrics(period: period);

    return {
      'period': periodStr,
      'totalOperations': metrics.totalOperations,
      'successfulOperations': metrics.successfulOperations,
      'failedOperations': metrics.failedOperations,
      'successRate': metrics.successRate,
      'averageOperationTime': metrics.averageOperationTime.inMilliseconds,
      'operationsPerSecond': metrics.operationsPerSecond,
      'totalBytesTransferred': metrics.totalBytesTransferred,
      'averageBytesPerSecond': metrics.averageBytesPerSecond,
      'operationTypeCount': metrics.operationTypeCount,
    };
  }

  /// Collects failure analysis data
  Map<String, dynamic> _collectFailureAnalysisData(
      Map<String, dynamic> parameters) {
    final periodStr = parameters['period'] as String? ?? 'last_day';
    final period = _parsePeriod(periodStr);

    final analysis = _analyticsService.getFailureAnalysis(period: period);
    final stats = _failureAnalytics?.getFailureStatistics(period: period) ?? {};

    return {
      'period': periodStr,
      'totalFailures': analysis.totalFailures,
      'failuresByType': analysis.failuresByType,
      'failuresByCollection': analysis.failuresByCollection,
      'topErrorMessages': analysis.topErrorMessages,
      'meanTimeBetweenFailures': analysis.meanTimeBetweenFailures,
      'classificationStats': stats,
    };
  }

  /// Collects sync status data
  Map<String, dynamic> _collectSyncStatusData(Map<String, dynamic> parameters) {
    final activeOps = _analyticsService.getActiveOperations();
    final recentOps = _analyticsService.getOperationHistory(limit: 10);

    return {
      'activeOperations': activeOps.length,
      'activeOperationsList': activeOps
          .map((op) => {
                'id': op.operationId,
                'collection': op.collection,
                'type': op.operationType.name,
                'startTime': op.startTime.toIso8601String(),
                'itemsProcessed': op.itemsProcessed,
              })
          .toList(),
      'recentOperations': recentOps
          .map((op) => {
                'id': op.operationId,
                'collection': op.collection,
                'type': op.operationType.name,
                'status': op.status.name,
                'duration': op.duration?.inMilliseconds,
                'itemsProcessed': op.itemsProcessed,
              })
          .toList(),
    };
  }

  /// Collects network status data
  Map<String, dynamic> _collectNetworkStatusData(
      Map<String, dynamic> parameters) {
    // In real implementation, get actual network metrics from performance monitor
    return {
      'isConnected': true,
      'connectionType': 'wifi',
      'latency': 50 + math.Random().nextDouble() * 100,
      'bandwidth': 1024 * 1024 * (1 + math.Random().nextDouble()),
      'packetLoss': math.Random().nextDouble() * 0.01,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  /// Collects trend chart data
  Map<String, dynamic> _collectTrendChartData(Map<String, dynamic> parameters) {
    final metric = parameters['metric'] as String? ?? 'operations';
    final periodStr = parameters['period'] as String? ?? 'last_day';
    // Note: period parsing available if needed for future functionality

    // Generate trend data points based on metric type
    final dataPoints = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int i = 23; i >= 0; i--) {
      final timestamp = now.subtract(Duration(hours: i));
      double value = 0;

      switch (metric) {
        case 'operations':
          value = 10 + math.Random().nextDouble() * 20;
          break;
        case 'failures':
          value = math.Random().nextDouble() * 5;
          break;
        case 'response_time':
          value = 100 + math.Random().nextDouble() * 500;
          break;
      }

      dataPoints.add({
        'timestamp': timestamp.toIso8601String(),
        'value': value,
      });
    }

    return {
      'metric': metric,
      'period': periodStr,
      'dataPoints': dataPoints,
    };
  }

  /// Collects alert list data
  Map<String, dynamic> _collectAlertListData(Map<String, dynamic> parameters) {
    final limit = parameters['limit'] as int? ?? 20;
    final type = parameters['type'] as String?;

    // In real implementation, get actual alerts
    final alerts = <Map<String, dynamic>>[];
    final alertTypes = ['warning', 'error', 'info'];

    for (int i = 0; i < math.min(limit, 10); i++) {
      alerts.add({
        'id': 'alert_$i',
        'type': alertTypes[math.Random().nextInt(alertTypes.length)],
        'message': 'Sample alert message $i',
        'timestamp':
            DateTime.now().subtract(Duration(minutes: i * 5)).toIso8601String(),
        'severity': ['low', 'medium', 'high'][math.Random().nextInt(3)],
      });
    }

    return {
      'alerts': alerts,
      'totalCount': alerts.length,
      'filterType': type,
    };
  }

  /// Collects top failures data
  Map<String, dynamic> _collectTopFailuresData(
      Map<String, dynamic> parameters) {
    final limit = parameters['limit'] as int? ?? 10;
    final analysis = _analyticsService.getFailureAnalysis();

    final topFailures = analysis.failuresByType.entries
        .map((entry) => {
              'type': entry.key,
              'count': entry.value,
            })
        .toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int))
      ..take(limit);

    return {
      'topFailures': topFailures.toList(),
      'totalFailureTypes': analysis.failuresByType.length,
    };
  }

  /// Collects resource usage data
  Map<String, dynamic> _collectResourceUsageData(
      Map<String, dynamic> parameters) {
    // In real implementation, get actual resource metrics
    return {
      'memoryUsage': {
        'used': 100 + math.Random().nextInt(400), // MB
        'available': 500 + math.Random().nextInt(1000), // MB
        'pressure': math.Random().nextDouble() * 0.8,
      },
      'diskUsage': {
        'used': 1000 + math.Random().nextInt(5000), // MB
        'available': 10000 + math.Random().nextInt(20000), // MB
      },
      'networkUsage': {
        'bytesPerSecond': 1024 * (10 + math.Random().nextInt(100)),
        'packetsPerSecond': 100 + math.Random().nextInt(500),
      },
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  /// Collects operation history data
  Map<String, dynamic> _collectOperationHistoryData(
      Map<String, dynamic> parameters) {
    final limit = parameters['limit'] as int? ?? 50;
    final operations = _analyticsService.getOperationHistory(limit: limit);

    return {
      'operations': operations
          .map((op) => {
                'id': op.operationId,
                'collection': op.collection,
                'type': op.operationType.name,
                'status': op.status.name,
                'startTime': op.startTime.toIso8601String(),
                'endTime': op.endTime?.toIso8601String(),
                'duration': op.duration?.inMilliseconds,
                'itemsProcessed': op.itemsProcessed,
                'itemsSuccessful': op.itemsSuccessful,
                'itemsFailed': op.itemsFailed,
                'bytesTransferred': op.bytesTransferred,
              })
          .toList(),
      'totalCount': operations.length,
    };
  }

  /// Parses period string into Duration
  Duration _parsePeriod(String period) {
    switch (period) {
      case 'last_hour':
        return const Duration(hours: 1);
      case 'last_4_hours':
        return const Duration(hours: 4);
      case 'last_24_hours':
      case 'last_day':
        return const Duration(hours: 24);
      case 'last_week':
        return const Duration(days: 7);
      case 'last_month':
        return const Duration(days: 30);
      default:
        return const Duration(hours: 1);
    }
  }

  /// Parses widget configuration from JSON
  DashboardWidgetConfig _parseWidgetConfig(Map<String, dynamic> json) {
    return DashboardWidgetConfig(
      id: json['id'] as String,
      title: json['title'] as String,
      type: DashboardWidgetType.values.firstWhere(
        (t) => t.name == json['type'],
      ),
      parameters: json['parameters'] as Map<String, dynamic>? ?? {},
      refreshInterval:
          Duration(seconds: json['refreshIntervalSeconds'] as int? ?? 30),
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  /// Disposes the dashboard
  void dispose() {
    _stopAllWidgets();
    _dataController.close();
  }
}
