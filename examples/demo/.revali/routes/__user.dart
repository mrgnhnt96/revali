part of '../server.dart';

Route user(
  ThisController thisController,
  DI di,
) {
  return Route(
    'user',
    middlewares: [Auth(AuthType.user)],
    allowedOrigins: AllowedOriginsImpl(
      {
        'http://localhost:8080',
        'http://localhost:8081',
      },
      inherit: true,
    ),
    allowedHeaders: AllowedHeadersImpl(
      {'X-UR-AWESOME'},
      inherit: true,
    ),
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
        combine: [
          AuthCombine(),
          OtherCombine(di),
        ],
        meta: (m) {
          m..add(Role(AuthType.admin));
        },
        method: 'GET',
        handler: (context) async {
          await context.request.resolvePayload();

          final result = await thisController.getNewPerson(
            name: await NamePipe().transform(
              context.request.queryParameters['name'] ??
                  (throw 'Missing value!'),
              PipeContextImpl.from(
                context,
                annotationArgument: null,
                nameOfParameter: 'name',
                type: AnnotationType.query,
              ),
            ),
            id: await StringToIntPipe().transform(
              context.request.pathParameters['id'],
              PipeContextImpl.from(
                context,
                annotationArgument: null,
                nameOfParameter: 'id',
                type: AnnotationType.param,
              ),
            ),
            myName: await MyParam().parse(CustomParamContextImpl.from(
              context,
              nameOfParameter: 'myName',
              parameterType: String,
            )),
            data:
                context.request.body.data?['name'] ?? (throw 'Missing value!'),
          );

          context.response.body['data'] = result.toJson();
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
