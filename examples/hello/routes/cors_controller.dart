import 'package:revali_router/revali_router.dart';

@ExpectHeaders({'X-Some-Header'})
@ExpectHeaders({'X-Different-Header'})
@Controller('cors')
class CorsController {
  const CorsController();

  @Get()
  @ExpectHeaders({'X-Another-Header'})
  void headers() {}
}
