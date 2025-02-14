import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:server_client/src/cookie_parser.dart';
import 'package:server_client/src/server_exception.dart';
import 'package:server_client/src/storage.dart';

class HttpClient {
  HttpClient({
    required this.storage,
    http.Client? client,
    this.baseUrl,
  }) : _client = client ?? http.Client();

  final Storage storage;
  final http.Client _client;
  final String? baseUrl;

  Future<http.ByteStream> request({
    required String method,
    required String path,
    Map<String, String>? headers,
    Object? body,
    Map<String, dynamic> query = const {},
  }) async {
    assert(path.isNotEmpty, 'Path cannot be empty');

    String formQuery() {
      if (query.isEmpty) {
        return '';
      }

      final buffer = StringBuffer()..write('?');

      for (final (index, MapEntry(:key, :value)) in query.entries.indexed) {
        if (value == null) continue;

        buffer.write('$key=$value');

        if (index < query.length - 1) {
          buffer.write('&');
        }
      }

      return buffer.toString();
    }

    final fullPath = switch ((path[0], baseUrl)) {
      ('/', final String base) => '$base$path${formQuery()}',
      ('/', null) => throw Exception('Base URL not set'),
      _ => '$path${formQuery()}',
    };

    final uri = Uri.parse(fullPath);

    final request = http.Request(method, uri);

    if (headers != null) {
      request.headers.addAll(headers);
    }

    if (body != null) {
      request.body = jsonEncode(body);
    }

    final response = await _client.send(request);

    final hasException = switch (response.statusCode) {
      >= 200 && < 300 => false,
      _ => true,
    };

    if (hasException) {
      final body = await response.stream.transform(utf8.decoder).join();

      throw ServerException(
        message: response.reasonPhrase ?? 'Unknown error',
        statusCode: response.statusCode,
        body: body,
      );
    }

    if (response.headers['set-cookie'] case final String cookies
        when cookies.isNotEmpty) {
      final parser = CookieParser(cookies);

      if (parser.parse() case final cookies when cookies.isNotEmpty) {
        await storage.saveAll(cookies);
      }
    }

    return response.stream;
  }
}
