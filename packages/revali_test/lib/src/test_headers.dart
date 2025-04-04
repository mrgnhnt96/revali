import 'dart:io';

class TestHeaders implements HttpHeaders {
  TestHeaders(
    this._headers, {
    int? port,
    String? host,
    ContentType? contentType,
    bool? chunkedTransferEncoding,
    bool? persistentConnection,
    DateTime? date,
    DateTime? expires,
    DateTime? ifModifiedSince,
    int? contentLength,
  }) {
    if (contentLength case final int length when length != -1) {
      this.contentLength = length;
    }

    if (contentType case final ContentType contentType) {
      this.contentType = contentType;
    }

    if (date case final DateTime date) {
      this.date = date;
    }

    if (expires case final DateTime expires) {
      this.expires = expires;
    }

    if (host case final String host) {
      this.host = host;
    }

    if (port case final int port) {
      this.port = port;
    }

    if (ifModifiedSince case final DateTime ifModifiedSince) {
      this.ifModifiedSince = ifModifiedSince;
    }

    if (chunkedTransferEncoding case final bool chunk) {
      this.chunkedTransferEncoding = chunk;
    }

    if (persistentConnection case final bool value) {
      this.persistentConnection = value;
    }
  }

  final Map<String, String> _headers;

  Map<String, String> get allValues => Map.unmodifiable(_headers);
  Map<String, String> get values => Map.unmodifiable(
        Map.fromEntries(
          _headers.entries.map((e) => MapEntry(e.key, e.value)),
        ),
      );

  @override
  List<String>? operator [](String name) {
    return _headers[name]?.split(',');
  }

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers[name] = value.toString();
  }

  @override
  void clear() {
    _headers.clear();
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _headers.forEach((key, value) {
      action(key, value.split(','));
    });
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
    return _headers[name];
  }

  int _contentLength = -1;
  @override
  int get contentLength => _contentLength != -1
      ? _contentLength
      : switch (_headers[HttpHeaders.contentLengthHeader]) {
          final String value => int.tryParse(value) ?? -1,
          _ => -1,
        };
  @override
  set contentLength(int value) {
    _add(HttpHeaders.contentLengthHeader, '$value');

    _contentLength = value;
  }

  ContentType? _contentType;
  @override
  ContentType? get contentType =>
      _contentType ??= switch (_headers[HttpHeaders.contentTypeHeader]) {
        final String type => ContentType.parse(type),
        _ => null,
      };

  @override
  set contentType(ContentType? type) {
    _add(HttpHeaders.contentTypeHeader, type?.mimeType);

    _contentType = type;
  }

  DateTime? _date;
  @override
  DateTime? get date => _date ??= switch (_headers[HttpHeaders.dateHeader]) {
        final String value => DateTime.tryParse(value),
        _ => null,
      };

  @override
  set date(DateTime? value) {
    _add(HttpHeaders.dateHeader, value?.toIso8601String());

    _date = value;
  }

  DateTime? _expires;
  @override
  DateTime? get expires =>
      _expires ??= switch (_headers[HttpHeaders.expiresHeader]) {
        final String value => DateTime.tryParse(value),
        _ => null,
      };

  @override
  set expires(DateTime? value) {
    _add(HttpHeaders.expiresHeader, value?.toIso8601String());

    _expires = value;
  }

  String? _host;
  @override
  String? get host => _host ??= switch (_headers[HttpHeaders.hostHeader]) {
        final String value => value,
        _ => null,
      };

  @override
  set host(String? host) {
    _add(HttpHeaders.hostHeader, host);

    _host = host;
  }

  DateTime? _ifModifiedSince;
  @override
  DateTime? get ifModifiedSince => _ifModifiedSince ??=
          switch (_headers[HttpHeaders.ifModifiedSinceHeader]) {
        final String value => DateTime.tryParse(value),
        _ => null,
      };

  @override
  set ifModifiedSince(DateTime? value) {
    _add(HttpHeaders.expiresHeader, value?.toIso8601String());

    _ifModifiedSince = value;
  }

  int? _port;
  @override
  int? get port => _port ??= switch (_headers[HttpHeaders.hostHeader]) {
        final String value => int.tryParse(value),
        _ => null,
      };

  @override
  set port(int? port) {
    _add(HttpHeaders.hostHeader, port?.toString());

    _port = port;
  }

  bool? _chunkedTransferEncoding;
  @override
  bool get chunkedTransferEncoding =>
      _chunkedTransferEncoding ??
      switch (_headers[HttpHeaders.transferEncodingHeader]) {
        'true' => true,
        _ => false,
      };

  @override
  set chunkedTransferEncoding(bool value) {
    _add(HttpHeaders.transferEncodingHeader, '$value');

    _chunkedTransferEncoding = value;
  }

  bool? _persistentConnection;
  @override
  bool get persistentConnection => _persistentConnection ??=
          switch (_headers[HttpHeaders.connectionHeader]) {
        'true' => true,
        _ => false,
      };

  @override
  set persistentConnection(bool value) {
    _add(HttpHeaders.connectionHeader, '$value');

    _persistentConnection = value;
  }

  void _add(String key, String? value) {
    switch (value) {
      case String():
        add(key, value);
      case null:
        _headers.remove(key);
    }
  }
}
