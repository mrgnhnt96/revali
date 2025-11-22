import 'dart:convert';

import 'package:revali_router_core/body/body.dart';
import 'package:revali_router_core/method_mutations/headers/headers.dart';

abstract class Payload {
  const Payload();

  Future<Body> resolve(Headers headers);
  Future<void> close();
  int? get contentLength;
  Stream<List<int>> read();
  String readAsString({Encoding encoding = utf8});
}
