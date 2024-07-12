import 'dart:io';

import 'package:collection/collection.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_router/src/body/read_only_body.dart';
import 'package:revali_router/src/headers/common_headers_mixin.dart';
import 'package:revali_router/src/headers/mutable_headers.dart';

typedef _Headers = Map<String, List<String>>;

class MutableHeadersImpl extends CommonHeadersMixin implements MutableHeaders {
  MutableHeadersImpl([_Headers? headers]) : _headers = headers ?? {};

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

  final _Headers _headers;

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

  void syncWith(ReadOnlyRequestContext request) {
    if (request.headers.encoding case final otherEncoding
        when encoding == otherEncoding) {}
  }

  @override
  void reactToBody(ReadOnlyBody body) {
    if (body.contentLength case final length) {
      if (length == null) {
        remove(HttpHeaders.contentLengthHeader);
      } else {
        set(HttpHeaders.contentLengthHeader, '$length');
      }
    }

    // mimetype
    if (body.mimeType case final mimeType) {
      if (mimeType == null) {
        remove(HttpHeaders.contentTypeHeader);
      } else {
        set(HttpHeaders.contentTypeHeader, mimeType);
      }
    }
  }

  @override
  void reactToStatusCode(int code) {
    switch (code) {
      case HttpStatus.noContent:
        remove(HttpHeaders.contentLengthHeader);
        remove(HttpHeaders.contentTypeHeader);
        break;
      default:
        break;
    }
  }
}

// TODO(mrgnhnt): Implement the following methods
// ignore: unused_element
const _a = '';
// /// Adds content-type information to [headers].
// ///
// /// Returns a new map without modifying [headers]. This is used to add
// /// content-type information when creating a 500 response with a default body.
// Map<String, Object> _adjustErrorHeaders(
//     Map<String, /* String | List<String> */ Object>? headers) {
//   if (headers == null || headers['content-type'] == null) {
//     return addHeader(headers, 'content-type', 'text/plain');
//   }

//   final contentTypeValue =
//       expandHeaderValue(headers['content-type']!).join(',');
//   var contentType =
//       MediaType.parse(contentTypeValue).change(mimeType: 'text/plain');
//   return addHeader(headers, 'content-type', contentType.toString());
// }

// /// Adds information about [encoding] to [headers].
// ///
// /// Returns a new map without modifying [headers].
// Map<String, List<String>> _adjustHeaders(
//   Map<String, List<String>>? headers,
//   Payload body,
// ) {
//   var sameEncoding = _sameEncoding(headers, body);
//   if (sameEncoding) {
//     if (body.contentLength == null ||
//         findHeader(headers, 'content-length') == '${body.contentLength}') {
//       return headers ?? {};
//     } else if (body.contentLength == 0 &&
//         (headers == null || headers.isEmpty)) {
//       return {
//         'content-length': ['0'],
//       };
//     }
//   }

//   var newHeaders = headers == null
//       ? CaseInsensitiveMap<List<String>>()
//       : CaseInsensitiveMap<List<String>>.from(headers);

//   if (!sameEncoding) {
//     if (newHeaders['content-type'] == null) {
//       newHeaders['content-type'] = [
//         'application/octet-stream; charset=${body.encoding!.name}'
//       ];
//     } else {
//       final contentType =
//           MediaType.parse(joinHeaderValues(newHeaders['content-type'])!)
//               .change(parameters: {'charset': body.encoding!.name});
//       newHeaders['content-type'] = [contentType.toString()];
//     }
//   }

//   final explicitOverrideOfZeroLength =
//       body.contentLength == 0 && findHeader(headers, 'content-length') != null;

//   if (body.contentLength != null && !explicitOverrideOfZeroLength) {
//     final coding = joinHeaderValues(newHeaders['transfer-encoding']);
//     if (coding == null || equalsIgnoreAsciiCase(coding, 'identity')) {
//       newHeaders['content-length'] = [body.contentLength.toString()];
//     }
//   }

//   return newHeaders;
// }
