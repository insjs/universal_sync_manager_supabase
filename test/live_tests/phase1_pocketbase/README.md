# Phase 1: PocketBase Live Testing

## Overview

Phase 1 provides comprehensive live testing of the Universal Sync Manager against a real PocketBase backend. This phase validates bidirectional sync functionality, data integrity, and conflict resolution.

## Objectives

1. ✅ **Schema Deployment**: Create and manage test schemas in PocketBase
2. ✅ **Local Database Setup**: Initialize SQLite database with test schema
3. ✅ **Bidirectional Sync**: Test local-to-remote and remote-to-local synchronization
4. ✅ **Data Integrity**: Validate data consistency across sync operations
5. ✅ **Conflict Resolution**: Test conflict detection and resolution mechanisms
6. ✅ **Performance Monitoring**: Measure sync performance and resource usage

## Test Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   SQLite DB     │◄──►│ Universal Sync   │◄──►│  PocketBase     │
│   (usmtest.db)  │    │    Manager       │    │   (Remote)      │
│                 │    │                  │    │                 │
│ • usm_test      │    │ • Sync Logic     │    │ • usm_test      │
│ • Local Data    │    │ • Conflict Res   │    │ • Remote Data   │
│ • Audit Fields  │    │ • Analytics      │    │ • Collections   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Directory Structure

```
phase1_pocketbase/
├── README.md                    # This documentation
├── setup/
│   ├── config.yaml             # Test configuration
│   ├── database_setup.dart     # SQLite database initialization
│   ├── pocketbase_setup.dart   # PocketBase collection setup
│   └── test_data_generator.dart # Test data generation
├── schemas/
│   └── usm_test.yaml           # Test table schema definition
├── tests/
│   ├── sync_test_runner.dart   # Main test orchestrator
│   ├── local_to_remote_test.dart # Local→Remote sync testing
│   ├── remote_to_local_test.dart # Remote→Local sync testing
│   ├── bidirectional_test.dart   # Full bidirectional testing
│   ├── conflict_resolution_test.dart # Conflict scenarios
│   └── performance_test.dart      # Performance and stress testing
└── validation/
    ├── data_validator.dart     # Data integrity validation
    ├── report_generator.dart   # Test result reporting
    └── metrics_collector.dart  # Performance metrics
```

## Test Scenarios

### 1. Basic Sync Operations
- **Create**: Add new records locally, sync to remote
- **Read**: Fetch remote records to local database
- **Update**: Modify local records, sync changes to remote
- **Delete**: Soft delete records, sync deletion to remote

### 2. Conflict Resolution
- **Same Field Updates**: Modify same field on both sides
- **Timestamp Conflicts**: Create timing-based conflicts
- **Delete vs Update**: Delete locally while updating remotely
- **Field-Level Conflicts**: Test enhanced conflict resolution

### 3. Edge Cases
- **Network Interruption**: Test sync resilience during network failures
- **Large Datasets**: Sync performance with substantial data volumes
- **Concurrent Operations**: Multiple sync operations simultaneously
- **Data Corruption**: Handle malformed or invalid data

### 4. Performance Testing
- **Sync Speed**: Measure time for various dataset sizes
- **Memory Usage**: Monitor resource consumption during sync
- **Network Efficiency**: Measure bandwidth usage and optimization
- **Battery Impact**: Test on mobile platforms

## Quick Start

### Prerequisites

1. **PocketBase Server**: Running locally or accessible remotely
   ```bash
   # Download PocketBase and run locally
   ./pocketbase serve --http=127.0.0.1:8090
   ```

2. **Admin Account**: Create admin user in PocketBase UI
   - Access: http://localhost:8090/_/
   - Create admin credentials

3. **Configuration**: Update `setup/config.yaml` with your settings

### Run Tests

#### Option 1: Automated (Recommended)
```bash
# Navigate to phase 1 directory
cd test/live_tests/phase1_pocketbase

# On Linux/macOS
./run_tests.sh

# On Windows
run_tests.bat
```

#### Option 2: Manual Step-by-Step
```bash
# Navigate to phase 1 directory
cd test/live_tests/phase1_pocketbase

# Setup PocketBase collections and test data
dart run setup/pocketbase_setup.dart --generate-data

# Run comprehensive sync tests
dart run tests/sync_tests.dart

# Check results
ls results/
```

#### Option 3: Individual Components (Advanced)
```bash
# Setup databases and schemas
dart run setup/database_setup.dart
dart run setup/pocketbase_setup.dart

# Run specific test scenarios
dart run tests/local_to_remote_test.dart
dart run tests/remote_to_local_test.dart
dart run tests/bidirectional_test.dart
dart run tests/conflict_resolution_test.dart
```

## Configuration

Edit `setup/config.yaml` to customize test parameters:

```yaml
# PocketBase connection
pocketbase:
  url: "http://localhost:8090"
  admin_email: "admin@example.com"
  admin_password: "admin123"
  
# Local database
database:
  path: "usmtest.db"
  reset_on_start: true
  
# Test parameters
testing:
  record_count: 100
  batch_size: 25
  timeout_seconds: 30
  enable_logging: true
  generate_reports: true
```

## Expected Results

✅ **Successful Sync**: All records sync bidirectionally without data loss  
✅ **Conflict Resolution**: Conflicts detected and resolved using configured strategies  
✅ **Data Integrity**: Checksums and validation confirm data consistency  
✅ **Performance**: Sync operations complete within acceptable time limits  
✅ **Error Handling**: Network failures and edge cases handled gracefully  

### Test Reports

After running tests, detailed reports are generated in the `results/` directory:

- **test_report.json**: Comprehensive JSON report with all test results
- **Console Output**: Real-time progress and summary statistics
- **Expected Metrics**: 6/6 tests passing, 95%+ success rate, <500ms average duration  

## Troubleshooting

### Common Issues

1. **Connection Failed**: Verify PocketBase URL and admin credentials
2. **Schema Errors**: Check YAML schema syntax and field definitions
3. **Sync Timeouts**: Increase timeout values for large datasets
4. **Permission Denied**: Ensure admin user has proper collection access

### Debug Mode

Enable detailed logging by setting `enable_logging: true` in config.yaml:

```bash
# Run with verbose output
dart run tests/sync_test_runner.dart --verbose
```

## Next Steps

After completing Phase 1:
1. Review test results and performance metrics
2. Address any issues identified during testing
3. Proceed to [Phase 2: Supabase Testing](../phase2_supabase/README.md)
4. Consider expanding test scenarios based on findings

---

**Status**: ✅ Ready for Implementation  
**Estimated Duration**: 2-4 hours setup + testing  
**Dependencies**: PocketBase server, Flutter/Dart environment
