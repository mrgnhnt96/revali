import 'package:revali_router_core/revali_router_core.dart';

class InterceptorContextImpl implements InterceptorContext {
  const InterceptorContextImpl({
    required this.meta,
    required this.data,
    required this.request,
    required this.response,
    required this.reflect,
  });

  @override
  final InterceptorMeta meta;

  @override
  final DataHandler data;

  @override
  final MutableRequestContext request;

  @override
  final MutableResponseContext response;

  @override
  final ReflectHandler reflect;
}
