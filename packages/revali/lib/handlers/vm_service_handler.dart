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
import 'package:revali/utils/ticked_progress.dart';
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
    this.getDependencyDirectories,
    this.hotReloadExclude = const [],
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
  final Future<List<String>> Function()? getDependencyDirectories;

  /// Resolved absolute paths to exclude from hot reload. Changes in these
  /// paths (or files/directories within them) will not trigger a reload.
  final List<String> hotReloadExclude;

  bool _isReloading = false;
  bool _pendingReload = false;
  bool _intentionalServerRestart = false;

  /// True after at least one successful reload/restart this session.
  bool _hasReloadedOnce = false;

  /// True after [printStatusBoard] has run for the current child process.
  bool _statusBoardPrinted = false;

  /// Bumped whenever watchers are torn down so stale `asFuture` handlers
  /// do not call [stop] after an intentional cancel/restart.
  int _watcherGeneration = 0;
  bool _enableHotReload = false;
  void Function()? _serveOnReady;

  TickedProgress? __progress;
  TickedProgress? get _progress => __progress;
  set _progress(TickedProgress? value) {
    __progress?.cancel();

    __progress = value;
  }

  io.Process? _serverProcess;
  StreamSubscription<WatchEvent>? _watcherSubscription;
  final List<StreamSubscription<WatchEvent>> _dependencyWatchers = [];
  StreamSubscription<List<int>>? _inputSubscription;
  StreamSubscription<io.ProcessSignal>? _killSubscription;

  // Broadcast stream controller for stdin to allow multiple subscriptions
  StreamController<List<int>>? _stdinController;
  StreamSubscription<List<int>>? _stdinSourceSubscription;

  // Buffers for server output - used when process exits to show diagnostics
  final StringBuffer _stderrBuffer = StringBuffer();
  final StringBuffer _stdoutBuffer = StringBuffer();

  bool get isServerRunning => _serverProcess != null;

  bool get isWatching => _watcherSubscription != null;
  bool get isInputWatching => _inputSubscription != null;

  bool get isCompleted => _exitCodeCompleter.isCompleted;

  final Completer<int> _exitCodeCompleter = Completer<int>();

  Future<int> get exitCode => _exitCodeCompleter.future;

  String _vmServiceUri = '';
  String? _servingAt;
  List<MetaRoute> __lastRoutes = [];

  bool get _isLoud => logger.level == Level.verbose;

  /// Coalesce rapid file-change reloads and restart the child process so
  /// newly added/removed libraries (controllers, apps) take effect.
  ///
  /// Dart VM hot reload cannot reliably load new libraries, so regenerating
  /// `.revali/` alone is not enough when route files appear or disappear.
  Future<void> _reload([String? path]) async {
    if (_isReloading) {
      _pendingReload = true;
      logger.detail('Reload in progress; queued follow-up reload');
      return;
    }

    _isReloading = true;
    try {
      do {
        _pendingReload = false;
        await _performReload();
      } while (_pendingReload && !isCompleted);
    } finally {
      _isReloading = false;
    }
  }

  Future<void> _performReload() async {
    if (!isServerRunning) {
      _progress = TickedProgress('Restarting server', level: logger.level);
      try {
        await serve(enableHotReload: _enableHotReload, onReady: _serveOnReady);
      } finally {
        _progress = null;
      }
      return;
    }

    _progress = TickedProgress('Reloading', level: logger.level);

    if (await checkForErrors()) {
      return;
    }

    // Keep the file watcher alive during regen/restart so edits that land
    // mid-reload are queued via [_pendingReload] instead of being dropped.

    try {
      var server = await codeGenerator(_progress?.update);
      _progress?.update('Restarting server process');
      _hasReloadedOnce = true;
      _serveOnReady = () {
        _printReadyBoard(
          tag: StatusBoardTag.reload,
          routes: server.routes,
        ).ignore();
      };
      try {
        await _restartServerProcess();
      } catch (e) {
        // AI-style delete/create races can leave the first regen briefly
        // inconsistent; one disk-synced retry usually recovers.
        logger.detail('Restart failed ($e); regenerating and retrying once');
        _progress?.update('Recovering');
        server = await codeGenerator(_progress?.update);
        _serveOnReady = () {
          _printReadyBoard(
            tag: StatusBoardTag.reload,
            routes: server.routes,
          ).ignore();
        };
        await _restartServerProcess();
      }

      // Status board is printed once from serve onReady — no second clear.

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
    } catch (e, st) {
      _progress?.fail('Failed to reload');
      logger
        ..err('$e')
        ..detail('$st');
      printInputCommands();
    }
  }

  Future<bool> checkForErrors() async {
    final errors = await this.errors();
    if (errors.isEmpty) {
      return false;
    }

    _wipeOrDivide(label: 'errors');
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
    logger.write('\n');
    printInputCommands();

    return true;
  }

  void lockInput() {
    if (!io.stdin.hasTerminal) return;

    try {
      io.stdin.echoMode = false;
      io.stdin.lineMode = false;
      // hide cursor
      io.stdout.write('\x1B[?25l');
    } on io.StdinException {
      // Pseudo-TTYs / redirected stdin can report hasTerminal=true but still
      // reject mode changes (e.g. errno 19). Continue without raw input.
    }
  }

  void unlockInput() {
    if (!io.stdin.hasTerminal) return;

    try {
      io.stdin.echoMode = true;
      io.stdin.lineMode = true;
      // show cursor
      io.stdout.write('\x1B[?25h');
    } on io.StdinException {
      // See [lockInput].
    }
  }

  void _wipeOrDivide({String label = 'reload'}) {
    if (_isLoud) {
      logger.write('\n${darkGray.wrap('── $label ──')}\n');
    } else {
      print('\x1B[2J\x1B[0;0H');
    }
  }

  /// Waits briefly for the child "Serving at" line (stdout races stderr).
  Future<void> _printReadyBoard({
    required StatusBoardTag tag,
    List<MetaRoute>? routes,
  }) async {
    for (var i = 0; i < 40 && _servingAt == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    printStatusBoard(tag: tag, routes: routes);
  }

  /// Stable status board reprinted after clear, reload, and `c`.
  void printStatusBoard({
    StatusBoardTag? tag,
    List<MetaRoute>? routes,
    bool clear = true,
  }) {
    final resolvedTag =
        tag ??
        (_hasReloadedOnce ? StatusBoardTag.reload : StatusBoardTag.ready);

    if (clear) {
      _wipeOrDivide(
        label: resolvedTag == StatusBoardTag.reload ? 'reload' : 'ready',
      );
    }

    var header = '${yellow.wrap(_formatTime(DateTime.now()))}';
    if (canHotReload) {
      final label = switch (resolvedTag) {
        StatusBoardTag.ready => '[READY]',
        StatusBoardTag.reload => '[RELOAD]',
      };
      header += ' ${darkGray.wrap(label)}';
    }
    logger.info(header);

    if (_servingAt case final serving?) {
      logger.success(serving);
    }

    if (_vmServiceUri.isNotEmpty) {
      for (final line in _vmServiceUri.split('\n')) {
        if (line.isEmpty) continue;
        logger.info(darkGray.wrap(line));
      }
    }

    if (_enableHotReload || canHotReload) {
      printInputCommands();
    }

    printParsedRoutes(routes);
    _statusBoardPrinted = true;
  }

  void printInputCommands() {
    final buffer = StringBuffer()
      ..write(darkGray.wrap('Press: '))
      ..write(yellow.wrap('r'))
      ..write(darkGray.wrap(' reload, '))
      ..write(yellow.wrap('c'))
      ..write(darkGray.wrap(' clear, '))
      ..write(yellow.wrap('q'))
      ..write(darkGray.wrap(' quit'));

    if (!io.stdin.hasTerminal) {
      buffer
        ..write(darkGray.wrap(' — or write to '))
        ..write(yellow.wrap(_devCommandFileName));
    }

    logger.write('$buffer\n');
  }

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
    final process = _serverProcess;
    if (process == null) {
      return;
    }
    // Clear before kill so exit handlers can treat this as intentional when
    // [_intentionalServerRestart] is set.
    _serverProcess = null;

    if (io.Platform.isWindows) {
      await io.Process.run('taskkill', ['/F', '/T', '/PID', '${process.pid}']);
      return;
    }

    process.kill();
    try {
      await process.exitCode.timeout(const Duration(seconds: 3));
    } on TimeoutException {
      logger.detail('Server did not exit after SIGTERM; sending SIGKILL');
      process.kill(io.ProcessSignal.sigkill);
      try {
        await process.exitCode.timeout(const Duration(seconds: 2));
      } on TimeoutException {
        logger.warn('Server process did not exit after SIGKILL');
      }
    }
  }

  Future<void> _restartServerProcess() async {
    final artifact = io.File(serverFile);
    if (!artifact.existsSync()) {
      throw StateError(
        'Cannot restart: generated server is missing at $serverFile',
      );
    }

    _intentionalServerRestart = true;
    try {
      await _killServerProcess();
      // Allow the OS to release the listen port before rebinding.
      await Future<void>.delayed(const Duration(milliseconds: 350));

      var attempts = 0;
      while (true) {
        attempts++;
        if (!artifact.existsSync()) {
          throw StateError(
            'Generated server disappeared at $serverFile during restart',
          );
        }

        final ready = Completer<void>();
        var processExitedEarly = false;

        await serve(
          enableHotReload: _enableHotReload,
          onReady: () {
            _serveOnReady?.call();
            if (!ready.isCompleted) {
              ready.complete();
            }
          },
        );

        final started = _serverProcess;
        if (started != null) {
          started.exitCode.then((code) {
            if (!ready.isCompleted) {
              processExitedEarly = true;
              ready.completeError(
                StateError('Server exited during startup (code $code)'),
              );
            }
          }).ignore();
        }

        try {
          await ready.future.timeout(const Duration(seconds: 45));
          return;
        } catch (e) {
          logger.detail('Server restart attempt $attempts failed: $e');
          await _killServerProcess();
          if (attempts >= 3) {
            logger.err(
              'Failed to restart server process after $attempts attempts',
            );
            rethrow;
          }
          // Back off harder when the port is still held.
          await Future<void>.delayed(Duration(milliseconds: 500 * attempts));
          if (processExitedEarly) {
            continue;
          }
        }
      }
    } finally {
      _intentionalServerRestart = false;
    }
  }

  // Internal method to cancel the watcher subscription.
  // Make sure to call `stop` after calling this method to also stop the
  // server process.
  Future<void> _cancelWatcherSubscription() async {
    if (!isWatching && _dependencyWatchers.isEmpty) {
      return;
    }

    _watcherGeneration++;
    logger.detail('Cancelling file watchers');
    await _watcherSubscription?.cancel();
    _watcherSubscription = null;

    for (final watcher in _dependencyWatchers) {
      await watcher.cancel();
    }
    _dependencyWatchers.clear();
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

    final progress = TickedProgress(
      'Generating server code',
      level: logger.level,
    );

    final server = await codeGenerator(progress.update);

    progress.complete('Generated server code');

    _enableHotReload = enableHotReload;
    _serveOnReady = () {
      _printReadyBoard(
        tag: _hasReloadedOnce ? StatusBoardTag.reload : StatusBoardTag.ready,
        routes: server.routes,
      ).ignore();
    };
    await serve(enableHotReload: enableHotReload, onReady: _serveOnReady);

    if (enableHotReload) {
      watchForInput();
      await watchForFileChanges();
    }
  }

  void watchForInput() {
    try {
      // Create broadcast stream controller once from stdin. Headless / AI
      // launches often get an immediately-closed stdin — do not poison the
      // controller permanently when that happens.
      if (_stdinController == null || _stdinController!.isClosed) {
        _stdinController = StreamController<List<int>>.broadcast();
        _stdinSourceSubscription?.cancel();
        _stdinSourceSubscription = io.stdin.listen(
          (event) => _stdinController?.add(event),
          onDone: () {
            logger.detail('stdin closed; hotkeys unavailable until restart');
            _stdinSourceSubscription = null;
          },
          onError: (Object e) {
            logger.detail('stdin error: $e');
          },
          cancelOnError: false,
        );
      }

      // Cancel existing subscription if any
      _inputSubscription?.cancel();

      // Re-lock input to ensure single-key mode is maintained
      lockInput();

      _inputSubscription = _stdinController?.stream.listen((event) {
        _handleDevCommand(utf8.decode(event));
      });
    } catch (e) {
      logger
        ..detail('stdin not available (headless/AI mode): $e')
        ..detail('Use .revali_cmd file for r/c/q commands instead');
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
      // Killing the child during hot-reload restart must not tear down the
      // parent CLI (signals can surface here when the child shares a group).
      if (_intentionalServerRestart || _isReloading) {
        logger.detail('Ignoring $event during reload/restart');
        return;
      }

      logger.detail('Received process signal: $event');
      if (attemptsToKill > 0) {
        logger.detail('Second signal received, forcing exit');
        exit(1);
      } else if (attemptsToKill == 0) {
        logger.detail('Gracefully shutting down (user requested)');
        stop().ignore();
      }

      attemptsToKill++;
    });
  }

  /// Handles interactive keys and headless `.revali_cmd` file commands.
  void _handleDevCommand(String raw) {
    final key = raw.toLowerCase().trim();
    if (key.isEmpty) return;

    logger.detail('dev command: $key');

    final _ = switch (key) {
      'r' || 'reload' => _reload().ignore(),
      'c' || 'clear' => printStatusBoard(),
      'q' || 'quit' || 'exit' => stop().ignore(),
      _ => null,
    };
  }

  Future<void> _handleDevCommandFile(String path) async {
    try {
      final file = io.File(path);
      if (!file.existsSync()) return;
      final raw = await file.readAsString();
      // Truncate so the next write is a fresh command.
      await file.writeAsString('');
      for (final line in raw.split(RegExp(r'[\r\n]+'))) {
        _handleDevCommand(line);
      }
    } catch (e) {
      logger.detail('Failed to read .revali_cmd: $e');
    }
  }

  static const _devCommandFileName = '.revali_cmd';

  bool _isDevCommandPath(String path) =>
      p.basename(path) == _devCommandFileName;

  bool _isPathExcluded(String path) {
    final normalizedPath = p.normalize(p.absolute(path));
    final basename = p.basename(normalizedPath);
    if (basename == '.revali.staging' ||
        basename.startsWith('.revali.staging.')) {
      return true;
    }

    if (hotReloadExclude.isEmpty) return false;
    for (final excluded in hotReloadExclude) {
      final normalizedExcluded = p.normalize(p.absolute(excluded));
      if (normalizedPath == normalizedExcluded) return true;
      if (p.isWithin(normalizedExcluded, normalizedPath)) return true;
    }
    return false;
  }

  Future<void> watchForFileChanges() async {
    logger.detail('Watching ${root.path} for changes');

    if (_watcherSubscription != null) {
      return;
    }

    final generation = _watcherGeneration;

    // Watch the root directory
    _watcherSubscription = DirectoryWatcher(root.path).events
        .asyncMap((event) async {
          final WatchEvent(:type, :path) = event;

          // Handle immediately (not debounced) so a trailing `r` command
          // cannot swallow a preceding route-file change in the debounce
          // window.
          if (_isDevCommandPath(path)) {
            if (type != ChangeType.REMOVE) {
              await _handleDevCommandFile(path);
            }
            return null;
          }

          if (type == ChangeType.REMOVE) {
            await onFileRemove(path);
          } else {
            await onFilesChange([path]);
          }

          return event;
        })
        .where((event) => event != null)
        .cast<WatchEvent>()
        .debounce(const Duration(milliseconds: 300))
        .listen((event) {
          final WatchEvent(:type, :path) = event;

          if (_isPathExcluded(path)) {
            logger.detail('Ignoring change in excluded path: $path');
            return;
          }
          _reload(path);
        });

    _watcherSubscription
        ?.asFuture<void>()
        .then((_) async {
          if (generation != _watcherGeneration || isCompleted) {
            return;
          }
          logger.detail('Root directory watcher closed normally');
          await _cancelWatcherSubscription();
          await stop();
        })
        .catchError((Object e, StackTrace st) async {
          if (generation != _watcherGeneration || isCompleted) {
            return;
          }
          await _handleWatcherError(e, st, watcherType: 'root directory');
        })
        .ignore();

    // Watch dependency directories if available
    if (getDependencyDirectories case final getDependencyDirectories?
        when _dependencyWatchers.isEmpty) {
      final dependencyDirs = await getDependencyDirectories();
      for (final dir in dependencyDirs) {
        logger.detail('Watching dependency directory: $dir');
        final watcher = DirectoryWatcher(dir).events
            .asyncMap((event) async {
              final WatchEvent(:type, :path) = event;

              // Only watch for Dart files in dependency directories
              if (p.extension(path) == '.dart') {
                if (type == ChangeType.REMOVE) {
                  await onFileRemove(path);
                } else {
                  await onFilesChange([path]);
                }
              }

              return event;
            })
            .debounce(const Duration(milliseconds: 300))
            .listen((event) {
              final WatchEvent(:type, :path) = event;

              if (p.extension(path) == '.dart') {
                if (_isPathExcluded(path)) {
                  logger.detail('Ignoring change in excluded path: $path');
                  return;
                }
                _reload(path);
              }
            });

        _dependencyWatchers.add(watcher);

        watcher
            .asFuture<void>()
            .then((_) async {
              if (generation != _watcherGeneration || isCompleted) {
                return;
              }
              logger.detail('Dependency watcher closed: $dir');
              await _cancelWatcherSubscription();
              await stop();
            })
            .catchError((Object e, StackTrace st) async {
              if (generation != _watcherGeneration || isCompleted) {
                return;
              }
              await _handleWatcherError(e, st, watcherType: 'dependency $dir');
            })
            .ignore();
      }
    }
  }

  /// Handles watcher stream errors. Recovers from transient
  /// [FileSystemException]s (e.g., "Folder expected" when an ephemeral
  /// directory is deleted) by restarting the watchers instead of stopping
  /// the server.
  Future<void> _handleWatcherError(
    Object e,
    StackTrace st, {
    required String watcherType,
  }) async {
    await _cancelWatcherSubscription();

    final isRecoverable =
        (e is io.PathNotFoundException) ||
        (e is io.FileSystemException &&
            (e.message.contains('Folder expected') ||
                e.message.contains('No such file')));

    if (isRecoverable && !isCompleted) {
      logger
        ..detail('File watcher recovered ($watcherType): $e')
        ..detail('Restarting watchers');
      await watchForFileChanges();
    } else {
      logger
        ..err('File watcher error ($watcherType): $e')
        ..detail('Stack trace: $st');
      await stop(1);
    }
  }

  Future<void> stop([int exitCode = 0]) async {
    unlockInput();

    if (isCompleted) {
      logger.detail('Stop called but already completed');
      return;
    }

    logger.detail('Stopping dev server... (exitCode: $exitCode)');
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
    // Status board is printed once when the server is ready — avoid an empty
    // wipe here so we do not clear twice on reload.
    logger.detail('Starting server');
    _vmServiceUri = '';
    _servingAt = null;
    _statusBoardPrinted = false;

    var hasStartedServer = false;

    // Avoid a shell intermediary so SIGTERM targets only the server VM
    // and does not bounce into the parent CLI's signal watchers.
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
    ]);

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

    _stderrBuffer.clear();
    _stdoutBuffer.clear();
    process.stderr.listen((err) async {
      final message = utf8.decode(err).trim();
      _stderrBuffer.writeln(message);
      if (message.isEmpty) return;

      HotReloadData? data;

      try {
        data = HotReloadData.fromJson(
          jsonDecode(message) as Map<String, dynamic>,
        );
      } catch (_) {
        logger.err(message);
        return;
      }

      switch (data) {
        case HotReloadFilesChanged(:final files):
          // Parent file watchers restart the process; avoid a redundant wipe
          // here that flickers the status board before that restart.
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
          final progressMessage = _hasReloadedOnce
              ? 'Reloaded'
              : 'Server started';
          _progress?.complete(progressMessage);
          _progress = null;
          onReady?.call();
          return;

        case HotReloadData(type: HotReloadType.hotReloadEnabled):
          return;
      }
    });

    process.stdout.listen((out) async {
      final message = utf8.decode(out).trim();
      _stdoutBuffer.writeln(message);
      if (message.isEmpty) {
        return;
      }

      if (message.contains('Dart VM service')) {
        _vmServiceUri = message;
      } else if (message.contains('Dart DevTools debugger')) {
        _vmServiceUri = _vmServiceUri.isEmpty
            ? message
            : '$_vmServiceUri\n$message';
        _progress = TickedProgress('Starting server', level: logger.level);
      } else if (message.startsWith('Serving at ')) {
        _servingAt = message;
        // Board already printed without a URL (stdout raced past the wait).
        if (_statusBoardPrinted) {
          logger.success(message);
        }
      } else {
        logger.write('$message\n');
      }
    });

    process.exitCode.then((code) async {
      await _handleServerProcessExit(code);
    }).ignore();
  }

  Future<void> _handleServerProcessExit(int code) async {
    if (isCompleted) return;

    // Intentional kill+respawn during reload — do not treat as a crash.
    if (_intentionalServerRestart) {
      logger.detail('Server process exited during intentional restart ($code)');
      return;
    }

    _serverProcess = null;

    // Log diagnostics before any stop() — otherwise the process may exit
    // before these messages are flushed when exitCode completer completes.
    logger
      ..err('')
      ..err('Server process terminated unexpectedly with exit code: $code');
    final stderr = _stderrBuffer.toString().trim();
    if (stderr.isNotEmpty) {
      logger.err('Server stderr:');
      for (final line in stderr.split('\n')) {
        logger.err('  $line');
      }
    }
    final stdout = _stdoutBuffer.toString().trim();
    if (stdout.isNotEmpty) {
      logger.err('Server stdout (last ${stdout.split("\n").length} lines):');
      final lines = stdout.split('\n');
      for (final line
          in lines.length > 20 ? lines.sublist(lines.length - 20) : lines) {
        logger.err('  $line');
      }
    }

    if (canHotReload) {
      logger
        ..warn(
          'Dev server is still running. Fix the error above, then press '
          '${yellow.wrap('r')} to restart the server process.',
        )
        ..err('');
      printInputCommands();
      return;
    }

    logger
      ..err('Check for uncaught exceptions or early exit in your server code.')
      ..err('');
    await stop(1);
  }

  String _formatTime(DateTime time) {
    final String hour;
    final String ampm;
    if (time.hour == 0) {
      hour = '12';
      ampm = 'AM';
    } else if (time.hour == 12) {
      hour = '12';
      ampm = 'PM';
    } else if (time.hour > 12) {
      hour = '${time.hour - 12}';
      ampm = 'PM';
    } else {
      hour = '${time.hour}';
      ampm = 'AM';
    }

    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');

    return '$hour:$minute:$second $ampm';
  }
}

enum StatusBoardTag { ready, reload }

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
