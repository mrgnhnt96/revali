import 'package:revali_router/src/request/request_context.dart';
import 'package:revali_router/src/route.dart';
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
    routes: [
      Route(
        ':id',
        method: 'GET',
        handler: (context) async {},
      ),
      Route(
        '',
        method: 'GET',
        handler: (context) async {},
      ),
    ],
  ),
];
