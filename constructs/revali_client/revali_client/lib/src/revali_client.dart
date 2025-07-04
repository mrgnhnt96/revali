import 'dart:convert';

import 'package:revali_client/src/cookie_parser.dart';
import 'package:revali_client/src/http_client.dart';
import 'package:revali_client/src/http_interceptor.dart';
import 'package:revali_client/src/http_request.dart';
import 'package:revali_client/src/http_response.dart';
import 'package:revali_client/src/integrations/http_package_client.dart';
import 'package:revali_client/src/server_exception.dart';
import 'package:revali_client/src/storage.dart';

class RevaliClient {
  RevaliClient({
    required this.storage,
    HttpClient? client,
    this.baseUrl,
  }) : _client = client ?? HttpPackageClient();

  final Storage storage;
  final HttpClient _client;
  final String? baseUrl;

  List<HttpInterceptor> get interceptors => _client.interceptors;

  /// [headers] Accepts either a Map<String, List<String>>
  /// or a Map<String, String>.
  ///
  /// [query] Accepts either a Map<String, List<String>>
  /// or a Map<String, String>.
  Future<HttpResponse> request({
    required String method,
    required String path,
    Map<String, dynamic>? headers,
    Object? body,
    Map<String, dynamic> query = const {},
  }) async {
    assert(path.isNotEmpty, 'Path cannot be empty');

    String formQuery() {
      if (query.isEmpty) {
        return '';
      }

      final buffer = StringBuffer();

      void write(String key, dynamic value) {
        if (value == null) return;

        if (value is List) {
          for (final e in value) {
            write(key, e);
            buffer.write('&');
          }
        } else {
          buffer.write('$key=');
          try {
            switch (value) {
              case String():
                buffer.write(value);
              case _:
                buffer.write(jsonEncode(value));
            }
          } catch (_) {
            buffer.write('$value');
          }
        }
      }

      for (final (index, MapEntry(:key, value: rawValue))
          in query.entries.indexed) {
        write(key, rawValue);

        if (index < query.length - 1) {
          buffer.write('&');
        }
      }

      if (buffer.isEmpty) {
        return '';
      }

      return '?$buffer';
    }

    final fullPath = switch ((path[0], baseUrl)) {
      ('/', final String base) => '$base$path${formQuery()}',
      ('/', null) => throw Exception('Base URL not set'),
      _ => '$path${formQuery()}',
    };

    final uri = Uri.parse(fullPath);

    final request = HttpRequest(method: method, url: uri);

    if (headers != null) {
      void addHeader(String key, dynamic value) {
        if (value == null) return;

        if (value is List) {
          request.headers[key] = value.map((e) => '$e').join(',');
        } else {
          request.headers[key] = value.toString();
        }
      }

      headers.forEach(addHeader);
    }

    switch (body) {
      case List<int>():
        request.bodyBytes = body;
        request.headers['content-type'] = 'application/octet-stream';

      case List<dynamic>():
      case Map<dynamic, dynamic>():
        request.body = jsonEncode(body);
        request.headers['content-type'] = 'application/json';

      case String():
        request.body = body;
        request.headers['content-type'] = 'text/plain';

      case Stream<dynamic>():
        throw UnimplementedError('Stream body not implemented');
      // request.body = body;
      // request.headers['content-type'] = 'application/octet-stream';
      case null:
        break;
      default:
        request.body = jsonEncode(body);
        request.headers['content-type'] = 'application/json';
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

    return response;
  }
}
