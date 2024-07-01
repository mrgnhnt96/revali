import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_shelf/makers/method_handler.dart';
import 'package:revali_shelf/makers/utils/meta_method_extensions.dart';
import 'package:revali_shelf/makers/utils/meta_route_extensions.dart';

List<PartFile> routeHandlers(
  List<MetaRoute> routes,
  String Function(Spec) formatter,
) {
  return [
    for (var route in routes) _routeHandler(route, formatter),
  ];
}

PartFile _routeHandler(MetaRoute route, String Function(Spec) formatter) {
  final controller = declareFinal('controller')
      .assign(
        refer('DI').property('instance').property('get').call(
          [],
          {},
          [
            refer(route.className),
          ],
        ),
      )
      .statement;

  var router = refer('Router').newInstance([]);

  for (var method in route.methods) {
    router = router.cascade('add').call(
      [
        literalString(method.method),
        literalString(method.cleanPath),
        Method(
          (b) => b
            ..lambda = true
            ..requiredParameters.add(Parameter((b) => b..name = 'context'))
            ..body = Block.of(
              [
                refer(
                  method.handlerName(route),
                ).call([refer('controller')]).call([
                  refer('context'),
                ]).code,
              ],
            ),
        ).closure,
      ],
    );
  }

  final routerMethod = Method(
    (b) => b
      ..name = route.handlerName
      ..returns = refer('Handler')
      ..body = Block.of([controller, router.returned.statement]),
  );

  final specs = <Spec>[
    routerMethod,
    for (final method in route.methods) methodHandler(method, route),
  ];

  final content = specs.map(formatter).join('\n\n');

  return PartFile(
    path: ['server', 'handlers', '__${route.handlerName}.dart'],
    content: content,
  );
}
