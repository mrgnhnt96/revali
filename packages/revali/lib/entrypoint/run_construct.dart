import 'package:file/local.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:platform/platform.dart';
import 'package:revali/revali.dart';
import 'package:revali/services/ansi.dart';
import 'package:revali_construct/revali_construct.dart';

/// The constructs entrypoint, and the second half of `revali up`'s colour
/// handshake.
///
/// The generated build script's `main` calls straight into this, and
/// `ConstructEntrypointHandler.run` starts that script with `Isolate.spawnUri`
/// — a *new isolate*, which begins in a fresh root zone. `runRevali` wrapping
/// its own run in [withForcedAnsi] therefore does nothing for anything printed
/// over here, and everything a developer reads while `revali dev` is up is
/// printed over here: the status board, the `Press: r reload…` legend, the
/// route table, and every `TickedProgress`.
///
/// That is why the board came out white under `revali up` while the
/// `Retrieving constructs` / `Compiling constructs entrypoint` lines above it —
/// the last things the outer process prints before this isolate takes over —
/// came out coloured. One handshake, two programs; the zone reaches one of
/// them, so the other has to ask for itself.
///
/// Reading the *environment* is what makes asking possible: an environment is
/// process-wide, so it crosses the isolate boundary a zone value cannot.
Future<int> runConstruct(
  List<String> args, {
  required List<ConstructMaker> constructs,
  required String path,
}) => withForcedAnsi(
  () => _runConstruct(args, constructs: constructs, path: path),
);

Future<int> _runConstruct(
  List<String> args, {
  required List<ConstructMaker> constructs,
  required String path,
}) async {
  const fs = LocalFileSystem();

  // `--root` is consumed by the construct kernel entrypoint / spawn caller;
  // ConstructRunner's arg parser must not see it.
  final filteredArgs = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (args[i] == ConstructEntrypointHandler.rootArgName) {
      if (i + 1 < args.length) i++;
      continue;
    }
    filteredArgs.add(args[i]);
  }

  var isLoud = false;
  var isQuiet = false;
  if (filteredArgs.contains('--loud')) {
    isLoud = true;
  } else if (filteredArgs.contains('--quiet')) {
    isQuiet = true;
  }

  final logger = Logger(
    level: isLoud
        ? Level.verbose
        : isQuiet
        ? Level.error
        : Level.info,
  );

  const platform = LocalPlatform();

  final runner = ConstructRunner(
    fs: fs,
    constructs: constructs,
    rootPath: path,
    logger: logger,
    analyzer: Analyzer(
      fs: fs,
      find: const FindImpl(
        platform: platform,
        fs: fs,
        startProcess: processToDetails,
      ),
      platform: platform,
      logger: logger,
    ),
  );

  final result = await runner.run(filteredArgs);

  return result;
}
