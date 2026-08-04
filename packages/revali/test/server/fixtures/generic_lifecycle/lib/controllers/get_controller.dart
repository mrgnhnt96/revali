import 'package:generic_lifecycle_fixture/components/rate_limit.dart';
import 'package:generic_lifecycle_fixture/models/get_body.dart';
import 'package:revali_router/revali_router.dart';

@Controller('api')
class GetController {
  const GetController();

  @RateLimit<GetBody>(maxRequests: 100)
  @Get('')
  Future<Map<String, Object?>> get(@Body() GetBody body) async {
    return const {};
  }
}

@Controller('api/lifecycle-components')
class LifecycleComponentsGetController {
  const LifecycleComponentsGetController();

  @LifecycleComponents([RateLimit<GetBody>])
  @RateLimit<GetBody>(maxRequests: 100)
  @Get('')
  Future<Map<String, Object?>> get(@Body() GetBody body) async {
    return const {};
  }
}
