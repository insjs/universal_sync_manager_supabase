/// Test runner for Task 4.1: Intelligent Sync Optimization
///
/// This file runs the comprehensive demo for all intelligent sync
/// optimization features implemented in Task 4.1.
library;

import 'src/demos/usm_task4_1_demo.dart';

/// Main entry point for Task 4.1 demo
Future<void> main() async {
  try {
    await Task41Demo.run();
  } catch (e, stackTrace) {
    print('\n❌ Demo failed with error:');
    print('Error: $e');
    print('Stack trace: $stackTrace');
  }
}
