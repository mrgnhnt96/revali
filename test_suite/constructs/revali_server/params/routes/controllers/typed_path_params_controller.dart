import 'package:revali_router/revali_router.dart';

// Path parameters always arrive as `String`; non-String primitives are parsed.
@Controller('typed-path')
class TypedPathParamsController {
  const TypedPathParamsController();

  @Get('int/:id')
  int intParam(@Param() int id) {
    return id;
  }

  @Get('double/:value')
  double doubleParam(@Param() double value) {
    return value;
  }

  @Get('num/:value')
  num numParam(@Param() num value) {
    return value;
  }

  @Get('bool/:flag')
  bool boolParam(@Param() bool flag) {
    return flag;
  }
}
