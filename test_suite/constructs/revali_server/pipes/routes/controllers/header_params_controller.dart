import 'package:revali_router/revali_router.dart';
import 'package:revali_server_pipes_test/components/pipes/bool_pipe.dart';
import 'package:revali_server_pipes_test/components/pipes/optional_bool_pipe.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('header')
class HeaderParamsController {
  const HeaderParamsController();

  @Get('bool')
  bool boolean({
    @Header.pipe(BoolPipe) required bool data,
  }) {
    return data;
  }

  @Get('list-bool')
  List<bool> listBoolean({
    @Header.allPipe(BoolPipe) required List<bool> data,
  }) {
    return data;
  }

  @Get('optional-bool')
  bool? optionalBool({
    @Header.pipe(OptionalBoolPipe) required bool? data,
  }) {
    return data;
  }

  @Get('default-bool')
  bool? defaultBool({
    @Header.pipe(OptionalBoolPipe) bool data = true,
  }) {
    return data;
  }

  @Get('default-optional-bool')
  bool? defaultOptionalBool({
    @Header.pipe(OptionalBoolPipe) bool? data = true,
  }) {
    return data;
  }
}
