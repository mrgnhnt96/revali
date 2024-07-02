part of '../../server.dart';

Handler user() {
  final controller = DI.instance.get<ThisController>();
  return Router()
    ..add(
      'GET',
      '/',
      (context) => _user(controller)(context),
    )
    ..add(
      'GET',
      '/<id>',
      (context) => _userId(controller)(context),
    )
    ..add(
      'POST',
      '/create',
      (context) => _userCreate(controller)(context),
    );
}


Handler _user(ThisController controller) {
  return Pipeline().addHandler((context) {
    controller.listPeople();
    return Response.ok('listPeople');
  });
}


Handler _userId(ThisController controller) {
  return Pipeline().addHandler((context) {
    final name = context.url.queryParameters['name'];
    final id = StringToIntPipe(DI.instance.get()).transform(
      (context.params['id']! as String),
      ArgumentMetadata(
        ParamType.param,
        'id',
      ),
    );
    if (name == null) {
      return Response.badRequest(body: {'error': 'name is required in query'});
    }
    final result = controller
        .getNewPerson(
          name: name,
          id: id,
        )
        .toJson();
    return Response.ok(jsonEncode({'data': result}));
  });
}


Handler _userCreate(ThisController controller) {
  return Pipeline().addHandler((context) {
    final name = context.url.queryParameters['name'];
    if (name == null) {
      return Response.badRequest(body: {'error': 'name is required in query'});
    }
    controller.create(name);
    return Response.ok('create');
  });
}
