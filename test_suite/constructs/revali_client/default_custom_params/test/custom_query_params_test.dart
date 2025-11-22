import 'dart:convert';

import 'package:revali_client/revali_client.dart';
import 'package:revali_client_default_custom_params/revali_client_default_custom_params.dart';
import 'package:revali_client_default_custom_params_test/models/user.dart';
import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('custom query params', () {
    late TestServer server;
    late Server client;
    HttpRequest? request;

    setUp(() {
      server = TestServer();

      client = Server(client: TestClient(server, (req) => request = req));

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
      const user = User(name: 'John');
      final response = await client.customQueryParams.required(user: user);

      expect(response, user);
      verifyRequest('/api/custom/query/required', method: 'GET');
      expect(request?.url.queryParametersAll['user'], [jsonEncode(user)]);
    });

    test('optional', () async {
      const user = User(name: 'John');
      final response = await client.customQueryParams.optional(user: user);

      expect(response, user);
      verifyRequest('/api/custom/query/optional', method: 'GET');
      expect(request?.url.queryParametersAll['user'], [jsonEncode(user)]);
    });

    test('all', () async {
      const users = [User(name: 'John'), User(name: 'Jane')];
      final response = await client.customQueryParams.all(users: users);

      expect(response, users);
      verifyRequest('/api/custom/query/all', method: 'GET');
      expect(
        request?.url.queryParametersAll['user'],
        users.map(jsonEncode).toList(),
      );
    });

    test('all-optional', () async {
      const users = [User(name: 'John'), User(name: 'Jane')];
      final response = await client.customQueryParams.allOptional(users: users);

      expect(response, users);
      verifyRequest('/api/custom/query/all-optional', method: 'GET');
      expect(
        request?.url.queryParametersAll['user'],
        users.map(jsonEncode).toList(),
      );
    });
  });
}
