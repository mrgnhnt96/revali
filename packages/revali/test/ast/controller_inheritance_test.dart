import 'package:revali/ast/visitors/controller_visitor.dart';
import 'package:test/test.dart';

import '../server/helpers/analysis_helper.dart';

void main() {
  late AnalysisHelper helper;

  setUpAll(() async {
    helper = await AnalysisHelper.create();
  });

  /// Route paths the generator found for [className], as `METHOD path`.
  Future<Set<String>> routesOf(String className) async {
    final element = await helper.classElement(
      unitPath: 'lib/controllers/inherited_controller.dart',
      className: className,
    );

    final visitor = ControllerVisitor();
    element.accept(visitor);

    expect(visitor.hasController, isTrue, reason: '$className is a controller');

    return {
      for (final method in visitor.values.methods)
        '${method.method.toUpperCase()} ${method.path}',
    };
  }

  group('controller inheritance', () {
    test('picks up endpoints declared on a superclass', () async {
      expect(await routesOf('InheritedController'), {
        'POST ',
        'GET all',
        'DELETE purge',
        'GET health',
      });
    });

    test('picks up endpoints from a mixin', () async {
      expect(await routesOf('InheritedController'), contains('GET health'));
    });

    test('an override replaces the inherited route', () async {
      final routes = await routesOf('OverridingController');

      expect(routes, contains('GET everything'));
      expect(
        routes,
        isNot(contains('GET all')),
        reason: 'the base annotation must not register a second route',
      );
    });

    test('an unannotated override keeps the inherited route once', () async {
      final routes = await routesOf('UnannotatedOverrideController');

      expect(routes, contains('GET all'));
      expect(
        routes.where((r) => r.startsWith('GET all')),
        hasLength(1),
        reason: 'must not register twice',
      );
    });

    test('the controller own methods still win', () async {
      expect(await routesOf('InheritedController'), contains('POST '));
    });
  });
}
