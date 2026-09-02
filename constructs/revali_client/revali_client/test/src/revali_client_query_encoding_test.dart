import 'dart:convert';

import 'package:revali_client/revali_client.dart';
import 'package:test/test.dart';

/// Answers everything with a 200 and remembers what it was asked for, so a
/// test can read back the URI the client actually built.
class CapturingClient implements HttpClient {
  final sent = <HttpRequest>[];

  @override
  final List<HttpInterceptor> interceptors = [];

  @override
  Future<HttpResponse> send(HttpRequest request) async {
    sent.add(request);

    return HttpResponse(
      request: request,
      statusCode: 200,
      headers: const {},
      stream: const Stream.empty(),
      persistentConnection: false,
      reasonPhrase: null,
      contentLength: 0,
    );
  }
}

/// The query the client put on the wire for [query], as the server would
/// decode it.
Future<Uri> uriFor(Map<String, dynamic> query) async {
  final transport = CapturingClient();

  await RevaliClient(
    storage: SessionStorage(),
    client: transport,
    baseUrl: 'http://x.test',
  ).request(method: 'GET', path: '/thing', query: query);

  return transport.sent.single.url;
}

void main() {
  group('query values survive the trip', () {
    const values = {
      'hash': 'a#b',
      'ampersand': 'a&b',
      'equals': 'a=b',
      'percent': 'a%b',
      'plus': 'a+b',
      'space': 'a b',
      'encoded space': 'a%20b',
    };

    for (final MapEntry(key: name, value: value) in values.entries) {
      test('a $name is not lost', () async {
        final uri = await uriFor({'k': value});

        expect(uri.queryParameters['k'], value);
      });
    }

    test('a JSON body containing a # is not truncated', () async {
      final body = jsonEncode({
        'id': 'rec#123',
        'items': ['a', 'b'],
      });

      final uri = await uriFor({'body': body});

      expect(uri.queryParameters['body'], body);
      expect(jsonDecode(uri.queryParameters['body']!), {
        'id': 'rec#123',
        'items': ['a', 'b'],
      });
    });
  });

  group('query shape', () {
    test('a list emits one pair per element with no empty pair', () async {
      final uri = await uriFor({
        'a': [1, 2],
        'b': 3,
      });

      expect(uri.query, 'a=1&a=2&b=3');
      expect(uri.queryParametersAll['a'], ['1', '2']);
    });

    test('a non-String value is JSON encoded, then percent encoded', () async {
      final uri = await uriFor({
        'k': {'x': 1},
      });

      expect(jsonDecode(uri.queryParameters['k']!), {'x': 1});
    });

    test('a key is encoded too', () async {
      final uri = await uriFor({'a&b': 'c'});

      expect(uri.queryParameters['a&b'], 'c');
    });

    test('a null value does not leave a dangling separator', () async {
      final uri = await uriFor({'a': 1, 'b': null, 'c': 2});

      expect(uri.query, 'a=1&c=2');
    });
  });
}
