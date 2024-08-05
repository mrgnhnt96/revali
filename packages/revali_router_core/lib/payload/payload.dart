import 'dart:convert';

import 'package:revali_router_core/body/body_data.dart';
import 'package:revali_router_core/headers/read_only_headers.dart';

abstract class Payload {
  const Payload();

  int? get contentLength;
  Stream<List<int>> read();
  Future<BodyData> resolve(ReadOnlyHeaders headers);

  String readAsString({Encoding encoding = utf8});
}
