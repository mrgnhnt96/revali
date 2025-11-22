---
title: Storage
description: Persist data between client sessions
sidebar_position: 2
---

# Storage

Revali Client provides a flexible storage system for persisting data between sessions. This is essential for maintaining user authentication, storing preferences, and managing cookies automatically.

## Overview

By default, Revali Client uses **in-memory storage** (`SessionStorage`), which means data is lost when the app closes or restarts. For production applications, you'll want to implement persistent storage using packages like `shared_preferences` or `hive`.

**Key features:**

- Automatic cookie management
- Simple key-value interface
- Pluggable storage backends
- Session and persistent storage options
- Type-safe value retrieval

---

## Understanding Storage Types

### Session Storage (Default)

Session storage keeps data in memory only during the app's lifetime.

**Characteristics:**

- Data is cleared when the app restarts
- Fast access (no disk I/O)
- Good for temporary data
- Default implementation

**Use cases:**

- Temporary cache
- Development and testing
- Non-sensitive data
- Session-only state

### Persistent Storage

Persistent storage saves data to disk, surviving app restarts.

**Characteristics:**

- Data persists across app launches
- Requires disk I/O
- Good for long-term data
- Requires implementation

**Use cases:**

- Authentication tokens
- User preferences
- Offline data
- Long-term sessions

---

## Cookie Management

Revali Client automatically manages HTTP cookies for you, storing them in the provided storage implementation and including them in subsequent requests.

### How Cookies Work

#### 1. Server Sets Cookie

When the server sends a `Set-Cookie` header in the response:

```http
HTTP/1.1 200 OK
Set-Cookie: sessionId=abc123; Path=/; HttpOnly
Set-Cookie: theme=dark; Path=/
```

Revali Client automatically:

- Parses the cookies
- Stores them using your `Storage` implementation
- Makes them available for future requests

#### 2. Client Sends Cookie

On subsequent requests, cookies are automatically included:

```http
GET /api/user HTTP/1.1
Cookie: sessionId=abc123; theme=dark
```

**You don't need to manually handle cookie headers** — Revali Client does this automatically!

:::tip
Learn more about server-side cookies in the [Revali Server Cookie Guide][revali-server-cookies].
:::

---

## The Storage Interface

The `Storage` interface defines five methods for managing key-value data:

```dart
abstract interface class Storage {
  /// Retrieve a value by key
  Future<Object?> operator [](String key);

  /// Save a single key-value pair
  Future<void> save(String key, Object? value);

  /// Save multiple key-value pairs at once
  Future<void> saveAll(Map<String, Object?> values);

  /// Remove a specific key
  Future<void> remove(String key);

  /// Clear all stored data
  Future<void> clear();
}
```

### Method Details

#### `operator []` - Get Value

Retrieves a value for the given key.

```dart
final value = await storage['sessionId'];
print(value); // Output: abc123
```

**Returns:** The stored value or `null` if not found.

#### `save` - Save Value

Stores a key-value pair.

```dart
await storage.save('userId', '12345');
await storage.save('theme', 'dark');
```

**Parameters:**

- `key`: The storage key (String)
- `value`: The value to store (Object?, nullable)

#### `saveAll` - Batch Save

Saves multiple key-value pairs efficiently.

```dart
await storage.saveAll({
  'userId': '12345',
  'username': 'alice',
  'theme': 'dark',
});
```

**Use case:** Storing multiple cookies at once (used internally by Revali Client).

#### `remove` - Delete Value

Removes a specific key from storage.

```dart
await storage.remove('sessionId');
```

**Use case:** Logging out, clearing specific data.

#### `clear` - Clear All

Removes all data from storage.

```dart
await storage.clear();
```

**Use case:** Complete logout, reset app state.

---

## Implementing Custom Storage

### Using SharedPreferences (Flutter)

The most common persistent storage for Flutter apps:

```dart
import 'package:revali_client/revali_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesStorage implements Storage {
  SharedPreferencesStorage(this._prefs);

  final SharedPreferences _prefs;

  static Future<SharedPreferencesStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesStorage(prefs);
  }

  @override
  Future<Object?> operator [](String key) async {
    return _prefs.get(key);
  }

  @override
  Future<void> save(String key, Object? value) async {
    if (value == null) {
      await _prefs.remove(key);
      return;
    }

    switch (value) {
      case String():
        await _prefs.setString(key, value);
      case int():
        await _prefs.setInt(key, value);
      case double():
        await _prefs.setDouble(key, value);
      case bool():
        await _prefs.setBool(key, value);
      case List<String>():
        await _prefs.setStringList(key, value);
      default:
        // For complex types, store as JSON string
        await _prefs.setString(key, value.toString());
    }
  }

  @override
  Future<void> saveAll(Map<String, Object?> values) async {
    for (final entry in values.entries) {
      await save(entry.key, entry.value);
    }
  }

  @override
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  @override
  Future<void> clear() async {
    await _prefs.clear();
  }
}
```

**Usage:**

```dart
void main() async {
  // Initialize storage
  final storage = await SharedPreferencesStorage.create();

  // Create client with persistent storage
  final server = Server(storage: storage);

  // Cookies and data now persist across app restarts!
  await server.auth.login(email: 'user@example.com', password: 'password');
}
```

### Using Hive (Flutter/Dart)

For high-performance persistent storage:

```dart
import 'package:revali_client/revali_client.dart';
import 'package:hive/hive.dart';

class HiveStorage implements Storage {
  HiveStorage(this._box);

  final Box _box;

  static Future<HiveStorage> create() async {
    await Hive.initFlutter();
    final box = await Hive.openBox('revali_storage');
    return HiveStorage(box);
  }

  @override
  Future<Object?> operator [](String key) async {
    return _box.get(key);
  }

  @override
  Future<void> save(String key, Object? value) async {
    if (value == null) {
      await _box.delete(key);
    } else {
      await _box.put(key, value);
    }
  }

  @override
  Future<void> saveAll(Map<String, Object?> values) async {
    await _box.putAll(values);
  }

  @override
  Future<void> remove(String key) async {
    await _box.delete(key);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }
}
```

**Usage:**

```dart
void main() async {
  final storage = await HiveStorage.create();
  final server = Server(storage: storage);
}
```

### Using Web Storage (Web Apps)

For Dart web applications using `web` package:

```dart
import 'dart:convert';
import 'package:revali_client/revali_client.dart';
import 'package:web/web.dart' as web;

class WebStorage implements Storage {
  const WebStorage();

  web.Storage get _localStorage => web.window.localStorage;

  @override
  Future<Object?> operator [](String key) async {
    final value = _localStorage.getItem(key);
    if (value == null) return null;

    // Try to decode JSON, fallback to string
    try {
      return jsonDecode(value);
    } catch (_) {
      return value;
    }
  }

  @override
  Future<void> save(String key, Object? value) async {
    if (value == null) {
      _localStorage.removeItem(key);
      return;
    }

    final encoded = switch (value) {
      String() => value,
      _ => jsonEncode(value),
    };

    _localStorage.setItem(key, encoded);
  }

  @override
  Future<void> saveAll(Map<String, Object?> values) async {
    for (final entry in values.entries) {
      await save(entry.key, entry.value);
    }
  }

  @override
  Future<void> remove(String key) async {
    _localStorage.removeItem(key);
  }

  @override
  Future<void> clear() async {
    _localStorage.clear();
  }
}
```

---

## What's Next?

Now that you understand storage, explore these related topics:

- **[HTTP Interceptors](/constructs/revali_client/getting-started/http-interceptors)** - Add authentication headers
- **[Return Types](/constructs/revali_client/getting-started/return-types)** - Handle custom data types
- **[Generated Code](/constructs/revali_client/generated-code)** - Understand the client structure
- **[get_it Integration](/constructs/revali_client/integrations/get_it)** - Use with dependency injection

[revali-server-cookies]: ../../revali_server/response/cookies.md
