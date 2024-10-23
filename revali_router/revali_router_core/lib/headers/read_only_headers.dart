import 'dart:convert';

import 'package:http_parser/http_parser.dart';

abstract class ReadOnlyHeaders {
  const ReadOnlyHeaders();

  String? get(String key);
  String? operator [](String value);
  Iterable<String> get keys;
  Map<String, Iterable<String>> get values;

  Iterable<String>? getAll(String key);
  void forEach(void Function(String key, Iterable<String> value) f);

  /// If [ReadOnlyHeaders] doesn't have a Content-Type header or it specifies an
  /// encoding that `dart:convert` doesn't support, this will be `null`.
  Encoding get encoding;

  MediaType? get contentType;

  /// If this is non-`null` and the requested resource hasn't been modified
  /// since this date and time, the server should return a 304 Not Modified
  /// response.
  ///
  /// This is parsed from the If-Modified-Since header in [ReadOnlyHeaders]. If
  /// [ReadOnlyHeaders] doesn't have an If-Modified-Since header,
  /// this will be `null`.
  ///
  /// Throws [FormatException], if incoming HTTP request has an invalid
  /// If-Modified-Since header.
  DateTime? get ifModifiedSince;

  /// This is parsed from the Content-Type header in [ReadOnlyHeaders].
  /// It contains only
  /// the MIME type, without any Content-Type parameters.
  ///
  /// If there's no Content-Type header, this will be `null`.
  String? get mimeType;

  int? get contentLength;

  String? get origin;

  String? get filename;

  String? get transferEncoding;

  (int, int)? get range;

  Map<K2, V2> map<K2, V2>(
    MapEntry<K2, V2> Function(String key, Iterable<String> values) convert,
  );
}
