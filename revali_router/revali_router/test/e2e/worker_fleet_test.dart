import 'dart:async';
import 'dart:isolate';

import 'package:revali_router/revali_router.dart';
import 'package:test/test.dart';

/// Registers, then reports the drain delay it was told to use.
void _reportingWorker(List<Object> boot) {
  final registration = boot[0] as SendPort;
  final observer = boot[1] as SendPort;

  listenForDrainCommands(registration, (drainDelay) async {
    observer.send(drainDelay.inMicroseconds);
  });
}

/// Registers, then never finishes draining.
void _hangingWorker(SendPort registration) {
  listenForDrainCommands(registration, (_) => Completer<void>().future);
}

/// Registers, then throws while draining.
void _throwingWorker(SendPort registration) {
  listenForDrainCommands(
    registration,
    (_) async => throw StateError('pool close failed'),
  );
}

/// Polls until [condition] holds, so a test never races isolate startup.
Future<void> until(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));

  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('condition never became true');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  group('WorkerFleet', () {
    late WorkerFleet fleet;
    final spawned = <Isolate>[];

    setUp(() => fleet = WorkerFleet());

    tearDown(() {
      for (final isolate in spawned) {
        isolate.kill(priority: Isolate.immediate);
      }
      spawned.clear();
      fleet.reset();
    });

    test('drains with nothing registered', () async {
      expect(
        await fleet.drainAll(
          drainDelay: Duration.zero,
          timeout: const Duration(seconds: 1),
        ),
        isTrue,
      );
    });

    test('a worker registers and drains on command', () async {
      final registration = fleet.open();
      final observed = ReceivePort();

      spawned.add(
        await Isolate.spawn(_reportingWorker, <Object>[
          registration,
          observed.sendPort,
        ]),
      );

      await until(() => fleet.registered == 1);

      expect(
        await fleet.drainAll(
          drainDelay: const Duration(milliseconds: 40),
          timeout: const Duration(seconds: 5),
        ),
        isTrue,
      );

      // The parent's delay reaches the worker, so every isolate opens the
      // same readiness window rather than only the one handling the signal.
      expect(
        await observed.first,
        const Duration(milliseconds: 40).inMicroseconds,
      );

      observed.close();
    });

    test('every worker in the fleet is told to drain', () async {
      final registration = fleet.open();
      final observed = ReceivePort();
      final drained = <int>[];

      observed.listen((message) => drained.add(message as int));

      for (var i = 0; i < 3; i++) {
        spawned.add(
          await Isolate.spawn(_reportingWorker, <Object>[
            registration,
            observed.sendPort,
          ]),
        );
      }

      await until(() => fleet.registered == 3);

      expect(
        await fleet.drainAll(
          drainDelay: Duration.zero,
          timeout: const Duration(seconds: 5),
        ),
        isTrue,
      );

      await until(() => drained.length == 3);

      expect(drained, hasLength(3));

      observed.close();
    });

    test('a hanging worker costs the timeout, not the shutdown', () async {
      final registration = fleet.open();

      spawned.add(await Isolate.spawn(_hangingWorker, registration));

      await until(() => fleet.registered == 1);

      // Reports failure rather than throwing or waiting forever: the caller
      // is on its way to exit either way.
      expect(
        await fleet.drainAll(
          drainDelay: Duration.zero,
          timeout: const Duration(milliseconds: 200),
        ),
        isFalse,
      );
    });

    test('a worker that throws while draining still reports back', () async {
      final registration = fleet.open();

      spawned.add(await Isolate.spawn(_throwingWorker, registration));

      await until(() => fleet.registered == 1);

      // Without the reply, the parent would wait out its whole timeout for a
      // worker that already knows it is finished.
      expect(
        await fleet.drainAll(
          drainDelay: Duration.zero,
          timeout: const Duration(seconds: 5),
        ),
        isTrue,
      );
    });

    test('reset forgets a previous generation of workers', () async {
      final registration = fleet.open();
      final observed = ReceivePort();

      spawned.add(
        await Isolate.spawn(_reportingWorker, <Object>[
          registration,
          observed.sendPort,
        ]),
      );

      await until(() => fleet.registered == 1);

      // Hot reload respawns workers; without reset the old generation's ports
      // accumulate and every restart waits on isolates that are already gone.
      fleet.reset();

      expect(fleet.registered, 0);
      expect(
        await fleet.drainAll(
          drainDelay: Duration.zero,
          timeout: const Duration(milliseconds: 200),
        ),
        isTrue,
      );

      observed.close();
    });
  });
}
