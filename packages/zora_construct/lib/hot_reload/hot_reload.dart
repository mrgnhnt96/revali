import 'dart:async';
import 'dart:io';

import 'package:hotreloader/hotreloader.dart';
import 'package:logging/logging.dart' as logging;

void hotReload(Future<HttpServer> Function() callback) {
  HotReload(serverFactory: callback).attach().ignore();
}

class HotReload {
  const HotReload({
    required this.serverFactory,
    this.logLevel = logging.Level.OFF,
  });

  final Future<HttpServer> Function() serverFactory;
  final logging.Level logLevel;

  /// Set default messages
  void _onReloaded() {
    final time = _formatTime(DateTime.now());
    stdout.writeln('[hotreload] $time - Application reloaded.');
  }

  void _onHotReloadAvailable() {
    stdout.writeln('[hotreload] Hot reload is enabled.');
  }

  void _onHotReloadNotAvailable() {
    stdout.writeln(
      '[hotreload] Hot reload not enabled. Run this app with '
      '--enable-vm-service (or use debug run) '
      'in order to enable hot reload.',
    );
  }

  void _onHotReloadLog(logging.LogRecord log) {
    final time = _formatTime(log.time);
    (log.level < logging.Level.SEVERE ? stdout : stderr).writeln(
      '[hotreload] $time - ${log.message}',
    );
  }

  Future<void> attach() async {
    /// Current server instance
    HttpServer? runningServer;

    /// Configure logging
    logging.hierarchicalLoggingEnabled = true;
    HotReloader.logLevel = logLevel;
    logging.Logger.root.onRecord.listen(_onHotReloadLog);

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
        onAfterReload: (ctx) {
          obtainNewServer(serverFactory);
        },
        debounceInterval: const Duration(milliseconds: 1000),
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
