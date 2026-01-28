// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:io';

import 'package:analyzer/error/error.dart';
import 'package:async/async.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:revali/dart_define/dart_define.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:watcher/watcher.dart';

class VMServiceHandler {
  VMServiceHandler({
    required this.root,
    required this.serverFile,
    required this.codeGenerator,
    required this.logger,
    required this.canHotReload,
    required this.serverArgs,
    required this.mode,
    required this.onFilesChange,
    required this.onFileRemove,
    required this.errors,
    this.dartDefine = const DartDefine(),
    this.dartVmServicePort = '0',
  }) : assert(
         dartVmServicePort.isNotEmpty,
         'dartVmServicePort cannot be empty',
       );

  final Logger logger;
  final String dartVmServicePort;
  final Directory root;
  final String serverFile;
  final Future<MetaServer> Function([void Function(String)?]) codeGenerator;
  final bool canHotReload;
  final DartDefine dartDefine;
  final List<String> serverArgs;
  final Mode mode;
  final Future<void> Function(List<String>) onFilesChange;
  final Future<void> Function(String) onFileRemove;
  final Future<List<(String, List<AnalysisError>)>> Function() errors;

  bool _isReloading = false;

  Progress? __progress;
  Progress? get _progress => __progress;
  set _progress(Progress? value) {
    __progress?.cancel();

    __progress = value;
  }

  io.Process? _serverProcess;
  StreamSubscription<WatchEvent>? _watcherSubscription;
  StreamSubscription<List<int>>? _inputSubscription;
  StreamSubscription<io.ProcessSignal>? _killSubscription;

  // Broadcast stream controller for stdin to allow multiple subscriptions
  StreamController<List<int>>? _stdinController;
  StreamSubscription<List<int>>? _stdinSourceSubscription;

  bool get isServerRunning => _serverProcess != null;

  bool get isWatching => _watcherSubscription != null;
  bool get isInputWatching => _inputSubscription != null;

  bool get isCompleted => _exitCodeCompleter.isCompleted;

  final Completer<int> _exitCodeCompleter = Completer<int>();

  Future<int> get exitCode => _exitCodeCompleter.future;

  String _vmServiceUri = '';

  Future<void> _reload([String? path]) async {
    if (_isReloading) {
      logger.detail('Still reloading, skipping');
      return;
    }

    _isReloading = true;

    _progress = logger.progress('Reloading');

    if (await checkForErrors()) {
      return;
    }

    await _cancelWatcherSubscription();

    final server = await codeGenerator(_progress?.update);
    _progress?.complete('Reloaded');
    clearConsole();
    printVmServiceUri();
    printParsedRoutes(server.routes);

    logger.flush((message) {
      if (message == null) return;
      final lines = message.split('\n');
      final updatedMessage = [for (final line in lines) '[FLUSHED]: $line'];
      logger.detail('[FLUSHED]: $updatedMessage');

      if (!message.contains(RegExp('error|fail', caseSensitive: false))) {
        return;
      }

      logger.err(message);
    });

    watchForFileChanges();
    watchForInput();
    _isReloading = false;
  }

  Future<bool> checkForErrors() async {
    final errors = await this.errors();
    if (errors.isEmpty) {
      return false;
    }

    _isReloading = false;
    clearConsole();
    _progress?.fail('Failed to reload');
    logger
      ..write('\n')
      ..write('Found ${errors.length} errors\n');
    for (final (path, errors) in errors) {
      logger.write('\n${yellow.wrap(path)}\n');
      for (final error in errors) {
        logger.write('${red.wrap('  -')} ${error.message}\n');
      }
    }

    return true;
  }

  void lockInput() {
    if (!io.stdin.hasTerminal) return;

    io.stdin.echoMode = false;
    io.stdin.lineMode = false;
    // hide cursor
    io.stdout.write('\x1B[?25l');
  }

  void unlockInput() {
    if (!io.stdin.hasTerminal) return;

    io.stdin.echoMode = true;
    io.stdin.lineMode = true;
    // show cursor
    io.stdout.write('\x1B[?25h');
  }

  void clearConsole() {
    print('\x1B[2J\x1B[0;0H');
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
    printInputCommands();
  }

  void printInputCommands() {
    if (!io.stdin.hasTerminal) {
      return;
    }

    final buffer = StringBuffer()
      ..write(darkGray.wrap('Press: '))
      ..write(yellow.wrap('r'))
      ..write(darkGray.wrap(' to reload, '))
      ..write(yellow.wrap('c'))
      ..write(darkGray.wrap(' to clear, '))
      ..write(yellow.wrap('q'))
      ..write(darkGray.wrap(' to quit'));

    logger.write('$buffer\n');
  }

  List<MetaRoute> __lastRoutes = [];
  void printParsedRoutes(List<MetaRoute>? routes0) {
    var routes = routes0;
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
        logger.detail('method: ${method.name}');

        final fullPath = p.join(root, method.path ?? '');
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
    if (!isServerRunning) {
      return;
    }

    logger.detail('Killing server process');
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

    logger.detail('Cancelling file watcher');
    await _watcherSubscription?.cancel();
    _watcherSubscription = null;
  }

  Future<void> _cancelInputSubscription() async {
    if (!isInputWatching) {
      return;
    }

    logger.detail('Cancelling input watcher');
    await _inputSubscription?.cancel();
    _inputSubscription = null;
  }

  Future<void> _closeBroadcastStream() async {
    // Close the stream controller and cancel the source subscription
    logger.detail('Closing stdin broadcast stream');
    await _stdinSourceSubscription?.cancel();
    await _stdinController?.close();
    _stdinSourceSubscription = null;
    _stdinController = null;
  }

  Future<void> start({required bool enableHotReload}) async {
    lockInput();

    logger.detail('Starting dev server');
    if (isCompleted) {
      throw Exception('Cannot start a dev server after it has been stopped.');
    }

    if (isServerRunning) {
      throw Exception('Cannot start a dev server while already running.');
    }

    final progress = logger.progress('Generating server code');

    final server = await codeGenerator(progress.update);

    progress.complete('Generated server code');

    await serve(
      enableHotReload: enableHotReload,
      onReady: () => printParsedRoutes(server.routes),
    );

    if (enableHotReload) {
      watchForInput();
      watchForFileChanges();
    }
  }

  void _cleanConsole() {
    print('\x1B[2J\x1B[0;0H');
    printVmServiceUri();
  }

  void watchForInput() {
    try {
      // Create broadcast stream controller once from stdin
      if (_stdinController == null) {
        _stdinController = StreamController<List<int>>.broadcast();
        _stdinSourceSubscription = io.stdin.listen(
          (event) => _stdinController?.add(event),
          onDone: () => _stdinController?.close(),
        );
      }

      // Cancel existing subscription if any
      _inputSubscription?.cancel();

      // Re-lock input to ensure single-key mode is maintained
      lockInput();

      _inputSubscription = _stdinController?.stream.listen((event) {
        var key = utf8.decode(event).toLowerCase().trim();
        if (key.isEmpty && event.length == 1) {
          key = '${event[0]}';
        }
        logger.detail('key: $key');

        final _ = switch (key) {
          'r' || 'R' => _reload().ignore(),
          'c' || 'C' => _cleanConsole(),
          'q' || 'Q' => stop().ignore(),
          _ => null,
        };
      });
    } catch (e) {
      logger
        ..err('Failed to connect to stdin, cannot watch for input')
        ..detail('$e');
      return;
    }

    logger.detail('Watching for kill signal');

    var attemptsToKill = 0;
    final stream = Platform.isWindows
        ? ProcessSignal.sigint.watch()
        : StreamGroup.merge([
            ProcessSignal.sigterm.watch(),
            ProcessSignal.sigint.watch(),
          ]);

    _killSubscription ??= stream.listen((event) {
      logger.detail('Received SIGINT');
      if (attemptsToKill > 0) {
        exit(1);
      } else if (attemptsToKill == 0) {
        stop().ignore();
      }

      attemptsToKill++;
    });
  }

  void watchForFileChanges() {
    logger.detail('Watching ${root.path} for changes');

    if (_watcherSubscription != null) {
      return;
    }

    _watcherSubscription = DirectoryWatcher(root.path).events
        .asyncMap((event) async {
          final WatchEvent(:type, :path) = event;

          if (type == ChangeType.REMOVE) {
            await onFileRemove(path);
          } else {
            await onFilesChange([path]);
          }

          return event;
        })
        .debounce(Duration.zero)
        .listen((event) {
          final WatchEvent(:type, :path) = event;

          _reload(path);
        });

    _watcherSubscription
        ?.asFuture<void>()
        .then((_) async {
          await _cancelWatcherSubscription();
          await stop();
        })
        .catchError((_) async {
          await _cancelWatcherSubscription();
          await stop(1);
        })
        .ignore();
  }

  Future<void> stop([int exitCode = 0]) async {
    unlockInput();

    if (isCompleted) {
      logger.detail('Stop called but already completed');
      return;
    }

    logger.detail('Stopping dev server...');
    _progress?.cancel();

    await _cancelWatcherSubscription();
    await _killServerProcess();
    await _cancelInputSubscription();
    await _killSubscription?.cancel();
    await _closeBroadcastStream();

    // Complete the exit code completer to signal the process can exit
    if (!_exitCodeCompleter.isCompleted) {
      logger.detail('Completing exit code completer with code: $exitCode');
      _exitCodeCompleter.complete(exitCode);
    } else {
      logger.detail('Exit code completer was already completed');
    }
  }

  Future<void> serve({
    required bool enableHotReload,
    void Function()? onReady,
  }) async {
    clearConsole();
    logger.detail('Starting server');

    var hasStartedServer = false;

    final process = _serverProcess = await io.Process.start('dart', [
      if (enableHotReload) ...[
        '--enable-vm-service=$dartVmServicePort',
        '--enable-asserts',
      ],
      if (dartDefine.isNotEmpty) ...[
        for (final entry in dartDefine.entries) '-D$entry',
      ],
      '-D__DEBUG__=${mode.isDebug}',
      '-D__PROFILE__=${mode.isProfile}',
      '-D__RELEASE__=${mode.isRelease}',
      serverFile,
      ...serverArgs,
    ], runInShell: true);

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

    process.stderr.listen((err) async {
      final message = utf8.decode(err).trim();
      if (message.isEmpty) return;

      HotReloadData? data;

      try {
        data = HotReloadData.fromJson(
          jsonDecode(message) as Map<String, dynamic>,
        );
      } catch (e) {
        // ignore
      }

      switch (data) {
        case null:
          break;
        case HotReloadFilesChanged(:final files):
          clearConsole();
          printVmServiceUri();
          printParsedRoutes(null);

          await onFilesChange(files);
          logger.detail('Files changed:');
          for (final file in files) {
            logger.detail('  - $file');
          }

          if (await checkForErrors()) {
            return;
          }

        case HotReloadData(type: HotReloadType.revaliStarted):
          if (hasStartedServer) {
            return;
          }

          hasStartedServer = true;
          _progress?.complete();
          onReady?.call();
          return;

        case HotReloadData(type: HotReloadType.hotReloadEnabled):
          return;
      }
    });

    process.stdout.listen((out) async {
      final message = utf8.decode(out).trim();
      if (message.isEmpty) {
        return;
      }

      if (message.contains('Dart VM service')) {
        _vmServiceUri = message;
        logger.success(message);
      } else if (message.contains('Dart DevTools debugger')) {
        _vmServiceUri += '\n$message';
        logger.success(message);
        printInputCommands();
        logger.write('\n');
        _progress = logger.progress('Starting server');
      } else {
        logger.write('$message\n');
      }
    });
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
    final padded = switch (this) {
      MetaMethod(:final method, isSse: true) => '$method (SSE)',
      MetaMethod(:final method) => method,
    }.padRight(10);

    switch (method) {
      case 'GET' when isSse:
        return yellow.wrap(padded);
      case 'GET':
        return lightYellow.wrap(padded);
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
