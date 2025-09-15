import 'package:flutter/material.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_test_page.dart';

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
      home: const SupabaseTestPage(),
    );
  }
}
