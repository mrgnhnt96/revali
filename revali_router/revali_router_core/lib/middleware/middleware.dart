import 'package:revali_router_core/middleware/middleware_action.dart';
import 'package:revali_router_core/middleware/middleware_context.dart';
import 'package:revali_router_core/middleware/middleware_result.dart';

abstract interface class Middleware {
  const Middleware();

  Future<MiddlewareResult> use(
    MiddlewareContext context,
    MiddlewareAction action,
  );
}
