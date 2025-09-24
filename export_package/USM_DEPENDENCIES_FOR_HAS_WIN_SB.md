# Universal Sync Manager Dependencies

Add these dependencies to your `pubspec.yaml` file in the `has_win_sb` project:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Universal Sync Manager Dependencies
  http: ^1.2.2
  pocketbase: ^0.22.0
  supabase_flutter: ^2.8.0
  yaml: ^3.1.3
  sqlite3: ^2.4.6
  path: ^1.9.0
  uuid: ^4.5.1
  
  # Your existing dependencies...

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  # Your existing dev_dependencies...
```

## Environment Requirements

```yaml
environment:
  sdk: ^3.6.2
  flutter: ">=3.10.0"
```

## Usage

After adding the dependencies and running `flutter pub get`, import USM in your code:

```dart
import 'package:has_win_sb/usm_import.dart';

// Example usage
class MyService {
  late UniversalSyncOperationService syncService;
  
  void initializeSync() {
    // Initialize your sync service here
  }
}
```

## Installation Steps

1. Copy all USM files to your `has_win_sb` project
2. Add the dependencies above to your pubspec.yaml
3. Run `flutter pub get`
4. Import USM using: `import 'package:has_win_sb/usm_import.dart';`
5. Start using USM classes in your project!