part of '../server.dart';

Route user(ThisController thisController) {
  return Route(
    'user',
    middlewares: [Auth(AuthType.user)],
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
        catchers: [NotAuthCatcher('bye')],
        combine: [AuthCombine()],
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
            data: (jsonDecode((await context.request.body) ?? '')
                    as Map<String, dynamic>)['name'] ??
                (throw 'Missing value!'),
          );
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
