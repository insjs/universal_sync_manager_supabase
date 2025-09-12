// Test importing USM package
import 'package:universal_sync_manager/universal_sync_manager.dart';

void main() {
  // Test creating core classes
  print('Testing USM imports...');
  
  // These should compile if imports work
  print('PocketBaseSyncAdapter: ${PocketBaseSyncAdapter}');
  print('SyncResult: ${SyncResult}');
  print('MyAppSyncManager: ${MyAppSyncManager}');
  print('AuthContext: ${AuthContext}');
  print('SyncableModel: ${SyncableModel}');
  
  print('All imports successful!');
}
