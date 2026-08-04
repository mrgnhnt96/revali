import 'package:revali_router/revali_router.dart';

class RequestScope implements LifecycleComponent {
  const RequestScope();

  WrapperResult wrap(Context context, NextResponse next) {
    return next();
  }
}
