import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../interfaces/usm_sync_backend_adapter.dart';
import '../models/usm_sync_backend_capabilities.dart';
import '../models/usm_sync_backend_configuration.dart';
import '../models/usm_sync_result.dart';
import '../models/usm_sync_event.dart';
import '../models/usm_auth_context.dart';
import '../services/usm_token_manager.dart';
import '../config/usm_sync_enums.dart';

/// Supabase implementation of the Universal Sync Manager backend adapter
///
/// This adapter provides integration with Supabase backend services,
/// implementing the standard ISyncBackendAdapter interface to enable
/// seamless switching between different backend providers.
///
/// Key Features:
/// - Full CRUD operations with Supabase tables
/// - Real-time subscriptions using Supabase Realtime
/// - Authentication integration with Supabase Auth
/// - Automatic field mapping for USM conventions
/// - Error handling with proper USM error types
/// - Connection management and health monitoring
/// - Row Level Security (RLS) support
/// - PostgreSQL advanced features (JSON, arrays, etc.)
/// - Edge Functions integration
/// - Storage bucket operations
///
/// Following USM naming conventions:
/// - File: usm_supabase_sync_adapter.dart (snake_case with usm_ prefix)
/// - Class: SupabaseSyncAdapter (PascalCase)
/// - Tables: snake_case naming (audit_items, organization_profiles)
/// - Fields: snake_case naming (organization_id, created_by, updated_at)
class SupabaseSyncAdapter implements ISyncBackendAdapter {
  // Core Supabase configuration
  final String supabaseUrl;
  final String supabaseAnonKey;
  final Duration connectionTimeout;
  final Duration requestTimeout;

  // Connection state
  bool _isConnected = false;
  SupabaseClient? _client;

  // Real-time subscriptions tracking
  final Map<String, RealtimeChannel> _subscriptions = {};
  final Map<String, StreamController<SyncEvent>> _controllers = {};

  // Authentication state
  User? _currentUser;

  // Enhanced authentication integration
  AuthContext? _authContext;
  TokenManager? _tokenManager;
  SyncAuthConfiguration? _authConfig;

  // Backend metadata
  static const String _backendType = 'supabase';
  static const String _backendVersion = '2.8.0';

  /// Creates a new Supabase sync adapter
  SupabaseSyncAdapter({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.connectionTimeout = const Duration(seconds: 30),
    this.requestTimeout = const Duration(seconds: 60),
  });

  @override
  String get backendType => _backendType;

  @override
  String get backendVersion => _backendVersion;

  @override
  Map<String, dynamic> get backendInfo => {
        'supabaseUrl': supabaseUrl,
        'connectionTimeout': connectionTimeout.inSeconds,
        'requestTimeout': requestTimeout.inSeconds,
        'isAuthenticated': _currentUser != null,
        'currentUser': _currentUser?.toJson(),
        'activeSubscriptions': _subscriptions.length,
        'capabilities': capabilities.featureSummary,
        // Enhanced auth info
        'hasAuthContext': _authContext != null,
        'authContextId': _authContext?.contextId,
        'userId': _authContext?.userId,
        'organizationId': _authContext?.organizationId,
        'authContextExpiry': _authContext?.expiresAt?.toIso8601String(),
        'hasTokenManager': _tokenManager != null,
      };

  @override
  bool get isConnected => _isConnected;

  @override
  SyncBackendCapabilities get capabilities =>
      SyncBackendCapabilities.supabase();

  // === Connection Management ===

  @override
  Future<bool> connect(SyncBackendConfiguration config) async {
    try {
      // Validate configuration
      if (config.backendType != _backendType) {
        throw SyncError.validation(
          message:
              'Invalid backend type: ${config.backendType}. Expected: $_backendType',
          details: 'Supabase adapter can only connect to Supabase backends',
        );
      }

      // Store auth configuration for enhanced features
      if (config.authConfig != null) {
        _authConfig = config.authConfig;

        // Initialize token manager if callback is provided
        if (_authConfig!.tokenRefreshCallback != null) {
          _tokenManager = TokenManager(
            config: TokenManagementConfig(
              refreshThreshold: const Duration(minutes: 5),
              maxRefreshAttempts: 3,
              baseRetryDelay: const Duration(seconds: 2),
            ),
          );
        }

        // Initialize auth context
        if (_authConfig!.userContext != null &&
            _authConfig!.userContext!.isNotEmpty) {
          _authContext = AuthContext.authenticated(
            userId: _authConfig!.userContext!['userId'] as String? ?? '',
            organizationId:
                _authConfig!.userContext!['organizationId'] as String?,
            userContext: _authConfig!.userContext!,
            metadata: _authConfig!.metadata,
            credentials: _authConfig!.credentials,
            validity: const Duration(hours: 23),
          );
        }
      }

      // Initialize Supabase client (check if already initialized)
      try {
        _client = Supabase.instance.client;
      } catch (e) {
        // Instance not initialized yet
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseAnonKey,
        );
        _client = Supabase.instance.client;
      }

      // Test connection with a simple query to a table that should exist
      try {
        // Try to query app_settings which should be available as a public table
        await _client!.from('app_settings').select('setting_key').limit(1);
      } catch (e) {
        // If app_settings doesn't exist, try a simple RPC call or just continue
        // The error is not critical as long as Supabase client is initialized
        print('🔗 Note: Could not perform health check query: $e');
      }

      // Handle authentication - support both old and new auth patterns
      if (_authConfig != null &&
          _authConfig!.credentials.containsKey('token')) {
        // Enhanced auth: use existing Supabase auth token
        // Note: Supabase handles auth tokens internally, we just need to ensure
        // the auth context is properly set for Row Level Security
        _currentUser = _client!.auth.currentUser;
      } else if (config.customSettings.containsKey('email') &&
          config.customSettings.containsKey('password')) {
        // Legacy auth: authenticate with credentials
        await _authenticateWithCredentials(
          config.customSettings['email'] as String,
          config.customSettings['password'] as String,
        );
      }

      // Listen to Supabase auth state changes
      _client!.auth.onAuthStateChange.listen((data) {
        _currentUser = data.session?.user;

        // Update auth context when Supabase auth state changes
        if (_authContext != null && _currentUser != null) {
          _authContext = AuthContext.authenticated(
            userId: _currentUser!.id,
            organizationId: _authContext!.organizationId,
            userContext: {
              ..._authContext!.userContext,
              'supabaseUser': _currentUser!.toJson(),
            },
            metadata: _authContext!.metadata,
            credentials: {
              ..._authContext!.credentials,
              'supabaseAccessToken': data.session?.accessToken,
            },
            validity: const Duration(hours: 23),
          );
        }
      });

      _isConnected = true;
      return true;
    } catch (e) {
      _isConnected = false;
      if (e is SyncError) rethrow;

      throw SyncError.network(
        message: 'Failed to connect to Supabase: $e',
        details: 'Connection error during Supabase initialization',
        originalException: e,
      );
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      // Close all subscriptions
      for (final channel in _subscriptions.values) {
        await _client?.removeChannel(channel);
      }
      _subscriptions.clear();

      // Close all controllers
      for (final controller in _controllers.values) {
        await controller.close();
      }
      _controllers.clear();

      // Sign out if authenticated
      if (_currentUser != null) {
        await _client?.auth.signOut();
        _currentUser = null;
      }

      _client = null;
      _isConnected = false;
    } catch (e) {
      print('Warning: Error during Supabase disconnect: $e');
    }
  }

  // === CRUD Operations ===

  @override
  Future<SyncResult> create(
      String collection, Map<String, dynamic> data) async {
    _ensureConnected();

    try {
      // Set RLS context for this operation
      await _setRLSContext();

      // Make a deep copy to avoid modifying the original data
      final originalData = Map<String, dynamic>.from(data);
      final supabaseData = _mapToBackendFormat(originalData);

      // Enhance data with user context for RLS policies
      final enhancedData = _enhanceDataWithUserContext(supabaseData);

      // Convert field types to ensure Supabase compatibility
      _convertFieldTypesForSupabase(enhancedData);

      // CRITICAL: Ensure all values are properly typed for JSON serialization
      final finalData = Map<String, dynamic>.from(enhancedData);

      // Validate that all required fields are present and properly typed
      _validateDataTypes(finalData);

      print('🔧 DEBUG - About to call Supabase insert with timeout...');
      final response = await _client!
          .from(collection)
          .insert(finalData)
          .select()
          .single()
          .timeout(
            requestTimeout,
            onTimeout: () => throw TimeoutException(
              'Request timeout after ${requestTimeout.inSeconds}s',
              requestTimeout,
            ),
          );

      print('🔧 DEBUG [1] - Supabase insert successful, response received');
      print('🔧 DEBUG [2] - Response: $response');
      print('🔧 DEBUG [3] - Response type: ${response.runtimeType}');

      try {
        print('🔧 DEBUG [4] - About to call _mapFromBackendFormat...');
        final mappedData = _mapFromBackendFormat(response);
        print('🔧 DEBUG [5] - _mapFromBackendFormat successful');

        print('🔧 DEBUG [6] - About to create recordId...');
        // NEW SCHEMA: id is now UUID primary key, no more external_id needed
        final recordId = response['id'].toString();
        print('🔧 DEBUG [7] - recordId created: $recordId');

        print('🔧 DEBUG [8] - About to create metadata...');
        // CRITICAL: Ensure metadata values are properly typed as strings to prevent casting errors
        final metadata = {
          'id': response['id'].toString(), // UUID primary key
          'created_at': response['created_at'].toString(),
          'updated_at': response['updated_at'].toString(),
        };
        print('🔧 DEBUG [9] - metadata created: $metadata');

        print('🔧 DEBUG [10] - About to create SyncResult.success...');
        final result = SyncResult.success(
          data: mappedData,
          action: SyncAction.create,
          collection: collection,
          recordId: recordId, // Now using UUID primary key
          metadata: metadata,
        );
        print('🔧 DEBUG [11] - SyncResult.success created successfully');
        return result;
      } catch (e, stackTrace) {
        print('🔧 DEBUG [ERROR] - Exception during response processing: $e');
        print('🔧 DEBUG [ERROR] - Stack trace: $stackTrace');
        print('🔧 DEBUG [ERROR] - Exception type: ${e.runtimeType}');
        rethrow;
      }
    } on TimeoutException catch (e) {
      return SyncResult.error(
        error: SyncError.network(
          message: 'Request timeout after ${requestTimeout.inSeconds}s: $e',
          details: 'Network timeout during create operation',
          originalException: e,
        ),
        action: SyncAction.create,
        collection: collection,
      );
    } on SocketException catch (e) {
      return SyncResult.error(
        error: SyncError.network(
          message: 'Network connection error: $e',
          details: 'Socket error (semaphore timeout or connection failure)',
          originalException: e,
        ),
        action: SyncAction.create,
        collection: collection,
      );
    } on PostgrestException catch (e) {
      return SyncResult.error(
        error: _mapPostgrestErrorToSyncError(e),
        action: SyncAction.create,
        collection: collection,
      );
    } on TypeError catch (e) {
      print('🔧 DEBUG - TypeError (likely the casting issue): $e');
      print('🔧 DEBUG - Stack trace: ${e.stackTrace}');
      return SyncResult.error(
        error: SyncError.validation(
          message: 'Type casting error during create operation: $e',
          details:
              'Client-side type validation failed. Check data types in payload.',
        ),
        action: SyncAction.create,
        collection: collection,
      );
    } catch (e) {
      print('🔧 DEBUG - General exception: $e');
      print('🔧 DEBUG - Exception type: ${e.runtimeType}');

      // Handle semaphore timeout specifically
      if (e.toString().contains('semaphore timeout') ||
          e.toString().contains('semaphore') ||
          e.toString().contains('connection')) {
        return SyncResult.error(
          error: SyncError.network(
            message: 'Network connection error: $e',
            details: 'Semaphore timeout or network connection failure',
            originalException: e,
          ),
          action: SyncAction.create,
          collection: collection,
        );
      }

      if (e.toString().contains('type cast')) {
        print('🔧 DEBUG - This appears to be the type casting error!');
      }

      return SyncResult.error(
        error: SyncError.network(
          message: 'Failed to create record in table $collection: $e',
          details: 'Network error during create operation',
          originalException: e,
        ),
        action: SyncAction.create,
        collection: collection,
      );
    }
  }

  @override
  Future<SyncResult> read(String collection, String id) async {
    _ensureConnected();

    try {
      // Set RLS context for this operation
      await _setRLSContext();

      // NEW SCHEMA: id is now UUID primary key, direct lookup
      final response =
          await _client!.from(collection).select().eq('id', id).single();

      final mappedData = _mapFromBackendFormat(response);

      // Use id (UUID) as recordId
      final recordId = response['id'].toString();

      return SyncResult.success(
        data: mappedData,
        action: SyncAction.read,
        collection: collection,
        recordId: recordId, // Use UUID primary key
        metadata: {
          'id': response['id'].toString(), // UUID primary key
          'created_at': response['created_at'].toString(),
          'updated_at': response['updated_at'].toString(),
        },
      );
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        // No rows returned (404 equivalent)
        return SyncResult.error(
          error: SyncError.validation(
            message: 'Record not found: $id in table $collection',
            details: 'The requested record does not exist',
          ),
          action: SyncAction.read,
          collection: collection,
          recordId: id,
        );
      }
      return SyncResult.error(
        error: _mapPostgrestErrorToSyncError(e),
        action: SyncAction.read,
        collection: collection,
        recordId: id,
      );
    } catch (e) {
      return SyncResult.error(
        error: SyncError.network(
          message: 'Failed to read record $id from table $collection: $e',
          details: 'Network error during read operation',
          originalException: e,
        ),
        action: SyncAction.read,
        collection: collection,
        recordId: id,
      );
    }
  }

  @override
  Future<SyncResult> update(
      String collection, String id, Map<String, dynamic> data) async {
    _ensureConnected();

    try {
      final supabaseData = _mapToBackendFormat(data);

      // Remove read-only fields that cannot be updated
      final updateData = Map<String, dynamic>.from(supabaseData);
      updateData.remove('id'); // Auto-generated UUID, cannot be updated
      updateData.remove('created_at'); // Set once, cannot be updated

      // Convert field types to ensure Supabase compatibility
      _convertFieldTypesForSupabase(updateData);

      // NEW SCHEMA: id is now UUID primary key, direct update
      final response = await _client!
          .from(collection)
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      final mappedData = _mapFromBackendFormat(response);

      // Use id (UUID) as recordId
      final recordId = response['id'].toString();

      return SyncResult.success(
        data: mappedData,
        action: SyncAction.update,
        collection: collection,
        recordId: recordId, // Use UUID primary key
        metadata: {
          'id': response['id'].toString(), // UUID primary key
          'created_at': response['created_at'].toString(),
          'updated_at': response['updated_at'].toString(),
        },
      );
    } on PostgrestException catch (e) {
      return SyncResult.error(
        error: _mapPostgrestErrorToSyncError(e),
        action: SyncAction.update,
        collection: collection,
        recordId: id,
      );
    } catch (e) {
      return SyncResult.error(
        error: SyncError.network(
          message: 'Failed to update record $id in table $collection: $e',
          details: 'Network error during update operation',
          originalException: e,
        ),
        action: SyncAction.update,
        collection: collection,
        recordId: id,
      );
    }
  }

  @override
  Future<SyncResult> delete(String collection, String id) async {
    _ensureConnected();

    try {
      // NEW SCHEMA: id is now UUID primary key, direct delete
      await _client!.from(collection).delete().eq('id', id);

      return SyncResult.success(
        data: {'id': id, 'isDeleted': true},
        action: SyncAction.delete,
        collection: collection,
        recordId: id, // UUID primary key
        metadata: {
          'deletedId': id,
          'deletedAt': DateTime.now().toIso8601String(),
        },
      );
    } on PostgrestException catch (e) {
      return SyncResult.error(
        error: _mapPostgrestErrorToSyncError(e),
        action: SyncAction.delete,
        collection: collection,
        recordId: id,
      );
    } catch (e) {
      return SyncResult.error(
        error: SyncError.network(
          message: 'Failed to delete record $id from table $collection: $e',
          details: 'Network error during delete operation',
          originalException: e,
        ),
        action: SyncAction.delete,
        collection: collection,
        recordId: id,
      );
    }
  }

  @override
  Future<List<SyncResult>> query(String collection, SyncQuery query) async {
    _ensureConnected();

    try {
      dynamic queryBuilder = _client!.from(collection).select();

      // Apply filters
      for (final entry in query.filters.entries) {
        final value = entry.value;
        queryBuilder = queryBuilder.eq(entry.key, value);
      }

      // Apply ordering
      for (final order in query.orderBy) {
        queryBuilder = queryBuilder.order(
          order.field,
          ascending: order.direction == SyncOrderDirection.ascending,
        );
      }

      // Apply pagination
      if (query.limit != null) {
        queryBuilder = queryBuilder.limit(query.limit!);
      }
      if (query.offset != null) {
        queryBuilder = queryBuilder.range(
          query.offset!,
          query.offset! + (query.limit ?? 1000) - 1,
        );
      }

      final response = await queryBuilder;
      final items = response as List<dynamic>;

      return items.map((item) {
        final itemData = item;
        final mappedData = _mapFromBackendFormat(itemData);

        // Use id (UUID) as recordId
        final recordId = itemData['id'].toString();

        return SyncResult.success(
          data: mappedData,
          action: SyncAction.read,
          collection: collection,
          recordId: recordId, // Use UUID primary key
          metadata: {
            'id': itemData['id'].toString(), // UUID primary key
            'created_at': itemData['created_at'].toString(),
            'updated_at': itemData['updated_at'].toString(),
          },
        );
      }).toList();
    } on PostgrestException catch (e) {
      return [
        SyncResult.error(
          error: _mapPostgrestErrorToSyncError(e),
          action: SyncAction.read,
          collection: collection,
        )
      ];
    } catch (e) {
      return [
        SyncResult.error(
          error: SyncError.network(
            message: 'Failed to query table $collection: $e',
            details: 'Network error during query operation',
            originalException: e,
          ),
          action: SyncAction.read,
          collection: collection,
        )
      ];
    }
  }

  // === Batch Operations ===

  @override
  Future<List<SyncResult>> batchCreate(
      String collection, List<Map<String, dynamic>> items) async {
    _ensureConnected();

    try {
      final supabaseItems = items.map((item) {
        final mappedItem = _mapToBackendFormat(item);
        _convertFieldTypesForSupabase(mappedItem);
        return mappedItem;
      }).toList();
      final response =
          await _client!.from(collection).insert(supabaseItems).select();

      final results = <SyncResult>[];
      for (final item in response) {
        final itemData = item;
        final mappedData = _mapFromBackendFormat(itemData);

        // Use id (now UUID) as recordId for consistency with USM UUID expectations
        final recordId = itemData['id'].toString();

        results.add(SyncResult.success(
          data: mappedData,
          action: SyncAction.create,
          collection: collection,
          recordId: recordId, // Use UUID primary key
          metadata: {
            'id': itemData['id'].toString(), // UUID primary key
            'created_at': itemData['created_at'].toString(),
            'updated_at': itemData['updated_at'].toString(),
          },
        ));
      }
      return results;
    } on PostgrestException catch (e) {
      final error = _mapPostgrestErrorToSyncError(e);
      return items
          .map((item) => SyncResult.error(
                error: error,
                action: SyncAction.create,
                collection: collection,
              ))
          .toList();
    } catch (e) {
      final error = SyncError.network(
        message: 'Failed to batch create records in table $collection: $e',
        details: 'Network error during batch create operation',
        originalException: e,
      );
      return items
          .map((item) => SyncResult.error(
                error: error,
                action: SyncAction.create,
                collection: collection,
              ))
          .toList();
    }
  }

  @override
  Future<List<SyncResult>> batchUpdate(
      String collection, List<Map<String, dynamic>> items) async {
    final results = <SyncResult>[];

    // Supabase doesn't have native batch update, so we do individual updates
    for (final item in items) {
      final id = item['id']?.toString();
      if (id == null) {
        results.add(SyncResult.error(
          error: SyncError.validation(
            message: 'Missing id field for batch update',
            details: 'Each item in batch update must have an id field',
          ),
          action: SyncAction.update,
          collection: collection,
        ));
        continue;
      }

      final result = await update(collection, id, item);
      results.add(result);

      // Add small delay to avoid overwhelming the server
      if (items.length > 10) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }

    return results;
  }

  @override
  Future<List<SyncResult>> batchDelete(
      String collection, List<String> ids) async {
    _ensureConnected();

    try {
      // NEW SCHEMA: id is now UUID primary key, direct delete
      await _client!.from(collection).delete().inFilter('id', ids);

      return ids
          .map((id) => SyncResult.success(
                data: {'id': id, 'isDeleted': true},
                action: SyncAction.delete,
                collection: collection,
                recordId: id, // UUID primary key
                metadata: {
                  'deletedId': id,
                  'deletedAt': DateTime.now().toIso8601String(),
                },
              ))
          .toList();
    } on PostgrestException catch (e) {
      final error = _mapPostgrestErrorToSyncError(e);
      return ids
          .map((id) => SyncResult.error(
                error: error,
                action: SyncAction.delete,
                collection: collection,
                recordId: id,
              ))
          .toList();
    } catch (e) {
      final error = SyncError.network(
        message: 'Failed to batch delete records from table $collection: $e',
        details: 'Network error during batch delete operation',
        originalException: e,
      );
      return ids
          .map((id) => SyncResult.error(
                error: error,
                action: SyncAction.delete,
                collection: collection,
                recordId: id,
              ))
          .toList();
    }
  }

  // === Real-time Subscriptions ===

  @override
  Stream<SyncEvent> subscribe(
      String collection, SyncSubscriptionOptions options) {
    final subscriptionId =
        '${collection}_${DateTime.now().millisecondsSinceEpoch}';

    final controller = StreamController<SyncEvent>.broadcast();
    _controllers[subscriptionId] = controller;

    _startRealtimeSubscription(subscriptionId, collection, options, controller);

    return controller.stream;
  }

  @override
  Future<void> unsubscribe(String subscriptionId) async {
    final controller = _controllers.remove(subscriptionId);
    if (controller != null) {
      await controller.close();
    }

    final channel = _subscriptions.remove(subscriptionId);
    if (channel != null && _client != null) {
      await _client!.removeChannel(channel);
    }
  }

  // === Private Helper Methods ===

  void _ensureConnected() {
    if (!_isConnected) {
      throw SyncError.network(
        message: 'Not connected to Supabase. Call connect() first.',
        details: 'Adapter must be connected before performing operations',
      );
    }
  }

  Map<String, dynamic> _mapToBackendFormat(Map<String, dynamic> data) {
    final mapped = Map<String, dynamic>.from(data);

    // Convert DateTime objects to ISO strings
    for (final entry in mapped.entries) {
      if (entry.value is DateTime) {
        mapped[entry.key] = (entry.value as DateTime).toIso8601String();
      }
    }

    // Handle specific field type conversions for Supabase compatibility
    _convertFieldTypesForSupabase(mapped);

    return mapped;
  }

  /// Converts field types to match Supabase schema expectations
  void _convertFieldTypesForSupabase(Map<String, dynamic> data) {
    // CRITICAL: Ensure ID fields are always strings to prevent type casting errors
    final idFields = [
      'id',
      'organization_id',
      'created_by',
      'updated_by',
      'user_id'
    ];
    for (final field in idFields) {
      if (data.containsKey(field) && data[field] != null) {
        data[field] = data[field].toString();
      }
    }

    // Handle JSON/JSONB fields - keep as Map<String, dynamic> for Supabase
    final jsonFields = ['settings', 'metadata', 'config'];
    for (final field in jsonFields) {
      if (data.containsKey(field)) {
        final value = data[field];
        if (value is String) {
          try {
            // Parse JSON string to Map for Supabase JSONB
            final jsonStr = value;
            if (jsonStr.isNotEmpty) {
              final parsed = jsonDecode(jsonStr);
              // Ensure all values in JSON are properly typed
              if (parsed is Map<String, dynamic>) {
                data[field] = _sanitizeJsonValues(parsed);
              } else {
                data[field] = parsed;
              }
            } else {
              data[field] = null;
            }
          } catch (e) {
            print('⚠️ Failed to parse JSON for field $field: $value');
            // Keep as string if parsing fails
            data[field] = value;
          }
        } else if (value is Map<String, dynamic>) {
          // Already a Map, just sanitize the values
          data[field] = _sanitizeJsonValues(value);
        }
      }
    }

    // Convert integer boolean fields to proper booleans
    final booleanFields = ['is_active', 'is_deleted', 'is_dirty'];
    for (final field in booleanFields) {
      if (data.containsKey(field)) {
        final value = data[field];
        if (value is int) {
          data[field] = value == 1;
        } else if (value is String) {
          data[field] = value.toLowerCase() == 'true' || value == '1';
        }
      }
    }

    // CRITICAL: Ensure integer fields are properly typed as integers
    // Priority and sync_version should be integers according to schema
    final integerFields = ['priority', 'sync_version'];
    for (final field in integerFields) {
      if (data.containsKey(field) && data[field] != null) {
        final value = data[field];
        if (value is String) {
          try {
            data[field] = int.parse(value);
          } catch (e) {
            print('⚠️ Failed to parse integer for field $field: $value');
            // Keep original value if parsing fails
          }
        }
        // If already int, keep as is
      }
    }

    // Ensure decimal fields are properly typed
    final doubleFields = ['completion_percentage', 'execution_time'];
    for (final field in doubleFields) {
      if (data.containsKey(field)) {
        final value = data[field];
        if (value is String) {
          try {
            data[field] = double.parse(value);
          } catch (e) {
            print('⚠️ Failed to parse double for field $field: $value');
          }
        } else if (value is int) {
          data[field] = value.toDouble();
        }
      }
    }

    // Ensure DateTime fields are properly formatted as ISO strings
    final dateTimeFields = [
      'due_date',
      'created_at',
      'updated_at',
      'deleted_at',
      'last_synced_at'
    ];
    for (final field in dateTimeFields) {
      if (data.containsKey(field) && data[field] != null) {
        final value = data[field];
        if (value is DateTime) {
          data[field] = value.toIso8601String();
        } else if (value is String) {
          // Validate it's a proper ISO string, if not try to parse and re-format
          try {
            final dateTime = DateTime.parse(value);
            data[field] = dateTime.toIso8601String();
          } catch (e) {
            print('⚠️ Failed to parse DateTime for field $field: $value');
            // Keep original value if parsing fails
          }
        }
      }
    }
  }

  /// Sanitizes JSON values to ensure proper typing for Supabase JSONB
  Map<String, dynamic> _sanitizeJsonValues(Map<String, dynamic> json) {
    final sanitized = <String, dynamic>{};

    for (final entry in json.entries) {
      final value = entry.value;

      if (value is Map<String, dynamic>) {
        // Recursively sanitize nested maps
        sanitized[entry.key] = _sanitizeJsonValues(value);
      } else if (value is List) {
        // Sanitize list values
        sanitized[entry.key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _sanitizeJsonValues(item);
          }
          return item; // Keep primitives as-is
        }).toList();
      } else {
        // Keep primitive values as-is (int, double, String, bool, null)
        // This is CRITICAL - don't convert integers to strings in JSON
        sanitized[entry.key] = value;
      }
    }

    return sanitized;
  }

  /// Validates data types to prevent client-side casting errors
  void _validateDataTypes(Map<String, dynamic> data) {
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      // Check for problematic null values in non-nullable fields
      if (value == null) {
        final requiredFields = ['organization_id', 'created_by', 'updated_by'];
        if (requiredFields.contains(key)) {
          throw SyncError.validation(
            message: 'Required field $key cannot be null',
            details: 'Required field validation failed',
          );
        }
        continue;
      }

      // Validate specific field types based on schema
      switch (key) {
        case 'priority':
        case 'sync_version':
          if (value is! int) {
            throw SyncError.validation(
              message:
                  'Field $key must be an integer, got ${value.runtimeType}',
              details: 'Type validation failed for integer field',
            );
          }
          break;
        case 'completion_percentage':
        case 'execution_time':
          if (value is! double && value is! int) {
            throw SyncError.validation(
              message: 'Field $key must be a number, got ${value.runtimeType}',
              details: 'Type validation failed for numeric field',
            );
          }
          break;
        case 'is_active':
        case 'is_deleted':
        case 'is_dirty':
          if (value is! bool) {
            throw SyncError.validation(
              message: 'Field $key must be a boolean, got ${value.runtimeType}',
              details: 'Type validation failed for boolean field',
            );
          }
          break;
        case 'metadata':
        case 'settings':
        case 'config':
          if (value is! Map<String, dynamic> && value is! String) {
            throw SyncError.validation(
              message:
                  'Field $key must be a Map or String, got ${value.runtimeType}',
              details: 'Type validation failed for JSON field',
            );
          }
          break;
      }
    }
  }

  Map<String, dynamic> _mapFromBackendFormat(Map<String, dynamic> data) {
    print('🔧 DEBUG [_mapFromBackendFormat] - Input data: $data');
    print('🔧 DEBUG [_mapFromBackendFormat] - Input data types:');
    for (final entry in data.entries) {
      print('  ${entry.key}: ${entry.value} (${entry.value.runtimeType})');
    }

    final mapped = Map<String, dynamic>.from(data);

    try {
      print('🔧 DEBUG [_mapFromBackendFormat] - Processing UUID fields...');
      // NEW SCHEMA: All ID fields are now UUIDs, convert them to strings for consistency
      final uuidFields = [
        'id', // Now UUID primary key, not integer
        'organization_id',
        'created_by',
        'updated_by',
        'user_id'
      ];
      for (final field in uuidFields) {
        if (mapped.containsKey(field) && mapped[field] != null) {
          print(
              '🔧 DEBUG [_mapFromBackendFormat] - Converting UUID field $field: ${mapped[field]} (${mapped[field].runtimeType})');
          mapped[field] = mapped[field].toString();
          print(
              '🔧 DEBUG [_mapFromBackendFormat] - After conversion: ${mapped[field]} (${mapped[field].runtimeType})');
        }
      }

      print('🔧 DEBUG [_mapFromBackendFormat] - Processing integer fields...');
      // CRITICAL: Preserve integer fields as integers (don't convert to string)
      // sync_version and priority should remain as integers per schema
      final integerFields = ['sync_version', 'priority'];
      for (final field in integerFields) {
        if (mapped.containsKey(field) && mapped[field] != null) {
          final value = mapped[field];
          print(
              '🔧 DEBUG [_mapFromBackendFormat] - Processing integer field $field: $value (${value.runtimeType})');
          if (value is String) {
            try {
              mapped[field] = int.parse(value);
              print(
                  '🔧 DEBUG [_mapFromBackendFormat] - Converted string to int: ${mapped[field]}');
            } catch (e) {
              print(
                  '⚠️ Failed to parse integer from string for field $field: $value');
            }
          }
          // If already int, keep as is
        }
      }

      print(
          '🔧 DEBUG [_mapFromBackendFormat] - Processing timestamp fields...');
      // Map Supabase timestamp fields to USM snake_case conventions
      if (data.containsKey('created_at')) {
        mapped['created_at'] = data['created_at'];
      }
      if (data.containsKey('updated_at')) {
        mapped['updated_at'] = data['updated_at'];
      }

      print('🔧 DEBUG [_mapFromBackendFormat] - Converting DateTime fields...');
      // Convert string dates to DateTime objects
      for (final entry in mapped.entries) {
        if (entry.value is String && _isDateTimeField(entry.key)) {
          try {
            mapped[entry.key] = DateTime.parse(entry.value as String);
            print(
                '🔧 DEBUG [_mapFromBackendFormat] - Converted DateTime field ${entry.key}: ${mapped[entry.key]}');
          } catch (e) {
            // Keep as string if parsing fails
            print(
                '🔧 DEBUG [_mapFromBackendFormat] - Failed to parse DateTime for ${entry.key}: ${entry.value}');
          }
        }
      }

      print('🔧 DEBUG [_mapFromBackendFormat] - Final mapped data: $mapped');
      return mapped;
    } catch (e, stackTrace) {
      print('🔧 DEBUG [_mapFromBackendFormat ERROR] - Exception: $e');
      print(
          '🔧 DEBUG [_mapFromBackendFormat ERROR] - Stack trace: $stackTrace');
      rethrow;
    }
  }

  bool _isDateTimeField(String fieldName) {
    final dateTimeFields = {
      'created_at',
      'updated_at',
      'deleted_at',
      'last_synced_at',
    };
    return dateTimeFields.contains(fieldName);
  }

  SyncError _mapPostgrestErrorToSyncError(PostgrestException e) {
    switch (e.code) {
      case '23505': // unique_violation
        return SyncError.conflict(
          message: 'Unique constraint violation: ${e.message}',
          details: 'A record with this data already exists',
        );
      case '23503': // foreign_key_violation
        return SyncError.validation(
          message: 'Foreign key constraint violation: ${e.message}',
          details: 'Referenced record does not exist',
        );
      case '23502': // not_null_violation
        return SyncError.validation(
          message: 'Required field missing: ${e.message}',
          details: 'One or more required fields are null',
        );
      case '42501': // insufficient_privilege
        return SyncError.authorization(
          message: 'Insufficient privileges: ${e.message}',
          details: 'You do not have permission to perform this operation',
        );
      case 'PGRST116': // No rows returned
        return SyncError.validation(
          message: 'Record not found: ${e.message}',
          details: 'The requested record does not exist',
        );
      case 'PGRST301': // JWT expired
        return SyncError.authentication(
          message: 'Authentication token expired: ${e.message}',
          details: 'Please re-authenticate',
        );
      case 'PGRST204': // Schema cache loading error
      case 'PGRST000': // Connection error
        return SyncError.backend(
          message: 'Database connection error: ${e.message}',
          details: 'The database server is temporarily unavailable',
        );
      default:
        return SyncError.backend(
          message: 'Database error: ${e.message}',
          details: 'An unexpected database error occurred',
          originalException: e,
        );
    }
  }

  Future<void> _authenticateWithCredentials(
      String email, String password) async {
    try {
      final response = await _client!.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _currentUser = response.user;
      if (_currentUser == null) {
        throw SyncError.authentication(
          message: 'Authentication failed: Invalid credentials',
          details: 'Please check your email and password',
        );
      }
    } on AuthException catch (e) {
      throw SyncError.authentication(
        message: 'Authentication failed: ${e.message}',
        details: 'Supabase authentication error',
        originalException: e,
      );
    } catch (e) {
      throw SyncError.authentication(
        message: 'Authentication failed: $e',
        details: 'Unexpected error during authentication',
        originalException: e,
      );
    }
  }

  /// Enhances data with user context for Supabase RLS policies
  Map<String, dynamic> _enhanceDataWithUserContext(Map<String, dynamic> data) {
    final enhancedData = Map<String, dynamic>.from(data);

    // Ensure we have the current user ID for RLS policies
    if (_currentUser != null) {
      // Override created_by and updated_by with the current authenticated user
      // CRITICAL: Convert to string to prevent type casting errors
      enhancedData['created_by'] = _currentUser!.id.toString();
      enhancedData['updated_by'] = _currentUser!.id.toString();

      // Don't add user_id field as it doesn't exist in schema
      // RLS policies should use created_by and updated_by instead
    }

    // Add auth context if available
    if (_authContext != null) {
      if (_authContext!.organizationId != null) {
        // CRITICAL: Convert to string to prevent type casting errors
        enhancedData['organization_id'] =
            _authContext!.organizationId.toString();
      }

      // Add role metadata for RLS policies
      for (final entry in _authContext!.metadata.entries) {
        if (entry.key.startsWith('role_') ||
            entry.key.startsWith('permission_')) {
          enhancedData[entry.key] = entry.value;
        }
      }
    }

    // Final safety check: ensure all ID fields are strings
    final idFields = ['id', 'organization_id', 'created_by', 'updated_by'];
    for (final field in idFields) {
      if (enhancedData.containsKey(field) && enhancedData[field] != null) {
        enhancedData[field] = enhancedData[field].toString();
      }
    }

    return enhancedData;
  }

  /// Sets RLS context variables for current session
  Future<void> _setRLSContext() async {
    if (_authContext == null || _currentUser == null) return;

    try {
      // Set RLS context variables that can be used in policies
      final contextVars = <String, dynamic>{};

      if (_authContext!.userId != null) {
        contextVars['app.user_id'] = _authContext!.userId;
      }
      if (_authContext!.organizationId != null) {
        contextVars['app.organization_id'] = _authContext!.organizationId;
      }

      // Add role metadata to context
      for (final entry in _authContext!.metadata.entries) {
        contextVars['app.${entry.key}'] = entry.value.toString();
      }

      // Execute SET LOCAL commands for RLS context
      for (final entry in contextVars.entries) {
        await _client!.rpc('set_config', params: {
          'setting_name': entry.key,
          'new_value': entry.value,
          'is_local': true,
        });
      }
    } catch (e) {
      // Non-critical: RLS context setting failed, but operation can continue
      // This might happen if the RLS functions don't exist
    }
  }

  Future<void> _startRealtimeSubscription(
    String subscriptionId,
    String collection,
    SyncSubscriptionOptions options,
    StreamController<SyncEvent> controller,
  ) async {
    try {
      final channel = _client!.channel('table_db_changes');
      _subscriptions[subscriptionId] = channel;

      channel
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: collection,
            callback: (payload) {
              final event = _parseRealtimeEvent(payload, collection);
              if (event != null && !controller.isClosed) {
                controller.add(event);
              }
            },
          )
          .subscribe();
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(SyncError.network(
          message: 'Failed to start real-time subscription: $e',
          details: 'Could not establish real-time connection',
          originalException: e,
        ));
      }
    }
  }

  SyncEvent? _parseRealtimeEvent(
      PostgresChangePayload payload, String collection) {
    try {
      SyncEventType eventType;
      Map<String, dynamic>? record;

      switch (payload.eventType) {
        case PostgresChangeEvent.insert:
          eventType = SyncEventType.create;
          record = payload.newRecord;
          break;
        case PostgresChangeEvent.update:
          eventType = SyncEventType.update;
          record = payload.newRecord;
          break;
        case PostgresChangeEvent.delete:
          eventType = SyncEventType.delete;
          record = payload.oldRecord;
          break;
        default:
          return null;
      }

      if (record.isEmpty) return null;

      final mappedData = _mapFromBackendFormat(record);

      // Use id (UUID) as recordId
      final recordId = record['id']?.toString();

      return SyncEvent(
        type: eventType,
        collection: collection,
        recordId: recordId, // Use UUID primary key
        data: mappedData,
        timestamp: DateTime.now(),
        metadata: {
          'id': record['id'].toString(), // UUID primary key
          'created_at': record['created_at'].toString(),
          'updated_at': record['updated_at'].toString(),
          'schema': payload.schema,
          'table': payload.table,
        },
      );
    } catch (e) {
      return null;
    }
  }
}
