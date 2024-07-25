import 'dart:convert';

import 'package:revali_router_core/body/read_only_body.dart';
import 'package:revali_router_core/headers/read_only_headers.dart';

abstract class BodyData extends ReadOnlyBody {
  BodyData();

  String? get mimeType => null;
  int? get contentLength => null;

  Encoding encoding = utf8;

  @override
  Stream<List<int>>? read();

  ReadOnlyHeaders headers(ReadOnlyHeaders? requestHeaders);
}
