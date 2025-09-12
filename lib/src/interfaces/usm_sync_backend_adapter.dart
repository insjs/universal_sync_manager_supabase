import '../models/usm_sync_backend_capabilities.dart';
import '../models/usm_sync_backend_configuration.dart';  /// Creates a query for dirty records (pending sync)
  factory SyncQuery.dirtyRecords({
    String? organizationId,
    List<SyncOrderBy> orderBy = const [],
    int? limit,
  }) {
    final filters = <String, dynamic>{'is_dirty': 1};
    if (organizationId != null) {
      filters['organization_id'] = organizationId;
    }

    return SyncQuery(
      filters: filters,
      orderBy: orderBy,
      limit: limit,
    );
  }s/usm_sync_result.dart';
import '../models/usm_sync_event.dart';

/// Core interface for backend adapters in Universal Sync Manager
///
/// This interface defines the contract that all backend implementations must follow,
/// enabling seamless switching between different backend services (Firebase, Supabase,
/// PocketBase, custom APIs) without changing core sync logic.
///
/// Following USM naming conventions:
/// - File: usm_sync_backend_adapter.dart (snake_case with usm_ prefix)
/// - Interface: ISyncBackendAdapter (I prefix for interfaces)
abstract class ISyncBackendAdapter {
  /// Connection management
  ///
  /// Establishes connection to the backend service using provided configuration.
  /// Returns true if connection is successful, false otherwise.
  Future<bool> connect(SyncBackendConfiguration config);

  /// Disconnects from the backend service and cleans up resources
  Future<void> disconnect();

  /// Current connection status
  bool get isConnected;

  /// CRUD operations
  ///
  /// Creates a new record in the specified collection.
  /// Collection names follow snake_case convention (e.g., 'audit_items')
  Future<SyncResult> create(String collection, Map<String, dynamic> data);

  /// Reads a specific record by ID from the collection
  Future<SyncResult> read(String collection, String id);

  /// Updates an existing record in the collection
  Future<SyncResult> update(
      String collection, String id, Map<String, dynamic> data);

  /// Deletes a record from the collection (soft delete preferred)
  Future<SyncResult> delete(String collection, String id);

  /// Queries multiple records from the collection based on provided criteria
  Future<List<SyncResult>> query(String collection, SyncQuery query);

  /// Batch operations for performance optimization
  ///
  /// Creates multiple records in a single operation
  Future<List<SyncResult>> batchCreate(
      String collection, List<Map<String, dynamic>> items);

  /// Updates multiple records in a single operation
  Future<List<SyncResult>> batchUpdate(
      String collection, List<Map<String, dynamic>> items);

  /// Deletes multiple records in a single operation
  Future<List<SyncResult>> batchDelete(String collection, List<String> ids);

  /// Real-time subscriptions
  ///
  /// Subscribes to real-time changes in a collection.
  /// Returns a stream of sync events for live updates.
  Stream<SyncEvent> subscribe(
      String collection, SyncSubscriptionOptions options);

  /// Unsubscribes from real-time updates for a specific subscription
  Future<void> unsubscribe(String subscriptionId);

  /// Backend capabilities and feature detection
  ///
  /// Returns the capabilities supported by this backend adapter
  SyncBackendCapabilities get capabilities;

  /// Backend-specific metadata and information
  String get backendType;
  String get backendVersion;
  Map<String, dynamic> get backendInfo;
}

/// Represents a query for filtering and sorting data
class SyncQuery {
  final Map<String, dynamic> filters;
  final List<SyncOrderBy> orderBy;
  final int? limit;
  final int? offset;
  final List<String>? fields; // For selecting specific fields only

  const SyncQuery({
    this.filters = const {},
    this.orderBy = const [],
    this.limit,
    this.offset,
    this.fields,
  });

  /// Creates a query that filters by organizationId (common pattern)
  factory SyncQuery.byOrganization(
    String organizationId, {
    Map<String, dynamic> additionalFilters = const {},
    List<SyncOrderBy> orderBy = const [],
    int? limit,
    int? offset,
  }) {
    return SyncQuery(
      filters: {'organization_id': organizationId, ...additionalFilters},
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// Creates a query for dirty records (pending sync)
  factory SyncQuery.dirtyRecords({
    String? organizationId,
    List<SyncOrderBy> orderBy = const [],
    int? limit,
  }) {
    final filters = <String, dynamic>{'isDirty': 1};
    if (organizationId != null) {
      filters['organization_id'] = organizationId;
    }

    return SyncQuery(
      filters: filters,
      orderBy: orderBy,
      limit: limit,
    );
  }
}

/// Represents sorting criteria for queries
class SyncOrderBy {
  final String field;
  final SyncOrderDirection direction;

  const SyncOrderBy(this.field, this.direction);

  /// Helper constructors
  const SyncOrderBy.asc(String field)
      : this(field, SyncOrderDirection.ascending);
  const SyncOrderBy.desc(String field)
      : this(field, SyncOrderDirection.descending);
}

/// Sort direction enumeration
enum SyncOrderDirection {
  ascending,
  descending,
}

/// Options for configuring real-time subscriptions
class SyncSubscriptionOptions {
  final Map<String, dynamic> filters;
  final List<String>? events; // ['create', 'update', 'delete']
  final bool includeInitialData;
  final Duration? timeout;

  const SyncSubscriptionOptions({
    this.filters = const {},
    this.events,
    this.includeInitialData = false,
    this.timeout,
  });

  /// Default subscription for all events in an organization
  factory SyncSubscriptionOptions.forOrganization(String organizationId) {
    return SyncSubscriptionOptions(
      filters: {'organizationId': organizationId},
      events: ['create', 'update', 'delete'],
      includeInitialData: true,
    );
  }
}
