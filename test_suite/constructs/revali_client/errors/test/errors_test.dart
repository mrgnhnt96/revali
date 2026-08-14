import 'package:revali_client/revali_client.dart';
import 'package:revali_client_errors/revali_client_errors.dart';
import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('errors across the hop', () {
    late TestServer server;
    late Server client;

    setUp(() async {
      server = TestServer();
      client = Server(client: TestClient(server, (_) {}));
      await createServer(server);
    });

    tearDown(() => server.close());

    test('a structured error arrives with its code', () async {
      // The whole point of the feature: the caller branches on `code` rather
      // than on a status shared by every other 404, or on a sentence.
      final exception = await client.errors.structured().then<Object?>(
        (_) => null,
        onError: (Object e) => e,
      );

      expect(exception, isA<ServerException>());
      final error = exception! as ServerException;

      expect(error.statusCode, 404);
      expect(error.code, 'user_not_found');
      expect(error.reason, 'No user with that id');
      expect(error.details, {'id': 7});
      expect(error.isStructured, isTrue);
    });

    test('carries the status the error chose', () async {
      final exception = await client.errors.bare().then<Object?>(
        (_) => null,
        onError: (Object e) => e,
      );

      final error = exception! as ServerException;

      expect(error.statusCode, 409);
      expect(error.code, 'already_exists');
      expect(error.details, isNull);
    });

    test('an ordinary exception is still an untyped failure', () async {
      final exception = await client.errors.unstructured().then<Object?>(
        (_) => null,
        onError: (Object e) => e,
      );

      final error = exception! as ServerException;

      // Nothing about the framework's plain-text defaults changed, so a
      // handler that throws something else behaves exactly as before.
      expect(error.statusCode, 500);
      expect(error.isStructured, isFalse);
      expect(error.code, isNull);
    });
  });
}
