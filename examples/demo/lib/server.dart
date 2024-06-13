import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

void main() async {
  final handler = Cascade().add(_root()).handler;

  final server = await io.serve(handler, 'localhost', 8123);

  // Enable content compression
  server.autoCompress = true;

  print('Serving at http://${server.address.host}:${server.port}');
}

Handler _root() {
  final pipeline = Pipeline();

  final router = Router()
    ..mount('/hello', (context) {
      if (context.method != 'GET') {
        return Response(405, body: 'Method Not Allowed');
      }

      return _helloHandler(context);
    })
    ..mount('/', (context) {
      if (context.method != 'GET') {
        return Response(405, body: 'Method Not Allowed');
      }

      return Response.ok('Hello, World!');
    });

  return pipeline.addHandler(router);
}

Response _helloHandler(Request request) {
  final name = request.url.queryParameters['name'] ?? 'You';
  return Response.ok('Hello, $name!');
}
