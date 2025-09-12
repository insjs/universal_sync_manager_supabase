// Direct PocketBase health check test to verify server is running

import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'dart:convert';

void main() {
  group('PocketBase Server Tests', () {
    test('PocketBase Health Check', () async {
      try {
        print('🔗 Testing direct connection to PocketBase...');

        final client = HttpClient();
        final uri = Uri.parse('http://localhost:8090/api/health');
        final request = await client.openUrl('GET', uri);
        final response = await request.close();

        print('   Status code: ${response.statusCode}');
        print('   Headers: ${response.headers}');

        final responseBody = await response.transform(utf8.decoder).join();
        print('   Response: $responseBody');

        expect(response.statusCode, equals(200));

        client.close();
        print('✅ PocketBase server is responding');
      } catch (e) {
        print('❌ PocketBase health check failed: $e');
        fail('PocketBase server not accessible: $e');
      }
    });
  });
}
