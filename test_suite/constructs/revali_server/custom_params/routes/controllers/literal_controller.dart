import 'package:revali_router/revali_router.dart';
import 'package:revali_server_custom_params_test/models/user.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('literal')
class LiteralController {
  const LiteralController();

  @Get('root')
  User root(@Body() User data) {
    return data;
  }

  @Get('nested')
  User nested(@Body(['data']) User data) {
    return data;
  }

  @Get('multiple')
  List<User> multiple(@Body(['one']) User one, @Body(['two']) User two) {
    return [one, two];
  }
}
