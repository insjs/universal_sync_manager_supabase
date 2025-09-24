import '../config/usm_sync_enums.dart';

/// Collection to be synchronized
///
/// This class represents a collection (table) that should be synchronized
/// with the backend. It defines the sync direction and optional filters.
class SyncCollection {
  /// Name of the collection to synchronize
  final String name;

  /// Direction of synchronization (download, upload, or bidirectional)
  final SyncDirection syncDirection;

  /// Optional filters to apply when synchronizing this collection
  final Map<String, dynamic>? filters;

  /// Creates a new sync collection configuration
  const SyncCollection({
    required this.name,
    required this.syncDirection,
    this.filters,
  });
}
