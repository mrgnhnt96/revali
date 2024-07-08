import 'package:revali_router/revali_router.dart';

import 'param_type.dart';
import 'pipe_context.dart';

class PipeContextImpl<T> implements PipeContext<T> {
  const PipeContextImpl({
    required this.arg,
    required this.paramName,
    required this.data,
    required this.meta,
    required this.type,
  });

  PipeContextImpl.from(
    EndpointContext context, {
    required this.arg,
    required this.paramName,
    required this.type,
  })  : data = context.data,
        meta = context.meta;

  @override
  final ReadOnlyDataHandler data;

  @override
  final ReadOnlyMeta meta;

  @override
  final ParamType type;

  @override
  final T arg;

  @override
  final String paramName;
}
