#!/usr/bin/env bash
# test/live_tests/phase1_pocketbase/run_tests.sh

echo "🚀 USM Live Tests - Phase 1: PocketBase Integration"
echo "=================================================="
echo ""

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if PocketBase is running
check_pocketbase() {
    local url="$1"
    echo "🔍 Checking PocketBase connectivity..."
    
    if command_exists curl; then
        if curl -s "$url/api/health" >/dev/null 2>&1; then
            echo "✅ PocketBase is running at $url"
            return 0
        else
            echo "❌ PocketBase is not responding at $url"
            return 1
        fi
    elif command_exists wget; then
        if wget -q --spider "$url/api/health" 2>/dev/null; then
            echo "✅ PocketBase is running at $url"
            return 0
        else
            echo "❌ PocketBase is not responding at $url"
            return 1
        fi
    else
        echo "⚠️ Cannot check PocketBase connectivity (curl/wget not available)"
        echo "   Please ensure PocketBase is running at $url"
        return 0
    fi
}

# Check if Dart is available
if ! command_exists dart; then
    echo "❌ Dart is not available. Please install Dart SDK."
    exit 1
fi

echo "✅ Dart SDK is available"

# Load configuration to get PocketBase URL
if [ -f "setup/config.yaml" ]; then
    POCKETBASE_URL=$(grep -E '^\s*url:' setup/config.yaml | sed 's/.*url:\s*//' | tr -d '"' | tr -d "'")
    if [ -n "$POCKETBASE_URL" ]; then
        if ! check_pocketbase "$POCKETBASE_URL"; then
            echo ""
            echo "💡 Quick PocketBase Setup:"
            echo "   1. Download PocketBase from https://pocketbase.io/docs/"
            echo "   2. Run: ./pocketbase serve"
            echo "   3. Create admin account at http://127.0.0.1:8090/_/"
            echo "   4. Update setup/config.yaml with admin credentials"
            echo ""
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    fi
else
    echo "⚠️ Configuration file not found. Please run setup first."
    exit 1
fi

echo ""
echo "🔧 Phase 1: PocketBase Setup"
echo "----------------------------"

# Run PocketBase setup
cd setup
if dart pocketbase_setup.dart --generate-data; then
    echo "✅ PocketBase setup completed"
else
    echo "❌ PocketBase setup failed"
    exit 1
fi
cd ..

echo ""
echo "🧪 Phase 2: Live Sync Tests"
echo "---------------------------"

# Run sync tests
cd tests
if dart sync_tests.dart; then
    echo "✅ Sync tests completed"
else
    echo "❌ Sync tests failed"
    exit 1
fi
cd ..

echo ""
echo "📊 Phase 3: Results Analysis"
echo "----------------------------"

# Show test results if they exist
if [ -d "tests/results" ]; then
    LATEST_REPORT=$(ls -t tests/results/test_report_*.json 2>/dev/null | head -n1)
    if [ -n "$LATEST_REPORT" ]; then
        echo "📄 Latest test report: $LATEST_REPORT"
        
        if command_exists jq; then
            echo ""
            echo "📊 Quick Summary:"
            jq -r '.summary | "Success Rate: \(.success_rate)%, Average Duration: \(.average_duration_ms)ms"' "$LATEST_REPORT" 2>/dev/null || echo "Report available but jq not installed for parsing"
        fi
    else
        echo "⚠️ No test reports found"
    fi
else
    echo "⚠️ Results directory not found"
fi

echo ""
echo "🎉 USM Live Tests Phase 1 Completed!"
echo ""
echo "💡 Next Steps:"
echo "   1. Review test results in tests/results/"
echo "   2. Check PocketBase Admin UI for created test data"
echo "   3. Run additional tests as needed"
echo "   4. Proceed to Phase 2 (Additional Backend Testing)"
