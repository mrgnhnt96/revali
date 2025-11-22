import 'package:revali_router/revali_router.dart';
import 'package:revali_server_pipes_test/components/pipes/optional_user_pipe.dart';
import 'package:revali_server_pipes_test/components/pipes/user_pipe.dart';
import 'package:revali_server_pipes_test/domain/user.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('header')
class HeaderParamsController {
  const HeaderParamsController();

  @Get('user')
  String user({@Header.pipe(UserPipe) required User data}) {
    return data.name;
  }

  @Get('list-user')
  List<String> listUser({@Header.allPipe(UserPipe) required List<User> data}) {
    return data.map((user) => user.name).toList();
  }

  @Get('optional-user')
  String? optionalUser({@Header.pipe(OptionalUserPipe) required User? data}) {
    return data?.name;
  }

  @Get('default-user')
  String? defaultUser({
    @Header.pipe(OptionalUserPipe) User data = const User('default'),
  }) {
    return data.name;
  }

  @Get('default-optional-user')
  String? defaultOptionalUser({
    @Header.pipe(OptionalUserPipe) User? data = const User('default'),
  }) {
    return data?.name;
  }
}
