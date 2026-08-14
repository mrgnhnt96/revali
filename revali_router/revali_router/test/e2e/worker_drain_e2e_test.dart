// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:revali_router/revali_router.dart';
import 'package:test/test.dart';

/// End-to-end drain across real worker isolates over a real socket.
///
/// `worker_fleet_test.dart` covers the fleet *protocol* -- registration,
/// command delivery, timeout, a throwing worker, reset -- with workers that
/// never serve anything. That leaves the property the fleet exists for
/// untested: an HTTP request already being served *by a worker* must finish
/// when the parent starts shutting down.
///
/// Everything here is real: real isolates, a real shared socket, real requests
/// over loopback, and the real `shutdownServer` drain.
///
/// ## No timing, anywhere
///
/// A previous attempt at this test passed against a build where the fleet
/// drain did nothing, because every request took the same three seconds --
/// with one fixed duration, "the response arrived" and "the response arrived
/// *because* we waited for it" are indistinguishable.
///
/// A sleep-based version of *this* test was then flaky at 2 passes in 8: it
/// compared when the client finished reading against when the parent's drain
/// returned, and those are scheduled independently, so the order was never
/// guaranteed even when the drain was perfectly correct. That assertion was
/// wrong, not merely racy.
///
/// So handlers here block on a signal the parent controls instead of a sleep.
/// The requests are *provably* in flight when the drain begins -- they cannot
/// finish, because nothing has released them yet -- and the property under
/// test becomes a plain question with no clock in it: did every response
/// survive intact?
///
/// ## Why it cannot pass vacuously
///
/// Only workers bind the port, so every request is provably served by a
/// worker, and the test asserts the load reached more than one of them. The
/// companion test drives the identical scenario with a worker that abandons
/// its in-flight requests and requires that to break the responses -- if it
/// ever stops breaking them, the discriminator is gone and the suite says so.

/// Boot arguments, by index, shared by both worker entry points.
const _registration = 0;
const _observer = 1;
const _port = 2;
const _workerId = 3;

/// A worker isolate: binds the shared port, holds requests open until the
/// parent releases them, and drains when the parent says so.
Future<void> _servingWorker(List<Object> boot) async {
  final registration = boot[_registration] as SendPort;
  final observer = boot[_observer] as SendPort;
  final port = boot[_port] as int;
  final workerId = boot[_workerId] as int;

  final release = Completer<void>();
  final releases = ReceivePort()
    ..listen((_) {
      if (!release.isCompleted) release.complete();
    });

  observer.send(<Object>['release-port', workerId, releases.sendPort]);

  final server = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    port,
    shared: true,
  );

  final inFlight = InFlightRequests();

  unawaited(
    () async {
      await for (final request in server) {
        final work = () async {
          observer.send(<Object>['started', workerId]);

          // No sleep: this request cannot complete until the parent says so,
          // which is what makes "in flight during the drain" a fact rather
          // than a hope about scheduling.
          await release.future;

          request.response.write('served-by-$workerId');
          await request.response.close();

          observer.send(<Object>['finished', workerId]);
        }();

        inFlight.track(work);
        unawaited(work);
      }
    }(),
  );

  listenForDrainCommands(registration, (drainDelay) async {
    await shutdownServer(
      server: server,
      inFlight: inFlight,
      timeout: const Duration(seconds: 20),
      drainDelay: drainDelay,
    );
  });
}

/// A worker that ignores its in-flight requests when told to drain.
///
/// The "feature off" build, kept executable in the suite rather than patched
/// in by hand: it force-closes the socket and reports back, which is exactly
/// what a broken drain does.
Future<void> _abandoningWorker(List<Object> boot) async {
  final registration = boot[_registration] as SendPort;
  final observer = boot[_observer] as SendPort;
  final port = boot[_port] as int;
  final workerId = boot[_workerId] as int;

  final release = Completer<void>();
  final releases = ReceivePort()
    ..listen((_) {
      if (!release.isCompleted) release.complete();
    });

  observer.send(<Object>['release-port', workerId, releases.sendPort]);

  final server = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    port,
    shared: true,
  );

  unawaited(
    () async {
      await for (final request in server) {
        unawaited(() async {
          observer.send(<Object>['started', workerId]);
          await release.future;
          try {
            request.response.write('served-by-$workerId');
            await request.response.close();
            observer.send(<Object>['finished', workerId]);
          } catch (_) {
            // The socket is already gone -- which is the point.
          }
        }());
      }
    }(),
  );

  listenForDrainCommands(registration, (_) async {
    await server.close(force: true);
  });
}

/// A port nothing is listening on.
///
/// Bound and released rather than guessed, so the suite does not collide with
/// whatever else is running on the machine.
Future<int> _freePort() async {
  final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = probe.port;
  await probe.close();

  return port;
}

Future<void> _until(bool Function() condition, {String? describe}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));

  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      final detail = describe == null ? '' : ': $describe';
      fail('condition never became true$detail');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

/// Everything the parent observes about one fleet of workers.
class _Harness {
  _Harness(this.port);

  final int port;
  final releasePorts = <int, SendPort>{};
  final startedBy = <int>{};
  final finished = <int>[];
  int started = 0;

  /// Lets every held request finish.
  void release() {
    for (final port in releasePorts.values) {
      port.send('go');
    }
  }
}

void main() {
  group('multi-worker drain', () {
    late WorkerFleet fleet;
    final spawned = <Isolate>[];
    final observers = <ReceivePort>[];

    setUp(() => fleet = WorkerFleet());

    tearDown(() {
      for (final isolate in spawned) {
        isolate.kill(priority: Isolate.immediate);
      }
      spawned.clear();
      for (final port in observers) {
        port.close();
      }
      observers.clear();
      fleet.reset();
    });

    Future<_Harness> spawnWorkers({
      required Future<void> Function(List<Object>) entry,
      required int count,
    }) async {
      final harness = _Harness(await _freePort());
      final registration = fleet.open();
      final observed = ReceivePort();
      observers.add(observed);

      observed.listen((message) {
        switch (message) {
          case ['release-port', final int id, final SendPort port]:
            harness.releasePorts[id] = port;
          case ['started', final int id]:
            harness.started++;
            harness.startedBy.add(id);
          case ['finished', final int id]:
            harness.finished.add(id);
        }
      });

      for (var i = 0; i < count; i++) {
        spawned.add(
          await Isolate.spawn(entry, <Object>[
            registration,
            observed.sendPort,
            harness.port,
            i,
          ]),
        );
      }

      await _until(
        () => fleet.registered == count && harness.releasePorts.length == count,
        describe: '$count workers registered and reachable',
      );

      return harness;
    }

    test(
      'in-flight requests on workers survive the parent draining the fleet',
      () async {
        const workerCount = 3;
        const requestCount = 6;

        final harness = await spawnWorkers(
          entry: _servingWorker,
          count: workerCount,
        );

        final client = HttpClient();
        final responses = <Future<String>>[
          for (var i = 0; i < requestCount; i++)
            () async {
              final request = await client.get(
                InternetAddress.loopbackIPv4.address,
                harness.port,
                '/',
              );
              final response = await request.close();

              return response.transform(utf8.decoder).join();
            }(),
        ];

        // Every request is in flight and *cannot* complete: nothing has been
        // released. This is a fact about the handlers, not about timing.
        await _until(
          () => harness.started == requestCount,
          describe: 'all $requestCount requests started on a worker',
        );

        expect(
          harness.finished,
          isEmpty,
          reason: 'nothing may have completed before the drain begins, or the '
              'drain is not what kept these requests alive',
        );

        // Start the drain, then release. The drain must wait for work that was
        // already running when it began.
        final draining = fleet.drainAll(
          drainDelay: Duration.zero,
          timeout: const Duration(seconds: 20),
        );

        harness.release();

        expect(
          await draining,
          isTrue,
          reason: 'every worker should report having drained',
        );

        final bodies = await Future.wait(responses);

        // The property, with no clock in it: a drain that did not wait would
        // have force-closed these sockets mid-response.
        for (final body in bodies) {
          expect(body, startsWith('served-by-'));
        }

        expect(harness.finished, hasLength(requestCount));

        // Guards against the test quietly becoming vacuous: if traffic ever
        // stopped reaching multiple worker isolates, fail loudly rather than
        // pass while proving nothing.
        expect(
          harness.startedBy.length,
          greaterThan(1),
          reason: 'requests must spread across more than one worker for '
              'this to be a multi-worker test; served by ${harness.startedBy}',
        );

        client.close();
      },
      timeout: const Timeout(Duration(seconds: 120)),
    );

    test(
      'the same scenario breaks when a worker abandons its in-flight requests',
      () async {
        // The discriminator, kept executable. If this ever passes cleanly, the
        // test above has stopped being able to tell a working drain from a
        // broken one.
        final harness = await spawnWorkers(
          entry: _abandoningWorker,
          count: 2,
        );

        final client = HttpClient();

        Object? failure;
        String? body;

        // The error is caught *inside* the future rather than asserted on from
        // outside with `expectLater`. The socket is force-closed while nothing
        // is awaiting yet, so an escaping rejection is an unhandled async
        // error -- which the test framework reports as a failure regardless of
        // what the assertion says. Catching it here is what makes the expected
        // breakage observable instead of fatal.
        final done = () async {
          try {
            final request = await client.get(
              InternetAddress.loopbackIPv4.address,
              harness.port,
              '/',
            );
            final response = await request.close();
            body = await response.transform(utf8.decoder).join();
          } catch (e) {
            failure = e;
          }
        }();

        await _until(() => harness.started == 1, describe: 'request started');

        await fleet.drainAll(
          drainDelay: Duration.zero,
          timeout: const Duration(seconds: 20),
        );

        harness.release();
        await done;

        // A worker that does not wait truncates the response: either the read
        // throws, or no intact body ever arrives. Both are failures to drain,
        // and neither is what the real worker does.
        expect(
          failure != null || body == null || !body!.startsWith('served-by-'),
          isTrue,
          reason: 'abandoning an in-flight request must break the response; if '
              'it does not, the passing test above proves nothing. '
              'failure=$failure body=$body',
        );

        client.close();
      },
      timeout: const Timeout(Duration(seconds: 120)),
    );
  });
}
