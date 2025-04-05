import 'package:revali_router/revali_router.dart';
import 'package:revali_server_pipes_test/components/pipes/bool_pipe.dart';
import 'package:revali_server_pipes_test/components/pipes/optional_bool_pipe.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('query')
class QueryParamsController {
  const QueryParamsController();

  @Get('bool')
  bool boolean({
    @Query.pipe(BoolPipe) required bool data,
  }) {
    return data;
  }

  @Get('list-bool')
  List<bool> listBoolean({
    @Query.allPipe(BoolPipe) required List<bool> data,
  }) {
    return data;
  }

  @Get('optional-bool')
  bool? optionalBool({
    @Query.pipe(OptionalBoolPipe) required bool? data,
  }) {
    return data;
  }

  @Get('default-bool')
  bool? defaultBool({
    @Query.pipe(OptionalBoolPipe) bool data = true,
  }) {
    return data;
  }

  @Get('default-optional-bool')
  bool? defaultOptionalBool({
    @Query.pipe(OptionalBoolPipe) bool? data = true,
  }) {
    return data;
  }
}
