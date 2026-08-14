// Spawned as a child process by `status_board_test.dart`, so its stdout is a
// real pipe — the same shape `revali dev` has when `revali up` runs it.
//
// It answers two questions.
//
// *Provenance*: which process writes the status board. The board is easy to
// mistake for the server's own output, because the line above it (`Serving at
// ...`) is something the server really did print. It is not: the server prints
// that once, plainly, with `print` (`AppConfig.onServerStarted`), `revali dev`
// catches it on the child's stdout, and every line of the board — including
// that one — is composed and coloured by `VMServiceHandler.printStatusBoard`.
// Nothing here reaches into a server process, and there is no server: whatever
// colour comes out of this is `revali dev`'s.
//
// *Reach*: how far one handshake gets. `revali dev` is two programs — the
// `revali` CLI, and the constructs entrypoint it starts with
// `Isolate.spawnUri` — and the board is printed by the second. `--spawn`
// reproduces that pair here, because a probe that only ever printed the board
// on the isolate it started on is exactly the probe that said the board was
// coloured while a real terminal showed it white.
//
// Usage: dart run <this>                  — no handshake, the CI shape
//        REVALI_FORCE_ANSI=1 ...          — a child under `revali up`
//        ... --spawn                      — force ANSI here, then print the
//                                           board from an isolate spawned the
//                                           way `revali dev` spawns its own
//        ... --spawn --naked              — the same pair, with the spawned
//                                           half not asking for itself: what
//                                           the constructs entrypoint used to
//                                           do, and the shape of the defect
import 'dart:io';
import 'dart:isolate';

import 'package:file/local.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali/handlers/vm_service_handler.dart';
import 'package:revali/services/ansi.dart';
import 'package:revali_construct/revali_construct.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--spawn')) {
    // The parent half: `runRevali`, which forces the colour on for its own
    // isolate and then hands the real work to another one.
    await withForcedAnsi(() => _spawn(naked: args.contains('--naked')));

    return;
  }

  // The spawned half, and the whole of the question this file exists to
  // answer: `--naked` is a `main` that trusts the zone it was spawned from,
  // and anything else asks the environment for itself the way `runConstruct`
  // does.
  if (args.contains('--naked')) {
    _printBoard();

    return;
  }

  withForcedAnsi(_printBoard);
}

/// Starts this same file in a second isolate and waits for it to finish.
///
/// `Isolate.spawnUri` and not `Isolate.spawn`, because it is the boundary
/// `ConstructEntrypointHandler.run` crosses — and the two are not the same
/// boundary for this: `spawn` shares the spawning isolate's code but neither
/// shares its zone, so the URI form is the one worth pinning.
Future<void> _spawn({required bool naked}) async {
  final done = ReceivePort();

  await Isolate.spawnUri(
    Platform.script,
    [if (naked) '--naked'],
    null,
    onExit: done.sendPort,
  );

  await done.first;

  done.close();
}

void _printBoard() {
  const fs = LocalFileSystem();

  final handler = VMServiceHandler(
    root: fs.currentDirectory,
    serverFile: 'server.dart',
    codeGenerator: ([_]) async => throw UnimplementedError(),
    logger: Logger(),
    // The board only prints `[READY]` and the key hints when a reload is
    // possible, which is the case a developer running `revali up` is in.
    canHotReload: true,
    serverArgs: const [],
    mode: Mode.debug,
    onFilesChange: (_) async {},
    onFileRemove: (_) async {},
    errors: () async => [],
  );

  handler.printStatusBoard(tag: StatusBoardTag.ready);
}
