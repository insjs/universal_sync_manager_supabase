# Live Testing Framework for Universal Sync Manager

This directory contains comprehensive live testing scenarios for validating the Universal Sync Manager against real backend services.

## Overview

The live testing framework follows a phased approach to validate sync functionality with actual backend services, starting with PocketBase and expanding to other backends.

## Testing Phases

### Phase 1: PocketBase Live Testing ✅
- **Objective**: Validate USM sync functionality against a real PocketBase instance
- **Components**:
  - Schema creation and deployment
  - Local SQLite database setup
  - Bidirectional sync testing
  - Data integrity validation

### Phase 2: Supabase Live Testing 🔄
- **Objective**: Validate USM sync with Supabase PostgreSQL backend
- **Components**: Similar to Phase 1 but with Supabase-specific configurations

### Phase 3: Multi-Backend Testing 🔄
- **Objective**: Test sync across multiple backends simultaneously
- **Components**: Cross-backend data consistency and conflict resolution

### Phase 4: Performance and Stress Testing 🔄
- **Objective**: Validate performance under realistic load conditions
- **Components**: Large dataset sync, concurrent user simulation, network condition testing

## Directory Structure

```
live_tests/
├── README.md                     # This file
├── phase1_pocketbase/            # Phase 1: PocketBase testing
│   ├── README.md                 # Phase 1 documentation
│   ├── setup/                    # Setup scripts and configurations
│   ├── schemas/                  # Test schemas
│   ├── tests/                    # Test implementations
│   └── validation/               # Validation and reporting
├── phase2_supabase/              # Phase 2: Supabase testing
├── phase3_multi_backend/         # Phase 3: Multi-backend testing
├── phase4_performance/           # Phase 4: Performance testing
└── shared/                       # Shared utilities and helpers
```

## Quick Start

1. **Prerequisites**:
   - Flutter/Dart development environment
   - PocketBase server (local or remote)
   - SQLite support
   - Network connectivity

2. **Run Phase 1 Tests**:
   ```bash
   cd test/live_tests/phase1_pocketbase
   dart run tests/full_sync_test.dart
   ```

3. **View Results**:
   - Test results are logged to console and files
   - Validation reports are generated automatically
   - Performance metrics are captured for analysis

## Test Data Strategy

- **Synthetic Data**: Generated test data following realistic patterns
- **Schema Validation**: Ensures data integrity across sync operations
- **Conflict Simulation**: Deliberate conflicts to test resolution mechanisms
- **Edge Cases**: Boundary conditions, large datasets, network failures

## Monitoring and Reporting

- Real-time sync progress monitoring
- Comprehensive test result reporting
- Performance metrics collection
- Error logging and analysis
- Data integrity verification

## Security Considerations

- Test environments are isolated from production
- Sensitive data is never used in testing
- Authentication credentials are configurable
- All test data is cleanly removable

---

**Next**: Start with [Phase 1 PocketBase Testing](phase1_pocketbase/README.md)
