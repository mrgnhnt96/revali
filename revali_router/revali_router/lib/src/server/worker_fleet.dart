// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:isolate';

/// Parent-side handle on worker isolates, so a shutdown reaches all of them.
///
/// With `AppConfig.workers > 1` every isolate binds the same port with
/// `shared: true` and keeps its **own** in-flight set, while only the parent
/// watches for signals. Without this, a `SIGTERM` drains one isolate's
/// requests and the parent's `exit(0)` then takes every other isolate's
/// requests with it — and readiness has the same split, since a probe the OS
/// balanced onto a worker reports ready while the parent is already draining.
///
/// The fleet closes that gap: the parent tells each worker to drain, every
/// isolate flags its own readiness, and the process only exits once they have
/// all reported back.
class WorkerFleet {
  final _commands = <SendPort>[];

  ReceivePort? _registrations;

  /// How many workers have registered so far.
  ///
  /// Registration is a message, so this climbs as workers start rather than
  /// being final the moment they are spawned.
  int get registered => _commands.length;

  /// Opens the registration channel and returns the port to hand to workers.
  SendPort open() {
    reset();

    final port = ReceivePort();
    _registrations = port;

    port.listen((message) {
      if (message is SendPort) {
        _commands.add(message);
      }
    });

    return port.sendPort;
  }

  /// Forgets every worker and closes the registration channel.
  ///
  /// Respawning without this leaves the previous generation's ports in the
  /// list, which a hot reload would otherwise accumulate on every restart.
  void reset() {
    _registrations?.close();
    _registrations = null;
    _commands.clear();
  }

  /// Tells every registered worker to drain, and waits for them to finish.
  ///
  /// Returns true when all of them reported back within [timeout]. A worker
  /// that died, never registered, or hangs must not keep the process alive
  /// forever, so the wait is bounded and reports false rather than throwing —
  /// the caller is on its way to `exit` either way, and a stuck worker should
  /// cost the timeout, not the whole shutdown.
  Future<bool> drainAll({
    required Duration drainDelay,
    required Duration timeout,
    void Function(String message)? log,
  }) async {
    if (_commands.isEmpty) {
      return true;
    }

    log?.call('Draining ${_commands.length} worker isolate(s)...');

    final ports = <ReceivePort>[];
    final replies = <Future<bool>>[];

    for (final command in _commands) {
      final reply = ReceivePort();
      ports.add(reply);

      // Closing the port below completes `first` with an error rather than a
      // value, so a timed-out worker resolves to false instead of surfacing
      // as an unhandled async error.
      replies.add(
        reply.first.then((value) => value == true).catchError((Object _) {
          return false;
        }),
      );

      // A Duration is not worth relying on across a port; microseconds are.
      command.send(<Object>[drainDelay.inMicroseconds, reply.sendPort]);
    }

    try {
      final results = await Future.wait(replies).timeout(timeout);

      return results.every((drained) => drained);
    } on TimeoutException {
      log?.call(
        'Timed out after ${timeout.inSeconds}s waiting for worker isolates '
        'to drain.',
      );

      return false;
    } finally {
      for (final port in ports) {
        port.close();
      }
    }
  }
}

/// Worker-side half of [WorkerFleet].
///
/// Registers this isolate with the parent and runs [drain] whenever the parent
/// asks, reporting back once it finishes. Returns the command port so a caller
/// that outlives the server can close it.
ReceivePort listenForDrainCommands(
  SendPort registration,
  Future<void> Function(Duration drainDelay) drain,
) {
  final commands = ReceivePort()
    ..listen((message) async {
      if (message case [final int micros, final SendPort reply]) {
        try {
          await drain(Duration(microseconds: micros));
        } catch (e, st) {
          // A worker that fails to drain must still report, or the parent waits
          // out its entire timeout for a reply that was never coming.
          print('Worker drain failed: $e\n$st');
        }

        reply.send(true);
      }
    });

  registration.send(commands.sendPort);

  return commands;
}
