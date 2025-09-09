import 'package:revali_router_core/context/context.dart';
import 'package:revali_router_core/results/interceptor_post_result.dart';
import 'package:revali_router_core/results/interceptor_pre_result.dart';

abstract interface class Interceptor {
  const Interceptor();

  InterceptorPreResult pre(covariant Context context);

  InterceptorPostResult post(covariant Context context);
}
