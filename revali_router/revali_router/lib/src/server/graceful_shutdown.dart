// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:revali_router/src/server/in_flight_requests.dart';

/// Stops [server] without truncating requests that are already in flight.
///
/// The sequence matters:
///
/// 1. The drain is flagged, which flips the readiness probe to 503 while the
///    server is *still accepting*. See [drainDelay].
/// 2. `server.close()` is started but **not** awaited. It ends the accept
///    loop immediately so no new request is taken, but its own future may
///    wait on idle keep-alive connections, which is not something a shutdown
///    should block on.
/// 3. In-flight requests are awaited, up to [timeout].
/// 4. `server.close(force: true)` drops whatever sockets remain, so the
///    process can actually exit.
///
/// Returns true when everything drained within [timeout].
Future<bool> shutdownServer({
  required HttpServer server,
  required InFlightRequests inFlight,
  Duration timeout = const Duration(seconds: 30),
  Duration drainDelay = Duration.zero,
  Future<void> Function()? onStopped,
  void Function(String message)? log,
}) async {
  // Flag the drain *before* closing, so the accept loop -- which ends the
  // moment close() lands -- knows not to run its own teardown on top of
  // requests that are still being served.
  inFlight.beginDraining();

  // Closing the listening socket is invisible to a load balancer: it keeps
  // routing until its own readiness probe fails, and every request it sends
  // in the meantime hits a closed socket. Readiness reports 503 from the line
  // above, so this window is the balancer's chance to notice and steer away
  // while the server can still serve. Requests arriving during it are served
  // and tracked normally -- the accept loop does not refuse while draining.
  if (drainDelay > Duration.zero) {
    // Sub-second delays are legitimate, and `inSeconds` truncates them to a
    // baffling "for 0s".
    final window = drainDelay.inMilliseconds < 1000
        ? '${drainDelay.inMilliseconds}ms'
        : '${drainDelay.inSeconds}s';

    log?.call(
      'Draining: readiness now reports unavailable, '
      'still accepting for $window...',
    );
    await Future<void>.delayed(drainDelay);
  }

  unawaited(server.close().catchError((Object _) {}));

  final pending = inFlight.length;
  if (pending > 0) {
    log?.call('Waiting for $pending in-flight request(s) to finish...');
  }

  final drained = await inFlight.drain(timeout);

  if (!drained) {
    log?.call(
      'Shutdown timed out after ${timeout.inSeconds}s with '
      '${inFlight.length} request(s) still running.',
    );
  }

  try {
    await onStopped?.call();
  } catch (e, st) {
    print('onServerStopped failed: $e\n$st');
  }

  try {
    await server.close(force: true);
  } catch (_) {
    // Already closed.
  }

  return drained;
}

/// Signals that should stop the server.
///
/// `SIGTERM` is what container runtimes and process supervisors send, and is
/// the reason this exists at all. Windows supports neither it nor `SIGHUP`,
/// so only `SIGINT` is watched there.
List<ProcessSignal> shutdownSignals() => [
      ProcessSignal.sigint,
      if (!Platform.isWindows) ProcessSignal.sigterm,
    ];

/// Runs [onShutdown] the first time a shutdown signal arrives.
///
/// Later signals are ignored while the first shutdown is still running — an
/// impatient second Ctrl-C should not start a second drain. Returns the
/// subscriptions so a caller that outlives the server (tests, embedders) can
/// cancel them.
List<StreamSubscription<ProcessSignal>> listenForShutdown(
  Future<void> Function(ProcessSignal signal) onShutdown,
) {
  final subscriptions = <StreamSubscription<ProcessSignal>>[];
  var handling = false;

  for (final signal in shutdownSignals()) {
    try {
      subscriptions.add(
        signal.watch().listen((received) async {
          if (handling) {
            return;
          }
          handling = true;

          await onShutdown(received);
        }),
      );
    } catch (e) {
      // Watching a signal can fail on platforms that do not support it.
      print('Could not watch $signal: $e');
    }
  }

  return subscriptions;
}
