import 'package:hello/auth_lifecycle_components.dart';
import 'package:revali_router/revali_router.dart';

@Controller('my')
class MyController {
  const MyController();

  @AuthLifecycleComponent()
  @Get()
  Future<void> get() async {}
}
