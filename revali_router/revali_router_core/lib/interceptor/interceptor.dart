import 'package:revali_router_core/interceptor/interceptor_context.dart';

abstract interface class Interceptor {
  const Interceptor();

  Future<void> pre(RestrictedInterceptorContext context);

  Future<void> post(FullInterceptorContext context);
}
