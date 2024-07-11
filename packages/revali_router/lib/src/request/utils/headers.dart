import 'package:collection/collection.dart';

Map<String, List<String>>? expandToHeadersAll(
  Map<String, /* String | List<String> */ Object>? headers,
) {
  if (headers is Map<String, List<String>>) return headers;
  if (headers == null || headers.isEmpty) return null;

  return Map.fromEntries(headers.entries.map((e) {
    return MapEntry(e.key, expandHeaderValue(e.value));
  }));
}

List<String> expandHeaderValue(Object v) {
  if (v is String) {
    return [v];
  } else if (v is List<String>) {
    return v;
  } else if ((v as dynamic) == null) {
    return const [];
  } else {
    throw ArgumentError('Expected String or List<String>, got: `$v`.');
  }
}

/// Adds a header with [name] and [value] to [headers], which may be null.
///
/// Returns a new map without modifying [headers].
Map<String, Object> addHeader(
  Map<String, Object>? headers,
  String name,
  String value,
) {
  headers = headers == null ? {} : Map.from(headers);
  headers[name] = value;
  return headers;
}

/// Returns the header with the given [name] in [headers].
///
/// This works even if [headers] is `null`, or if it's not yet a
/// case-insensitive map.
String? findHeader(Map<String, List<String>?>? headers, String name) {
  if (headers == null) return null;

  for (var key in headers.keys) {
    if (equalsIgnoreAsciiCase(key, name)) {
      return joinHeaderValues(headers[key]);
    }
  }
  return null;
}

/// Multiple header values are joined with commas.
/// See https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-p1-messaging-21#page-22
String? joinHeaderValues(List<String>? values) {
  if (values == null) return null;
  if (values.isEmpty) return '';
  if (values.length == 1) return values.single;
  return values.join(',');
}
