/// Every code sample on the page, in one place.
///
/// These are marketing samples, but they are not invented: each one is either
/// lifted from `doc-site/content/` or written against the API documented there.
/// If the framework's surface changes, this file is what goes stale — keep the
/// doc path in the comment above each snippet so the check is a diff, not a
/// hunt.
library;

// ---------------------------------------------------------------------------
// The one source of truth, and the four things generated from it.
// ---------------------------------------------------------------------------

/// The hero snippet. Lines are kept under ~46 characters: the hero code column
/// is the narrowest one on the page, and anything longer scrolls sideways in
/// the first thing a visitor looks at.
///
/// Source: content/revali/getting-started/create-your-first-endpoint.md
const source = '''
@Controller('users')
class UsersController {
  const UsersController(this.users);

  final UserService users;

  @Get()
  Future<List<User>> all() => users.all();

  @Get(':id')
  Future<User> byId(@Param() String id) {
    return users.find(id);
  }

  @Post()
  @StatusCode(201)
  Future<User> create(@Body() NewUser body) {
    return users.create(body);
  }
}
''';

/// Source: content/revali/cli/routes.md — the documented `revali routes`
/// output format, listing the three endpoints in [source].
const routeTable = '''
prefix: /api  (3 routes)

GET     /api/users      →  UsersController.all
GET     /api/users/:id  →  UsersController.byId
POST    /api/users      →  UsersController.create
''';

/// Source: content/constructs/revali_client/index.md and generated-code.md.
/// The package is `client` by default, body parameters are named, and models
/// come from the package both sides share ("Sharing types"): `client.dart`
/// does not export them. Checked by generating a client from [source] and
/// analyzing this against it.
const client = '''
// .revali/revali_client — generated, then added
// to your Flutter app as a path dependency.
import 'package:client/client.dart';
import 'package:models/models.dart';

final server = Server();

// The same names. The same types.
// No HTTP written by hand, on either side.
final users = await server.users.all();

final ada = await server.users.create(
  body: NewUser(
    name: 'Ada',
    email: 'ada@revali.dev',
  ),
);
''';

/// Source: content/constructs/revali_swagger/index.md
const openapi = '''
openapi: 3.0.3
info:
  title: API
  version: 1.0.0
paths:
  /users:
    get:
      operationId: users_all
      tags:
        - users
      responses:
        '200':
          description: Success
          content:
            application/json:
              schema:
                type: array
                items:
                  \$ref: '#/components/schemas/User'
    post:
      operationId: users_create
      requestBody:
        required: true
        content:
          application/json:
            schema:
              \$ref: '#/components/schemas/NewUser'
''';

/// Source: content/constructs/revali_docker/index.md
const dockerfile = '''
# Stage 1: Build environment
FROM dart:stable AS build

WORKDIR /app
COPY . .
RUN dart pub get

# Build the server with Revali
RUN dart run revali build --release

# Compile to native executable
RUN dart compile exe .revali/server/server.dart \\
  -o /app/server

# Stage 2: Runtime environment
FROM alpine:latest
RUN apk add --no-cache libc6-compat ca-certificates
COPY --from=build /app/server /app/bin/server

CMD ["/app/bin/server"]
''';

// ---------------------------------------------------------------------------
// Feature samples.
// ---------------------------------------------------------------------------

/// The headline idea of the preferred middleware API: the *return type* of a
/// method is what decides which stage of the request it runs in.
///
/// Source: content/constructs/revali_server/lifecycle-components/components.md
const lifecycle = '''
class Session implements LifecycleComponent {
  const Session(this.tokens);

  final TokenService tokens;

  // A Guard: it can stop the request.
  Future<GuardResult> authenticated(
    @Header('authorization') String? auth,
  ) async {
    if (await tokens.valid(auth)) {
      return const GuardResult.pass();
    }

    return const GuardResult.block(statusCode: 401);
  }

  // An Interceptor: it runs after the handler.
  InterceptorPostResult timing(Context context) {
    context.response.headers['x-served-by'] = 'revali';
  }
}
''';

/// Source: content/constructs/revali_server/core/binding.md and the
/// `@Body`/`@Query`/`@Param`/`@Header`/`@Cookie` reference pages.
const binding = '''
@Get('search')
Future<Page<User>> search(
  @Query() String q,
  @Query('page') int page,
  @Header('accept-language') String? locale,
  @Cookie('session') String? session,
) async {
  return users.search(q, page: page);
}
''';

/// Source: content/constructs/revali_server/response/websockets.md
const websocket = '''
@Controller('chat')
class ChatController {
  const ChatController();

  @WebSocket('messages')
  String handle(@Body() String message) {
    return 'Echo: \$message';
  }
}
''';

/// Source: content/constructs/revali_server/response/server-sent-events.md
const sse = '''
@Controller('events')
class EventController {
  const EventController();

  @SSE('live')
  Stream<String> live(CleanUp cleanUp) async* {
    cleanUp.add(feed.dispose);

    yield* feed.stream;
  }
}
''';

/// Source: content/revali/app-configuration/configure-dependencies.md
const di = '''
@App()
final class MainApp extends AppConfig {
  const MainApp() : super(port: 8080);

  @override
  Future<void> configureDependencies(DI di) async {
    di.registerSingleton(await Database.connect());
    di.registerLazySingleton<UserService>(UserServiceImpl.new);
    di.registerFactory<Mailer>(SmtpMailer.new);
  }
}
''';

/// Source: content/create-constructs/core/build-construct.md
const construct = '''
final class GraphQlConstruct extends BuildConstruct {
  const GraphQlConstruct();

  @override
  BuildDirectory generate(
    RevaliBuildContext context,
    MetaServer server,
  ) {
    // Every route, every annotation, every type
    // — the same input the built-in server uses.
    return BuildDirectory(files: const []);
  }
}
''';

// ---------------------------------------------------------------------------
// Terminal.
// ---------------------------------------------------------------------------

const installCommand = 'dart pub add revali_router dev:revali';
const runCommand = 'dart run revali dev';

/// Source: content/revali/cli/dev.md — the documented status board.
const statusBoard = '''
Serving at http://localhost:8080/api
Press: r reload, c clear, q quit
''';

// ---------------------------------------------------------------------------
// Quickstart.
// ---------------------------------------------------------------------------

/// Source: content/revali/getting-started/installation.md
const quickstartInstall = '''
dart create -t console my_api
cd my_api
dart pub add revali_router
dart pub add --dev revali
''';

/// Saved at [quickstartControllerPath].
///
/// Source: content/revali/getting-started/create-your-first-endpoint.md
const quickstartController = '''
import 'package:revali_router/revali_router.dart';

@Controller('hello')
class HelloController {
  const HelloController();

  @Get()
  String world() => 'Hello, world!';
}
''';

const quickstartControllerPath = 'routes/controllers/hello_controller.dart';

const quickstartRun = 'dart run revali dev';

const quickstartUrl = 'http://localhost:8080/api/hello';
