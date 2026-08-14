import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
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

    await Future.wait(exits);

    for (final subscription in signals) {
      await subscription.cancel();
    }

    return _stopping ? 0 : 1;
  }

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
