import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:revali/utils/extensions/directory_extensions.dart';
import 'package:revali_construct/hot_reload/hot_reload.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:watcher/watcher.dart';

final _warningRegex = RegExp(r'^.*:\d+:\d+: Warning: .*', multiLine: true);

final _dartVmServiceAlreadyInUseErrorRegex = RegExp(
  '^Could not start the VM service: localhost:.* is already in use.',
  multiLine: true,
);

class VMServiceHandler {
  VMServiceHandler({
    required this.root,
    required this.serverFile,
    required this.codeGenerator,
    required this.logger,
    required this.canHotReload,
    this.dartVmServicePort = '8080',
  }) : assert(
          dartVmServicePort.isNotEmpty,
          'dartVmServicePort cannot be empty',
        );

  final Logger logger;
  final String dartVmServicePort;
  final Directory root;
  final String serverFile;
  final Future<MetaServer?> Function() codeGenerator;
  final bool canHotReload;

  bool _isReloading = false;

  io.Process? _serverProcess;
  StreamSubscription<WatchEvent>? _watcherSubscription;

  bool get isServerRunning => _serverProcess != null;

  bool get isWatching => _watcherSubscription != null;

  bool get isCompleted => _exitCodeCompleter.isCompleted;

  final Completer<int> _exitCodeCompleter = Completer<int>();

  Future<int> get exitCode => _exitCodeCompleter.future;

  String _vmServiceUri = '';

  Future<void> _reload() async {
    if (_isReloading) {
      logger.detail('Still reloading, skipping...');
      return;
    }

    _isReloading = true;
    _cancelWatcherSubscription();
    final progress = logger.progress('Reloading...');

    final server = await codeGenerator();
    if (server == null) {
      clearConsole();
      progress.fail('Failed to reload');
      logger
        ..write('\n')
        ..flush();
      watchForChanges();
      _isReloading = false;
      return;
    }

    progress.complete('Reloaded');
    clearConsole();
    printVmServiceUri();
    printParsedRoutes(server.routes);
    watchForChanges();
    _isReloading = false;
  }

  void clearConsole() {
    print("\x1B[2J\x1B[0;0H");
    var message = '${yellow.wrap(_formatTime(DateTime.now()))}';
    if (canHotReload) {
      message += ' ${darkGray.wrap('[RELOAD]')}';
    }
    logger.info(message);
  }

  void printVmServiceUri() {
    if (_vmServiceUri.isEmpty) {
      return;
    }

    logger.success(_vmServiceUri);
  }

  List<MetaRoute> __lastRoutes = [];
  void printParsedRoutes(List<MetaRoute>? routes) {
    if (routes == null) {
      if (__lastRoutes.isEmpty) {
        return;
      }

      routes = __lastRoutes;
    }

    __lastRoutes = routes;

    logger.write('\n');
    for (final route in routes) {
      final root = '/${route.path}';
      logger.info(darkGray.wrap(root));
      for (final method in route.methods) {
        logger.detail('method: ${method.path}');

        final fullPath = path.join(root, (method.path ?? ''));
        logger.info(
          '${method.wrappedMethod}'
          '${darkGray.wrap('-> ')}'
          '$fullPath',
        );
      }
    }
    logger.write('\n');
  }

  // Internal method to kill the server process.
  // Make sure to call `stop` after calling this method to also stop the
  // watcher.
  Future<void> _killServerProcess() async {
    logger.detail('Killing server process...');
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

  Future<void> start({
    required bool enableHotReload,
  }) async {
    logger.detail('Starting dev server...');
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

    final server = await codeGenerator();
    if (server == null) {
      logger
        ..err('Failed to start up server')
        ..write('\n')
        ..flush();
      await stop(1);
      return;
    }

    await serve(
      enableHotReload: enableHotReload,
      onReady: () => printParsedRoutes(server.routes),
    );

    if (enableHotReload) {
      watchForChanges();
    }
  }

  void watchForChanges() {
    logger.detail('Watching ${root.path} for changes...');
    final watcher = DirectoryWatcher(root.path);
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

    logger.detail('Stopping dev server...');

    if (isWatching) {
      await _cancelWatcherSubscription();
    }
    if (isServerRunning) {
      await _killServerProcess();
    }

    _exitCodeCompleter.complete(exitCode);
  }

  Future<void> serve({
    required bool enableHotReload,
    void Function()? onReady,
  }) async {
    var isHotReloadingEnabled = false;
    clearConsole();
    logger.detail('Starting server...');

    var _hasStartedServer = false;

    final process = _serverProcess = await io.Process.start(
      'dart',
      [
        if (enableHotReload) ...[
          '--enable-vm-service=$dartVmServicePort',
          '--enable-asserts',
        ],
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

    Progress? progress;
    process.stderr.listen((_) async {
      progress?.fail('Failed to start server');

      if (_isReloading) {
        return;
      }

      final message = utf8.decode(_).trim();
      if (message.isEmpty) return;

      if (message.contains(HotReload.nonRevaliReload)) {
        clearConsole();
        printVmServiceUri();
        printParsedRoutes(null);
        return;
      }

      final isDartVMServiceAlreadyInUseError =
          _dartVmServiceAlreadyInUseErrorRegex.hasMatch(message);
      final isSDKWarning = _warningRegex.hasMatch(message);

      if (isDartVMServiceAlreadyInUseError) {
        logger.err(
          '$message '
          'Try specifying a different port using the `--dart-vm-service-port` argument',
        );
      } else if (isSDKWarning) {
        // Do not kill the process if the error is a warning from the SDK.
        logger.warn(message);
      } else {
        logger.err(message);
      }

      if ((!isHotReloadingEnabled && !isSDKWarning) ||
          isDartVMServiceAlreadyInUseError) {
        await _killServerProcess();
        await stop(1);
        return;
      }
    });

    process.stdout.listen((_) {
      final message = utf8.decode(_).trim();
      if (message.isEmpty) {
        return;
      }

      if (message.contains(HotReload.reloaded)) {
        logger.write('');
        return;
      }

      if (message.contains(HotReload.nonRevaliReload)) {
        clearConsole();
        printVmServiceUri();
        return;
      }

      if (message.contains(HotReload.revaliStarted) && !_hasStartedServer) {
        _hasStartedServer = true;
        progress?.complete();
        onReady?.call();
        return;
      }

      if (message.contains(HotReload.hotReloadEnabled)) {
        isHotReloadingEnabled = true;
        return;
      }

      if (message.contains('Dart VM service')) {
        _vmServiceUri = message;
        logger.success(message);
      } else if (message.contains('Dart DevTools debugger')) {
        _vmServiceUri += '\n$message';
        logger
          ..success(message)
          ..write('\n');
        progress = logger.progress('Starting server...');
      } else {
        logger.write('$message\n');
      }
    });

    process.exitCode.then((code) async {
      if (isCompleted) return;
      await _killServerProcess();
      await stop(1);
    }).ignore();
  }

  Future<bool> shouldReload(WatchEvent event) async {
    logger.detail('File ${event.type}: ${event.path}');

    if (_isReloading) {
      logger.detail('Skipping reload, hot reload in progress...');
      return false;
    }

    final revali = await root.getRevali();

    final server =
        path.equals(revali.childFile(ServerFile.fileName).path, event.path);
    final pubspec =
        path.equals(revali.childFile('pubspec.yaml').path, event.path);

    if (server || pubspec) {
      return true;
    }
    final routesDir = await root.getRoutes();
    if (routesDir != null) {
      if (path.isWithin(routesDir.path, event.path)) {
        return true;
      }
    }

    final public = await root.getPublic();

    if (path.isWithin(public.path, event.path)) {
      return true;
    }

    logger.detail('No construct reload needed');
    return false;
  }

  String _formatTime(DateTime time) {
    String hour;
    //am/pm
    String ampm;
    if (time.hour case _ when time.hour > 12) {
      hour = (time.hour - 12).toString();
      ampm = 'PM';
    } else if (time.hour case _ when time.hour == 0) {
      hour = '12';
      ampm = 'AM';
    } else {
      hour = time.hour.toString();
      ampm = 'AM';
    }

    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');

    return '$hour:$minute:$second $ampm';
  }
}

extension _MethodX on MetaMethod {
  /// Wraps the method with an associated color
  String? get wrappedMethod {
    final padded = method.padRight(6);
    switch (method) {
      case 'GET':
        return yellow.wrap(padded);
      case 'POST':
        return green.wrap(padded);
      case 'PUT':
        return blue.wrap(padded);
      case 'DELETE':
        return red.wrap(padded);
      case 'PATCH':
        return magenta.wrap(padded);
      case 'HEAD':
        return cyan.wrap(padded);
      case 'CONNECT':
        return lightGreen.wrap(padded);
      case 'OPTIONS':
        return lightRed.wrap(padded);
      case 'TRACE':
        return lightBlue.wrap(padded);
      case 'WS':
        return lightMagenta.wrap(padded);
      default:
        return padded;
    }
  }
}
