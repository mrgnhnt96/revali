import 'package:revali_router/revali_router.dart';
import 'package:revali_router_core/revali_router_core.dart';

class InterceptorContextImpl implements InterceptorContext<MutableResponse> {
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
  final MutableRequest request;

  @override
  final MutableResponse response;

  @override
  final ReadOnlyReflectHandler reflect;
}
