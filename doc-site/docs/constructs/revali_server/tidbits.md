---
description: Extra details to help you understand stuff
---

# Tid Bits

This page collects the small-but-important details that help you reason about how Revali turns annotations into runtime behavior. If an annotation is behaving in a surprising way, there is a good chance the answer lives in one of the sections below.

## Using Types in Annotations

When you decorate controllers, handlers, or bindings, you are authoring normal Dart annotations. That means every expression inside the annotation has to be evaluated at compile time so the compiler can capture it inside the library metadata that Revali inspects later.

### Compile-Time Constants

Dart enforces that annotation expressions are compile-time constants. If the value cannot be evaluated without running your program, it cannot appear in an annotation.

The following patterns are safe to use:

- Literal values such as strings, numbers, booleans, and `null`
- Invocations of `const` constructors whose arguments are also constant
- Top-level `const` variables or `static const` fields
- `const` collections (`List`, `Set`, `Map`) whose contents are themselves constant

```dart
@Post('hello')

const dataPath = ['data', 'user', 'id'];

@Body(dataPath)
```

The `const` keyword is optional inside annotations because Dart automatically treats annotation expressions as `const`; however, the expression still needs to be something the compiler can reduce to a constant value. Any attempt to instantiate a class with a non-constant constructor (for example, `Service()` where `Service` is not `const`) will fail immediately.

:::tip
If you are unsure whether something qualifies, the Dart docs on [constants][dart-constants] outline every rule in detail.
:::

### Type Referencing

Revali performs static analysis by walking the Dart Abstract Syntax Tree (AST). In most cases it does not need an actual instance of the type you mention in an annotation; it just needs the type reference so it can look up constructors, parameters, and metadata. As long as the type is reachable at compile time, Revali can wire it up at runtime.

Consider the interaction between [pipes] and [bindings]. Suppose you have a `UserPipe` that ultimately depends on a `Connection` object that in turn needs runtime configuration:

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

We can see that `UserPipe` depends on `UserService`, which depends on `Database`, which depends on `Connection`. Because `Connection` needs runtime configuration, you cannot include an instance of it inside an annotation. Fortunately, Revali does not require that; you only have to reference the `UserPipe` symbol:

```dart
@Body.pipe(UserPipe)
```

That single reference gives Revali enough information to build the entire dependency chain when the generated server boots. Conceptually, the generated code might resemble:

```dart
final connection = Connection();
await connection.connect();

final database = Database(connection: connection);
final userService = UserService(database: database);

final user = await UserPipe(userService: userService).transform(...);
```

The important takeaway: annotations pass _type information_, not instances. Revali inspects the referenced type, determines its constructor signature, and asks the dependency-injection container to provide everything it needs.

### Injecting Types

Sometimes you must give an annotation both a compile-time value (like a status code) and a dependency that can only be created at runtime. A common example is a [`LifecycleComponent`][lifecycle-component] that mixes primitive configuration with a service dependency:

```dart
class MyComponent implements LifecycleComponent {
    const MyComponent(this.statusCode, this.service);

    final int statusCode;
    final Service service;
}
```

The `statusCode` argument is trivially constant, but `service` is not. That means these two naive attempts fail for different reasons:

```dart
class MyController {
    @MyComponent(200, Service()) // Error! Service is not a constant
    @Get()
    User getUser() ...

    @LifecycleComponents([MyComponent]) // Works, but what's the value of the `statusCode`?
    @Get()
    User getUser() ...
}
```

To bridge that gap, Revali ships the `Inject` base class. By extending it, you create a marker type that is constant (because it has a `const` constructor) but still tells Revali which dependency to resolve at runtime.

```dart
import 'package:revali/revali.dart';

final class InjectService extends Inject implements Service {
    const InjectService();
}
```

Now you can pass both pieces of information in a single annotation:

```dart
@MyComponent(200, InjectService())
@Get()
User getUser() ...
```

Behind the scenes Revali does three things when it sees `InjectService`:

1. Confirms the class extends `Inject` (so it is safe to treat as a marker).
2. Looks at the interfaces or base classes it implements (`Service` in this case).
3. Asks the dependency-injection container for the real implementation of that interface.

This pattern lets you mix literal configuration with runtime dependencies in a single annotation without sacrificing compile-time safety.

[dart-constants]: https://dart.dev/language/variables#final-and-const
[pipes]: ./core/pipes.md
[bindings]: ./core/binding.md
[lifecycle-component]: ./lifecycle-components/overview.md
