import 'dart:io';

import 'package:file/local.dart';
// `overrideAnsiOutput` is `package:io`'s, re-exported here. Taken from
// `mason_logger` because `mason_logger` is what it has to agree with: the
// override sets the zone value that `mason_logger`'s own `ansiOutputEnabled`
// reads, and two copies of `package:io` in one program would not share it.
import 'package:mason_logger/mason_logger.dart';
import 'package:revali/clis/revali_runner/revali_runner.dart';
import 'package:revali/services/ansi.dart';

void runRevali(List<String> args) {
  // The child half of `revali up`'s colour handshake.
  //
  // `mason_logger` colours through `ansiOutputEnabled`, which answers
  // `Zone.current[AnsiCode] ?? (stdout.supportsAnsiEscapes && ...)` — false
  // whenever this process's stdout is a pipe, which is exactly what it is when
  // `revali up` spawned it. [overrideAnsiOutput] sets the zone value that
  // branch reads, which is why the whole run goes inside it rather than the
  // colour being turned on somewhere: a `Progress` frame is written from a
  // timer, and a timer paints in the zone it was *created* in.
  //
  // Only when asked. `revali dev` run from a real terminal already gets this
  // right on its own, and forcing it would put escape sequences into every
  // redirected build log in the world. See [kForceAnsiEnvVar] for why the
  // parent is the one that decides.
  if (Platform.environment[kForceAnsiEnvVar] == '1') {
    overrideAnsiOutput(true, () => _run(args));

    return;
  }

  _run(args);
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
