import 'package:revali_router/revali_router.dart';
import 'package:revali_server_pipes_test/components/pipes/user_pipe.dart';
import 'package:revali_server_pipes_test/domain/user.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('path')
class PathParamsController {
  const PathParamsController();

  @Get('user/:first')
  String user({
    @Param.pipe(UserPipe) required User first,
  }) {
    return first.name;
  }
}
