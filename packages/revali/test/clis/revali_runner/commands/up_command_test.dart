import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:revali/clis/revali_runner/commands/up_command.dart';
import 'package:revali/services/service_discovery.dart';
import 'package:revali/services/service_plan.dart';
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
}
