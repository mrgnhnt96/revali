import 'dart:io';

import 'package:revali_router/revali_router.dart';

void main() async {
  final server = await HttpServer.bind(
    'localhost',
    8080,
  );

  final router = Router(
    routes: [
      Route(
        '',
        method: 'GET',
        handler: (context) async {},
      ),
      Route(
        'user',
        catchers: const [],
        routes: [
          Route(
            ':id',
            catchers: const [],
            guards: const [],
            handler: (context) async {
              context.response.statusCode = 200;
              context.response.body = {'id': 'hi'};
            },
            interceptors: const [],
            meta: (m) {},
            method: 'GET',
            middlewares: const [],
            routes: const [],
          ),
          Route(
            '',
            method: 'POST',
            handler: (context) async {
              final body = context.request.body;
              print(body);

              context.response.statusCode = 200;
              context.response.body = {'id': 'hi'};
            },
          ),
        ],
      ),
    ],
  );

  handleRequests(
    server,
    router.handle,
    router.responseHandler,
  ).ignore();

  print('Serving at http://${server.address.host}:${server.port}');
}
