import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_router_core/revali_router_core.dart';

import '../routes/dev.app.dart';
import '../routes/file.controller.dart';
import '../routes/some.controller.dart';
import '../routes/user.controller.dart';

part 'routes/__file.dart';
part 'routes/__some.dart';
part 'routes/__user.dart';

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
      final di = DI();
      app.configureDependencies(di);
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
        context,
        routes: [
          ..._routes,
          ...public,
        ],
        reflects: reflects,
      );

      final response = await router.handle();

      di.dispose();

      return response;
    },
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
        handler: (EndpointContext context) async {
          final file = File(p.join(
            'public',
            'favicon.png',
          ));

          context.response.body = file;
        },
      )
    ];
