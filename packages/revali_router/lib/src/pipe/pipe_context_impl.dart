import 'package:revali_router_core/revali_router_core.dart';

class PipeContextImpl<T> implements PipeContext<T> {
  const PipeContextImpl({
    required this.annotationArgument,
    required this.nameOfParameter,
    required this.data,
    required this.meta,
    required this.type,
  });

  PipeContextImpl.from(
    EndpointContext context, {
    required this.annotationArgument,
    required this.nameOfParameter,
    required this.type,
  })  : data = context.data,
        meta = context.meta;

  @override
  final ReadOnlyDataHandler data;

  @override
  final ReadOnlyMeta meta;

  @override
  final AnnotationType type;

  @override
  final T annotationArgument;

  @override
  final String nameOfParameter;
}
