import 'package:analyzer/error/error.dart';
// `src`, like `ast/analyzer/analyzer.dart` in lib: the analyzer exposes no
// public `Source` implementation, and a hand-rolled one would be a dozen
// members of noise around the two this test actually reads.
import 'package:analyzer/src/string_source.dart';
import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:platform/platform.dart';
import 'package:revali/ast/analyzer/analyzer.dart';
import 'package:revali/ast/find/find_impl.dart';
import 'package:revali/clis/construct_runner/commands/dev_command.dart';
import 'package:revali/handlers/routes_handler.dart';
import 'package:revali/utils/type_def/start_process.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:test/test.dart';

/// `dev --generate-only` reporting whether the project it generated from
/// actually analyses.
///
/// It used to `return 0` unconditionally. Appending a line of invalid Dart to
/// a route file in test_suite/constructs/revali_server/messaging printed 14
/// analysis errors, emitted a server anyway, and exited 0 -- so
/// scripts/verify_generated_suites.sh, CI and the pre-push hook all read
/// "the generator produced a server" as "the project is sound", and the real
/// failure only turned up later as a compile error in whatever consumed the
/// output.
class RecordingLogger extends Logger {
  final lines = <String>[];

  @override
  void err(String? message, {LogStyle? style}) => lines.add(message ?? '');

  @override
  void write(String? message) => lines.add(message ?? '');

  String get output => lines.join();
}

class StubRoutesHandler extends RoutesHandler {
  StubRoutesHandler({
    required super.fs,
    required super.rootPath,
    required super.analyzer,
    this.result = const [],
  });

  final List<(String, List<AnalysisError>)> result;

  /// Whether generation was attempted. Analysis errors must stop it, so this
  /// staying false is half of what the first test asserts.
  bool didParse = false;

  @override
  Future<List<(String, List<AnalysisError>)>> errors() async => result;

  @override
  Future<MetaServer> parse() async {
    didParse = true;
    return const MetaServer(routes: [], apps: [], public: []);
  }
}

AnalysisError errorSaying(String message, {String path = 'routes/app.dart'}) =>
    AnalysisError.forValues(
      source: StringSource('', path),
      offset: 0,
      length: 1,
      diagnosticCode: diagnosticCodeValues.first,
      message: message,
    );

void main() {
  late MemoryFileSystem fs;
  late RecordingLogger logger;
  late Analyzer analyzer;

  setUp(() {
    fs = MemoryFileSystem.test();
    logger = RecordingLogger();

    const platform = LocalPlatform();
    analyzer = Analyzer(
      fs: fs,
      find: FindImpl(
        platform: platform,
        fs: fs,
        startProcess: processToDetails,
      ),
      platform: platform,
      logger: logger,
    );
  });

  Future<(int?, StubRoutesHandler)> runGenerateOnly(
    List<(String, List<AnalysisError>)> errors,
  ) async {
    final routesHandler = StubRoutesHandler(
      fs: fs,
      rootPath: '/repo',
      analyzer: analyzer,
      result: errors,
    );

    final runner = CommandRunner<int>('revali', 'test')
      ..addCommand(
        DevCommand(
          rootPath: '/repo',
          constructs: const [],
          fs: fs,
          logger: logger,
          analyzer: analyzer,
          routesHandler: routesHandler,
        ),
      );

    return (await runner.run(['dev', '--generate-only']), routesHandler);
  }

  group('dev --generate-only', () {
    test('exits non-zero when the project does not analyse', () async {
      final (code, routesHandler) = await runGenerateOnly([
        ('routes/app.dart', [errorSaying("Expected to find ';'.")]),
      ]);

      expect(code, 1);
      expect(
        routesHandler.didParse,
        isFalse,
        reason: 'source that does not analyse must not be generated from',
      );
    });

    test('names the file and the message it failed on', () async {
      final (_, _) = await runGenerateOnly([
        ('routes/app.dart', [errorSaying("Expected to find ';'.")]),
        ('lib/models/user.dart', [errorSaying("Undefined class 'not'.")]),
      ]);

      expect(logger.output, contains('Found 2 errors'));
      expect(logger.output, contains('routes/app.dart'));
      expect(logger.output, contains("Expected to find ';'."));
      expect(logger.output, contains('lib/models/user.dart'));
      expect(logger.output, contains("Undefined class 'not'."));
    });

    test('counts errors, not files', () async {
      await runGenerateOnly([
        (
          'routes/app.dart',
          [errorSaying('one'), errorSaying('two'), errorSaying('three')],
        ),
      ]);

      expect(logger.output, contains('Found 3 errors'));
    });

    test('says "error" when there is exactly one', () async {
      await runGenerateOnly([
        ('routes/app.dart', [errorSaying('only one')]),
      ]);

      expect(logger.output, contains('Found 1 error\n'));
    });
  });
}
