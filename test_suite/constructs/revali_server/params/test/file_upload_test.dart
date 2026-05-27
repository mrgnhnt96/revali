import 'dart:io';

import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

String multipartBody({
  required String boundary,
  required Map<String, String> fields,
  Map<String, ({String filename, String content})>? files,
}) {
  const crlf = '\r\n';
  final buffer = StringBuffer();

  for (final entry in fields.entries) {
    buffer.write('--$boundary$crlf');
    buffer.write('Content-Disposition: form-data; name="${entry.key}"$crlf');
    buffer.write(crlf);
    buffer.write('${entry.value}$crlf');
  }

  for (final entry in (files ?? const {}).entries) {
    buffer.write('--$boundary$crlf');
    buffer.write(
      'Content-Disposition: form-data; name="${entry.key}"; '
      'filename="${entry.value.filename}"$crlf',
    );
    buffer.write(crlf);
    buffer.write('${entry.value.content}$crlf');
  }

  buffer.write('--$boundary--$crlf');
  return buffer.toString();
}

void main() {
  group('file-upload', () {
    late TestServer server;

    setUp(() {
      server = TestServer();
      createServer(server);
    });

    tearDown(() {
      server.close();
    });

    test('multipart form upload', () async {
      const boundary = 'dart-test-boundary';
      const fileContent = 'Sup, hows it going?';

      final response = await server.send(
        method: 'POST',
        path: '/api/file',
        headers: {
          'content-type': 'multipart/form-data; boundary=$boundary',
        },
        body: multipartBody(
          boundary: boundary,
          fields: {
            'is_awesome': 'true',
            'count': '1',
          },
          files: {
            'file': (filename: 'file.txt', content: fileContent),
          },
        ),
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {
        'data': {
          'filename': 'file.txt',
          'size': fileContent.length,
          'content': fileContent,
          'is_awesome': true,
          'count': 1,
        },
      });
    });

    test('raw octet-stream upload', () async {
      const fileContent = 'sup dude!';

      final response = await server.send(
        method: 'POST',
        path: '/api/file/raw',
        headers: {
          'content-type': 'application/octet-stream',
        },
        body: fileContent,
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {
        'data': {
          'size': fileContent.length,
          'content': fileContent,
        },
      });
    });
  });
}
