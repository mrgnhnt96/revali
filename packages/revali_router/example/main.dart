import 'dart:io';

import 'package:revali_router/revali_router.dart';
import 'package:revali_router_core/revali_router_core.dart';

void main() async {
  final server = await HttpServer.bind(
    'localhost',
    8080,
    backlog: 0,
  );

  handleRequests(server, (context) async {
    final router = Router(
      context,
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
  });

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
        method: 'POST',
        handler: (context) async {
          final body = await context.request.body;
          print(body);

          context.response.statusCode = 200;
          context.response.body = {'id': 'hi'};
        },
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
