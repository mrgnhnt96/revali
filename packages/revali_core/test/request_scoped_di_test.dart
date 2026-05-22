import 'dart:async';

import 'package:revali_core/revali_core.dart';
import 'package:test/test.dart';

void main() {
  group(RequestScopedDI, () {
    test('getFrom resolves from request scope when zone is active', () {
      final appDi = DIImpl()..registerSingleton<String>('app');

      final scoped = RequestScopedDI(parent: appDi)
        ..registerSingleton<String>('request');

      String? resolved;
      runZoned(
        () {
          resolved = RequestScopedDI.getFrom<String>(appDi);
        },
        zoneValues: {RequestScopedDI.zoneKey: scoped},
      );

      expect(resolved, 'request');
    });

    test('getFrom falls back to app DI when zone is inactive', () {
      final appDi = DIImpl()..registerSingleton<String>('app');

      expect(RequestScopedDI.getFrom<String>(appDi), 'app');
    });
  });
}
