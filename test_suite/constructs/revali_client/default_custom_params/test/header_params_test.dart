import 'package:revali_client/revali_client.dart';
import 'package:revali_client_default_custom_params/revali_client_default_custom_params.dart';
import 'package:revali_client_default_custom_params_test/lib/enums/serialized_user_type.dart';
import 'package:revali_client_default_custom_params_test/lib/enums/user_type.dart';
import 'package:revali_client_default_custom_params_test/lib/models/string_user.dart';
import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('header params', () {
    late TestServer server;
    late Server client;
    HttpRequest? request;

    setUp(() {
      server = TestServer();

      client = Server(
        client: TestClient(server, (req) => request = req),
      );

      createServer(server);
    });

    tearDown(() {
      server.close();
    });

    void verifyRequest(String path, {required String method}) {
      final req = request;
      expect(req?.url.path, path);
      expect(req?.method, method);
    }

    test('required', () async {
      final response = await client.headerParams.required();

      expect(response, const StringUser(name: 'John'));
      verifyRequest('/api/header/required', method: 'GET');
      expect(request?.headers['X-User'], isNull);
    });

    test('optional', () async {
      final response = await client.headerParams.optional();

      expect(response, const StringUser(name: 'John'));
      verifyRequest('/api/header/optional', method: 'GET');
      expect(request?.headers['X-User'], isNull);
    });

    test('all', () async {
      final response = await client.headerParams.all();

      expect(response, [
        const StringUser(name: 'John'),
        const StringUser(name: 'Jane'),
      ]);
      verifyRequest('/api/header/all', method: 'GET');
      expect(request?.headers['X-User'], isNull);
    });

    test('all-optional', () async {
      final response = await client.headerParams.allOptional();

      expect(response, [
        const StringUser(name: 'John'),
        const StringUser(name: 'Jane'),
      ]);
      verifyRequest('/api/header/all-optional', method: 'GET');
      expect(request?.headers['X-User'], isNull);
    });

    test('user-type', () async {
      final response = await client.headerParams.userType();

      expect(response, UserType.admin);
      verifyRequest('/api/header/user-type', method: 'GET');
      expect(request?.headers['X-User'], isNull);
    });

    test('serialized-user-type', () async {
      final response = await client.headerParams.serializedUserType();

      expect(response, SerializedUserType.admin);
      verifyRequest('/api/header/serialized-user-type', method: 'GET');
      expect(request?.headers['X-User'], isNull);
    });
  });
}
