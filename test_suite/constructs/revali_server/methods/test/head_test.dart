import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('methods HEAD', () {
    late TestServer server;

    setUp(() async {
      server = TestServer();
      await createServer(server);
    });

    tearDown(() {
      server.close();
    });

    test(
      'explicit @Head answers HEAD even when @Get is declared first',
      () async {
        final response = await server.send(method: 'HEAD', path: '/api/head');

        expect(response.statusCode, 200);
        expect(response.headers.values['x-handler'], 'head');
        expect(response.body, isNull);
      },
    );

    test('@Get still answers GET on the same path', () async {
      final response = await server.send(method: 'GET', path: '/api/head');

      expect(response.statusCode, 200);
      expect(response.headers.values['x-handler'], 'get');
      expect(response.body, {'data': 'Hello world!'});
    });

    test(
      'explicit @Head answers HEAD on a sub-path when @Get is declared first',
      () async {
        final head = await server.send(method: 'HEAD', path: '/api/head/both');

        expect(head.statusCode, 200);
        expect(head.headers.values['x-handler'], 'head');
        expect(head.body, isNull);

        final get = await server.send(method: 'GET', path: '/api/head/both');

        expect(get.statusCode, 200);
        expect(get.headers.values['x-handler'], 'get');
        expect(get.body, {'data': 'Hello world!'});
      },
    );

    test('explicit @Head answers HEAD when declared before @Get', () async {
      final head = await server.send(method: 'HEAD', path: '/api/head-first');

      expect(head.statusCode, 200);
      expect(head.headers.values['x-handler'], 'head');
      expect(head.body, isNull);

      final get = await server.send(method: 'GET', path: '/api/head-first');

      expect(get.statusCode, 200);
      expect(get.headers.values['x-handler'], 'get');
      expect(get.body, {'data': 'Hello world!'});
    });

    test('@Get answers HEAD without a body when no @Head exists', () async {
      final response = await server.send(
        method: 'HEAD',
        path: '/api/head/get-only',
      );

      expect(response.statusCode, 200);
      // The GET handler is not invoked for an automatic HEAD response.
      expect(response.headers.values['x-handler'], isNull);
      expect(response.body, isNull);
    });
  });
}
