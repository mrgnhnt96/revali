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
      ),
      Route(
        '',
        method: 'GET',
        handler: (context) async {
          final file = File('static/file.txt');
          final bytes = await file.readAsBytes();

          context.response.body = MemoryFile(bytes, mimeType: 'text/plain');
        },
      )
    ],
  );
}
