import 'dart:convert';
import 'dart:io';

import 'package:http_parser/http_parser.dart';
import 'package:revali_router_core/headers/read_only_headers.dart';

abstract class CommonHeadersMixin extends ReadOnlyHeaders {
  @override
  MediaType? get contentType {
    if (get(HttpHeaders.contentTypeHeader) case final value?) {
      return MediaType.parse(value);
    }

    return null;
  }

  @override
  Encoding get encoding {
    if (contentType?.parameters['charset'] case final value?) {
      return Encoding.getByName(value) ?? utf8;
    }

    return utf8;
  }

  @override
  DateTime? get ifModifiedSince {
    if (get(HttpHeaders.ifModifiedSinceHeader) case final value?) {
      return parseHttpDate(value);
    }

    return null;
  }

  DateTime? get lastModified {
    if (get(HttpHeaders.ifModifiedSinceHeader) case final value?) {
      return parseHttpDate(value);
    }

    return null;
  }

  @override
  String? get mimeType {
    return contentType?.mimeType;
  }

  @override
  int? get contentLength {
    if (get(HttpHeaders.contentLengthHeader) case final value?) {
      return int.tryParse(value);
    }

    return null;
  }

  @override
  (int, int)? get range {
    if (get(HttpHeaders.rangeHeader) case final value?) {
      final match = RegExp(r'bytes=(\d+)-(\d+)?').firstMatch(value);
      if (match == null) {
        return null;
      }

      final start = int.tryParse(match.group(1)!) ?? 0;
      final end = int.tryParse(match.group(2)!) ?? -1;

      return (start, end);
    }

    return null;
  }

  String? get acceptRanges {
    return get(HttpHeaders.acceptRangesHeader);
  }

  @override
  String? get origin {
    return get(HttpHeaders.accessControlAllowOriginHeader);
  }

  @override
  String? get transferEncoding {
    return get(HttpHeaders.transferEncodingHeader);
  }

  @override
  String? get filename {
    if (get(HttpHeaders.contentDisposition) case final value?) {
      if (RegExp('filename="([^"]+)"').firstMatch(value) case final match?) {
        return match.group(1);
      }
    }

    if (contentType?.parameters['filename'] case final value?) {
      return value;
    }

    return null;
  }
}
