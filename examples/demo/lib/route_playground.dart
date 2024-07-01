import 'dart:convert';
import 'dart:io';

import 'package:examples/repos/repo.dart';
import 'package:examples/utils/logger.dart';
import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import 'user.controller.dart' as user_controller;

void main() async {
  _registerDependencies();
  _registerControllers();

  hotReload(createServer);
}

Future<HttpServer> createServer() async {
  final server =
      await io.serve(Cascade().add(_root()).handler, 'localhost', 8123);

  // Enable content compression
  server.autoCompress = true;

  print('Serving at http://${server.address.host}:${server.port}');

  return server;
}

void _registerDependencies() {
  DI.instance.registerLazySingleton<Repo>(Repo.new);
  DI.instance.registerLazySingleton<Logger>(Logger.new);
}

void _registerControllers() {
  DI.instance.registerLazySingleton<user_controller.ThisController>(
    () => user_controller.ThisController(DI.instance.get(), DI.instance.get()),
  );
}

Handler _root() {
  return Pipeline().addHandler(
    Cascade()
        // mount passes on all requests
        .add(Router()..mount('/user', (context) => user()(context)))
        .handler,
  );
}

Handler user() {
  final controller = DI.instance.get<user_controller.ThisController>();

  return Router()
    ..add('GET', '/', (context) => _userListPeople(controller)(context))
    ..add('GET', '/<id>', (context) => _userGetNewPerson(controller)(context))
    ..add('POST', '/create', (context) => _userCreate(controller)(context));
}

Handler _userListPeople(user_controller.ThisController controller) {
  return Pipeline().addHandler((context) {
    controller.listPeople();

    return Response.ok('listPeople');
  });
}

Handler _userCreate(user_controller.ThisController controller) {
  return Pipeline().addHandler((context) {
    // controller.create();

    return Response(201);
  });
}

Handler _userGetNewPerson(user_controller.ThisController controller) {
  return Pipeline().addHandler((context) {
    final name = context.url.queryParameters['name'];
    if (name == null) {
      throw Exception('name is required');
    }

    final idPathParam = context.params['id']!;

    final result = controller.getNewPerson(name: name, id: idPathParam);

    return Response.ok(jsonEncode({
      'data': result,
    }));
  });
}
