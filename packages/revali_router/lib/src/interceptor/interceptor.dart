import 'package:revali_router/src/interceptor/interceptor_action.dart';
import 'package:revali_router/src/interceptor/interceptor_context.dart';
import 'package:revali_router/src/interceptor/interceptor_meta.dart';

abstract class Interceptor {
  const Interceptor();

  void pre(
    InterceptorContext context,
    InterceptorAction action,
  );

  void post(
    InterceptorContext context,
    InterceptorMeta meta,
  );
}
