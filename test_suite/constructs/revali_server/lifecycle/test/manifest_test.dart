import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('generated routes manifest', () {
    late Map<String, dynamic> manifest;

    setUpAll(() {
      final file = File('.revali/server/routes.json');

      expect(
        file.existsSync(),
        isTrue,
        reason: 'run `revali dev --generate-only` first',
      );

      manifest = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    });

    Map<String, dynamic> routeFor(String path) {
      final routes = (manifest['routes'] as List).cast<Map<String, dynamic>>();

      return routes.firstWhere((r) => r['path'] == path);
    }

    test('declares the version the contract check expects', () {
      // `checkContract` skips return-type comparison below version 2 and says
      // so. If the generator ever stops emitting 2, every check silently
      // narrows instead of failing.
      expect(manifest['version'], 2);
    });

    test('carries a return type for every route', () {
      final routes = (manifest['routes'] as List).cast<Map<String, dynamic>>();

      expect(routes, isNotEmpty);
      for (final route in routes) {
        expect(
          route.containsKey('returns'),
          isTrue,
          reason: '${route['path']} has no return type',
        );
        expect(route.containsKey('returnsNullable'), isTrue);
      }
    });

    test('reports the actual return type, not a placeholder', () {
      // The contract check compares these by name; a constant would make
      // every comparison pass.
      expect(
        routeFor('/api/lifecycle/trace')['returns'],
        'Map<String, Object?>',
      );
      expect(routeFor('/api/lifecycle/boom')['returns'], 'String');
    });

    test('unwraps a Future return type', () {
      // What a caller receives is the awaited value, so a manifest that said
      // `Future<String>` would flag a false break the moment anyone compared
      // it against a synchronous handler returning the same thing.
      expect(routeFor('/api/lifecycle/trace-async')['returns'], 'String');
      expect(routeFor('/api/lifecycle/trace-async')['returnsNullable'], isTrue);
    });
  });
}
