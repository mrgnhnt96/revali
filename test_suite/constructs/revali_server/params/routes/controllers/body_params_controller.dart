import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('body')
class BodyParamsController {
  const BodyParamsController();

  @Get('root')
  String required(@Body() String data) {
    return data;
  }

  @Get('nested')
  String optional(@Body(['data']) String? data) {
    return data ?? 'no data';
  }

  @Get('multiple')
  String all(@Body(['name']) String name, @Body(['age']) int age) {
    return '$name $age';
  }
}
