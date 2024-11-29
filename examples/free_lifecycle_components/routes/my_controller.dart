import 'package:revali_router/revali_router.dart';

import 'auth_lifecycle_components.dart';

@Controller('my')
class MyController {
  const MyController();

  @LifecycleComponents([Auth])
  // @Auth()
  @Get()
  Future<void> get() async {}
}
