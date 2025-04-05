import 'dart:async';

import 'package:revali_router/revali_router.dart';

// Learn more about Pipes at https://www.revali.dev/constructs/revali_server/core/pipes
class BoolPipe implements Pipe<String, bool> {
  const BoolPipe();

  @override
  Future<bool> transform(String value, PipeContext context) async {
    return value == 'true';
  }
}
