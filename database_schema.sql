-- USM Live Testing Database Schema
-- Generated on: 2025-08-14T11:50:57.029146
-- Table: usm_test

PRAGMA foreign_keys = ON;

-- Create main table
CREATE TABLE IF NOT EXISTS usm_test (
    localId TEXT NOT NULL, -- Local UUID for tracking records across sync operations
    organizationId TEXT NOT NULL, -- Organization identifier for multi-tenancy
    testName TEXT NOT NULL, -- Human-readable test name
    testDescription TEXT, -- Detailed description of the test case
    testCategory TEXT, -- Category: 'sync', 'conflict', 'performance', 'edge_case'
    isActive INTEGER DEFAULT 1, -- Active status (1=active, 0=inactive)
    priority INTEGER DEFAULT 5, -- Priority level (1-10, higher = more important)
    completionPercentage REAL DEFAULT 0.0, -- Completion percentage (0.0 to 1.0)
    testData TEXT, -- JSON-encoded test data payload
    tags TEXT, -- JSON array of tags for categorization
    executionTime REAL, -- Test execution time in milliseconds
    lastResult TEXT, -- Last test result: 'passed', 'failed', 'skipped'
    errorMessage TEXT, -- Error message if test failed
    config TEXT, -- JSON configuration object for test parameters
    createdBy TEXT NOT NULL, -- User ID who created this record
    updatedBy TEXT NOT NULL, -- User ID who last updated this record
    createdAt TEXT, -- ISO timestamp when record was created
    updatedAt TEXT, -- ISO timestamp of last modification
    deletedAt TEXT, -- ISO timestamp when record was deleted (soft delete)
    lastSyncedAt TEXT, -- Last successful sync timestamp (ISO format)
    isDirty INTEGER DEFAULT 1, -- Pending sync flag (1=needs sync, 0=synced)
    syncVersion INTEGER DEFAULT 0, -- Incremental sync version number
    isDeleted INTEGER DEFAULT 0 -- Soft delete flag (1=deleted, 0=active)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_usm_test_org_id 
    ON usm_test (organizationId);
CREATE INDEX IF NOT EXISTS idx_usm_test_category_active 
    ON usm_test (testCategory, isActive);
CREATE INDEX IF NOT EXISTS idx_usm_test_sync_status 
    ON usm_test (isDirty, isDeleted);
CREATE INDEX IF NOT EXISTS idx_usm_test_created 
    ON usm_test (createdAt);
CREATE INDEX IF NOT EXISTS idx_usm_test_updated 
    ON usm_test (updatedAt);

