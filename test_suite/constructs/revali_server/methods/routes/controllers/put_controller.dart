import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://docs.revali.dev/constructs/revali_server/core/controllers/
@Controller('put')
class PutController {
  const PutController();

  @Put()
  String handle() {
    return 'Hello world!';
  }
}
