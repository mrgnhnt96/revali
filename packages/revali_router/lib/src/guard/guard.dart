import 'package:revali_router/src/guard/guard_action.dart';
import 'package:revali_router/src/guard/guard_context.dart';

abstract class Guard {
  const Guard();

  Future<GuardResult> canNavigate(GuardContext context, GuardAction action);
}
