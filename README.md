# UnivUniversal Sync Manager is a powerful Flutter package for synchronizing data across multiple backends with built-in conflict resolution, authentication, and real-time capabilities.

## 📦 Package Status
**Version**: 0.1.0 | **Type**: Local Flutter Package | **Flutter SDK**: 3.35.2+

This package is ready for local usage in other Flutter projects via path dependencies.

## Features

- **Multi-Backend Support**: Seamlessly switch between Firebase, Supabase, PocketBase, and custom backends
- **SQLite-First Architecture**: Local-first approach with reliable sync
- **Advanced Conflict Resolution**: Intelligent merge strategies and manual resolution options
- **Real-time Synchronization**: Live updates and collaborative features
- **Comprehensive Authentication**: Support for multiple auth providers and SSO
- **Security & Compliance**: Built-in encryption, audit trails, and RBAC
- **Performance Optimized**: Efficient sync algorithms and caching strategies

## 🚀 Quick Start

### Installation
Add to your Flutter project's `pubspec.yaml`:
```yaml
dependencies:
  universal_sync_manager:
    path: ../universal_sync_manager  # Adjust path as needed
```

### Basic Usage
```dart
import 'package:universal_sync_manager/universal_sync_manager.dart';

// Configure backend
final config = SyncBackendConfiguration(
  configId: 'my-backend',
  displayName: 'My Backend',
  backendType: 'pocketbase',
  baseUrl: 'http://localhost:8090',
  projectId: 'my-project',
);

// Create adapter
final adapter = PocketBaseSyncAdapter(baseUrl: config.baseUrl);

// Start syncing
final syncService = UniversalSyncOperationService();
await syncService.initialize(adapter: adapter);
```

## 📚 Testing Documentation

### For Claude Sonnet Agents
- **[Testing Guide](TESTING_USM_PACKAGE_GUIDE.md)** - Comprehensive step-by-step instructions
- **[Testing Checklist](USM_TESTING_CHECKLIST.md)** - Quick validation checklist  
- **[Package Conversion Summary](PACKAGE_CONVERSION_SUMMARY.md)** - What was accomplished

### Validation Tools
- **validate_usm_package.dart** - Automated validation script
- **example/** - Example implementation and test app

### Quick Test Command
```bash
# Run this in your test project to validate USM package works:
dart ../universal_sync_manager/validate_usm_package.dart
```

## 📋 Universal Sync Manager (USM) Development Project

A backend-agnostic, platform-independent synchronization system for offline-first Flutter applications.

## 🚀 Overview

Universal Sync Manager (USM) is a comprehensive synchronization framework that enables offline-first operation with seamless backend synchronization for Flutter applications. It abstracts away backend-specific implementations, allowing developers to switch between different backend services (Firebase, Supabase, PocketBase, custom APIs) without changing application code.

## ✨ Key Features

- **Backend Agnostic**: Pluggable adapter system for any backend service
- **Platform Independent**: Works on iOS, Android, Web, Windows, macOS, Linux
- **Offline-First**: Full functionality without internet connection
- **Bidirectional Sync**: Changes sync from local to remote and vice versa
- **Conflict Resolution**: Configurable strategies for handling conflicting changes
- **Real-time Updates**: Subscribe to changes when online
- **Type-Safe**: Generic interfaces with strong typing
- **Performance Optimized**: Intelligent sync scheduling and batching
- **Extensible**: Plugin architecture for custom adapters and strategies

## 🏗️ Architecture

### Core Principles

1. **Separation of Concerns**:
   - **Core Sync Logic**: Independent of backend implementation
   - **Backend Adapters**: Implement backend-specific operations
   - **Platform Services**: Handle platform-specific requirements
   - **Configuration**: Externalized and customizable

2. **Consistent Data Structure**:
   - **SyncableModel**: Standard interface for all syncable entities
   - **Audit Fields**: Universal fields for tracking changes (createdAt, updatedAt, etc.)
   - **Sync Fields**: Universal fields for sync state (isDirty, syncVersion, etc.)

3. **Universal Standards**:
   - **Table Names**: Consistent across all backends
   - **Field Names**: camelCase everywhere to eliminate mapping complexity
   - **Primary Keys**: UUID-based string identifiers

### Key Components

```dart
// Core interface for backend adapters
abstract class ISyncBackendAdapter {
  Future<bool> connect(SyncBackendConfiguration config);
  Future<SyncResult> create(String collection, Map<String, dynamic> data);
  Future<SyncResult> read(String collection, String id);
  Future<SyncResult> update(String collection, String id, Map<String, dynamic> data);
  Future<SyncResult> delete(String collection, String id);
  Future<List<SyncResult>> query(String collection, SyncQuery query);
  Stream<SyncEvent> subscribe(String collection, SyncSubscriptionOptions options);
  // ... additional methods
}

// Universal Sync Manager public API
class UniversalSyncManager {
  Future<void> initialize(UniversalSyncConfig config);
  Future<void> setBackend(ISyncBackendAdapter adapter);
  
  void registerEntity<T extends SyncableModel>(String tableName, SyncEntityConfig config);
  
  Future<SyncResult> syncEntity(String tableName);
  Future<SyncResult> syncAll();
  
  Stream<SyncProgress> get syncProgressStream;
  Stream<SyncEvent> get syncEventStream;
  
  // ... additional methods
}
```

## 📋 Implementation Guidelines

### Data Model Requirements

All syncable models must:

1. **Implement SyncableModel interface**:
   ```dart
   mixin SyncableModel {
     String get id;
     String get organizationId;
     bool get isDirty;
     DateTime? get lastSyncedAt;
     int get syncVersion;
     DateTime? get updatedAt;
     bool get isDeleted;
     // ... additional sync properties
   }
   ```

2. **Include standard audit fields**:
   ```dart
   // Required in all syncable models
   String createdBy;
   String updatedBy;
   DateTime? createdAt;
   DateTime? updatedAt;
   DateTime? deletedAt;
   bool isDirty;
   DateTime? lastSyncedAt;
   int syncVersion;
   bool isDeleted;
   ```

### Database Schema

All SQLite tables must include:

```sql
CREATE TABLE IF NOT EXISTS my_table_name (
  id TEXT PRIMARY KEY,
  organizationId TEXT NOT NULL,
  
  -- Feature-specific fields (use camelCase naming)
  name TEXT NOT NULL,
  description TEXT,
  isActive INTEGER NOT NULL DEFAULT 1,
  
  -- REQUIRED AUDIT FIELDS
  createdBy TEXT NOT NULL,
  updatedBy TEXT NOT NULL, 
  createdAt TEXT,
  updatedAt TEXT,
  deletedAt TEXT,
  
  -- REQUIRED SYNC FIELDS
  isDirty INTEGER NOT NULL DEFAULT 1,
  lastSyncedAt TEXT,
  syncVersion INTEGER NOT NULL DEFAULT 0,
  isDeleted INTEGER NOT NULL DEFAULT 0
);
```

### Backend Adapters

Each backend adapter must:

1. **Implement ISyncBackendAdapter interface**
2. **Map backend-specific operations** to standardized operations
3. **Handle authentication** specific to the backend
4. **Manage subscriptions** for real-time updates
5. **Implement field conversion** if needed

## 🔧 Getting Started

### Installation

```yaml
dependencies:
  universal_sync_manager:
    path: path/to/universal_sync_manager
```

### Basic Usage

```dart
// Initialize the Universal Sync Manager
final syncManager = UniversalSyncManager();
await syncManager.initialize(
  UniversalSyncConfig(
    projectId: 'my_project',
    syncMode: SyncMode.automatic,
    syncInterval: Duration(minutes: 15),
  ),
);

// Set up the backend adapter
final pocketBaseAdapter = PocketBaseSyncAdapter(
  baseUrl: 'https://my-pocketbase.com',
);
await syncManager.setBackend(pocketBaseAdapter);

// Register entities
syncManager.registerEntity(
  'users',
  SyncEntityConfig(
    tableName: 'users',
    requiresAuthentication: true,
  ),
);

// Trigger sync
await syncManager.syncAll();

// Listen for sync progress
syncManager.syncProgressStream.listen((progress) {
  print('Sync progress: ${progress.percentage}%');
});
```

## 🧪 Testing

USM includes a comprehensive test suite:

- **Unit Tests**: Test individual components
- **Integration Tests**: Test component interactions
- **Mock Adapters**: Test sync operations without a real backend
- **Conflict Simulation**: Test various conflict scenarios
- **Network Simulation**: Test behavior under different network conditions

## 📘 Documentation

Detailed documentation is available in the docs folder:

- Architecture Overview
- Backend Adapters
- Configuration Guide
- Conflict Resolution
- Performance Optimization
- Migration Guide

## 📋 TODO

### Backend Adapters (Future Implementation)

- **Firebase/Firestore Adapter** (`usm_firebase_sync_adapter.dart`) - PLACEHOLDER CREATED
  - Full CRUD operations with Firestore collections and documents
  - Real-time subscriptions using Firestore snapshots
  - Firebase Authentication integration
  - Offline support with Firestore cache
  - Firebase Security Rules integration
  - Cloud Functions integration for server-side operations
  - Dependencies: firebase_core, cloud_firestore, firebase_auth

- **Custom API Adapter** (`usm_custom_api_sync_adapter.dart`) - PLACEHOLDER CREATED
  - Generic REST/GraphQL adapter with configurable endpoints
  - Custom authentication strategies (API keys, OAuth, JWT, etc.)
  - Flexible field mapping and data transformation
  - Real-time subscriptions via WebSocket, SSE, or polling
  - Rate limiting and retry mechanisms
  - Custom request/response interceptors
  - Plugin architecture for extending functionality
