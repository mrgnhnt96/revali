import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
// Narrowed on purpose: `package:nocterm` exports its own `Logger`, which would
// collide with `mason_logger`'s the moment anything here said `Logger`.
import 'package:nocterm/nocterm.dart' show runApp, shutdownApp;
import 'package:path/path.dart' as p;
import 'package:platform/platform.dart';
// Prefixed because the TUI's `UpCommand` — the r/c/q key constants — shares its
// name with the command class below. Unprefixed, the class would shadow it and
// the constants would be unreachable from here.
import 'package:revali/clis/revali_runner/tui/up_app.dart' as tui;
import 'package:revali/services/ansi.dart';
import 'package:revali/services/service_discovery.dart';
import 'package:revali/services/service_plan.dart';
import 'package:revali/services/service_session.dart';

/// How one `revali dev` child is spawned.
///
/// A seam, and the only reason a restart can be proved without the suite
/// starting real `dart run revali dev` processes on the machine running it.
/// Narrower than `io.Process.start` on purpose — it names only the four things
/// this command actually passes — and a tear-off of the real one still fits,
/// since the extra parameters it has are all optional.
typedef ProcessSpawner =
    Future<io.Process> Function(
      String executable,
      List<String> arguments, {
      String? workingDirectory,
      Map<String, String>? environment,
    });

/// Runs every service in the repository at once.
///
/// A system split across five services is five `revali dev` processes in five
/// terminals, which is the point at which people stop running the whole thing
/// locally and start developing one service against staging or mocks. Both
/// hide exactly the mismatches that splitting into services creates — and a
/// system you cannot run is a system you cannot trust to work deployed.
class UpCommand extends Command<int> {
  UpCommand({
    required this.logger,
    required this.fs,
    ProcessSpawner spawn = io.Process.start,
  }) : _spawn = spawn {
    argParser
      ..addOption(
        'root',
        help: 'Directory to search from. Defaults to the working directory.',
        valueHelp: 'path',
      )
      ..addMultiOption(
        'only',
        help: 'Run just these services, by package name or path.',
        valueHelp: 'name',
      )
      ..addOption(
        'base-port',
        help: 'First port to assign; services take one each in order.',
        valueHelp: 'port',
        defaultsTo: '8080',
      );
  }

  final Logger logger;
  final FileSystem fs;

  final ProcessSpawner _spawn;

  /// Children, so a signal can reach all of them.
  ///
  /// Keyed by label, and the key is how a restart knows whether there is
  /// already a process behind a service: the exit handler removes the entry, so
  /// a label that is still in here has something running under it. Spawning a
  /// second one would leave the first unreachable — nothing would hold its
  /// handle, so `Ctrl+C` would not reach it and it would keep the port.
  final _running = <String, io.Process>{};

  var _stopping = false;

  /// Children currently running, and whether anything has ever started.
  ///
  /// A count rather than the list of exit futures this used to wait on.
  /// `Future.wait` iterates its argument once, when it is called, so an exit
  /// future appended afterwards is never waited on at all — and a restart
  /// appends one. The fleet would have been declared gone the moment the
  /// *original* processes were all accounted for, taking the screen down while
  /// a service someone had just asked for was still coming up.
  var _alive = 0;
  var _spawned = 0;

  /// Completes when every child is gone and none has been brought back.
  final _fleetGone = Completer<void>();

  /// Whether [_fleetGone] is allowed to complete yet.
  ///
  /// The initial services are spawned one at a time, so [_alive] passes through
  /// zero legitimately — a service that dies on the spot while the next one is
  /// still being started would otherwise take the whole run down with it. The
  /// gate is opened once, after the starting loop, and the check is run by hand
  /// there for the case where they really are all already gone.
  var _fleetArmed = false;

  /// The width the roster's labels are padded to, so a restart lines its
  /// prefixed output up with everything the service printed before it died.
  var _labelWidth = 0;

  /// Whether nocterm owns the screen.
  ///
  /// Decided once, before anything starts, because every write after it has to
  /// respect the answer: with the alternate screen up, a `logger` line paints
  /// over the frame nocterm is drawing.
  var _useTui = false;

  @override
  String get name => 'up';

  @override
  String get description => 'Run every Revali service in this repository';

  @override
  Future<int> run() async {
    final rootPath = argResults?['root'] as String? ?? fs.currentDirectory.path;
    final root = fs.directory(rootPath);

    if (!root.existsSync()) {
      logger.err('No such directory: $rootPath');

      return 1;
    }

    final basePort = int.tryParse(argResults?['base-port'] as String? ?? '');
    if (basePort == null) {
      logger.err('--base-port must be a number');

      return 1;
    }

    final services = const ServiceDiscovery().find(root);

    if (services.isEmpty) {
      logger.err(
        'No Revali services found under $rootPath.\n'
        'A service is a package with a routes/ directory that depends on '
        'revali_router.',
      );

      return 1;
    }

    final List<ServicePlan> plans;
    try {
      plans = planServices(
        services,
        basePort: basePort,
        only: argResults?['only'] as List<String>? ?? const [],
      );
    } on UnknownServiceException catch (e) {
      logger.err('$e');

      return 1;
    }

    return _runAll(plans);
  }

  Future<int> _runAll(List<ServicePlan> plans) async {
    final width = _labelWidth = plans
        .map((p) => p.label.length)
        .reduce((a, b) => a > b ? a : b);

    _useTui = canDrawTui();

    // The summary prints either way. Under the TUI the alternate screen covers
    // it a moment later and gives it back on exit, and it is what a developer
    // sees if a service dies before the screen is even up.
    logger.info('Starting ${plans.length} service(s)\n');
    for (final (index, plan) in plans.indexed) {
      final color = colorFor(index);
      logger.info(
        '  ${color.wrap(plan.label.padRight(width))}  '
        'http://localhost:${plan.port}',
      );
    }
    logger.info('');

    final sessions = <ServiceSession>[];

    if (!await startFleet(plans, sessions)) {
      logger.err('No service could be started.');

      return 1;
    }

    // A signal here has to reach the children: they are the ones holding
    // ports and in-flight requests, and the generated server already knows
    // how to drain on SIGTERM.
    final signals = _listenForShutdown();

    if (_useTui) {
      return _runTui(plans, sessions, signals);
    }

    await _fleetGone.future;

    for (final subscription in signals) {
      await subscription.cancel();
    }

    return _stopping ? 0 : 1;
  }

  /// Starts every service in [plans], filling [sessions] as it goes.
  ///
  /// Returns whether anything started at all. A service that fails to start
  /// must not take the others down: the usual cause is a compile error the
  /// developer is about to fix, and losing the whole fleet for it makes the
  /// loop worse, not safer.
  ///
  /// [sessions] is filled here rather than returned so it stays the same list
  /// the caller hands to the screen — the screen is built from it before any of
  /// this has finished, and a second list would leave the two able to disagree.
  /// A session is made only where there is a pane to draw it in; on the flat
  /// path one would be a ring buffer filling up for no one.
  ///
  /// Public so a test can stand a fleet up with an injected spawner, which is
  /// the only way to reach [fleetGone] — the one thing a restart has to get
  /// right and the one thing that is invisible until every service has died.
  Future<bool> startFleet(
    List<ServicePlan> plans,
    List<ServiceSession> sessions,
  ) async {
    if (_labelWidth == 0) {
      _labelWidth = plans
          .map((p) => p.label.length)
          .reduce((a, b) => a > b ? a : b);
    }

    for (final (index, plan) in plans.indexed) {
      final session = _useTui ? ServiceSession(plan) : null;
      if (session != null) {
        sessions.add(session);
      }

      await _start(plan, colorFor(index), _labelWidth, session);
    }

    if (_spawned == 0) return false;

    // Opened only now, for the reason [_fleetArmed] carries: until the loop
    // above has finished, a zero here means "not started yet" as often as it
    // means "all gone". Checked by hand in the same breath, because if they
    // really did all die while starting there is no exit left to come and
    // notice it.
    _fleetArmed = true;
    _noticeFleetGone();

    return true;
  }

  /// Completes when every child is gone and none has been brought back.
  ///
  /// What decides the run is over, on both paths: the flat one awaits it and
  /// the TUI takes the screen down on it.
  Future<void> get fleetGone => _fleetGone.future;

  /// How many children are running right now.
  int get aliveCount => _alive;

  /// Whether the TUI is in play, which decides whether services get panes.
  ///
  /// Settable only for a test: the real answer comes from [canDrawTui], and a
  /// test has no terminal to give it.
  // ignore: avoid_setters_without_getters
  set useTui(bool value) => _useTui = value;

  /// Holds the screen until the fleet is gone, drawing it as it goes.
  ///
  /// This is what replaces the flat path's `await Future.wait(exits)`: nocterm
  /// runs its own event loop, so waiting on the children happens alongside it
  /// rather than instead of it.
  Future<int> _runTui(
    List<ServicePlan> plans,
    List<ServiceSession> sessions,
    List<StreamSubscription<io.ProcessSignal>> signals,
  ) async {
    // A dead fleet must not leave the screen up: there is nothing left to
    // watch, and the one key that could have brought something back — `s` —
    // needs a service to be *focused*, which means a screen, which means at
    // least one other service still holding it up. So a fleet that is entirely
    // gone is genuinely the end of the run, and this is where a restart stops
    // being reachable: `s` recovers a crashed service out of a fleet, not the
    // fleet itself. Bringing that back would mean a `revali up` that sits on an
    // empty screen after everything has died, which is a worse default than
    // exiting for every use that is not a person watching it.
    unawaited(_fleetGone.future.then((_) => shutdownApp(_stopping ? 0 : 1)));

    await runApp(
      buildApp(plans, sessions),
      // Nothing on this screen is worth reloading in place. The `r` key
      // rebuilds the *services*; wiring a second, unrelated reload into the
      // same session is a VM service connection `revali up` has no use for.
      enableHotReload: false,
    );

    // Only reached if nocterm's loop ends without `shutdownApp` — that call
    // restores the terminal and exits the process itself, so the lines below
    // are the answer for the path where it never happens.
    for (final subscription in signals) {
      await subscription.cancel();
    }

    _restoreTerminalMode();

    return _stopping ? 0 : 1;
  }

  /// The screen, with its keys wired to the fleet.
  ///
  /// [sessions] must line up with [plans] — the app hands a session back and
  /// the command goes to that session's own plan, so a service can be
  /// addressed without the app knowing what addressing one involves.
  ///
  /// Public so a `NoctermTester` can press keys at it and watch the files
  /// land. Wired inside `runApp` there is nothing between the keystroke and a
  /// real terminal to assert on.
  tui.UpApp buildApp(List<ServicePlan> plans, List<ServiceSession> sessions) {
    return tui.UpApp(
      sessions: sessions,
      onCommand: (session, key) => _send(session.plan, key),
      onCommandAll: (key) {
        _sendAll(plans, key);

        if (key == tui.UpCommand.quit) {
          // The children are told to quit *and* the fleet stops: a child that
          // is wedged badly enough to ignore its command file must not leave
          // `revali up` waiting on it forever.
          _stop();
        }
      },
      onQuit: _quit,
      onOpenUrl: openUrl,
      onRestart: (session) => restart(session, plans).ignore(),
    );
  }

  /// Brings a dead service back with a fresh `revali dev` process.
  ///
  /// The half `r` cannot do. Reload travels by writing `.revali_cmd`, which
  /// works only while the `revali dev` wrapper is alive to be watching it —
  /// that is the `needs fix` case, where the wrapper stayed up on purpose after
  /// its inner server died. Once the wrapper itself is gone there is nobody
  /// reading the file, so `r` writes into the void; the only way back is
  /// another [io.Process.start], which is this.
  ///
  /// Declines, quietly and on purpose, in three cases:
  ///
  /// * the fleet is draining. A `Ctrl+C` or `Q` has already gone out and every
  ///   other child has had its SIGTERM; spawning one more would be starting a
  ///   service into a shutdown, and it would not be in [_running] early enough
  ///   for [_stop] to have reached it either.
  /// * something is already running under this label. Guarded here as well as
  ///   in the screen because this is the check that costs something to get
  ///   wrong: a second process would take the first one's place in [_running]
  ///   and leave it with no handle, so `Ctrl+C` could not reach it and it would
  ///   sit on the port until it was killed by hand.
  /// * the service is not dead. `needs fix` looks broken and is not gone, and
  ///   `r` is what it wants.
  ///
  /// Quietly because the screen is nocterm's — there is nowhere to print that
  /// would not paint over the frame — and because every one of these is a key
  /// the legend already drew dim.
  ///
  /// Public so a test can drive it with an injected spawner.
  Future<void> restart(ServiceSession session, List<ServicePlan> plans) async {
    if (_stopping) return;
    if (_fleetGone.isCompleted) return;
    if (_running.containsKey(session.label)) return;
    if (!session.isDead) return;

    // By label rather than by identity, so a plan list rebuilt anywhere along
    // the way still resolves. The index is also the service's colour, which is
    // why it is wanted rather than just the plan.
    final index = plans.indexWhere((plan) => plan.label == session.label);
    if (index == -1) return;

    // Before the spawn, so the pane is empty the instant the key is pressed
    // rather than at whatever point the new child gets round to printing. If
    // the spawn then fails, [_start] ingests the reason into a pane holding
    // nothing but that reason.
    session.markRestarted();

    await _start(plans[index], colorFor(index), _labelWidth, session);
  }

  /// Hands [url] to whatever this platform opens URLs with.
  ///
  /// Fire and forget, and deliberately quiet. The screen is nocterm's, so there
  /// is nowhere to print a failure that would not paint over the frame being
  /// drawn — and a browser that did not open is a click the user can simply
  /// make again, which is not worth taking the fleet down for. It goes to the
  /// verbose log instead, which is where someone working out why nothing
  /// happened will look.
  ///
  /// Public so a test can pin the argv without a browser opening: asserting the
  /// URL that would be launched is the whole of what this side controls.
  void openUrl(String url) {
    final (executable, arguments) = openerFor(url);

    try {
      // Not awaited: a click must not block the render loop on a process
      // start, and there is nothing in the result worth waiting for.
      unawaited(
        io.Process.run(executable, arguments)
            .then((result) {
              if (result.exitCode != 0) {
                logger.detail('Could not open $url: ${result.stderr}');
              }
            })
            .catchError((Object e) {
              logger.detail('Could not open $url: $e');
            }),
      );
    } catch (e) {
      logger.detail('Could not open $url: $e');
    }
  }

  /// The command that opens a URL on this platform.
  ///
  /// Windows goes through `cmd /c start` because `start` is a shell builtin
  /// rather than an executable, and the empty `""` is its title argument —
  /// without it `start` reads the URL as the window title and opens nothing.
  ///
  /// Public, and takes the platform explicitly, so all three branches can be
  /// proved from one machine. Two of them are unreachable on any given
  /// developer's laptop and would otherwise be found broken by a user.
  static (String, List<String>) openerFor(
    String url, {
    Platform platform = const LocalPlatform(),
  }) => switch (platform) {
    Platform(isMacOS: true) => ('open', [url]),
    Platform(isWindows: true) => ('cmd', ['/c', 'start', '', url]),
    _ => ('xdg-open', [url]),
  };

  /// `Ctrl+C`: stop the fleet, and on a second press stop waiting for it.
  ///
  /// The first press is a SIGTERM to every child, not a kill, so each drains
  /// through the same graceful path a `Ctrl+C` at its own terminal would take.
  /// That takes real time — a service with an in-flight drain delay and worker
  /// isolates to wind down takes seconds — so the TUI swaps to its shutdown
  /// screen for the duration, naming what is happening and keeping each
  /// service's state moving as it goes. See `shutdown_view.dart`; nothing about
  /// the mechanism here changes for it.
  ///
  /// The screen then comes down on its own once they are all gone. A second
  /// press is the way out when one of them does not go: the screen must not be
  /// the thing holding the user hostage.
  void _quit() {
    if (_stopping) {
      // `shutdownApp` rather than `exit`: it restores the terminal on the way
      // out, and a shell left in raw mode is worse than a wedged child.
      shutdownApp(1);

      return;
    }

    _stop();
  }

  /// Whether this run has a terminal that can carry the TUI.
  ///
  /// `revali up` in CI has no terminal at all, and flat prefixed output is the
  /// whole of what it should produce there — so this is a seam, not a
  /// preference.
  ///
  /// Raw mode is probed rather than assumed: a pseudo-TTY can report
  /// [io.Stdin.hasTerminal] and still refuse it, and nocterm's backend
  /// swallows that refusal, which would leave a screen drawn that cannot read
  /// a key. Better to find out here, while flat output is still an option.
  ///
  /// Public so a test can stand where CI stands. Making the TUI unconditional
  /// would delete the only output a pipeline ever gets, and it would do it
  /// silently — nobody runs CI's path by hand.
  bool canDrawTui() {
    // Both halves: nocterm draws to stdout and reads keys from stdin, and
    // either one redirected makes the screen wrong.
    if (!io.stdin.hasTerminal || !io.stdout.hasTerminal) {
      return false;
    }

    try {
      io.stdin
        ..echoMode = false
        ..lineMode = false;
    } catch (_) {
      return false;
    }

    // Put it straight back. nocterm sets raw mode itself when it starts, and
    // a terminal left raw in the gap swallows the `Ctrl+C` of someone who
    // changed their mind while the services were still spawning.
    _restoreTerminalMode();

    return true;
  }

  /// Writes [command] to one service's `.revali_cmd`.
  ///
  /// The file is the channel because a keypress cannot simply be passed
  /// through. A child's stdin is a pipe, not a terminal, so `revali dev`
  /// inside it takes its headless path and never reads keystrokes at all —
  /// which is why pressing `r` under `revali up` used to do nothing while
  /// file-watching reload worked fine. `revali dev` already had the answer:
  /// without a TTY it watches a `.revali_cmd` file in its project root for
  /// `reload` / `clear` / `quit`, so this writes that file rather than
  /// inventing a second channel — one service per file, in its own directory.
  ///
  /// Addressing a single service is the half a broadcast cannot express:
  /// reloading the one service being worked on should not restart the other
  /// four as collateral.
  ///
  /// Public so a test can drive it without starting real processes.
  void sendCommand(ServicePlan plan, String command) {
    final file = fs.file(
      p.join(plan.service.directory.path, _devCommandFileName),
    );

    try {
      // Newline-terminated: the reader splits on line breaks, and a bare
      // token with nothing after it is one `readAsString` race away from
      // being read half-written.
      file.writeAsStringSync('$command\n', flush: true);
    } catch (e) {
      // One unwritable directory must not stop the other services from
      // getting the command -- so this is caught here, per service, rather
      // than around the loop in [broadcastCommand].
      logger.detail('Could not signal ${plan.label}: $e');
    }
  }

  /// Writes [command] to every service's `.revali_cmd`.
  ///
  /// Public so a test can drive it without starting real processes.
  void broadcastCommand(List<ServicePlan> plans, String command) {
    for (final plan in plans) {
      sendCommand(plan, command);
    }
  }

  /// Sends the keystroke [key] to one service.
  void _send(ServicePlan plan, String key) =>
      sendCommand(plan, wireWordFor(key));

  /// Sends the keystroke [key] to the whole fleet.
  void _sendAll(List<ServicePlan> plans, String key) =>
      broadcastCommand(plans, wireWordFor(key));

  /// The word that goes on the wire for a [tui.UpCommand] keystroke.
  ///
  /// See [_wireWords] for why there is a translation at all, and why it is the
  /// word rather than the letter that travels.
  ///
  /// Public so a test can pin the two ends together: the reader drops a
  /// command it does not recognise without saying so, which makes a mismatch
  /// here indistinguishable from a key that simply does nothing.
  String wireWordFor(String key) {
    if (_wireWords[key] case final word?) {
      return word;
    }

    // A key the TUI binds that this map has not caught up with. The bare
    // letter is understood too, so it still works — but say so, because the
    // reader will not: it drops what it does not recognise without a word.
    logger.detail('No wire word for "$key"; sending the letter as-is');

    return key;
  }

  void _restoreTerminalMode() {
    try {
      // Leaving the terminal in raw mode makes the user's shell unusable
      // afterwards — no echo, no line editing.
      io.stdin
        ..echoMode = true
        ..lineMode = true;
    } catch (_) {
      // Nothing to restore if the mode never took.
    }
  }

  /// The file `revali dev` watches when it has no terminal of its own.
  static const _devCommandFileName = '.revali_cmd';

  /// What one child is started with, on top of this process's own environment.
  ///
  /// [useTui] is the whole of the colour decision, and it is a decision the
  /// *parent* has to make: a child's stdout is a pipe on both paths, so the
  /// child cannot tell them apart by looking. Under the TUI a pipe is an
  /// implementation detail of a pane that is about to paint colour; on the flat
  /// path it is the output CI reads, where escape sequences are a regression.
  ///
  /// Public so the two branches can be proved without spawning a process. The
  /// flat one is the branch nobody runs by hand, because it is the one CI
  /// takes — and getting it wrong is invisible here and loud in a build log.
  Map<String, String> childEnvironment(
    ServicePlan plan, {
    required bool useTui,
  }) => {
    // The port the fleet assigned. `AppConfig.fromEnv` reads it; a service
    // that hard-codes its port ignores this and will collide with whatever
    // else claimed that port.
    'PORT': '${plan.port}',

    // Ask for colour. `mason_logger` colours through `ansiOutputEnabled`,
    // which is false on a pipe — so without this the child emits plain text
    // and the pane has nothing to render however well it renders.
    // `revali dev` reads this variable and opts in; see [kForceAnsiEnvVar].
    if (useTui) kForceAnsiEnvVar: '1',
  };

  /// Starts one service and counts it into the fleet.
  ///
  /// A service that cannot start adds nothing, so the fleet carries on without
  /// it. The label is padded *before* it is coloured: ANSI escapes count
  /// toward string length, so padding afterwards misaligns every prefix.
  ///
  /// [session] is the pane this service's output belongs to, or null on the
  /// flat path where there are no panes.
  ///
  /// Called for the first start and for every restart, which is what makes a
  /// brought-back service indistinguishable from an original one to everything
  /// downstream — [_running], the liveness count, the pipes and the exit.
  Future<void> _start(
    ServicePlan plan,
    AnsiCode color,
    int width,
    ServiceSession? session,
  ) async {
    final label = color.wrap(plan.label.padRight(width)) ?? plan.label;

    final io.Process process;
    try {
      process = await _spawn(
        'dart',
        ['run', 'revali', 'dev'],
        workingDirectory: plan.service.directory.path,
        environment: childEnvironment(plan, useTui: _useTui),
      );
    } catch (e) {
      logger.err('${plan.label}: failed to start: $e');

      if (session != null) {
        // The reason belongs in the pane too: the line above scrolls away the
        // moment the screen goes up, and a row that says `crashed` with
        // nothing under it is a dead end. Ingested *before* the exit is
        // recorded — a session that already knows it is gone ignores output,
        // so that it cannot walk `crashed` back to `serving`.
        session
          ..ingest('failed to start: $e\n', isError: true)
          ..markExited(1);
      }

      return;
    }

    _running[plan.label] = process;
    _alive++;
    _spawned++;

    void pipe(Stream<List<int>> stream, {required bool isError}) {
      stream
          .transform(utf8.decoder)
          .listen(
            (chunk) => routeOutput(
              chunk,
              label: label,
              isError: isError,
              session: session,
            ),
          );
    }

    pipe(process.stdout, isError: false);
    pipe(process.stderr, isError: true);

    unawaited(
      process.exitCode.then<void>((code) {
        // Only if this is still the process behind that label. A restart that
        // raced ahead of a late exit would otherwise have its own handle
        // dropped by the dead one's callback, leaving the live child with
        // nothing holding it for `Ctrl+C`.
        if (identical(_running[plan.label], process)) {
          _running.remove(plan.label);
        }

        _alive--;
        _noticeFleetGone();

        if (session != null) {
          // The row reports it, in place and permanently: `stopped` or
          // `crashed`. A logger line as well would paint over the frame
          // nocterm is drawing.
          session.markExited(code);

          return;
        }

        if (_stopping) {
          return;
        }

        // Reported rather than silent: a service that dies mid-session
        // otherwise just stops producing output, which reads like idleness.
        logger.err('${plan.label} exited ($code)');
      }),
    );
  }

  /// Sends one write from a child to wherever this run shows output.
  ///
  /// With a [session], the raw chunk goes to that service's pane. A pane owns
  /// its region and can redraw a spinner frame in place, which is exactly what
  /// [prefixLines] cannot do and why it drops unresolved frames instead.
  ///
  /// Without one — CI, a pipe, a terminal that refused raw mode — it is the
  /// flat prefixed stream, unchanged. That path is the only reason
  /// [prefixLines] still has a caller, and this is the one it has.
  ///
  /// Public so the flat path can be proved without spawning a process. It is
  /// the branch nobody runs by hand, because it is the one CI takes.
  void routeOutput(
    String chunk, {
    required String label,
    required bool isError,
    ServiceSession? session,
  }) {
    if (session != null) {
      session.ingest(chunk, isError: isError);

      return;
    }

    for (final line in prefixLines(chunk, label)) {
      if (isError) {
        logger.err(line);
      } else {
        logger.write('$line\n');
      }
    }
  }

  /// Completes [_fleetGone] if nothing is running any more.
  ///
  /// Re-asked on every exit rather than decided once, which is the whole
  /// difference a restart makes: "the fleet is gone" stopped being a fact about
  /// a fixed set of processes the moment a sixth one could appear after the
  /// first five had been counted.
  void _noticeFleetGone() {
    if (!_fleetArmed) return;
    if (_alive > 0) return;
    if (_fleetGone.isCompleted) return;

    _fleetGone.complete();
  }

  List<StreamSubscription<io.ProcessSignal>> _listenForShutdown() {
    final signals = <StreamSubscription<io.ProcessSignal>>[];

    for (final signal in [
      io.ProcessSignal.sigint,
      if (!io.Platform.isWindows) io.ProcessSignal.sigterm,
    ]) {
      try {
        signals.add(signal.watch().listen((_) => _stop()));
      } catch (_) {
        // Not every platform supports every signal.
      }
    }

    return signals;
  }

  void _stop() {
    if (_stopping) {
      return;
    }
    _stopping = true;

    if (!_useTui) {
      // Under the TUI the rows flipping to `stopped` are the acknowledgement.
      // A line printed here would land on top of the frame nocterm is drawing
      // and be painted over by the next one anyway.
      logger.info('\nStopping ${_running.length} service(s)...');
    }

    for (final process in _running.values) {
      // kill() sends SIGTERM by default, which the generated server drains
      // on -- the behaviour this loop is meant to exercise.
      process.kill();
    }
  }
}

/// The word sent to `revali dev` for each key the TUI binds.
///
/// `_handleDevCommand` in `vm_service_handler.dart` accepts either form — `'r'`
/// or `'reload'`, `'c'` or `'clear'`, `'q'`/`'quit'`/`'exit'` — and ignores
/// anything else *silently*: an unrecognised command falls through to `null`
/// and is dropped, not reported. Getting this wrong therefore looks exactly
/// like a key that does nothing, so one form has to be chosen and held to.
///
/// The word is the one on the wire. It is what every existing call site and
/// `up_command_test.dart` already assert, and it is the form that survives
/// being read out of a `.revali_cmd` file by someone working out why a key did
/// nothing. The TUI's constants stay single letters because that is the
/// keystroke; the translation belongs here, at the edge that owns the file.
const _wireWords = {
  tui.UpCommand.reload: 'reload',
  tui.UpCommand.clear: 'clear',
  tui.UpCommand.quit: 'quit',
};
