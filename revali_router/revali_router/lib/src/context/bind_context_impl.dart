import 'package:revali_router_core/revali_router_core.dart';

class BindContextImpl implements BindContext {
  const BindContextImpl({
    required this.nameOfParameter,
    required this.parameterType,
    required this.data,
    required this.meta,
    required this.request,
    required this.response,
    required this.reflect,
    required this.route,
  });

  @override
  final String nameOfParameter;

  @override
  final Type parameterType;

  @override
  final ReflectHandler reflect;

  @override
  final RouteEntry route;

  @override
  final DataHandler data;

  @override
  final Meta meta;

  @override
  final MutableRequest request;

  @override
  final MutableResponse response;
}
