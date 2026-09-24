---
title: Generated Code
description: The files revali_client generates, the Server class, how endpoints map to client methods, supported types and errors
---

What `revali_client` writes into `.revali/revali_client/`, and how each server endpoint turns into a client method. The directory is regenerated on every run, so never edit it by hand.

## Layout

```tree
.revali/revali_client/
├── pubspec.yaml                 # name: <package_name>
└── lib/
    ├── <package_name>.dart      # Server + implementations
    ├── interfaces.dart          # interfaces, re-exports Storage
    └── src/
        ├── server.dart
        ├── impls/
        │   └── user_data_source_impl.dart
        └── interfaces/
            └── user_data_source.dart
```

The generated `pubspec.yaml` depends on `http`, `revali_client`, `web_socket_channel` (only if you have WebSocket endpoints), `get_it` (only with the [get_it integration](/constructs/revali_client/integrations/get_it)), and every package that a type in an endpoint signature is imported from.

## The `Server` class

`Server` (renamed with `server_name`) is the entry point. It has one field per controller, typed as that controller's interface:

<CodeFile name=".revali/revali_client/lib/src/server.dart">

```dart
class Server {
  Server({HttpClient? client, Storage? storage, Uri? baseUrl})
    : storage = storage ?? SessionStorage() {
    final url = baseUrl?.toString() ?? "http://localhost:8080/api";

    this.client = RevaliClient(
      client: client ?? HttpPackageClient(),
      baseUrl: url,
      storage: this.storage,
    );
    // ...
  }

  late final RevaliClient client;
  late final Storage storage;

  late final UserDataSource user = UserDataSourceImpl(
    client: client,
    storage: storage,
  );
}
```

</CodeFile>

| Constructor argument | Default | Use it for |
| --- | --- | --- |
| `baseUrl` | `<scheme>://<host>:<port>/<prefix>` from your `AppConfig` at generation time | Any deployed or non-local server. Include the prefix, e.g. `https://api.example.com/api`. |
| `client` | `HttpPackageClient()` | Registering [interceptors](/constructs/revali_client/resilience#interceptors), or swapping the transport. |
| `storage` | `SessionStorage()` (in memory) | Persisting cookies across restarts. See [Storage](/constructs/revali_client/storage). |
| `websocket` | `WebSocketChannel.connect` | Only generated when the API has `@WebSocket` endpoints. Replace it to control how sockets are opened. |

`Server` does not take a timeout or retry policy. To set those, build a `RevaliClient` yourself. See [Configuring a generated client](/constructs/revali_client/resilience#configuring-a-generated-client).

## Naming

| Server | Client interface | Client implementation | `Server` field |
| --- | --- | --- | --- |
| `UserController` | `UserDataSource` | `UserDataSourceImpl` | `user` |
| `OrderItemsController` | `OrderItemsDataSource` | `OrderItemsDataSourceImpl` | `orderItems` |

Client methods keep the Dart method name of the server handler.

## Parameters

Given:

<CodeFile name="routes/controllers/shop_controller.dart">

```dart
@Controller('shops/:shopId')
class ShopController {
  const ShopController();

  @Post('products')
  Future<Product> create(
    @Param() String shopId,
    @Query('dry_run') bool? dryRun,
    @Header('X-Request-Id') String requestId,
    @Body() Product product,
    @Cookie('session') String session,
  ) async => ...;
}
```

</CodeFile>

the generated interface is:

```dart
abstract interface class ShopDataSource {
  const ShopDataSource();

  Future<Product> create({
    required String shopId,
    required Product product,
    bool? dryRun,
    required String requestId,
  });
}
```

- Path, query, header and body parameters become **named** arguments, named after the Dart parameter rather than the header or query key. Nullable parameters and parameters with a default value are optional.
- `@Header.all` and `@Query.all` become `List<T>` arguments.
- `@Body(['name'])` parameters are sent together as a JSON object, one key per parameter.
- `@Cookie` parameters are not arguments. The client reads them from `Storage` and sends them in a `Cookie` header. A required cookie that is missing from storage throws before the request is sent.
- Parameters the server fills from its own context (dependencies, `SetCookies`, WebSocket senders and so on) do not appear on the client.

## Return types

| Server handler returns | Client method returns |
| --- | --- |
| `T` or `Future<T>` | `Future<T>` |
| `void` / `Future<void>` | `Future<void>` |
| `Stream<T>`, or any `@SSE` handler | `Stream<T>` |
| `@WebSocket` handler with `@Body() T` | `Stream<R>`, taking `required Stream<T> data` |

`T` can be `String`, `int`, `double`, `bool`, `List`, `Set`, `Iterable`, `Map`, positional, named or mixed records, enums, custom classes, `List<int>` (bytes), and any nullable or nested combination of these.

The client unwraps the server's `{"data": ...}` envelope for you. If the response body does not match the declared type, the method throws `Exception('Invalid response')`.

### Custom types

A custom class used as a parameter or return type needs:

- a `fromJson` factory taking a `Map<String, dynamic>`, and
- a `toJson()` method returning a `Map<String, dynamic>`.

Enums are sent and read by `name`. An enum with its own `static fromJson(String)` and `toJson()` uses those instead.

```dart
class User {
  const User({required this.name});

  factory User.fromJson(Map<String, dynamic> json) =>
      User(name: json['name'] as String);

  final String name;

  Map<String, dynamic> toJson() => {'name': name};
}
```

### Sharing types

The generated package imports each custom type from the package it is declared in, and adds that package to its `pubspec.yaml`. If a model lives in the server package, the client ends up depending on the whole server. Put shared models in their own package that both the server and the app depend on:

```tree
my_project/
├── models/        # User, Product, ... (depends on neither side)
├── my_server/     # depends on models
└── my_app/        # depends on models and on my_server/.revali/revali_client
```

## Errors

Any non-2xx response throws `ServerException`:

```dart
try {
  await server.user.getById(id: '123');
} on ServerException catch (e) {
  if (e.code == 'user_not_found') {
    // ...
  }
}
```

| Field | Meaning |
| --- | --- |
| `statusCode` | HTTP status. |
| `message` | The HTTP reason phrase. |
| `body` | Raw response body, when there was one. |
| `code`, `reason`, `details` | Read from a `{"error": {"code", "message", "details"}}` body, which [`HttpError`](/revali/app-configuration/default-responses#httperror) produces. `null` otherwise. |
| `isStructured` | `true` when `code` was present. |

Transport failures (connection refused, timeouts) surface as the underlying exception, not `ServerException`.

## Testing against the interfaces

Code that depends on `UserDataSource` rather than `Server` can be tested with a fake:

```dart
class FakeUsers implements UserDataSource {
  const FakeUsers();

  @override
  Future<User> getById({required String id}) async => User(name: 'test');
}
```
