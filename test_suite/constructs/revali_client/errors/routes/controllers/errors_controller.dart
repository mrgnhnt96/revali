import 'package:revali_router/revali_router.dart';

@Controller('errors')
class ErrorsController {
  const ErrorsController();

  @Get('structured')
  String structured() {
    throw const HttpError.notFound(
      code: 'user_not_found',
      message: 'No user with that id',
      details: {'id': 7},
    );
  }

  @Get('bare')
  String bare() {
    throw const HttpError.conflict(code: 'already_exists', message: 'Taken');
  }

  @Get('unstructured')
  String unstructured() {
    throw StateError('something went wrong');
  }
}
