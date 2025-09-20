import 'package:revali_client_default_custom_params_test/enums/serialized_user_type.dart';
import 'package:revali_client_default_custom_params_test/enums/user_type.dart';
import 'package:revali_client_default_custom_params_test/models/string_user.dart';
import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('header')
class HeaderParamsController {
  const HeaderParamsController();

  @Get('required')
  StringUser required([
    @Header('X-User') StringUser user = const StringUser(name: 'John'),
  ]) {
    return user;
  }

  @Get('optional')
  StringUser? optional([
    @Header('X-User') StringUser? user = const StringUser(name: 'John'),
  ]) {
    return user;
  }

  @Get('all')
  List<StringUser> all([
    @Header.all('X-User')
    List<StringUser> users = const [
      StringUser(name: 'John'),
      StringUser(name: 'Jane'),
    ],
  ]) {
    return users;
  }

  @Get('all-optional')
  List<StringUser>? allOptional([
    @Header.all('X-User')
    List<StringUser>? users = const [
      StringUser(name: 'John'),
      StringUser(name: 'Jane'),
    ],
  ]) {
    return users;
  }

  @Get('user-type')
  UserType userType([@Header('X-User') UserType user = UserType.admin]) {
    return user;
  }

  @Get('serialized-user-type')
  SerializedUserType serializedUserType([
    @Header('X-User') SerializedUserType user = SerializedUserType.admin,
  ]) {
    return user;
  }
}
