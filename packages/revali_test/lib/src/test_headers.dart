import 'dart:io';

class TestHeaders implements HttpHeaders {
  TestHeaders(
    this._headers, {
    this.port,
    this.contentType,
    this.chunkedTransferEncoding = false,
    this.persistentConnection = false,
    this.date,
    this.expires,
    this.host,
    this.ifModifiedSince,
  }) {
    _headers[HttpHeaders.contentLengthHeader] = [
      if (contentLength case final int length) '$length',
    ];
    _headers[HttpHeaders.contentTypeHeader] = [
      if (contentType case final ContentType contentType) contentType.mimeType,
    ];
    _headers[HttpHeaders.dateHeader] = [
      if (date case final DateTime date) date.toIso8601String(),
    ];
    _headers[HttpHeaders.expiresHeader] = [
      if (expires case final DateTime expires) expires.toIso8601String(),
    ];
    _headers[HttpHeaders.hostHeader] = [if (host case final String host) host];
    _headers[HttpHeaders.ifModifiedSinceHeader] = [
      if (ifModifiedSince case final DateTime ifModifiedSince)
        ifModifiedSince.toIso8601String(),
    ];
  }

  final Map<String, List<String>> _headers;

  @override
  List<String>? operator [](String name) {
    return _headers[name];
  }

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    (_headers[name] ??= []).add(value.toString());
  }

  @override
  void clear() {
    _headers.clear();
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _headers.forEach(action);
  }

  @override
  void noFolding(String name) {
    throw UnimplementedError();
  }

  @override
  void remove(String name, Object value) {
    _headers.remove(name);
  }

  @override
  void removeAll(String name) {
    _headers.remove(name);
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    add(
      switch (name) {
        _ when preserveHeaderCase => name,
        _ => name.toLowerCase(),
      },
      value,
    );
  }

  @override
  String? value(String name) {
    return _headers[name]?.firstOrNull;
  }

  @override
  int contentLength = 0;

  @override
  ContentType? contentType;

  @override
  DateTime? date;

  @override
  DateTime? expires;

  @override
  String? host;

  @override
  DateTime? ifModifiedSince;

  @override
  int? port;

  @override
  bool chunkedTransferEncoding = false;

  @override
  bool persistentConnection = false;
}
