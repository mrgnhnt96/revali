import 'package:revali_router/revali_router.dart';

/// Carries both sequential lifecycle roles so the guard and middleware
/// content makers can be exercised from a single component.
final class SequentialComponent implements LifecycleComponent {
  const SequentialComponent();

  GuardResult protect(Context context) => const GuardResult.pass();

  MiddlewareResult handle(Context context) => const MiddlewareResult.next();
}
