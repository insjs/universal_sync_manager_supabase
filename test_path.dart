import 'dart:io';

void main() async {
  print('Testing file paths:');

  final paths = [
    'test/live_tests/phase1_pocketbase/setup/config.yaml',
    'test/live_tests/phase1_pocketbase/schemas/usm_test.yaml'
  ];

  for (final p in paths) {
    final f = File(p);
    final exists = await f.exists();
    print('$p exists: $exists');
    if (exists) {
      print('  Content size: ${await f.length()} bytes');
    }
  }
}
