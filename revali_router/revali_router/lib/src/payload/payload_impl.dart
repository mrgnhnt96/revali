import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:revali_router/src/body/mutable_body_impl.dart';
import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:revali_router/src/exceptions/payload_resolve_exception.dart';
import 'package:revali_router/utils/coerce.dart' as type;
import 'package:revali_router_core/revali_router_core.dart';

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
      String() => Stream.fromIterable([encoded ?? []]),
      null => Stream.fromIterable([encoded ?? []]),
      List() => Stream.value(encoded ?? []),
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

  static Map<String, BodyParser> additionalParsers = {};

  final Stream<List<int>> _stream;
  @override
  final int? contentLength;

  List<int>? _bytes;
  StreamController<List<int>>? _backupStream;
  @override
  Stream<List<int>> read() async* {
    if (_bytes case final bytes?) {
      yield* Stream.value(bytes);
      return;
    }

    if (_backupStream case final bytes?) {
      yield* bytes.stream;
      return;
    }

    _backupStream ??= StreamController.broadcast();

    await for (final chunk in _stream) {
      yield chunk;
      _backupStream?.add(chunk);
      (_bytes ??= []).addAll(chunk);
    }
  }

  Future<BodyData?> coerce(ReadOnlyHeaders headers) async {
    final encoding = headers.encoding;

    if (headers.mimeType case String()) {
      return resolve(headers);
    }

    final options = {
      'application/json': () => _resolveJson(encoding),
      'application/x-www-form-urlencoded': () => _resolveFormUrl(encoding),
      if (headers.contentType case final MediaType contentType)
        'multipart/form-data': () => _resolveFormData(encoding, contentType),
      'text/plain': () => _resolveString(encoding),
      'application/octet-stream': () => _resolveBinary(encoding),
      '': () =>
          additionalParsers[headers.mimeType]
              ?.parse(encoding, read(), headers) ??
          _resolveUnknown(encoding, headers.mimeType),
    };

    for (final attempt in options.values) {
      try {
        if (await attempt() case final resolved) {
          return resolved;
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  @override
  Future<BodyData> resolve(ReadOnlyHeaders headers) async {
    final encoding = headers.encoding;

    try {
      final bodyData = await switch (headers.mimeType) {
        'application/json' => _resolveJson(encoding),
        'application/x-www-form-urlencoded' => _resolveFormUrl(encoding),
        'multipart/form-data' =>
          _resolveFormData(encoding, headers.contentType),
        'text/plain' => _resolveString(encoding),
        'application/octet-stream' => _resolveBinary(encoding),
        _ => additionalParsers[headers.mimeType]
                ?.parse(encoding, read(), headers) ??
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
  ) async {
    final content = await encoding.decodeStream(read());
    if (!content.contains('=')) {
      throw const FormatException('Invalid form data');
    }

    final data = Uri.splitQueryString(content, encoding: encoding);

    final coerced = {
      for (final entry in data.entries) entry.key: type.coerce(entry.value),
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
        final content = type.coerce(await encoding.decodeStream(part));
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

  @override
  String readAsString({Encoding encoding = utf8}) {
    final bytes = _bytes;
    if (bytes == null) {
      throw StateError('Payload has not been resolved');
    }

    return encoding.decode(bytes);
  }

  @override
  Future<void> close() async {
    await _backupStream?.close();
  }
}
