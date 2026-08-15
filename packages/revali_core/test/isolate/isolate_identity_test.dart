import 'dart:isolate';

import 'package:revali_core/revali_core.dart';
import 'package:test/test.dart';

/// Reports what a *freshly spawned* isolate sees, so the caller can compare it
/// against what the parent set.
void reportIdentity(SendPort port) {
  final identity = IsolateIdentity.current;

  port.send([identity.index, identity.isWorker, identity.workerCount]);
}

void main() {
  tearDown(() {
    IsolateIdentity.setCurrentForGeneratedCode(IsolateIdentity.single);
  });

  group('defaults', () {
    test('describe the parent of a single-isolate app', () {
      expect(IsolateIdentity.current.index, 0);
      expect(IsolateIdentity.current.isWorker, isFalse);
      expect(IsolateIdentity.current.workerCount, 1);
    });
  });

  group('setCurrentForGeneratedCode', () {
    test('round-trips what was set', () {
      IsolateIdentity.setCurrentForGeneratedCode(
        const IsolateIdentity(index: 2, workerCount: 4),
      );

      expect(IsolateIdentity.current.index, 2);
      expect(IsolateIdentity.current.isWorker, isTrue);
      expect(IsolateIdentity.current.workerCount, 4);
    });

    test('index 0 is the parent, not a worker', () {
      IsolateIdentity.setCurrentForGeneratedCode(
        const IsolateIdentity(index: 0, workerCount: 4),
      );

      expect(IsolateIdentity.current.isWorker, isFalse);
    });
  });

  // The claim the doc comment rests on: statics are per-isolate, so what the
  // parent sets is not what a spawned isolate reads. If this ever stopped
  // holding, every isolate would report the parent's identity and naming
  // anything after it would silently collide.
  test('a spawned isolate does not inherit the parent identity', () async {
    IsolateIdentity.setCurrentForGeneratedCode(
      const IsolateIdentity(index: 3, workerCount: 8),
    );

    final receive = ReceivePort();
    final isolate = await Isolate.spawn(reportIdentity, receive.sendPort);

    addTearDown(() {
      isolate.kill(priority: Isolate.immediate);
      receive.close();
    });

    expect(await receive.first, [0, false, 1]);
    expect(IsolateIdentity.current.index, 3, reason: 'parent is untouched');
  });
}
