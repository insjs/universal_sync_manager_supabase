import 'package:flutter/material.dart';
import '../models/test_result.dart';

/// Widget that displays a list of test results
class TestResultsList extends StatelessWidget {
  final List<TestResult> results;

  const TestResultsList({
    super.key,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const Center(
        child: Text(
          'No test results yet. Run some tests to see results here.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return Card(
          child: ListTile(
            leading: Icon(
              result.success ? Icons.check_circle : Icons.error,
              color: result.success ? Colors.green : Colors.red,
            ),
            title: Text(result.testName),
            subtitle: Text(result.message),
            trailing: Text(
              result.formattedTime,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
      },
    );
  }
}
