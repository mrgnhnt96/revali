/// Template strings for AI coding assistant reference files.
library;

// ---------------------------------------------------------------------------
// Shared master reference document (used by Claude, Copilot, Windsurf, Cline)
// ---------------------------------------------------------------------------

const _doc = r"""
# Revali Framework Reference

> Revali is an annotation-driven Dart API framework. You write plain Dart classes decorated with annotations like `@App()`, `@Controller()`, `@Get()`/`@Post()`/etc., and Revali's CLI (`revali dev` / `revali build`) analyzes that code and generates the actual HTTP server, plus optional client SDKs, OpenAPI specs, and Dockerfiles through a pluggable "constructs" system — you never hand-write routing or serialization boilerplate.

## Project structure

A Revali project has no fixed "framework folder" beyond two conventions: an app/controller-scanning directory named `routes/`, and a generated-output directory named `.revali/` that must never be hand-edited.

```
.
├── lib/
│   └── components/            # lifecycle components (middleware, guards, pipes, catchers)
│       ├── lifecycle_components/
│       ├── observers/
│       └── pipes/
├── routes/
│   ├── main_app.dart          # @App() AppConfig subclass — must end in _app.dart / .app.dart
│   └── controllers/
│       └── users_controller.dart   # @Controller — must end in _controller.dart / .controller.dart
├── pubspec.yaml
├── revali.yaml                 # optional: constructs, hot reload, build config
└── .revali/                    # GENERATED — never edit by hand
    ├── server/                 # built-in server construct output (server.dart, routes.json)
    ├── build/                  # build-construct output (e.g. Dockerfile)
    ├── revali_client/          # if revali_client is enabled
    └── revali_swagger/         # if revali_swagger is enabled (swagger.yaml/json)
```

Key naming rules enforced by file-system scanning under `routes/`:

- **Controllers**: filename must end with `_controller.dart` or `.controller.dart`.
- **App configs**: filename must end with `_app.dart` or `.app.dart`.
- Both can be nested in subdirectories under `routes/`.
- Files outside `routes/` and `lib/components/**` (the watched hot-reload paths) are not scanned as routes.

## revali.yaml

`revali.yaml`, at the project root, configures which constructs run and how, hot-reload exclusions, and optional native-executable build settings. It is entirely optional — Revali works with sensible defaults with no `revali.yaml` at all.

```yaml
# Constructs configuration
constructs:
  - name: revali_docker
    enabled: true
  - name: revali_client
    enabled: true
    options:
      package_name: my_api_client
      scheme: https
  - name: revali_swagger
    enabled: true
    options:
      title: My API
      version: 2.1.0

# Exclude paths from triggering hot reload (relative to revali.yaml, or absolute)
hot_reload:
  exclude:
    - lib/generated
    - docs

# Optional: compile the server to a native executable during `revali build`
build:
  target_os: linux            # optional, defaults to host OS
  target_arch: [x64, arm64]   # optional, defaults to host arch
  strip_debug_info: true      # optional, default false
```

- All constructs are enabled by default; add an explicit `enabled: false` entry to disable one.
- If two dependencies register a construct with the same `name`, disambiguate with `package:` (must match the package name in `pubspec.yaml`).
- Server generation itself (`revali_server`) is *built into* `revali` — it is not something you enable/disable via this file.
- Adding a `build:` section is the *signal* that tells `revali build` to also run `dart compile exe` for you (cross-compiling to Linux works from any host OS since Dart 3.8; `macos`/`windows` targets must be built natively on that OS).

## App

Every Revali app has a class annotated `@App()` extending `AppConfig`, placed under `routes/` in a `*_app.dart` file. It defines host/port/prefix, dependency registration, and — optionally — flavor, default responses, and trusted-proxy config.

```dart
import 'package:revali_router/revali_router.dart';

@App()
final class MainApp extends AppConfig {
  const MainApp() : super(
    host: 'localhost',
    port: 8080,
    prefix: '/api',
  );

  @override
  Future<void> configureDependencies(DI di) async {
    // Register your dependencies here
  }
}
```

- `host`/`port` are required constructor args; `prefix` is optional and is prepended to every controller route.
- URL shape: `{host}:{port}{prefix}/{controller-path}/{method-path}`.
- Multiple `AppConfig` subclasses can coexist in one project (e.g. a public API app and an internal admin app on different ports).
- Override `trustedProxy` (a `TrustedProxy(headers: [...])`) so `request.ip`/`@Ip()` resolve behind a reverse proxy — see [Request](#request) below.
- For HTTPS locally, either pass `--cert`/`--key` to `revali dev` (no code change needed) or use `AppConfig.secure(... securityContext: SecurityContext()..useCertificateChain(...)..usePrivateKey(...))` for programmatic control (e.g. mutual TLS via `requestClientCertificate`). CLI flags win if both are present.

## Controllers & Methods

Controllers group related endpoints; they live in `routes/`, must end in `_controller.dart`/`.controller.dart`, and are annotated `@Controller('basePath')`. Endpoints are methods annotated with exactly one HTTP-method annotation.

```dart
import 'package:revali_router/revali_router.dart';

@Controller('users')
class UsersController {
  const UsersController(this._userService, this._logger);

  final UserService _userService;
  final Logger _logger;

  @Get()
  Future<List<User>> getUsers() async => _userService.getAllUsers();

  @Get(':id')
  Future<User> getUser(@Param() String id) async =>
      _userService.getUserById(id);

  @Post()
  Future<User> createUser(@Body() CreateUserRequest request) async =>
      _userService.createUser(request);

  @Put(':id')
  Future<User> updateUser(
    @Param() String id,
    @Body() UpdateUserRequest request,
  ) async => _userService.updateUser(id, request);

  @Delete(':id')
  Future<void> deleteUser(@Param() String id) async =>
      _userService.deleteUser(id);
}
```

Available method annotations: `@Get()`, `@Post()`, `@Put()`, `@Patch()`, `@Delete()`, `@SSE()` (Server-Sent Events), `@WebSocket()`. Only one method annotation per endpoint. Custom methods can be created by extending `Method`: `final class CustomMethod extends Method { const CustomMethod([String? path]) : super('CUSTOM', path: path); }`.

Path parameters use `:name` syntax and can be declared at the controller level too (`@Controller('shops/:shopId')`), shared by every endpoint beneath it. Path parameters are always `String`, required, and URL-decoded.

Controllers use constructor injection (Revali picks the **first public constructor**; private constructors are ignored) and are **singletons by default** — pass `type: InstanceType.factory` to `@Controller(...)` for a fresh instance per request. Controllers never receive request objects directly; use binding annotations instead.

## Binding

Binding extracts data from the request (or injects a dependency) straight into an endpoint's parameters — no manual request parsing.

| Annotation | Purpose | Example |
| --- | --- | --- |
| `@Param()` | Path parameter | `@Param() String id` |
| `@Query()` | Query parameter | `@Query() String? search` |
| `@Header()` | Request header | `@Header('Authorization') String? auth` |
| `@Ip()` | Resolved client IP | `@Ip() String? clientIp` |
| `@Body()` | Request body (whole or nested keys) | `@Body() User user` / `@Body(['data','email']) String email` |
| `@Dep()` | Dependency injection | `@Dep() UserService service` |
| `@Data()` | Value from the request's Data Handler | `@Data() User currentUser` |
| custom `Bind<T>` | Custom extraction logic | `@CustomBind() CustomType data` |

Only one binding annotation per parameter. `@Query()`/`@Header()` collapse repeated values (last value wins / comma-joined respectively) unless you use `@Query.all()` / `@Header.all()`, which bind a `List<String>` of every value.

```dart
@Controller('users')
class UsersController {
  const UsersController(@Dep() this._userService);
  final UserService _userService;

  @Post('login')
  String login(
    @Body() LoginRequest credentials,
    @Ip() String? clientIp,
    @Header('User-Agent') String? ua,
  ) => 'Login from $clientIp';
}
```

Revali auto-converts request-body JSON into typed objects when the target class exposes a `fromJson(Map<String, dynamic>)` factory constructor (must take exactly one argument) — no pipe required for the common case. `@Param()`/`@Query()`/`@Header()` values are always `String`; use a [pipe](#pipes) to convert them.

Custom bindings extend `Bind<T>` and implement `T bind(BindContext context)`; the constructor must be `const`. Use `@Binds(MyBinding)` instead of `@MyBinding()` when the binding needs runtime (non-const) arguments.

## Implied Binding

Some parameter types are recognized automatically and need **no** annotation at all — this is how endpoints (and [lifecycle components](#middleware)) reach lower-level request/response/context objects when binding annotations aren't expressive enough.

```dart
@Controller('api')
class ApiController {
  @Get('debug')
  String debug(Request request) => 'Method: ${request.method}, Path: ${request.path}';

  @Get('custom')
  String getCustom(Headers headers) {
    headers['X-Custom-Header'] = 'My Value';
    return 'Custom response';
  }
}
```

Commonly implied types: `Request`, `RequestHeaders`, `RequestCookies`, `Response`, `Headers`/`ResponseHeaders`, `Cookies`/`ResponseCookies`, `SetCookies`, `DI`, `Meta`/`MetaScope`, `RouteEntry`, `Data`, `CleanUp`, `ReflectHandler`/`Reflect`, and `Context` (the full context, exposing `data`, `meta`, `route`, `request`, `response`, `reflect`). Prefer scoped bindings (`@Param()`, `@Body()`, etc.) over these low-level types in endpoints for testability; implied types are most useful inside [lifecycle components](#middleware), which all share the same `Context` regardless of role.

## Pipes

Pipes transform/validate a bound value before it reaches your endpoint — for anything beyond what an automatic `fromJson` conversion can do (DB lookups, complex validation, async work).

```dart
import 'package:revali_router/revali_router.dart';

class UserPipe implements Pipe<String, User> {
  const UserPipe({required this.userService});
  final UserService userService;

  @override
  Future<User> transform(String value, Context context) async {
    final user = await userService.getUserById(value);
    if (user == null) throw NotFoundException('User not found: $value');
    return user;
  }
}
```

Use it with `.pipe(...)` on any binding annotation:

```dart
@Get(':id')
Future<User> getUser(@Param.pipe(UserPipe) User user) async => user;

@Get()
Future<List<User>> search(@Query.pipe(EmailPipe) String email) async =>
    userService.findByEmail(email);
```

Generate a pipe scaffold with `dart run revali create pipe`. **Rule of thumb**: reach for `fromJson` for plain synchronous parsing; reach for a pipe when you need validation, async operations, or custom error handling.

## Request

The `Request` object is read-only. It's mostly accessed through binding annotations, but the raw object is available via [implied binding](#implied-binding) inside endpoints and lifecycle components.

**Body** — lazily resolved; content-type determines the concrete `BodyData` subtype (`StringBodyData` for `text/plain`, `JsonBodyData` for `application/json`, `FormDataBodyData` for form/multipart, `BinaryBodyData` for `application/octet-stream`). In an endpoint, `@Body()` resolves it automatically; outside an endpoint (e.g. in middleware) call `await context.request.resolvePayload()` first, or an `UnresolvedPayloadException` is thrown. Custom body types are supported by extending `BodyData`/`BodyParser` and registering via `PayloadImpl.additionalParsers[mimeType] = MyBodyParser(mimeType)` in your `AppConfig` constructor.

**Headers** — read-only; access via `context.request.headers` or bind a specific header with `@Header('Name')`.

**Client IP** — `request.ip`, or `@Ip()` in an endpoint. By default it's the raw TCP remote address. Behind a proxy, override `trustedProxy` on your `AppConfig`:

```dart
@App()
final class MainApp extends AppConfig {
  const MainApp() : super(host: 'localhost', port: 8080);

  @override
  TrustedProxy get trustedProxy => const TrustedProxy(
    headers: ['X-Forwarded-For'],
  );
}
```

Headers are checked in order; the default scans each comma-separated value **right to left** (rightmost = proxy-appended client IP) — set `useLeftmostIp: true` to flip that. Only enable `trustedProxy` when *all* traffic reaches you through proxies you control, and consider pairing it with `@PreventHeaders({'X-Forwarded-For', ...})` so clients can't spoof the header themselves.

## Middleware

`Middleware` is a lifecycle component that runs first (before guards), used to inspect/transform the request or short-circuit it. The modern, preferred way to write any lifecycle component (middleware, guard, interceptor, exception catcher) is a plain class `implements LifecycleComponent` with methods whose **return type** determines their role:

| Return type | Role |
| --- | --- |
| `WrapperResult` | Request Wrapper |
| `GuardResult` | Guard |
| `MiddlewareResult` | Middleware |
| `InterceptorPreResult` | Interceptor (pre) |
| `InterceptorPostResult` | Interceptor (post) |
| `ExceptionCatcherResult<Exception>` | Exception Catcher |

```dart
import 'package:revali_router/revali_router.dart';

class RequireApiKey implements LifecycleComponent {
  const RequireApiKey();

  MiddlewareResult checkApiKey(@Header('X-Api-Key') String? apiKey, Data data) {
    if (apiKey == null) {
      return const MiddlewareResult.stop(statusCode: 401, body: 'Missing X-Api-Key header');
    }
    data.add(apiKey);
    return const MiddlewareResult.next();
  }
}
```

Register it as an annotation on the app, controller, or endpoint:

```dart
@RequireApiKey()
@Get('protected')
String protected(@Data() String apiKey) => 'key: $apiKey';
```

Or by type reference when a compile-time constant argument isn't possible: `@LifecycleComponents([RequireApiKey])` (the classic-interface equivalents are `@Middlewares([...])`, `@Guards([...])`, `@Intercepts([...])`, `@Catches([...])`).

**Scoping & order**: components apply at app, controller, or endpoint level (inherited top-down); with several stacked on one endpoint, pre-phases run top-to-bottom and post-phases run bottom-to-top. Full request lifecycle order: Request → Request Wrapper (pre) → Observer (pre) → Middleware → Guard → Interceptor (pre) → Pipes → Endpoint → Interceptor (post) → Request Wrapper (post) → Observer (post) → Response.

**Guards** (run after middleware, before interceptors) protect access:

```dart
class RoleGuard implements LifecycleComponent {
  const RoleGuard(this.role);
  final String role;

  GuardResult protect(Data data) {
    final user = data.get<User?>();
    if (user == null) return const GuardResult.block(statusCode: 401);
    if (user.role != role) {
      return const GuardResult.block(statusCode: 403, body: 'Insufficient role');
    }
    return const GuardResult.pass();
  }
}
```

**Interceptors** wrap the endpoint with `pre`/`post` phases (e.g. to mutate `Response` after the handler runs) — see [`InterceptorPreResult`/`InterceptorPostResult`](#error-handling) in the lifecycle table above.

Classic interface forms (`implements Middleware { use(context) }`, `implements Guard { protect(context) }`, `implements Interceptor { pre(context) / post(context) }`) remain fully supported for advanced cases requiring a full `Context` parameter.

## Error Handling

An `ExceptionCatcher`-shaped `LifecycleComponent` method (return type `ExceptionCatcherResult<T>`) catches every exception of type `T` thrown anywhere in the request lifecycle and shapes the error response. The exception instance is bound automatically by matching the method's exception-typed parameter.

```dart
class NotFoundException implements Exception {
  const NotFoundException(this.message);
  final String message;
}

class NotFoundCatcher implements LifecycleComponent {
  const NotFoundCatcher();

  ExceptionCatcherResult<NotFoundException> catchNotFound(NotFoundException exception) {
    return ExceptionCatcherResult.handled(
      statusCode: 404,
      body: {'error': exception.message},
    );
  }
}
```

```dart
@Controller('widgets')
class WidgetController {
  @NotFoundCatcher()
  @Get('missing')
  String missing() => throw const NotFoundException('Widget not found');
}
```

Register once at the app or controller level to cover every route beneath it. `ExceptionCatcherResult.unhandled()` passes the exception on to the next matching catcher (useful for repetitive catchers). A `DefaultExceptionCatcher` subtype (classic form) catches anything unhandled elsewhere — scope it to the app level. Unhandled exceptions default to `500 Internal Server Error`, customizable via [`defaultResponses`](#app-configuration). `MissingArgumentException` (a missing/invalid `@Query`/`@Body`/… binding) is already mapped to HTTP 400 automatically. In debug mode, error response bodies include a `__DEBUG__` field with the exception and stack trace; this is stripped in profile/release modes.

## Authentication

Authentication is just a `Guard`-shaped lifecycle component reading a header and sharing the resolved identity via `Data`:

```dart
class RequireAuth implements LifecycleComponent {
  const RequireAuth();

  GuardResult checkAuth(@Header('Authorization') String? authorization, Data data) {
    if (authorization == null || !authorization.startsWith('Bearer ')) {
      return const GuardResult.block(statusCode: 401, body: 'Missing or invalid Authorization header');
    }
    final token = authorization.substring('Bearer '.length);
    if (!isValidToken(token)) {
      return const GuardResult.block(statusCode: 401, body: 'Invalid token');
    }
    data.add(token);
    return const GuardResult.pass();
  }
}
```

```dart
@Controller('account')
class AccountController {
  @RequireAuth()
  @Get('me')
  String me(@Data() String token) => 'authenticated as $token';
}
```

Apply `@RequireAuth()` at the controller or app level to guard every route beneath it in one place. Stack a second, role-checking guard (reading the `Data` the first guard stored) for authorization on top of authentication — see the `RoleGuard` pattern under [Middleware](#middleware). In real apps, swap the hardcoded `isValidToken` check for an injected auth service resolved via [DI](#dependency-injection--configure-dependencies).

## Dependency Injection / Configure Dependencies

Override `configureDependencies(DI di)` in your `AppConfig` to register services; Revali resolves them into controller constructors (and lifecycle-component constructors — `@Dep()` is implicit there) automatically.

```dart
@App()
final class MainApp extends AppConfig {
  const MainApp() : super(host: 'localhost', port: 8080);

  @override
  Future<void> configureDependencies(DI di) async {
    di.registerLazySingleton<DatabaseConnection>(() => DatabaseConnection.fromEnv());
    di.registerLazySingleton<IUserRepository>(UserRepository.new);
    di.registerLazySingleton<IUserService>(UserService.new);
    di.registerFactory<Logger>(() => Logger.withTimestamp());
    di.registerSingleton<AppConfig>(this);
  }
}
```

| Method | Behavior | Use for |
| --- | --- | --- |
| `registerLazySingleton<T>` | One instance, created on first use | expensive/stateless shared resources |
| `registerSingleton<T>` | Registers an already-built instance | config objects, pre-initialized resources |
| `registerFactory<T>` | New instance every resolution | stateful/transient objects |

```dart
@Controller('users')
class UsersController {
  const UsersController(this._userService); // constructor injection
  final IUserService _userService;

  @Get()
  Future<List<User>> getUsers() async => _userService.getAllUsers();
}
```

`@Dep()` is for controller constructors / endpoint parameters. For a **compile-time-constant annotation argument that needs a runtime dependency** (e.g. a `LifecycleComponent` constructor argument), extend the `Inject` marker class instead:

```dart
final class InjectService extends Inject implements Service {
  const InjectService();
}

class MyComponent implements LifecycleComponent {
  const MyComponent(this.statusCode, this.service);
  final int statusCode;
  final Service service;
}

@MyComponent(200, InjectService())
@Get('/')
User getUser() => ...;
```

For per-request state (a transaction, a session context), use `RequestScopedDI` inside a request [wrapper](#middleware) installed via `runZoned`, then `RequestScopedDI.current.registerSingleton<Transaction>(...)` and `RequestScopedDI.getFrom<MyService>(appDi)` to resolve with app-level fallback.

## App Configuration

| Concept | Summary |
| --- | --- |
| **Flavors** | `@App(flavor: 'development')` (case-sensitive) lets multiple `AppConfig`s coexist per environment; select with `revali dev --flavor=development` / `revali build --flavor=production`. |
| **Default responses** | Override `defaultResponses` (a `DefaultResponses(...)`) on `AppConfig` to customize the `internalServerError`, `notFound`, `failedCorsOrigin`, and `failedCorsHeaders` `SimpleResponse`s. |
| **Env vars** | Read runtime values with `Env.current` — `string(name, orElse:)`, `require(name)` (throws when unset), `integer`/`boolean`/`uri` (throw when set but malformed). An empty value counts as unset. `.env`/`--dart-define` values stay compile-time (`String.fromEnvironment(...)`) and are for build configuration only. |
| **Address from env** | `super.fromEnv()` reads `HOST`/`PORT` at startup, defaulting to `0.0.0.0:8080` — what containers and `revali up`/`revali compose` expect. Not `const`, so the app class cannot be `const` either. |
| **Workers** | `workers: N` on `AppConfig` runs N isolates bound to the same port (`shared: true`). Isolates share no memory: caches, counters and statics become one per isolate. `IsolateIdentity.current` (`.index`, `.workerCount`, `.isWorker`) tells them apart — use `!isWorker` to guard once-per-process work. `backlog` sets the listen backlog (`0` = OS default). |
| **Health probes** | The `health` getter returns `HealthSettings` — `/healthz` (liveness, runs no checks) and `/readyz` (readiness, runs registered `HealthCheck`s), both served outside `prefix`. Override to move the paths, register checks, or `const HealthSettings.disabled()`. Every worker isolate reports `503` together while draining. |
| **Graceful shutdown** | `SIGTERM` drains consumers, then in-flight requests, before exit; `drainDelay` (default zero) and `shutdownTimeout` (default 15s) on `AppConfig`, plus `onServerStopped()`. `SIGINT` skips the drain delay. |
| **Compression** | Gzip is **on** by default via the `compression` getter; use `const CompressionSettings.disabled()` when a CDN or proxy in front already compresses. |
| **HTTPS in dev** | `revali dev --cert path.pem --key key.pem` (no code change), or `AppConfig.secure(securityContext: ...)` for programmatic TLS / mutual TLS. Generate local certs with `mkcert`. |
| **CORS (`@AllowOrigins`)** | All origins allowed by default; scope `@AllowOrigins({'https://myapp.com'})` at app/controller/endpoint level (inherits by default; `@AllowOrigins.noInherit(...)` opts out; `@AllowOrigins.all()` is an explicit wildcard). |

```dart
@App(flavor: 'production')
final class ProdApp extends AppConfig {
  const ProdApp() : super(host: '0.0.0.0', port: 80, prefix: '/api');

  @override
  DefaultResponses get defaultResponses => DefaultResponses(
    internalServerError: SimpleResponse(statusCode: 500, body: 'Something went wrong.'),
    notFound: SimpleResponse(statusCode: 404, body: 'Not found.'),
  );

  @override
  Future<void> configureDependencies(DI di) async {
    di.registerLazySingleton<DatabaseConnection>(() => DatabaseConnection.fromEnv());
  }
}
```

## Messaging (`@Consumes`)

Revali does not run a broker — it is infrastructure you deploy, like a database. The framework supplies the client side: a `MessageBroker` contract, an `@Consumes` annotation that turns a controller method into a handler, and the wiring that gives each message the same treatment a request gets.

Messaging is opt-in in **both** directions, and forgetting either half fails quietly (compiles, starts, nothing arrives):

1. Annotate a method with `@Consumes(topic, group:)`.
2. Return a broker from `AppConfig.createBroker()` — it returns `null` by default, and a `null` broker registers no consumers even when handlers are annotated.

```dart
@Controller('orders')
class OrdersController {
  const OrdersController();

  @Get()
  String list() => 'ok';

  @Consumes('order.placed', group: 'billing')
  Future<void> onPlaced(BrokerMessage message) async {
    await invoices.create(message.json);
  }
}

// In the app:
@override
Future<MessageBroker?> createBroker() async => InMemoryBroker();
```

| Rule | Detail |
| --- | --- |
| **Handler signature** | One `BrokerMessage` parameter, or none at all. Anything else — extra parameters, a non-`BrokerMessage` parameter, two `@Consumes` on one method, an empty topic or group — is rejected at generation time by name. `message.json` decodes the payload (throws if it is not JSON); `message.payload` is the raw form. |
| **Not both** | A method cannot be a route and a consumer; generation fails by name rather than emitting something ambiguous. |
| **Guards & middleware do NOT run** | A message has no caller to reject. Authorization has to come from the payload — the publisher knew who the user was. |
| **What a message does get** | Its own `TraceContext` (seeded from message headers) and its own `RequestScopedDI` scope, disposed when the message ends. |
| **Groups** | Members of one group share the work (one delivery each); separate groups each get a copy. |
| **Shutdown** | The broker is owned by the framework once returned — consumers drain first on `SIGTERM`, then HTTP. Do not close it in `onServerStopped`. |
| **Publishing a trace** | Nothing forwards headers automatically: `broker.publish(topic, body, headers: TraceContext.current?.outboundHeaders() ?? const {})`. |
| **Redis** | `revali_redis` provides `RedisBroker` (Redis Streams + consumer groups, not pub/sub). Give each **replica** its own `consumerName`; worker isolates are suffixed for you from `IsolateIdentity`. |

## Constructs

A **construct** is a standalone Dart package, imported as a dependency and auto-detected by Revali, that generates code into its own `.revali/<name>/` directory based on your routes and annotations. Server generation (`revali_server`) is built into `revali` itself and isn't a construct you choose — everything else is opt-in via `pubspec.yaml` + `revali.yaml`.

| Construct | Generates |
| --- | --- |
| `revali_server` (built in) | The actual HTTP server implementation — routing, middleware pipeline, request/response handling — from your controllers and annotations. Nothing to install. |
| `revali_client` | A type-safe Dart client SDK (interfaces + implementations mirroring your controllers) that calls your server, with HTTP interceptors, storage, and `get_it` DI integration support. |
| `revali_swagger` | An OpenAPI 3.0.3 spec (`swagger.yaml`/`swagger.json`) from your routes, parameters, and return types, with optional `@ApiSummary`/`@ApiDescription`/`@ApiTag`/`@ApiResponse`/`@ApiType` annotations to enrich it. |
| `revali_docker` | A multi-stage, production-ready `Dockerfile` that compiles your server to a native executable (or copies a pre-cross-compiled one if a `build:` section exists in `revali.yaml`). |

Constructs are either **Build Constructs** (run during `revali build`, generate deployment artifacts — client SDKs, Dockerfiles, OpenAPI docs) or **Generic Constructs** (flexible, run during `revali dev`/`revali build`, output to `.revali/<name>/`). You can author your own — see the `create-constructs` docs for the package-creation, entrypoint, and lifecycle guide (gap: full construct-authoring API surface is out of scope for this reference; consult `/create-constructs` directly for that).

## CLI Commands

| Command | Purpose |
| --- | --- |
| `dart run revali dev` | Analyze routes, generate server code, start the dev server with hot reload + a Dart VM debug service. Flags: `--debug`/`--release`/`--profile`, `--flavor`/`-f`, `--recompile`, `--skip-if-fresh`, `--inspect`, `--dart-vm-service-port`, `--dart-define`/`-D`, `--dart-define-from-file`, `--cert`/`--key`. |
| `dart run revali build` | Run all registered build constructs to produce deployment artifacts (and, with a `build:` section in `revali.yaml`, cross-compile a native executable via `dart compile exe`). Flags: `--release`/`--profile` (release is default), `--flavor`/`-f`, `--recompile`, `--dart-define`/`-D`, `--dart-define-from-file`. |
| `dart run revali routes` | List generated routes by reading `.revali/server/routes.json`. Flags: `--generate`/`-g` (regenerate first), `--json`. |
| `dart run revali doctor` | Diagnose SDK version, resolved `revali*` packages/constructs, construct kernel cache, and generated-output freshness. Flag: `--json`. |
| `dart run revali create <component>` | Scaffold a `controller`, `app`, `lifecycle-component` (`lc`), `observer`, or `pipe` — interactive if no component is named. Output paths are customizable under `server.create_path` in `revali.yaml`. |
| `dart run revali ai <tool>` | Install this reference doc for an AI coding assistant (`claude`, `cursor`, `copilot`, `windsurf`, `cline`, or `all`). Skips files that already exist unless `--force`. |
| `dart run revali services` | List the Revali services in the repository (a package with `routes/` that depends on the framework). Flags: `--root <path>`, `--paths` (one path per line, for scripting). Exits non-zero when none are found. |
| `dart run revali up` | Run **every** service at once, each on its own port from `--base-port` (passed as `PORT`, which `AppConfig.fromEnv` reads). Flags: `--root <path>`, `--only <name>` (repeatable), `--base-port <port>`. |
| `dart run revali compose` | Generate a `docker-compose.yaml` covering every service, with the same port assignment. Flags: `--root <path>`, `--output`/`-o <path>`, `--base-port <port>`, `--stdout`. Regenerating overwrites — keep additions in `compose.override.yaml`. |

While `revali dev` is running (with a TTY): press `r` to force regenerate + restart, `c` to clear/reprint the status board, `q` to quit. Without a TTY, write `reload`/`clear`/`quit` to a `.revali_cmd` file in the project root.

`revali up` draws a TUI when it has a terminal: a roster of services, a log pane for the focused one, and a key legend. `↑`/`↓` and `1`-`9` select; `j`/`k`/`g` scroll the pane; `r`/`c`/`q` act on the focused service and `R`/`C`/`Q` on the whole fleet; `s` restarts one whose process has exited; `Ctrl-C` stops the fleet. Without a terminal (CI, redirected output) it prints each service's output flat, prefixed with its name. It reaches children through their `.revali_cmd` files, since a child's stdin is a pipe rather than a terminal.

## Database Integration

Revali has no built-in ORM — the pattern is a plain repository class registered via DI, using whatever driver you like (the docs demonstrate `sqlite3`, but the shape is identical for Postgres/MySQL/etc.).

```yaml
dependencies:
  sqlite3: ^2.9.0
```

```dart
import 'package:sqlite3/sqlite3.dart';

class TodoRepository {
  TodoRepository(this._db) {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL
      );
    ''');
  }

  final Database _db;

  List<Map<String, Object?>> findAll() {
    final result = _db.select('SELECT id, title FROM todos ORDER BY id');
    return [for (final row in result) {'id': row['id'], 'title': row['title']}];
  }

  int insert(String title) {
    _db.execute('INSERT INTO todos (title) VALUES (?)', [title]);
    return _db.lastInsertRowId;
  }
}
```

Register the connection and repository as lazy singletons — since `TodoRepository` takes a constructor argument, register it with a closure (a bare `.new` tear-off only works for no-arg constructors):

```dart
@App()
final class MainApp extends AppConfig {
  MainApp() : super(host: 'localhost', port: 8080);

  @override
  Future<void> configureDependencies(DI di) async {
    di
      ..registerLazySingleton<Database>(sqlite3.openInMemory)
      ..registerLazySingleton<TodoRepository>(() => TodoRepository(di.get<Database>()));
  }
}
```

```dart
@Controller('todos')
class TodoController {
  const TodoController({@Dep() required this.repo});
  final TodoRepository repo;

  @Get()
  List<Map<String, Object?>> list() => repo.findAll();

  @Post()
  Map<String, Object?> create(@Body(['title']) String title) {
    final id = repo.insert(title);
    return {'id': id, 'title': title};
  }
}
```

The `Database` instance persists across requests because it's a lazy singleton, not per-request state — for genuinely per-request resources (a transaction), use `RequestScopedDI` instead (see [Dependency Injection](#dependency-injection--configure-dependencies)).

---

**Documentation gaps** (not fully specified in the doc-site content reviewed, so intentionally not invented here): the complete construct-authoring API (`create-constructs/core/*`) beyond the one-line summary above; the full `Context`/`Meta`/`Reflect` API surface beyond the implied-binding table; WebSocket/SSE handler lifecycle details beyond the basic `@SSE()`/`@WebSocket()` examples; and the exact `revali_swagger` type-inference rules for exotic types (only "primitives/collections/records/enums/sealed classes map automatically; unresolvable types like `Duration` warn and suggest `@ApiType`" is documented).
""";

// ---------------------------------------------------------------------------
// Single-file tool templates
// ---------------------------------------------------------------------------

const claudeMd = '''
# Revali Project

This is a **Revali** application. Revali analyzes your annotated Dart classes (`@App`, `@Controller`, `@Get`/`@Post`/etc.) and code-generates the actual HTTP server — plus, via optional "constructs," a type-safe Dart client, an OpenAPI spec, and a production Dockerfile. Run `dart run revali dev` for a hot-reloading dev server with an attachable Dart VM debugger, `dart run revali build` to run build constructs (and optionally cross-compile a native executable), `dart run revali routes` to list generated routes, and `dart run revali doctor` to diagnose SDK/construct/generated-output issues. Never hand-edit anything under `.revali/` — it is fully regenerated.

$_doc''';

const copilotMd = _doc;
const windsurfRules = _doc;
const clineRules = _doc;

// ---------------------------------------------------------------------------
// Cursor MDC files — one per topic, with glob-based auto-attachment
// ---------------------------------------------------------------------------

const cursorMdcFiles = <String, String>{
  'revali-overview.mdc': """
---
description: Revali overview — framework, project layout, revali.yaml config, CLI commands
globs: revali.yaml
alwaysApply: false
---

# Revali Framework Overview

Revali is an annotation-driven Dart API framework. You write plain Dart classes decorated with annotations like `@App()`, `@Controller()`, `@Get()`/`@Post()`/etc., and Revali's CLI (`revali dev` / `revali build`) analyzes that code and generates the actual HTTP server, plus optional client SDKs, OpenAPI specs, and Dockerfiles through a pluggable "constructs" system — you never hand-write routing or serialization boilerplate.

## Project structure

```
.
├── lib/
│   └── components/            # lifecycle components (middleware, guards, pipes, catchers)
│       ├── lifecycle_components/
│       ├── observers/
│       └── pipes/
├── routes/
│   ├── main_app.dart          # @App() AppConfig subclass — must end in _app.dart / .app.dart
│   └── controllers/
│       └── users_controller.dart   # @Controller — must end in _controller.dart / .controller.dart
├── pubspec.yaml
├── revali.yaml                 # optional: constructs, hot reload, build config
└── .revali/                    # GENERATED — never edit by hand
    ├── server/                 # built-in server construct output (server.dart, routes.json)
    ├── build/                  # build-construct output (e.g. Dockerfile)
    ├── revali_client/          # if revali_client is enabled
    └── revali_swagger/         # if revali_swagger is enabled (swagger.yaml/json)
```

- **Controllers**: filename must end with `_controller.dart` or `.controller.dart`.
- **App configs**: filename must end with `_app.dart` or `.app.dart`.
- Both can be nested in subdirectories under `routes/`.
- Files outside `routes/` and `lib/components/**` are not scanned as routes.

## revali.yaml

Entirely optional — configures which constructs run, hot-reload exclusions, and native-executable build settings.

```yaml
constructs:
  - name: revali_docker
    enabled: true
  - name: revali_client
    enabled: true
    options:
      package_name: my_api_client
      scheme: https
  - name: revali_swagger
    enabled: true
    options:
      title: My API
      version: 2.1.0

hot_reload:
  exclude:
    - lib/generated
    - docs

build:
  target_os: linux            # optional, defaults to host OS
  target_arch: [x64, arm64]   # optional, defaults to host arch
  strip_debug_info: true      # optional, default false
```

- All constructs are enabled by default; add `enabled: false` to disable one.
- Disambiguate same-named constructs from different packages with `package:`.
- `revali_server` is built into `revali` — not a construct you enable/disable here.
- Adding a `build:` section tells `revali build` to also cross-compile a native executable via `dart compile exe`.

## CLI Commands

| Command | Purpose |
| --- | --- |
| `dart run revali dev` | Analyze routes, generate server code, start the dev server with hot reload + Dart VM debug service. |
| `dart run revali build` | Run build constructs to produce deployment artifacts; optionally cross-compile a native executable. |
| `dart run revali routes` | List generated routes (`--generate`/`-g` to regenerate first, `--json`). |
| `dart run revali doctor` | Diagnose SDK/construct/generated-output freshness (`--json`). |
| `dart run revali create <component>` | Scaffold a `controller`, `app`, `lifecycle-component` (`lc`), `observer`, or `pipe`. |
| `dart run revali ai <tool>` | Install this reference doc for an AI assistant (`claude`/`cursor`/`copilot`/`windsurf`/`cline`/`all`). |
| `dart run revali services` | List the Revali services in the repo (`--root <path>`, `--paths` for scripting). |
| `dart run revali up` | Run every service at once, ports assigned from `--base-port` and passed as `PORT` (`--root`, `--only <name>`). |
| `dart run revali compose` | Generate a `docker-compose.yaml` for every service (`--root`, `-o <path>`, `--base-port`, `--stdout`). |

While `revali dev` is running (TTY): `r` regenerate+restart, `c` clear status board, `q` quit. Without a TTY, write `reload`/`clear`/`quit` to `.revali_cmd`.

`revali up` draws a TUI with a terminal: `↑`/`↓` and `1`-`9` select a service, `j`/`k`/`g` scroll its log pane, `r`/`c`/`q` act on it, `R`/`C`/`Q` on the whole fleet, `s` restarts a dead one, `Ctrl-C` stops everything. Without a terminal it prints flat, name-prefixed output.
""",
  'revali-app.mdc': """
---
description: Revali app config — @App, dependency injection, flavors, default responses, database integration
globs: routes/**/*_app.dart
alwaysApply: false
---

# Revali App & Dependency Injection

Every Revali app has a class annotated `@App()` extending `AppConfig`, in a `*_app.dart` file under `routes/`.

```dart
import 'package:revali_router/revali_router.dart';

@App()
final class MainApp extends AppConfig {
  const MainApp() : super(
    host: 'localhost',
    port: 8080,
    prefix: '/api',
  );

  @override
  Future<void> configureDependencies(DI di) async {
    // Register your dependencies here
  }
}
```

- `host`/`port` required; `prefix` optional, prepended to every controller route.
- URL shape: `{host}:{port}{prefix}/{controller-path}/{method-path}`.
- Multiple `AppConfig` subclasses can coexist (e.g. a public API app and an admin app on different ports).
- Override `trustedProxy` (`TrustedProxy(headers: [...])`) so `request.ip`/`@Ip()` resolve behind a reverse proxy.
- HTTPS locally: `revali dev --cert path.pem --key key.pem`, or `AppConfig.secure(securityContext: ...)` for mutual TLS.

## Dependency Injection

```dart
@override
Future<void> configureDependencies(DI di) async {
  di.registerLazySingleton<DatabaseConnection>(() => DatabaseConnection.fromEnv());
  di.registerLazySingleton<IUserRepository>(UserRepository.new);
  di.registerLazySingleton<IUserService>(UserService.new);
  di.registerFactory<Logger>(() => Logger.withTimestamp());
  di.registerSingleton<AppConfig>(this);
}
```

| Method | Behavior | Use for |
| --- | --- | --- |
| `registerLazySingleton<T>` | One instance, created on first use | expensive/stateless shared resources |
| `registerSingleton<T>` | Registers an already-built instance | config objects, pre-initialized resources |
| `registerFactory<T>` | New instance every resolution | stateful/transient objects |

Controllers/lifecycle components resolve constructor args automatically (`@Dep()` implicit there). For a compile-time-constant annotation argument needing a runtime dependency, extend `Inject`:

```dart
final class InjectService extends Inject implements Service {
  const InjectService();
}
```

For per-request state (a transaction), use `RequestScopedDI` inside a request wrapper: `RequestScopedDI.current.registerSingleton<Transaction>(...)`, resolved via `RequestScopedDI.getFrom<MyService>(appDi)`.

## App Configuration

| Concept | Summary |
| --- | --- |
| **Flavors** | `@App(flavor: 'development')`; select with `revali dev --flavor=development` / `revali build --flavor=production`. |
| **Default responses** | Override `defaultResponses` for `internalServerError`, `notFound`, `failedCorsOrigin`, `failedCorsHeaders`. |
| **Env vars** | Runtime: `Env.current.string/require/integer/boolean/uri` (empty counts as unset; malformed throws). `super.fromEnv()` reads `HOST`/`PORT`, defaulting to `0.0.0.0:8080`. `.env`/`--dart-define` stay compile-time (`String.fromEnvironment`). |
| **Workers** | `workers: N` runs N isolates on one port; they share no memory, so caches/counters/statics are per isolate. `IsolateIdentity.current.isWorker` guards once-per-process work. |
| **Shutdown & probes** | `SIGTERM` drains consumers then HTTP (`drainDelay`, `shutdownTimeout`, `onServerStopped`); `/healthz` and `/readyz` come from the `health` getter. |
| **Compression** | Gzip is on by default (`compression` getter); disable with `const CompressionSettings.disabled()`. |
| **CORS** | All origins allowed by default; scope with `@AllowOrigins({'https://myapp.com'})` (`.noInherit(...)`, `.all()`). |

## Database Integration

No built-in ORM — register a plain repository as a lazy singleton (closure needed since it takes a constructor arg):

```dart
@override
Future<void> configureDependencies(DI di) async {
  di
    ..registerLazySingleton<Database>(sqlite3.openInMemory)
    ..registerLazySingleton<TodoRepository>(() => TodoRepository(di.get<Database>()));
}
```

The instance persists across requests (lazy singleton, not per-request) — for genuinely per-request resources, use `RequestScopedDI` instead.
""",
  'revali-controllers.mdc': r"""
---
description: Revali controllers — @Controller, HTTP methods, binding, implied binding, pipes, request
globs: routes/**/*_controller.dart
alwaysApply: false
---

# Revali Controllers, Binding & Pipes

Controllers live in `routes/`, must end in `_controller.dart`/`.controller.dart`, annotated `@Controller('basePath')`.

```dart
@Controller('users')
class UsersController {
  const UsersController(this._userService);
  final UserService _userService;

  @Get()
  Future<List<User>> getUsers() async => _userService.getAllUsers();

  @Get(':id')
  Future<User> getUser(@Param() String id) async => _userService.getUserById(id);

  @Post()
  Future<User> createUser(@Body() CreateUserRequest request) async =>
      _userService.createUser(request);
}
```

Method annotations: `@Get()`, `@Post()`, `@Put()`, `@Patch()`, `@Delete()`, `@SSE()`, `@WebSocket()` — one per endpoint. Path params use `:name` (controller-level too: `@Controller('shops/:shopId')`), always `String`, required, URL-decoded. Constructor injection uses the **first public constructor**; controllers are **singletons by default** (`type: InstanceType.factory` for per-request instances).

## Binding

| Annotation | Purpose |
| --- | --- |
| `@Param()` | Path parameter |
| `@Query()` | Query parameter (`.all()` for `List<String>`) |
| `@Header()` | Request header (`.all()` for `List<String>`) |
| `@Ip()` | Resolved client IP |
| `@Body()` | Request body (whole or `@Body(['data','email'])` nested key) |
| `@Dep()` | Dependency injection |
| `@Data()` | Value from the request's Data Handler |

Only one binding annotation per parameter. Body JSON auto-converts to typed objects via a `fromJson(Map<String, dynamic>)` factory (single argument). `@Param()`/`@Query()`/`@Header()` are always `String` — use a pipe to convert.

## Implied Binding

No annotation needed for: `Request`, `RequestHeaders`, `RequestCookies`, `Response`, `Headers`, `Cookies`, `SetCookies`, `DI`, `Meta`, `RouteEntry`, `Data`, `CleanUp`, `Reflect`, `Context`. Prefer scoped bindings in endpoints for testability; implied types are most useful in lifecycle components.

## Pipes

```dart
class UserPipe implements Pipe<String, User> {
  const UserPipe({required this.userService});
  final UserService userService;

  @override
  Future<User> transform(String value, Context context) async {
    final user = await userService.getUserById(value);
    if (user == null) throw NotFoundException('User not found: $value');
    return user;
  }
}
```

```dart
@Get(':id')
Future<User> getUser(@Param.pipe(UserPipe) User user) async => user;
```

Scaffold with `dart run revali create pipe`. Use `fromJson` for plain sync parsing; use a pipe for validation, async work, or DB lookups.

## Request

**Body** — lazily resolved (`StringBodyData`/`JsonBodyData`/`FormDataBodyData`/`BinaryBodyData` by content-type). `@Body()` resolves automatically in endpoints; elsewhere call `await context.request.resolvePayload()` first.

**Client IP** — `request.ip` / `@Ip()`. Behind a proxy, override `trustedProxy` on `AppConfig` (`TrustedProxy(headers: ['X-Forwarded-For'])`, right-to-left by default, `useLeftmostIp: true` to flip). Pair with `@PreventHeaders({...})` so clients can't spoof it.
""",
  'revali-lifecycle.mdc': """
---
description: Revali lifecycle components — middleware, guards, interceptors, exception catchers, authentication
globs: lib/components/**
alwaysApply: false
---

# Revali Lifecycle Components

A plain class `implements LifecycleComponent`; method **return type** determines its role:

| Return type | Role |
| --- | --- |
| `WrapperResult` | Request Wrapper |
| `GuardResult` | Guard |
| `MiddlewareResult` | Middleware |
| `InterceptorPreResult` | Interceptor (pre) |
| `InterceptorPostResult` | Interceptor (post) |
| `ExceptionCatcherResult<Exception>` | Exception Catcher |

```dart
class RequireApiKey implements LifecycleComponent {
  const RequireApiKey();

  MiddlewareResult checkApiKey(@Header('X-Api-Key') String? apiKey, Data data) {
    if (apiKey == null) {
      return const MiddlewareResult.stop(statusCode: 401, body: 'Missing X-Api-Key header');
    }
    data.add(apiKey);
    return const MiddlewareResult.next();
  }
}
```

Register as an annotation on the app/controller/endpoint: `@RequireApiKey()`, or by type when a compile-time constant argument isn't possible: `@LifecycleComponents([RequireApiKey])` (classic equivalents: `@Middlewares`, `@Guards`, `@Intercepts`, `@Catches`).

**Order**: Request → Wrapper (pre) → Observer (pre) → Middleware → Guard → Interceptor (pre) → Pipes → Endpoint → Interceptor (post) → Wrapper (post) → Observer (post) → Response. Several stacked on one endpoint: pre-phases top-to-bottom, post-phases bottom-to-top.

## Guards & Authentication

```dart
class RequireAuth implements LifecycleComponent {
  const RequireAuth();

  GuardResult checkAuth(@Header('Authorization') String? authorization, Data data) {
    if (authorization == null || !authorization.startsWith('Bearer ')) {
      return const GuardResult.block(statusCode: 401, body: 'Missing or invalid Authorization header');
    }
    final token = authorization.substring('Bearer '.length);
    if (!isValidToken(token)) {
      return const GuardResult.block(statusCode: 401, body: 'Invalid token');
    }
    data.add(token);
    return const GuardResult.pass();
  }
}
```

Apply `@RequireAuth()` at controller/app level. Stack a second role-checking guard (reading the `Data` the first stored) for authorization. Swap hardcoded checks for an injected auth service via DI in real apps.

## Error Handling

```dart
class NotFoundCatcher implements LifecycleComponent {
  const NotFoundCatcher();

  ExceptionCatcherResult<NotFoundException> catchNotFound(NotFoundException exception) {
    return ExceptionCatcherResult.handled(
      statusCode: 404,
      body: {'error': exception.message},
    );
  }
}
```

Register at app/controller level to cover every route beneath it. `ExceptionCatcherResult.unhandled()` passes to the next matching catcher. `DefaultExceptionCatcher` (classic form, scoped to app level) catches anything else unhandled. Unhandled exceptions default to `500`, customizable via `defaultResponses`. `MissingArgumentException` already maps to `400`. Debug mode adds a `__DEBUG__` field with exception + stack trace (stripped in profile/release).
""",
  'revali-constructs.mdc': '''
---
description: Revali constructs — revali_server, revali_client, revali_swagger, revali_docker
globs: pubspec.yaml
alwaysApply: false
---

# Revali Constructs

A **construct** is a standalone Dart package, added as a dependency and auto-detected by Revali, that generates code into its own `.revali/<name>/` directory from your routes and annotations. Enable/disable and configure via `revali.yaml` (see `revali-overview.mdc`).

| Construct | Generates |
| --- | --- |
| `revali_server` (built in) | The HTTP server implementation — routing, middleware pipeline, request/response handling. Nothing to install. |
| `revali_client` | A type-safe Dart client SDK mirroring your controllers, with HTTP interceptors, storage, and `get_it` DI integration. |
| `revali_swagger` | An OpenAPI 3.0.3 spec (`swagger.yaml`/`swagger.json`), enrichable with `@ApiSummary`/`@ApiDescription`/`@ApiTag`/`@ApiResponse`/`@ApiType`. |
| `revali_docker` | A multi-stage production `Dockerfile` compiling your server to a native executable (or copying a pre-cross-compiled one). |

Constructs are **Build Constructs** (run during `revali build`, produce deployment artifacts) or **Generic Constructs** (run during `revali dev`/`revali build`, output to `.revali/<name>/`). Authoring your own construct is covered by the `create-constructs` docs — not fully reproduced here.
''',
};
