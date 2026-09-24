import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://docs.revali.dev/constructs/revali_server/core/controllers/
@Controller('head')
class HeadController {
  const HeadController();

  // GET is declared before HEAD on purpose: an explicit @Head must still win
  // HEAD requests regardless of declaration order.
  @Get()
  @SetHeader('x-handler', 'get')
  String get() {
    return 'Hello world!';
  }

  @Head()
  @SetHeader('x-handler', 'head')
  void head() {}

  @Get('both')
  @SetHeader('x-handler', 'get')
  String getBoth() {
    return 'Hello world!';
  }

  @Head('both')
  @SetHeader('x-handler', 'head')
  void headBoth() {}

  @Get('get-only')
  @SetHeader('x-handler', 'get')
  String getOnly() {
    return 'Hello world!';
  }
}
