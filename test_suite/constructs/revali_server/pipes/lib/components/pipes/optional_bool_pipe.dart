import 'dart:async';

import 'package:revali_router/revali_router.dart';

// Learn more about Pipes at https://www.revali.dev/constructs/revali_server/core/pipes
class OptionalBoolPipe implements Pipe<String?, bool> {
  const OptionalBoolPipe();

  @override
  Future<bool> transform(String? value, PipeContext context) async {
    if (value == null) {
      return true;
    }

    return value == 'true';
  }
}
