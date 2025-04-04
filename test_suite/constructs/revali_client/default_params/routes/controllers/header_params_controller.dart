import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('header')
class HeaderParamsController {
  const HeaderParamsController();

  @Get('required')
  String required([
    @Header('X-Data') String data = 'Hello world',
  ]) {
    return data;
  }

  @Get('optional')
  String? optional([
    @Header('X-Data') String? data = 'Hello world',
  ]) {
    return data;
  }

  @Get('all')
  List<String> all([
    @Header.all('X-Data') List<String> data = const [
      'Hello',
      'world',
    ],
  ]) {
    return data;
  }

  @Get('all-optional')
  List<String>? allOptional([
    @Header.all('X-Data') List<String>? data = const [
      'Hello',
      'world',
    ],
  ]) {
    return data;
  }
}
