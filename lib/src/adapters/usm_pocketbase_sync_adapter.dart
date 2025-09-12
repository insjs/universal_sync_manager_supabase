import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../interfaces/usm_sync_backend_adapter.dart';
import '../models/usm_sync_backend_capabilities.dart';
import '../models/usm_sync_backend_configuration.dart';
import '../models/usm_sync_result.dart';
import '../models/usm_sync_event.dart';
import '../models/usm_auth_context.dart';
import '../services/usm_token_manager.dart';
import '../config/usm_sync_enums.dart';

/// PocketBase implementation of the Universal Sync Manager backend adapter
///
/// This adapter provides integration with PocketBase backend services,
/// implementing the standard ISyncBackendAdapter interface to enable
/// seamless switching between different backend providers.
///
/// Key Features:
/// - Full CRUD operations with PocketBase collections
/// - Real-time subscriptions using PocketBase API
/// - Authentication integration with PocketBase auth
/// - Automatic field mapping for USM conventions
/// - Error handling with proper USM error types
/// - Connection management and health monitoring
///
/// Following USM naming conventions:
/// - File: usm_pocketbase_sync_adapter.dart (snake_case with usm_ prefix)
/// - Class: PocketBaseSyncAdapter (PascalCase)
class PocketBaseSyncAdapter implements ISyncBackendAdapter {
  // Core PocketBase configuration
  final String baseUrl;
  final Duration connectionTimeout;
  final Duration requestTimeout;

  // Connection state
  bool _isConnected = false;
  HttpClient? _httpClient;

  // Real-time subscriptions tracking
  final Map<String, StreamController<SyncEvent>> _subscriptions = {};
  final Map<String, HttpClientRequest> _sseConnections = {};
  Timer? _heartbeatTimer;

  // Authentication state
  String? _authToken;
  Map<String, dynamic>? _currentUser;
  DateTime? _tokenExpiry;

  // Enhanced authentication integration
  AuthContext? _authContext;
  TokenManager? _tokenManager;
  SyncAuthConfiguration? _authConfig;

  // Backend metadata
  static const String _backendType = 'pocketbase';
  static const String _backendVersion = '0.22.0';

  /// Creates a new PocketBase sync adapter
  PocketBaseSyncAdapter({
    required this.baseUrl,
    this.connectionTimeout = const Duration(seconds: 30),
    this.requestTimeout = const Duration(seconds: 60),
  }) {
    _httpClient = HttpClient();
    _httpClient!.connectionTimeout = connectionTimeout;
  }

  @override
  String get backendType => _backendType;

  @override
  String get backendVersion => _backendVersion;

  @override
  Map<String, dynamic> get backendInfo => {
        'baseUrl': baseUrl,
        'connectionTimeout': connectionTimeout.inSeconds,
        'requestTimeout': requestTimeout.inSeconds,
        'isAuthenticated': _authToken != null,
        'currentUser': _currentUser,
        'tokenExpiry': _tokenExpiry?.toIso8601String(),
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
      SyncBackendCapabilities.pocketBase();

  // === Connection Management ===

  @override
  Future<bool> connect(SyncBackendConfiguration config) async {
    try {
      // Validate configuration
      if (config.backendType != _backendType) {
        throw SyncError.validation(
          message:
              'Invalid backend type: ${config.backendType}. Expected: $_backendType',
          details: 'PocketBase adapter can only connect to PocketBase backends',
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

      // Test connection with health check (bypass _ensureConnected during initial connection)
      final healthResponse =
          await _makeRequestWithoutConnectionCheck('GET', '/api/health');
      if (healthResponse.statusCode != 200) {
        throw SyncError.network(
          message: 'PocketBase health check failed',
          details: 'Could not connect to PocketBase server at $baseUrl',
          httpStatusCode: healthResponse.statusCode,
        );
      }

      // Handle authentication - support both old and new auth patterns
      if (_authConfig != null &&
          _authConfig!.credentials.containsKey('token')) {
        // Enhanced auth: use token from auth config
        _authToken = _authConfig!.credentials['token'] as String;
      } else if (config.customSettings.containsKey('email') &&
          config.customSettings.containsKey('password')) {
        // Legacy auth: authenticate with credentials
        await _authenticateWithCredentials(
          config.customSettings['email'] as String,
          config.customSettings['password'] as String,
        );
      }

      _startHeartbeat();
      _isConnected = true;
      return true;
    } catch (e) {
      _isConnected = false;
      if (e is SyncError) rethrow;

      throw SyncError.network(
        message: 'Failed to connect to PocketBase: $e',
        details: 'Connection error during PocketBase initialization',
        originalException: e,
      );
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;

      for (final request in _sseConnections.values) {
        request.close();
      }
      _sseConnections.clear();

      for (final controller in _subscriptions.values) {
        await controller.close();
      }
      _subscriptions.clear();

      _authToken = null;
      _currentUser = null;
      _tokenExpiry = null;

      _httpClient?.close();
      _httpClient = null;

      _isConnected = false;
    } catch (e) {
      print('Warning: Error during PocketBase disconnect: $e');
    }
  }

  // === CRUD Operations ===

  @override
  Future<SyncResult> create(
      String collection, Map<String, dynamic> data) async {
    _ensureConnected();

    try {
      final pocketBaseData = _mapToBackendFormat(data);
      final response = await _makeRequest(
        'POST',
        '/api/collections/$collection/records',
        body: pocketBaseData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = await response.transform(utf8.decoder).join();
        final responseData = json.decode(responseBody) as Map<String, dynamic>;
        final mappedData = _mapFromBackendFormat(responseData);

        return SyncResult.success(
          data: mappedData,
          action: SyncAction.create,
          collection: collection,
          recordId: responseData['id'] as String,
          metadata: {
            'backendId': responseData['id'],
            'created': responseData['created'],
            'updated': responseData['updated'],
          },
        );
      } else {
        final error = await _parseErrorResponse(response);
        return SyncResult.error(
          error: error,
          action: SyncAction.create,
          collection: collection,
        );
      }
    } catch (e) {
      return SyncResult.error(
        error: SyncError.network(
          message: 'Failed to create record in collection $collection: $e',
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
      final response =
          await _makeRequest('GET', '/api/collections/$collection/records/$id');

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final responseData = json.decode(responseBody) as Map<String, dynamic>;
        final mappedData = _mapFromBackendFormat(responseData);

        return SyncResult.success(
          data: mappedData,
          action: SyncAction.read,
          collection: collection,
          recordId: id,
          metadata: {
            'backendId': id,
            'created': responseData['created'],
            'updated': responseData['updated'],
          },
        );
      } else if (response.statusCode == 404) {
        return SyncResult.error(
          error: SyncError.validation(
            message: 'Record not found: $id in collection $collection',
            details: 'The requested record does not exist',
          ),
          action: SyncAction.read,
          collection: collection,
          recordId: id,
        );
      } else {
        final error = await _parseErrorResponse(response);
        return SyncResult.error(
          error: error,
          action: SyncAction.read,
          collection: collection,
          recordId: id,
        );
      }
    } catch (e) {
      return SyncResult.error(
        error: SyncError.network(
          message: 'Failed to read record $id from collection $collection: $e',
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
      final pocketBaseData = _mapToBackendFormat(data);
      final response = await _makeRequest(
        'PATCH',
        '/api/collections/$collection/records/$id',
        body: pocketBaseData,
      );

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final responseData = json.decode(responseBody) as Map<String, dynamic>;
        final mappedData = _mapFromBackendFormat(responseData);

        return SyncResult.success(
          data: mappedData,
          action: SyncAction.update,
          collection: collection,
          recordId: id,
          metadata: {
            'backendId': id,
            'created': responseData['created'],
            'updated': responseData['updated'],
          },
        );
      } else {
        final error = await _parseErrorResponse(response);
        return SyncResult.error(
          error: error,
          action: SyncAction.update,
          collection: collection,
          recordId: id,
        );
      }
    } catch (e) {
      return SyncResult.error(
        error: SyncError.network(
          message: 'Failed to update record $id in collection $collection: $e',
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
      final response = await _makeRequest(
          'DELETE', '/api/collections/$collection/records/$id');

      if (response.statusCode == 204) {
        return SyncResult.success(
          data: {'id': id, 'isDeleted': true},
          action: SyncAction.delete,
          collection: collection,
          recordId: id,
          metadata: {
            'backendId': id,
            'deletedAt': DateTime.now().toIso8601String(),
          },
        );
      } else {
        final error = await _parseErrorResponse(response);
        return SyncResult.error(
          error: error,
          action: SyncAction.delete,
          collection: collection,
          recordId: id,
        );
      }
    } catch (e) {
      return SyncResult.error(
        error: SyncError.network(
          message:
              'Failed to delete record $id from collection $collection: $e',
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
      final queryParams = _buildQueryParams(query);
      final queryString = Uri(queryParameters: queryParams).query;
      final url = '/api/collections/$collection/records' +
          (queryString.isNotEmpty ? '?$queryString' : '');

      final response = await _makeRequest('GET', url);

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final responseData = json.decode(responseBody) as Map<String, dynamic>;
        final items = responseData['items'] as List<dynamic>;

        return items.map((item) {
          final itemData = item as Map<String, dynamic>;
          final mappedData = _mapFromBackendFormat(itemData);
          return SyncResult.success(
            data: mappedData,
            action: SyncAction.read,
            collection: collection,
            recordId: itemData['id'] as String,
            metadata: {
              'backendId': itemData['id'],
              'created': itemData['created'],
              'updated': itemData['updated'],
            },
          );
        }).toList();
      } else {
        final error = await _parseErrorResponse(response);
        return [
          SyncResult.error(
            error: error,
            action: SyncAction.read,
            collection: collection,
          )
        ];
      }
    } catch (e) {
      return [
        SyncResult.error(
          error: SyncError.network(
            message: 'Failed to query collection $collection: $e',
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
    final results = <SyncResult>[];

    for (final item in items) {
      final result = await create(collection, item);
      results.add(result);

      if (items.length > 10) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    return results;
  }

  @override
  Future<List<SyncResult>> batchUpdate(
      String collection, List<Map<String, dynamic>> items) async {
    final results = <SyncResult>[];

    for (final item in items) {
      final id = item['id'] as String?;
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

      if (items.length > 10) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    return results;
  }

  @override
  Future<List<SyncResult>> batchDelete(
      String collection, List<String> ids) async {
    final results = <SyncResult>[];

    for (final id in ids) {
      final result = await delete(collection, id);
      results.add(result);

      if (ids.length > 10) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    return results;
  }

  // === Real-time Subscriptions ===

  @override
  Stream<SyncEvent> subscribe(
      String collection, SyncSubscriptionOptions options) {
    final subscriptionId =
        '${collection}_${DateTime.now().millisecondsSinceEpoch}';

    final controller = StreamController<SyncEvent>.broadcast();
    _subscriptions[subscriptionId] = controller;

    _startRealtimeSubscription(subscriptionId, collection, options, controller);

    return controller.stream;
  }

  @override
  Future<void> unsubscribe(String subscriptionId) async {
    final controller = _subscriptions.remove(subscriptionId);
    if (controller != null) {
      await controller.close();
    }

    final request = _sseConnections.remove(subscriptionId);
    if (request != null) {
      request.close();
    }
  }

  // === Private Helper Methods ===

  void _ensureConnected() {
    if (!_isConnected) {
      throw SyncError.network(
        message: 'Not connected to PocketBase. Call connect() first.',
        details: 'Adapter must be connected before performing operations',
      );
    }
  }

  Future<HttpClientResponse> _makeRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    _ensureConnected();

    final uri = Uri.parse('$baseUrl$path');
    final request = await _httpClient!.openUrl(method, uri);

    request.headers.set('Content-Type', 'application/json');

    // Add authentication token
    if (_authToken != null) {
      request.headers.set('Authorization', 'Bearer $_authToken');
    }

    // Add user context headers for PocketBase collection rules
    if (_authContext != null) {
      if (_authContext!.userId != null) {
        request.headers.set('X-User-Id', _authContext!.userId!);
      }
      if (_authContext!.organizationId != null) {
        request.headers.set('X-Organization-Id', _authContext!.organizationId!);
      }

      // Add role/feature metadata as headers for PocketBase rules
      if (_authContext!.metadata.isNotEmpty) {
        for (final entry in _authContext!.metadata.entries) {
          request.headers.set('X-Meta-${entry.key}', entry.value.toString());
        }
      }
    }

    // Enhance body with user context for PocketBase filtering
    if (body != null) {
      final enhancedBody = Map<String, dynamic>.from(body);

      // Add user context to request body for backend filtering
      if (_authContext != null) {
        if (_authContext!.userId != null) {
          enhancedBody['__user_id'] = _authContext!.userId;
        }
        if (_authContext!.organizationId != null) {
          enhancedBody['__organization_id'] = _authContext!.organizationId;
        }
        // Add additional user context fields
        for (final entry in _authContext!.userContext.entries) {
          enhancedBody['__${entry.key}'] = entry.value;
        }
      }

      final bodyJson = json.encode(enhancedBody);
      request.write(bodyJson);
    }

    return await request.close();
  }

  /// Make HTTP request without connection state check (used during initial connection)
  Future<HttpClientResponse> _makeRequestWithoutConnectionCheck(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = await _httpClient!.openUrl(method, uri);

    request.headers.set('Content-Type', 'application/json');
    if (_authToken != null) {
      request.headers.set('Authorization', 'Bearer $_authToken');
    }

    if (body != null) {
      final bodyJson = json.encode(body);
      request.write(bodyJson);
    }

    return await request.close();
  }

  Map<String, dynamic> _mapToBackendFormat(Map<String, dynamic> data) {
    final mapped = Map<String, dynamic>.from(data);

    for (final entry in mapped.entries) {
      if (entry.value is DateTime) {
        mapped[entry.key] = (entry.value as DateTime).toIso8601String();
      }
    }

    return mapped;
  }

  Map<String, dynamic> _mapFromBackendFormat(Map<String, dynamic> data) {
    final mapped = Map<String, dynamic>.from(data);

    // Map PocketBase timestamp fields to USM snake_case conventions
    if (data.containsKey('created')) {
      mapped['created_at'] = data['created'];
    }
    if (data.containsKey('updated')) {
      mapped['updated_at'] = data['updated'];
    }

    for (final entry in mapped.entries) {
      if (entry.value is String && _isDateTimeField(entry.key)) {
        try {
          mapped[entry.key] = DateTime.parse(entry.value as String);
        } catch (e) {
          // Keep as string if parsing fails
        }
      }
    }

    return mapped;
  }

  bool _isDateTimeField(String fieldName) {
    final dateTimeFields = {
      'created_at',
      'updated_at',
      'deleted_at',
      'last_synced_at',
      'created',
      'updated',
      'deleted'
    };
    return dateTimeFields.contains(fieldName);
  }

  Map<String, String> _buildQueryParams(SyncQuery query) {
    final params = <String, String>{};

    if (query.filters.isNotEmpty) {
      final filterParts = <String>[];
      for (final entry in query.filters.entries) {
        final value = entry.value;
        String filterValue;

        if (value is String) {
          filterValue = '"$value"';
        } else if (value is DateTime) {
          filterValue = '"${value.toIso8601String()}"';
        } else if (value is bool || value is num) {
          filterValue = value.toString();
        } else if (value == null) {
          filterValue = 'null';
        } else {
          filterValue = '"${jsonEncode(value)}"';
        }

        filterParts.add('${entry.key} = $filterValue');
      }
      params['filter'] = filterParts.join(' && ');
    }

    if (query.orderBy.isNotEmpty) {
      final sortParts = query.orderBy.map((order) {
        final direction =
            order.direction == SyncOrderDirection.descending ? '-' : '+';
        return '$direction${order.field}';
      }).toList();
      params['sort'] = sortParts.join(',');
    }

    if (query.limit != null) {
      params['perPage'] = query.limit.toString();
    }
    if (query.offset != null) {
      params['page'] = ((query.offset! ~/ (query.limit ?? 30)) + 1).toString();
    }

    if (query.fields != null && query.fields!.isNotEmpty) {
      params['fields'] = query.fields!.join(',');
    }

    return params;
  }

  Future<SyncError> _parseErrorResponse(HttpClientResponse response) async {
    try {
      final responseBody = await response.transform(utf8.decoder).join();
      final errorData = json.decode(responseBody) as Map<String, dynamic>;

      return _mapHttpStatusToSyncError(
        response.statusCode,
        errorData['message'] as String? ?? 'Unknown PocketBase error',
        errorData,
      );
    } catch (e) {
      return _mapHttpStatusToSyncError(
        response.statusCode,
        'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        null,
      );
    }
  }

  SyncError _mapHttpStatusToSyncError(
      int statusCode, String message, Map<String, dynamic>? errorData) {
    switch (statusCode) {
      case 400:
        return SyncError.validation(
          message: 'Validation error: $message',
          details: errorData?.toString(),
        );
      case 401:
        return SyncError.authentication(
          message: 'Authentication required: $message',
          details: 'Please check your authentication credentials',
        );
      case 403:
        return SyncError.authorization(
          message: 'Access forbidden: $message',
          details: 'You do not have permission to perform this operation',
        );
      case 404:
        return SyncError.validation(
          message: 'Record not found: $message',
          details: 'The requested record does not exist',
        );
      case 409:
        return SyncError.conflict(
          message: 'Conflict: $message',
          details:
              'The operation conflicts with the current state of the resource',
        );
      case 429:
        return SyncError.rateLimit(
          message: 'Rate limit exceeded: $message',
          details: 'Too many requests, please slow down',
        );
      case 500:
      case 502:
      case 503:
      case 504:
        return SyncError.backend(
          message: 'Server error: $message',
          details: 'The server encountered an error processing the request',
          httpStatusCode: statusCode,
        );
      default:
        return SyncError.network(
          message: 'Network error: $message',
          details: 'The network request failed',
          httpStatusCode: statusCode,
        );
    }
  }

  Future<void> _authenticateWithCredentials(
      String email, String password) async {
    final response = await _makeRequestWithoutConnectionCheck(
      'POST',
      '/api/collections/ost_super_admins/auth-with-password',
      body: {'identity': email, 'password': password},
    );

    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final data = json.decode(responseBody) as Map<String, dynamic>;
      _authToken = data['token'] as String?;
      _currentUser = data['record'] as Map<String, dynamic>?;
      _tokenExpiry = DateTime.now().add(const Duration(hours: 23));
    } else {
      final error = await _parseErrorResponse(response);
      throw error;
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      try {
        final response = await _makeRequest('GET', '/api/health');
        if (response.statusCode != 200) {
          _isConnected = false;
          timer.cancel();
        }
      } catch (e) {
        _isConnected = false;
        timer.cancel();
      }
    });
  }

  Future<void> _startRealtimeSubscription(
    String subscriptionId,
    String collection,
    SyncSubscriptionOptions options,
    StreamController<SyncEvent> controller,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/api/realtime');
      final request = await _httpClient!.getUrl(uri);

      if (_authToken != null) {
        request.headers.set('Authorization', 'Bearer $_authToken');
      }

      request.headers.set('Accept', 'text/event-stream');
      request.headers.set('Cache-Control', 'no-cache');

      final response = await request.close();
      _sseConnections[subscriptionId] = request;

      response.transform(utf8.decoder).transform(const LineSplitter()).listen(
        (line) {
          if (line.startsWith('data: ')) {
            try {
              final data =
                  json.decode(line.substring(6)) as Map<String, dynamic>;
              final event = _parseRealtimeEvent(data, collection);
              if (event != null && !controller.isClosed) {
                controller.add(event);
              }
            } catch (e) {
              // Ignore parsing errors for SSE
            }
          }
        },
        onError: (error) {
          if (!controller.isClosed) {
            controller.addError(SyncError.network(
              message: 'Real-time subscription error: $error',
              details: 'Error in real-time subscription stream',
              originalException: error,
            ));
          }
        },
        onDone: () {
          _sseConnections.remove(subscriptionId);
        },
      );
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

  SyncEvent? _parseRealtimeEvent(Map<String, dynamic> data, String collection) {
    try {
      final action = data['action'] as String?;
      final record = data['record'] as Map<String, dynamic>?;

      if (action == null || record == null) return null;

      SyncEventType eventType;
      switch (action) {
        case 'create':
          eventType = SyncEventType.create;
          break;
        case 'update':
          eventType = SyncEventType.update;
          break;
        case 'delete':
          eventType = SyncEventType.delete;
          break;
        default:
          return null;
      }

      final mappedData = _mapFromBackendFormat(record);

      return SyncEvent(
        type: eventType,
        collection: collection,
        recordId: record['id'] as String?,
        data: mappedData,
        timestamp: DateTime.now(),
        metadata: {
          'backendId': record['id'],
          'created': record['created'],
          'updated': record['updated'],
        },
      );
    } catch (e) {
      return null;
    }
  }
}
