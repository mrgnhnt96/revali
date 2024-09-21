part of '../server.dart';

Route hello(
  HelloController helloController,
  DI di,
) {
  return Route(
    'hello',
    routes: [
      Route(
        '',
        method: 'GET',
        handler: (context) async {
          final result = helloController.hello();

          context.response.body['data'] = result;
        },
      )
    ],
  );
}
