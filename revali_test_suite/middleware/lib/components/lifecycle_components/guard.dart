import 'package:revali_router/revali_router.dart';

// Learn more about Lifecycle Components at https://www.revali.dev/constructs/revali_server/lifecycle-components/components
class Allow implements LifecycleComponent {
  const Allow();

  GuardResult guard() {
    return const GuardResult.pass();
  }
}

class Reject implements LifecycleComponent {
  const Reject();

  GuardResult guard() {
    return const GuardResult.block(
      statusCode: 403,
      body: 'I am a custom rejection message',
    );
  }
}
