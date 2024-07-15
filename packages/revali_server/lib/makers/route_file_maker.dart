import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:revali_annotations/revali_annotations.dart' show DI;
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_server/makers/parts/create_child_route.dart';
import 'package:revali_server/makers/parts/create_route_args.dart';
import 'package:revali_server/revali_server.dart';

PartFile routeFileMaker(
  ServerParentRoute route,
  String Function(Spec) format,
) {
  final closure = Method(
    (p) => p
      ..name = route.handlerName
      ..returns = refer('Route')
      ..requiredParameters.addAll([
        Parameter(
          (b) => b
            ..name = route.className.toCamelCase()
            ..type = refer(route.className),
        ),
        Parameter(
          (b) => b
            ..name = 'di'
            ..type = refer('$DI'),
        ),
      ])
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
