part of '../server.dart';

Route file(
  FileUploader fileUploader,
  DI di,
) {
  return Route(
    'file',
    routes: [
      Route(
        ':id',
        method: 'POST',
        handler: (context) async {
          fileUploader.uploadFile(ParamPipe().transform(
            context.request.pathParameters['hi'] ?? (throw 'Missing value!'),
            PipeContextImpl.from(
              context,
              arg: 'hi',
              paramName: 'id',
              type: ParamType.param,
            ),
          ));
        },
      )
    ],
  );
}
