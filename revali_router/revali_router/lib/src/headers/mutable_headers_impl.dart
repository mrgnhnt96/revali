import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http_parser/http_parser.dart';
import 'package:revali_router/src/cookies/mutable_cookies_impl.dart';
import 'package:revali_router/src/cookies/mutable_set_cookies_impl.dart';
import 'package:revali_router/src/headers/common_headers_mixin.dart';
import 'package:revali_router_core/revali_router_core.dart';

class MutableHeadersImpl extends CommonHeadersMixin implements MutableHeaders {
  MutableHeadersImpl([Map<String, Iterable<String>>? headers])
      : _headers = CaseInsensitiveMap.from(
          headers ?? {},
        ),
        cookies = MutableCookiesImpl.fromHeader(
          headers?[HttpHeaders.cookieHeader]?.join(';'),
        ),
        setCookies = MutableSetCookiesImpl.fromHeader(
          headers?[HttpHeaders.setCookieHeader]?.join(';'),
        );

  factory MutableHeadersImpl.from(Object? object) {
    if (object is MutableHeadersImpl) {
      return object;
    } else if (object is HttpHeaders) {
      final map = <String, List<String>>{};

      object.forEach((key, values) {
        map[key] = values;
      });

      return MutableHeadersImpl(map);
    }

    final converted = switch (object) {
      Map<String, List<String>>() => {...object},
      Map<String, String>() => {
          for (final entry in object.entries) entry.key: [entry.value],
        },
      null => <String, List<String>>{},
      _ => throw ArgumentError(
          'Unsupported data type for '
          '$MutableHeadersImpl: ${object.runtimeType}',
        ),
    };

    return MutableHeadersImpl(converted);
  }

  final CaseInsensitiveMap<Iterable<String>> _headers;

  @override
  String? operator [](String value) {
    return get(value);
  }

  @override
  void operator []=(String key, String value) {
    set(key, value);
  }

  @override
  String? get(String key) {
    final result = _headers[key];

    /// See https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-p1-messaging-21#page-22
    return switch (result?.length) {
      null => null,
      0 => null,
      1 => result?.first,
      _ => result?.join(', '),
    };
  }

  @override
  List<String>? getAll(String key) {
    if (!_headers.containsKey(key)) {
      return null;
    }

    Iterable<String> iterate() sync* {
      for (final header in _headers[key] ?? <String>[]) {
        yield* header.split(',');
      }
    }

    return iterate().toList();
  }

  @override
  void add(String key, String value) {
    _headers[key] = (_headers[key] ?? []).followedBy([value]);
  }

  @override
  void set(String key, String value) {
    _headers[key] = [value];
  }

  void setAll(String key, List<String> value) {
    _headers[key] = value;
  }

  @override
  Iterable<String> get keys {
    return values.keys;
  }

  @override
  void addAll(Map<String, String> headers) {
    for (final MapEntry(:key, :value) in headers.entries) {
      set(key, value);
    }
  }

  @override
  void remove(String key) {
    _headers.removeWhere((header, value) => equalsIgnoreAsciiCase(header, key));
  }

  @override
  void forEach(void Function(String key, Iterable<String> value) f) {
    for (final MapEntry(:key, :value) in values.entries) {
      f(key, value);
    }
  }

  void syncWith(ReadOnlyRequest request) {
    if (request.headers.encoding case final otherEncoding
        when encoding == otherEncoding) {}
  }

  @override
  Map<String, List<String>> get values => Map.unmodifiable({
        for (final MapEntry(:key, :value) in _headers.entries)
          key: value.toList(),
        if (cookies.isNotEmpty) cookies.headerKey: [cookies.headerValue()],
        if (setCookies.isNotEmpty)
          setCookies.headerKey: [setCookies.headerValue()],
      });

  @override
  Map<K2, V2> map<K2, V2>(
    MapEntry<K2, V2> Function(String key, Iterable<String> values) convert,
  ) {
    return values.map(convert);
  }

  @override
  set contentLength(int? value) {
    if (value == null) {
      remove(HttpHeaders.contentLengthHeader);
    } else {
      set(HttpHeaders.contentLengthHeader, '$value');
    }
  }

  @override
  set contentType(MediaType? value) {
    if (value == null) {
      remove(HttpHeaders.contentTypeHeader);
    } else {
      set(HttpHeaders.contentTypeHeader, value.toString());
    }
  }

  @override
  // ignore: avoid_setters_without_getters
  set contentTypeString(String? value) {
    if (value == null) {
      remove(HttpHeaders.contentTypeHeader);
    } else {
      set(HttpHeaders.contentTypeHeader, value);
    }
  }

  @override
  set encoding(Encoding value) {
    set(HttpHeaders.contentEncodingHeader, value.name);
  }

  @override
  set ifModifiedSince(DateTime? value) {
    if (value == null) {
      remove(HttpHeaders.ifModifiedSinceHeader);
    } else {
      set(HttpHeaders.ifModifiedSinceHeader, formatHttpDate(value));
    }
  }

  @override
  set mimeType(String? value) {
    if (value == null) {
      remove(HttpHeaders.contentTypeHeader);
    } else {
      set(HttpHeaders.contentTypeHeader, value);
    }
  }

  @override
  set lastModified(DateTime? value) {
    if (value == null) {
      remove(HttpHeaders.lastModifiedHeader);
    } else {
      set(HttpHeaders.lastModifiedHeader, formatHttpDate(value));
    }
  }

  @override
  set origin(String? value) {
    if (value == null) {
      remove(HttpHeaders.accessControlAllowOriginHeader);
    } else {
      set(HttpHeaders.accessControlAllowOriginHeader, value);
    }
  }

  @override
  set transferEncoding(String? value) {
    if (value == null) {
      remove(HttpHeaders.transferEncodingHeader);
    } else {
      set(HttpHeaders.transferEncodingHeader, value);
    }
  }

  @override
  set contentRange((int, int, int)? value) {
    if (value == null) {
      remove(HttpHeaders.contentRangeHeader);
    } else {
      final (start, end, total) = value;
      set(HttpHeaders.contentRangeHeader, 'bytes $start-$end/$total');
    }
  }

  @override
  set filename(String? value) {
    if (value == null) {
      remove(HttpHeaders.contentDisposition);
    } else {
      set(
        HttpHeaders.contentDisposition,
        'attachment; filename="${Uri.encodeComponent(value)}"',
      );
    }
  }

  @override
  set acceptRanges(String? value) {
    if (value == null) {
      remove(HttpHeaders.acceptRangesHeader);
    } else {
      set(HttpHeaders.acceptRangesHeader, value);
    }
  }

  @override
  void clear() {
    _headers.clear();
    cookies.clear();
    setCookies.clear();
  }

  @override
  void addEverything(Map<String, Iterable<String>> headers) {
    _headers.addAll(headers);
  }

  @override
  bool get isEmpty => values.isEmpty;

  @override
  bool get isNotEmpty => values.isNotEmpty;

  @override
  int get length => values.length;

  @override
  final MutableCookies cookies;

  @override
  final MutableSetCookies setCookies;
}
