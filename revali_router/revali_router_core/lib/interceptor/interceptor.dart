import 'package:revali_router_core/interceptor/interceptor_context.dart';
import 'package:revali_router_core/interceptor/interceptor_post_result.dart';
import 'package:revali_router_core/interceptor/interceptor_pre_result.dart';

abstract interface class Interceptor {
  const Interceptor();

  InterceptorPreResult pre(RestrictedInterceptorContext context);

  InterceptorPostResult post(FullInterceptorContext context);
}
