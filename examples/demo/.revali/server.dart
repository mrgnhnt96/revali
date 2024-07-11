import 'dart:io';
import 'dart:convert';
import 'package:revali_router/revali_router.dart';
import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_construct/revali_construct.dart';
import '../routes/user.controller.dart';
import '../routes/some.controller.dart';
import '../routes/dev.app.dart';

part 'routes/__user.dart';
part 'routes/__some.dart';

void main() {
  hotReload(createServer);
}

Future<HttpServer> createServer() async {
  final app = DevApp();
  late final HttpServer server;
  try {
    server = await HttpServer.bind(
      app.host,
      app.port,
    );
  } catch (e) {
    print('Failed to bind server:\n$e');
    exit(1);
  }

  handleRequests(
    server,
    (context) async {
      var _routes = routes;
      if (app.prefix case final prefix? when prefix.isNotEmpty) {
        _routes = [
          Route(
            prefix,
            routes: _routes,
          )
        ];
      }

      final router = Router(
        context,
        routes: _routes,
        reflects: reflects,
        globalModifiers: RouteModifiers(catchers: [DumbExceptionCatcher()]),
      );

      final response = await router.handle();

      return response;
    },
  );

  // ensure that the routes are configured correctly
  try {
    routes;
  } catch (e) {
    print('Failed to setup routes:\n$e');
    exit(1);
  }

  app.onServerStarted?.call(server);

  return server;
}

List<Route> get routes => [
      user(ThisController()),
      some(Some()),
    ];

Set<Reflect> get reflects => {
      Reflect(
        User,
        metas: (m) {
          m['id']..add(Role(AuthType.admin));
        },
      )
    };