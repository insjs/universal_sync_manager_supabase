#!/bin/bash

# Universal Sync Manager - Copy to Another Project Script
# Usage: ./copy_to_project.sh /path/to/target/project

if [ $# -eq 0 ]; then
    echo "Usage: $0 <target_project_path>"
    echo "Example: $0 /path/to/my/flutter/project"
    exit 1
fi

TARGET_PROJECT="$1"
USM_SOURCE_DIR="$(dirname "$0")/.."

# Validate target project
if [ ! -f "$TARGET_PROJECT/pubspec.yaml" ]; then
    echo "Error: $TARGET_PROJECT doesn't appear to be a Flutter project (no pubspec.yaml found)"
    exit 1
fi

echo "Copying Universal Sync Manager to: $TARGET_PROJECT"

# Create USM directory in target project
mkdir -p "$TARGET_PROJECT/lib/usm"

# Copy main export file
echo "Copying main export file..."
cp "$USM_SOURCE_DIR/lib/universal_sync_manager.dart" "$TARGET_PROJECT/lib/usm/"

# Copy src directory
echo "Copying source files..."
cp -r "$USM_SOURCE_DIR/lib/src" "$TARGET_PROJECT/lib/usm/"

# Create local import file
echo "Creating local import file..."
cat > "$TARGET_PROJECT/lib/usm_import.dart" << 'EOF'
// Universal Sync Manager - Local Import
// Import all USM functionality from the copied package files

export 'usm/universal_sync_manager.dart';

// Optional: Add any project-specific USM extensions here
EOF

echo "✅ Universal Sync Manager copied successfully!"
echo ""
echo "Next steps:"
echo "1. Add USM dependencies to your pubspec.yaml:"
echo "   - http: ^1.2.2"
echo "   - pocketbase: ^0.22.0" 
echo "   - supabase_flutter: ^2.8.0"
echo "   - yaml: ^3.1.3"
echo "   - sqlite3: ^2.4.6"
echo "   - path: ^1.9.0"
echo "   - uuid: ^4.5.1"
echo ""
echo "2. Run 'flutter pub get'"
echo ""
echo "3. Import USM in your code:"
echo "   import 'package:$(basename "$TARGET_PROJECT")/usm_import.dart';"
echo ""
echo "4. Start using USM classes in your project!"