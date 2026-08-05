import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:revali_client/src/http_request.dart';
import 'package:revali_client/src/integrations/http_package_client.dart';
import 'package:test/test.dart';

void main() {
  group(HttpPackageClient, () {
    test('does not send a literal "credentials" header', () async {
      http.BaseRequest? captured;
      final mock = MockClient((request) async {
        captured = request;
        return http.Response('', 200);
      });

      final client = HttpPackageClient(client: mock);

      await client.send(
        HttpRequest(method: 'GET', url: Uri.parse('https://example.com')),
      );

      expect(captured, isNotNull);
      expect(captured!.headers.containsKey('credentials'), isFalse);
    });

    test('still forwards caller-provided headers', () async {
      http.BaseRequest? captured;
      final mock = MockClient((request) async {
        captured = request;
        return http.Response('', 200);
      });

      final client = HttpPackageClient(client: mock);

      await client.send(
        HttpRequest(
          method: 'GET',
          url: Uri.parse('https://example.com'),
          headers: {'x-custom': 'value'},
        ),
      );

      expect(captured!.headers['x-custom'], 'value');
    });
  });
}
