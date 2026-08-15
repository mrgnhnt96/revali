import 'package:nocterm/nocterm.dart';
import 'package:revali/services/service_session.dart';

/// The key legend along the bottom, dimmed to what the focused service can
/// actually do right now.
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
/// ## Why dim rather than hide
///
/// Every hint is drawn in every state, in the same order, at the same column;
/// the ones that would do nothing are drawn dim. Hiding them, or moving the
/// applicable one to the front, would make this line move under the reader's
/// eyes exactly when they are looking something up — and a legend whose items
/// are in a different place each time you read it is worse than one that is
/// simply wrong. Dimming answers the actual complaint, which is not "`r` is
/// missing" but "`r` is offered and does nothing, so the key must be broken":
/// a dim `r reload` beside a bright `s start` says which one to press *and*
/// that the other one still exists.
///
/// The fleet-wide keys and `^C` are never dimmed. They apply whatever the
/// focused service is doing — `^C` especially, since it is the way out.
///
/// ## Why the gaps are one space
///
/// Nine hints is 68 columns of text, and the frame leaves 78 on the 80-column
/// terminal this screen is drawn for. Two spaces between them does not fit, and
/// the version of this line before the start key was added already ran off the
/// right border and clipped `^C exit` to `^C e`. One space fits with two to
/// spare, and the separating work whitespace would have done is done instead by
/// the alternation the hints already have: a bold key against a grey
/// description. Dropping a hint to buy the wider gap was the alternative, and
/// every one of them is a key someone has to be able to find.
class UpFooter extends StatelessComponent {
  const UpFooter({required this.state, this.showStart = false, super.key});

  /// Where the focused service is, or null when there is no focused service.
  ///
  /// The state rather than the session, so this component is a pure function of
  /// what it is handed and can be pumped at directly. Keeping it live is the
  /// caller's job — see the `ListenableBuilder` in `up_app.dart`, without which
  /// this line would still describe the service as it was at the last keypress.
  final ServiceState? state;

  /// Whether the runner wired a way to start a dead service.
  ///
  /// False leaves the `s` hint off the line entirely rather than drawing it
  /// dim, which is `UpApp.onOpenUrl`'s rule and for its reason: a key with
  /// nothing behind it is not a key that is unavailable right now, it is a key
  /// that does not exist, and advertising it dim would promise a state it can
  /// never reach. This is fixed for the lifetime of the screen, so it moves
  /// nothing as states change.
  final bool showStart;

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
        // Selecting and scrolling are always live. A dead service still has a
        // row to move to and a pane to read, which is most of why its row is
        // kept at all.
        const _Hint('↑↓', 'select'),
        const _Hint('jk', 'scroll'),
        const _Hint('g', 'live'),
        _Hint('r', 'reload', enabled: _reachable),
        if (showStart) _Hint('s', 'start', enabled: _startable),
        // `c` empties the pane on this side before it forwards anything, so it
        // does something visible even for a service that will never answer.
        const _Hint('c', 'clear'),
        _Hint('q', 'quit', enabled: _reachable),
        const _Hint('R/C/Q', 'all'),
        const _Hint('^C', 'exit', last: true),
      ],
    );
  }
}

class _Hint extends StatelessComponent {
  const _Hint(
    this.keys,
    this.description, {
    this.enabled = true,
    this.last = false,
  });

  final String keys;
  final String description;

  /// Whether pressing this key right now would do anything.
  final bool enabled;

  /// Whether this is the last hint, which is the one that does not pay for a
  /// gap after it — the column it would spend is the border's.
  final bool last;

  @override
  Component build(BuildContext context) {
    // Dimmer than the grey a description is normally drawn in, so a disabled
    // hint reads as *behind* the line rather than as another part of it. The
    // key loses its weight as well: bold is what makes a key look pressable,
    // and leaving it on a key that is not would be the legend arguing with
    // itself.
    final keyStyle = enabled
        ? const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        : const TextStyle(color: Colors.brightBlack);
    final textStyle = TextStyle(
      color: enabled ? Colors.grey : Colors.brightBlack,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(keys, style: keyStyle),
        Text(' $description${last ? '' : ' '}', style: textStyle),
      ],
    );
  }
}
