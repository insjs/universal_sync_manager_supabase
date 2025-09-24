# Manual Copy Instructions: Universal Sync Manager to has_win_sb

Since the `has_win_sb` repository is private and cannot be directly cloned in this environment, here are the step-by-step manual instructions to copy the Universal Sync Manager to your repository.

## Step 1: Prepare Your has_win_sb Repository

1. Clone your `has_win_sb` repository locally:
   ```bash
   git clone https://github.com/insjs/has_win_sb.git
   cd has_win_sb
   ```

## Step 2: Copy USM Files

### Option A: Using the Copy Script (Recommended)

1. Download the `copy_usm_to_project.sh` script from this repository
2. Make it executable: `chmod +x copy_usm_to_project.sh`
3. Run: `./copy_usm_to_project.sh /path/to/has_win_sb`

### Option B: Manual File Copy

1. **Create the USM directory structure:**
   ```bash
   mkdir -p lib/usm
   ```

2. **Copy the main export file:**
   - Copy `universal_sync_manager.dart` from this repo's `lib/` folder to `has_win_sb/lib/usm/`

3. **Copy the source files:**
   - Copy the entire `src/` directory from this repo's `lib/src/` to `has_win_sb/lib/usm/src/`

4. **Create the import convenience file:**
   Create `has_win_sb/lib/usm_import.dart` with this content:
   ```dart
   // Universal Sync Manager - Local Import
   // Import all USM functionality from the copied package files

   export 'usm/universal_sync_manager.dart';

   // Optional: Add any project-specific USM extensions here
   ```

## Step 3: Update Dependencies

Add these dependencies to your `has_win_sb/pubspec.yaml`:

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
```

## Step 4: Install Dependencies

```bash
cd /path/to/has_win_sb
flutter pub get
```

## Step 5: Use USM in Your Code

Import USM in your Dart files:
```dart
import 'package:has_win_sb/usm_import.dart';

// Now you can use all USM classes
class MyService {
  late UniversalSyncOperationService syncService;
  late SupabaseSyncAdapter supabaseAdapter;
  
  void initializeSync() async {
    supabaseAdapter = SupabaseSyncAdapter();
    syncService = UniversalSyncOperationService();
    
    // Configure and use USM...
  }
}
```

## Files You Need to Copy

### Essential Files:
- `lib/universal_sync_manager.dart` → `has_win_sb/lib/usm/universal_sync_manager.dart`
- `lib/src/` (entire directory) → `has_win_sb/lib/usm/src/`

### Generated Files:
- Create `has_win_sb/lib/usm_import.dart` (convenience import)
- Update `has_win_sb/pubspec.yaml` with dependencies

## Directory Structure After Copy

```
has_win_sb/
├── lib/
│   ├── usm_import.dart                    # ← Create this
│   ├── usm/
│   │   ├── universal_sync_manager.dart    # ← Copy from USM repo
│   │   └── src/                           # ← Copy entire src/ directory
│   │       ├── adapters/
│   │       ├── config/
│   │       ├── core/
│   │       ├── interfaces/
│   │       ├── models/
│   │       ├── platform/
│   │       └── services/
│   └── ... # your existing files
├── pubspec.yaml                           # ← Update with USM dependencies
└── ... # your existing files
```

## Verification

After copying, verify the setup:

1. Run `flutter pub get` successfully
2. Try importing: `import 'package:has_win_sb/usm_import.dart';`
3. Verify you can reference USM classes like `UniversalSyncOperationService`

## Troubleshooting

- **Import errors**: Make sure the file paths are correct and `flutter pub get` completed successfully
- **Missing dependencies**: Check that all USM dependencies are added to pubspec.yaml
- **Path issues**: Ensure the `usm/` folder is directly under `lib/` in your has_win_sb project

## Next Steps

Once USM is integrated:
1. Configure your chosen backend adapter (Supabase, PocketBase, etc.)
2. Set up your data models to use USM's sync capabilities
3. Initialize and start using the sync manager in your app

For detailed usage examples, refer to the Universal Sync Manager documentation and test files.