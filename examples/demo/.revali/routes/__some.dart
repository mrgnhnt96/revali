part of '../server.dart';

Route some(Some some) {
  return Route(
    'some',
    catchers: const [],
    data: const [],
    guards: const [],
    handler: null,
    interceptors: const [],
    meta: (m) {},
    method: null,
    middlewares: const [],
    redirect: null,
    routes: [
      Route(
        '',
        catchers: const [],
        data: const [],
        guards: const [],
        interceptors: const [],
        meta: (m) {},
        method: 'GET',
        middlewares: const [],
        redirect: null,
        handler: (context) async {
          some.get();
        },
      )
    ],
  );
}
