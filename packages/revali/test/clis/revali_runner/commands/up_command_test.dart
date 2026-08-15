import 'dart:io' as io;

import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
// Hidden rather than prefixed: nocterm exports its own `isEmpty`/`isNotEmpty`,
// which would shadow the matchers this file asserts with, and its own `Logger`,
// which would collide with `mason_logger`'s.
import 'package:nocterm/nocterm.dart' hide Logger, isEmpty, isNotEmpty;
import 'package:path/path.dart' as p;
import 'package:platform/platform.dart';
import 'package:revali/clis/revali_runner/commands/up_command.dart';
// Prefixed for the same reason `up_command.dart` prefixes it: the TUI's
// `UpCommand` key constants share their name with the command class.
import 'package:revali/clis/revali_runner/tui/up_app.dart' as tui;
import 'package:revali/services/ansi.dart';
import 'package:revali/services/service_discovery.dart';
import 'package:revali/services/service_plan.dart';
import 'package:revali/services/service_session.dart';
import 'package:test/test.dart';

/// `revali up` forwarding `r` / `c` / `q` to its children.
///
/// The keys could not simply be piped through: a child's stdin is a pipe, not
/// a terminal, so `revali dev` inside it takes its headless path and never
/// reads keystrokes. Pressing `r` under `revali up` did nothing, while
/// file-watching reload worked — which is what made it look like reload was
/// fine.
///
/// `revali dev` already watches a `.revali_cmd` file when it has no TTY, so
/// the fix writes that file rather than adding a second channel. These tests
/// pin the half that is testable without spawning processes: that the right
/// word lands in the right file, for every service.
///
/// The words here must stay in step with `_handleDevCommand` in
/// `vm_service_handler.dart`, which is the code that reads them.
void main() {
  late MemoryFileSystem fs;
  late UpCommand command;

  setUp(() {
    fs = MemoryFileSystem.test();
    command = UpCommand(logger: Logger(), fs: fs);
  });

  ServicePlan planFor(String name, {int port = 8080}) {
    final directory = fs.directory('/repo/$name')..createSync(recursive: true);

    return ServicePlan(
      service: RevaliService(
        name: name,
        directory: directory,
        relativePath: name,
      ),
      port: port,
      label: name,
    );
  }

  String cmdFileOf(ServicePlan plan) =>
      fs.file(p.join(plan.service.directory.path, '.revali_cmd')).existsSync()
      ? fs
            .file(p.join(plan.service.directory.path, '.revali_cmd'))
            .readAsStringSync()
      : '<missing>';

  test('a command can be addressed to one service, leaving the rest alone', () {
    final orders = planFor('orders');
    final billing = planFor('billing', port: 8081);

    command.sendCommand(orders, 'reload');

    expect(cmdFileOf(orders), 'reload\n');

    // The whole point of addressing one service: reloading `orders` must not
    // restart `billing` as collateral. A broadcast cannot express this.
    expect(
      cmdFileOf(billing),
      '<missing>',
      reason: 'billing was not addressed and should not have been signalled',
    );

    // The converse still holds: a broadcast reaches the ones a send skipped.
    command.broadcastCommand([orders, billing], 'quit');

    expect(cmdFileOf(orders), 'quit\n');
    expect(cmdFileOf(billing), 'quit\n');
  });

  test('a command reaches every service, not just the first', () {
    final plans = [planFor('orders'), planFor('billing'), planFor('users')];

    command.broadcastCommand(plans, 'reload');

    for (final plan in plans) {
      expect(
        cmdFileOf(plan),
        'reload\n',
        reason: '${plan.label} should have been signalled',
      );
    }
  });

  test('the file lands in each service directory, not a shared one', () {
    final plans = [planFor('orders'), planFor('billing')];

    command.broadcastCommand(plans, 'quit');

    expect(fs.file('/repo/orders/.revali_cmd').existsSync(), isTrue);
    expect(fs.file('/repo/billing/.revali_cmd').existsSync(), isTrue);

    // A single file at the root would be read by whichever service noticed
    // first and truncated before the others saw it.
    expect(fs.file('/repo/.revali_cmd').existsSync(), isFalse);
  });

  test('the command is newline-terminated', () {
    final plans = [planFor('orders')];

    command.broadcastCommand(plans, 'clear');

    // The reader splits on line breaks and truncates the file as it goes. A
    // bare token with no terminator is one read away from arriving half
    // written.
    expect(cmdFileOf(plans.single), endsWith('\n'));
  });

  test('a later command replaces an earlier one', () {
    final plans = [planFor('orders')];

    command
      ..broadcastCommand(plans, 'reload')
      ..broadcastCommand(plans, 'quit');

    // Appending would leave a stale `reload` for the reader to act on after
    // the quit.
    expect(cmdFileOf(plans.single), 'quit\n');
  });

  test('every word written is one the dev runner understands', () {
    // These are the tokens `_handleDevCommand` in vm_service_handler.dart
    // accepts. A rename on either side silently stops the keys working, since
    // an unrecognised command is ignored rather than reported.
    const understood = {'reload', 'clear', 'quit'};

    final plans = [planFor('orders')];

    for (final word in understood) {
      command.broadcastCommand(plans, word);
      expect(cmdFileOf(plans.single).trim(), word);
    }
  });

  test('an unwritable service does not stop the others being signalled', () {
    final good = planFor('orders');

    // A service whose directory does not exist stands in for one that cannot
    // be written to. Losing the whole broadcast over it would mean one broken
    // checkout disables the keys for the entire fleet.
    final missing = ServicePlan(
      service: RevaliService(
        name: 'ghost',
        directory: fs.directory('/repo/ghost/nested/deep'),
        relativePath: 'ghost',
      ),
      port: 8081,
      label: 'ghost',
    );

    command.broadcastCommand([missing, good], 'reload');

    expect(cmdFileOf(good), 'reload\n');
  });

  test('every key the TUI binds goes on the wire as a word, not a letter', () {
    // Both forms reach `_handleDevCommand`, which is what makes picking the
    // wrong one so quiet: it drops what it does not recognise without a word,
    // so a mismatch looks exactly like a key that does nothing. One form has
    // to be chosen, and the word is it — that is what every call site above
    // and the reader on the other end already agree on.
    const understood = {'reload', 'clear', 'quit'};

    for (final key in [
      tui.UpCommand.reload,
      tui.UpCommand.clear,
      tui.UpCommand.quit,
    ]) {
      expect(
        key.length,
        1,
        reason: 'the TUI binds keystrokes; the translation happens at the file',
      );

      expect(
        understood,
        contains(command.wireWordFor(key)),
        reason: '"$key" must arrive as something the dev runner acts on',
      );
    }
  });

  group('the screen is wired to the fleet', () {
    /// Pumps the app the runner would have handed to `runApp`.
    Future<NoctermTester> pump(List<ServiceSession> sessions) async {
      final tester = await NoctermTester.create();
      addTearDown(tester.dispose);

      await tester.pumpComponent(
        command.buildApp(sessions.map((s) => s.plan).toList(), sessions),
      );

      return tester;
    }

    test('a key reaches the focused service and only that one', () async {
      final billing = ServiceSession(planFor('billing'));
      final orders = ServiceSession(planFor('orders', port: 8081));

      final tester = await pump([billing, orders]);

      await tester.sendKey(LogicalKey.arrowDown);
      await tester.sendKey(LogicalKey.keyR);

      // The word, not the letter the key carries: both are accepted by the
      // reader, and a mismatch would be dropped in silence.
      expect(cmdFileOf(orders.plan), 'reload\n');
      expect(
        cmdFileOf(billing.plan),
        '<missing>',
        reason: 'reloading one service must not restart the rest',
      );
    });

    test('a shifted key reaches every service', () async {
      final billing = ServiceSession(planFor('billing'));
      final orders = ServiceSession(planFor('orders', port: 8081));

      final tester = await pump([billing, orders]);

      await tester.sendKeyEvent(
        // A terminal delivers `R` as the same logical key carrying the
        // uppercase character.
        const KeyboardEvent(
          logicalKey: LogicalKey.keyR,
          character: 'R',
          modifiers: ModifierKeys(shift: true),
        ),
      );

      expect(cmdFileOf(billing.plan), 'reload\n');
      expect(cmdFileOf(orders.plan), 'reload\n');
    });

    test('every key the screen binds lands as a word', () async {
      final orders = ServiceSession(planFor('orders'));

      final tester = await pump([orders]);

      for (final (key, word) in [
        (LogicalKey.keyR, 'reload'),
        (LogicalKey.keyC, 'clear'),
        (LogicalKey.keyQ, 'quit'),
      ]) {
        await tester.sendKey(key);

        expect(cmdFileOf(orders.plan), '$word\n');
      }
    });
  });

  group('opening a clicked link', () {
    /// All three branches from one machine. Two of them are unreachable on any
    /// given developer's laptop and would otherwise be found broken by a user.
    ///
    /// Destructured rather than compared as a record: a record's `==` compares
    /// its fields with `==`, and two equal `List`s are not `==`.
    void expectOpener(
      String os, {
      required String executable,
      required List<String> arguments,
    }) {
      final (actualExecutable, actualArguments) = UpCommand.openerFor(
        'http://localhost:8080/api',
        platform: FakePlatform(operatingSystem: os),
      );

      expect(actualExecutable, executable);
      expect(actualArguments, arguments);
    }

    test('macOS opens with `open`', () {
      expectOpener(
        'macos',
        executable: 'open',
        arguments: ['http://localhost:8080/api'],
      );
    });

    test('Linux opens with `xdg-open`', () {
      expectOpener(
        'linux',
        executable: 'xdg-open',
        arguments: ['http://localhost:8080/api'],
      );
    });

    test('Windows goes through `cmd /c start` with an empty title', () {
      // `start` is a shell builtin, not an executable, and without the empty
      // title argument it reads the URL as the window title and opens nothing.
      expectOpener(
        'windows',
        executable: 'cmd',
        arguments: ['/c', 'start', '', 'http://localhost:8080/api'],
      );
    });

    test('the screen the runner builds has an opener wired to it', () async {
      // The seam is only worth having if the real screen actually carries it:
      // a null `onOpenUrl` makes every link inert AND unmarked, which would
      // read in a test exactly like a link that was never found.
      final billing = ServiceSession(planFor('billing'))
        ..ingest('Serving at http://0.0.0.0:8080/api\n', isError: false);

      expect(command.buildApp([billing.plan], [billing]).onOpenUrl, isNotNull);
    });
  });

  group('the colour handshake with the child', () {
    test('the fleet still hands every child its assigned port', () {
      expect(
        command.childEnvironment(planFor('orders', port: 8081), useTui: true),
        containsPair('PORT', '8081'),
      );
      expect(
        command.childEnvironment(planFor('billing'), useTui: false),
        containsPair('PORT', '8080'),
      );
    });

    test('asks for colour where a pane is going to paint it', () {
      // Without this the child sees a pipe, `ansiOutputEnabled` is false, and
      // it emits plain text -- so the pane has no colour to render however
      // well it renders.
      expect(
        command.childEnvironment(planFor('orders'), useTui: true),
        containsPair(kForceAnsiEnvVar, '1'),
      );
    });

    test('does not ask for it on the flat path', () {
      // The regression most likely to ship unnoticed. That path's pipe is not
      // an implementation detail -- it is the build log CI reads, and escape
      // sequences in one are exactly what the flat path exists to avoid.
      expect(
        command.childEnvironment(planFor('orders'), useTui: false),
        isNot(contains(kForceAnsiEnvVar)),
      );
    });
  });

  group('output routing', () {
    ServicePlan plan() => planFor('orders');

    test('no terminal means no TUI', () {
      // Where CI stands: `dart test` pipes this process's output, so there is
      // no terminal to draw on. Making the TUI unconditional would take the
      // flat output below away and leave a pipeline with nothing at all.
      expect(command.canDrawTui(), isFalse);
    });

    /// Runs [body] with a [Logger] whose streams are captured.
    ///
    /// The logger has to be *built* inside the override: `mason_logger` reads
    /// `IOOverrides.current` once, in a field initialiser, so one constructed
    /// outside would keep writing to the real terminal.
    ({String out, String err}) captured(void Function(UpCommand) body) {
      final out = _FakeStdout();
      final err = _FakeStdout();

      io.IOOverrides.runZoned(
        () => body(UpCommand(logger: Logger(), fs: fs)),
        stdout: () => out,
        stderr: () => err,
      );

      return (out: '$out', err: '$err');
    }

    test('without a pane, output is the flat prefixed stream', () {
      // The regression most likely to ship unnoticed: this is CI's path, and
      // nobody runs it by hand. A TUI made unconditional would take it away
      // and `revali up` would produce nothing at all in a pipeline.
      final result = captured(
        (command) => command.routeOutput(
          'listening\nready\n',
          label: 'orders',
          isError: false,
        ),
      );

      expect(result.out, 'orders | listening\norders | ready\n');
    });

    test('without a pane, stderr still goes to stderr', () {
      final result = captured(
        (command) =>
            command.routeOutput('boom\n', label: 'orders', isError: true),
      );

      // Styled red on the way out, so the prefix is what can be asserted on.
      expect(result.err, contains('orders | boom'));
      expect(
        result.out,
        isEmpty,
        reason: 'an error on stdout would be invisible to `2>` in CI',
      );
    });

    test('without a pane, an unresolved spinner frame is still dropped', () {
      final result = captured(
        (command) => command.routeOutput(
          '⠋ Generating server code...',
          label: 'orders',
          isError: false,
        ),
      );

      // A shared append-only stream cannot redraw in place, so every frame
      // would become a permanent line. This is the whole reason `prefixLines`
      // exists, and the flat path is the only caller it has left.
      expect(result.out, isEmpty);
    });

    test('with a pane, the chunk goes to the session and nowhere else', () {
      final session = ServiceSession(plan());

      final result = captured(
        (command) => command.routeOutput(
          'listening\n',
          label: 'orders',
          isError: false,
          session: session,
        ),
      );

      expect(session.lines, [
        const ServiceLogLine('listening', isError: false),
      ]);

      // A second copy on the shared stream would paint over the frame nocterm
      // is drawing.
      expect(result.out, isEmpty);
      expect(result.err, isEmpty);
    });

    test('with a pane, an unresolved spinner frame is kept', () {
      final session = ServiceSession(plan());

      captured(
        (command) => command.routeOutput(
          '⠋ Generating server code...',
          label: 'orders',
          isError: false,
          session: session,
        ),
      );

      // The pane owns its region and redraws in place, so the frame the child
      // is still painting is worth holding — dropping it, as the flat path
      // must, would leave the pane looking idle mid-build.
      expect(session.lines, [
        const ServiceLogLine('⠋ Generating server code...', isError: false),
      ]);
    });

    test('with a pane, stderr keeps its stream so it can be styled', () {
      final session = ServiceSession(plan());

      captured(
        (command) => command.routeOutput(
          'boom\n',
          label: 'orders',
          isError: true,
          session: session,
        ),
      );

      expect(session.lines.single.isError, isTrue);
    });
  });
}

/// A [io.Stdout] that keeps what was written to it.
///
/// `noSuchMethod` covers the rest of the interface: nothing under test touches
/// the terminal-shaped half of it, and spelling out forty members to say so
/// would bury the four that matter.
class _FakeStdout implements io.Stdout {
  final _buffer = StringBuffer();

  @override
  void write(Object? object) => _buffer.write(object);

  @override
  void writeln([Object? object = '']) => _buffer.writeln(object);

  @override
  bool get hasTerminal => false;

  @override
  bool get supportsAnsiEscapes => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  String toString() => _buffer.toString();
}
