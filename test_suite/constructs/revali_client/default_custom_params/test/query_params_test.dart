import 'package:revali_client/revali_client.dart';
import 'package:revali_client_default_custom_params/revali_client_default_custom_params.dart';
import 'package:revali_client_default_custom_params_test/enums/serialized_user_type.dart';
import 'package:revali_client_default_custom_params_test/enums/user_type.dart';
import 'package:revali_client_default_custom_params_test/models/string_user.dart';
import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('query params', () {
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
      final response = await client.queryParams.required();

      expect(response, const StringUser(name: 'John'));
      verifyRequest('/api/query/required', method: 'GET');
      expect(request?.url.queryParametersAll['user'], isNull);
    });

    test('optional', () async {
      final response = await client.queryParams.optional();

      expect(response, const StringUser(name: 'John'));
      verifyRequest('/api/query/optional', method: 'GET');
      expect(request?.url.queryParametersAll['user'], isNull);
    });

    test('all', () async {
      final response = await client.queryParams.all();

      expect(response, [
        const StringUser(name: 'John'),
        const StringUser(name: 'Jane'),
      ]);
      verifyRequest('/api/query/all', method: 'GET');
      expect(request?.url.queryParametersAll['user'], isNull);
    });

    test('all-optional', () async {
      final response = await client.queryParams.allOptional();

      expect(response, [
        const StringUser(name: 'John'),
        const StringUser(name: 'Jane'),
      ]);
      verifyRequest('/api/query/all-optional', method: 'GET');
      expect(request?.url.queryParametersAll['user'], isNull);
    });

    test('user-type', () async {
      final response = await client.queryParams.userType();

      expect(response, UserType.admin);
      verifyRequest('/api/query/user-type', method: 'GET');
      expect(request?.url.queryParametersAll['user'], isNull);
    });

    test('serialized-user-type', () async {
      final response = await client.queryParams.serializedUserType();

      expect(response, SerializedUserType.admin);
      verifyRequest('/api/query/serialized-user-type', method: 'GET');
      expect(request?.url.queryParametersAll['user'], isNull);
    });
  });
}
