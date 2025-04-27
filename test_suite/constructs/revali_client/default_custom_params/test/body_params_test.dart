import 'dart:convert';

import 'package:revali_client/revali_client.dart';
import 'package:revali_client_default_custom_params/revali_client_default_custom_params.dart';
import 'package:revali_client_default_custom_params_test/lib/enums/serialized_user_type.dart';
import 'package:revali_client_default_custom_params_test/lib/enums/user_type.dart';
import 'package:revali_client_default_custom_params_test/lib/models/user.dart';
import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('body params', () {
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

    test('non-null', () async {
      final response = await client.bodyParams.nonNull();

      expect(response, const User(name: 'John'));
      verifyRequest('/api/body/non-null', method: 'GET');
      expect(request?.body, '');
    });

    test('nested-non-null', () async {
      final response = await client.bodyParams.nestedNonNull();

      expect(response, const User(name: 'John'));
      verifyRequest('/api/body/nested-non-null', method: 'GET');
      expect(request?.body, jsonEncode({'name': null}));
    });

    test('nested-nullable', () async {
      final response = await client.bodyParams.nestedNullable();

      expect(response, const User(name: 'John'));
      verifyRequest('/api/body/nested-nullable', method: 'GET');
      expect(request?.body, jsonEncode({'name': null}));
    });

    test('user-type', () async {
      final response = await client.bodyParams.userType();

      expect(response, UserType.admin);
      verifyRequest('/api/body/user-type', method: 'GET');
      expect(request?.body, '');
    });

    test('serialized-user-type', () async {
      final response = await client.bodyParams.serializedUserType();

      expect(response, SerializedUserType.admin);
      verifyRequest('/api/body/serialized-user-type', method: 'GET');
      expect(request?.body, '');
    });
  });
}
