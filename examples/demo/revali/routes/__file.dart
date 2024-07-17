part of '../server.dart';

Route file(
  FileUploader fileUploader,
  DI di,
) {
  return Route(
    'file',
    routes: [
      Route(
        '',
        method: 'POST',
        handler: (context) async {
          fileUploader.uploadFile();
        },
      )
    ],
  );
}
