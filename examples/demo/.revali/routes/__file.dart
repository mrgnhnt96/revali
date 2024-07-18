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
          fileUploader.uploadFile(await ParamPipe().transform(
            context.request.pathParameters['hi'] ?? (throw 'Missing value!'),
            PipeContextImpl.from(
              context,
              annotationArgument: 'hi',
              nameOfParameter: 'id',
              type: AnnotationType.param,
            ),
          ));
        },
      )
    ],
  );
}
