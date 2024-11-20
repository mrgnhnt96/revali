import 'dart:io';

import 'package:revali_router_core/revali_router_core.dart';

mixin RemoveHeadersMixin {
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
}
