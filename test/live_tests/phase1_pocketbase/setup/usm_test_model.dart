// USM Live Testing Model
// Generated on: 2025-08-14T10:22:50.562807
// Table: usm_test

import '../../../lib/src/models/usm_syncable_model.dart';

/// UsmTest model for USM live testing
class UsmTest with SyncableModel {
  /// Unique identifier (UUID format)
  final String? id;

  /// Organization identifier for multi-tenancy
  final String organizationId;

  /// Human-readable test name
  final String testName;

  /// Detailed description of the test case
  final String? testDescription;

  /// Category: 'sync', 'conflict', 'performance', 'edge_case'
  final String? testCategory;

  /// Active status (1=active, 0=inactive)
  final int? isActive;

  /// Priority level (1-10, higher = more important)
  final int? priority;

  /// Completion percentage (0.0 to 1.0)
  final double? completionPercentage;

  /// JSON-encoded test data payload
  final String? testData;

  /// JSON array of tags for categorization
  final String? tags;

  /// Test execution time in milliseconds
  final double? executionTime;

  /// Last test result: 'passed', 'failed', 'skipped'
  final String? lastResult;

  /// Error message if test failed
  final String? errorMessage;

  /// JSON configuration object for test parameters
  final String? config;

  /// User ID who created this record
  final String createdBy;

  /// User ID who last updated this record
  final String updatedBy;

  /// ISO timestamp when record was created
  final String? createdAt;

  /// ISO timestamp of last modification
  final String? updatedAt;

  /// ISO timestamp when record was deleted (soft delete)
  final String? deletedAt;

  /// Last successful sync timestamp (ISO format)
  final String? lastSyncedAt;

  /// Pending sync flag (1=needs sync, 0=synced)
  final int? isDirty;

  /// Incremental sync version number
  final int? syncVersion;

  /// Soft delete flag (1=deleted, 0=active)
  final int? isDeleted;

  /// Constructor
  const UsmTest({
    this.id,
    required this.organizationId,
    required this.testName,
    this.testDescription,
    this.testCategory,
    this.isActive,
    this.priority,
    this.completionPercentage,
    this.testData,
    this.tags,
    this.executionTime,
    this.lastResult,
    this.errorMessage,
    this.config,
    required this.createdBy,
    required this.updatedBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.lastSyncedAt,
    this.isDirty,
    this.syncVersion,
    this.isDeleted,
  });

  /// Create from Map
  factory UsmTest.fromMap(Map<String, dynamic> map) {
    return UsmTest(
      id: map['id'] as String?,
      organizationId: map['organizationId'] as String?,
      testName: map['testName'] as String?,
      testDescription: map['testDescription'] as String?,
      testCategory: map['testCategory'] as String?,
      isActive: map['isActive'] as int?,
      priority: map['priority'] as int?,
      completionPercentage: map['completionPercentage'] as double?,
      testData: map['testData'] as String?,
      tags: map['tags'] as String?,
      executionTime: map['executionTime'] as double?,
      lastResult: map['lastResult'] as String?,
      errorMessage: map['errorMessage'] as String?,
      config: map['config'] as String?,
      createdBy: map['createdBy'] as String?,
      updatedBy: map['updatedBy'] as String?,
      createdAt: map['createdAt'] as String?,
      updatedAt: map['updatedAt'] as String?,
      deletedAt: map['deletedAt'] as String?,
      lastSyncedAt: map['lastSyncedAt'] as String?,
      isDirty: map['isDirty'] as int?,
      syncVersion: map['syncVersion'] as int?,
      isDeleted: map['isDeleted'] as int?,
    );
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organizationId': organizationId,
      'testName': testName,
      'testDescription': testDescription,
      'testCategory': testCategory,
      'isActive': isActive,
      'priority': priority,
      'completionPercentage': completionPercentage,
      'testData': testData,
      'tags': tags,
      'executionTime': executionTime,
      'lastResult': lastResult,
      'errorMessage': errorMessage,
      'config': config,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deletedAt': deletedAt,
      'lastSyncedAt': lastSyncedAt,
      'isDirty': isDirty,
      'syncVersion': syncVersion,
      'isDeleted': isDeleted,
    };
  }

  @override
  UsmTest copyWith({
    String? id,
    String? organizationId,
    String? testName,
    String? testDescription,
    String? testCategory,
    int? isActive,
    int? priority,
    double? completionPercentage,
    String? testData,
    String? tags,
    double? executionTime,
    String? lastResult,
    String? errorMessage,
    String? config,
    String? createdBy,
    String? updatedBy,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
    String? lastSyncedAt,
    int? isDirty,
    int? syncVersion,
    int? isDeleted,
  }) {
    return UsmTest(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      testName: testName ?? this.testName,
      testDescription: testDescription ?? this.testDescription,
      testCategory: testCategory ?? this.testCategory,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      testData: testData ?? this.testData,
      tags: tags ?? this.tags,
      executionTime: executionTime ?? this.executionTime,
      lastResult: lastResult ?? this.lastResult,
      errorMessage: errorMessage ?? this.errorMessage,
      config: config ?? this.config,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isDirty: isDirty ?? this.isDirty,
      syncVersion: syncVersion ?? this.syncVersion,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
