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
// Prefixed because the TUI's `UpCommand` — the r/c/q key constants — shares its
// name with the command class below. Unprefixed, the class would shadow it and
// the constants would be unreachable from here.
import 'package:revali/clis/revali_runner/tui/up_app.dart' as tui;
import 'package:revali/services/ansi.dart';
import 'package:revali/services/service_discovery.dart';
import 'package:revali/services/service_plan.dart';
import 'package:revali/services/service_session.dart';

/// Runs every service in the repository at once.
///
/// A system split across five services is five `revali dev` processes in five
/// terminals, which is the point at which people stop running the whole thing
/// locally and start developing one service against staging or mocks. Both
/// hide exactly the mismatches that splitting into services creates — and a
/// system you cannot run is a system you cannot trust to work deployed.
class UpCommand extends Command<int> {
  UpCommand({required this.logger, required this.fs}) {
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

  /// Children, so a signal can reach all of them.
  final _running = <String, io.Process>{};

  var _stopping = false;

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
    final width = plans
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

    final exits = <Future<void>>[];
    final sessions = <ServiceSession>[];

    for (final (index, plan) in plans.indexed) {
      // A session per service only where there is a pane to draw it in.
      // Without one the flat path still owns the output, and a session nobody
      // reads would be a ring buffer filling up for no one.
      final session = _useTui ? ServiceSession(plan) : null;
      if (session != null) {
        sessions.add(session);
      }

      // One service failing to start must not take the others down: the usual
      // cause is a compile error the developer is about to fix, and losing the
      // whole fleet for it makes the loop worse, not safer.
      await _start(plan, colorFor(index), width, exits, session);
    }

    if (exits.isEmpty) {
      logger.err('No service could be started.');

      return 1;
    }

    // A signal here has to reach the children: they are the ones holding
    // ports and in-flight requests, and the generated server already knows
    // how to drain on SIGTERM.
    final signals = _listenForShutdown();

    if (_useTui) {
      return _runTui(plans, sessions, exits, signals);
    }

    await Future.wait(exits);

    for (final subscription in signals) {
      await subscription.cancel();
    }

    return _stopping ? 0 : 1;
  }

  /// Holds the screen until the fleet is gone, drawing it as it goes.
  ///
  /// This is what replaces the flat path's `await Future.wait(exits)`: nocterm
  /// runs its own event loop, so waiting on the children happens alongside it
  /// rather than instead of it.
  Future<int> _runTui(
    List<ServicePlan> plans,
    List<ServiceSession> sessions,
    List<Future<void>> exits,
    List<StreamSubscription<io.ProcessSignal>> signals,
  ) async {
    // A dead fleet must not leave the screen up: there is nothing left to
    // watch and no key that would bring it down, since every command this
    // screen offers is addressed to a process that no longer exists.
    unawaited(
      Future.wait(exits).then((_) => shutdownApp(_stopping ? 0 : 1)),
    );

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
    );
  }

  /// `Ctrl+C`: stop the fleet, and on a second press stop waiting for it.
  ///
  /// The first press is a SIGTERM to every child, not a kill, so each drains
  /// through the same graceful path a `Ctrl+C` at its own terminal would take
  /// — and the screen stays up while they do, which is what makes the drain
  /// something you can watch rather than guess at. The rows going `stopped`
  /// one by one is the acknowledgement; there is no line to print one on.
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

  /// Starts one service, appending its exit future to [exits].
  ///
  /// A service that cannot start adds nothing, so the fleet carries on without
  /// it. The label is padded *before* it is coloured: ANSI escapes count
  /// toward string length, so padding afterwards misaligns every prefix.
  ///
  /// [session] is the pane this service's output belongs to, or null on the
  /// flat path where there are no panes.
  Future<void> _start(
    ServicePlan plan,
    AnsiCode color,
    int width,
    List<Future<void>> exits,
    ServiceSession? session,
  ) async {
    final label = color.wrap(plan.label.padRight(width)) ?? plan.label;

    final io.Process process;
    try {
      process = await io.Process.start(
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

    void pipe(Stream<List<int>> stream, {required bool isError}) {
      stream.transform(utf8.decoder).listen(
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

    exits.add(
      process.exitCode.then<void>((code) {
        _running.remove(plan.label);

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
