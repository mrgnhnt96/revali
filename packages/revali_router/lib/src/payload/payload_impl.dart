import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:revali_router/src/body/mutable_body_impl.dart';
import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:revali_router_core/body/body_data.dart';
import 'package:revali_router_core/headers/read_only_headers.dart';
import 'package:revali_router_core/payload/payload.dart';

class PayloadImpl implements Payload {
  PayloadImpl._({
    required Stream<List<int>> stream,
    this.contentLength,
  }) : _stream = stream;

  factory PayloadImpl(Object? body) {
    if (body is PayloadImpl) return body;

    final List<int>? encoded = switch (body) {
      String() => utf8.encode(body),
      List<int>() => body,
      List() => body.cast(),
      null => [],
      Stream() => null,
      _ => throw ArgumentError(
          'Body must be a String, List<int>, or a Stream.',
        ),
    };

    final Stream<List<int>> stream = switch (body) {
      String() => Stream.fromIterable([encoded!]),
      null => Stream.fromIterable([encoded!]),
      List() => Stream.value(encoded!),
      Stream<List<int>>() => body,
      Stream() => body.cast(),
      _ => throw ArgumentError(
          'Body must be a String, List<int>, or a Stream.',
        ),
    };

    return PayloadImpl._(
      stream: stream,
      contentLength: encoded?.length,
    );
  }

  static Map<String, Future<BodyData> Function(Encoding, Stream<List<int>>)>
      additionalParsers = {};

  final Stream<List<int>> _stream;
  final int? contentLength;

  static bool _isPlainAscii(List<int> bytes, int codeUnits) {
    // Most non-ASCII code units will produce multiple bytes and make the text
    // longer.
    if (bytes.length != codeUnits) return false;

    // Non-ASCII code units between U+0080 and U+009F produce 8-bit characters
    // with the high bit set.
    return bytes.every((byte) => byte & 0x80 == 0);
  }

  List<int>? _bytes;
  Stream<List<int>> read() async* {
    if (_bytes != null) {
      yield _bytes!;
      return;
    }

    final bytes = await _stream.toList();

    _bytes = bytes.expand<int>((e) => e).toList();

    yield _bytes!;
  }

  Future<BodyData> resolve(ReadOnlyHeaders headers) async {
    final encoding = headers.encoding;

    final bodyData = await switch (headers.mimeType) {
      'application/json' => _resolveJson(encoding),
      'application/x-www-form-urlencoded' =>
        _resolveFormUrl(encoding, headers.contentType),
      'multipart/form-data' => _resolveFormData(encoding, headers.contentType),
      'text/plain' => _resolveString(encoding),
      'application/octet-stream' => _resolveBinary(encoding),
      _ => additionalParsers[headers.mimeType]?.call(encoding, read()) ??
          _resolveUnknown(encoding, headers.mimeType),
    };

    return MutableBodyImpl(bodyData);
  }

  Future<JsonData> _resolveJson(Encoding encoding) async {
    final json = await encoding.decodeStream(read());

    final data = jsonDecode(json);

    if (data is List) {
      return ListBodyData(data);
    } else if (data is Map) {
      if (data is Map<String, dynamic>) {
        return JsonBodyData(data);
      } else {
        return JsonBodyData({
          for (final entry in data.entries) '${entry.key}': entry.value,
        });
      }
    }

    throw FormatException('Invalid JSON data');
  }

  Future<FormDataBodyData> _resolveFormUrl(
    Encoding encoding,
    MediaType? contentType,
  ) async {
    final content = await encoding.decodeStream(read());
    final data = Uri.splitQueryString(content);

    final coerced = {
      for (final entry in data.entries) entry.key: coerce(entry.value),
    };

    return FormDataBodyData(coerced);
  }

  Future<FormDataBodyData> _resolveFormData(
    Encoding encoding,
    MediaType? contentType,
  ) async {
    if (contentType == null) {
      throw FormatException('Content-Type header is missing');
    }

    final boundary = contentType.parameters['boundary'];
    if (boundary == null) {
      throw FormatException('Boundary parameter is missing');
    }

    final transformer = MimeMultipartTransformer(boundary);
    final parts = await transformer.bind(read()).toList();

    final data = Map<String, dynamic>();
    for (final part in parts) {
      final disposition = part.headers['content-disposition'];
      if (disposition == null) continue;

      final headers = HeaderValue.parse(disposition);
      final name = headers.parameters['name'];

      if (name == null) continue;
      final filename = headers.parameters['filename'];

      if (filename != null) {
        final bytes = await part.fold<List<int>>([], (a, b) => a..addAll(b));
        final content = await encoding.decode(bytes);
        data[name] = {
          'filename': filename,
          'content': content,
          'bytes': bytes,
        };
      } else {
        final content = coerce(await encoding.decodeStream(part));
        data[name] = content;
      }
    }

    return FormDataBodyData(data);
  }

  Future<StringBodyData> _resolveString(Encoding encoding) async {
    final data = await encoding.decodeStream(read());

    return StringBodyData(data);
  }

  Future<BinaryBodyData> _resolveBinary(Encoding encoding) async {
    final data = await read().toList();

    return BinaryBodyData(data);
  }

  Future<UnknownBodyData> _resolveUnknown(
    Encoding encoding,
    String? mimeType,
  ) async {
    final data = await read().toList();

    return UnknownBodyData(data, mimeType: mimeType);
  }
}

dynamic coerce(dynamic value) {
  final attempts = [
    () => int.parse(value),
    () => double.parse(value),
    () => (jsonDecode(value) as List).map(coerce),
    () => {
          for (final item in (jsonDecode(value) as Map).entries)
            item.key: coerce(item.value),
        },
    () => switch (value) {
          'true' => true,
          'false' => false,
          _ => throw '',
        },
    () => value,
  ];

  for (final attempt in attempts) {
    try {
      final result = attempt();

      return result;
    } catch (_) {}
  }

  throw FormatException('Failed to coerce value: $value');
}
