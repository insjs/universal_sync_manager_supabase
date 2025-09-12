import 'package:flutter/foundation.dart';
import '../models/test_result.dart';

/// Service that manages test results and state for the USM example app
class TestResultsManager extends ChangeNotifier {
  final List<TestResult> _results = [];
  String _status = 'Not initialized';
  bool _isConnected = false;
  bool _isAuthenticated = false;

  // Getters
  List<TestResult> get results => List.unmodifiable(_results);
  String get status => _status;
  bool get isConnected => _isConnected;
  bool get isAuthenticated => _isAuthenticated;

  /// Adds a test result and notifies listeners
  void addResult(TestResult result) {
    _results.add(result);
    notifyListeners();
  }

  /// Adds a successful test result
  void addSuccess(String testName, String message) {
    addResult(TestResult.success(testName, message));
  }

  /// Adds a failed test result
  void addFailure(String testName, String message) {
    addResult(TestResult.failure(testName, message));
  }

  /// Adds a test result from an exception
  void addError(String testName, dynamic error) {
    addResult(TestResult.fromError(testName, error));
  }

  /// Updates the connection status
  void updateConnectionStatus(bool connected) {
    _isConnected = connected;
    notifyListeners();
  }

  /// Updates the authentication status
  void updateAuthenticationStatus(bool authenticated) {
    _isAuthenticated = authenticated;
    notifyListeners();
  }

  /// Updates the overall status message
  void updateStatus(String status) {
    _status = status;
    notifyListeners();
  }

  /// Clears all test results
  void clearResults() {
    _results.clear();
    notifyListeners();
  }

  /// Resets all state to initial values
  void reset() {
    _results.clear();
    _status = 'Not initialized';
    _isConnected = false;
    _isAuthenticated = false;
    notifyListeners();
  }

  /// Gets the number of successful tests
  int get successCount => _results.where((r) => r.success).length;

  /// Gets the number of failed tests
  int get failureCount => _results.where((r) => !r.success).length;

  /// Gets the total number of tests
  int get totalCount => _results.length;

  /// Gets the success rate as a percentage
  double get successRate {
    if (totalCount == 0) return 0.0;
    return (successCount / totalCount) * 100;
  }

  /// Converts results to legacy format for backward compatibility
  List<Map<String, dynamic>> get legacyResults {
    return _results.map((r) => r.toMap()).toList();
  }
}
