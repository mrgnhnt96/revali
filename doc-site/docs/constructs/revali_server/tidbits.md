---
description: Extra details to help you understand stuff
---

# Tid Bits

## Using Types in Annotations

### Compile-Time Constants

Dart requires annotations to be compile-time constants. This means that if you don't already know what the value is going to be, it's not compile-time constant and can't be used in an annotation.

Primitive types like `String`, `int`, `double`, and `bool` can be compile-time constants and can be used in annotations.

```dart
@Post('hello')
```

Iterable types like `List`, `Set`, and `Map` can be compile-time constants and as long as the values they contain are constants.

```dart
@Body(['data', 'user', 'id'])
```

:::tip
Check out the dart docs on [Constants][dart-constants] to learn more.
:::

### Type Referencing

Behind the scenes, revali analyzes the code and retrieves AST (Abstract Syntax Tree) nodes to extract the information it needs.

When using types in annotations, even though we are not providing the actual value, we are providing a reference to the type. This is enough for revali to understand the class, it's constructor, and it's parameters.

To understand this on a deeper level, let's take a look at how [pipes] are used in [bindings].

Let's say we have a `UserPipe` class that will fetch a user from the database based on the `id` provided in the request. Our classes might look like this:

```dart title="lib/components/pipes/user_pipe.dart"
class UserPipe implements Pipe<String, User> {
    const UserPipe({
        required this.userService,
    });

    final UserService userService;
    ...
}
```

```dart title="lib/services/user_service.dart"
class UserService {
    const UserService({
        required this.database,
    });

    final Database database;
    ...
}
```

```dart title="lib/database.dart"
class Database {
    const Database({
        required this.connection,
    });

    final Connection connection;
    ...
}
```

We can see that the `UserPipe` requires a `UserService` which requires a `Database` which requires a `Connection`. For the sake of this example, let's assume that the `Connection` class requires some run-time configuration that cannot be provide at compile-time. This means that we can't use the `Connection` class in an annotation, which implies that any class that requires it can't be used in an annotation either.

Luckily, we don't need to provide an actual instance of the `UserPipe` class, we just need to provide a reference to it.

```dart
@Body.pipe(UserPipe)
```

This is enough for revali to resolve the `UserPipe` type and use it in during runtime.

The generated code could look something like this:

```dart
// some where in the generated code
final connection = Connection();
await connection.connect();

final database = Database(connection: connection);
final userService = UserService(database: database);

// some where else in the generated code
final user = await UserPipe(userService: userService).transform(...);
```

[dart-constants]: https://dart.dev/language/variables#final-and-const
[pipes]: ./core/pipes.md
[bindings]: ./core/binding.md
