import 'package:revali_router/revali_router.dart';
import 'package:revali_server_pipes_test/components/pipes/bool_pipe.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('path')
class PathParamsController {
  const PathParamsController();

  @Get('bool/:first')
  bool boolean({
    @Param.pipe(BoolPipe) required bool first,
  }) {
    return first;
  }
}
