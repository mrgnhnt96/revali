import 'package:revali_router/src/middleware/middleware_action.dart';
import 'package:revali_router/src/middleware/middleware_context.dart';

abstract class Middleware {
  const Middleware();

  Future<MiddlewareResult> use(
    MiddlewareContext context,
    MiddlewareAction action,
  );
}
