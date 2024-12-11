import 'package:revali_router_core/revali_router_core.dart';

class PipeContextImpl implements PipeContext {
  const PipeContextImpl({
    required this.annotationArgument,
    required this.nameOfParameter,
    required this.data,
    required this.meta,
    required this.type,
  });

  PipeContextImpl.from(
    BaseContext context, {
    required this.annotationArgument,
    required this.nameOfParameter,
    required this.type,
  })  : data = context.data,
        meta = context.meta;

  @override
  final ReadOnlyData data;

  @override
  final ReadOnlyMeta meta;

  @override
  final AnnotationType type;

  @override
  final dynamic annotationArgument;

  @override
  final String nameOfParameter;
}
