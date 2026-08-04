import 'dart:async';

import 'package:revali_core/revali_core.dart';

abstract interface class Pipe<T, R> {
  const Pipe();

  Future<R> transform(T value, PipeContext context);
}
