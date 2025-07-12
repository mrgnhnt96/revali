// ignore_for_file: avoid_redundant_argument_values

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hotreloader/hotreloader.dart';
import 'package:logging/logging.dart';
import 'package:revali_construct/models/hot_reload_data/hot_reload_data.dart';
import 'package:revali_construct/models/hot_reload_data/hot_reload_files_changed.dart';
import 'package:revali_construct/utils/debouncer.dart';

void hotReload(Future<HttpServer> Function() callback) {
  HotReload(serverFactory: callback).attach().ignore();
}

class HotReload {
  HotReload({required this.serverFactory, this.logLevel = Level.OFF})
      : controller = StreamController<HotReloadData>.broadcast();

  final Future<HttpServer> Function() serverFactory;
  final Level logLevel;
  final StreamController<HotReloadData> controller;

  void _onHotReloadAvailable() {
    controller.add(const HotReloadData(type: HotReloadType.hotReloadEnabled));
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
    Future<void> obtainNewServer(FutureOr<HttpServer> Function() create) async {
      /// Shut down existing server
      await runningServer?.close(force: true);

      /// Create a new server
      runningServer = await create();
    }

    controller.stream.transform(const Debouncer()).listen((msg) async {
      try {
        stderr.writeln(jsonEncode(msg.toJson()));
      } catch (_) {}
      switch (msg.type) {
        case HotReloadType.filesChanged:
          await obtainNewServer(serverFactory);
        case HotReloadType.revaliStarted:
        case HotReloadType.hotReloadEnabled:
      }
    });

    try {
      /// Register the server reload mechanism to the generic HotReloader.
      /// It will throw an error if reloading is not available.
      await HotReloader.create(
        watchDependencies: true,
        onAfterReload: (context) async {
          controller.add(
            HotReloadFilesChanged(
              files: context.events?.map((e) => e.path).toList() ?? [],
            ),
          );
        },
        debounceInterval: Duration.zero,
      );

      controller.add(const HotReloadData(type: HotReloadType.revaliStarted));

      /// Hot-reload is available
      _onHotReloadAvailable();
      // ignore: avoid_catching_errors
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
