part of '../server.dart';

Route user(ThisController thisController) {
  return Route(
    'user',
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
          final result = await thisController.listPeople();
        },
      ),
      Route(
        ':id',
        catchers: const [NotAuthCatcher('hi')],
        data: const [],
        guards: const [],
        interceptors: const [],
        middlewares: const [],
        redirect: null,
        meta: (m) {},
        method: 'GET',
        handler: (context) async {
          final result = thisController.getNewPerson();
        },
      ),
      Route(
        'create',
        data: const [],
        guards: const [],
        interceptors: const [],
        middlewares: const [],
        redirect: null,
        meta: (m) {},
        method: 'POST',
        handler: (context) async {
          thisController.create();
        },
      ),
    ],
  );
}
