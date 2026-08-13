import 'dart:convert';
import 'dart:typed_data';

import 'package:revali_test/src/test_request.dart';
import 'package:test/test.dart';

TestRequest request({Object? body}) => TestRequest(
  method: 'POST',
  path: '/upload',
  body: body,
  onResponse: (_) {},
  onWebSocketMessage: null,
);

Future<List<int>> read(TestRequest r) =>
    r.fold<List<int>>([], (a, b) => a..addAll(b));

void main() {
  group('TestRequest body', () {
    test('sends bytes untouched', () async {
      // Regression: these used to be jsonEncode'd, so a binary upload
      // arrived as the *text* "[1,2,3]".
      expect(await read(request(body: [1, 2, 3])), [1, 2, 3]);
    });

    test('sends a streamed body as it arrives', () async {
      final body = Stream.fromIterable([
        [1, 2],
        [3, 4],
      ]);

      expect(await read(request(body: body)), [1, 2, 3, 4]);
    });

    test('sends a string as utf8', () async {
      expect(utf8.decode(await read(request(body: 'héllo'))), 'héllo');
    });

    test('json-encodes anything else', () async {
      final bytes = await read(request(body: {'a': 1}));

      expect(jsonDecode(utf8.decode(bytes)), {'a': 1});
    });

    test('an absent body is empty', () async {
      expect(await read(request()), isEmpty);
    });

    test('a Uint8List body is preserved', () async {
      final bytes = Uint8List.fromList([9, 8, 7]);

      expect(await read(request(body: bytes)), [9, 8, 7]);
    });
  });
}
