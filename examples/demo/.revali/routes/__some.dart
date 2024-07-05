part of '../server.dart';

Route some(Some some) {
  return Route(
    'some',
    data: const [],
    guards: const [],
    interceptors: const [],
    middlewares: const [],
    redirect: null,
    meta: (m) {},
    routes: [
      Route(
        '',
        data: const [],
        guards: const [],
        interceptors: const [],
        middlewares: const [],
        redirect: null,
        meta: (m) {},
        method: 'GET',
        handler: (context) async {
          some.get();
        },
      )
    ],
  );
}
