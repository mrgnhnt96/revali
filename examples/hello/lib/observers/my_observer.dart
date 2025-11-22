import 'package:revali_router/revali_router.dart';

class MyObserver implements Observer {
  const MyObserver();

  @override
  Future<void> see(
    Request request,
    Future<Response> response,
  ) async {
    print('before');

    await response;

    print('after');
  }
}
