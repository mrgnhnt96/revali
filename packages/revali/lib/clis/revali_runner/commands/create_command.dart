import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

/// Proxies to `dart run revali_server create …`.
///
/// Scaffolds live in the revali_server package.
class CreateCommand extends Command<int> {
  CreateCommand({required this.logger});

  final Logger logger;

  @override
  String get name => 'create';

  @override
  String get description =>
      'Scaffold app/controller/lifecycle-component/pipe/observer '
      '(proxies to revali_server create)';

  @override
  String get invocation =>
      'revali create <controller|app|lifecycle-component|pipe|observer> '
      '[arguments]';

  /// Forward all tokens after `create` untouched.
  @override
  ArgParser get argParser => ArgParser.allowAnything();

  @override
  Future<int> run() async {
    final forwarded = argResults?.arguments ?? const <String>[];
    final args = ['run', 'revali_server', 'create', ...forwarded];

    logger.detail('Running: dart ${args.join(' ')}');

    final process = await io.Process.start(
      'dart',
      args,
      mode: io.ProcessStartMode.inheritStdio,
      workingDirectory: io.Directory.current.path,
    );

    return process.exitCode;
  }
}
