import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:revali_router/revali_router.dart';
import 'package:test/test.dart';

/// Long enough to clear the default 1 KB threshold, and repetitive so gzip
/// visibly shrinks it.
final _bigJson = jsonEncode({
  'items': List.generate(200, (i) => {'id': i, 'name': 'item-name-$i'}),
});

void main() {
  group('response compression', () {
    late HttpServer server;
    late HttpClient client;

    Future<void> serve({
      CompressionSettings compression = const CompressionSettings(),
      String body = '',
      String mimeType = 'application/json',
    }) async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

      final router = Router(
        compression: compression,
        routes: [
          Route(
            'data',
            method: 'GET',
            handler: (context) async {
              context.response
                ..headers.mimeType = mimeType
                ..body = body;
            },
          ),
        ],
      );

      unawaited(handleRouterRequests(server, router, server.close));
    }

    setUp(() {
      client = HttpClient()..autoUncompress = false;
    });

    tearDown(() async {
      client.close(force: true);
      await server.close(force: true);
    });

    Future<HttpClientResponse> get({String? acceptEncoding}) async {
      final request = await client.getUrl(
        Uri.parse('http://127.0.0.1:${server.port}/data'),
      );
      // dart:io sets this itself; clear it so each test controls it.
      request.headers.removeAll(HttpHeaders.acceptEncodingHeader);
      if (acceptEncoding != null) {
        request.headers.set(HttpHeaders.acceptEncodingHeader, acceptEncoding);
      }

      return request.close();
    }

    test('compresses a large JSON body when the client accepts gzip', () async {
      await serve(body: _bigJson);

      final response = await get(acceptEncoding: 'gzip');
      final bytes = await response.fold<List<int>>([], (a, b) => a..addAll(b));

      expect(response.headers.value('content-encoding'), 'gzip');
      expect(bytes.length, lessThan(_bigJson.length));

      // The point of all this: it still decodes to what the handler sent.
      expect(utf8.decode(gzip.decode(bytes)), _bigJson);
    });

    test('sets Vary so caches do not serve the wrong variant', () async {
      await serve(body: _bigJson);

      final response = await get(acceptEncoding: 'gzip');
      await response.drain<void>();

      expect(
        response.headers.value('vary')?.toLowerCase(),
        contains('accept-encoding'),
      );
    });

    test('leaves the body alone when the client does not accept gzip',
        () async {
      await serve(body: _bigJson);

      final response = await get();
      final body = await response.transform(utf8.decoder).join();

      expect(response.headers.value('content-encoding'), isNull);
      expect(body, _bigJson);
    });

    test('honors a q-value list', () async {
      await serve(body: _bigJson);

      final response =
          await get(acceptEncoding: 'br;q=1.0, gzip;q=0.8, *;q=0.1');
      await response.drain<void>();

      expect(response.headers.value('content-encoding'), 'gzip');
    });

    test('skips bodies below the threshold', () async {
      await serve(body: '{"ok":true}');

      final response = await get(acceptEncoding: 'gzip');
      final body = await response.transform(utf8.decoder).join();

      expect(response.headers.value('content-encoding'), isNull);
      expect(body, '{"ok":true}');
    });

    test('skips mime types that are already compressed', () async {
      await serve(body: _bigJson, mimeType: 'image/png');

      final response = await get(acceptEncoding: 'gzip');
      await response.drain<void>();

      expect(response.headers.value('content-encoding'), isNull);
    });

    test('can be turned off entirely', () async {
      await serve(
        body: _bigJson,
        compression: const CompressionSettings.disabled(),
      );

      final response = await get(acceptEncoding: 'gzip');
      final body = await response.transform(utf8.decoder).join();

      expect(response.headers.value('content-encoding'), isNull);
      expect(body, _bigJson);
    });

    test('respects a custom threshold', () async {
      await serve(
        body: _bigJson,
        compression: const CompressionSettings(minBytes: 1 << 30),
      );

      final response = await get(acceptEncoding: 'gzip');
      await response.drain<void>();

      expect(response.headers.value('content-encoding'), isNull);
    });
  });

  group('CompressionSettings', () {
    test('allows only listed mime types', () {
      const settings = CompressionSettings();

      expect(settings.allows('application/json'), isTrue);
      expect(settings.allows('APPLICATION/JSON'), isTrue, reason: 'case');
      expect(settings.allows('image/png'), isFalse);
      expect(settings.allows(null), isFalse);
    });

    test('disabled allows nothing', () {
      const settings = CompressionSettings.disabled();

      expect(settings.allows('application/json'), isFalse);
    });
  });
}
