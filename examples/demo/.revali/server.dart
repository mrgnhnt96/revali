import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf_io.dart' as io;
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
  final server = await io.serve(
    (context) async {
      final requestContext = RequestContext(context);

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
        requestContext,
        routes: _routes,
        reflects: reflects,
      );

      final response = await router.handle();

      return response;
    },
    app.host,
    app.port,
  );

  // ensure that the routes are configured correctly
  routes;

  app.onServerStarted?.call(server);

  return server;
}

List<Route> get routes => [
      user(ThisController(
        repo: DI.instance.get(),
        logger: DI.instance.get(),
      )),
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