import 'package:revali_router/revali_router.dart';

@ExpectHeaders({'X-Some-Header'})
@AllowHeaders.simple()
@AllowHeaders({'X-Different-Header'})
@Controller('cors')
class CorsController {
  const CorsController();

  @Get()
  @AllowHeaders.noInherit({'X-Another-Header'})
  @AllowHeaders.simple()
  @AllowHeaders.common()
  void headers() {}
}
