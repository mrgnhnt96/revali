import 'package:revali_router_core/guard/guard_action.dart';
import 'package:revali_router_core/guard/guard_context.dart';
import 'package:revali_router_core/guard/guard_result.dart';

abstract interface class Guard {
  const Guard();

  Future<GuardResult> canActivate(GuardContext context, GuardAction action);
}
