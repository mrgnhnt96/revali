import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('auth')
class AuthController {
  const AuthController();

  @Post()
  void login({
    @Body(['data', 'email']) required String email,
    @Body(['data', 'password']) required String password,
    required SetCookies cookies,
  }) {
    cookies['auth'] = '123';
  }
}
