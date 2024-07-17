import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_router_core/revali_router_core.dart';
import 'package:revali_router_core/revali_router_core_access_control.dart';
import 'package:revali_router/revali_router.dart';

import '../routes/dev.app.dart';
import '../routes/file.controller.dart';
import '../routes/some.controller.dart';
import '../routes/user.controller.dart';

part 'routes/__user.dart';
part 'routes/__some.dart';
part 'routes/__file.dart';

void main() {
  createServer();
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
    globalModifiers: RouteModifiersImpl(
      catchers: [DumbExceptionCatcher()],
      allowedOrigins: AllowOrigins(
        {'*'},
        inherit: false,
      ),
      allowedHeaders: AllowHeaders(
        {'X-IM-AWESOME'},
        inherit: true,
      ),
    ),
  );

  handleRequests(
    server,
    router.handle,
  );

  app.onServerStarted(server);

  return server;
}

List<Route> routes(DI di) => [
      user(
        ThisController(
          logger: di.get(),
          repo: di.get(),
        ),
        di,
      ),
      some(
        Some(),
        di,
      ),
      file(
        FileUploader(),
        di,
      ),
    ];

Set<Reflect> get reflects => {
      Reflect(
        User,
        metas: (m) {
          m['id']..add(Role(AuthType.admin));
        },
      )
    };

List<Route> get public => [
      Route(
        'favicon.png',
        method: 'GET',
        allowedOrigins: AllowOrigins.all(),
        handler: (context) async {
          context.response.body = File(p.join(
            'public',
            'favicon.png',
          ));
        },
      )
    ];