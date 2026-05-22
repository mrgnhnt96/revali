import 'package:revali_router/revali_router.dart';

final class RateLimit<T> implements LifecycleComponent {
  const RateLimit({required this.maxRequests});

  final int maxRequests;

  GuardResult check(@Body() T body) {
    return const GuardResult.pass();
  }
}
