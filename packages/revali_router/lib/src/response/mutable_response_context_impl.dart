import 'package:revali_router/src/body/mutable_body.dart';
import 'package:revali_router/src/body/mutable_body_impl.dart';
import 'package:revali_router/src/headers/mutable_headers.dart';
import 'package:revali_router/src/headers/mutable_headers_impl.dart';
import 'package:revali_router/src/headers/read_only_headers.dart';
import 'package:revali_router/src/response/mutable_response_context.dart';

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
    headers.reactToStatusCode(value);
  }

  final MutableBody _body;
  @override
  MutableBody get body => _body;

  void set body(Object? data) {
    body.replace(data);
    headers.reactToBody(body);
  }

  final MutableHeadersImpl _headers;
  @override
  MutableHeaders get headers => _headers;
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
