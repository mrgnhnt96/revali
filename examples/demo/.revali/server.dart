import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router/revali_router.dart';

import '../routes/file.controller.dart';
import '../routes/some.controller.dart';
import '../routes/user.controller.dart';

part 'definitions/__public.dart';
part 'definitions/__reflects.dart';
part 'definitions/__routes.dart';
part 'routes/__file.dart';
part 'routes/__some.dart';
part 'routes/__user.dart';

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
  await app.configureDependencies(di);
  di.finishRegistration();

  var _routes = routes(di);
  if (app.prefix case final prefix? when prefix.isNotEmpty) {
    _routes = [
      Route(
        prefix,
        routes: _routes,
      )
    ];
  }

  final router = Router(
    routes: [
      ..._routes,
      ...public,
    ],
    reflects: reflects,
  );

  handleRequests(
    server,
    router.handle,
  );

  app.onServerStarted(server);

  return server;
}