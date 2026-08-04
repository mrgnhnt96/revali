import 'package:revali_core/context/context.dart';
import 'package:revali_core/results/guard_result.dart';

abstract interface class Guard {
  const Guard();

  Future<GuardResult> protect(covariant Context context);
}
