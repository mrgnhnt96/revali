import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:revali_client/revali_client.dart';
import 'package:test/test.dart';

void main() {
  group('streamed request bodies', () {
    late HttpServer server;
    late List<int> received;
    late String? receivedContentType;
    late String? receivedTransferEncoding;

    setUp(() async {
      received = [];
      receivedContentType = null;
      receivedTransferEncoding = null;

      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

      unawaited(
        server.forEach((request) async {
          receivedContentType = request.headers.contentType?.mimeType;
          receivedTransferEncoding = request.headers.value(
            HttpHeaders.transferEncodingHeader,
          );

          await for (final chunk in request) {
            received.addAll(chunk);
          }

          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'data': received.length}));
          await request.response.close();
        }),
      );
    });

    tearDown(() async => server.close(force: true));

    RevaliClient client() => RevaliClient(
      storage: SessionStorage(),
      baseUrl: 'http://127.0.0.1:${server.port}',
    );

    test('sends a byte stream without buffering it', () async {
      // Three chunks handed over lazily -- the point is that the transport
      // pulls them rather than the caller materialising one big list.
      final chunks = [
        [1, 2, 3],
        [4, 5],
        [6],
      ];

      final response = await client().request(
        method: 'POST',
        path: '/upload',
        body: Stream.fromIterable(chunks),
      );

      expect(response, isNotNull);
      expect(received, [1, 2, 3, 4, 5, 6]);
      expect(receivedContentType, 'application/octet-stream');
      expect(
        receivedTransferEncoding,
        'chunked',
        reason: 'unknown length must stream, not buffer to a Content-Length',
      );
    });

    test('encodes a string stream as utf8', () async {
      await client().request(
        method: 'POST',
        path: '/upload',
        body: Stream.fromIterable(['héllo ', 'wörld']),
      );

      expect(utf8.decode(received), 'héllo wörld');
      expect(receivedContentType, 'text/plain');
    });

    test('carries a large body through', () async {
      final chunk = List.filled(64 * 1024, 7);

      await client().request(
        method: 'POST',
        path: '/upload',
        body: Stream.fromIterable([chunk, chunk, chunk]),
      );

      expect(received, hasLength(3 * 64 * 1024));
    });

    test('rejects a stream it has no framing for', () async {
      await expectLater(
        client().request(
          method: 'POST',
          path: '/upload',
          body: Stream<int>.fromIterable([1, 2, 3]),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('Stream<List<int>> or Stream<String>'),
              contains('map the stream'),
            ),
          ),
        ),
      );
    });

    test('a non-stream body still works', () async {
      await client().request(
        method: 'POST',
        path: '/upload',
        body: {'name': 'Ada'},
      );

      expect(jsonDecode(utf8.decode(received)), {'name': 'Ada'});
      expect(receivedContentType, 'application/json');
    });
  });
}
