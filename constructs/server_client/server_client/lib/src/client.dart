import 'dart:convert';
import 'dart:io';

import 'package:server_client/src/cookie_parser.dart';
import 'package:server_client/src/server_exception.dart';
import 'package:server_client/src/storage.dart';

class Client {
  Client({
    required this.storage,
    HttpClient? client,
    this.baseUrl,
  }) : _client = client ?? HttpClient();

  final Storage storage;
  final HttpClient _client;
  final String? baseUrl;

  Future<HttpClientResponse> request({
    required String method,
    required String path,
    Map<String, String>? headers,
    Object? body,
    Map<String, dynamic> query = const {},
  }) async {
    assert(path.isNotEmpty, 'Path cannot be empty');

    final queryString = switch (query) {
      _ when query.isEmpty => '',
      // ignore: prefer_interpolation_to_compose_strings
      _ => '?' + query.entries.map((e) => '${e.key}=${e.value}').join('&')
    };

    final fullPath = switch ((path[0], baseUrl)) {
      ('/', final String base) => '$base$path$queryString',
      ('/', null) => throw Exception('Base URL not set'),
      _ => '$path$queryString',
    };

    final uri = Uri.parse(fullPath);

    final request = await _client.openUrl(method, uri);

    if (headers != null) {
      for (final entry in headers.entries) {
        request.headers.add(entry.key, entry.value);
      }
    }

    if (body != null) {
      request.write(jsonEncode(body));
    }

    final response = await request.close();

    final hasException = switch (response.statusCode) {
      >= 200 && < 300 => false,
      _ => true,
    };

    if (hasException) {
      final body = await response.transform(utf8.decoder).join();

      throw ServerException(
        message: response.reasonPhrase,
        statusCode: response.statusCode,
        body: body,
      );
    }

    if (response.headers['set-cookie'] case final List<dynamic> cookies
        when cookies.isNotEmpty) {
      final parser = CookieParser(cookies);

      if (parser.parse() case final cookies when cookies.isNotEmpty) {
        await storage.saveAll(cookies);
      }
    }

    return response;
  }
}
