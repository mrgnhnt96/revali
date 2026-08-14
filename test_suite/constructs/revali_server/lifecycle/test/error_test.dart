import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('structured errors on a generated server', () {
    late TestServer server;

    setUp(() async {
      server = TestServer();
      await createServer(server);
    });

    tearDown(() => server.close());

    test('an HttpError responds with its status and envelope', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/lifecycle/boom',
      );

      expect(response.statusCode, 409);

      final body = response.body as Map;

      // Asserted on the `error` key rather than the whole body: in debug mode
      // the framework appends `__DEBUG__` with the stack trace to every error
      // body. A client reads `error` and is unaffected either way.
      expect(body['error'], {'code': 'already_exists', 'message': 'Taken'});
    });

    test('debug output sits alongside the envelope, not inside it', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/lifecycle/boom',
      );

      final body = response.body as Map;

      // Nesting the debug payload inside `error` would put an unexpected key
      // in front of every client parsing the envelope.
      expect(body.containsKey('__DEBUG__'), isTrue);
      expect((body['error'] as Map).containsKey('__DEBUG__'), isFalse);
    });
  });
}
