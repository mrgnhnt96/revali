import 'dart:io';

import 'package:revali_router/revali_router.dart';

void main() async {
  final server = await HttpServer.bind(
    'localhost',
    8080,
  );

  handleRequests(server, (context) async {
    final router = Router(
      routes: [
        Route(
          '',
          method: 'GET',
          handler: (context) async {},
        ),
        Route(
          'user',
          catchers: [],
          routes: [
            Route(
              ':id',
              catchers: [],
              guards: [],
              handler: (context) async {
                context.response.statusCode = 200;
                context.response.body = {'id': 'hi'};
              },
              interceptors: [],
              meta: (m) {},
              method: 'GET',
              middlewares: [],
              routes: [],
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

    final response = await router.handle(context);

    return response;
  }).ignore();

  print('Serving at http://${server.address.host}:${server.port}');
}
