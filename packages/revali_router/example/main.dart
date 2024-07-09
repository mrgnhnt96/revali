import 'package:revali_router/revali_router.dart';
import 'package:shelf/shelf_io.dart';

void main() async {
  final server = await serve(
    (context) async {
      final requestContext = RequestContext(context);
      final router = Router(
        requestContext,
        routes: routes,
        reflects: {
          Reflect(
            User,
            metas: (m) {
              m['user']..add(Role('admin'));
            },
          ),
        },
      );

      final response = await router.handle();

      return response;
    },
    'localhost',
    1234,
  );

  // ensure that the routes are configured correctly
  routes;

  print('Serving at http://${server.address.host}:${server.port}');
}

late final routes = [
  Route(
    '',
    method: 'GET',
    handler: (context) async {},
  ),
  Route(
    'user',
    catchers: [AuthExceptionCatcher()],
    routes: [
      Route(
        ':id',
        catchers: [],
        guards: [AuthGuard()],
        handler: (context) async {
          context.response.statusCode = 200;
          context.response.body = {'id': 'hi'};
        },
        interceptors: [BodyInterceptor()],
        meta: (m) {},
        method: 'GET',
        middlewares: [AddAuth()],
        redirect: null,
        routes: [],
      ),
      Route(
        '',
        method: 'GET',
        guards: [AuthGuard()],
        handler: (context) async {},
      ),
    ],
  ),
];

class AuthGuard extends Guard {
  @override
  Future<GuardResult> canActivate(context, canActivate) async {
    final hasAuth = context.data.get<HasAuth>();

    if (hasAuth case null) {
      throw AuthException();
    }

    if (!hasAuth.hasAuth) {
      return canActivate.no();
    }

    return canActivate.yes();
  }
}

class AddAuth extends Middleware {
  @override
  Future<MiddlewareResult> use(
    MiddlewareContext context,
    MiddlewareAction canActivate,
  ) async {
    context.data.add(HasAuth(true));

    return canActivate.next();
  }
}

class HasAuth {
  final bool hasAuth;

  HasAuth(this.hasAuth);
}

class AuthException implements Exception {}

class AuthExceptionCatcher extends ExceptionCatcher<AuthException> {
  @override
  ExceptionCatcherResult catchException(
    AuthException e,
    ExceptionCatcherContext context,
    ExceptionCatcherAction action,
  ) {
    return action.handled(
      statusCode: 401,
      body: 'Unauthorized',
    );
  }
}

class User {
  const User(this.name);

  final String name;
}

class Role {
  const Role(this.name);

  final String name;
}

class BodyInterceptor extends Interceptor {
  const BodyInterceptor();

  @override
  Future<void> post(InterceptorContext context) async {
    final reflect = context.reflect.get<User>();

    reflect?.meta.entries;

    reflect?.meta['user']?.has<Role>();
  }

  @override
  Future<void> pre(InterceptorContext context) async {}
}
