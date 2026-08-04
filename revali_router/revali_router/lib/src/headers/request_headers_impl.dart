import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_router/src/headers/headers_impl.dart';

class RequestHeadersImpl extends HeadersImpl implements RequestHeaders {
  RequestHeadersImpl([super.headers]);

  factory RequestHeadersImpl.from(Object? object) {
    if (object is RequestHeadersImpl) {
      return object;
    }

    final headers = HeadersImpl.from(object);
    if (headers is RequestHeadersImpl) {
      return headers;
    }

    return RequestHeadersImpl(headers.values);
  }
}
