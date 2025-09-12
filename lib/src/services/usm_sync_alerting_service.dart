// lib/src/services/usm_sync_alerting_service.dart

import 'dart:async';
import 'dart:math' as math;

import 'usm_sync_analytics_service.dart';
import 'usm_sync_performance_monitor.dart';
import 'usm_sync_failure_analytics.dart';

/// Alert severity levels
enum AlertSeverity {
  low,
  medium,
  high,
  critical,
}

/// Alert categories
enum AlertCategory {
  performance,
  failure,
  network,
  authentication,
  resource,
  data,
  system,
}

/// Alert status
enum AlertStatus {
  active,
  acknowledged,
  resolved,
  suppressed,
}

/// Notification channels
enum NotificationChannel {
  inApp,
  email,
  push,
  webhook,
  sms,
  slack,
}

/// Alert configuration
class AlertRule {
  final String id;
  final String name;
  final String description;
  final AlertCategory category;
  final AlertSeverity severity;
  final AlertCondition condition;
  final Duration evaluationInterval;
  final Duration suppressionWindow;
  final List<NotificationChannel> notificationChannels;
  final bool isEnabled;
  final Map<String, dynamic> metadata;

  const AlertRule({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.severity,
    required this.condition,
    this.evaluationInterval = const Duration(minutes: 1),
    this.suppressionWindow = const Duration(minutes: 15),
    this.notificationChannels = const [NotificationChannel.inApp],
    this.isEnabled = true,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category.name,
        'severity': severity.name,
        'condition': condition.toJson(),
        'evaluationIntervalMinutes': evaluationInterval.inMinutes,
        'suppressionWindowMinutes': suppressionWindow.inMinutes,
        'notificationChannels':
            notificationChannels.map((c) => c.name).toList(),
        'isEnabled': isEnabled,
        'metadata': metadata,
      };

  factory AlertRule.fromJson(Map<String, dynamic> json) {
    return AlertRule(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category:
          AlertCategory.values.firstWhere((c) => c.name == json['category']),
      severity:
          AlertSeverity.values.firstWhere((s) => s.name == json['severity']),
      condition: AlertCondition.fromJson(json['condition']),
      evaluationInterval:
          Duration(minutes: json['evaluationIntervalMinutes'] ?? 1),
      suppressionWindow:
          Duration(minutes: json['suppressionWindowMinutes'] ?? 15),
      notificationChannels: (json['notificationChannels'] as List<dynamic>?)
              ?.map((c) =>
                  NotificationChannel.values.firstWhere((nc) => nc.name == c))
              .toList() ??
          [NotificationChannel.inApp],
      isEnabled: json['isEnabled'] ?? true,
      metadata: json['metadata'] ?? {},
    );
  }
}

/// Alert condition configuration
class AlertCondition {
  final String metric;
  final ComparisonOperator operator;
  final dynamic threshold;
  final Duration timeWindow;
  final int? dataPointsRequired;
  final Map<String, dynamic> filters;

  const AlertCondition({
    required this.metric,
    required this.operator,
    required this.threshold,
    this.timeWindow = const Duration(minutes: 5),
    this.dataPointsRequired,
    this.filters = const {},
  });

  Map<String, dynamic> toJson() => {
        'metric': metric,
        'operator': operator.name,
        'threshold': threshold,
        'timeWindowMinutes': timeWindow.inMinutes,
        'dataPointsRequired': dataPointsRequired,
        'filters': filters,
      };

  factory AlertCondition.fromJson(Map<String, dynamic> json) {
    return AlertCondition(
      metric: json['metric'],
      operator: ComparisonOperator.values
          .firstWhere((o) => o.name == json['operator']),
      threshold: json['threshold'],
      timeWindow: Duration(minutes: json['timeWindowMinutes'] ?? 5),
      dataPointsRequired: json['dataPointsRequired'],
      filters: json['filters'] ?? {},
    );
  }
}

/// Comparison operators for alert conditions
enum ComparisonOperator {
  greaterThan,
  greaterThanOrEqual,
  lessThan,
  lessThanOrEqual,
  equals,
  notEquals,
  contains,
  notContains,
}

/// Alert instance
class SyncAlert {
  final String id;
  final String ruleId;
  final String ruleName;
  final AlertCategory category;
  final AlertSeverity severity;
  final AlertStatus status;
  final String title;
  final String description;
  final Map<String, dynamic> context;
  final DateTime triggeredAt;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final String? acknowledgedBy;
  final String? resolutionNotes;
  final Duration? duration;

  const SyncAlert({
    required this.id,
    required this.ruleId,
    required this.ruleName,
    required this.category,
    required this.severity,
    required this.status,
    required this.title,
    required this.description,
    required this.context,
    required this.triggeredAt,
    this.acknowledgedAt,
    this.resolvedAt,
    this.acknowledgedBy,
    this.resolutionNotes,
    this.duration,
  });

  /// Creates resolved version of alert
  SyncAlert resolve({String? notes}) {
    final now = DateTime.now();
    return SyncAlert(
      id: id,
      ruleId: ruleId,
      ruleName: ruleName,
      category: category,
      severity: severity,
      status: AlertStatus.resolved,
      title: title,
      description: description,
      context: context,
      triggeredAt: triggeredAt,
      acknowledgedAt: acknowledgedAt,
      resolvedAt: now,
      acknowledgedBy: acknowledgedBy,
      resolutionNotes: notes,
      duration: now.difference(triggeredAt),
    );
  }

  /// Creates acknowledged version of alert
  SyncAlert acknowledge({required String acknowledgedBy}) {
    return SyncAlert(
      id: id,
      ruleId: ruleId,
      ruleName: ruleName,
      category: category,
      severity: severity,
      status: AlertStatus.acknowledged,
      title: title,
      description: description,
      context: context,
      triggeredAt: triggeredAt,
      acknowledgedAt: DateTime.now(),
      resolvedAt: resolvedAt,
      acknowledgedBy: acknowledgedBy,
      resolutionNotes: resolutionNotes,
      duration: duration,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ruleId': ruleId,
        'ruleName': ruleName,
        'category': category.name,
        'severity': severity.name,
        'status': status.name,
        'title': title,
        'description': description,
        'context': context,
        'triggeredAt': triggeredAt.toIso8601String(),
        'acknowledgedAt': acknowledgedAt?.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
        'acknowledgedBy': acknowledgedBy,
        'resolutionNotes': resolutionNotes,
        'durationMinutes': duration?.inMinutes,
      };
}

/// Notification configuration
class NotificationConfig {
  final NotificationChannel channel;
  final Map<String, dynamic> settings;
  final bool isEnabled;

  const NotificationConfig({
    required this.channel,
    required this.settings,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() => {
        'channel': channel.name,
        'settings': settings,
        'isEnabled': isEnabled,
      };
}

/// Comprehensive sync alerting service
class SyncAlertingService {
  final SyncAnalyticsService _analyticsService;
  final SyncPerformanceMonitor? _performanceMonitor;
  final SyncFailureAnalytics? _failureAnalytics;

  final Map<String, AlertRule> _alertRules = {};
  final Map<String, SyncAlert> _activeAlerts = {};
  final List<SyncAlert> _alertHistory = [];
  final Map<String, Timer> _evaluationTimers = {};
  final Map<String, DateTime> _lastSuppressionTime = {};

  final StreamController<SyncAlert> _alertTriggeredController =
      StreamController<SyncAlert>.broadcast();
  final StreamController<SyncAlert> _alertResolvedController =
      StreamController<SyncAlert>.broadcast();
  final StreamController<SyncAlert> _alertAcknowledgedController =
      StreamController<SyncAlert>.broadcast();

  final Map<NotificationChannel, NotificationConfig> _notificationConfigs = {};

  SyncAlertingService(
    this._analyticsService, [
    this._performanceMonitor,
    this._failureAnalytics,
  ]) {
    _initializeDefaultRules();
    _startEvaluationLoop();
  }

  /// Stream of triggered alerts
  Stream<SyncAlert> get alertTriggered => _alertTriggeredController.stream;

  /// Stream of resolved alerts
  Stream<SyncAlert> get alertResolved => _alertResolvedController.stream;

  /// Stream of acknowledged alerts
  Stream<SyncAlert> get alertAcknowledged =>
      _alertAcknowledgedController.stream;

  /// Adds or updates an alert rule
  void addAlertRule(AlertRule rule) {
    _alertRules[rule.id] = rule;

    if (rule.isEnabled) {
      _startRuleEvaluation(rule);
    } else {
      _stopRuleEvaluation(rule.id);
    }
  }

  /// Removes an alert rule
  void removeAlertRule(String ruleId) {
    _alertRules.remove(ruleId);
    _stopRuleEvaluation(ruleId);

    // Resolve any active alerts for this rule
    final activeAlertsForRule =
        _activeAlerts.values.where((alert) => alert.ruleId == ruleId).toList();

    for (final alert in activeAlertsForRule) {
      resolveAlert(alert.id, notes: 'Alert rule removed');
    }
  }

  /// Enables or disables an alert rule
  void setRuleEnabled(String ruleId, bool enabled) {
    final rule = _alertRules[ruleId];
    if (rule == null) return;

    final updatedRule = AlertRule(
      id: rule.id,
      name: rule.name,
      description: rule.description,
      category: rule.category,
      severity: rule.severity,
      condition: rule.condition,
      evaluationInterval: rule.evaluationInterval,
      suppressionWindow: rule.suppressionWindow,
      notificationChannels: rule.notificationChannels,
      isEnabled: enabled,
      metadata: rule.metadata,
    );

    addAlertRule(updatedRule);
  }

  /// Gets all alert rules
  List<AlertRule> getAllRules() => List.unmodifiable(_alertRules.values);

  /// Gets active alerts
  List<SyncAlert> getActiveAlerts(
      {AlertSeverity? severity, AlertCategory? category}) {
    var alerts = _activeAlerts.values.toList();

    if (severity != null) {
      alerts = alerts.where((a) => a.severity == severity).toList();
    }

    if (category != null) {
      alerts = alerts.where((a) => a.category == category).toList();
    }

    return List.unmodifiable(alerts);
  }

  /// Gets alert history
  List<SyncAlert> getAlertHistory({
    int? limit,
    DateTime? since,
    AlertSeverity? severity,
    AlertCategory? category,
  }) {
    var alerts = _alertHistory.toList();

    if (since != null) {
      alerts = alerts.where((a) => a.triggeredAt.isAfter(since)).toList();
    }

    if (severity != null) {
      alerts = alerts.where((a) => a.severity == severity).toList();
    }

    if (category != null) {
      alerts = alerts.where((a) => a.category == category).toList();
    }

    // Sort by triggered time descending
    alerts.sort((a, b) => b.triggeredAt.compareTo(a.triggeredAt));

    if (limit != null && alerts.length > limit) {
      alerts = alerts.take(limit).toList();
    }

    return List.unmodifiable(alerts);
  }

  /// Acknowledges an alert
  void acknowledgeAlert(String alertId, {required String acknowledgedBy}) {
    final alert = _activeAlerts[alertId];
    if (alert == null || alert.status != AlertStatus.active) return;

    final acknowledgedAlert = alert.acknowledge(acknowledgedBy: acknowledgedBy);
    _activeAlerts[alertId] = acknowledgedAlert;
    _alertAcknowledgedController.add(acknowledgedAlert);
  }

  /// Resolves an alert
  void resolveAlert(String alertId, {String? notes}) {
    final alert = _activeAlerts[alertId];
    if (alert == null) return;

    final resolvedAlert = alert.resolve(notes: notes);
    _activeAlerts.remove(alertId);
    _alertHistory.add(resolvedAlert);
    _alertResolvedController.add(resolvedAlert);
  }

  /// Suppresses alerts for a rule temporarily
  void suppressRule(String ruleId, Duration duration) {
    _lastSuppressionTime[ruleId] = DateTime.now().add(duration);
  }

  /// Configures notification channel
  void configureNotification(
      NotificationChannel channel, Map<String, dynamic> settings) {
    _notificationConfigs[channel] = NotificationConfig(
      channel: channel,
      settings: settings,
      isEnabled: true,
    );
  }

  /// Enables or disables notification channel
  void setNotificationEnabled(NotificationChannel channel, bool enabled) {
    final config = _notificationConfigs[channel];
    if (config == null) return;

    _notificationConfigs[channel] = NotificationConfig(
      channel: config.channel,
      settings: config.settings,
      isEnabled: enabled,
    );
  }

  /// Gets alert statistics
  Map<String, dynamic> getAlertStatistics({Duration? period}) {
    final now = DateTime.now();
    final since = period != null
        ? now.subtract(period)
        : now.subtract(const Duration(hours: 24));

    final recentAlerts =
        _alertHistory.where((a) => a.triggeredAt.isAfter(since)).toList();

    final severityCount = <String, int>{};
    final categoryCount = <String, int>{};
    final resolvedCount =
        recentAlerts.where((a) => a.status == AlertStatus.resolved).length;

    for (final alert in recentAlerts) {
      severityCount[alert.severity.name] =
          (severityCount[alert.severity.name] ?? 0) + 1;
      categoryCount[alert.category.name] =
          (categoryCount[alert.category.name] ?? 0) + 1;
    }

    final totalDuration = recentAlerts
        .where((a) => a.duration != null)
        .fold<Duration>(Duration.zero, (sum, a) => sum + a.duration!);

    final avgResolutionTime = recentAlerts.isNotEmpty &&
            totalDuration != Duration.zero
        ? Duration(
            milliseconds:
                (totalDuration.inMilliseconds / recentAlerts.length).round())
        : Duration.zero;

    return {
      'periodHours': period?.inHours ?? 24,
      'totalAlerts': recentAlerts.length,
      'activeAlerts': _activeAlerts.length,
      'resolvedAlerts': resolvedCount,
      'resolutionRate':
          recentAlerts.isNotEmpty ? resolvedCount / recentAlerts.length : 0.0,
      'averageResolutionTimeMinutes': avgResolutionTime.inMinutes,
      'severityBreakdown': severityCount,
      'categoryBreakdown': categoryCount,
      'enabledRules': _alertRules.values.where((r) => r.isEnabled).length,
      'totalRules': _alertRules.length,
    };
  }

  /// Creates predefined alert rules
  static List<AlertRule> createDefaultRules() => [
        // High failure rate
        AlertRule(
          id: 'high_failure_rate',
          name: 'High Failure Rate',
          description:
              'Triggered when sync failure rate exceeds 10% over 5 minutes',
          category: AlertCategory.failure,
          severity: AlertSeverity.high,
          condition: AlertCondition(
            metric: 'failure_rate',
            operator: ComparisonOperator.greaterThan,
            threshold: 0.1,
            timeWindow: const Duration(minutes: 5),
          ),
        ),

        // Critical failure rate
        AlertRule(
          id: 'critical_failure_rate',
          name: 'Critical Failure Rate',
          description:
              'Triggered when sync failure rate exceeds 25% over 2 minutes',
          category: AlertCategory.failure,
          severity: AlertSeverity.critical,
          condition: AlertCondition(
            metric: 'failure_rate',
            operator: ComparisonOperator.greaterThan,
            threshold: 0.25,
            timeWindow: const Duration(minutes: 2),
          ),
        ),

        // Slow response time
        AlertRule(
          id: 'slow_response_time',
          name: 'Slow Response Time',
          description:
              'Triggered when average response time exceeds 10 seconds',
          category: AlertCategory.performance,
          severity: AlertSeverity.medium,
          condition: AlertCondition(
            metric: 'avg_response_time',
            operator: ComparisonOperator.greaterThan,
            threshold: 10000, // milliseconds
            timeWindow: const Duration(minutes: 5),
          ),
        ),

        // Network connectivity issues
        AlertRule(
          id: 'network_disconnected',
          name: 'Network Disconnected',
          description: 'Triggered when network connectivity is lost',
          category: AlertCategory.network,
          severity: AlertSeverity.critical,
          condition: AlertCondition(
            metric: 'network_connected',
            operator: ComparisonOperator.equals,
            threshold: false,
            timeWindow: const Duration(seconds: 30),
          ),
        ),

        // High memory usage
        AlertRule(
          id: 'high_memory_usage',
          name: 'High Memory Usage',
          description: 'Triggered when memory usage exceeds 85%',
          category: AlertCategory.resource,
          severity: AlertSeverity.medium,
          condition: AlertCondition(
            metric: 'memory_pressure',
            operator: ComparisonOperator.greaterThan,
            threshold: 0.85,
            timeWindow: const Duration(minutes: 3),
          ),
        ),

        // Authentication failures
        AlertRule(
          id: 'auth_failures',
          name: 'Authentication Failures',
          description:
              'Triggered when authentication failures occur repeatedly',
          category: AlertCategory.authentication,
          severity: AlertSeverity.high,
          condition: AlertCondition(
            metric: 'auth_failure_count',
            operator: ComparisonOperator.greaterThan,
            threshold: 3,
            timeWindow: const Duration(minutes: 5),
          ),
        ),

        // Sync queue backup
        AlertRule(
          id: 'sync_queue_backup',
          name: 'Sync Queue Backup',
          description:
              'Triggered when sync queue has too many pending operations',
          category: AlertCategory.system,
          severity: AlertSeverity.medium,
          condition: AlertCondition(
            metric: 'pending_operations',
            operator: ComparisonOperator.greaterThan,
            threshold: 100,
            timeWindow: const Duration(minutes: 10),
          ),
        ),
      ];

  /// Initialize default alert rules
  void _initializeDefaultRules() {
    for (final rule in createDefaultRules()) {
      addAlertRule(rule);
    }
  }

  /// Starts evaluation loop for all rules
  void _startEvaluationLoop() {
    for (final rule in _alertRules.values) {
      if (rule.isEnabled) {
        _startRuleEvaluation(rule);
      }
    }
  }

  /// Starts evaluation for a specific rule
  void _startRuleEvaluation(AlertRule rule) {
    _stopRuleEvaluation(rule.id);

    _evaluationTimers[rule.id] = Timer.periodic(rule.evaluationInterval, (_) {
      _evaluateRule(rule);
    });

    // Immediate evaluation
    _evaluateRule(rule);
  }

  /// Stops evaluation for a specific rule
  void _stopRuleEvaluation(String ruleId) {
    _evaluationTimers[ruleId]?.cancel();
    _evaluationTimers.remove(ruleId);
  }

  /// Evaluates a specific alert rule
  void _evaluateRule(AlertRule rule) {
    // Check if rule is suppressed
    final suppressionTime = _lastSuppressionTime[rule.id];
    if (suppressionTime != null && DateTime.now().isBefore(suppressionTime)) {
      return;
    }

    // Check if alert already exists for this rule
    final existingAlert = _activeAlerts.values
        .where((alert) => alert.ruleId == rule.id)
        .firstOrNull;

    try {
      final conditionMet = _evaluateCondition(rule.condition);

      if (conditionMet && existingAlert == null) {
        _triggerAlert(rule);
      } else if (!conditionMet && existingAlert != null) {
        resolveAlert(existingAlert.id, notes: 'Condition no longer met');
      }
    } catch (e) {
      // Handle evaluation error
      print('Error evaluating rule ${rule.id}: $e');
    }
  }

  /// Evaluates an alert condition
  bool _evaluateCondition(AlertCondition condition) {
    final metricValue = _getMetricValue(condition.metric, condition.timeWindow);

    if (metricValue == null) return false;

    switch (condition.operator) {
      case ComparisonOperator.greaterThan:
        return _compareNumbers(
            metricValue, condition.threshold, (a, b) => a > b);
      case ComparisonOperator.greaterThanOrEqual:
        return _compareNumbers(
            metricValue, condition.threshold, (a, b) => a >= b);
      case ComparisonOperator.lessThan:
        return _compareNumbers(
            metricValue, condition.threshold, (a, b) => a < b);
      case ComparisonOperator.lessThanOrEqual:
        return _compareNumbers(
            metricValue, condition.threshold, (a, b) => a <= b);
      case ComparisonOperator.equals:
        return metricValue == condition.threshold;
      case ComparisonOperator.notEquals:
        return metricValue != condition.threshold;
      case ComparisonOperator.contains:
        return metricValue.toString().contains(condition.threshold.toString());
      case ComparisonOperator.notContains:
        return !metricValue.toString().contains(condition.threshold.toString());
    }
  }

  /// Compares two values numerically
  bool _compareNumbers(
      dynamic a, dynamic b, bool Function(num, num) compareFn) {
    final numA = _toNumber(a);
    final numB = _toNumber(b);

    if (numA == null || numB == null) return false;

    return compareFn(numA, numB);
  }

  /// Converts value to number
  num? _toNumber(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  /// Gets metric value for evaluation
  dynamic _getMetricValue(String metric, Duration timeWindow) {
    final performanceMetrics =
        _analyticsService.getPerformanceMetrics(period: timeWindow);
    final healthStatus = _analyticsService.getCurrentHealthStatus();

    switch (metric) {
      case 'failure_rate':
        return 1.0 - performanceMetrics.successRate;
      case 'avg_response_time':
        return performanceMetrics.averageOperationTime.inMilliseconds;
      case 'operations_per_second':
        return performanceMetrics.operationsPerSecond;
      case 'network_connected':
        // In real implementation, get from network monitor
        return true;
      case 'memory_pressure':
        // In real implementation, get from system monitor
        return math.Random().nextDouble() * 0.7; // Simulate < 85% usually
      case 'auth_failure_count':
        // Count auth-related failures
        final failures =
            _analyticsService.getFailureAnalysis(period: timeWindow);
        return failures.failuresByType['authentication'] ?? 0;
      case 'pending_operations':
        return _analyticsService.getActiveOperations().length;
      case 'health_score':
        return healthStatus.healthScore;
      default:
        return null;
    }
  }

  /// Triggers a new alert
  void _triggerAlert(AlertRule rule) {
    final alertId =
        'alert_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';

    final alert = SyncAlert(
      id: alertId,
      ruleId: rule.id,
      ruleName: rule.name,
      category: rule.category,
      severity: rule.severity,
      status: AlertStatus.active,
      title: rule.name,
      description: _generateAlertDescription(rule),
      context: _gatherAlertContext(rule),
      triggeredAt: DateTime.now(),
    );

    _activeAlerts[alertId] = alert;
    _alertTriggeredController.add(alert);

    // Send notifications
    _sendNotifications(alert, rule);

    // Set suppression window
    _lastSuppressionTime[rule.id] = DateTime.now().add(rule.suppressionWindow);
  }

  /// Generates alert description
  String _generateAlertDescription(AlertRule rule) {
    final condition = rule.condition;
    return '${rule.description}. '
        'Condition: ${condition.metric} ${condition.operator.name} ${condition.threshold} '
        'over ${condition.timeWindow.inMinutes} minutes.';
  }

  /// Gathers alert context
  Map<String, dynamic> _gatherAlertContext(AlertRule rule) {
    final metrics = _analyticsService.getPerformanceMetrics(
        period: rule.condition.timeWindow);
    final health = _analyticsService.getCurrentHealthStatus();

    return {
      'metricValue':
          _getMetricValue(rule.condition.metric, rule.condition.timeWindow),
      'threshold': rule.condition.threshold,
      'timeWindow': rule.condition.timeWindow.inMinutes,
      'performanceMetrics': {
        'successRate': metrics.successRate,
        'totalOperations': metrics.totalOperations,
        'averageResponseTime': metrics.averageOperationTime.inMilliseconds,
      },
      'healthStatus': {
        'healthLevel': health.healthLevel.name,
        'healthScore': health.healthScore,
        'activeIssues': health.activeIssues,
      },
    };
  }

  /// Sends notifications for an alert
  void _sendNotifications(SyncAlert alert, AlertRule rule) {
    for (final channel in rule.notificationChannels) {
      final config = _notificationConfigs[channel];

      if (config?.isEnabled == true) {
        _sendNotification(alert, channel, config!);
      }
    }
  }

  /// Sends notification via specific channel
  void _sendNotification(
      SyncAlert alert, NotificationChannel channel, NotificationConfig config) {
    switch (channel) {
      case NotificationChannel.inApp:
        // In-app notifications are handled by the stream
        break;
      case NotificationChannel.email:
        _sendEmailNotification(alert, config);
        break;
      case NotificationChannel.push:
        _sendPushNotification(alert, config);
        break;
      case NotificationChannel.webhook:
        _sendWebhookNotification(alert, config);
        break;
      case NotificationChannel.sms:
        _sendSmsNotification(alert, config);
        break;
      case NotificationChannel.slack:
        _sendSlackNotification(alert, config);
        break;
    }
  }

  /// Email notification (placeholder)
  void _sendEmailNotification(SyncAlert alert, NotificationConfig config) {
    // In real implementation, integrate with email service
    print('EMAIL: ${alert.title} - ${alert.description}');
  }

  /// Push notification (placeholder)
  void _sendPushNotification(SyncAlert alert, NotificationConfig config) {
    // In real implementation, integrate with push notification service
    print('PUSH: ${alert.title}');
  }

  /// Webhook notification (placeholder)
  void _sendWebhookNotification(SyncAlert alert, NotificationConfig config) {
    // In real implementation, send HTTP POST to webhook URL
    print('WEBHOOK: ${alert.toJson()}');
  }

  /// SMS notification (placeholder)
  void _sendSmsNotification(SyncAlert alert, NotificationConfig config) {
    // In real implementation, integrate with SMS service
    print('SMS: ${alert.title}');
  }

  /// Slack notification (placeholder)
  void _sendSlackNotification(SyncAlert alert, NotificationConfig config) {
    // In real implementation, send to Slack webhook
    print('SLACK: ${alert.title} - ${alert.description}');
  }

  /// Disposes the alerting service
  void dispose() {
    for (final timer in _evaluationTimers.values) {
      timer.cancel();
    }

    _alertTriggeredController.close();
    _alertResolvedController.close();
    _alertAcknowledgedController.close();
  }
}
