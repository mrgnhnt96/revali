import 'dart:io';
import 'dart:convert';
import 'package:examples/repos/repo.dart';
import 'package:examples/utils/logger.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:zora_annotations/zora_annotations.dart';
import '../routes/user.controller.dart' as user_controller;
import 'package:zora_construct/zora_construct.dart';

part 'server/__register_dependencies.dart';
part 'server/__register_controllers.dart';

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
        ))
      .handler);
}

Handler user() {
  final controller = DI.instance.get<user_controller.ThisController>();
  return Router();
}