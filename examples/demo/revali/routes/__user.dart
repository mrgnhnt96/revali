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
        catchers: [NotAuthCatcher(DI.instance.get())],
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

          final result = thisController.getNewPerson(
            name: NamePipe().transform(
              context.request.queryParameters['name']!,
              PipeContextImpl<dynamic>.from(
                context,
                arg: context.request.queryParameters['name']!,
                paramName: 'name',
                type: ParamType.query,
              ),
            ),
            id: StringToIntPipe(DI.instance.get()).transform(
              context.request.pathParameters['id']!,
              PipeContextImpl<dynamic>.from(
                context,
                arg: context.request.pathParameters['id']!,
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
                as Map<String, dynamic>)['name']!,
          );
        },
      ),
      Route(
        'create',
        method: 'POST',
        handler: (context) async {
          thisController.create(context.request.queryParameters['name']!);
        },
      ),
    ],
  );
}
