import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  print('=== SQLite Database Location Checker ===\n');

  // Check platform
  print('Platform: ${Platform.operatingSystem}');

  try {
    // For desktop platforms (like your Windows system)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String mainDbPath = join(appDocDir.path, 'usm_example.db');

      print('\n--- Main Database (database_helper.dart) ---');
      print('Path: $mainDbPath');
      print('Exists: ${await File(mainDbPath).exists()}');

      if (await File(mainDbPath).exists()) {
        final stat = await File(mainDbPath).stat();
        print('Size: ${stat.size} bytes');
        print('Modified: ${stat.modified}');
      }
    }

    // For mobile platforms (default database path)
    try {
      final String mobileDbPath =
          join(await getDatabasesPath(), 'usm_example.db');
      print('\n--- Mobile-style Database Path ---');
      print('Path: $mobileDbPath');
      print('Exists: ${await File(mobileDbPath).exists()}');

      if (await File(mobileDbPath).exists()) {
        final stat = await File(mobileDbPath).stat();
        print('Size: ${stat.size} bytes');
        print('Modified: ${stat.modified}');
      }
    } catch (e) {
      print('Mobile database path not available: $e');
    }

    // Check test database (local_sample_data.dart)
    try {
      final String testDbPath = join(await getDatabasesPath(), 'usm_test.db');
      print('\n--- Test Database (local_sample_data.dart) ---');
      print('Path: $testDbPath');
      print('Exists: ${await File(testDbPath).exists()}');

      if (await File(testDbPath).exists()) {
        final stat = await File(testDbPath).stat();
        print('Size: ${stat.size} bytes');
        print('Modified: ${stat.modified}');
      }
    } catch (e) {
      print('Test database path not available: $e');
    }

    // List all .db files in the documents directory
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      print('\n--- All .db files in Documents directory ---');

      try {
        await for (final entity in appDocDir.list(recursive: true)) {
          if (entity is File && entity.path.endsWith('.db')) {
            final stat = await entity.stat();
            print(
                '${entity.path} (${stat.size} bytes, modified: ${stat.modified})');
          }
        }
      } catch (e) {
        print('Error listing files: $e');
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}
