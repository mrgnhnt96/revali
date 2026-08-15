import 'package:nocterm/nocterm.dart';
import 'package:revali/clis/revali_runner/tui/service_list.dart';
import 'package:revali/clis/revali_runner/tui/service_log.dart';
import 'package:revali/clis/revali_runner/tui/shutdown_view.dart';
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

  /// Start a service whose process is gone.
  ///
  /// The one key here that is *not* forwarded to a running `revali dev`, and
  /// could not be: there is nothing left to forward it to. It asks the runner
  /// to spawn a new process, which is why it travels by its own callback
  /// instead of joining the map that turns a keystroke into a word in a file.
  ///
  /// `s` for start. `r` is spoken for by reload — and deliberately not reused
  /// for both, since the whole complaint this answers is that one key appeared
  /// to mean two things and silently did nothing for one of them. Of the
  /// letters left, `s` is the one that says what it does, and it collides with
  /// nothing: `j`/`k`/`g` scroll, `r`/`c`/`q` are commands, and `1`-`9` select.
  static const start = 's';
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
    this.onOpenUrl,
    this.onRestart,
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

  /// Called on `Ctrl+C`, every press.
  ///
  /// Two presses mean two different things, and telling them apart is the
  /// runner's business rather than this component's: the first stops the fleet
  /// and the second stops waiting for it. What the screen does with them is
  /// separate — see [_UpAppState._stopping].
  final VoidCallback onQuit;

  /// Called with the URL of a clicked link in the log pane.
  ///
  /// A seam, and the reason the whole of this is provable headlessly: opening a
  /// URL means starting a process, and a component that started one could not
  /// be tested without a browser opening. The runner supplies the real opener;
  /// a test supplies a list to append to and asserts the URL that WOULD have
  /// been opened.
  ///
  /// Null makes every link inert *and* unmarked — see [ServiceLog.onOpenUrl].
  final void Function(String url)? onOpenUrl;

  /// Called with the focused session when `s` is pressed and that service is
  /// dead.
  ///
  /// A seam, for [onOpenUrl]'s reason and one more. Restarting means starting a
  /// process, so a component that did it could not be pumped at without the
  /// suite spawning `dart run revali dev`; and *which* process, with which port
  /// and which environment, is a fact about the plan that this screen has
  /// deliberately never held — it is handed sessions and hands sessions back.
  ///
  /// Only ever called for a session that is [ServiceSession.isDead]. The runner
  /// checks again on its side; this check is here as well so the key and the
  /// legend cannot disagree, since both are decided from the same place.
  ///
  /// Null takes the `s` hint off the legend entirely rather than dimming it —
  /// see [UpFooter.showStart].
  final void Function(ServiceSession session)? onRestart;

  @override
  State<UpApp> createState() => _UpAppState();
}

class _UpAppState extends State<UpApp> {
  int _focused = 0;

  /// Whether the fleet has been asked to go down.
  ///
  /// Kept here rather than read off the runner because it is a fact about what
  /// this screen was told, and every way of telling it is a keystroke this
  /// component already handles. Sourcing it from the runner would mean the
  /// runner reaching back into the view, which is the one direction `tui/` does
  /// not go — and it would put a second hand on `_stop()`, which owns the
  /// shutdown and should keep owning all of it.
  ///
  /// One-way on purpose. There is no path back from a fleet that is draining:
  /// the children have had their SIGTERM and the screen comes down on its own
  /// once they are gone.
  var _stopping = false;

  /// Rows the log pane was last given, so a key can scroll by what is actually
  /// on screen.
  ///
  /// Only the layout knows this, and only at build time — the pane is whatever
  /// is left after the roster, the rules and the legend have taken theirs.
  /// Recorded on the way past rather than pushed through `setState`, because
  /// nothing renders from it: it is read when a key arrives, which is always
  /// after the build that set it.
  var _paneHeight = 0;

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
        // The screen swaps on the way *in* to the callback, so the second
        // press — the one that ends the process from inside [onQuit] — is not
        // relied on to come back and finish a `setState`.
        _enterShutdown();
        component.onQuit();

        return true;
      }

      // Nothing else is bound with Ctrl held, and letting `Ctrl+r` fall
      // through to the plain `r` branch would reload on a chord nobody meant.
      return false;
    }

    // Once the fleet is draining, `^C` is the only live key and the shutdown
    // screen advertises nothing else. Letting `r` through would write a reload
    // to a service that is on its way out — and swallowing it here is what
    // makes "the keys stopped working" a thing the screen said rather than
    // something the reader has to infer from nothing happening.
    if (_stopping) {
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

    if (_handleScroll(event)) return true;

    final digit = _digitKeys.indexOf(event.logicalKey);
    if (digit != -1) {
      _select(digit);
      return true;
    }

    if (_handleStart(event)) return true;

    final command = _commands[event.logicalKey];
    if (command == null) return false;

    // Emptied here, on this side, rather than left to the child's own
    // `ESC[2J` coming back up the pipe. The child writes that sequence on every
    // reload as well, and a pane cannot tell the two apart — see
    // [kRedrawDivider]. This side can: `c` is a keystroke, and a keystroke is
    // only ever a request to clear.
    //
    // Before the callback, not after. The child answers by clearing its screen
    // and reprinting its board, and that reprint must land in the pane this
    // emptied rather than being emptied along with what it replaced.
    if (command == UpCommand.clear) {
      final targets = _isShifted(event)
          ? component.sessions
          : [if (_session case final session?) session];

      for (final session in targets) {
        session.clear();
      }
    }

    if (_isShifted(event)) {
      if (command == UpCommand.quit) {
        // `Q` stops the fleet too — the runner sends every child `quit` *and*
        // calls the same `_stop()` a `Ctrl+C` does. So it is the same drain to
        // sit through, and it would be a strange screen that explained it for
        // one of the two keys that starts it. Unshifted `q` is untouched: that
        // one stops a single service and the fleet carries on.
        _enterShutdown();
      }

      component.onCommandAll(command);

      return true;
    }

    if (_session case final session?) {
      component.onCommand(session, command);
    }

    return true;
  }

  /// Brings the focused service back, if this is `s` and it is gone.
  ///
  /// Returns whether the key was spent here. `s` is spent whenever it arrives
  /// unshifted — including at a service that is still running, where it does
  /// nothing. That is the point: the key is bound, the legend says so, and
  /// letting it fall through would leave it free to mean something else later
  /// at exactly the services where it is most likely to be pressed by mistake.
  ///
  /// Deliberately not in [_commands]. Everything in that map has a shifted
  /// fleet-wide form, and `S` for "start all of them" is not a thing this
  /// screen offers: a fleet-wide restart is several spawns with no way to
  /// report which of them failed, and the ones that were already running would
  /// have to be silently skipped. `S` is left unbound, which is why the shifted
  /// check here returns false rather than falling through to the unshifted
  /// branch.
  bool _handleStart(KeyboardEvent event) {
    if (event.logicalKey != LogicalKey.keyS) return false;
    if (_isShifted(event)) return false;

    final onRestart = component.onRestart;
    if (onRestart == null) return false;

    // Checked here as well as in the runner. The legend draws `s` bright from
    // this same answer, so a key that fired anyway would be the screen saying
    // one thing and doing another — and firing it at a *live* service is the
    // one outcome that would cost a second process.
    if (_session case final session? when session.isDead) {
      onRestart(session);
    }

    return true;
  }

  /// Scrolls the focused pane, if this key is one of the ones that does.
  ///
  /// Returns whether the key was spent here, so a key that is not a scroll key
  /// carries on to the roster and the commands untouched.
  ///
  /// `j`/`k` and `g` are plain unshifted letters on purpose. `↑`/`↓` and `1`-`9`
  /// already move the *selection*, and `r`/`c`/`q` — with their shifted
  /// fleet-wide forms — are spoken for; letters that arrive as ordinary
  /// characters are also the ones this app has already proved a terminal
  /// delivers, which `PageUp` and `PageDown` are not. Those two are bound as
  /// well because they are what a hand reaches for first, but nothing depends
  /// on them: every scroll action has a letter that does the same thing.
  bool _handleScroll(KeyboardEvent event) {
    final session = _session;
    if (session == null) return false;

    // Shifted means "the whole fleet" everywhere else on this screen, and
    // there is no fleet-wide scroll. Letting `J` through would scroll one pane
    // from a key that reads as acting on all of them.
    if (_isShifted(event)) return false;

    // A page keeps one row of overlap, so the line you were reading when you
    // pressed it is still there to pick the thread back up from.
    final page = (_scrollViewport - 1).clamp(1, _scrollViewport);

    final delta = switch (event.logicalKey) {
      LogicalKey.keyK => -1,
      LogicalKey.keyJ => 1,
      LogicalKey.pageUp => -page,
      LogicalKey.pageDown => page,
      LogicalKey.keyG => 0,
      _ => null,
    };

    if (delta == null) return false;

    if (delta == 0) {
      session.scrollToLive();
    } else {
      session.scrollBy(delta, viewport: _scrollViewport);
    }

    return true;
  }

  /// Rows a scroll moves against.
  ///
  /// The pane gives its last row to the "not at the live end" marker the moment
  /// it stops following, so this is the height minus that row — the same number
  /// [ServiceLog] draws with once scrolled, which is the only state where the
  /// anchor is read at all.
  int get _scrollViewport =>
      ServiceLog.viewportFor(_paneHeight, isLive: false).clamp(0, _paneHeight);

  /// Puts the screen into its shutdown state, once.
  void _enterShutdown() {
    if (_stopping) return;

    setState(() => _stopping = true);
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: _handleKey,
      child: Container(
        decoration: BoxDecoration(
          border: BoxBorder.all(color: Colors.grey),
          title: const BorderTitle(text: ' revali up '),
        ),
        // The frame is the same frame; what is inside it is not. The roster,
        // the log pane and the key legend all describe a fleet that is still
        // running, so the drain gets the whole screen rather than a line
        // appended to one that has stopped being true.
        child: _stopping
            ? ShutdownView(sessions: component.sessions)
            : _buildFleet(),
      ),
    );
  }

  /// The running screen: the roster, the focused service's output, the legend.
  Component _buildFleet() {
    final session = _session;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ServiceList(
          sessions: component.sessions,
          focusedIndex: _focused,
          // Clicking a row lands in the same place `↑`/`↓` and `1`-`9` land, so
          // there is one definition of what selecting a service means and a
          // click cannot drift from a keypress.
          onSelect: _select,
        ),
        const Divider(),
        Expanded(
          child: session == null
              ? const Text('No services.')
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final height = constraints.maxHeight.floor();
                    _paneHeight = height;

                    return ServiceLog(
                      session: session,
                      index: _focused,
                      height: height,
                      onOpenUrl: component.onOpenUrl,
                    );
                  },
                ),
        ),
        const Divider(),
        // Listening, not read once. The legend describes the focused service's
        // *current* state, and the thing that changes that state is the child's
        // output arriving — not a keystroke. Built off `session.state` at build
        // time alone, the line would go on advertising `r reload` at a service
        // that crashed until the next key was pressed, which is the stale
        // legend this replaces wearing a different disguise.
        if (session == null)
          UpFooter(
            state: null,
            showStart: component.onRestart != null,
            canSelect: component.sessions.length > 1,
          )
        else
          ListenableBuilder(
            listenable: session,
            builder: (context, _) => UpFooter(
              state: session.state,
              showStart: component.onRestart != null,
              canSelect: component.sessions.length > 1,
            ),
          ),
      ],
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
