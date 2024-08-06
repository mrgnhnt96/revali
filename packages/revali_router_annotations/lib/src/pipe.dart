import 'dart:async';

import 'package:revali_router_core/revali_router_core.dart';

abstract class Pipe<T, R> {
  const Pipe();

  FutureOr<R> transform(T value, PipeContext<dynamic> context);
}
