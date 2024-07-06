import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_shelf/converters/shelf_child_route.dart';
import 'package:revali_shelf/converters/shelf_mimic.dart';
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
      statusCode: route.httpCode?.code,
    ),
    if (route.redirect case final redirect?)
      'redirect': literal(mimic(redirect)),
  });
}

Map<String, Expression> createRouteArgs({
  required ShelfRoute route,
  ShelfReturnType? returnType,
  String? classVarName,
  String? method,
  int? statusCode,
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
      'catchers': literalConstList(
          [for (final catcher in route.annotations.catchers) mimic(catcher)]),
    if (route.annotations.data.isNotEmpty)
      'data': literalConstList(
          [for (final data in route.annotations.data) mimic(data)]),
    if (route.annotations.guards.isNotEmpty)
      'guards': literalConstList(
          [for (final guard in route.annotations.guards) mimic(guard)]),
    if (route.annotations.interceptors.isNotEmpty)
      'interceptors': literalConstList([
        for (final interceptor in route.annotations.interceptors)
          mimic(interceptor)
      ]),
    if (route.annotations.middlewares.isNotEmpty)
      'middlewares': literalConstList([
        for (final middleware in route.annotations.middlewares)
          mimic(middleware)
      ]),
    if (route.annotations.combine.isNotEmpty)
      'combine': literalConstList(
          [for (final combine in route.annotations.combine) mimic(combine)]),
    if (route.annotations.meta.isNotEmpty)
      ...() {
        final m = refer('m');

        return {
          'meta': Method((p) => p
            ..requiredParameters.add(Parameter((b) => b..name = 'm'))
            ..body = Block.of([
              for (final meta in route.annotations.meta)
                m.cascade('add').call([
                  mimic(meta),
                ]).statement,
            ])).closure
        };
      }(),
    if (method != null) 'method': literalString(method),
    if ('$handler' != '$literalNull')
      'handler': Method(
        (p) => p
          ..requiredParameters.add(Parameter((b) => b..name = 'context'))
          ..modifier = MethodModifier.async
          ..body = Block.of([
            if (statusCode != null)
              refer('context')
                  .property('response')
                  .property('statusCode')
                  .assign(
                    literalNum(statusCode),
                  )
                  .statement,
            Code('\n'),
            handler.statement,
          ]),
      ).closure,
  };
}

Expression mimic(ShelfMimic mimic) => CodeExpression(Code(mimic.instance));
