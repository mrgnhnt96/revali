import 'dart:convert';

class HttpRequest {
  HttpRequest({
    required this.method,
    required this.url,
    Map<String, String>? headers,
    this.body = '',
    this.bodyBytes,
    this.encoding,
    this.contentLength,
  }) : headers = headers ?? {};

  final String method;
  final Uri url;
  Map<String, String> headers;
  String body;
  List<int>? bodyBytes;
  Encoding? encoding;
  int? contentLength;
}
