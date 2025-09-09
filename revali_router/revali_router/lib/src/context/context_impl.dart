import 'package:revali_router_core/revali_router_core.dart';

class ContextImpl implements Context {
  const ContextImpl({
    required this.data,
    required this.meta,
    required this.request,
    required this.response,
    required this.reflect,
    required this.route,
  });

  @override
  final DataHandler data;

  @override
  final Meta meta;

  @override
  final RouteEntry route;

  @override
  final MutableRequest request;

  @override
  final MutableResponse response;

  @override
  final ReflectHandler reflect;
}
