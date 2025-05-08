import 'package:revali_client/revali_client.dart';
import 'package:revali_client_params/revali_client_params.dart';
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

    test('required/string', () async {
      final response = await client.queryParams.requiredString(shopId: 'abc');

      expect(response, 'abc');
      verifyRequest('/api/query/required/string', method: 'GET');
      expect(request?.url.queryParametersAll['shopId'], ['abc']);
    });

    test('required/int', () async {
      final response = await client.queryParams.requiredInt(shopId: 123);

      expect(response, 123);
      verifyRequest('/api/query/required/int', method: 'GET');
      expect(request?.url.queryParametersAll['shopId'], ['123']);
    });

    test('required/bool', () async {
      final response = await client.queryParams.requiredBool(shopId: true);

      expect(response, true);
      verifyRequest('/api/query/required/bool', method: 'GET');
      expect(request?.url.queryParametersAll['shopId'], ['true']);
    });

    test('required/double', () async {
      final response = await client.queryParams.requiredDouble(shopId: 123);

      expect(response, 123.0);
      verifyRequest('/api/query/required/double', method: 'GET');
      expect(request?.url.queryParametersAll['shopId'], ['123.0']);
    });

    test('optional/string', () async {
      final response = await client.queryParams.optionalString(shopId: 'abc');

      expect(response, 'abc');
      verifyRequest('/api/query/optional/string', method: 'GET');
      expect(request?.url.queryParametersAll['shopId'], ['abc']);
    });

    test('optional/int', () async {
      final response = await client.queryParams.optionalInt(shopId: 123);

      expect(response, 123);
      verifyRequest('/api/query/optional/int', method: 'GET');
      expect(request?.url.queryParametersAll['shopId'], ['123']);
    });

    test('optional/bool', () async {
      final response = await client.queryParams.optionalBool(shopId: true);

      expect(response, true);
      verifyRequest('/api/query/optional/bool', method: 'GET');
      expect(request?.url.queryParametersAll['shopId'], ['true']);
    });

    test('optional/double', () async {
      final response = await client.queryParams.optionalDouble(shopId: 123);

      expect(response, 123.0);
      verifyRequest('/api/query/optional/double', method: 'GET');
      expect(request?.url.queryParametersAll['shopId'], ['123.0']);
    });

    test('all/string', () async {
      final response =
          await client.queryParams.allString(shopIds: ['abc', 'def']);

      expect(response, 'abc,def');
      verifyRequest('/api/query/all/string', method: 'GET');
      expect(request?.url.queryParametersAll['shopId'], ['abc', 'def']);
    });

    test('all/int', () async {
      final response = await client.queryParams.allInt(shopIds: [123, 456]);

      // hack to bypass bytes response
      expect(response, [123, 456].join(','));
      verifyRequest('/api/query/all/int', method: 'GET');
      expect(request?.url.queryParametersAll['shopId'], ['123', '456']);
    });

    test('all/bool', () async {
      final response = await client.queryParams.allBool(shopIds: [true, false]);

      expect(response, [true, false]);
      verifyRequest('/api/query/all/bool', method: 'GET');
      expect(request?.url.queryParametersAll['shopId'], ['true', 'false']);
    });

    test('all/double', () async {
      final response =
          await client.queryParams.allDouble(shopIds: [123.0, 456.0]);

      expect(response, [123.0, 456.0]);
      verifyRequest('/api/query/all/double', method: 'GET');
      expect(request?.url.queryParametersAll['shopId'], ['123.0', '456.0']);
    });

    test('all-optional/string', () async {
      final response =
          await client.queryParams.allOptionalString(shopIds: ['abc', 'def']);

      expect(response, ['abc', 'def']);
      verifyRequest('/api/query/all-optional/string', method: 'GET');
      expect(request?.url.queryParametersAll['shopId'], ['abc', 'def']);
    });

    test('all-optional/int', () async {
      final response =
          await client.queryParams.allOptionalInt(shopIds: [123, 456]);

      // hack to bypass bytes response
      expect(response, [123, 456].join(','));
      verifyRequest('/api/query/all-optional/int', method: 'GET');
      expect(request?.url.queryParametersAll['shopId'], ['123', '456']);
    });

    test('all-optional/bool', () async {
      final response =
          await client.queryParams.allOptionalBool(shopIds: [true, false]);

      expect(response, [true, false]);
      verifyRequest('/api/query/all-optional/bool', method: 'GET');
      expect(request?.url.queryParametersAll['shopId'], ['true', 'false']);
    });

    test('all-optional/double', () async {
      final response =
          await client.queryParams.allOptionalDouble(shopIds: [123.0, 456.0]);

      expect(response, [123.0, 456.0]);
      verifyRequest('/api/query/all-optional/double', method: 'GET');
      expect(request?.url.queryParametersAll['shopId'], ['123.0', '456.0']);
    });
  });
}
