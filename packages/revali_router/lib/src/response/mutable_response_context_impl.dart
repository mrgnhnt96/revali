import 'dart:io';

import 'package:revali_router/revali_router.dart';
import 'package:revali_router_core/revali_router_core.dart';

class MutableResponseContextImpl implements MutableResponseContext {
  MutableResponseContextImpl({
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
  BodyData get body => _body;

  void set body(Object? newBody) {
    _body.replace(newBody);
  }

  MutableHeaders _headers;
  @override
  MutableHeaders get headers {
    final headers = MutableHeadersImpl();

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

// TODO(mrgnhnt): Implement the following methods
// ignore: unused_element
const _a = '';

/// Serves a range of [file], if [request] is valid 'bytes' range request.
///
/// If the request does not specify a range, specifies a range of the wrong
/// type, or has a syntactic error the range is ignored and `null` is returned.
///
/// If the range request is valid but the file is not long enough to include the
/// start of the range a range not satisfiable response is returned.
///
/// Ranges that end past the end of the file are truncated.
// Response? _fileRangeResponse(
//   RequestContext request,
//   File file,
//   Map<String, Object> headers,
// ) {
//   final _bytesMatcher = RegExp(r'^bytes=(\d*)-(\d*)$');

//   final range = request.headers[HttpHeaders.rangeHeader];
//   if (range == null) return null;
//   final matches = _bytesMatcher.firstMatch(range);
//   // Ignore ranges other than bytes
//   if (matches == null) return null;

//   final actualLength = file.lengthSync();
//   final startMatch = matches[1]!;
//   final endMatch = matches[2]!;
//   if (startMatch.isEmpty && endMatch.isEmpty) return null;

//   int start; // First byte position - inclusive.
//   int end; // Last byte position - inclusive.
//   if (startMatch.isEmpty) {
//     start = actualLength - int.parse(endMatch);
//     if (start < 0) start = 0;
//     end = actualLength - 1;
//   } else {
//     start = int.parse(startMatch);
//     end = endMatch.isEmpty ? actualLength - 1 : int.parse(endMatch);
//   }

//   // If the range is syntactically invalid the Range header
//   // MUST be ignored (RFC 2616 section 14.35.1).
//   if (start > end) return null;

//   if (end >= actualLength) {
//     end = actualLength - 1;
//   }
//   if (start >= actualLength) {
//     return Response(
//       HttpStatus.requestedRangeNotSatisfiable,
//       headers: headers,
//     );
//   }
//   return Response(
//     HttpStatus.partialContent,
//     body: request.method == 'HEAD' ? null : file.openRead(start, end + 1),
//     headers: headers
//       ..[HttpHeaders.contentLengthHeader] = (end - start + 1).toString()
//       ..[HttpHeaders.contentRangeHeader] = 'bytes $start-$end/$actualLength',
//   );
// }
