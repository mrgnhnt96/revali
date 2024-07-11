part of '../server.dart';

Route some(Some some) {
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
