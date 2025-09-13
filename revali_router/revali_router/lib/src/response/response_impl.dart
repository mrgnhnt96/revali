import 'dart:io';

import 'package:revali_router/src/body/body_impl.dart';
import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:revali_router/src/headers/headers_impl.dart';
import 'package:revali_router_core/revali_router_core.dart';

class ResponseImpl implements Response {
  ResponseImpl({
    required Headers requestHeaders,
    Headers? headers,
  })  : _requestHeaders = requestHeaders,
        _body = BodyImpl(),
        headers = headers != null
            ? HeadersImpl({
                for (final key in headers.keys) key: headers.getAll(key) ?? [],
              })
            : HeadersImpl();

  factory ResponseImpl.from(Response response) {
    if (response is ResponseImpl) {
      return response;
    }

    final result = ResponseImpl(
      requestHeaders: HeadersImpl(),
      headers: response.headers,
    );

    try {
      result
        ..statusCode = response.statusCode
        ..body = response.body;
    } catch (e) {
      result.statusCode = HttpStatus.internalServerError;
    }

    return result;
  }

  final Headers _requestHeaders;

  int _statusCode = 200;
  @override
  int get statusCode => _statusCode;
  @override
  set statusCode(int value) {
    _statusCode = value;
  }

  final Body _body;
  @override
  Body get body => _body;

  @override
  set body(Object? newBody) {
    _body.replace(newBody).catchError((e) {
      _statusCode = HttpStatus.internalServerError;
    });

    if (_body.data case final FileBodyData body) {
      final file = body.file;
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
  final Headers headers;

  @override
  set headers(Headers newValue) {
    headers
      ..clear()
      ..addEverything(newValue.values);
  }

  @override
  Headers get joinedHeaders {
    final headers = HeadersImpl.from(this.headers);

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
