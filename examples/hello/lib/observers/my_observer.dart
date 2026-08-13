import 'package:revali_router/revali_router.dart';

class MyObserver implements Observer {
  const MyObserver();

  @override
  Future<void> see(ObservedRequest observed) async {
    final response = observed.response;

    print('before');

    await response;

    print('after');
  }
}
