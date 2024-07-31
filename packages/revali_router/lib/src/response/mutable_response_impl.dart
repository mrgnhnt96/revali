import 'dart:io';

import 'package:revali_router/src/body/mutable_body_impl.dart';
import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:revali_router/src/headers/mutable_headers_impl.dart';
import 'package:revali_router_core/revali_router_core.dart';

class MutableResponseImpl implements MutableResponse {
  MutableResponseImpl({
    required ReadOnlyHeaders requestHeaders,
  })  : _requestHeaders = requestHeaders,
        _body = MutableBodyImpl(),
        headers = MutableHeadersImpl();

  final ReadOnlyHeaders _requestHeaders;

  int _statusCode = 200;
  @override
  int get statusCode => _statusCode;
  @override
  set statusCode(int value) {
    _statusCode = value;
  }

  final MutableBody _body;
  @override
  MutableBody get body => _body;

  @override
  set body(Object? newBody) {
    _body.replace(newBody);

    if (_body is FileBodyData) {
      final file = (_body as FileBodyData).file;
      final stat = file.statSync();
      if (stat.type == FileSystemEntityType.notFound) {
        _statusCode = HttpStatus.notFound;
        return;
      }

      if (_requestHeaders.ifModifiedSince case final date?) {
        final modified = stat.modified.toSecondResolution();
        if (modified.isBefore(date)) {
          _statusCode = HttpStatus.notModified;
          return;
        }
      }
    }
  }

  @override
  final MutableHeaders headers;

  @override
  MutableHeaders get headersToSend {
    final headers = MutableHeadersImpl.from(this.headers);

    _body.headers(_requestHeaders).forEach((key, values) {
      headers[key] ??= values.join(',');
    });

    return headers;
  }
}

extension _DateTimeX on DateTime {
  DateTime toSecondResolution() {
    if (millisecond == 0) return this;
    return subtract(Duration(milliseconds: millisecond));
  }
}
