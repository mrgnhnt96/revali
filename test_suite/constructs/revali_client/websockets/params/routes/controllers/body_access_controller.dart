import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('body')
class BodyParamsController {
  const BodyParamsController();

  @WebSocket('root')
  String root(@Body() String data) {
    return data;
  }

  @WebSocket('nested')
  String nested(@Body(['data']) String? data) {
    return data ?? 'no data';
  }

  @WebSocket('multiple')
  String multiple(@Body(['name']) String name, @Body(['age']) int age) {
    return '$name $age';
  }
}
