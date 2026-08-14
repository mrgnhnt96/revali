// Spawned as a child process by `ticked_progress_test.dart`, so its stdout is
// a real pipe — the same shape `revali dev` has when `revali up` runs it, and
// the only way to see the bytes a progress line actually writes.
//
// Usage: dart run <this> <impl> <mode>
//
//   impl: mason      — mason_logger's own Progress
//         ticked     — TickedProgress, animation left to `progressCanAnimate`
//         ticked-on  — TickedProgress, animation forced on
//         main-timer — a spinner driven by Timer.periodic on *this* isolate,
//                      which is what mason_logger does when it has a terminal
//
//   mode: block — hold the main isolate in a synchronous loop, which is what
//                 the analyzer does to it during generation
//         idle  — await instead; the control, which any spinner passes
import 'dart:async';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:revali/utils/ticked_progress.dart';

const _frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];

Future<void> main(List<String> args) async {
  final [impl, mode] = args;

  stderr.writeln('hasTerminal=${stdout.hasTerminal}');

  final void Function([String? message]) complete;

  switch (impl) {
    case 'mason':
      final progress = Logger().progress('working');
      complete = progress.complete;
    case 'ticked':
      final progress = TickedProgress('working');
      complete = progress.complete;
    case 'ticked-on':
      final progress = TickedProgress('working', animate: true);
      complete = progress.complete;
    case 'main-timer':
      // The control. Deliberately the same shape as mason_logger's terminal
      // path: a Timer.periodic on the isolate that is about to be blocked.
      var frame = 0;
      stdout.write('${_frames.first} working...');
      final ticker = Timer.periodic(const Duration(milliseconds: 80), (_) {
        frame++;
        stdout.write('\r${_frames[frame % _frames.length]} working...');
      });
      complete = ([message]) {
        ticker.cancel();
        stdout.write('\r✓ ${message ?? 'working'}\n');
      };
    default:
      throw ArgumentError.value(impl, 'impl');
  }

  if (mode == 'block') {
    // A synchronous busy loop. No timer, microtask or event can run on this
    // isolate until it ends — `await Future.delayed` would yield, and every
    // implementation would pass.
    final until = DateTime.now().add(const Duration(milliseconds: 1200));
    while (DateTime.now().isBefore(until)) {
      // Deliberately empty.
    }
  } else {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
  }

  complete('done');

  // Give the sidecar's final write a moment to land before the process goes.
  await Future<void>.delayed(const Duration(milliseconds: 50));
}
