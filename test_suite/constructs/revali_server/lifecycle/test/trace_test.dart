import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('trace context on a generated server', () {
    late TestServer server;

    setUp(() async {
      server = TestServer();
      await createServer(server);
    });

    tearDown(() => server.close());

    Future<Map<String, dynamic>> trace({
      Map<String, String> headers = const {},
    }) async {
      final response = await server.send(
        method: 'GET',
        path: '/api/lifecycle/trace',
        headers: headers,
      );

      return (response.body as Map)['data'] as Map<String, dynamic>;
    }

    test('adopts the caller request id', () async {
      // The router installs the context on the serve path the generated
      // server actually uses -- a regression here would leave every real app
      // with a null context while unit tests kept passing.
      final body = await trace(headers: {'X-Request-Id': 'from-caller'});

      expect(body['requestId'], 'from-caller');
    });

    test('generates an id when the caller sent none', () async {
      expect((await trace())['requestId'], matches(RegExp(r'^[0-9a-f]{32}$')));
    });

    test('carries traceparent through', () async {
      final body = await trace(headers: {'traceparent': '00-abc-def-01'});

      expect(body['traceparent'], '00-abc-def-01');
    });

    test('decodes inbound baggage', () async {
      final body = await trace(headers: {'baggage': 'tenant=acme'});

      expect(body['baggage'], {'tenant': 'acme'});
    });

    test('survives an await inside the handler', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/lifecycle/trace-async',
        headers: {'X-Request-Id': 'across-the-gap'},
      );

      expect((response.body as Map)['data'], 'across-the-gap');
    });
  });
}
