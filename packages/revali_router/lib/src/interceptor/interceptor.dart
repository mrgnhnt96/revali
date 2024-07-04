import 'package:revali_router/src/interceptor/interceptor_context.dart';

abstract class Interceptor {
  const Interceptor();

  Future<void> pre(InterceptorContext context);

  Future<void> post(InterceptorContext context);
}
