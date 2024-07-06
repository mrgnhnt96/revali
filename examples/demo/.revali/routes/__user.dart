part of '../server.dart';

Route user(ThisController thisController) {
  return Route(
    'user',
    middlewares: const [Auth(AuthType.user)],
    routes: [
      Route(
        '',
        method: 'GET',
        handler: (context) async {
          await thisController.listPeople();
        },
      ),
      Route(
        ':id',
        catchers: const [NotAuthCatcher('bye')],
        combine: const [AuthCombine()],
        meta: (m) {
          m..add(Role(AuthType.admin));
        },
        method: 'GET',
        handler: (context) async {
          context.response
            ..statusCode = 201
            ..setHeader(
              'method',
              'hi',
            );

          final result = thisController.getNewPerson();
        },
      ),
      Route(
        'create',
        method: 'POST',
        handler: (context) async {
          thisController.create();
        },
      ),
    ],
  );
}
