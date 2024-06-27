import 'dart:async';
import 'dart:io';

import 'package:hotreloader/hotreloader.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

void hotReload(Future<HttpServer> Function() callback) {
  HotReload(serverFactory: callback).attach().ignore();
}

class HotReload {
  const HotReload({
    required this.serverFactory,
    this.logLevel = Level.OFF,
  });

  final Future<HttpServer> Function() serverFactory;
  final Level logLevel;

  /// Set default messages
  void _onReloaded() {
    final time = _formatTime(DateTime.now());

    stdout.writeln(
      '$time - Reloaded',
    );
  }

  void _onHotReloadAvailable() {
    stdout.writeln('[ZORA] Hot reload enabled');
  }

  void _onHotReloadNotAvailable() {
    stdout.writeln(
      '[hotreload] Hot reload not enabled. Run this app with '
      '--enable-vm-service (or use debug run) '
      'in order to enable hot reload.',
    );
  }

  void _onHotReloadLog(LogRecord log) {
    final time = _formatTime(log.time);
    (log.level < Level.SEVERE ? stdout : stderr).writeln(
      '[hotreload] $time - ${log.message}',
    );
  }

  Future<void> attach() async {
    /// Current server instance
    HttpServer? runningServer;

    /// Configure logging
    hierarchicalLoggingEnabled = true;
    HotReloader.logLevel = logLevel;
    Logger.root.onRecord.listen(_onHotReloadLog);

    /// Function in charge of replacing the running http server
    final obtainNewServer = (FutureOr<HttpServer> Function() create) async {
      /// Will we replace a server?
      var willReplaceServer = runningServer != null;

      /// Shut down existing server
      await runningServer?.close(force: true);

      /// Report about reloading
      if (willReplaceServer) {
        _onReloaded();
      }

      /// Create a new server
      runningServer = await create();
    };

    try {
      /// Register the server reload mechanism to the generic HotReloader.
      /// It will throw an error if reloading is not available.
      await HotReloader.create(
        onBeforeReload: (context) {
          final path = context.event?.path;

          if (path == null) {
            return false;
          }

          final cwd = Directory.current.path;
          if (!p.isWithin(cwd, path)) {
            return true;
          }

          final lib = Directory(p.join(cwd, 'lib')).path;
          final routes = Directory(p.join(cwd, 'routes')).path;
          final public = Directory(p.join(cwd, 'public')).path;
          final server = File(p.join(cwd, '.zora', 'server.dart')).path;

          if (p.isWithin(lib, path)) {
            return true;
          }

          if (server == path) {
            return true;
          }

          if (p.isWithin(routes, path) || p.isWithin(public, path)) {
            // The construct runner will be triggered and will update
            // the server file.
            return false;
          }

          return false;
        },
        onAfterReload: (ctx) {
          obtainNewServer(serverFactory);
        },
        debounceInterval: Duration.zero,
      );

      /// Hot-reload is available
      _onHotReloadAvailable();
    } on StateError catch (e) {
      if (e.message.contains('VM service not available')) {
        /// Hot-reload is not available
        _onHotReloadNotAvailable();
      } else {
        rethrow;
      }
    }

    await obtainNewServer(serverFactory);
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}
