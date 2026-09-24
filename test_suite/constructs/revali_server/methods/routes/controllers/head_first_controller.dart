import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://docs.revali.dev/constructs/revali_server/core/controllers/
@Controller('head-first')
class HeadFirstController {
  const HeadFirstController();

  // HEAD is declared before GET on purpose: the explicit @Head must still
  // win HEAD requests regardless of declaration order.
  @Head()
  @SetHeader('x-handler', 'head')
  void head() {}

  @Get()
  @SetHeader('x-handler', 'get')
  String get() {
    return 'Hello world!';
  }
}
