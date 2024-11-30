import 'package:revali_router/revali_router.dart';

import 'auth_lifecycle_components.dart';

@Controller('my')
class MyController {
  const MyController();

  @LifecycleComponents([AuthLifecycleComponent])
  @Get()
  Future<void> get() async {}

  @LifecycleComponents([AuthLifecycleComponent])
  @Put()
  Future<void> put() async {}
}
