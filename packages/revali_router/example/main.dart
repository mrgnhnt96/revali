import 'package:revali_router/src/exception_catcher/exception_catcher.dart';
import 'package:revali_router/src/exception_catcher/exception_catcher_action.dart';
import 'package:revali_router/src/exception_catcher/exception_catcher_context.dart';
import 'package:revali_router/src/guard/guard.dart';
import 'package:revali_router/src/guard/guard_action.dart';
import 'package:revali_router/src/middleware/middleware.dart';
import 'package:revali_router/src/middleware/middleware_action.dart';
import 'package:revali_router/src/middleware/middleware_context.dart';
import 'package:revali_router/src/request/request_context.dart';
import 'package:revali_router/src/route/route.dart';
import 'package:revali_router/src/router.dart';
import 'package:shelf/shelf_io.dart';

void main() async {
  final server = await serve(
    (context) async {
      final routerContext = RequestContext(context);
      final router = Router(routerContext, routes: routes);

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
        method: 'GET',
        middlewares: [AddAuth()],
        guards: [AuthGuard()],
        handler: (context) async {},
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
