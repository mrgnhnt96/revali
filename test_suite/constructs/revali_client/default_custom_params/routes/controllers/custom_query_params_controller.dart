import 'package:revali_client_default_custom_params_test/models/user.dart';
import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('custom/query')
class CustomQueryParamsController {
  const CustomQueryParamsController();

  @Get('required')
  User required({@Query() required User user}) {
    return user;
  }

  @Get('optional')
  User? optional({@Query() required User? user}) {
    return user;
  }

  @Get('all')
  List<User> all({@Query.all('user') required List<User> users}) {
    return users;
  }

  @Get('all-optional')
  List<User>? allOptional({@Query.all('user') required List<User>? users}) {
    return users;
  }
}
