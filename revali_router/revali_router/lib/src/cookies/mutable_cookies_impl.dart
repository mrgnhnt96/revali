import 'dart:io';

import 'package:http_parser/http_parser.dart';
import 'package:revali_router_core/revali_router_core.dart';

class MutableCookiesImpl implements MutableCookies {
  MutableCookiesImpl([Map<String, String?>? values])
      : _values = CaseInsensitiveMap<String?>.from(values ?? {});
  factory MutableCookiesImpl.fromHeader(String? value) {
    if (value == null) {
      return MutableCookiesImpl();
    }

    final values = <String, String?>{};
    final parts = value.split(';');

    for (final cookie in parts) {
      final parts = cookie.split('=');

      var [String? name, String? value] = switch (parts.length) {
        1 => [parts[0].trim(), null],
        >= 2 => [parts[0].trim(), parts[1].trim()],
        _ => [null, null],
      };

      if (name == null || name.isEmpty) continue;

      if (name.startsWith('"') && name.endsWith('"')) {
        name = name.substring(1, name.length - 1);
      }

      if (value != null) {
        if (value.startsWith('"') && value.endsWith('"')) {
          value = value.substring(1, value.length - 1);
        }
      }

      values[name] = value;
    }

    return MutableCookiesImpl(values);
  }

  final CaseInsensitiveMap<String?> _values;

  @override
  String? operator [](String key) => _values[key];

  @override
  void operator []=(String key, String? value) {
    final cookie = Cookie(key.trim(), value?.trim() ?? '');

    _values[cookie.name] = switch (value) {
      null => null,
      _ => cookie.value,
    };
    _values[key.trim()] = value?.trim();
  }

  @override
  void clear() {
    _values.clear();
  }

  @override
  List<MapEntry<String, String?>> get entries => _values.entries.toList();

  @override
  bool get isEmpty => _values.isEmpty;

  @override
  bool get isNotEmpty => _values.isNotEmpty;

  @override
  List<String> get keys => _values.keys.toList();

  @override
  int get length => _values.length;

  @override
  void remove(String key) => _values.remove(key);

  @override
  List<String> get values => _values.values.whereType<String>().toList();

  @override
  String get headerKey => HttpHeaders.cookieHeader;

  @override
  String headerValue() {
    final buffer = StringBuffer();

    for (final MapEntry(key: name, :value) in _values.entries) {
      final entry = switch (value) {
        String() when value.isNotEmpty => '$name=$value; ',
        _ => '$name; ',
      };

      buffer.write(entry);
    }

    return buffer.toString();
  }

  @override
  bool containsKey(String key) => _values.containsKey(key);

  @override
  Map<String, String?> get all => Map.unmodifiable(_values);

  @override
  void add(String key, String? value) {
    _values[key] = value;
  }
}
