# Universal Sync Manager

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Pub Version](https://img.shields.io/pub/v/universal_sync_manager.svg)](https://pub.dev/packages/universal_sync_manager)
[![Dart SDK](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-3.10+-blue.svg)](https://flutter.dev)

A backend-agnostic, platform-independent synchronization framework for Flutter applications. Enable offline-first operation with seamless backend synchronization using a pluggable adapter architecture.

## ✨ Features

- 🔄 **Universal Backend Support** - Works with PocketBase, Supabase, Firebase, and custom APIs
- 📱 **Platform Independent** - Runs on iOS, Android, Windows, macOS, Linux, and Web
- 🔒 **Offline-First** - SQLite-based local storage with intelligent sync
- 🛡️ **Built-in Security** - Authentication, encryption, and role-based access control
- ⚡ **Real-time Sync** - Live updates with conflict resolution
- 🎯 **Type-Safe** - Full TypeScript-style type safety in Dart

## 🚀 Quick Start

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  universal_sync_manager: ^0.1.0
```

### Basic Usage

```dart
import 'package:universal_sync_manager/universal_sync_manager.dart';

// 1. Initialize with your backend
final adapter = PocketBaseSyncAdapter(
  baseUrl: 'https://your-pocketbase.com',
);

await MyAppSyncManager.initialize(
  backendAdapter: adapter,
  publicCollections: ['public_data'],
  autoSync: true,
);

// 2. Authenticate user
final loginResult = await MyAppSyncManager.instance.login(
  token: userToken,
  userId: userId,
  organizationId: organizationId,
);

// 3. Sync data
await MyAppSyncManager.instance.syncAll();
```

## 📖 Documentation

- [Getting Started](doc/README.md)
- [Configuration Guide](doc/generated/configuration_guide.md)
- [Migration Guide](doc/migration/USM_MIGRATION_GUIDE.md)
- [API Reference](doc/generated/)

## 🔌 Supported Backends

| Backend | Status | Features |
|---------|--------|----------|
| PocketBase | ✅ Full | Auth, Real-time, Files |
| Supabase | ✅ Full | Auth, RLS, Real-time |
| Firebase | 🚧 Beta | Auth, Firestore |
| Custom API | ✅ Full | REST/GraphQL |

## 📱 Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Android | ✅ Full | API 21+ |
| iOS | ✅ Full | iOS 12+ |
| Windows | ✅ Full | Windows 10+ |
| macOS | ✅ Full | macOS 10.14+ |
| Linux | ✅ Full | Ubuntu 18.04+ |
| Web | ✅ Full | Modern browsers |

## 🤝 Contributing

Contributions are welcome! Please see our [Contributing Guide](CONTRIBUTING.md).

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
