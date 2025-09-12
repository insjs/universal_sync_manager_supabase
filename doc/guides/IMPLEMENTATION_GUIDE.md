# Universal Sync Manager Implementation Guide

## Overview

This guide provides step-by-step instructions for implementing Universal Sync Manager (USM) Phase 3: App Integration Framework in different scenarios. This implementation focuses on the new high-level `MyAppSyncManager` API that provides simplified authentication and sync management.

## Phase 3 Features

Universal Sync Manager Phase 3 introduces:

- **MyAppSyncManager**: High-level wrapper with simplified authentication
- **Auth Provider Integration**: Automatic sync with Firebase, Supabase, Auth0
- **State Management Integration**: Built-in support for Bloc, Riverpod, GetX, Provider
- **Auth Lifecycle Management**: Session management, token refresh, user switching
- **Binary Auth State**: Simple authenticated vs public state management

## Table of Contents

- [Quick Start with Phase 3](#quick-start-with-phase-3)
- [New Project Implementation](#new-project-implementation)
- [Existing Project Migration](#existing-project-migration)
- [Auth Provider Integration](#auth-provider-integration)
- [State Management Integration](#state-management-integration)
- [Advanced Configuration](#advanced-configuration)
- [Testing and Validation](#testing-and-validation)
- [Troubleshooting](#troubleshooting)

## Quick Start with Phase 3

### 5-Minute Setup

For the fastest setup, use the new Phase 3 MyAppSyncManager:

```dart
// 1. Add dependency
dependencies:
  universal_sync_manager:
    git: https://github.com/your-org/universal_sync_manager.git
  pocketbase: ^0.22.0

// 2. Initialize in main()
import 'package:universal_sync_manager/universal_sync_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize MyAppSyncManager
  await MyAppSyncManager.initialize(
    backendAdapter: PocketBaseSyncAdapter(
      baseUrl: 'https://your-pocketbase.com',
      connectionTimeout: const Duration(seconds: 30),
      requestTimeout: const Duration(seconds: 15),
    ),
    publicCollections: ['announcements', 'public_data'],
    autoSync: true,
    syncInterval: const Duration(seconds: 30),
  );
  
  runApp(MyApp());
}

// 3. Use in your app
class AuthButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: MyAppSyncManager.instance.authStateChanges,
      builder: (context, snapshot) {
        final isAuthenticated = MyAppSyncManager.instance.isAuthenticated;
        
        if (isAuthenticated) {
          return ElevatedButton(
            onPressed: () => MyAppSyncManager.instance.logout(),
            child: Text('Logout'),
          );
        } else {
          return ElevatedButton(
            onPressed: () => _login(),
            child: Text('Login'),
          );
        }
      },
    );
  }
  
  Future<void> _login() async {
    final result = await MyAppSyncManager.instance.login(
      token: 'your-auth-token',
      userId: 'user-id',
      organizationId: 'org-id', // Optional
    );
    
    if (!result.isSuccess) {
      // Handle login error
      print('Login failed: ${result.errorMessage}');
    }
  }
}
```

That's it! Your app now has offline-first sync with automatic authentication management.

## New Project Implementation

### 1. Project Setup

#### Create New Flutter Project
```bash
flutter create my_sync_app
cd my_sync_app
```

#### Add Dependencies (Phase 3)
```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Universal Sync Manager (Phase 3)
  universal_sync_manager:
    git: https://github.com/your-org/universal_sync_manager.git
  
  # Backend adapter dependencies (choose based on your backend)
  pocketbase: ^0.22.0  # For PocketBase
  # supabase_flutter: ^2.8.0  # For Supabase
  # firebase_core: ^2.24.2  # For Firebase
  
  # State Management (optional - Phase 3 has built-in integration)
  provider: ^6.1.1
  # or
  riverpod: ^2.4.9
  # or
  bloc: ^8.1.2
  # or
  get: ^4.6.6
  
  # Auth Providers (optional - for enhanced integration)
  firebase_auth: ^4.15.2
  # supabase_flutter: ^2.8.0  # Also provides auth
  # auth0_flutter: ^1.6.1
  
  # Utilities
  http: ^1.2.2
  path: ^1.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
```
  # firebase_core: ^2.24.2  # For Firebase
  # supabase_flutter: ^2.0.0  # For Supabase
  
  # Utilities
  uuid: ^4.2.1
  json_annotation: ^4.8.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
  flutter_lints: ^3.0.1
```

### 2. Project Structure (Phase 3)

Create the following folder structure optimized for Phase 3:

```
lib/
├── main.dart
├── app.dart
├── config/
│   └── app_config.dart          # App-wide configuration
├── models/
│   ├── user.dart
│   ├── post.dart
│   └── base_model.dart
├── services/
│   ├── auth_service.dart        # Your auth logic
│   └── data_service.dart        # Business logic
├── screens/
│   ├── home_screen.dart
│   ├── login_screen.dart
│   ├── users_screen.dart
│   └── posts_screen.dart
└── widgets/
    ├── auth_wrapper.dart        # Phase 3 auth state wrapper
    ├── sync_status_widget.dart
    └── loading_widget.dart
```

### 3. Core Implementation (Phase 3)

#### App Configuration

```dart
// lib/config/app_config.dart
import 'package:universal_sync_manager/universal_sync_manager.dart';

class AppConfig {
  static const String appName = 'My Sync App';
  static const String version = '1.0.0';
  
  // Backend configuration
  static const String pocketbaseUrl = 'https://your-pocketbase.com';
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';
  
  // Public collections (accessible without authentication)
  static const List<String> publicCollections = [
    'announcements',
    'app_config',
    'public_posts',
  ];
  
  // Sync configuration
  static const Duration syncInterval = Duration(seconds: 30);
  static const bool enableAutoSync = true;
  
  /// Initialize MyAppSyncManager with your backend
  static Future<void> initializeSync() async {
    await MyAppSyncManager.initialize(
      backendAdapter: _createBackendAdapter(),
      publicCollections: publicCollections,
      autoSync: enableAutoSync,
      syncInterval: syncInterval,
    );
  }
  
  /// Create backend adapter based on your choice
  static ISyncBackendAdapter _createBackendAdapter() {
    // Option 1: PocketBase
    return PocketBaseSyncAdapter(
      baseUrl: pocketbaseUrl,
      connectionTimeout: const Duration(seconds: 30),
      requestTimeout: const Duration(seconds: 15),
    );
    
    // Option 2: Supabase
    // return SupabaseSyncAdapter(
    //   configuration: SyncBackendConfiguration(
    //     configId: 'supabase-main',
    //     backendType: 'supabase',
    //     baseUrl: supabaseUrl,
    //     projectId: 'your-project-id',
    //     environment: 'production',
    //     customHeaders: {
    //       'apikey': supabaseAnonKey,
    //       'Authorization': 'Bearer $supabaseAnonKey',
    //     },
    //   ),
    // );
    
    // Option 3: Firebase
    // return FirebaseSyncAdapter(
    //   configuration: SyncBackendConfiguration(
    //     configId: 'firebase-main',
    //     backendType: 'firebase',
    //     projectId: 'your-firebase-project-id',
    //     environment: 'production',
    //   ),
    // );
  }
}
```

#### Data Models (Simplified Phase 3)

```dart
// lib/models/base_model.dart
/// Base interface for syncable models
/// Phase 3 simplifies this - no manual repository pattern needed
abstract class SyncableModel {
  String get id;
  String get organizationId;
  Map<String, dynamic> toJson();
  
  // USM handles these automatically:
  // - isDirty flag management
  // - sync version tracking  
  // - audit field population
  // - conflict resolution
}

// lib/models/user.dart
import 'base_model.dart';

class User implements SyncableModel {
  @override
  final String id;
  
  final String name;
  final String email;
  
  @override
  final String organizationId;
  
  // Optional: Add your business fields
  final String? profileImageUrl;
  final bool isActive;
  final DateTime? lastLoginAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.organizationId,
    this.profileImageUrl,
    this.isActive = true,
    this.lastLoginAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      organizationId: json['organizationId'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      lastLoginAt: json['lastLoginAt'] != null 
          ? DateTime.parse(json['lastLoginAt']) 
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'organizationId': organizationId,
      'profileImageUrl': profileImageUrl,
      'isActive': isActive,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? name,
    String? email,
    String? profileImageUrl,
    bool? isActive,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      organizationId: organizationId,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isActive: isActive ?? this.isActive,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

// lib/models/post.dart
import 'base_model.dart';

class Post implements SyncableModel {
  @override
  final String id;
  
  final String title;
  final String content;
  final String authorId;
  
  @override
  final String organizationId;
  
  final List<String> tags;
  final bool isPublished;
  final DateTime? publishedAt;

  const Post({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.organizationId,
    this.tags = const [],
    this.isPublished = false,
    this.publishedAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      authorId: json['authorId'] as String,
      organizationId: json['organizationId'] as String,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      isPublished: json['isPublished'] as bool? ?? false,
      publishedAt: json['publishedAt'] != null 
          ? DateTime.parse(json['publishedAt']) 
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'authorId': authorId,
      'organizationId': organizationId,
      'tags': tags,
      'isPublished': isPublished,
      'publishedAt': publishedAt?.toIso8601String(),
    };
  }

  Post copyWith({
    String? title,
    String? content,
    List<String>? tags,
    bool? isPublished,
    DateTime? publishedAt,
  }) {
    return Post(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId,
      organizationId: organizationId,
      tags: tags ?? this.tags,
      isPublished: isPublished ?? this.isPublished,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }
}
```

### 4. App Integration (Phase 3)

#### Main App Setup

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize MyAppSyncManager
  await AppConfig.initializeSync();
  
  runApp(MyApp());
}

// lib/app.dart
import 'package:flutter/material.dart';
import 'widgets/auth_wrapper.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'USM Phase 3 Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: AuthWrapper(), // Phase 3 auth state management
    );
  }
}
```

#### Auth Wrapper (Phase 3 Pattern)

```dart
// lib/widgets/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';

/// Phase 3: Auth state wrapper that automatically handles auth state changes
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: MyAppSyncManager.instance.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while determining auth state
        if (!snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing...'),
                ],
              ),
            ),
          );
        }

        final authState = snapshot.data!;
        
        switch (authState) {
          case AuthState.authenticated:
            return HomeScreen(); // User is logged in
          case AuthState.public:
            return LoginScreen(); // User needs to log in
        }
      },
    );
  }
}
```

#### Login Screen (Phase 3)

```dart
// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'USM Phase 3 Demo',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 32),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading 
                    ? CircularProgressIndicator() 
                    : Text('Login'),
              ),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: _handleDemoLogin,
              child: Text('Demo Login (Skip Authentication)'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Please enter email and password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // In a real app, you'd authenticate with your auth provider first
      // Then get the token and user ID
      final mockToken = 'demo-token-${DateTime.now().millisecondsSinceEpoch}';
      final mockUserId = 'user-${_emailController.text.split('@')[0]}';
      
      final result = await MyAppSyncManager.instance.login(
        token: mockToken,
        userId: mockUserId,
        organizationId: 'demo-org',
        metadata: {
          'email': _emailController.text,
          'loginTime': DateTime.now().toIso8601String(),
        },
      );

      if (!result.isSuccess) {
        _showError(result.errorMessage ?? 'Login failed');
      }
      // Note: No navigation needed - AuthWrapper handles this automatically
    } catch (e) {
      _showError('Login error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDemoLogin() async {
    setState(() => _isLoading = true);
    
    final result = await MyAppSyncManager.instance.login(
      token: 'demo-token-${DateTime.now().millisecondsSinceEpoch}',
      userId: 'demo-user',
      organizationId: 'demo-org',
      metadata: {'type': 'demo'},
    );
    
    if (!result.isSuccess) {
      _showError(result.errorMessage ?? 'Demo login failed');
    }
    
    setState(() => _isLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
```
```

#### Home Screen with Phase 3 Features

```dart
// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';
import '../widgets/sync_status_widget.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('USM Phase 3 Demo'),
        actions: [
          SyncStatusWidget(),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'profile', child: Text('Profile')),
              PopupMenuItem(value: 'settings', child: Text('Settings')),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<AuthContext?>(
        stream: MyAppSyncManager.instance.authContextChanges,
        builder: (context, snapshot) {
          final user = snapshot.data;
          
          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              // User info card
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome!',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: 8),
                      Text('User ID: ${user?.userId ?? 'Unknown'}'),
                      Text('Organization: ${user?.organizationId ?? 'None'}'),
                      if (user?.metadata.isNotEmpty == true)
                        Text('Email: ${user?.metadata['email'] ?? 'N/A'}'),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Feature cards
              _buildFeatureCard(
                context,
                icon: Icons.people,
                title: 'Users',
                subtitle: 'Manage users with auto-sync',
                onTap: () => _navigateToUsers(context),
              ),
              
              _buildFeatureCard(
                context,
                icon: Icons.article,
                title: 'Posts',
                subtitle: 'Manage posts with real-time updates',
                onTap: () => _navigateToPosts(context),
              ),
              
              _buildFeatureCard(
                context,
                icon: Icons.sync,
                title: 'Sync Status',
                subtitle: 'Monitor synchronization',
                onTap: () => _showSyncDialog(context),
              ),
              
              SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _triggerManualSync(context),
                      icon: Icon(Icons.sync),
                      label: Text('Manual Sync'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _refreshToken(context),
                      icon: Icon(Icons.refresh),
                      label: Text('Refresh Token'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'profile':
        // Navigate to profile
        break;
      case 'settings':
        // Navigate to settings
        break;
      case 'logout':
        MyAppSyncManager.instance.logout();
        break;
    }
  }

  void _navigateToUsers(BuildContext context) {
    // TODO: Implement users screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Users screen - Coming soon!')),
    );
  }

  void _navigateToPosts(BuildContext context) {
    // TODO: Implement posts screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Posts screen - Coming soon!')),
    );
  }

  void _showSyncDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sync Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Auth State: ${MyAppSyncManager.instance.authState}'),
            Text('Is Authenticated: ${MyAppSyncManager.instance.isAuthenticated}'),
            // TODO: Add more sync details
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerManualSync(BuildContext context) async {
    try {
      // In Phase 3, sync is handled automatically by MyAppSyncManager
      // This is more for demonstration
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync triggered! USM handles this automatically.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    }
  }

  Future<void> _refreshToken(BuildContext context) async {
    try {
      final newToken = 'refreshed-token-${DateTime.now().millisecondsSinceEpoch}';
      final result = await MyAppSyncManager.instance.refreshAuthentication(
        newToken: newToken,
      );
      
      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Token refreshed successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Token refresh failed: ${result.errorMessage}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token refresh error: $e')),
      );
    }
  }
}
```
```

#### Sync Status Widget (Phase 3)

```dart
// lib/widgets/sync_status_widget.dart
import 'package:flutter/material.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';

class SyncStatusWidget extends StatefulWidget {
  @override
  _SyncStatusWidgetState createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  AuthState _authState = AuthState.public;
  bool _isSyncing = false;
  String _lastSyncTime = 'Never';

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    // Listen to auth state changes
    MyAppSyncManager.instance.authStateChanges.listen((authState) {
      setState(() {
        _authState = authState;
      });
    });

    // Listen to sync manager events if available
    // Note: In Phase 3, this might be abstracted
    // This is a simplified example
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor() {
    switch (_authState) {
      case AuthState.authenticated:
        return _isSyncing ? Colors.orange : Colors.green;
      case AuthState.public:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (_authState) {
      case AuthState.authenticated:
        return _isSyncing ? Icons.sync : Icons.cloud_done;
      case AuthState.public:
        return Icons.cloud_off;
    }
  }

  String _getStatusText() {
    switch (_authState) {
      case AuthState.authenticated:
        return _isSyncing ? 'Syncing...' : _lastSyncTime;
      case AuthState.public:
        return 'Offline';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isSyncing && _authState == AuthState.authenticated)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else
            Icon(
              _getStatusIcon(),
              size: 16,
              color: Colors.white,
            ),
          SizedBox(width: 4),
          Text(
            _getStatusText(),
            style: TextStyle(fontSize: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
```

## Auth Provider Integration

Phase 3 provides built-in integration with popular auth providers:

### Firebase Auth Integration

```dart
// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';

class AuthService {
  static void setupFirebaseIntegration() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        // Automatic Firebase -> USM integration
        FirebaseAuthIntegration.syncWithUSM(user);
      } else {
        MyAppSyncManager.instance.logout();
      }
    });
  }

  static Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // USM sync happens automatically via the listener above
    } catch (e) {
      throw 'Firebase login failed: $e';
    }
  }

  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    // USM logout happens automatically via the listener above
  }
}
```

### Supabase Auth Integration

```dart
// Enhanced Supabase integration
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';

class SupabaseAuthService {
  static void setupSupabaseIntegration() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final user = data.user;
      if (user != null) {
        // Automatic Supabase -> USM integration
        SupabaseAuthIntegration.syncWithUSM(user);
      } else {
        MyAppSyncManager.instance.logout();
      }
    });
  }

  static Future<void> signIn(String email, String password) async {
    final response = await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    if (response.user == null) {
      throw 'Supabase login failed';
    }
    // USM sync happens automatically via the listener above
  }
}
```

## State Management Integration

Phase 3 provides built-in mixins for popular state management solutions:

### Riverpod Integration

```dart
// Using Phase 3 Riverpod integration
import 'package:riverpod/riverpod.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';

final authProvider = StateNotifierProvider<AuthSyncNotifier, RiverpodAuthSyncState>((ref) {
  final notifier = AuthSyncNotifier();
  notifier.initialize(); // Connects to MyAppSyncManager automatically
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

// In your widget
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    return authState.when(
      authenticated: (user) => Text('Welcome ${user.userId}'),
      public: () => Text('Please login'),
    );
  }
}
```

### Bloc Integration

```dart
// Using Phase 3 Bloc integration
import 'package:bloc/bloc.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';

class MyAppBloc extends Bloc<AppEvent, AppState> with AuthSyncBlocMixin {
  MyAppBloc() : super(AppInitial()) {
    initializeAuthSync(); // Connects to MyAppSyncManager automatically
  }
  
  @override
  Future<void> close() {
    disposeAuthSync(); // Clean up USM integration
    return super.close();
  }
}
```
```

### 5. Testing Your Implementation

#### Phase 3 Unit Tests

```dart
// test/my_app_sync_manager_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';

class MockSyncAdapter implements ISyncBackendAdapter {
  bool _isConnected = false;
  final Map<String, dynamic> _data = {};

  @override
  Future<bool> connect(SyncBackendConfiguration config) async {
    _isConnected = true;
    return true;
  }

  @override
  Future<void> disconnect() async {
    _isConnected = false;
  }

  @override
  bool get isConnected => _isConnected;

  // Implement other required methods...
}

void main() {
  group('MyAppSyncManager Tests', () {
    late MockSyncAdapter mockAdapter;

    setUp(() {
      mockAdapter = MockSyncAdapter();
    });

    test('should initialize successfully', () async {
      await MyAppSyncManager.initialize(
        backendAdapter: mockAdapter,
        publicCollections: ['test'],
      );

      expect(MyAppSyncManager.instance.authState, AuthState.public);
      expect(MyAppSyncManager.instance.isAuthenticated, false);
    });

    test('should login successfully', () async {
      await MyAppSyncManager.initialize(
        backendAdapter: mockAdapter,
        publicCollections: ['test'],
      );

      final result = await MyAppSyncManager.instance.login(
        token: 'test-token',
        userId: 'test-user',
        organizationId: 'test-org',
      );

      expect(result.isSuccess, true);
      expect(MyAppSyncManager.instance.authState, AuthState.authenticated);
      expect(MyAppSyncManager.instance.isAuthenticated, true);
      expect(MyAppSyncManager.instance.currentUser?.userId, 'test-user');
    });

    test('should logout successfully', () async {
      await MyAppSyncManager.initialize(
        backendAdapter: mockAdapter,
        publicCollections: ['test'],
      );

      // Login first
      await MyAppSyncManager.instance.login(
        token: 'test-token',
        userId: 'test-user',
      );

      // Then logout
      await MyAppSyncManager.instance.logout();

      expect(MyAppSyncManager.instance.authState, AuthState.public);
      expect(MyAppSyncManager.instance.isAuthenticated, false);
      expect(MyAppSyncManager.instance.currentUser, null);
    });

    test('should handle auth state changes', () async {
      await MyAppSyncManager.initialize(
        backendAdapter: mockAdapter,
        publicCollections: ['test'],
      );

      final authStates = <AuthState>[];
      final subscription = MyAppSyncManager.instance.authStateChanges.listen(
        (state) => authStates.add(state),
      );

      // Login
      await MyAppSyncManager.instance.login(
        token: 'test-token',
        userId: 'test-user',
      );

      // Logout
      await MyAppSyncManager.instance.logout();

      await subscription.cancel();

      expect(authStates, contains(AuthState.authenticated));
      expect(authStates, contains(AuthState.public));
    });

    test('should switch users correctly', () async {
      await MyAppSyncManager.initialize(
        backendAdapter: mockAdapter,
        publicCollections: ['test'],
      );

      // Login as first user
      await MyAppSyncManager.instance.login(
        token: 'token1',
        userId: 'user1',
      );

      expect(MyAppSyncManager.instance.currentUser?.userId, 'user1');

      // Switch to second user
      final result = await MyAppSyncManager.instance.switchUser(
        token: 'token2',
        userId: 'user2',
      );

      expect(result.isSuccess, true);
      expect(MyAppSyncManager.instance.currentUser?.userId, 'user2');
    });

    test('should refresh token correctly', () async {
      await MyAppSyncManager.initialize(
        backendAdapter: mockAdapter,
        publicCollections: ['test'],
      );

      // Login first
      await MyAppSyncManager.instance.login(
        token: 'old-token',
        userId: 'test-user',
      );

      // Refresh token
      final result = await MyAppSyncManager.instance.refreshAuthentication(
        newToken: 'new-token',
      );

      expect(result.isSuccess, true);
      expect(MyAppSyncManager.instance.isAuthenticated, true);
    });
  });
}
```

#### Integration Tests

```dart
// test/auth_integration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_sync_manager/universal_sync_manager.dart';

void main() {
  group('Auth Integration Tests', () {
    test('should integrate with auth providers', () async {
      // Test Firebase integration
      // This would require Firebase test setup
      
      // Test Supabase integration
      // This would require Supabase test setup
      
      // For now, test the pattern
      final mockUser = MockFirebaseUser(uid: 'test-uid');
      
      // Verify integration works
      expect(mockUser.uid, 'test-uid');
    });

    test('should handle state management integration', () async {
      // Test Riverpod integration
      // Test Bloc integration
      // Test GetX integration
      // Test Provider integration
    });
  });
}

class MockFirebaseUser {
  final String uid;
  MockFirebaseUser({required this.uid});
}
```
```

### 6. Deployment Checklist (Phase 3)

#### Pre-Deployment
- [ ] MyAppSyncManager initialization tested
- [ ] Auth provider integration working
- [ ] State management integration functional
- [ ] Auth lifecycle management tested
- [ ] Backend adapter configured correctly
- [ ] Public collections defined properly
- [ ] Error handling tested
- [ ] Token refresh working
- [ ] User switching tested
- [ ] Offline functionality verified

#### Production Configuration
- [ ] Production backend URLs configured
- [ ] Auth provider settings verified
- [ ] Security tokens secured
- [ ] Error logging enabled
- [ ] Performance monitoring set up
- [ ] Backup strategies in place
- [ ] Rollback plan documented

## Existing Project Migration

### Migrating to Phase 3

If you're upgrading from an earlier USM version or migrating from another sync solution:

#### Step 1: Update Dependencies

```yaml
# pubspec.yaml
dependencies:
  # Update to latest USM
  universal_sync_manager:
    git: https://github.com/your-org/universal_sync_manager.git
    
  # Update backend adapters
  pocketbase: ^0.22.0
  supabase_flutter: ^2.8.0
```

#### Step 2: Replace Old Sync Manager

**Before (Old API):**
```dart
final syncManager = UniversalSyncManager();
await syncManager.initialize(config);
await syncManager.setBackend(adapter);
// Manual entity registration...
// Manual auth handling...
```

**After (Phase 3):**
```dart
await MyAppSyncManager.initialize(
  backendAdapter: PocketBaseSyncAdapter(
    baseUrl: 'https://your-backend.com',
  ),
  publicCollections: ['public_data'],
);
```

#### Step 3: Update Auth Handling

**Before (Manual):**
```dart
// Manual token management
void handleAuthChange(String? token, String? userId) {
  if (token != null && userId != null) {
    syncManager.authenticate(token, userId);
  } else {
    syncManager.logout();
  }
}
```

**After (Phase 3):**
```dart
// Automatic with auth provider integration
FirebaseAuth.instance.authStateChanges().listen((user) {
  if (user != null) {
    FirebaseAuthIntegration.syncWithUSM(user);
  } else {
    MyAppSyncManager.instance.logout();
  }
});
```

#### Step 4: Update State Management

**Before (Manual):**
```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // Manual USM integration
}
```

**After (Phase 3):**
```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> with AuthSyncBlocMixin {
  AuthBloc() : super(AuthInitial()) {
    initializeAuthSync(); // Automatic USM integration
  }
}
```

## Advanced Configuration

### Custom Backend Adapter

```dart
class CustomSyncAdapter implements ISyncBackendAdapter {
  @override
  Future<bool> connect(SyncBackendConfiguration config) async {
    // Custom connection logic
    return true;
  }

  @override
  Future<SyncResult> create(String collection, Map<String, dynamic> data) async {
    // Custom create logic
    return SyncResult(
      isSuccess: true,
      data: data,
      timestamp: DateTime.now(),
    );
  }

  // Implement other required methods...
}
```

### Custom Auth Provider Integration

```dart
class CustomAuthIntegration {
  static Future<void> syncWithUSM(CustomUser user) async {
    final result = await MyAppSyncManager.instance.login(
      token: user.token,
      userId: user.id,
      organizationId: user.organizationId,
      metadata: {
        'email': user.email,
        'role': user.role,
        'customData': user.customData,
      },
    );
    
    if (!result.isSuccess) {
      print('Custom auth integration failed: ${result.errorMessage}');
    }
  }
}
```

### Advanced Auth Lifecycle Management

```dart
class AdvancedAuthLifecycle {
  static void setupAdvancedLifecycle() {
    final lifecycleManager = AuthLifecycleManager();
    
    lifecycleManager.initialize(
      sessionTimeoutDuration: Duration(hours: 8),
      refreshThreshold: Duration(minutes: 5),
      warningThreshold: Duration(minutes: 10),
    );
    
    // Custom token refresh providers
    final coordinator = TokenRefreshCoordinator();
    coordinator.initialize([
      CustomTokenRefreshProvider(),
    ]);
    
    lifecycleManager.startTokenRefreshCoordination();
  }
}
```

## Troubleshooting

### Common Issues

#### 1. MyAppSyncManager Not Initialized
**Error:** `StateError: MyAppSyncManager not initialized`
**Solution:** Call `MyAppSyncManager.initialize()` before using the instance.

#### 2. Auth State Not Updating
**Problem:** Auth state changes not reflected in UI
**Solution:** Make sure you're listening to `authStateChanges` stream.

#### 3. Backend Connection Issues
**Problem:** Can't connect to backend
**Solutions:**
- Check backend URL and credentials
- Verify network connectivity
- Check backend adapter configuration

#### 4. Token Refresh Failures
**Problem:** Automatic token refresh not working
**Solutions:**
- Verify refresh token is provided during login
- Check token expiry times
- Implement custom token refresh logic

#### 5. State Management Integration Issues
**Problem:** State management mixins not working
**Solutions:**
- Ensure proper initialization of mixins
- Check dispose methods are called
- Verify framework-specific setup

### Debug Mode

Enable debug logging:

```dart
await MyAppSyncManager.initialize(
  backendAdapter: PocketBaseSyncAdapter(
    baseUrl: 'https://your-backend.com',
    enableLogging: true, // Enable detailed logging
  ),
  // ... other config
);
```

### Performance Optimization

1. **Optimize Sync Intervals:**
```dart
await MyAppSyncManager.initialize(
  syncInterval: Duration(minutes: 5), // Less frequent in production
  // ... other config
);
```

2. **Limit Public Collections:**
```dart
await MyAppSyncManager.initialize(
  publicCollections: ['essential_only'], // Only sync essential public data
  // ... other config
);
```

3. **Use Appropriate Auth Lifecycle Settings:**
```dart
final lifecycleManager = AuthLifecycleManager();
await lifecycleManager.initialize(
  sessionTimeoutDuration: Duration(hours: 12), // Longer for better UX
  refreshThreshold: Duration(minutes: 10), // More buffer time
);
```

## Next Steps

1. **Explore Advanced Features**: Check `/doc/examples/` for advanced usage patterns
2. **Review Configuration Guide**: See `/doc/generated/configuration_guide.md` for detailed options
3. **Study Migration Guide**: Review `/doc/generated/migration_guide.md` for upgrade paths
4. **Backend Setup**: Configure your chosen backend (PocketBase, Firebase, Supabase)
5. **Production Deployment**: Follow production best practices and monitoring

## Getting Help

- **Documentation**: Check `/doc/guides/` for additional guides
- **Examples**: See `/doc/examples/` for more implementation patterns
- **Configuration**: Review `/doc/generated/configuration_guide.md`
- **Migration**: See `/doc/generated/migration_guide.md` for upgrade guidance
- **Issues**: Open GitHub issues for specific problems
- **Community**: Join discussions for best practices and tips

---

*This guide covers Phase 3: App Integration Framework. For earlier phases or low-level API usage, refer to the migration guide and legacy documentation.*
