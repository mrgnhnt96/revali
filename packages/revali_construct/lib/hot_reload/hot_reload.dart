import 'dart:async';
import 'dart:io';

import 'package:hotreloader/hotreloader.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:revali_construct/models/files/server_file.dart';

void hotReload(Future<HttpServer> Function() callback) {
  HotReload(serverFactory: callback).attach().ignore();
}

class HotReload {
  const HotReload({
    required this.serverFactory,
    this.logLevel = Level.OFF,
  });

  static const reloaded = '__RELOADED__';
  static const nonrevaliReload = '__NON_revali_RELOAD__';
  static const revaliStarted = '__revali_STARTED__';
  static const hotReloadEnabled = '__HOT_RELOAD_ENABLED__';

  final Future<HttpServer> Function() serverFactory;
  final Level logLevel;

  void _onHotReloadAvailable() {
    stdout.writeln(hotReloadEnabled);
  }

  void _onHotReloadNotAvailable() {
    stdout.writeln(
      '[hotreload] Hot reload not enabled. Run this app with '
      '--enable-vm-service (or use debug run) '
      'in order to enable hot reload.',
    );
  }

  Future<void> attach() async {
    /// Current server instance
    HttpServer? runningServer;

    /// Configure logging
    hierarchicalLoggingEnabled = true;
    HotReloader.logLevel = logLevel;

    /// Function in charge of replacing the running http server
    final obtainNewServer = (FutureOr<HttpServer> Function() create) async {
      /// Shut down existing server
      await runningServer?.close(force: true);

      /// Create a new server
      runningServer = await create();
    };

    try {
      /// Register the server reload mechanism to the generic HotReloader.
      /// It will throw an error if reloading is not available.
      await HotReloader.create(
        onBeforeReload: (context) {
          final path = context.event?.path;

          final out = log.level < Level.SEVERE ? stdout : stderr;

          if (path == null) {
            return false;
          }

          final cwd = Directory.current.path;
          if (!p.isWithin(cwd, path)) {
            out.writeln(nonrevaliReload);

            return true;
          }

          final lib = Directory(p.join(cwd, 'lib')).path;
          final routes = Directory(p.join(cwd, 'routes')).path;
          final public = Directory(p.join(cwd, 'public')).path;
          final server = File(p.join(cwd, '.revali', ServerFile.fileName)).path;

          if (p.isWithin(lib, path)) {
            out.writeln(nonrevaliReload);
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
          stdout.writeln(reloaded);
          obtainNewServer(serverFactory);
        },
        debounceInterval: Duration.zero,
      );

      stdout.writeln(revaliStarted);

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
}
