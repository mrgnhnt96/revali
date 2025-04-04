import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('methods DELETE', () {
    late TestServer server;

    setUp(() async {
      server = TestServer();
      await createServer(server);
    });

    tearDown(() {
      server.close();
    });

    test('returns a successful response when DELETE request', () async {
      final response = await server.send(
        method: 'DELETE',
        path: '/api/delete',
      );

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
      expect(
        headers.remove('access-control-allow-methods'),
        'OPTIONS, DELETE',
      );
      expect(headers.remove('allow'), 'OPTIONS, DELETE');
      expect(headers.remove('content-type'), 'application/json');
      expect(headers.remove('content-length'), '23');

      expect(headers, isEmpty);
    });

    test('returns a successful response when OPTIONS request', () async {
      final response = await server.send(
        method: 'OPTIONS',
        path: '/api/delete',
      );

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
      expect(
        headers.remove('access-control-allow-methods'),
        'OPTIONS, DELETE',
      );
      expect(headers.remove('allow'), 'OPTIONS, DELETE');
      expect(headers.remove('content-type'), 'text/plain');
      expect(headers.remove('transfer-encoding'), 'chunked');

      expect(headers, isEmpty);
    });

    test('returns a 404 response when HEAD request', () async {
      final response = await server.send(
        method: 'HEAD',
        path: '/api/delete',
      );

      expect(response.statusCode, 404);
      expect(response.body, '''
Not Found

__DEBUG__:
Error: RouteNotFoundException: HEAD api/delete

Stack Trace:
package:revali_router/src/router/router.dart 158:34          Router.handle
package:revali_router/src/server/handle_requests.dart 28:14  handleRequests''');
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
      expect(headers.remove('content-length'), '233');

      expect(headers, isEmpty);
    });
  });
}
