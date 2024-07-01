part of '../../server.dart';

Handler some() {
  final controller = DI.instance.get<Some>();
  return Router()
    ..add(
      'GET',
      '/',
      (context) => _some(controller)(context),
    );
}


Handler _some(Some controller) {
  return Pipeline().addHandler((context) {
    controller.get();
    return Response.ok('get');
  });
}
