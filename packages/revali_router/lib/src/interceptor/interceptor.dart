import 'package:revali_router/src/interceptor/interceptor_action.dart';
import 'package:revali_router/src/interceptor/interceptor_context.dart';
import 'package:revali_router/src/interceptor/interceptor_meta.dart';

abstract class Interceptor {
  const Interceptor();

  Future<void> pre(
    InterceptorContext context,
    InterceptorAction action,
  );

  Future<void> post(
    InterceptorContext context,
    InterceptorMeta meta,
  );
}
