import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:revali/clis/revali_runner/commands/mixins/construct_runner_args.dart';
import 'package:revali/clis/revali_runner/commands/utils/validate_tls_args.dart';
import 'package:revali/clis/shared/commands/construct_flags.dart';
import 'package:revali/handlers/construct_entrypoint_handler.dart';

class DevCommand extends Command<int> with ConstructRunnerArgs {
  DevCommand({
    required ConstructEntrypointHandler generator,
    required this.logger,
    required this.fs,
  }) : _generator = generator {
    argParser
      ..addFlag(
        'recompile',
        help:
            'Re-compiles the construct kernel. '
            'Needed to sync changes for a local construct.',
        negatable: false,
      )
      ..addFlag(
        'skip-if-fresh',
        help:
            'Skip kernel + construct generation when `.revali` outputs are '
            'newer than package sources.',
        negatable: false,
      );

    sharedDevFlags.declareAll(argParser);

    argParser
      ..addFlag(
        'inspect',
        help:
            'Record recent requests to .revali/inspect/requests.jsonl '
            '(sets REVALI_INSPECT / REVALI_INSPECT_LOG)',
        negatable: false,
      )
      ..addOption(
        'cert',
        help:
            'Path to a TLS certificate chain (PEM). Binds the server with '
            'HTTPS. Must be passed together with --key.',
        valueHelp: 'certificates/localhost.pem',
      )
      ..addOption(
        'key',
        help:
            'Path to the TLS private key (PEM) matching --cert. '
            'Must be passed together with --cert.',
        valueHelp: 'certificates/localhost-key.pem',
      );
  }

  final ConstructEntrypointHandler _generator;
  @override
  final Logger logger;
  final FileSystem fs;

  @override
  String get name => 'dev';

  @override
  String get description => 'Starts the development server';

  @override
  List<ConstructFlag> get forwardedFlags => sharedDevFlags;

  String? get _certPath => switch (argResults?['cert'] as String?) {
    null => null,
    final path => p.absolute(path),
  };

  String? get _keyPath => switch (argResults?['key'] as String?) {
    null => null,
    final path => p.absolute(path),
  };

  @override
  List<String> get constructRunnerArgs {
    final args = super.constructRunnerArgs;
    if (argResults?['inspect'] as bool? ?? false) {
      args
        ..add('--dart-define=REVALI_INSPECT=true')
        ..add(
          '--dart-define=REVALI_INSPECT_LOG=.revali/inspect/requests.jsonl',
        );
    }
    if ((_certPath, _keyPath) case (final cert?, final key?)) {
      args
        ..add('--dart-define=REVALI_CERT=$cert')
        ..add('--dart-define=REVALI_KEY=$key');
    }
    return args;
  }

  @override
  String get usage {
    // return super.usage;
    final [description, args] = super.usage.split(
      '\nUsage: revali dev [arguments]',
    );
    return '''
$description
Usage: revali dev [options] [-- <server arguments>]
$args''';
  }

  @override
  Future<int> run() async {
    final argResults = this.argResults!;

    if (validateTlsArgs(cert: _certPath, key: _keyPath, fs: fs)
        case final error?) {
      logger.err(error);
      return 1;
    }

    final recompile = argResults['recompile'] as bool;
    final skipIfFresh = argResults['skip-if-fresh'] as bool;

    late final bool shouldRunConstructs;
    try {
      shouldRunConstructs = await _generator.generate(
        recompile: recompile,
        skipIfFresh: skipIfFresh,
      );
    } catch (e) {
      logger
        ..detail('Error: $e')
        ..err('Failed to generate the construct');
      return 1;
    }

    if (!shouldRunConstructs) {
      return 0;
    }

    logger.write('\n');

    // The construct runner's own exit code, not a constant: it is what says
    // whether generation actually succeeded, and for a real `dev` run it is
    // the server's exit code.
    return _generator.run(constructRunnerArgs);
  }
}
