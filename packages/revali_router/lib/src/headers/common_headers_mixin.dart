import 'dart:convert';

import 'package:http_parser/http_parser.dart';
import 'package:revali_router/src/headers/read_only_headers.dart';

abstract class CommonHeadersMixin extends ReadOnlyHeaders {
  MediaType? _contentType;
  @override
  MediaType? get contentType {
    if (_contentType case final value?) {
      return value;
    }

    if (get('content-type') case final value?) {
      return _contentType = MediaType.parse(value);
    }

    return null;
  }

  Encoding? _encoding;
  @override
  Encoding get encoding {
    if (_encoding case final value?) {
      return value;
    }

    if (contentType?.parameters['charset'] case final value?) {
      return _encoding = Encoding.getByName(value) ?? utf8;
    }

    return _encoding = utf8;
  }

  DateTime? _ifModifiedSince;
  @override
  DateTime? get ifModifiedSince {
    if (_ifModifiedSince case final value?) {
      return value;
    }

    if (get('if-modified-since') case final value?) {
      return _ifModifiedSince = parseHttpDate(value);
    }

    return null;
  }

  String? _mimeType;
  @override
  String? get mimeType {
    if (_mimeType case final value?) {
      return value;
    }

    return _mimeType = contentType?.mimeType;
  }

  int? _contentLength;
  @override
  int? get contentLength {
    if (_contentLength case final value?) {
      return value;
    }

    if (get('content-length') case final value?) {
      return _contentLength = int.tryParse(value);
    }

    return null;
  }
}
