/// Model representing a single test result
class TestResult {
  final String testName;
  final bool success;
  final String message;
  final DateTime timestamp;

  const TestResult({
    required this.testName,
    required this.success,
    required this.message,
    required this.timestamp,
  });

  /// Creates a successful test result
  factory TestResult.success(String testName, String message) {
    return TestResult(
      testName: testName,
      success: true,
      message: message,
      timestamp: DateTime.now(),
    );
  }

  /// Creates a failed test result
  factory TestResult.failure(String testName, String message) {
    return TestResult(
      testName: testName,
      success: false,
      message: message,
      timestamp: DateTime.now(),
    );
  }

  /// Creates a test result from an exception
  factory TestResult.fromError(String testName, dynamic error) {
    return TestResult(
      testName: testName,
      success: false,
      message: error.toString(),
      timestamp: DateTime.now(),
    );
  }

  /// Formats the timestamp for display
  String get formattedTime {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  /// Converts to a map for backward compatibility
  Map<String, dynamic> toMap() {
    return {
      'test': testName,
      'success': success,
      'message': message,
      'timestamp': timestamp,
    };
  }
}
