import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_shelf/converters/shelf_parent_route.dart';
import 'package:revali_shelf/converters/shelf_route.dart';

PartFile routeFileMaker(
  ShelfParentRoute route,
  String Function(Spec) format,
) {
  final closure = Method(
    (p) => p
      ..name = route.handlerName
      ..returns = refer('Route')
      ..requiredParameters.add(
        Parameter(
          (b) => b
            ..name = route.className.toCamelCase()
            ..type = refer(route.className),
        ),
      )
      ..body = Block.of([
        refer('Route')
            .newInstance([
              literalString(route.routePath)
            ], {
              'catchers': literalConstList([]),
              'data': literalConstList([]),
              'guards': literalConstList([]),
              'handler': literalNull,
              'interceptors': literalConstList([]),
              'meta': Method((p) => p
                ..requiredParameters.add(Parameter((b) => b..name = 'm'))
                ..body = Block.of([])).closure,
              'method': literalNull,
              'middlewares': literalConstList([]),
              'redirect': literalNull,
              if (route.routes.isNotEmpty)
                'routes': literalList([
                  for (final child in route.routes) createRoute(child, route)
                ])
            })
            .returned
            .statement,
      ]),
  );

  return PartFile(
    path: ['routes', '__${route.fileName}.dart'],
    content: format(closure),
  );
}

Spec createRoute(ShelfRoute route, ShelfParentRoute parent) {
  var handler = refer(parent.classVarName).property(route.handlerName).call([
    // TODO: Add parameters
  ]);

  if (route.returnType.isFuture) {
    handler = handler.awaited;
  }

  if (!route.returnType.isVoid) {
    handler = declareFinal('result').assign(handler);
  }

  return refer('Route').newInstance([
    literalString(route.path)
  ], {
    'catchers': literalConstList([]),
    'data': literalConstList([]),
    'guards': literalConstList([]),
    'interceptors': literalConstList([]),
    'meta': Method((p) => p
      ..requiredParameters.add(Parameter((b) => b..name = 'm'))
      ..body = Block.of([])).closure,
    'method': literalString(route.method),
    'middlewares': literalConstList([]),
    'redirect': literalNull,
    'handler': Method(
      (p) => p
        ..requiredParameters.add(Parameter((b) => b..name = 'context'))
        ..modifier = MethodModifier.async
        ..body = Block.of([
          handler.statement,
        ]),
    ).closure,
  });
}
