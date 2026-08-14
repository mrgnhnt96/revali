import 'dart:io';

import 'package:file/local.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali/clis/revali_runner/revali_runner.dart';
import 'package:revali/services/ansi.dart';

void runRevali(List<String> args) {
  // The child half of `revali up`'s colour handshake.
  //
  // `mason_logger` colours through `ansiOutputEnabled`, which answers
  // `Zone.current[AnsiCode] ?? (stdout.supportsAnsiEscapes && ...)` — false
  // whenever this process's stdout is a pipe, which is exactly what it is when
  // `revali up` spawned it. [withForcedAnsi] sets the zone value that branch
  // reads; see [kForceAnsiEnvVar] for why the parent is the one that decides,
  // and why a run from a real terminal is left alone.
  //
  // This covers *this program* and no more. Most of what `revali dev` prints —
  // the status board, the key legend, the route table — comes from the
  // constructs entrypoint, which `ConstructEntrypointHandler` starts with
  // `Isolate.spawnUri`; a zone value does not cross that boundary, so
  // `runConstruct` makes the same call on the other side. Deleting it there
  // does not fail a build, it just quietly turns the board white again.
  withForcedAnsi(() => _run(args));
}

Future<void> _run(List<String> args) async {
  const fs = LocalFileSystem();

  var isLoud = false;
  var isQuiet = false;
  if (args.contains('--loud')) {
    isLoud = true;
  } else if (args.contains('--quiet')) {
    isQuiet = true;
  }

  final logger = Logger(
    level: isLoud
        ? Level.verbose
        : isQuiet
        ? Level.error
        : Level.info,
  );

  final runner = RevaliRunner(
    initialDirectory: fs.currentDirectory.path,
    fs: fs,
    logger: logger,
  );

  final result = await runner.run(args);

  exit(result);
}
