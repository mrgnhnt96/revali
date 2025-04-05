import 'dart:async';

import 'package:revali_router_core/revali_router_core.dart';

abstract interface class Pipe<T, R> {
  const Pipe();

  Future<R> transform(T value, PipeContext context);
}
