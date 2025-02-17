import 'package:client_gen_models/client_gen_models.dart';
import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('game')
class GameController {
  const GameController();

  @WebSocket('')
  Stream<String> handle(
    @Body() User user,
  ) async* {
    yield 'Hello world!';
  }
}
