import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router/revali_router.dart';

import '../../routes/hello_controller.dart';

part 'definitions/__public.dart';
part 'definitions/__reflects.dart';
part 'definitions/__routes.dart';
part 'routes/__hello.dart';

void main() {
  hotReload(createServer);
}

Future<HttpServer> createServer() async {
  final app = AppConfig.defaultApp();
  late final HttpServer server;
  try {
    server = await HttpServer.bind(
      app.host,
      app.port,
      shared: true,
    );
  } catch (e) {
    print('Failed to bind server:\n$e');
    exit(1);
  }

  final di = DIImpl();
  try {
    await app.configureDependencies(di);
    di.finishRegistration();
  } catch (e) {
    print('Failed to configure dependencies:\n$e');
    return server;
  }

  Iterable<Route> _routes;
  try {
    _routes = routes(di);
  } catch (e) {
    print('Failed to create routes:\n$e');
    return server;
  }

  if (app.prefix case final prefix? when prefix.isNotEmpty) {
    _routes = [
      Route(
        prefix,
        routes: _routes,
      )
    ];
  }

  final router = Router(
    debug: true,
    routes: [
      ..._routes,
      ...public,
    ],
    reflects: reflects,
    defaultResponses: app.defaultResponses,
  );

  handleRequests(
    server,
    router.handle,
  ).ignore();

  app.onServerStarted(server);

  return server;
}
