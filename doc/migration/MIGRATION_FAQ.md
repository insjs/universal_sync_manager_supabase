# Universal Sync Manager Migration FAQ - Phase 3

## Frequently Asked Questions

### General Migration Questions

#### Q: How long does migration to Phase 3 typically take?
**A:** Migration time depends on your project complexity:
- **Small projects** (1-5 entities): 1-2 hours with MyAppSyncManager
- **Medium projects** (5-20 entities): 4-8 hours 
- **Large projects** (20+ entities): 1-2 days

Phase 3's simplified API significantly reduces migration complexity compared to earlier USM versions.

#### Q: What's different about Phase 3 migration?
**A:** Phase 3 introduces MyAppSyncManager, which dramatically simplifies migration:
- **Binary auth state** (authenticated vs public) instead of complex state management
- **Built-in auth provider integration** (Firebase, Supabase, Auth0)
- **Automatic state management integration** (Bloc, Riverpod, GetX, Provider)
- **Simplified initialization** - one call instead of multiple configuration steps

#### Q: Will I lose existing data during Phase 3 migration?
**A:** No! Phase 3 is designed to work with existing data. MyAppSyncManager handles audit fields automatically, so you don't need to manually manage sync metadata. Always backup your database before migration.

#### Q: Can I migrate gradually to Phase 3?
**A:** Yes! You can run both systems temporarily:

```dart
class HybridService {
  final bool usePhase3 = Environment.useMyAppSyncManager; // Feature flag
  
  Future<List<User>> getUsers() async {
    return usePhase3 
      ? await UserRepository().getAll()  // Phase 3 with MyAppSyncManager
      : await LegacyService().getUsers(); // Old system
  }
}
```

#### Q: What if my backend doesn't have a Phase 3 adapter?
**A:** Phase 3 uses the same adapter interface (`ISyncBackendAdapter`), so existing adapters work. However, Phase 3 adapters provide enhanced features like better auth integration and improved real-time capabilities.

### Data Model Questions

#### Q: Do I still need to add all the USM audit fields to my models in Phase 3?
**A:** No! Phase 3 simplifies this significantly. MyAppSyncManager handles audit fields automatically:

```dart
// Phase 3 - Simplified model (no manual audit fields needed)
class User implements SyncableModel {
  @override
  final String id;
  @override
  final String organizationId;
  
  final String name;
  final String email;
  
  User({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.email,
  });
  
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'organizationId': organizationId,
    'name': name,
    'email': email,
  };
  
  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    organizationId: json['organizationId'],
    name: json['name'],
    email: json['email'],
  );
}
```

#### Q: My field names use snake_case but Phase 3 requires camelCase. Do I need to rename everything?
**A:** Phase 3 backend adapters handle field mapping automatically, but you can also configure it:

```dart
// Phase 3 - Automatic field mapping in adapters
final adapter = PocketBaseSyncAdapter(
  baseUrl: 'https://your-pocketbase.com',
  fieldMappings: {
    'organizationId': 'organization_id',  // Local camelCase -> Remote snake_case
    'createdBy': 'created_by',
    'updatedBy': 'updated_by',
  },
);
```

#### Q: Can I keep my existing primary key format in Phase 3?
**A:** Yes! Phase 3 is more flexible with ID formats. Just ensure they're unique strings:

```dart
class User implements SyncableModel {
  @override
  final String id; // Can be your existing ID format
  // ... rest of model
}
```

### Sync Behavior Questions

#### Q: How does conflict resolution work in Phase 3?
**A:** Phase 3 provides simplified conflict resolution through MyAppSyncManager configuration:

```dart
// Phase 3 - Simplified conflict resolution
await MyAppSyncManager.initialize(
  backendAdapter: PocketBaseSyncAdapter(
    baseUrl: 'https://your-pocketbase.com',
    defaultConflictResolution: ConflictResolutionStrategy.timestampWins,
  ),
  publicCollections: ['public_data'],
);

// Custom conflict resolution (if needed)
MyAppSyncManager.instance.setConflictResolver((conflict) {
  if (conflict.entityName == 'users') {
    return ConflictResolution.useServer(); // Always use server for users
  }
  return ConflictResolution.useNewer(); // Timestamp wins for others
});
```

#### Q: Will Phase 3 work offline?
**A:** Yes! Phase 3 maintains the offline-first approach with enhanced capabilities:
- All operations work locally first with immediate UI responses
- Changes are automatically queued for sync when online
- Enhanced sync queue management with priority and batching
- Automatic sync when connection restored
- Better error handling and retry mechanisms

#### Q: How does real-time sync work in Phase 3?
**A:** Phase 3 provides enhanced real-time capabilities through MyAppSyncManager:

```dart
// Phase 3 - Automatic real-time updates
MyAppSyncManager.instance.authStateChanges.listen((authState) {
  if (authState == AuthState.authenticated) {
    // Real-time sync automatically enabled for authenticated collections
    print('Real-time sync active');
  }
});

// Listen to sync events
MyAppSyncManager.instance.syncEventStream.listen((event) {
  print('Sync event: ${event.type} for ${event.collection}');
});
```

#### Q: Will USM work offline?
**A:** Yes! USM is offline-first by design:
- All operations work locally first
- Changes are queued for sync when online
- Full CRUD operations available offline
- Automatic sync when connection restored

#### Q: How does real-time sync work?
**A:** USM handles real-time updates automatically:
- Subscribes to backend real-time events
- Updates local database automatically
- Notifies your app through sync event streams
- Resolves conflicts using configured strategy

### Performance Questions

#### Q: Will Phase 3 slow down my app?
**A:** Phase 3 is actually faster than previous versions:
- MyAppSyncManager optimizes sync operations automatically
- Binary auth state reduces state management overhead
- Enhanced batching and compression in backend adapters
- Intelligent sync scheduling based on auth state
- Reduced boilerplate code improves app startup time

#### Q: How much storage overhead does Phase 3 add?
**A:** Phase 3 reduces overhead compared to earlier versions:
- Automatic audit field management reduces manual data redundancy
- Enhanced compression in sync operations
- Optimized local database schema
- Smart sync metadata management
- Overall storage efficiency improvements

#### Q: Can I optimize sync for my specific use case in Phase 3?
**A:** Yes! Phase 3 provides streamlined optimization options:

```dart
// Phase 3 - Simplified performance optimization
await MyAppSyncManager.initialize(
  backendAdapter: PocketBaseSyncAdapter(
    baseUrl: 'https://your-pocketbase.com',
    connectionTimeout: Duration(seconds: 30),
    requestTimeout: Duration(seconds: 15),
    enableCompression: true,
  ),
  publicCollections: ['announcements'], // Limit public data
  autoSync: true,
  syncInterval: Duration(minutes: 5), // Optimize interval
);
```

### Backend-Specific Questions

#### Q: I'm using PocketBase. What changes do I need to make for Phase 3?
**A:** Phase 3 makes PocketBase integration much simpler:

```dart
// Phase 3 - Simple PocketBase setup
await MyAppSyncManager.initialize(
  backendAdapter: PocketBaseSyncAdapter(
    baseUrl: 'https://your-pocketbase.com',
    connectionTimeout: Duration(seconds: 30),
    requestTimeout: Duration(seconds: 15),
  ),
  publicCollections: ['announcements', 'public_posts'],
  autoSync: true,
);

// Authentication integration
await MyAppSyncManager.instance.login(
  token: 'pocketbase-auth-token',
  userId: 'user-id',
  organizationId: 'org-id',
);
```

#### Q: I'm using Firebase. How does Phase 3 improve Firebase integration?
**A:** Phase 3 provides enhanced Firebase integration with auth provider support:

```dart
// Phase 3 - Enhanced Firebase integration
await MyAppSyncManager.initialize(
  backendAdapter: FirebaseSyncAdapter(
    configuration: SyncBackendConfiguration(
      configId: 'firebase-main',
      backendType: 'firebase',
      projectId: 'your-firebase-project-id',
      environment: 'production',
    ),
  ),
  publicCollections: ['public_data'],
);

// Automatic Firebase Auth integration
FirebaseAuth.instance.authStateChanges().listen((user) {
  if (user != null) {
    FirebaseAuthIntegration.syncWithUSM(user);
  } else {
    MyAppSyncManager.instance.logout();
  }
});
```

#### Q: I'm using Supabase. What Phase 3 features are available?
**A:** Phase 3 offers comprehensive Supabase integration:

```dart
// Phase 3 - Supabase with RLS support
await MyAppSyncManager.initialize(
  backendAdapter: SupabaseSyncAdapter(
    configuration: SyncBackendConfiguration(
      configId: 'supabase-main',
      backendType: 'supabase',
      baseUrl: 'https://your-project.supabase.co',
      projectId: 'your-project-id',
      customHeaders: {
        'apikey': 'your-anon-key',
        'Authorization': 'Bearer your-anon-key',
      },
    ),
  ),
  publicCollections: ['public_announcements'],
);

// Automatic Supabase Auth integration
Supabase.instance.client.auth.onAuthStateChange.listen((data) {
  final user = data.user;
  if (user != null) {
    SupabaseAuthIntegration.syncWithUSM(user);
  } else {
    MyAppSyncManager.instance.logout();
  }
});
```

### Error Handling Questions

#### Q: What happens if sync fails in Phase 3?
**A:** Phase 3 provides enhanced error handling through MyAppSyncManager:

```dart
// Phase 3 - Enhanced error handling
MyAppSyncManager.instance.syncEventStream.listen((event) {
  switch (event.type) {
    case SyncEventType.error:
      // Automatic retry with exponential backoff
      print('Sync error: ${event.error} - Will retry automatically');
      break;
    case SyncEventType.retrySuccessful:
      print('Sync recovered successfully');
      break;
    case SyncEventType.syncComplete:
      print('Sync completed successfully');
      break;
  }
});
```

#### Q: How do I debug sync issues in Phase 3?
**A:** Phase 3 provides improved debugging capabilities:

```dart
// Phase 3 - Enhanced debugging
await MyAppSyncManager.initialize(
  backendAdapter: PocketBaseSyncAdapter(
    baseUrl: 'https://your-pocketbase.com',
    enableLogging: true, // Detailed logging
    logLevel: 'debug',
  ),
  publicCollections: ['public_data'],
);

// Monitor all sync activities
MyAppSyncManager.instance.syncEventStream.listen((event) {
  print('Sync Debug: ${event.type} - ${event.details}');
});

// Check auth state for debugging
print('Current auth state: ${MyAppSyncManager.instance.authState}');
print('Is authenticated: ${MyAppSyncManager.instance.isAuthenticated}');
if (MyAppSyncManager.instance.currentUser != null) {
  print('User: ${MyAppSyncManager.instance.currentUser!.userId}');
}
```

### Advanced Questions

#### Q: Can I customize the sync algorithm in Phase 3?
**A:** Phase 3 provides streamlined customization options:

```dart
// Phase 3 - Custom sync behavior
class CustomBackendAdapter extends PocketBaseSyncAdapter {
  CustomBackendAdapter({required String baseUrl}) : super(baseUrl: baseUrl);
  
  @override
  Future<SyncResult> performCustomSync(SyncContext context) async {
    // Your custom sync logic
    return await super.performSync(context);
  }
}

// Use custom adapter
await MyAppSyncManager.initialize(
  backendAdapter: CustomBackendAdapter(
    baseUrl: 'https://your-pocketbase.com',
  ),
);
```

#### Q: How do I handle authentication lifecycle in Phase 3?
**A:** Phase 3 provides built-in auth lifecycle management:

```dart
// Phase 3 - Automatic auth lifecycle management
final lifecycleManager = AuthLifecycleManager();
await lifecycleManager.initialize(
  sessionTimeoutDuration: Duration(hours: 8),
  refreshThreshold: Duration(minutes: 5),
  warningThreshold: Duration(minutes: 10),
);

// Automatic token refresh coordination
final coordinator = TokenRefreshCoordinator();
coordinator.initialize([
  FirebaseTokenRefreshProvider(),
  SupabaseTokenRefreshProvider(),
  Auth0TokenRefreshProvider(),
]);

lifecycleManager.startTokenRefreshCoordination();
```

#### Q: How do I integrate with state management in Phase 3?
**A:** Phase 3 provides built-in state management integration:

```dart
// Phase 3 - Riverpod integration
final authProvider = StateNotifierProvider<AuthSyncNotifier, RiverpodAuthSyncState>((ref) {
  final notifier = AuthSyncNotifier();
  notifier.initialize(); // Automatically connects to MyAppSyncManager
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

// Phase 3 - Bloc integration
class MyAppBloc extends Bloc<AppEvent, AppState> with AuthSyncBlocMixin {
  MyAppBloc() : super(AppInitial()) {
    initializeAuthSync(); // Automatically connects to MyAppSyncManager
  }
  
  @override
  Future<void> close() {
    disposeAuthSync();
    return super.close();
  }
}
```

### Troubleshooting Common Issues

#### Q: Migration fails with "MyAppSyncManager not initialized" errors
**Solution:** Ensure proper initialization order:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize MyAppSyncManager before running app
  await MyAppSyncManager.initialize(
    backendAdapter: PocketBaseSyncAdapter(
      baseUrl: 'https://your-pocketbase.com',
    ),
    publicCollections: ['public_data'],
  );
  
  runApp(MyApp());
}
```

#### Q: Auth state not updating in UI
**Solutions:**
1. Use StreamBuilder with auth state changes:

```dart
StreamBuilder<AuthState>(
  stream: MyAppSyncManager.instance.authStateChanges,
  builder: (context, snapshot) {
    final authState = snapshot.data ?? AuthState.public;
    return authState == AuthState.authenticated 
      ? HomeScreen() 
      : LoginScreen();
  },
);
```

#### Q: Real-time updates not working in Phase 3
**Solutions:**
1. Verify authentication is working
2. Check backend supports real-time subscriptions
3. Monitor sync events for debugging:

```dart
MyAppSyncManager.instance.syncEventStream.listen((event) {
  print('Sync Event: ${event.type} - ${event.collection}');
  if (event.type == SyncEventType.error) {
    print('Error: ${event.error}');
  }
});
```

#### Q: Performance issues after Phase 3 migration
**Solutions:**
1. Optimize sync interval:
```dart
await MyAppSyncManager.initialize(
  syncInterval: Duration(minutes: 5), // Less frequent
  // ... other config
);
```

2. Limit public collections:
```dart
await MyAppSyncManager.initialize(
  publicCollections: ['essential_only'], // Reduce data
  // ... other config
);
```

3. Use auth lifecycle management:
```dart
final lifecycleManager = AuthLifecycleManager();
await lifecycleManager.initialize(
  sessionTimeoutDuration: Duration(hours: 12), // Longer sessions
  refreshThreshold: Duration(minutes: 10), // More buffer
);
```

### Getting Additional Help

#### Q: Where can I get more help with migration?
**Resources:**
- **Documentation**: `/doc/guides/` and `/doc/migration/`
- **Examples**: `/doc/examples/` for code patterns
- **GitHub Issues**: For specific technical problems
- **Community**: For best practices and tips

#### Q: Can I get professional help with migration?
**A:** Check the main project README for:
- Professional services contacts
- Community support channels
- Training resources
- Consulting availability

#### Q: How do I contribute improvements to the migration process?
**A:** Contributions are welcome!
1. Fork the repository
2. Add improvements to migration tools or documentation
3. Submit a pull request
4. Share your migration experiences to help others

---

## Quick Reference

### Phase 3 Migration Checklist
- [ ] Update dependencies to include USM
- [ ] Initialize MyAppSyncManager in main()
- [ ] Update data models to implement SyncableModel interface
- [ ] Convert to local-first repository pattern (no direct backend calls)
- [ ] Set up auth provider integration (Firebase, Supabase, Auth0)
- [ ] Implement auth state management with MyAppSyncManager streams
- [ ] Configure state management integration (Bloc, Riverpod, GetX, Provider)
- [ ] Test authentication flow and sync functionality
- [ ] Deploy and monitor

### Phase 3 Essential Setup
```dart
// 1. Initialize MyAppSyncManager
await MyAppSyncManager.initialize(
  backendAdapter: PocketBaseSyncAdapter(
    baseUrl: 'https://your-pocketbase.com',
  ),
  publicCollections: ['public_data'],
  autoSync: true,
);

// 2. Handle authentication
final result = await MyAppSyncManager.instance.login(
  token: 'auth-token',
  userId: 'user-id',
  organizationId: 'org-id',
);

// 3. Listen to auth state changes
MyAppSyncManager.instance.authStateChanges.listen((authState) {
  // Update UI based on auth state
});
```

### Phase 3 Model Template
```dart
class User implements SyncableModel {
  @override
  final String id;
  @override
  final String organizationId;
  
  final String name;
  final String email;
  
  User({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.email,
  });
  
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'organizationId': organizationId,
    'name': name,
    'email': email,
  };
  
  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    organizationId: json['organizationId'],
    name: json['name'],
    email: json['email'],
  );
}
```

---

*Still have questions? Check the Phase 3 implementation guide at `/doc/guides/IMPLEMENTATION_GUIDE.md` or the Phase 3 configuration guide at `/doc/generated/configuration_guide.md` for detailed information.*
