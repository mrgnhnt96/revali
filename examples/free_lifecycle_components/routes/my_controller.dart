import 'package:revali_router/revali_router.dart';

import 'auth_lifecycle_components.dart';

@Controller('my')
class MyController {
  const MyController();

  @AuthLifecycleComponent()
  @Get()
  Future<void> get() async {}
}
