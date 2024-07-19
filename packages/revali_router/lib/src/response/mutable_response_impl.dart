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
        _headers = MutableHeadersImpl();

  final ReadOnlyHeaders _requestHeaders;

  int _statusCode = 200;
  @override
  int get statusCode => _statusCode;
  void set statusCode(int value) {
    _statusCode = value;
  }

  final MutableBody _body;
  @override
  MutableBody get body => _body;

  void set body(Object? newBody) {
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

  MutableHeaders _headers;
  @override
  MutableHeaders get headers {
    final headers = MutableHeadersImpl({
      HttpHeaders.contentLengthHeader: ['0'],
    });

    _headers.forEach((key, value) {
      headers.setAll(key, value);
    });

    body.headers(_requestHeaders).forEach((key, value) {
      headers.setAll(key, value);
    });
    headers.setIfAbsent(HttpHeaders.contentTypeHeader, () {
      return body.mimeType ?? 'text/plain';
    });

    void removeContentRelated(MutableHeaders headers) {
      headers
        ..remove(HttpHeaders.contentTypeHeader)
        ..remove(HttpHeaders.contentLengthHeader)
        ..remove(HttpHeaders.contentEncodingHeader)
        ..remove(HttpHeaders.transferEncodingHeader)
        ..remove(HttpHeaders.contentRangeHeader)
        ..remove(HttpHeaders.acceptRangesHeader)
        ..remove(HttpHeaders.contentDisposition)
        ..remove(HttpHeaders.contentLanguageHeader)
        ..remove(HttpHeaders.contentLocationHeader)
        ..remove(HttpHeaders.contentMD5Header);
    }

    void removeAccessControl(MutableHeaders headers) {
      headers
        ..remove(HttpHeaders.allowHeader)
        ..remove(HttpHeaders.accessControlAllowOriginHeader)
        ..remove(HttpHeaders.accessControlAllowCredentialsHeader)
        ..remove(HttpHeaders.accessControlExposeHeadersHeader)
        ..remove(HttpHeaders.accessControlMaxAgeHeader)
        ..remove(HttpHeaders.accessControlAllowMethodsHeader)
        ..remove(HttpHeaders.accessControlAllowHeadersHeader)
        ..remove(HttpHeaders.accessControlRequestHeadersHeader)
        ..remove(HttpHeaders.accessControlRequestMethodHeader);
    }

    switch (statusCode) {
      case HttpStatus.notModified:
      case HttpStatus.noContent:
        removeContentRelated(headers);
        break;
      case HttpStatus.notFound:
        removeContentRelated(headers);
        removeAccessControl(headers);
        break;
      default:
        break;
    }

    return headers;
  }
}

extension _DateTimeX on DateTime {
  DateTime toSecondResolution() {
    if (millisecond == 0) return this;
    return subtract(Duration(milliseconds: millisecond));
  }
}
