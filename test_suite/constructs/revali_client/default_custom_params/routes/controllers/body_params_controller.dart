// ignore_for_file: avoid_positional_boolean_parameters

import 'package:revali_client_default_custom_params_test/lib/models/user.dart';
import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('body')
class BodyParamsController {
  const BodyParamsController();

  @Get('non-null')
  User nonNull([@Body() User data = const User(name: 'John')]) {
    return data;
  }

  @Get('nullable')
  User? nullable([@Body() User? data = const User(name: 'John')]) {
    return data;
  }

  @Get('nested-non-null')
  User nestedNonNull([
    @Body(['name']) User data = const User(name: 'John'),
  ]) {
    return data;
  }

  @Get('nested-nullable')
  User? nestedNullable([
    @Body(['name']) User? data = const User(name: 'John'),
  ]) {
    return data;
  }
}
