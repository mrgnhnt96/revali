import 'package:revali_router/revali_router.dart';
import 'package:revali_server_pipes_test/components/pipes/optional_user_pipe.dart';
import 'package:revali_server_pipes_test/components/pipes/user_pipe.dart';
import 'package:revali_server_pipes_test/domain/user.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('body')
class BodyParamsController {
  const BodyParamsController();

  @Get('user')
  String user({
    @Body.pipe(UserPipe) required User data,
  }) {
    return data.name;
  }

  @Get('list-user')
  List<String> listUser({
    @Body.pipe(UserPipe) required List<User> data,
  }) {
    return data.map((user) => user.name).toList();
  }

  @Get('optional-user')
  String? optionalUser({
    @Body.pipe(OptionalUserPipe) required User? data,
  }) {
    return data?.name;
  }

  @Get('default-user')
  String? defaultUser({
    @Body.pipe(OptionalUserPipe) User data = const User('default'),
  }) {
    return data.name;
  }

  @Get('default-optional-user')
  String? defaultOptionalUser({
    @Body.pipe(OptionalUserPipe) User? data = const User('default'),
  }) {
    return data?.name;
  }
}
