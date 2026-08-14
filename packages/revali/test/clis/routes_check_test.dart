import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali/clis/revali_runner/commands/routes_command.dart';
import 'package:revali/handlers/construct_entrypoint_handler.dart';
import 'package:test/test.dart';

class RecordingLogger extends Logger {
  final infos = <String>[];
  final errors = <String>[];

  @override
  void info(String? message, {LogStyle? style}) => infos.add(message ?? '');

  @override
  void err(String? message, {LogStyle? style}) => errors.add(message ?? '');

  @override
  void success(String? message, {LogStyle? style}) => infos.add(message ?? '');

  String get output => [...infos, ...errors].join('\n');
}

Map<String, dynamic> manifest(List<Map<String, dynamic>> routes) => {
  'version': 2,
  'prefix': 'api',
  'routes': routes,
};

Map<String, dynamic> route({
  String path = '/api/users',
  String returns = 'User',
  List<Map<String, dynamic>> params = const [],
}) => {
  'method': 'GET',
  'path': path,
  'controller': 'UsersController',
  'handler': 'get',
  'sse': false,
  'webSocket': false,
  'returns': returns,
  'returnsNullable': false,
  'params': params,
  'lifecycle': <String>[],
};

void main() {
  late MemoryFileSystem fs;
  late RecordingLogger logger;

  setUp(() {
    fs = MemoryFileSystem();
    logger = RecordingLogger();

    // `rootOf` walks up looking for a pubspec, so the fixture needs one.
    fs.directory('/repo').createSync(recursive: true);
    fs.file('/repo/pubspec.yaml').writeAsStringSync('name: app\n');
  });

  void writeCurrent(Map<String, dynamic> payload) {
    fs.directory('/repo/.revali/server').createSync(recursive: true);
    fs
        .file('/repo/.revali/server/routes.json')
        .writeAsStringSync(jsonEncode(payload));
  }

  void writePinned(Map<String, dynamic> payload) {
    fs.file('/repo/pinned.json').writeAsStringSync(jsonEncode(payload));
  }

  Future<int> runCheck() async {
    final command = RoutesCommand(
      fs: fs,
      logger: logger,
      generator: ConstructEntrypointHandler(
        initialDirectory: '/repo',
        fs: fs,
        logger: logger,
      ),
    );
    final runner = CommandRunner<int>('revali', 'test')..addCommand(command);

    return await runner.run(['routes', '--check', '/repo/pinned.json']) ?? 0;
  }

  group('revali routes --check', () {
    test('exits 0 when nothing changed', () async {
      writeCurrent(manifest([route()]));
      writePinned(manifest([route()]));

      expect(await runCheck(), 0);
      expect(logger.output, contains('No contract changes'));
    });

    test('exits 1 when a route the consumer calls disappears', () async {
      writePinned(manifest([route(), route(path: '/api/teams')]));
      writeCurrent(manifest([route()]));

      // The exit code is the whole point: this is meant to gate CI.
      expect(await runCheck(), 1);
      expect(logger.output, contains('BREAKING'));
      expect(logger.output, contains('route removed'));
    });

    test('exits 0 for a compatible change, and still reports it', () async {
      writePinned(manifest([route()]));
      writeCurrent(manifest([route(), route(path: '/api/teams')]));

      expect(await runCheck(), 0);
      expect(logger.output, contains('compatible'));
      expect(logger.output, contains('route added'));
    });

    test('exits 1 when a return type changes', () async {
      writePinned(manifest([route()]));
      writeCurrent(manifest([route(returns: 'UserDto')]));

      expect(await runCheck(), 1);
      expect(logger.output, contains('now UserDto'));
    });

    test('fails when the pinned manifest is missing', () async {
      writeCurrent(manifest([route()]));

      expect(await runCheck(), 1);
      expect(logger.output, contains('No pinned manifest'));
    });

    test('fails when the current manifest has not been generated', () async {
      writePinned(manifest([route()]));

      expect(await runCheck(), 1);
      expect(logger.output, contains('No routes.json'));
    });

    test('fails on an unreadable manifest rather than passing it', () async {
      writeCurrent(manifest([route()]));
      fs.file('/repo/pinned.json').writeAsStringSync('not json at all');

      // Reporting "no changes" for a file it could not read would be the
      // worst possible outcome for a check meant to gate a release.
      expect(await runCheck(), 1);
      expect(logger.output, contains('Could not compare'));
    });
  });
}
