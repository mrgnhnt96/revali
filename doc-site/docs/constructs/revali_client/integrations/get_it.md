---
title: get_it Integration
description: Use dependency injection with get_it
sidebar_position: 1
---

# get_it Integration

Revali Client provides first-class integration with [get_it](https://pub.dev/packages/get_it), a popular service locator and dependency injection package in Dart and Flutter. This integration automatically generates registration code for all your data sources, making it easy to use dependency injection throughout your application.

## Overview

The get_it integration automatically:

- Adds `get_it` as a dependency to the generated client package
- Generates a `register()` method on your Server class
- Registers the Server instance as a singleton
- Registers all data source interfaces as lazy singletons
- Enables easy dependency injection in your app

**Benefits:**

- Clean architecture with dependency inversion
- Easy testing with mock implementations
- Centralized dependency management
- No manual registration boilerplate

---

## Configuration

Enable the get_it integration in your `revali.yaml`:

```yaml title="revali.yaml"
constructs:
  - name: revali_client
    options:
      integrations:
        get_it: true
```

After enabling this option and running `revali dev` or `revali build`, the generated client will include:

1. `get_it` package in `pubspec.yaml`
2. A `register()` method on the Server class
3. Proper imports for `get_it`

---

## Basic Usage

### Registering Services

Call the generated `register()` method during app initialization:

```dart
import 'package:get_it/get_it.dart';
import 'package:revali_client/client.dart';

void main() {
  // Get the GetIt instance
  final getIt = GetIt.instance;

  // Register all Revali Client services
  Server().register(getIt);

  // Run your app
  runApp(MyApp());
}
```

### Retrieving Services

Access your data sources anywhere in your app:

```dart
import 'package:get_it/get_it.dart';
import 'package:revali_client/interfaces.dart';

class UserRepository {
  // Get data source from GetIt
  final UserDataSource _userDataSource = GetIt.I<UserDataSource>();

  Future<List<User>> getUsers() async {
    return await _userDataSource.getAll();
  }

  Future<User> getUser(String id) async {
    return await _userDataSource.getById(id: id);
  }
}
```

Or use it directly in widgets:

```dart
class UserListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userDataSource = GetIt.I<UserDataSource>();

    return FutureBuilder<List<User>>(
      future: userDataSource.getAll(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return UserTile(user: snapshot.data![index]);
            },
          );
        }
        return CircularProgressIndicator();
      },
    );
  }
}
```

---

## What Gets Registered

The `register()` method registers two types of services:

### 1. Server Instance (Singleton)

The Server class itself is registered as a singleton:

```dart
getIt.registerSingleton(this); // The Server instance
```

This means you can also retrieve the entire Server:

```dart
final server = GetIt.I<Server>();
final users = await server.user.getAll();
```

### 2. Data Sources (Lazy Singletons)

Each data source interface is registered as a lazy singleton:

```dart
// For each controller, registers:
getIt.registerLazySingleton<UserDataSource>(() => server.user);
getIt.registerLazySingleton<PostDataSource>(() => server.post);
getIt.registerLazySingleton<AuthDataSource>(() => server.auth);
// ... etc
```

**Key points:**

- Registered by **interface type** (not implementation)
- **Lazy singletons**: Only created when first accessed
- Same instance returned on every call
- Backed by the Server's data source instances

---

## Complete Example

Here's a complete Flutter app using the get_it integration:

```dart title="main.dart"
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:revali_client/client.dart';
import 'package:revali_client/interfaces.dart';

void main() {
  // Initialize dependency injection
  setupDependencies();

  runApp(MyApp());
}

void setupDependencies() {
  final getIt = GetIt.instance;

  // Register Revali Client services
  Server().register(getIt);

  // Register other app services
  getIt.registerLazySingleton<UserRepository>(() => UserRepository());
  getIt.registerLazySingleton<AuthService>(() => AuthService());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      home: UserListPage(),
    );
  }
}

class UserListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Users')),
      body: UserList(),
    );
  }
}

class UserList extends StatelessWidget {
  // Inject the data source
  final UserDataSource _userDataSource = GetIt.I<UserDataSource>();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<User>>(
      future: _userDataSource.getAll(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final users = snapshot.data ?? [];

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(users[index].name),
              subtitle: Text(users[index].email),
            );
          },
        );
      },
    );
  }
}

// Repository pattern with injected data source
class UserRepository {
  final UserDataSource _userDataSource = GetIt.I<UserDataSource>();

  Future<List<User>> getAllUsers() => _userDataSource.getAll();

  Future<User> getUserById(String id) => _userDataSource.getById(id: id);

  Future<User> createUser(User user) => _userDataSource.create(user);
}
```

---

## Advanced Patterns

### Repository Pattern

Create repositories that depend on injected data sources:

```dart
class UserRepository {
  UserRepository(this._userDataSource);

  final UserDataSource _userDataSource;

  Future<List<User>> getActiveUsers() async {
    final users = await _userDataSource.getAll();
    return users.where((user) => user.isActive).toList();
  }

  Future<User> createUser({
    required String name,
    required String email,
  }) async {
    final user = User(name: name, email: email);
    return await _userDataSource.create(user);
  }
}

// Register with dependency
void setupDependencies() {
  final getIt = GetIt.instance;

  Server().register(getIt);

  getIt.registerLazySingleton<UserRepository>(
    () => UserRepository(getIt<UserDataSource>()),
  );
}
```

### Service Layer

Build service layers on top of data sources:

```dart
class AuthService {
  AuthService(this._authDataSource, this._storage);

  final AuthDataSource _authDataSource;
  final Storage _storage;

  Future<bool> login(String email, String password) async {
    try {
      final response = await _authDataSource.login(
        email: email,
        password: password,
      );

      await _storage.save('auth_token', response.token);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await _authDataSource.logout();
    await _storage.remove('auth_token');
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage['auth_token'];
    return token != null;
  }
}

// Register service with dependencies
getIt.registerLazySingleton<AuthService>(
  () => AuthService(
    getIt<AuthDataSource>(),
    getIt<Storage>(),
  ),
);
```

### BLoC/Cubit Integration

Use with state management solutions:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

class UserCubit extends Cubit<UserState> {
  UserCubit(this._userDataSource) : super(UserInitial());

  final UserDataSource _userDataSource;

  Future<void> loadUsers() async {
    emit(UserLoading());

    try {
      final users = await _userDataSource.getAll();
      emit(UserLoaded(users));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }
}

// Register cubit
getIt.registerFactory<UserCubit>(
  () => UserCubit(getIt<UserDataSource>()),
);

// Use in widget
class UserListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<UserCubit>()..loadUsers(),
      child: UserListView(),
    );
  }
}
```

### Provider Integration

Use with the Provider package:

```dart
import 'package:provider/provider.dart';

void main() {
  setupDependencies();

  runApp(
    MultiProvider(
      providers: [
        Provider<UserDataSource>(
          create: (_) => GetIt.I<UserDataSource>(),
        ),
        Provider<PostDataSource>(
          create: (_) => GetIt.I<PostDataSource>(),
        ),
        ProxyProvider<UserDataSource, UserRepository>(
          update: (_, userDataSource, __) => UserRepository(userDataSource),
        ),
      ],
      child: MyApp(),
    ),
  );
}
```

---

## Best Practices

### Use Interfaces

Always inject interface types, not implementations:

```dart
// ✅ Good - Depends on interface
class UserRepository {
  UserRepository(this._userDataSource);
  final UserDataSource _userDataSource;
}

// ❌ Bad - Depends on implementation
class UserRepository {
  UserRepository(this._userDataSource);
  final UserDataSourceImpl _userDataSource;
}
```

## What's Next?

Now that you understand the get_it integration, explore these related topics:

- **[Configuration](/constructs/revali_client/getting-started/configure)** - Learn about other integration options
- **[Generated Code](/constructs/revali_client/generated-code)** - Understand the client structure
- **[Testing](/constructs/revali_client/generated-code#testing-with-generated-code)** - Test your client code
- **[Storage](/constructs/revali_client/getting-started/storage)** - Manage cookies and sessions
