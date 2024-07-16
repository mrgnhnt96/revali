part of '../server.dart';

Route user(
  ThisController thisController,
  DI di,
) {
  return Route(
    'user',
    allowedOrigins: {
      'http://localhost:8080',
      'http://localhost:8081',
    },
    allowedHeaders: {'X-UR-AWESOME'},
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
        meta: (m) {
          m..add(Role(AuthType.admin));
        },
        method: 'GET',
        handler: (context) async {
          await context.request.resolvePayload();

          final result = await thisController.getNewPerson(
            name: NamePipe().transform(
              context.request.queryParameters['name'] ??
                  (throw 'Missing value!'),
              PipeContextImpl.from(
                context,
                arg: null,
                paramName: 'name',
                type: ParamType.query,
              ),
            ),
            id: StringToIntPipe().transform(
              context.request.pathParameters['id'],
              PipeContextImpl.from(
                context,
                arg: null,
                paramName: 'id',
                type: ParamType.param,
              ),
            ),
            myName: MyParam().parse(CustomParamContextImpl.from(
              context,
              name: 'myName',
              type: String,
            )),
            data:
                context.request.body.data?['name'] ?? (throw 'Missing value!'),
          );

          context.response.body = result.toJson();
        },
      ),
      Route.webSocket(
        'create',
        handler: (context) async {
          thisController.create(context.request.queryParametersAll['name']);
        },
        ping: Duration(microseconds: 500000),
      ),
    ],
  );
}
