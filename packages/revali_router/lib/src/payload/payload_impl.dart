import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:revali_router/src/body/mutable_body_impl.dart';
import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:revali_router/src/exceptions/payload_resolve_exception.dart';
import 'package:revali_router/utils/coerce.dart';
import 'package:revali_router_core/body/body_data.dart';
import 'package:revali_router_core/headers/read_only_headers.dart';
import 'package:revali_router_core/payload/payload.dart';

class PayloadImpl implements Payload {
  factory PayloadImpl(
    Object? body, {
    required Encoding encoding,
  }) {
    if (body is PayloadImpl) return body;

    final encoded = switch (body) {
      String() => encoding.encode(body),
      List<int>() => body,
      List() => body.cast<int>(),
      null => <int>[],
      Stream() => null,
      _ => throw ArgumentError(
          'Body must be a String, List<int>, or a Stream.',
        ),
    };

    final stream = switch (body) {
      String() => Stream.fromIterable([encoded!]),
      null => Stream.fromIterable([encoded!]),
      List() => Stream.value(encoded!),
      Stream<List<int>>() => body,
      Stream() => body.cast<List<int>>(),
      _ => throw ArgumentError(
          'Body must be a String, List<int>, or a Stream.',
        ),
    };

    return PayloadImpl._(
      stream: stream,
      contentLength: encoded?.length,
    );
  }

  factory PayloadImpl.encoded(
    dynamic body, {
    required Encoding encoding,
  }) {
    final bytes = switch (body) {
      List<int>() => body,
      List() => body.cast<int>(),
      _ => null,
    };

    if (bytes != null) {
      return PayloadImpl._(
        stream: Stream.value(bytes),
        contentLength: bytes.length,
      );
    }

    if (body is! String) {
      throw ArgumentError('Body must be a String or a List<int>.');
    }

    final encoded = encoding.encode(body);

    return PayloadImpl._(
      stream: Stream.value(encoded),
      contentLength: encoded.length,
    );
  }

  PayloadImpl._({
    required Stream<List<int>> stream,
    this.contentLength,
  }) : _stream = stream;

  static Map<String, Future<BodyData> Function(Encoding, Stream<List<int>>)>
      additionalParsers = {};

  final Stream<List<int>> _stream;
  @override
  final int? contentLength;

  List<int>? _bytes;
  @override
  Stream<List<int>> read() async* {
    if (_bytes != null) {
      yield _bytes!;
      return;
    }

    final bytes = await _stream.toList();

    _bytes = bytes.expand<int>((e) => e).toList();

    yield _bytes!;
  }

  @override
  Future<BodyData> resolve(ReadOnlyHeaders headers) async {
    final encoding = headers.encoding;

    try {
      final bodyData = await switch (headers.mimeType) {
        'application/json' => _resolveJson(encoding),
        'application/x-www-form-urlencoded' =>
          _resolveFormUrl(encoding, headers.contentType),
        'multipart/form-data' =>
          _resolveFormData(encoding, headers.contentType),
        'text/plain' => _resolveString(encoding),
        'application/octet-stream' => _resolveBinary(encoding),
        _ => additionalParsers[headers.mimeType]?.call(encoding, read()) ??
            _resolveUnknown(encoding, headers.mimeType),
      };

      return MutableBodyImpl(bodyData);
    } catch (e) {
      final data = <String>[];
      await for (final chunk in read()) {
        data.add(encoding.decode(chunk));
      }

      throw PayloadResolveException(
        encoding: encoding.name,
        contentType: headers.mimeType,
        content: data.join('\n'),
        innerException: e,
      );
    }
  }

  Future<JsonData<dynamic>> _resolveJson(Encoding encoding) async {
    final json = await encoding.decodeStream(read());

    if (json.isEmpty) {
      return JsonBodyData({});
    }

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

    throw const FormatException('Invalid JSON data');
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
      throw const FormatException('Content-Type header is missing');
    }

    final boundary = contentType.parameters['boundary'];
    if (boundary == null) {
      throw const FormatException('Boundary parameter is missing');
    }

    final transformer = MimeMultipartTransformer(boundary);
    final parts = await transformer.bind(read()).toList();

    final data = <String, dynamic>{};
    for (final part in parts) {
      final disposition = part.headers['content-disposition'];
      if (disposition == null) continue;

      final headers = HeaderValue.parse(disposition);
      final name = headers.parameters['name'];

      if (name == null) continue;
      final filename = headers.parameters['filename'];

      if (filename != null) {
        final bytes = await part.fold<List<int>>([], (a, b) => a..addAll(b));
        final content = encoding.decode(bytes);
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
