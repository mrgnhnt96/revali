import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:path/path.dart' as path;
import 'package:stream_transform/stream_transform.dart';
import 'package:watcher/watcher.dart';
import 'package:zora_gen/extensions/directory_extensions.dart';

final _warningRegex = RegExp(r'^.*:\d+:\d+: Warning: .*', multiLine: true);

final _dartVmServiceAlreadyInUseErrorRegex = RegExp(
  '^Could not start the VM service: localhost:.* is already in use.',
  multiLine: true,
);

class VMServiceRunner {
  VMServiceRunner({
    required this.root,
    required this.serverFile,
    required this.codeGen,
    this.dartVmServicePort = '8080',
    this.onHotReloadEnabled,
  }) : assert(
          dartVmServicePort.isNotEmpty,
          'dartVmServicePort cannot be empty',
        );

  final String dartVmServicePort;
  final Directory root;
  final void Function()? onHotReloadEnabled;
  final String serverFile;
  final Future<void> Function() codeGen;

  var _isReloading = false;
  io.Process? _serverProcess;
  StreamSubscription<WatchEvent>? _watcherSubscription;

  bool get isServerRunning => _serverProcess != null;

  bool get isWatching => _watcherSubscription != null;

  bool get isCompleted => _exitCodeCompleter.isCompleted;

  final Completer<int> _exitCodeCompleter = Completer<int>();

  Future<int> get exitCode => _exitCodeCompleter.future;

  Future<void> _reload([bool verbose = false]) async {
    _isReloading = true;
    await codeGen();
    _isReloading = false;
  }

  // Internal method to kill the server process.
  // Make sure to call `stop` after calling this method to also stop the
  // watcher.
  Future<void> _killServerProcess() async {
    _isReloading = false;
    final process = _serverProcess;
    if (process == null) {
      return;
    }
    if (io.Platform.isWindows) {
      await io.Process.run('taskkill', ['/F', '/T', '/PID', '${process.pid}']);
    } else {
      process.kill();
    }
    _serverProcess = null;
  }

  // Internal method to cancel the watcher subscription.
  // Make sure to call `stop` after calling this method to also stop the
  // server process.
  Future<void> _cancelWatcherSubscription() async {
    if (!isWatching) {
      return;
    }
    await _watcherSubscription!.cancel();
    _watcherSubscription = null;
  }

  Future<void> start() async {
    if (isCompleted) {
      throw Exception(
        'Cannot start a dev server after it has been stopped.',
      );
    }

    if (isServerRunning) {
      throw Exception(
        'Cannot start a dev server while already running.',
      );
    }

    print('starting');
    print('generating code...');

    await codeGen();
    print('code generated');
    print('serving');
    await serve();
    print('served');

    final watcher = DirectoryWatcher(path.join(root.path));
    _watcherSubscription = watcher.events
        .asyncWhere(shouldReload)
        .debounce(Duration.zero)
        .listen((_) => _reload());

    _watcherSubscription!.asFuture<void>().then((_) async {
      await _cancelWatcherSubscription();
      await stop();
    }).catchError((_) async {
      await _cancelWatcherSubscription();
      await stop(1);
    }).ignore();
  }

  Future<void> stop([int exitCode = 0]) async {
    if (isCompleted) {
      return;
    }

    if (isWatching) {
      await _cancelWatcherSubscription();
    }
    if (isServerRunning) {
      await _killServerProcess();
    }

    _exitCodeCompleter.complete(exitCode);
  }

  Future<void> serve() async {
    var isHotReloadingEnabled = false;

    print('serving');
    final process = _serverProcess = await io.Process.start(
      'dart',
      [
        '--enable-vm-service=$dartVmServicePort',
        '--enable-asserts',
        serverFile,
      ],
      runInShell: true,
    );

    // On Windows listen for CTRL-C and use taskkill to kill
    // the spawned process along with any child processes.
    // https://github.com/dart-lang/sdk/issues/22470
    if (io.Platform.isWindows) {
      io.ProcessSignal.sigint.watch().listen((_) {
        // Do not await on sigint
        _killServerProcess().ignore();
        stop();
      });
    }

    process.stderr.listen((_) async {
      if (_isReloading) return;

      final message = utf8.decode(_).trim();
      if (message.isEmpty) return;

      final isDartVMServiceAlreadyInUseError =
          _dartVmServiceAlreadyInUseErrorRegex.hasMatch(message);
      final isSDKWarning = _warningRegex.hasMatch(message);

      if (isDartVMServiceAlreadyInUseError) {
        print(
          '$message '
          'Try specifying a different port using the `--dart-vm-service-port` argument',
        );
      } else if (isSDKWarning) {
        // Do not kill the process if the error is a warning from the SDK.
        print('WARNING');
      } else {
        print('ERROR');
        print(message);
      }

      if ((!isHotReloadingEnabled && !isSDKWarning) ||
          isDartVMServiceAlreadyInUseError) {
        await _killServerProcess();
        await stop(1);
        return;
      }

      // await _target.rollback();
    });

    process.stdout.listen((_) {
      final message = utf8.decode(_).trim();
      final containsHotReload = message.contains('[hotreload]');
      if (message.isNotEmpty) {
        print('stdout:');
        print(message);
      }
      if (containsHotReload) {
        isHotReloadingEnabled = true;
        onHotReloadEnabled?.call();
      }

      // cacheLatestSnapshot();
    });

    process.exitCode.then((code) async {
      if (isCompleted) return;
      await _killServerProcess();
      await stop(1);
    }).ignore();
  }

  Future<void> reload() async {
    if (isCompleted || !isServerRunning || _isReloading) return;
    return _reload(true);
  }

  Future<bool> shouldReload(WatchEvent event) async {
    final zora = await root.getZora();

    final server = path.equals(zora.childFile('server.dart').path, event.path);
    final pubspec =
        path.equals(zora.childFile('pubspec.yaml').path, event.path);

    if (server || pubspec) {
      return true;
    }
    final routesDir = await root.getRoutes();
    if (routesDir != null) {
      if (path.isWithin(routesDir.path, event.path)) {
        return true;
      }
    }

    // path.isWithin(public, event.path);
    return false;
  }
}