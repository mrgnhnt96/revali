import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_shelf/converters/shelf_child_route.dart';
import 'package:revali_shelf/converters/shelf_class.dart';
import 'package:revali_shelf/converters/shelf_parent_route.dart';
import 'package:revali_shelf/converters/shelf_return_type.dart';
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
              ...createRouteArgs(
                route: route,
                returnType: null,
                classVarName: route.classVarName,
                method: null,
              ),
              if (route.routes.isNotEmpty)
                'routes': literalList([
                  for (final child in route.routes)
                    createChildRoute(child, route)
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

Spec createChildRoute(ShelfChildRoute route, ShelfParentRoute parent) {
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
    ...createRouteArgs(
      route: route,
      returnType: route.returnType,
      classVarName: parent.classVarName,
      method: route.method,
    ),
    if (route.redirect != null)
      'redirect': literal(createClass(route.redirect!)),
  });
}

Map<String, Expression> createRouteArgs({
  required ShelfRoute route,
  ShelfReturnType? returnType,
  String? classVarName,
  String? method,
}) {
  var handler = literalNull;
  if (returnType != null && classVarName != null) {
    handler = refer(classVarName).property(route.handlerName).call([
      // TODO: Add parameters
    ]);

    if (returnType.isFuture) {
      handler = handler.awaited;
    }

    if (!returnType.isVoid) {
      handler = declareFinal('result').assign(handler);
    }
  }
  return {
    if (route.annotations.catchers.isNotEmpty)
      'catchers': literalConstList([
        for (final catcher in route.annotations.catchers) createClass(catcher)
      ]),
    if (route.annotations.data.isNotEmpty)
      'data': literalConstList(
          [for (final data in route.annotations.data) createClass(data)]),
    if (route.annotations.guards.isNotEmpty)
      'guards': literalConstList(
          [for (final guard in route.annotations.guards) createClass(guard)]),
    if (route.annotations.interceptors.isNotEmpty)
      'interceptors': literalConstList([
        for (final interceptor in route.annotations.interceptors)
          createClass(interceptor)
      ]),
    if (route.annotations.middlewares.isNotEmpty)
      'middlewares': literalConstList([
        for (final middleware in route.annotations.middlewares)
          createClass(middleware)
      ]),
    if (route.annotations.combine.isNotEmpty)
      'combine': literalConstList([
        for (final combine in route.annotations.combine) createClass(combine)
      ]),
    'meta': Method((p) => p
      ..requiredParameters.add(Parameter((b) => b..name = 'm'))
      ..body = Block.of([])).closure,
    if (method != null) 'method': literalString(method),
    if ('$handler' != '$literalNull')
      'handler': Method(
        (p) => p
          ..requiredParameters.add(Parameter((b) => b..name = 'context'))
          ..modifier = MethodModifier.async
          ..body = Block.of([
            handler.statement,
          ]),
      ).closure,
  };
}

Spec createClass(ShelfClass clazz) {
  final positioned = <Expression>[];
  final named = <String, Expression>{};

  for (final paramWithValue in clazz.params) {
    final arg = CodeExpression(Code(paramWithValue.value));
    final param = paramWithValue.param;

    if (param.isNamed) {
      named[param.name] = arg;
    } else {
      positioned.add(arg);
    }
  }

  return Code(clazz.source);
}
