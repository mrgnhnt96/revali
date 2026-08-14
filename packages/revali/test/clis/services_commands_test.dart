import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali/clis/revali_runner/commands/compose_command.dart';
import 'package:revali/clis/revali_runner/commands/services_command.dart';
import 'package:test/test.dart';

/// Captures what the command wrote, so a test can assert on the output a user
/// actually sees rather than only on the exit code.
class RecordingLogger extends Logger {
  final infos = <String>[];
  final errors = <String>[];
  final warnings = <String>[];

  @override
  void info(String? message, {LogStyle? style}) => infos.add(message ?? '');

  @override
  void err(String? message, {LogStyle? style}) => errors.add(message ?? '');

  @override
  void warn(String? message, {String tag = 'WARN', LogStyle? style}) =>
      warnings.add(message ?? '');

  @override
  void success(String? message, {LogStyle? style}) => infos.add(message ?? '');

  String get allInfo => infos.join('\n');
  String get allErrors => errors.join('\n');
}

void main() {
  late MemoryFileSystem fs;
  late RecordingLogger logger;

  setUp(() {
    fs = MemoryFileSystem();
    logger = RecordingLogger();
  });

  void makeService(String path, String name, {bool dockerfile = false}) {
    final dir = fs.directory(path)..createSync(recursive: true);

    dir
        .childFile('pubspec.yaml')
        .writeAsStringSync('name: $name\ndependencies:\n  revali_router:\n');
    dir.childDirectory('routes').createSync();

    if (dockerfile) {
      dir.childDirectory('.revali').childDirectory('build')
        ..createSync(recursive: true)
        ..childFile('Dockerfile').writeAsStringSync('FROM dart:stable');
    }
  }

  Future<int> runCommand(Command<int> command, List<String> args) async {
    final runner = CommandRunner<int>('revali', 'test')..addCommand(command);

    return await runner.run(args) ?? 0;
  }

  group('revali services', () {
    Future<int> run(List<String> args) =>
        runCommand(ServicesCommand(fs: fs, logger: logger), args);

    test('lists what it found', () async {
      makeService('/repo/users', 'users_service');
      makeService('/repo/orders', 'orders_service');

      expect(await run(['services', '--root', '/repo']), 0);
      expect(logger.allInfo, contains('users_service'));
      expect(logger.allInfo, contains('orders_service'));
      expect(logger.allInfo, contains('2 service(s)'));
    });

    test('fails when there is nothing to list', () async {
      fs.directory('/repo').createSync(recursive: true);

      // Exiting 0 with an empty list would let a broken discovery pass a CI
      // step that meant to check something was found.
      expect(await run(['services', '--root', '/repo']), 1);
      expect(logger.allErrors, contains('No Revali services'));
    });

    test('fails on a directory that does not exist', () async {
      expect(await run(['services', '--root', '/nope']), 1);
      expect(logger.allErrors, contains('No such directory'));
    });

    test('flags services that have not been built', () async {
      makeService('/repo/a', 'built', dockerfile: true);
      makeService('/repo/b', 'unbuilt');

      await run(['services', '--root', '/repo']);

      expect(logger.allInfo, contains('unbuilt'));
      expect(logger.allInfo, contains('no Dockerfile yet'));
    });
  });

  group('revali compose', () {
    Future<int> run(List<String> args) =>
        runCommand(ComposeCommand(fs: fs, logger: logger), args);

    test('writes a compose file at the root', () async {
      makeService('/repo/users', 'users_service', dockerfile: true);

      expect(await run(['compose', '--root', '/repo']), 0);

      final written = fs.file('/repo/docker-compose.yaml');
      expect(written.existsSync(), isTrue);
      expect(written.readAsStringSync(), contains('users_service:'));
    });

    test('honours --output', () async {
      makeService('/repo/users', 'users_service', dockerfile: true);

      await run(['compose', '--root', '/repo', '-o', '/tmp/out.yaml']);

      expect(fs.file('/tmp/out.yaml').existsSync(), isTrue);
    });

    test('honours --base-port', () async {
      makeService('/repo/users', 'users_service', dockerfile: true);

      await run(['compose', '--root', '/repo', '--base-port', '9100']);

      expect(
        fs.file('/repo/docker-compose.yaml').readAsStringSync(),
        contains("PORT: '9100'"),
      );
    });

    test('rejects a non-numeric base port', () async {
      makeService('/repo/users', 'users_service');

      expect(
        await run(['compose', '--root', '/repo', '--base-port', 'eighty']),
        1,
      );
      expect(logger.allErrors, contains('must be a number'));
    });

    test('warns about services that cannot be built yet', () async {
      makeService('/repo/ready', 'built', dockerfile: true);
      makeService('/repo/not-ready', 'unbuilt');

      await run(['compose', '--root', '/repo']);

      // `docker compose up` would fail on these, and the reason is otherwise
      // only in a comment inside a generated file nobody reads. The warning
      // names the *path*, since that is where `revali build` has to be run.
      final warning = logger.warnings.join();

      expect(warning, contains('not-ready'));
      expect(warning, isNot(contains('/repo/ready')));
    });

    test('does not warn when everything is built', () async {
      makeService('/repo/a', 'built', dockerfile: true);

      await run(['compose', '--root', '/repo']);

      expect(logger.warnings, isEmpty);
    });

    test('prints instead of writing with --stdout', () async {
      makeService('/repo/users', 'users_service', dockerfile: true);

      expect(await run(['compose', '--root', '/repo', '--stdout']), 0);
      expect(fs.file('/repo/docker-compose.yaml').existsSync(), isFalse);
    });

    test('fails when there is nothing to generate', () async {
      fs.directory('/repo').createSync(recursive: true);

      expect(await run(['compose', '--root', '/repo']), 1);
      expect(fs.file('/repo/docker-compose.yaml').existsSync(), isFalse);
    });
  });
}
