import 'dart:async';

import 'package:revali_construct/hot_reload/reload_coalescer.dart';
import 'package:test/test.dart';

void main() {
  group('CoalescingReloadQueue', () {
    test('runs restarts one at a time', () async {
      final runs = <int>[];
      final gates = <Completer<void>>[];

      final queue = CoalescingReloadQueue(() async {
        runs.add(runs.length + 1);
        final gate = Completer<void>();
        gates.add(gate);
        await gate.future;
      });

      final first = queue.schedule();
      await Future<void>.delayed(Duration.zero);
      expect(runs, [1]);
      expect(gates, hasLength(1));

      final second = queue.schedule();
      await Future<void>.delayed(Duration.zero);
      expect(runs, [1]);

      gates[0].complete();
      await Future<void>.delayed(Duration.zero);
      expect(runs, [1, 2]);

      gates[1].complete();
      await first;
      await second;
    });

    test('keeps only one pending restart and replaces it', () async {
      final runs = <int>[];
      final gates = <Completer<void>>[];

      final queue = CoalescingReloadQueue(() async {
        runs.add(runs.length + 1);
        final gate = Completer<void>();
        gates.add(gate);
        await gate.future;
      });

      final first = queue.schedule();
      await Future<void>.delayed(Duration.zero);

      final second = queue.schedule();
      final third = queue.schedule();
      final fourth = queue.schedule();

      gates[0].complete();
      await Future<void>.delayed(Duration.zero);

      gates[1].complete();
      await first;
      await second;
      await third;
      await fourth;

      expect(runs, [1, 2]);
    });

    test('returns the same active future while a restart is running', () async {
      final gate = Completer<void>();

      final queue = CoalescingReloadQueue(() => gate.future);

      final first = queue.schedule();
      final second = queue.schedule();

      expect(identical(first, second), isTrue);

      gate.complete();
      await first;
      await second;
    });
  });
}
