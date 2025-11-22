import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('methods PATCH', () {
    late TestServer server;

    setUp(() async {
      server = TestServer();
      await createServer(server);
    });

    tearDown(() {
      server.close();
    });

    test('returns a successful response when PATCH request', () async {
      final response = await server.send(method: 'PATCH', path: '/api/patch');

      expect(response.statusCode, 200);
      expect(response.body, {'data': 'Hello world!'});

      final headers = {...response.headers.values};

      expect(
        headers.remove('date'),
        isA<String>().having(DateTime.parse, 'parses to date', isA<DateTime>()),
      );
      expect(
        response.headers.date?.isAfter(
          DateTime.now().subtract(const Duration(milliseconds: 50)),
        ),
        isTrue,
      );

      expect(headers.remove('access-control-allow-credentials'), 'true');
      expect(headers.remove('access-control-allow-origin'), '*');
      expect(headers.remove('access-control-allow-methods'), 'OPTIONS, PATCH');
      expect(headers.remove('allow'), 'OPTIONS, PATCH');
      expect(headers.remove('content-type'), 'application/json');
      expect(headers.remove('content-length'), '23');

      expect(headers, isEmpty);
    });

    test('returns a successful response when OPTIONS request', () async {
      final response = await server.send(method: 'OPTIONS', path: '/api/patch');

      expect(response.statusCode, 200);
      expect(response.body, isNull);
      final headers = {...response.headers.values};

      expect(
        headers.remove('date'),
        isA<String>().having(DateTime.parse, 'parses to date', isA<DateTime>()),
      );
      expect(
        response.headers.date?.isAfter(
          DateTime.now().subtract(const Duration(milliseconds: 50)),
        ),
        isTrue,
      );

      expect(headers.remove('access-control-allow-credentials'), 'true');
      expect(headers.remove('access-control-allow-origin'), '*');
      expect(headers.remove('access-control-allow-methods'), 'OPTIONS, PATCH');
      expect(headers.remove('allow'), 'OPTIONS, PATCH');
      expect(headers.remove('content-type'), 'text/plain');
      expect(headers.remove('transfer-encoding'), 'chunked');

      expect(headers, isEmpty);
    });

    test('returns a 404 response when HEAD request', () async {
      final response = await server.send(method: 'HEAD', path: '/api/patch');

      expect(response.statusCode, 404);
      expect(
        response.body,
        startsWith('''
Not Found

__DEBUG__:
Error: RouteNotFoundException: HEAD api/patch

Stack Trace:
package:revali_router/src/router/router.dart'''),
      );
      final headers = {...response.headers.values};

      expect(
        headers.remove('date'),
        isA<String>().having(DateTime.parse, 'parses to date', isA<DateTime>()),
      );
      expect(
        response.headers.date?.isAfter(
          DateTime.now().subtract(const Duration(milliseconds: 50)),
        ),
        isTrue,
      );

      expect(headers.remove('content-type'), 'text/plain');
      expect(headers.remove('content-length'), '232');

      expect(headers, isEmpty);
    });
  });
}
