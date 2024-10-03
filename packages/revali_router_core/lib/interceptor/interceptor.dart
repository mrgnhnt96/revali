import 'package:revali_router_core/interceptor/interceptor_context.dart';

abstract interface class Interceptor {
  const Interceptor();

  Future<void> pre(InterceptorContext context);

  Future<void> post(InterceptorContext context);
}
