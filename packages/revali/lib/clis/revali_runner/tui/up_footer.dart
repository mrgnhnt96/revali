import 'package:nocterm/nocterm.dart';
import 'package:revali/services/service_session.dart';

/// The key legend along the bottom, cut down to what can actually be pressed
/// right now.
///
/// Spells out the shifted forms rather than leaving them to be discovered:
/// `R`/`C`/`Q` act on the whole fleet, and a developer who reaches for one by
/// accident restarts every service they have running.
///
/// `j`/`k` and `g` are here for the opposite reason — nothing on screen implies
/// a pane can be scrolled at all until it has been, so this line is the only
/// place they exist to be found. The wheel is not listed: it needs no
/// discovering, and a legend that named every way in would be longer than the
/// screen is wide.
///
/// Clicking is not listed either, and for the wheel's reason turned around: an
/// underlined URL already advertises itself where it is, which is a better
/// place to say it than a legend eight hints along. A roster row has no mark —
/// but a click there only moves the selection `↑`/`↓` already moves, so nothing
/// is unreachable if it is never discovered.
///
/// ## Why omit rather than dim
///
/// A hint that would do nothing in the current state is not drawn at all. This
/// line went the other way first — every hint in every state, the inapplicable
/// ones greyed — on the reasoning that a legend whose items move under the
/// reader's eye is harder to use than a static one. That was overruled, and the
/// reasoning it rests on is the part that was wrong: dim is not a state most
/// readers can distinguish from "available" at a glance in a terminal whose
/// palette they chose themselves, so the dim `r reload` beside a bright
/// `s start` did not stop reading as an offer. Advertising a key that does
/// nothing is the worse failure of the two, and it is the complaint this line
/// exists to answer.
///
/// So: do not restore dimming here. `enabled` is gone from [_Hint] deliberately
/// — an absent hint is the design, not an oversight, and the argument for the
/// old behaviour is preserved in this paragraph precisely so it does not get
/// made again from scratch.
///
/// The keys that apply whatever the focused service is doing are still drawn
/// unconditionally: the fleet-wide `R`/`C`/`Q`, `^C` — especially `^C`, since
/// it is the way out — `c`, and the scroll keys, which address the log pane
/// rather than the process and work at a corpse as well as at a live server.
///
/// ## Why the gaps are one space
///
/// The widest this line can get is eight hints — the live-service state, with
/// the fleet selectable — which is 68 columns of text against the 78 the frame
/// leaves on the 80-column terminal this screen is drawn for. Two spaces
/// between them does not fit at that width, and an earlier version of this line
/// really did run off the right border and clip `^C exit` to `^C e`. One space
/// fits with ten to spare, and the separating work whitespace would have done
/// is done instead by the alternation the hints already have: a bold key
/// against a grey description. Omitting hints only ever shortens the line, so
/// no state reachable here is wider than that 68.
class UpFooter extends StatelessComponent {
  const UpFooter({
    required this.state,
    this.showStart = false,
    this.canSelect = false,
    super.key,
  });

  /// Where the focused service is, or null when there is no focused service.
  ///
  /// The state rather than the session, so this component is a pure function of
  /// what it is handed and can be pumped at directly. Keeping it live is the
  /// caller's job — see the `ListenableBuilder` in `up_app.dart`, without which
  /// this line would still describe the service as it was at the last keypress.
  final ServiceState? state;

  /// Whether the runner wired a way to start a dead service.
  ///
  /// False leaves the `s` hint off the line whatever the focused service is
  /// doing, which is `UpApp.onOpenUrl`'s rule: a key with nothing behind it is
  /// not a key that is unavailable right now, it is a key that does not exist.
  final bool showStart;

  /// Whether there is more than one service to move between.
  ///
  /// `↑`/`↓` wrap within the roster, so at a fleet of one they land back where
  /// they started — see `_move` in `up_app.dart`, whose modulo is a no-op at a
  /// count of one. A key that cannot move the selection is not offered.
  final bool canSelect;

  /// Whether a keystroke addressed to the focused service would reach anything.
  ///
  /// `r` and `q` both travel by writing the service's `.revali_cmd`, which the
  /// running `revali dev` is watching. Once that process is gone the file is a
  /// write into the void — see `_handleDevCommandFile` in
  /// `vm_service_handler.dart`, which is the thing that is no longer there to
  /// read it.
  bool get _reachable => state != null && !state!.isDead;

  /// Whether `s` would do anything: there is a service, and it is gone.
  bool get _startable => state != null && state!.isDead;

  @override
  Component build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canSelect) const _Hint('↑↓', 'select'),
        // Scrolling is always live. A dead service still has a pane to read,
        // which is most of why its row is kept at all.
        const _Hint('jk', 'scroll'),
        const _Hint('g', 'live'),
        if (_reachable) const _Hint('r', 'reload'),
        if (showStart && _startable) const _Hint('s', 'start'),
        // `c` empties the pane on this side before it forwards anything, so it
        // does something visible even for a service that will never answer.
        const _Hint('c', 'clear'),
        if (_reachable) const _Hint('q', 'quit'),
        const _Hint('R/C/Q', 'all'),
        const _Hint('^C', 'exit', last: true),
      ],
    );
  }
}

class _Hint extends StatelessComponent {
  const _Hint(this.keys, this.description, {this.last = false});

  final String keys;
  final String description;

  /// Whether this is the last hint, which is the one that does not pay for a
  /// gap after it — the column it would spend is the border's.
  ///
  /// Fixed rather than computed because the last hint is always `^C exit`: it
  /// is drawn in every state, so no omission above it can leave a different
  /// hint on the end holding a trailing space.
  final bool last;

  @override
  Component build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          keys,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          ' $description${last ? '' : ' '}',
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
