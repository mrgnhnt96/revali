import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_parent_route.dart';
import 'package:revali_server/converters/server_route_annotations.dart';
import 'package:test/test.dart';

void main() {
  group(ServerParentRoute, () {
    group('#handlerName', () {
      test(
        'should pre-pend name with r index when controller path is empty',
        () {
          final route = ServerParentRoute(
            className: 'TestController',
            importPath: ServerImports([]),
            routePath: '',
            routes: [],
            params: [],
            annotations: ServerRouteAnnotations.none(),
            index: 0,
            type: InstanceType.singleton,
          );

          expect(route.handlerName, 'r0Route');
        },
      );
    });

    group('#fileName', () {
      test(
        'should pre-pend name with r index when controller path is empty',
        () {
          final route = ServerParentRoute(
            className: 'TestController',
            importPath: ServerImports([]),
            routePath: '',
            routes: [],
            params: [],
            annotations: ServerRouteAnnotations.none(),
            index: 0,
            type: InstanceType.singleton,
          );

          expect(route.fileName, 'r0_route');
        },
      );
    });
  });
}
