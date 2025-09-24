#!/bin/bash

# Universal Sync Manager - Copy to Another Project Script
# Usage: ./copy_usm_to_project.sh /path/to/target/project

set -e  # Exit on any error

if [ $# -eq 0 ]; then
    echo "Usage: $0 <target_project_path>"
    echo "Example: $0 /path/to/has_win_sb"
    echo "Example: $0 ../has_win_sb"
    exit 1
fi

TARGET_PROJECT="$1"
USM_SOURCE_DIR="$(dirname "$0")"

echo "🚀 Universal Sync Manager - Project Copy Tool"
echo "=============================================="
echo "Source: $USM_SOURCE_DIR"
echo "Target: $TARGET_PROJECT"
echo ""

# Validate target project
if [ ! -d "$TARGET_PROJECT" ]; then
    echo "❌ Error: Target directory $TARGET_PROJECT doesn't exist"
    exit 1
fi

if [ ! -f "$TARGET_PROJECT/pubspec.yaml" ]; then
    echo "⚠️  Warning: $TARGET_PROJECT doesn't appear to be a Flutter project (no pubspec.yaml found)"
    echo "Do you want to continue anyway? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 1
    fi
fi

echo "📁 Creating USM directory structure..."

# Create USM directory in target project
mkdir -p "$TARGET_PROJECT/lib/usm"

# Copy main export file
echo "📄 Copying main export file..."
cp "$USM_SOURCE_DIR/lib/universal_sync_manager.dart" "$TARGET_PROJECT/lib/usm/"

# Copy src directory
echo "📦 Copying source files..."
cp -r "$USM_SOURCE_DIR/lib/src" "$TARGET_PROJECT/lib/usm/"

# Create local import file
echo "🔗 Creating local import file..."
cat > "$TARGET_PROJECT/lib/usm_import.dart" << 'EOF'
// Universal Sync Manager - Local Import
// Import all USM functionality from the copied package files

export 'usm/universal_sync_manager.dart';

// Optional: Add any project-specific USM extensions here
EOF

# Create dependencies info file
echo "📝 Creating dependencies info file..."
cat > "$TARGET_PROJECT/USM_DEPENDENCIES.md" << 'EOF'
# Universal Sync Manager Dependencies

Add these dependencies to your `pubspec.yaml` file:

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

## Usage

After adding the dependencies and running `flutter pub get`, import USM in your code:

```dart
import 'package:your_project_name/usm_import.dart';

// Example usage
class MyService {
  late UniversalSyncOperationService syncService;
  
  void initializeSync() {
    // Initialize your sync service here
  }
}
```

## Next Steps

1. Add the dependencies above to your pubspec.yaml
2. Run `flutter pub get`
3. Import USM using: `import 'package:your_project_name/usm_import.dart';`
4. Start using USM classes in your project!
EOF

echo ""
echo "✅ Universal Sync Manager copied successfully!"
echo ""
echo "📋 Summary of what was copied:"
echo "  ✓ lib/usm/universal_sync_manager.dart (main export file)"
echo "  ✓ lib/usm/src/ (all source files)"
echo "  ✓ lib/usm_import.dart (convenience import file)"
echo "  ✓ USM_DEPENDENCIES.md (setup instructions)"
echo ""
echo "📖 Next steps:"
echo "  1. Check USM_DEPENDENCIES.md for required dependencies"
echo "  2. Add dependencies to your pubspec.yaml"
echo "  3. Run 'flutter pub get'"
echo "  4. Import USM: import 'package:$(basename "$TARGET_PROJECT")/usm_import.dart';"
echo ""
echo "🎉 Ready to use Universal Sync Manager in your project!"