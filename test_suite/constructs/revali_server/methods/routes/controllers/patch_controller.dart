import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('patch')
class PatchController {
  const PatchController();

  @Patch()
  String handle() {
    return 'Hello world!';
  }
}
