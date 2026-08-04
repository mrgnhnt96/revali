import 'dart:io';

import 'package:revali_core/revali_core.dart';

mixin RemoveHeadersMixin {
  void removeContentRelated(Headers headers) {
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
}
