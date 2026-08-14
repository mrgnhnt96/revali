import 'package:nocterm/nocterm.dart';
import 'package:revali/clis/revali_runner/tui/service_list.dart';
import 'package:revali/clis/revali_runner/tui/service_log.dart';
import 'package:revali/clis/revali_runner/tui/up_footer.dart';
import 'package:revali/services/service_session.dart';

/// What a keypress asks the runner to do to a service.
///
/// Single letters because that is what the running `revali dev` reads. What
/// carrying them to it involves is the runner's business — a component that
/// knew would be a component that could not be tested without a filesystem.
abstract final class UpCommand {
  /// Rebuild and restart.
  static const reload = 'r';

  /// Clear the service's screen.
  static const clear = 'c';

  /// Stop the service.
  static const quit = 'q';
}

/// Signature for acting on one service.
typedef ServiceCommandCallback =
    void Function(ServiceSession session, String command);

/// Signature for acting on every service at once.
typedef FleetCommandCallback = void Function(String command);

/// The `revali up` screen: the roster, the focused service's output, and the
/// key legend.
///
/// Presentation only. It takes sessions in and calls back out; it starts no
/// processes and writes no files, which is what lets the whole of it be proved
/// against a `NoctermTester` with no terminal attached.
class UpApp extends StatefulComponent {
  const UpApp({
    required this.sessions,
    required this.onCommand,
    required this.onCommandAll,
    required this.onQuit,
    super.key,
  });

  /// Every service in the fleet, in the order they were planned — which is
  /// also the order their ports were assigned, and the order each service's
  /// colour is drawn from.
  final List<ServiceSession> sessions;

  /// Called with the focused session for an unshifted `r`, `c` or `q`.
  final ServiceCommandCallback onCommand;

  /// Called for a shifted `R`, `C` or `Q`, which act on the whole fleet.
  final FleetCommandCallback onCommandAll;

  /// Called on `Ctrl+C`: tear the TUI down.
  ///
  /// Distinct from `Q`, which stops the services and leaves the decision about
  /// the screen to whoever is holding it.
  final VoidCallback onQuit;

  @override
  State<UpApp> createState() => _UpAppState();
}

class _UpAppState extends State<UpApp> {
  int _focused = 0;

  ServiceSession? get _session =>
      component.sessions.isEmpty ? null : component.sessions[_focused];

  /// Moves the selection by [delta], wrapping at both ends.
  ///
  /// Wrapping rather than clamping because the list is a handful of services
  /// long: `↑` from the top reaches the last one in a keystroke, and there is
  /// no run of dead keypresses at either end to explain.
  void _move(int delta) {
    final count = component.sessions.length;
    if (count == 0) return;

    setState(() => _focused = (_focused + delta) % count);
  }

  void _select(int index) {
    if (index < 0 || index >= component.sessions.length) return;

    setState(() => _focused = index);
  }

  bool _handleKey(KeyboardEvent event) {
    if (event.isControlPressed) {
      if (event.logicalKey == LogicalKey.keyC) {
        component.onQuit();
        return true;
      }

      // Nothing else is bound with Ctrl held, and letting `Ctrl+r` fall
      // through to the plain `r` branch would reload on a chord nobody meant.
      return false;
    }

    if (event.logicalKey == LogicalKey.arrowUp) {
      _move(-1);
      return true;
    }

    if (event.logicalKey == LogicalKey.arrowDown) {
      _move(1);
      return true;
    }

    final digit = _digitKeys.indexOf(event.logicalKey);
    if (digit != -1) {
      _select(digit);
      return true;
    }

    final command = _commands[event.logicalKey];
    if (command == null) return false;

    if (_isShifted(event)) {
      component.onCommandAll(command);
      return true;
    }

    if (_session case final session?) {
      component.onCommand(session, command);
    }

    return true;
  }

  @override
  Component build(BuildContext context) {
    final session = _session;

    return Focusable(
      focused: true,
      onKeyEvent: _handleKey,
      child: Container(
        decoration: BoxDecoration(
          border: BoxBorder.all(color: Colors.grey),
          title: const BorderTitle(text: ' revali up '),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ServiceList(sessions: component.sessions, focusedIndex: _focused),
            const Divider(),
            Expanded(
              child: session == null
                  ? const Text('No services.')
                  : ServiceLog(session: session, index: _focused),
            ),
            const Divider(),
            const UpFooter(),
          ],
        ),
      ),
    );
  }
}

/// Whether this keypress was the shifted variant of its key.
///
/// A terminal delivers `R` as the *same* [LogicalKey] as `r` carrying the
/// uppercase character, and nocterm's parser infers the shift modifier from
/// that character. The character is therefore the ground truth; the modifier
/// is checked too so a synthesised event carrying only the modifier still
/// reads as shifted.
bool _isShifted(KeyboardEvent event) {
  if (event.character case final char? when char.isNotEmpty) {
    return char != char.toLowerCase();
  }

  return event.modifiers.shift;
}

/// `1`-`9`, selecting by position. A tenth service is reachable with `↑↓`;
/// there is no key left that would not collide with something.
const _digitKeys = [
  LogicalKey.digit1,
  LogicalKey.digit2,
  LogicalKey.digit3,
  LogicalKey.digit4,
  LogicalKey.digit5,
  LogicalKey.digit6,
  LogicalKey.digit7,
  LogicalKey.digit8,
  LogicalKey.digit9,
];

/// A map rather than a `switch`: [LogicalKey] overrides `==`, so its constants
/// are neither valid patterns nor valid constant map keys.
final _commands = {
  LogicalKey.keyR: UpCommand.reload,
  LogicalKey.keyC: UpCommand.clear,
  LogicalKey.keyQ: UpCommand.quit,
};
