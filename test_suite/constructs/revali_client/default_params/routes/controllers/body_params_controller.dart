// ignore_for_file: avoid_positional_boolean_parameters

import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('body')
class BodyParamsController {
  const BodyParamsController();

  @Get('non-null')
  String nonNull([@Body() String data = 'Hello world']) {
    return data;
  }

  @Get('nullable')
  String? nullable([@Body() String? data = 'Hello world']) {
    return data;
  }

  @Get('nested-non-null')
  String nestedNonNull([@Body(['name']) String data = 'Hello world']) {
    return data;
  }

  @Get('nested-nullable')
  String? nestedNullable([@Body(['name']) String? data = 'Hello world']) {
    return data;
  }
}
