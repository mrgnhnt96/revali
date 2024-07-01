import 'dart:io';
import 'dart:convert';
import 'package:examples/repos/repo.dart';
import 'package:examples/utils/logger.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_construct/revali_construct.dart';
import '../routes/user.controller.dart';
import '../routes/some.controller.dart';

part 'server/__register_dependencies.dart';
part 'server/__register_controllers.dart';
part 'server/handlers/__user.dart';
part 'server/handlers/__some.dart';

void main() async {
  _registerDependencies();
  _registerControllers();
  hotReload(createServer);
}

Future<HttpServer> createServer() async {
  final server = await io.serve(
    Cascade().add(_root()).handler,
    'localhost',
    8123,
  );
  server.autoCompress = true;
  print('Serving at http://${server.address.host}:${server.port}');
  return server;
}

Handler _root() {
  return Pipeline().addHandler(Cascade()
      .add(Router()
        ..mount(
          '/user',
          (context) => user()(context),
        )
        ..mount(
          '/some',
          (context) => some()(context),
        ))
      .handler);
}