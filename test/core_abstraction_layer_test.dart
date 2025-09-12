import 'package:flutter_test/flutter_test.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';

void main() {
  group('USM Core Abstraction Layer Tests', () {
    test('SyncBackendCapabilities should create basic capabilities', () {
      final capabilities = SyncBackendCapabilities.basic();

      expect(capabilities.supportsCrud, isTrue);
      expect(capabilities.supportsBatchOperations, isFalse);
      expect(capabilities.maxBatchSize, equals(50));
      expect(capabilities.maxQueryLimit, equals(500));
    });

    test('SyncBackendCapabilities should create full-featured capabilities',
        () {
      final capabilities = SyncBackendCapabilities.fullFeatured();

      expect(capabilities.supportsCrud, isTrue);
      expect(capabilities.supportsBatchOperations, isTrue);
      expect(capabilities.supportsRealTimeSubscriptions, isTrue);
      expect(capabilities.supportsAuthentication, isTrue);
      expect(capabilities.maxBatchSize, equals(500));
      expect(capabilities.maxQueryLimit, equals(10000));
    });

    test('SyncBackendCapabilities should check features correctly', () {
      final capabilities = SyncBackendCapabilities.fullFeatured();

      expect(capabilities.hasFeature('crud'), isTrue);
      expect(capabilities.hasFeature('batch'), isTrue);
      expect(capabilities.hasFeature('realtime'), isTrue);
      expect(capabilities.hasFeature('nonexistent'), isFalse);
    });

    test('SyncBackendConfiguration should create Firebase config', () {
      final config = SyncBackendConfiguration.firebase(
        configId: 'test-firebase',
        projectId: 'my-project',
        apiKey: 'test-api-key',
      );

      expect(config.backendType, equals('firebase'));
      expect(config.projectId, equals('my-project'));
      expect(config.authConfig?.type, equals(SyncAuthType.apiKey));
      expect(config.displayName, equals('Firebase (my-project)'));
    });

    test('SyncBackendConfiguration should create Supabase config', () {
      final config = SyncBackendConfiguration.supabase(
        configId: 'test-supabase',
        projectUrl: 'https://myproject.supabase.co',
        anonKey: 'test-anon-key',
      );

      expect(config.backendType, equals('supabase'));
      expect(config.projectId, equals('myproject'));
      expect(config.authConfig?.type, equals(SyncAuthType.bearer));
      expect(config.baseUrl, equals('https://myproject.supabase.co'));
    });

    test('SyncBackendConfiguration should create PocketBase config', () {
      final config = SyncBackendConfiguration.pocketBase(
        configId: 'test-pb',
        baseUrl: 'https://api.myapp.com',
        adminEmail: 'admin@test.com',
        adminPassword: 'password',
      );

      expect(config.backendType, equals('pocketbase'));
      expect(config.baseUrl, equals('https://api.myapp.com'));
      expect(config.authConfig?.type, equals(SyncAuthType.usernamePassword));
    });

    test('SyncResult should create successful result', () {
      final result = SyncResult.success(
        data: {'id': 'test-1', 'name': 'Test Item'},
        action: SyncAction.create,
        collection: 'test_items',
        recordId: 'test-1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.error, isNull);
      expect(result.action, equals(SyncAction.create));
      expect(result.affectedRecords, equals(1));
      expect(result.data?['id'], equals('test-1'));
    });

    test('SyncResult should create error result', () {
      final error = SyncError.network(
        message: 'Connection failed',
        httpStatusCode: 500,
        isRetryable: true,
      );

      final result = SyncResult.error(
        error: error,
        action: SyncAction.create,
        collection: 'test_items',
      );

      expect(result.isSuccess, isFalse);
      expect(result.error, isNotNull);
      expect(result.error?.type, equals(SyncErrorType.network));
      expect(result.error?.isRetryable, isTrue);
      expect(result.affectedRecords, equals(0));
    });

    test('SyncError should create specific error types', () {
      final networkError = SyncError.network(
        message: 'Network error',
        httpStatusCode: 503,
        isRetryable: true,
      );

      expect(networkError.type, equals(SyncErrorType.network));
      expect(networkError.httpStatusCode, equals(503));
      expect(networkError.isRetryable, isTrue);

      final authError = SyncError.authentication(
        message: 'Invalid credentials',
        errorCode: 'AUTH_INVALID',
      );

      expect(authError.type, equals(SyncErrorType.authentication));
      expect(authError.errorCode, equals('AUTH_INVALID'));
      expect(authError.isRetryable, isFalse);

      final conflictError = SyncError.conflict(
        message: 'Data conflict detected',
        conflictData: {'field': 'value'},
      );

      expect(conflictError.type, equals(SyncErrorType.conflict));
      expect(conflictError.isConflict, isTrue);
      expect(conflictError.conflictData['field'], equals('value'));
    });

    test('SyncEvent should create different event types', () {
      final createEvent = SyncEvent.create(
        collection: 'test_items',
        recordId: 'test-1',
        data: {'name': 'New Item'},
        organizationId: 'org-1',
      );

      expect(createEvent.type, equals(SyncEventType.create));
      expect(createEvent.collection, equals('test_items'));
      expect(createEvent.recordId, equals('test-1'));
      expect(createEvent.organizationId, equals('org-1'));

      final updateEvent = SyncEvent.update(
        collection: 'test_items',
        recordId: 'test-1',
        data: {'name': 'Updated Item'},
        previousData: {'name': 'Old Item'},
      );

      expect(updateEvent.type, equals(SyncEventType.update));
      expect(updateEvent.data?['name'], equals('Updated Item'));
      expect(updateEvent.previousData?['name'], equals('Old Item'));

      final deleteEvent = SyncEvent.delete(
        collection: 'test_items',
        recordId: 'test-1',
        previousData: {'name': 'Deleted Item'},
      );

      expect(deleteEvent.type, equals(SyncEventType.delete));
      expect(deleteEvent.recordId, equals('test-1'));
    });

    test('SyncEvent should check organization affiliation', () {
      final event = SyncEvent.create(
        collection: 'test_items',
        recordId: 'test-1',
        data: {'name': 'Test'},
        organizationId: 'org-1',
      );

      expect(event.affectsOrganization('org-1'), isTrue);
      expect(event.affectsOrganization('org-2'), isFalse);

      final globalEvent = SyncEvent.create(
        collection: 'test_items',
        recordId: 'test-1',
        data: {'name': 'Test'},
        // No organizationId = affects all organizations
      );

      expect(globalEvent.affectsOrganization('org-1'), isTrue);
      expect(globalEvent.affectsOrganization('org-2'), isTrue);
    });

    test('SyncQuery should create organization-specific queries', () {
      final query = SyncQuery.byOrganization(
        'org-1',
        additionalFilters: {'isActive': 1},
        orderBy: [SyncOrderBy.desc('updatedAt')],
        limit: 100,
      );

      expect(query.filters['organizationId'], equals('org-1'));
      expect(query.filters['isActive'], equals(1));
      expect(query.orderBy.length, equals(1));
      expect(query.orderBy[0].field, equals('updatedAt'));
      expect(query.orderBy[0].direction, equals(SyncOrderDirection.descending));
      expect(query.limit, equals(100));
    });

    test('SyncQuery should create dirty records query', () {
      final query = SyncQuery.dirtyRecords(
        organizationId: 'org-1',
        limit: 50,
      );

      expect(query.filters['isDirty'], equals(1));
      expect(query.filters['organizationId'], equals('org-1'));
      expect(query.limit, equals(50));
    });
  });
}
