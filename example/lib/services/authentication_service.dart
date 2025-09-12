import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/test_results_manager.dart';

/// Service that handles authentication operations for the USM example app
class AuthenticationService {
  final TestResultsManager _resultsManager;

  AuthenticationService(this._resultsManager);

  /// Gets the current Supabase client
  SupabaseClient get _client => Supabase.instance.client;

  /// Checks if user is currently authenticated
  bool get isAuthenticated => _client.auth.currentUser != null;

  /// Gets the current user
  User? get currentUser => _client.auth.currentUser;

  /// Gets the current session
  Session? get currentSession => _client.auth.currentSession;

  /// Signs in with email and password
  Future<bool> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Starting authentication with $email...');

      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      print('🔐 Auth response received: ${response.user?.id}');
      print('🔐 User email: ${response.user?.email}');
      print('🔐 User role: ${response.user?.role}');

      if (response.session?.accessToken != null) {
        print(
            '🔐 Access token: ${response.session!.accessToken.substring(0, 20)}...');
      }

      if (response.user != null) {
        _resultsManager.updateAuthenticationStatus(true);
        _resultsManager
            .updateStatus('Authenticated as ${response.user!.email}');
        _resultsManager.addSuccess(
            'Authentication', 'User authenticated: ${response.user!.email}');

        _logAuthState();
        return true;
      } else {
        _resultsManager.addFailure('Authentication', 'No user returned');
        return false;
      }
    } catch (e) {
      print('❌ Authentication error: $e');
      _resultsManager.addError('Authentication', e);
      return false;
    }
  }

  /// Signs out the current user
  Future<bool> signOut() async {
    try {
      print('🔐 Signing out...');
      await _client.auth.signOut();

      _resultsManager.updateAuthenticationStatus(false);
      _resultsManager.updateStatus('Signed out');
      _resultsManager.addSuccess('Sign Out', 'Successfully signed out');

      _logAuthState();
      return true;
    } catch (e) {
      print('❌ Sign out error: $e');
      _resultsManager.addError('Sign Out', e);
      return false;
    }
  }

  /// Signs in with the default test credentials
  Future<bool> signInWithTestCredentials() async {
    return await signInWithEmailPassword(
      email: 'admin@has.com',
      password: '123456789',
    );
  }

  /// Logs the current authentication state
  void _logAuthState() {
    final user = currentUser;
    final session = currentSession;

    print('🔐 === AUTH STATE ===');
    print('🔐 Current User: ${user?.toJson()}');
    print('🔐 Current Session: ${session?.toJson()}');
    print('🔐 Is Authenticated: ${user != null}');
    print('🔐 User ID: ${user?.id}');
    print('🔐 User Email: ${user?.email}');
    print('🔐 Session Expires: ${session?.expiresAt}');
    print('🔐 ==================');
  }

  /// Gets user information for display
  String getUserDisplayInfo() {
    final user = currentUser;
    if (user == null) return 'Not authenticated';
    return '${user.email} (${user.id})';
  }

  /// Checks if the session is still valid
  bool isSessionValid() {
    final session = currentSession;
    if (session == null) return false;

    final expiresAt = session.expiresAt;
    if (expiresAt == null) return true; // No expiry

    return DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000)
        .isAfter(DateTime.now());
  }

  /// Refreshes the current session if needed
  Future<bool> refreshSessionIfNeeded() async {
    if (!isAuthenticated || isSessionValid()) return true;

    try {
      await _client.auth.refreshSession();
      return true;
    } catch (e) {
      print('❌ Session refresh error: $e');
      return false;
    }
  }
}
