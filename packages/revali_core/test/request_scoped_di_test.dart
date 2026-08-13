import 'dart:async';

import 'package:revali_core/revali_core.dart';
import 'package:test/test.dart';

class Counter {
  Counter(this.id);

  final int id;
}

class Resource implements Disposable {
  Resource(this.log);

  final List<String> log;
  bool disposed = false;

  @override
  Future<void> dispose() async {
    disposed = true;
    log.add('disposed');
  }
}

class ExplodingResource implements Disposable {
  @override
  Future<void> dispose() async => throw StateError('teardown failed');
}

void main() {
  group('registerRequestScoped', () {
    late DIImpl app;
    var built = 0;

    setUp(() {
      built = 0;
      app = DIImpl()..registerRequestScoped<Counter>(() => Counter(++built));
    });

    test('builds once per request and shares within it', () async {
      final scope = RequestScopedDI(parent: app);

      await scope.run(() async {
        expect(scope.get<Counter>().id, 1);
        expect(scope.get<Counter>().id, 1, reason: 'same instance reused');
      });

      expect(built, 1);
    });

    test('builds a fresh instance for the next request', () async {
      final first = await RequestScopedDI(
        parent: app,
      ).run(() async => RequestScopedDI.current.get<Counter>().id);

      final second = await RequestScopedDI(
        parent: app,
      ).run(() async => RequestScopedDI.current.get<Counter>().id);

      expect(first, 1);
      expect(second, 2, reason: 'must not be shared between requests');
    });

    test('is not built at all when the request never asks for it', () async {
      await RequestScopedDI(parent: app).run(() async {});

      expect(built, 0, reason: 'should be lazy');
    });

    test('resolving outside a request explains itself', () {
      expect(
        () => app.get<Counter>(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('request scoped'), contains('outside a request')),
          ),
        ),
      );
    });

    test('rejects a type already registered another way', () {
      expect(
        () => app.registerSingleton<Counter>(Counter(0)),
        throwsA(isA<Exception>()),
      );
    });

    test('falls through to the app container for everything else', () async {
      app.registerSingleton<String>('shared');

      await RequestScopedDI(parent: app).run(() async {
        expect(RequestScopedDI.current.get<String>(), 'shared');
      });
    });

    test('resolves through a DIHandler wrapper', () async {
      // Production wraps the container before the router sees it, so the
      // request-scoped lookup has to work through the wrapper.
      final handler = DIHandler(app)..finishRegistration();

      await RequestScopedDI(parent: handler).run(() async {
        expect(RequestScopedDI.current.get<Counter>().id, 1);
      });
    });
  });

  group('disposal', () {
    test('disposes what the request built', () async {
      final log = <String>[];
      final app = DIImpl()
        ..registerRequestScoped<Resource>(() => Resource(log));

      late Resource resource;
      await RequestScopedDI(parent: app).run(() async {
        resource = RequestScopedDI.current.get<Resource>();
        expect(resource.disposed, isFalse);
      });

      expect(resource.disposed, isTrue);
      expect(log, ['disposed']);
    });

    test('disposes even when the request throws', () async {
      final log = <String>[];
      final app = DIImpl()
        ..registerRequestScoped<Resource>(() => Resource(log));

      await expectLater(
        RequestScopedDI(parent: app).run(() async {
          RequestScopedDI.current.get<Resource>();
          throw StateError('handler blew up');
        }),
        throwsStateError,
      );

      expect(log, ['disposed'], reason: 'a failed request still releases');
    });

    test('disposes in reverse creation order', () async {
      final order = <String>[];
      final app = DIImpl()
        ..registerRequestScoped<_First>(() => _First(order))
        ..registerRequestScoped<_Second>(() => _Second(order));

      await RequestScopedDI(parent: app).run(() async {
        RequestScopedDI.current
          ..get<_First>()
          ..get<_Second>();
      });

      expect(order, ['second', 'first']);
    });

    test('a failing dispose does not skip the rest', () async {
      final log = <String>[];
      final app = DIImpl()
        ..registerRequestScoped<ExplodingResource>(ExplodingResource.new)
        ..registerRequestScoped<Resource>(() => Resource(log));

      await RequestScopedDI(parent: app).run(() async {
        RequestScopedDI.current
          ..get<Resource>()
          ..get<ExplodingResource>();
      });

      expect(log, ['disposed'], reason: 'ran despite the earlier failure');
    });

    test('skips dependencies that are not Disposable', () async {
      final app = DIImpl()..registerRequestScoped<Counter>(() => Counter(1));

      await expectLater(
        RequestScopedDI(parent: app).run(() async {
          RequestScopedDI.current.get<Counter>();
        }),
        completes,
      );
    });

    test('is safe to call twice', () async {
      final log = <String>[];
      final app = DIImpl()
        ..registerRequestScoped<Resource>(() => Resource(log));

      final scope = RequestScopedDI(parent: app);
      await scope.run(() async => RequestScopedDI.current.get<Resource>());
      await scope.dispose();

      expect(log, ['disposed'], reason: 'disposed exactly once');
    });
  });

  group('zone access', () {
    test('maybeCurrent is null outside a request', () {
      expect(RequestScopedDI.maybeCurrent, isNull);
    });

    test('current explains itself outside a request', () {
      expect(() => RequestScopedDI.current, throwsStateError);
    });

    test('getFrom prefers the request scope', () async {
      final app = DIImpl()..registerSingleton<String>('app');
      final scope = RequestScopedDI(parent: app)
        ..registerSingleton<String>('request');

      await scope.run(() async {
        expect(RequestScopedDI.getFrom<String>(app), 'request');
      });

      expect(RequestScopedDI.getFrom<String>(app), 'app');
    });

    test('the scope survives an async gap', () async {
      final app = DIImpl()..registerRequestScoped<Counter>(() => Counter(1));

      await RequestScopedDI(parent: app).run(() async {
        await Future<void>.delayed(const Duration(milliseconds: 5));

        expect(RequestScopedDI.maybeCurrent, isNotNull);
        expect(RequestScopedDI.current.get<Counter>().id, 1);
      });
    });

    test('concurrent requests do not see each other', () async {
      var built = 0;
      final app = DIImpl()
        ..registerRequestScoped<Counter>(() => Counter(++built));

      Future<int> request() => RequestScopedDI(parent: app).run(() async {
        final first = RequestScopedDI.current.get<Counter>().id;
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Still the same instance after yielding to the other request.
        expect(RequestScopedDI.current.get<Counter>().id, first);

        return first;
      });

      final ids = await Future.wait([request(), request(), request()]);

      expect(ids.toSet(), hasLength(3), reason: 'each request got its own');
    });
  });
}

class _First implements Disposable {
  _First(this.order);

  final List<String> order;

  @override
  void dispose() => order.add('first');
}

class _Second implements Disposable {
  _Second(this.order);

  final List<String> order;

  @override
  void dispose() => order.add('second');
}
