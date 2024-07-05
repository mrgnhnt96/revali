part of '../server.dart';

Route user(ThisController thisController) {
  return Route(
    'user',
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
          final result = await thisController.listPeople();
        },
      ),
      Route(
        ':id',
        catchers: const [],
        data: const [],
        guards: const [],
        interceptors: const [],
        meta: (m) {},
        method: 'GET',
        middlewares: const [],
        redirect: null,
        handler: (context) async {
          final result = thisController.getNewPerson();
        },
      ),
      Route(
        'create',
        catchers: const [],
        data: const [],
        guards: const [],
        interceptors: const [],
        meta: (m) {},
        method: 'POST',
        middlewares: const [],
        redirect: null,
        handler: (context) async {
          thisController.create();
        },
      ),
    ],
  );
}
