import 'package:revali_router/src/response/override_error_response.dart';

import 'pipe_context.dart';

abstract class Pipe<T, R> extends OverrideErrorResponse
    with OverrideErrorResponseMixin {
  const Pipe();

  R transform(T value, PipeContext context);

  @override
  Object? get body => null;

  @override
  Map<String, String>? get headers => null;

  @override
  int? get statusCode => null;
}
