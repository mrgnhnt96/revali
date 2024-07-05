import 'package:revali_router/src/data/read_only_data_handler.dart';
import 'package:revali_router/src/meta/read_only_meta.dart';
import 'package:revali_router/src/pipe/param_type.dart';
import 'package:revali_router/src/pipe/pipe_context.dart';

class PipeContextImpl<T> implements PipeContext<T> {
  const PipeContextImpl({
    required this.arg,
    required this.paramName,
    required this.data,
    required this.meta,
    required this.type,
  });

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
