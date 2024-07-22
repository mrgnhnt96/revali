import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http_parser/http_parser.dart';
import 'package:revali_router/src/headers/common_headers_mixin.dart';
import 'package:revali_router_core/revali_router_core.dart';

class MutableHeadersImpl extends CommonHeadersMixin implements MutableHeaders {
  MutableHeadersImpl([Map<String, List<String>>? headers])
      : _headers = CaseInsensitiveMap.from(headers ?? {});

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

    final Map<String, List<String>> converted = switch (object) {
      Map<String, List<String>>() => {...object},
      Map<String, String>() => {
          for (final entry in object.entries) entry.key: [entry.value],
        },
      null => {},
      _ => throw ArgumentError(
          'Unsupported data type for $MutableHeadersImpl: ${object.runtimeType}',
        ),
    };

    return MutableHeadersImpl(converted);
  }

  final CaseInsensitiveMap<List<String>> _headers;

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
    return _headers[key];
  }

  @override
  void set(String key, String value) {
    (_headers[key] ??= []).add(value);
  }

  void setAll(String key, List<String> value) {
    (_headers[key] ??= []).addAll(value);
  }

  @override
  Iterable<String> get keys {
    return _headers.keys;
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
  void forEach(void Function(String key, List<String> value) f) {
    for (final MapEntry(:key, :value) in _headers.entries) {
      f(key, value);
    }
  }

  void syncWith(ReadOnlyRequest request) {
    if (request.headers.encoding case final otherEncoding
        when encoding == otherEncoding) {}
  }

  Map<String, List<String>> get values => Map.unmodifiable(_headers);

  void setIfAbsent(String contentTypeHeader, String Function() setter) {
    if (_headers[contentTypeHeader] == null) {
      set(contentTypeHeader, setter());
    }
  }

  @override
  Map<K2, V2> map<K2, V2>(
    MapEntry<K2, V2> Function(String key, List<String> values) convert,
  ) {
    return _headers.map(convert);
  }
}
