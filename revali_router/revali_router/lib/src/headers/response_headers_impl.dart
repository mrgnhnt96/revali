import 'package:revali_router/src/headers/headers_impl.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';

class ResponseHeadersImpl extends HeadersImpl implements ResponseHeaders {
  ResponseHeadersImpl([super.headers]);

  factory ResponseHeadersImpl.from(Object? object) {
    if (object is ResponseHeadersImpl) {
      return object;
    }

    final headers = HeadersImpl.from(object);
    if (headers is ResponseHeadersImpl) {
      return headers;
    }

    return ResponseHeadersImpl(headers.values);
  }
}
