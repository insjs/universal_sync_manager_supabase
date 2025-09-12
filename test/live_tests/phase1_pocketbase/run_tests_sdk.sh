#!/bin/bash
# test/live_tests/phase1_pocketbase/run_tests_sdk.sh

echo "🚀 USM Live Tests - Phase 1: PocketBase Integration (SDK)"
echo "========================================================"
echo

# Check if Dart is available
if ! command -v dart &> /dev/null; then
    echo "❌ Dart is not available. Please install Dart SDK."
    exit 1
fi

echo "✅ Dart SDK is available"

# Check if config file exists
if [ ! -f "setup/config.yaml" ]; then
    echo "⚠️ Configuration file not found. Please run setup first."
    exit 1
fi

echo "✅ Configuration file found"

# Step 1: Setup PocketBase schemas using existing tools
echo
echo "📋 Step 1: Setting up PocketBase schemas..."
echo

cd ../../../tools
if ! dart pocketbase_schema_manager.dart; then
    echo "❌ Schema setup failed"
    cd ../test/live_tests/phase1_pocketbase
    exit 1
fi

cd ../test/live_tests/phase1_pocketbase
echo "✅ Schema setup completed"

# Step 2: Run live sync tests with PocketBase SDK
echo
echo "🧪 Step 2: Running live sync tests with PocketBase SDK..."
echo

if ! dart tests/sync_tests_with_sdk.dart; then
    echo "❌ Sync tests failed"
    exit 1
fi

echo "✅ All tests completed successfully!"

echo
echo "🎯 Summary:"
echo "✓ Schema management using existing tools"
echo "✓ Live sync tests using PocketBase SDK"
echo "✓ HTTPS/TLS support built-in"
echo "✓ Better error handling and authentication"
echo
