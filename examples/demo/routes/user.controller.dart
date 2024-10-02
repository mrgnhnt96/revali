import 'package:examples/repos/repo.dart';
import 'package:examples/utils/logger.dart';
import 'package:revali_router/revali_router.dart';

@AllowOrigins({
  'http://localhost:8080',
  'http://localhost:8081',
})
@AllowHeaders({'X-UR-AWESOME'})
@Auth(AuthType.user)
@Controller('user')
class ThisController {
  const ThisController({
    @Dep() required this.logger,
    @Dep() required this.repo,
  });

  final Logger logger;
  final Repo repo;

  @Get()
  Future<void> listPeople() async {}

  @Combines([OtherCombine])
  @AuthCombine()
  @HttpCode(201)
  @SetHeader('method', 'hi')
  @NotAuthCatcher('bye')
  @Role(AuthType.admin)
  @Get(':id')
  Future<User> getNewPerson({
    @Query.pipe(NamePipe) required String name,
    @Param.pipe(StringToIntPipe) required int id,
    @MyParam() required String myName,
    @Body(['name']) required String data,
  }) async {
    final user = User(name, id);

    return user;
  }

  @WebSocket.ping(path: 'create', ping: Duration(milliseconds: 500))
  void create(
    @Query.all() List<String>? name,
  ) {}
}

class StringValue {
  const StringValue(this.value);

  final String value;
}

class NamePipe implements Pipe<String, String> {
  const NamePipe();

  @override
  String transform(String value, PipeContext<dynamic> context) {
    return 'value: ($value)';
  }
}

class Role implements Meta {
  const Role(this.type);

  final AuthType type;
}

class StringToIntPipe implements Pipe<String?, int> {
  const StringToIntPipe();

  @override
  int transform(String? value, PipeContext<dynamic> context) {
    return int.parse(value ?? '0');
  }
}

class User {
  const User(this.name, this.id);

  final String name;
  @Role(AuthType.admin)
  final int id;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': id,
    };
  }
}

class Auth implements Middleware {
  const Auth(this.type);

  final AuthType type;

  String get hi => 'hi';

  @override
  Future<MiddlewareResult> use(
    MiddlewareContext context,
    MiddlewareAction action,
  ) async {
    return action.next();
  }
}

enum AuthType {
  admin,
  user,
}

class AuthRepo {}

class Lazy {
  Lazy();

  String? value;

  String get() {
    return value ??= 'lazy';
  }
}

class NotAuth implements Exception {}

final class NotAuthCatcher extends ExceptionCatcher {
  const NotAuthCatcher(this.value);

  final String value;

  @override
  ExceptionCatcherResult catchException(
    Exception exception,
    ExceptionCatcherContext context,
    ExceptionCatcherAction action,
  ) {
    return action.handled();
  }
}

final class AuthCombine implements CombineComponents {
  const AuthCombine();

  @override
  List<ExceptionCatcher<Exception>> get catchers =>
      [const NotAuthCatcher('bye')];

  @override
  List<Guard> get guards => [];

  @override
  List<Interceptor> get interceptors => [];

  @override
  List<Middleware> get middlewares => [const Auth(AuthType.admin)];
}

final class OtherCombine implements CombineComponents {
  const OtherCombine(this.di);

  final DI di;

  @override
  List<ExceptionCatcher<Exception>> get catchers => [];

  @override
  List<Guard> get guards => [];

  @override
  List<Interceptor> get interceptors => [];

  @override
  List<Middleware> get middlewares => [];
}

class MyParam implements Bind<String> {
  const MyParam();

  @override
  String bind(BindContext context) {
    return context.request.queryParameters['name'] ?? '';
  }
}
