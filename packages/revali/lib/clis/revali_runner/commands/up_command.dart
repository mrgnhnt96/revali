import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:revali/services/service_discovery.dart';
import 'package:revali/services/service_plan.dart';

/// Runs every service in the repository at once.
///
/// A system split across five services is five `revali dev` processes in five
/// terminals, which is the point at which people stop running the whole thing
/// locally and start developing one service against staging or mocks. Both
/// hide exactly the mismatches that splitting into services creates — and a
/// system you cannot run is a system you cannot trust to work deployed.
class UpCommand extends Command<int> {
  UpCommand({required this.logger, required this.fs}) {
    argParser
      ..addOption(
        'root',
        help: 'Directory to search from. Defaults to the working directory.',
        valueHelp: 'path',
      )
      ..addMultiOption(
        'only',
        help: 'Run just these services, by package name or path.',
        valueHelp: 'name',
      )
      ..addOption(
        'base-port',
        help: 'First port to assign; services take one each in order.',
        valueHelp: 'port',
        defaultsTo: '8080',
      );
  }

  final Logger logger;
  final FileSystem fs;

  /// Children, so a signal can reach all of them.
  final _running = <String, io.Process>{};

  var _stopping = false;

  @override
  String get name => 'up';

  @override
  String get description => 'Run every Revali service in this repository';

  @override
  Future<int> run() async {
    final rootPath = argResults?['root'] as String? ?? fs.currentDirectory.path;
    final root = fs.directory(rootPath);

    if (!root.existsSync()) {
      logger.err('No such directory: $rootPath');

      return 1;
    }

    final basePort = int.tryParse(argResults?['base-port'] as String? ?? '');
    if (basePort == null) {
      logger.err('--base-port must be a number');

      return 1;
    }

    final services = const ServiceDiscovery().find(root);

    if (services.isEmpty) {
      logger.err(
        'No Revali services found under $rootPath.\n'
        'A service is a package with a routes/ directory that depends on '
        'revali_router.',
      );

      return 1;
    }

    final List<ServicePlan> plans;
    try {
      plans = planServices(
        services,
        basePort: basePort,
        only: argResults?['only'] as List<String>? ?? const [],
      );
    } on UnknownServiceException catch (e) {
      logger.err('$e');

      return 1;
    }

    return _runAll(plans);
  }

  Future<int> _runAll(List<ServicePlan> plans) async {
    final width = plans
        .map((p) => p.label.length)
        .reduce((a, b) => a > b ? a : b);

    logger.info('Starting ${plans.length} service(s)\n');
    for (final (index, plan) in plans.indexed) {
      final color = colorFor(index);
      logger.info(
        '  ${color.wrap(plan.label.padRight(width))}  '
        'http://localhost:${plan.port}',
      );
    }
    logger.info('');

    final exits = <Future<void>>[];

    for (final (index, plan) in plans.indexed) {
      // One service failing to start must not take the others down: the usual
      // cause is a compile error the developer is about to fix, and losing the
      // whole fleet for it makes the loop worse, not safer.
      await _start(plan, colorFor(index), width, exits);
    }

    if (exits.isEmpty) {
      logger.err('No service could be started.');

      return 1;
    }

    // A signal here has to reach the children: they are the ones holding
    // ports and in-flight requests, and the generated server already knows
    // how to drain on SIGTERM.
    final signals = _listenForShutdown();
    final keys = _listenForKeystrokes(plans);

    await Future.wait(exits);

    for (final subscription in signals) {
      await subscription.cancel();
    }

    await _restoreStdin(keys);

    return _stopping ? 0 : 1;
  }

  /// Forwards `r` / `c` / `q` to every child service.
  ///
  /// The keys cannot simply be passed through. A child's stdin is a pipe, not
  /// a terminal, so `revali dev` inside it takes its headless path and never
  /// reads keystrokes at all — which is why pressing `r` under `revali up`
  /// used to do nothing while file-watching reload worked fine.
  ///
  /// `revali dev` already has the answer: without a TTY it watches a
  /// `.revali_cmd` file in the project root for `reload` / `clear` / `quit`.
  /// So this translates the keypress into that file rather than inventing a
  /// second channel — one service per file, in its own directory.
  ///
  /// Returns null when there is no terminal to read (CI, a pipe), where there
  /// are no keystrokes to forward in the first place.
  StreamSubscription<List<int>>? _listenForKeystrokes(List<ServicePlan> plans) {
    if (!io.stdin.hasTerminal) {
      return null;
    }

    try {
      // Raw mode, so a single key registers without waiting for Enter.
      io.stdin
        ..echoMode = false
        ..lineMode = false;
    } catch (_) {
      // A pseudo-TTY can report hasTerminal and still refuse raw mode.
      return null;
    }

    logger.info(
      '${darkGray.wrap('Press ')}${yellow.wrap('r')}'
      '${darkGray.wrap(' reload  ')}${yellow.wrap('c')}'
      '${darkGray.wrap(' clear  ')}${yellow.wrap('q')}'
      '${darkGray.wrap(' quit')}\n',
    );

    return io.stdin.listen((bytes) {
      for (final key in utf8.decode(bytes, allowMalformed: true).split('')) {
        switch (key.toLowerCase()) {
          case 'r':
            broadcastCommand(plans, 'reload');
          case 'c':
            broadcastCommand(plans, 'clear');
          case 'q':
            // The children are told to quit *and* the fleet stops: a child
            // that is wedged badly enough to ignore its command file must not
            // leave `revali up` waiting on it forever.
            broadcastCommand(plans, 'quit');
            _stop();
        }
      }
    });
  }

  /// Writes [command] to every service's `.revali_cmd`.
  ///
  /// Public so a test can drive it without starting real processes.
  void broadcastCommand(List<ServicePlan> plans, String command) {
    for (final plan in plans) {
      final file = fs.file(
        p.join(plan.service.directory.path, _devCommandFileName),
      );

      try {
        // Newline-terminated: the reader splits on line breaks, and a bare
        // token with nothing after it is one `readAsString` race away from
        // being read half-written.
        file.writeAsStringSync('$command\n', flush: true);
      } catch (e) {
        // One unwritable directory must not stop the other services from
        // getting the command.
        logger.detail('Could not signal ${plan.label}: $e');
      }
    }
  }

  Future<void> _restoreStdin(StreamSubscription<List<int>>? keys) async {
    if (keys == null) {
      return;
    }

    await keys.cancel();

    try {
      // Leaving the terminal in raw mode makes the user's shell unusable
      // afterwards — no echo, no line editing.
      io.stdin
        ..echoMode = true
        ..lineMode = true;
    } catch (_) {
      // Nothing to restore if the mode never took.
    }
  }

  /// The file `revali dev` watches when it has no terminal of its own.
  static const _devCommandFileName = '.revali_cmd';

  /// Starts one service, appending its exit future to [exits].
  ///
  /// A service that cannot start adds nothing, so the fleet carries on without
  /// it. The label is padded *before* it is coloured: ANSI escapes count
  /// toward string length, so padding afterwards misaligns every prefix.
  Future<void> _start(
    ServicePlan plan,
    AnsiCode color,
    int width,
    List<Future<void>> exits,
  ) async {
    final label = color.wrap(plan.label.padRight(width)) ?? plan.label;

    final io.Process process;
    try {
      process = await io.Process.start(
        'dart',
        ['run', 'revali', 'dev'],
        workingDirectory: plan.service.directory.path,
        // The port the fleet assigned. `AppConfig.fromEnv` reads it; a
        // service that hard-codes its port ignores this and will collide
        // with whatever else claimed that port.
        environment: {'PORT': '${plan.port}'},
      );
    } catch (e) {
      logger.err('${plan.label}: failed to start: $e');

      return;
    }

    _running[plan.label] = process;

    void pipe(Stream<List<int>> stream, {required bool isError}) {
      stream.transform(utf8.decoder).listen((chunk) {
        for (final line in prefixLines(chunk, label)) {
          if (isError) {
            logger.err(line);
          } else {
            logger.write('$line\n');
          }
        }
      });
    }

    pipe(process.stdout, isError: false);
    pipe(process.stderr, isError: true);

    exits.add(
      process.exitCode.then<void>((code) {
        _running.remove(plan.label);

        if (_stopping) {
          return;
        }

        // Reported rather than silent: a service that dies mid-session
        // otherwise just stops producing output, which reads like idleness.
        logger.err('${plan.label} exited ($code)');
      }),
    );
  }

  List<StreamSubscription<io.ProcessSignal>> _listenForShutdown() {
    final signals = <StreamSubscription<io.ProcessSignal>>[];

    for (final signal in [
      io.ProcessSignal.sigint,
      if (!io.Platform.isWindows) io.ProcessSignal.sigterm,
    ]) {
      try {
        signals.add(signal.watch().listen((_) => _stop()));
      } catch (_) {
        // Not every platform supports every signal.
      }
    }

    return signals;
  }

  void _stop() {
    if (_stopping) {
      return;
    }
    _stopping = true;

    logger.info('\nStopping ${_running.length} service(s)...');

    for (final process in _running.values) {
      // kill() sends SIGTERM by default, which the generated server drains
      // on -- the behaviour this loop is meant to exercise.
      process.kill();
    }
  }
}
