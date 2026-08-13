import 'dart:convert';

class HttpRequest {
  HttpRequest({
    required this.method,
    required this.url,
    Map<String, String>? headers,
    this.body = '',
    this.bodyBytes,
    this.bodyStream,
    this.encoding,
    this.contentLength,
  }) : headers = headers ?? {};

  final String method;
  final Uri url;
  Map<String, String> headers;
  String body;
  List<int>? bodyBytes;

  /// Sent incrementally rather than buffered.
  ///
  /// Takes precedence over [body] and [bodyBytes]. Set [contentLength] when
  /// the size is known; otherwise the request goes out chunked.
  Stream<List<int>>? bodyStream;

  Encoding? encoding;
  int? contentLength;
}
