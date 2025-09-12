# Universal Sync Manager Examples

This directory contains comprehensive examples demonstrating how to use Universal Sync Manager in different scenarios and how to migrate from existing solutions.

## Example Categories

### 📚 Getting Started Examples
- [Basic Setup](./basic_setup_example.dart) - Simple USM initialization and configuration
- [First Sync](./first_sync_example.dart) - Your first sync operation with USM
- [Model Creation](./model_creation_example.dart) - Creating USM-compatible data models

### 🔄 Migration Examples  
- [PocketBase Migration](./pocketbase_migration_example.dart) - Migrate from direct PocketBase usage
- [Firebase Migration](./firebase_migration_example.dart) - Migrate from direct Firebase usage
- [Custom Backend Migration](./custom_backend_migration_example.dart) - Migrate custom sync solutions

### 🏗️ Architecture Examples
- [Repository Pattern](./repository_pattern_example.dart) - USM-compatible repository implementation
- [Multi-Backend Setup](./multi_backend_example.dart) - Using multiple backends simultaneously
- [Event-Driven Architecture](./event_driven_example.dart) - Handling USM events and notifications

### 📱 Platform Examples
- [Mobile App](./mobile_app_example.dart) - Complete mobile app with USM
- [Desktop App](./desktop_app_example.dart) - Desktop application with USM
- [Web App](./web_app_example.dart) - Web application with USM

### 🔧 Advanced Features
- [Conflict Resolution](./conflict_resolution_example.dart) - Custom conflict resolution strategies
- [Delta Sync](./delta_sync_example.dart) - Optimized incremental synchronization
- [Analytics Integration](./analytics_example.dart) - Monitoring and analytics with USM
- [Custom Adapters](./custom_adapter_example.dart) - Creating custom backend adapters

### 🧪 Testing Examples
- [Unit Testing](./unit_testing_example.dart) - Testing USM-enabled code
- [Integration Testing](./integration_testing_example.dart) - End-to-end sync testing
- [Mock Backend Testing](./mock_backend_example.dart) - Testing with mock backends

### 🏢 Business Scenarios
- [E-commerce App](./ecommerce_example.dart) - Product catalog with inventory sync
- [Task Management](./task_management_example.dart) - Collaborative task management
- [Real-time Chat](./realtime_chat_example.dart) - Real-time messaging with USM
- [Document Collaboration](./document_collaboration_example.dart) - Collaborative document editing

## How to Use These Examples

### 1. Copy and Adapt
Each example is self-contained and can be copied into your project as a starting point. Modify the code to fit your specific needs.

### 2. Step-by-Step Learning
Follow the examples in order for a complete learning path:
1. Start with Basic Setup
2. Try First Sync
3. Implement Model Creation
4. Choose appropriate Migration example
5. Explore Advanced Features

### 3. Real Project Reference
Use the Business Scenarios examples as reference for implementing similar functionality in your projects.

## Example Structure

Each example follows this structure:

```dart
// 1. Problem Statement
// What problem this example solves

// 2. Prerequisites
// What you need before running this example

// 3. Complete Code
// Full working example

// 4. Key Concepts
// Important USM concepts demonstrated

// 5. Next Steps
// What to explore after this example
```

## Running Examples

### Prerequisites
```yaml
# pubspec.yaml
dependencies:
  universal_sync_manager:
    path: ../  # Adjust path as needed
  sqflite: ^2.3.0
  sqflite_common_ffi: ^2.3.0  # For desktop
```

### Environment Setup
```dart
// Add to your main.dart before running examples
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  // Initialize FFI for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // Run example
  await runExample();
}
```

## Common Patterns

### USM Initialization Pattern
```dart
Future<UniversalSyncManager> initializeUSM() async {
  final syncManager = UniversalSyncManager();
  
  await syncManager.initialize(UniversalSyncConfig(
    projectId: 'your-project-id',
    syncMode: SyncMode.automatic,
  ));
  
  // Configure backend
  final adapter = PocketBaseSyncAdapter(baseUrl: 'your-backend-url');
  await syncManager.setBackend(adapter);
  
  // Register entities
  syncManager.registerEntity('entity_name', SyncEntityConfig(
    tableName: 'entity_name',
    requiresAuthentication: true,
  ));
  
  return syncManager;
}
```

### Model Definition Pattern
```dart
class ExampleModel with SyncableModel {
  // Business fields
  final String id;
  final String name;
  final String organizationId;
  
  // Required USM audit fields
  final String createdBy;
  final String updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final bool isDirty;
  final DateTime? lastSyncedAt;
  final int syncVersion;
  final bool isDeleted;
  
  // Constructor, copyWith, toJson, fromJson...
}
```

### Repository Pattern
```dart
class ExampleRepository {
  static const String tableName = 'example_table';
  
  Future<void> create(ExampleModel model) async {
    final db = await getDatabase();
    await db.insert(tableName, model.toJson());
    // USM automatically syncs dirty records
  }
  
  Future<List<ExampleModel>> getAll() async {
    final db = await getDatabase();
    final result = await db.query(
      tableName,
      where: 'isDeleted = 0',
      orderBy: 'updatedAt DESC',
    );
    return result.map((json) => ExampleModel.fromJson(json)).toList();
  }
}
```

## Example Difficulty Levels

### 🟢 Beginner (Basic Setup, First Sync, Model Creation)
- No prior USM knowledge required
- Basic Flutter/Dart knowledge sufficient
- 15-30 minutes per example

### 🟡 Intermediate (Repository Pattern, Migration Examples)
- Basic USM knowledge required
- Understanding of database concepts
- 30-60 minutes per example

### 🔴 Advanced (Custom Adapters, Complex Scenarios)
- Good USM knowledge required
- Advanced Flutter/Dart concepts
- 1-3 hours per example

## Contributing Examples

Want to add more examples? Follow these guidelines:

1. **Clear Problem Statement**: Start with what problem the example solves
2. **Complete Code**: Provide full, runnable examples
3. **Good Documentation**: Explain key concepts and decisions
4. **Follow Patterns**: Use consistent code structure and naming
5. **Test Your Code**: Ensure examples actually work

See [CONTRIBUTING.md](../CONTRIBUTING.md) for more details.

## Getting Help

- **Questions about examples**: Check the inline comments and documentation
- **Issues with examples**: Open a GitHub issue with "Example:" prefix
- **Request new examples**: Open a feature request describing your use case
- **General USM help**: See main documentation in `/doc/guides/`
