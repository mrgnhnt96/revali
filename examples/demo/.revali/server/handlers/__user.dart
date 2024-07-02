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
    final id = context.params['id']!;
    if (name == null) {
      return Response.badRequest(
          body: jsonEncode({'error': 'name is required in query'}));
    }
    final result = controller
        .getNewPerson(
          name: NamePipe().transform(
            (name as String),
            ArgumentMetadata(
              ParamType.query,
              'name',
            ),
          ),
          id: StringToIntPipe(DI.instance.get()).transform(
            (id as String),
            ArgumentMetadata(
              ParamType.param,
              'id',
            ),
          ),
        )
        .toJson();
    return Response.ok(jsonEncode({'data': result}));
  });
}


Handler _userCreate(ThisController controller) {
  return Pipeline().addHandler((context) {
    final name = context.url.queryParameters['name'];
    if (name == null) {
      return Response.badRequest(
          body: jsonEncode({'error': 'name is required in query'}));
    }
    controller.create(name);
    return Response.ok('create');
  });
}
