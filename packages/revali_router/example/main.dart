// ignore_for_file: avoid_print

import 'dart:io';

import 'package:revali_router/revali_router.dart';

void main() async {
  final server = await HttpServer.bind(
    'localhost',
    8080,
  );

  handleRequests(server, (context) async {
    final router = Router(
      routes: routes,
      reflects: {
        Reflect(
          User,
          metas: (m) {
            m['user'].add(const Role('admin'));
          },
        ),
      },
    );

    final response = await router.handle(context);

    return response;
  }).ignore();

  print('Serving at http://${server.address.host}:${server.port}');
}

final routes = [
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
        catchers: const [],
        guards: [AuthGuard()],
        handler: (context) async {
          context.response.statusCode = 200;
          context.response.body = {'id': 'hi'};
        },
        interceptors: const [BodyInterceptor()],
        meta: (m) {},
        method: 'GET',
        middlewares: [AddAuth()],
        routes: const [],
      ),
      Route(
        '',
        method: 'POST',
        handler: (context) async {
          final body = context.request.body;
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
  Future<GuardResult> canActivate(
    GuardContext context,
    GuardAction canActivate,
  ) async {
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

class AddAuth implements Middleware {
  @override
  Future<MiddlewareResult> use(
    MiddlewareContext context,
    MiddlewareAction action,
  ) async {
    context.data.add(HasAuth(hasAuth: true));

    return action.next();
  }
}

class HasAuth {
  HasAuth({required this.hasAuth});
  final bool hasAuth;
}

class AuthException implements Exception {}

final class AuthExceptionCatcher extends ExceptionCatcher<AuthException> {
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
