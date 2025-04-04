// ignore_for_file: avoid_positional_boolean_parameters

import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('body')
class BodyParamsController {
  const BodyParamsController();

  @Get('non-null')
  String nonNull([@Body() String data = '123']) {
    return data;
  }

  @Get('nullable')
  String nullable([@Body() String? data = '123']) {
    return data ?? 'no data';
  }

  @Get('multiple-non-null')
  String multipleNonNull([
    @Body(['name']) String name = 'John',
    @Body(['age']) int age = 30,
  ]) {
    return '$name $age';
  }

  @Get('multiple-nullable')
  String multipleNullable([
    @Body(['name']) String name = 'John',
    @Body(['age']) int? age = 30,
  ]) {
    return '$name $age';
  }
}
