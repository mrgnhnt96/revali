---
title: Storage
description: Persist data between client sessions
sidebar_position: 2
---

# Storage

Revali Client supports persisting data between sessions, making it easy to store user authentication tokens, preferences, and other important values that need to survive app restarts.

By default, Revali Client uses in-memory storage. This means any data saved will be lost once the app is closed or restarted. To persist data across sessions, you can implement a custom storage solution by extending the `Storage` interface.

When you use authenticated endpoints or interact with APIs that depend on cookies, Revali Client automatically handles storing and retrieving them through the provided `Storage` implementation.

## What Are Cookies?

Cookies are small pieces of data that a server can send to a client and store locally—usually to maintain state between requests. They’re commonly used for things like session management, authentication, and user preferences.

### How Cookies Are Created

Cookies are typically set by the server via the `Set-Cookie` HTTP response header. When the client receives this response, it stores the cookie according to the specified rules (e.g., domain, path, expiration). For example:

```http
Set-Cookie: sessionId=abc123;
```

### Cookie Flow

Once a cookie is set, the client automatically includes it in future requests to the same server via the `Cookie` request header:

```http
Cookie: sessionId=abc123
```

In Revali Client, cookies are automatically managed and persisted (if you provide a `Storage` implementation), so you don’t need to manually handle headers or session state.

:::tip
Read more about how cookies are used in [Revali Server][revali-server-cookies].
:::

---

## Implementing Custom Storage

The `Storage` interface defines a simple key-value storage system. You can implement this interface to connect Revali Client to your preferred storage mechanism, such as `shared_preferences`, `hive`, or `sqflite`.

### 1. Import the Storage Interface

```dart
import 'package:revali_client/revali_client.dart';
```

### 2. Create Your Storage Class

Implement the `Storage` interface by overriding its required methods:

```dart
class MyStorage extends Storage {

  @override
  Future<Object?> operator [](String key) async {
    // TODO: implement []
  }

  @override
  Future<void> save(String key, Object? value) async {
    // TODO: implement save
  }

  @override
  Future<void> saveAll(Map<String, Object?> values) async {
    // TODO: implement saveAll
  }
}
```

> 💡 In a real app, you might use `SharedPreferences`, `Hive`, or another persistent storage solution.

### 3. Provide the Custom Storage to the Client

Once you've implemented your custom storage, pass it to the client during initialization:

```dart
final client = Server(storage: MyStorage());
```

[revali-server-cookies]: ../../revali_server/response/cookies.md
