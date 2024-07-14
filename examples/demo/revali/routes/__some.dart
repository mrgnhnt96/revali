part of '../server.dart';

Route some(
  Some some,
  DI di,
) {
  return Route(
    'some',
    routes: [
      Route(
        '',
        method: 'GET',
        handler: (context) async {
          some.get();
        },
      )
    ],
  );
}
