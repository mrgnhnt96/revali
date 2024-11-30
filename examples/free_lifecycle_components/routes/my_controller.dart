import 'package:revali_router/revali_router.dart';

import 'auth_lifecycle_components.dart';

@Controller('my')
class MyController {
  const MyController();

  @LifecycleComponents([AuthLifecycleComponent])
  // @Auth()
  @Get()
  Future<void> get() async {}
}
