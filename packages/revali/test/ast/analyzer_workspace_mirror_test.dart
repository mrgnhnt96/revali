import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:platform/platform.dart';
import 'package:revali/ast/analyzer/analyzer.dart';
import 'package:revali/ast/find/find_impl.dart';
import 'package:revali/utils/type_def/start_process.dart';
import 'package:test/test.dart';

/// Reads that the analyzer performs while mirroring a workspace into its
/// in-memory overlay, with a hook for making individual reads fail.
class _ReadRecorder {
  final read = <String>[];
  int inFlight = 0;
  int peakInFlight = 0;

  /// Called before each read; return an error to fail that read.
  Exception? Function(String path)? failWith;

  Future<Uint8List> record(
    String path,
    Future<Uint8List> Function() delegate,
  ) async {
    read.add(path);
    inFlight++;
    peakInFlight = inFlight > peakInFlight ? inFlight : peakInFlight;
    try {
      if (failWith?.call(path) case final error?) {
        // Yield first so the failure races the other in-flight reads the way a
        // descriptor exhaustion would, rather than completing synchronously.
        await Future<void>.delayed(Duration.zero);
        throw error;
      }
      return await delegate();
    } finally {
      inFlight--;
    }
  }
}

class _RecordingFileSystem extends ForwardingFileSystem {
  _RecordingFileSystem(super.delegate, this.recorder);

  final _ReadRecorder recorder;

  @override
  File file(dynamic path) => _RecordingFile(delegate.file(path), recorder);
}

class _RecordingFile implements File {
  _RecordingFile(this._delegate, this._recorder);

  final File _delegate;
  final _ReadRecorder _recorder;

  @override
  Future<Uint8List> readAsBytes() =>
      _recorder.record(_delegate.path, _delegate.readAsBytes);

  @override
  String get path => _delegate.path;

  @override
  Directory get parent => _delegate.parent;

  @override
  bool existsSync() => _delegate.existsSync();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Analyzer workspace mirror', () {
    late LocalFileSystem local;
    late Directory temp;
    late Directory app;
    late _ReadRecorder recorder;
    late Analyzer analyzer;

    setUp(() {
      local = const LocalFileSystem();
      temp = local.systemTempDirectory.createTempSync('revali_mirror_');

      app = local.directory('${temp.path}/app')..createSync();
      app.childDirectory('lib').createSync();
      app.childFile('pubspec.yaml').writeAsStringSync('''
name: app
environment:
  sdk: ">=3.8.0 <4.0.0"
''');
      app.childFile('lib/main.dart').writeAsStringSync('''
String greet() => 'hello';
''');

      final appRootUri = Uri.directory(app.path).toString();
      app.childDirectory('.dart_tool').createSync(recursive: true);
      app.childFile('.dart_tool/package_config.json').writeAsStringSync('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "app",
      "rootUri": "$appRootUri",
      "packageUri": "lib/",
      "languageVersion": "3.8"
    }
  ],
  "generator": "revali_test"
}
''');

      recorder = _ReadRecorder();
      analyzer = Analyzer(
        fs: _RecordingFileSystem(local, recorder),
        find: const FindImpl(
          platform: LocalPlatform(),
          fs: LocalFileSystem(),
          startProcess: processToDetails,
        ),
        platform: const LocalPlatform(),
        logger: Logger(level: Level.quiet),
      );
    });

    tearDown(() {
      if (temp.existsSync()) {
        temp.deleteSync(recursive: true);
      }
    });

    test(
      'bounds concurrent reads so it cannot exhaust file descriptors',
      () async {
        await analyzer.initialize(root: app.path);

        // The overlay covers the workspace and the SDK — hundreds of files. An
        // unbounded fan-out holds one descriptor per in-flight read, which is
        // what silently truncated the mirror on a default 256-descriptor limit.
        expect(recorder.read.length, greaterThan(200));
        expect(recorder.peakInFlight, lessThanOrEqualTo(64));
      },
    );

    test('mirrors only the SDK files the analyzer can read', () async {
      await analyzer.initialize(root: app.path);

      final sdkRoot = await analyzer.sdkPath;
      final sdkReads = recorder.read.where((p) => p.startsWith(sdkRoot));

      expect(sdkReads, isNotEmpty, reason: 'the SDK must still be mirrored');
      expect(
        sdkReads.where((p) => local.path.isWithin('$sdkRoot/bin', p)),
        isEmpty,
        reason: 'bin/ holds the VM and AOT snapshots; analysis never reads it',
      );
      expect(
        sdkReads.where((p) => p.endsWith('.dill')),
        isEmpty,
        reason: 'kernel is not an analyzer summary',
      );
      // dart:core must survive the narrowing.
      expect(
        sdkReads.where((p) => p.endsWith('/lib/core/core.dart')),
        isNotEmpty,
      );
    });

    test(
      'a failed SDK read is not mistaken for a file that never existed',
      () async {
        recorder.failWith = (path) => path.endsWith('/lib/core/core.dart')
            ? const io.FileSystemException(
                'Too many open files',
                '',
                io.OSError('Too many open files', 24),
              )
            : null;

        await expectLater(
          analyzer.initialize(root: app.path),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              allOf(contains('Dart SDK'), contains('partial SDK')),
            ),
          ),
        );
      },
    );

    test('a genuinely absent file is still tolerated', () async {
      recorder.failWith = (path) => path.endsWith('/lib/core/core.dart')
          ? const io.FileSystemException(
              'No such file or directory',
              '',
              io.OSError('No such file or directory', 2),
            )
          : null;

      await expectLater(analyzer.initialize(root: app.path), completes);
    });
  });
}
