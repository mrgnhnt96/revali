import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('query')
class QueryParamsController {
  const QueryParamsController();

  @Get('required')
  String required([@Query() String data = 'Hello world']) {
    return data;
  }

  @Get('optional')
  String? optional([@Query() String? data = 'Hello world']) {
    return data;
  }

  @Get('all')
  List<String> all([
    @Query.all('data') List<String> data = const ['Hello', 'world'],
  ]) {
    return data;
  }

  @Get('all-optional')
  List<String>? allOptional([
    @Query.all('data') List<String>? data = const ['Hello', 'world'],
  ]) {
    return data;
  }
}
