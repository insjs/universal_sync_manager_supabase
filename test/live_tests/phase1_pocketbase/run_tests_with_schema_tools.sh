#!/bin/bash

# Universal Sync Manager - Phase 1 PocketBase Live Tests (Unix)
# This script uses the existing schema management tools for setup

set -e

echo "🚀 Universal Sync Manager - Phase 1 PocketBase Live Tests"
echo "========================================================="

# Change to the setup directory
cd "$(dirname "$0")/setup"

echo "📋 Step 1: Setting up PocketBase test schemas..."
dart setup_with_schema_tools.dart

if [ $? -ne 0 ]; then
    echo "❌ PocketBase setup failed. Please check the output above."
    exit 1
fi

echo ""
echo "✅ PocketBase setup completed successfully!"
echo ""

# Change to tests directory
cd ../tests

echo "📋 Step 2: Running live tests..."
echo ""

# Run each test
echo "🧪 Running Sync Tests..."
dart sync_tests.dart

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 All Phase 1 PocketBase live tests completed successfully!"
    echo ""
    echo "📊 Summary:"
    echo "   ✅ PocketBase setup: Success"
    echo "   ✅ Live sync tests: Success"
    echo ""
    echo "🚀 Ready for Phase 2 development!"
else
    echo ""
    echo "❌ Some tests failed. Please check the output above."
    exit 1
fi
