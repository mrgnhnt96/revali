// Spawned as a child process by `status_board_test.dart`, so its stdout is a
// real pipe — the same shape `revali dev` has when `revali up` runs it.
//
// It exists to answer a question about *provenance*: which process writes the
// status board. The board is easy to mistake for the server's own output,
// because the line above it (`Serving at ...`) is something the server really
// did print. It is not: the server prints that once, plainly, with `print`
// (`AppConfig.onServerStarted`), `revali dev` catches it on the child's stdout
// and every line of the board — including that one — is composed and coloured
// here, in `revali dev`, by `VMServiceHandler.printStatusBoard`.
//
// So it opens the way `runRevali` does. Nothing here reaches into the server
// process, and there is no server: whatever colour comes out of this is
// `revali dev`'s.
//
// Usage: dart run <this>          — no handshake, the CI shape
//        REVALI_FORCE_ANSI=1 ...  — a child under `revali up`
import 'dart:io';

import 'package:file/local.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali/handlers/vm_service_handler.dart';
import 'package:revali/services/ansi.dart';
import 'package:revali_construct/revali_construct.dart';

void main() => ansiForcedByParent()
    ? overrideAnsiOutput(true, _printBoard)
    : _printBoard();

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
