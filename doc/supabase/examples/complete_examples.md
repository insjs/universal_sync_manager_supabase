# Code Examples

Copy-paste code examples for common Universal Sync Manager scenarios.

## 🚀 Quick Start Example

```dart
import 'package:universal_sync_manager/universal_sync_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'your-supabase-url',
    anonKey: 'your-anon-key',
  );

  // Initialize USM
  final syncManager = UniversalSyncManager();
  await syncManager.initialize(UniversalSyncConfig(
    projectId: 'your-project-id',
    syncMode: SyncMode.automatic,
  ));

  // Set Supabase backend
  await syncManager.setBackend(SupabaseSyncAdapter());

  // Register entities
  syncManager.registerEntity(
    'user_profiles',
    SyncEntityConfig(tableName: 'user_profiles'),
  );

  runApp(MyApp(syncManager: syncManager));
}
```

## 👤 User Profile Management

### Create User Profile

```dart
class UserProfileService {
  final UniversalSyncManager _syncManager;

  UserProfileService(this._syncManager);

  Future<UserProfile> createProfile({
    required String organizationId,
    required String name,
    required String email,
  }) async {
    final profile = UserProfile.create(
      organizationId: organizationId,
      name: name,
      email: email,
      createdBy: Supabase.instance.client.auth.currentUser!.id,
    );

    final result = await _syncManager.create('user_profiles', profile.toJson());

    if (result.isSuccess && result.data != null) {
      return UserProfile.fromJson(result.data!);
    } else {
      throw Exception('Failed to create profile: ${result.error?.message}');
    }
  }
}
```

### Update User Profile

```dart
Future<UserProfile> updateProfile(UserProfile profile) async {
  final updatedProfile = profile.copyWith(
    name: 'Updated Name',
    updatedBy: Supabase.instance.client.auth.currentUser!.id,
    updatedAt: DateTime.now(),
  );

  final result = await _syncManager.update(
    'user_profiles',
    profile.id,
    updatedProfile.toJson(),
  );

  if (result.isSuccess && result.data != null) {
    return UserProfile.fromJson(result.data!);
  } else {
    throw Exception('Failed to update profile: ${result.error?.message}');
  }
}
```

### Get User Profiles

```dart
Future<List<UserProfile>> getUserProfiles(String organizationId) async {
  final result = await _syncManager.query(
    'user_profiles',
    SyncQuery(
      filters: {
        'organization_id': organizationId,
        'is_deleted': false,
      },
      orderBy: 'created_at DESC',
    ),
  );

  if (result.isSuccess && result.data != null) {
    return result.data!.map((json) => UserProfile.fromJson(json)).toList();
  } else {
    throw Exception('Failed to get profiles: ${result.error?.message}');
  }
}
```

### Delete User Profile

```dart
Future<void> deleteProfile(String profileId) async {
  final result = await _syncManager.delete('user_profiles', profileId);

  if (!result.isSuccess) {
    throw Exception('Failed to delete profile: ${result.error?.message}');
  }
}
```

## 🔐 Authentication Integration

### Login Flow

```dart
class AuthService {
  final UniversalSyncManager _syncManager;

  AuthService(this._syncManager);

  Future<UserProfile?> login(String email, String password) async {
    try {
      // Authenticate with Supabase
      final authResponse = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user != null) {
        // Get or create user profile
        final profile = await _getOrCreateProfile(authResponse.user!.id, email);
        return profile;
      }
    } catch (e) {
      print('Login failed: $e');
    }
    return null;
  }

  Future<UserProfile?> _getOrCreateProfile(String userId, String email) async {
    // Try to get existing profile
    final result = await _syncManager.query(
      'user_profiles',
      SyncQuery(filters: {'id': userId}),
    );

    if (result.isSuccess && result.data != null && result.data!.isNotEmpty) {
      return UserProfile.fromJson(result.data!.first);
    }

    // Create new profile if doesn't exist
    final newProfile = UserProfile.create(
      id: userId,
      organizationId: 'default-org', // You might want to determine this differently
      name: email.split('@').first, // Default name from email
      email: email,
      createdBy: userId,
    );

    final createResult = await _syncManager.create('user_profiles', newProfile.toJson());

    if (createResult.isSuccess && createResult.data != null) {
      return UserProfile.fromJson(createResult.data!);
    }

    return null;
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
  }
}
```

### Protected Route Widget

```dart
class ProtectedRoute extends StatelessWidget {
  final Widget child;

  const ProtectedRoute({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      // Redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return child;
  }
}
```

## 🔄 Sync Management

### Manual Sync

```dart
class SyncService {
  final UniversalSyncManager _syncManager;

  SyncService(this._syncManager);

  Future<void> syncAllData() async {
    print('🔄 Starting full sync...');

    final results = await _syncManager.syncAll();

    for (final result in results) {
      if (result.isSuccess) {
        print('✅ Synced ${result.entityName}: ${result.affectedItems} items');
      } else {
        print('❌ Failed to sync ${result.entityName}: ${result.error?.message}');
      }
    }

    print('🔄 Full sync completed');
  }

  Future<void> syncEntity(String entityName) async {
    print('🔄 Syncing $entityName...');

    final result = await _syncManager.syncEntity(entityName);

    if (result.isSuccess) {
      print('✅ Synced $entityName: ${result.affectedItems} items');
    } else {
      print('❌ Failed to sync $entityName: ${result.error?.message}');
    }
  }

  // Listen to sync progress
  StreamSubscription<SyncProgress>? _progressSubscription;

  void startListeningToSyncProgress() {
    _progressSubscription = _syncManager.syncProgressStream.listen((progress) {
      print('🔄 Sync Progress: ${progress.currentEntity} - ${progress.status}');

      if (progress.status == SyncStatus.completed) {
        print('✅ Sync completed: ${progress.recordsProcessed} records processed');
      }
    });
  }

  void stopListeningToSyncProgress() {
    _progressSubscription?.cancel();
  }
}
```

### Real-time Updates

```dart
class RealTimeService {
  final UniversalSyncManager _syncManager;
  StreamSubscription<SyncEvent>? _subscription;

  RealTimeService(this._syncManager);

  void startRealTimeUpdates() {
    _subscription = _syncManager.subscribe(
      'user_profiles',
      SyncSubscriptionOptions(),
    ).listen((event) {
      print('📡 Real-time event: ${event.type} on ${event.collection}');

      switch (event.type) {
        case 'INSERT':
          print('➕ New record: ${event.data}');
          break;
        case 'UPDATE':
          print('✏️ Updated record: ${event.data}');
          break;
        case 'DELETE':
          print('🗑️ Deleted record: ${event.id}');
          break;
      }
    });
  }

  void stopRealTimeUpdates() {
    _subscription?.cancel();
  }
}
```

## ⚔️ Conflict Resolution

### Custom Conflict Resolver

```dart
class CustomConflictResolver implements ConflictResolver {
  @override
  SyncConflictResolution resolveConflict(SyncConflict conflict) {
    // Always prefer server data for certain fields
    final serverWinsFields = ['is_active', 'organization_id'];

    // Always prefer client data for certain fields
    final clientWinsFields = ['last_login_at'];

    // Check if any server-wins fields have conflicts
    final serverWinsConflicts = conflict.fieldConflicts.keys
        .where((field) => serverWinsFields.contains(field))
        .toList();

    if (serverWinsConflicts.isNotEmpty) {
      return SyncConflictResolution.useServer(serverWinsConflicts);
    }

    // Check if any client-wins fields have conflicts
    final clientWinsConflicts = conflict.fieldConflicts.keys
        .where((field) => clientWinsFields.contains(field))
        .toList();

    if (clientWinsConflicts.isNotEmpty) {
      return SyncConflictResolution.useClient(clientWinsConflicts);
    }

    // For other fields, let user decide
    return SyncConflictResolution.manual();
  }
}

// Register custom resolver
syncManager.setConflictResolver('user_profiles', CustomConflictResolver());
```

### Conflict Handling in UI

```dart
class ConflictDialog extends StatelessWidget {
  final SyncConflict conflict;

  const ConflictDialog({Key? key, required this.conflict}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Sync Conflict'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('A conflict occurred while syncing:'),
          SizedBox(height: 16),
          ...conflict.fieldConflicts.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${entry.key}:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Local: ${entry.value.localValue}'),
                Text('Server: ${entry.value.serverValue}'),
                SizedBox(height: 8),
              ],
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(SyncConflictResolution.useClient()),
          child: Text('Use Local'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(SyncConflictResolution.useServer()),
          child: Text('Use Server'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(SyncConflictResolution.manual()),
          child: Text('Resolve Manually'),
        ),
      ],
    );
  }
}
```

## 📊 App Settings Management

### Settings Service

```dart
class AppSettingsService {
  final UniversalSyncManager _syncManager;

  AppSettingsService(this._syncManager);

  Future<AppSettings> getSettings(String organizationId) async {
    final result = await _syncManager.query(
      'app_settings',
      SyncQuery(
        filters: {'organization_id': organizationId},
        limit: 1,
      ),
    );

    if (result.isSuccess && result.data != null && result.data!.isNotEmpty) {
      return AppSettings.fromJson(result.data!.first);
    }

    // Return default settings if none exist
    return AppSettings.create(
      organizationId: organizationId,
      createdBy: Supabase.instance.client.auth.currentUser!.id,
    );
  }

  Future<AppSettings> updateSettings(AppSettings settings) async {
    final updatedSettings = settings.copyWith(
      updatedBy: Supabase.instance.client.auth.currentUser!.id,
      updatedAt: DateTime.now(),
    );

    final result = await _syncManager.update(
      'app_settings',
      settings.id,
      updatedSettings.toJson(),
    );

    if (result.isSuccess && result.data != null) {
      return AppSettings.fromJson(result.data!);
    } else {
      throw Exception('Failed to update settings: ${result.error?.message}');
    }
  }

  Future<void> resetToDefaults(String organizationId) async {
    final defaultSettings = AppSettings.create(
      organizationId: organizationId,
      createdBy: Supabase.instance.client.auth.currentUser!.id,
    );

    await _syncManager.create('app_settings', defaultSettings.toJson());
  }
}
```

## 🧪 Testing Examples

### Unit Test Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockSyncManager extends Mock implements UniversalSyncManager {}

void main() {
  late UserProfileService service;
  late MockSyncManager mockSyncManager;

  setUp(() {
    mockSyncManager = MockSyncManager();
    service = UserProfileService(mockSyncManager);
  });

  test('should create user profile successfully', () async {
    // Arrange
    final profileJson = {
      'id': 'test-id',
      'organization_id': 'org-1',
      'name': 'Test User',
      'email': 'test@example.com',
      'created_by': 'user-1',
      'is_dirty': false,
      'sync_version': 1,
      'is_deleted': false,
    };

    when(mockSyncManager.create('user_profiles', any))
        .thenAnswer((_) async => SyncResult.success(
              data: profileJson,
              action: SyncAction.create,
              timestamp: DateTime.now(),
            ));

    // Act
    final result = await service.createProfile(
      organizationId: 'org-1',
      name: 'Test User',
      email: 'test@example.com',
    );

    // Assert
    expect(result.id, 'test-id');
    expect(result.name, 'Test User');
    expect(result.email, 'test@example.com');
    verify(mockSyncManager.create('user_profiles', any)).called(1);
  });
}
```

### Integration Test Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('end-to-end user profile flow', (tester) async {
    // Initialize app
    await tester.pumpWidget(MyApp());

    // Navigate to profile creation
    await tester.tap(find.byKey(Key('create_profile_button')));
    await tester.pumpAndSettle();

    // Fill form
    await tester.enterText(find.byKey(Key('name_field')), 'Integration Test User');
    await tester.enterText(find.byKey(Key('email_field')), 'integration@example.com');
    await tester.tap(find.byKey(Key('submit_button')));
    await tester.pumpAndSettle();

    // Verify profile was created and synced
    expect(find.text('Profile created successfully'), findsOneWidget);

    // Wait for sync to complete
    await tester.pump(Duration(seconds: 5));

    // Verify data is persisted
    final profileList = find.byKey(Key('profile_list'));
    expect(find.descendant(of: profileList, matching: find.text('Integration Test User')), findsOneWidget);
  });
}
```

## 🎯 Complete App Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'your-supabase-url',
    anonKey: 'your-anon-key',
  );

  // Initialize USM
  final syncManager = UniversalSyncManager();
  await syncManager.initialize(UniversalSyncConfig(
    projectId: 'demo-app',
    syncMode: SyncMode.automatic,
  ));

  // Set backend
  await syncManager.setBackend(SupabaseSyncAdapter());

  // Register entities
  syncManager.registerEntity(
    'user_profiles',
    SyncEntityConfig(tableName: 'user_profiles'),
  );

  runApp(
    ProviderScope(
      overrides: [
        syncManagerProvider.overrideWithValue(syncManager),
      ],
      child: MyApp(),
    ),
  );
}

final syncManagerProvider = Provider<UniversalSyncManager>((ref) {
  throw UnimplementedError();
});

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'USM Demo App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthWrapper(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return LoginScreen();
    }

    return HomeScreen();
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading ? CircularProgressIndicator() : Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncManager = ref.watch(syncManagerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('User Profiles'),
        actions: [
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: () async {
              await syncManager.syncAll();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sync completed')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: UserProfilesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateProfileDialog(context, ref),
        child: Icon(Icons.add),
      ),
    );
  }

  void _showCreateProfileDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final syncManager = ref.read(syncManagerProvider);
              final user = Supabase.instance.client.auth.currentUser!;

              final profile = UserProfile.create(
                organizationId: 'demo-org',
                name: nameController.text,
                email: emailController.text,
                createdBy: user.id,
              );

              await syncManager.create('user_profiles', profile.toJson());
              Navigator.of(context).pop();
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }
}

class UserProfilesList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncManager = ref.watch(syncManagerProvider);

    return StreamBuilder<List<UserProfile>>(
      stream: _getProfilesStream(syncManager),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final profiles = snapshot.data!;

        return ListView.builder(
          itemCount: profiles.length,
          itemBuilder: (context, index) {
            final profile = profiles[index];
            return ListTile(
              title: Text(profile.name),
              subtitle: Text(profile.email),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () async {
                  await syncManager.delete('user_profiles', profile.id);
                },
              ),
            );
          },
        );
      },
    );
  }

  Stream<List<UserProfile>> _getProfilesStream(UniversalSyncManager syncManager) async* {
    // Initial load
    final result = await syncManager.query(
      'user_profiles',
      SyncQuery(filters: {'is_deleted': false}),
    );

    if (result.isSuccess && result.data != null) {
      yield result.data!.map((json) => UserProfile.fromJson(json)).toList();
    } else {
      yield [];
    }

    // Listen for real-time updates
    await for (final event in syncManager.subscribe('user_profiles', SyncSubscriptionOptions())) {
      final result = await syncManager.query(
        'user_profiles',
        SyncQuery(filters: {'is_deleted': false}),
      );

      if (result.isSuccess && result.data != null) {
        yield result.data!.map((json) => UserProfile.fromJson(json)).toList();
      }
    }
  }
}
```