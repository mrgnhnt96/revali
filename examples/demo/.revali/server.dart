import 'dart:io';
import 'dart:convert';
import 'package:examples/repos/repo.dart';
import 'package:examples/utils/logger.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:revali_router/revali_router.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_construct/revali_construct.dart';
import '../routes/user.controller.dart';
import '../routes/some.controller.dart';

part 'routes/__user.dart';
part 'routes/__some.dart';

void main() {
  hotReload(createServer);
}

Future<HttpServer> createServer() async {
  final server = await io.serve(
    (context) async {
      final requestContext = RequestContext(context);
      final router = Router(
        requestContext,
        routes: routes,
      );

      final response = await router.handle();

      return response;
    },
    'localhost',
    8123,
  );

  // ensure that the routes are configured correctly
  routes;

  print('Serving at http://${server.address.host}:${server.port}');

  return server;
}

List<Route> get routes => [
      user(ThisController()),
      some(Some()),
    ];