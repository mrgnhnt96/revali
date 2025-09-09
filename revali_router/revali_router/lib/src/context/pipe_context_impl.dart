import 'package:revali_router_core/revali_router_core.dart';

class PipeContextImpl implements PipeContext {
  const PipeContextImpl({
    required this.annotationArgument,
    required this.nameOfParameter,
    required this.data,
    required this.meta,
    required this.type,
    required this.reflect,
    required this.request,
    required this.response,
    required this.route,
  });

  @override
  final AnnotationType type;

  @override
  final dynamic annotationArgument;

  @override
  final String nameOfParameter;

  @override
  final DataHandler data;

  @override
  final Meta meta;

  @override
  final ReflectHandler reflect;

  @override
  final MutableRequest request;

  @override
  final MutableResponse response;

  @override
  final RouteEntry route;
}
