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

@Controller('api/quote')
class QuoteController {
  const QuoteController();

  /// Mirrors a route that lost three `@Query()` params to type-collapse:
  /// two `double`s and three `int?`s, all of which must survive to the client.
  @Get(':placeId')
  Future<Map<String, Object?>> quote({
    @Param() required String placeId,
    @Query() required double latitude,
    @Query() required double longitude,
    @Query() int? downPaymentCents,
    @Query() int? termPeriods,
    @Query() int? unitIndex,
  }) async {
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
