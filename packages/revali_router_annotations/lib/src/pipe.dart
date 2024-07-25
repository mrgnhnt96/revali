import 'dart:async';

import 'package:revali_router_core/revali_router_core.dart';

abstract class Pipe<T, R> extends OverrideErrorResponse
    with OverrideErrorResponseMixin {
  const Pipe();

  FutureOr<R> transform(T value, PipeContext<dynamic> context);

  @override
  Object? get body => null;

  @override
  Map<String, String>? get headers => null;

  @override
  int? get statusCode => null;
}
