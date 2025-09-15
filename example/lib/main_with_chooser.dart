import 'package:flutter/material.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import both versions for easy switching
import 'supabase_test_page.dart';
import 'supabase_test_page_refactored.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint(
        '${record.level.name}: ${record.loggerName}: ${record.time}: ${record.message}');
  });

  // Initialize sqflite_ffi for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory for desktop
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://rsuuacugtplmuhlevbbq.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJzdXVhY3VndHBsbXVobGV2YmJxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMzMjQ4MTksImV4cCI6MjA2ODkwMDgxOX0.Cq7UUeSWmo9BcRQPbadTT3xj9vusL5MjOdmfTfb-7cE',
  );

  // Get device timezone
  final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
  final logger = Logger('main');
  logger.info('Current timezone: $currentTimeZone');

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universal Sync Manager - Supabase Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const AppHomePage(),
    );
  }
}

/// Home page that allows switching between original and refactored versions
class AppHomePage extends StatelessWidget {
  const AppHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('USM Supabase Test - Choose Version'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.sync,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 32),
              const Text(
                'Universal Sync Manager',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Supabase Integration Test',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        'Choose Test Version',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SupabaseTestPageRefactored(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.architecture),
                          label: const Text('Refactored Version'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Modular, maintainable architecture\n~140 lines (vs 762 original)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SupabaseTestPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.code),
                          label: const Text('Original Version'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Original monolithic implementation\n762 lines in single file',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const _InfoDialog(),
                  );
                },
                icon: const Icon(Icons.info_outline),
                label: const Text('View Refactoring Details'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoDialog extends StatelessWidget {
  const _InfoDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Refactoring Details'),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('The original 762-line file has been broken down into:'),
            SizedBox(height: 16),
            Text('📁 Models:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• test_result.dart - Test result data model'),
            SizedBox(height: 12),
            Text('⚙️ Services:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• test_configuration_service.dart - Config constants'),
            Text('• test_results_manager.dart - State management'),
            Text('• authentication_service.dart - Auth logic'),
            Text('• test_operations_service.dart - Core operations'),
            SizedBox(height: 12),
            Text('🎨 Widgets:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• status_display.dart - Status information'),
            Text('• test_action_buttons.dart - Action buttons'),
            Text('• test_results_list.dart - Results display'),
            SizedBox(height: 12),
            Text('📱 Main Page:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• supabase_test_page_refactored.dart - Composition'),
            SizedBox(height: 16),
            Text('Benefits:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('✅ 82% reduction in main file size'),
            Text('✅ Better separation of concerns'),
            Text('✅ Improved testability'),
            Text('✅ Enhanced maintainability'),
            Text('✅ Reusable components'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
