import 'package:revali_router_core/context/context.dart';
import 'package:revali_router_core/results/middleware_result.dart';

abstract interface class Middleware {
  const Middleware();

  Future<MiddlewareResult> use(covariant Context context);
}
