import 'dart:convert';

import 'package:http_parser/http_parser.dart';

abstract class ReadOnlyHeaders {
  const ReadOnlyHeaders();

  String? get(String key);
  String? operator [](String value);
  Iterable<String> get keys;
  List<String>? getAll(String key);
  void forEach(void Function(String key, List<String> value) f);

  /// If [headers] doesn't have a Content-Type header or it specifies an
  /// encoding that `dart:convert` doesn't support, this will be `null`.
  Encoding get encoding;

  MediaType? get contentType;

  /// If this is non-`null` and the requested resource hasn't been modified
  /// since this date and time, the server should return a 304 Not Modified
  /// response.
  ///
  /// This is parsed from the If-Modified-Since header in [headers]. If
  /// [headers] doesn't have an If-Modified-Since header, this will be `null`.
  ///
  /// Throws [FormatException], if incoming HTTP request has an invalid
  /// If-Modified-Since header.
  DateTime? get ifModifiedSince;

  /// This is parsed from the Content-Type header in [headers]. It contains only
  /// the MIME type, without any Content-Type parameters.
  ///
  /// If there's no Content-Type header, this will be `null`.
  String? get mimeType;

  int? get contentLength;
}
