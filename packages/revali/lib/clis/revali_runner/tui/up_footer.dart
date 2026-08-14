import 'package:nocterm/nocterm.dart';

/// The key legend along the bottom.
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
class UpFooter extends StatelessComponent {
  const UpFooter({super.key});

  @override
  Component build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Hint('↑↓', 'select'),
        _Hint('jk', 'scroll'),
        _Hint('g', 'live'),
        _Hint('r', 'reload'),
        _Hint('c', 'clear'),
        _Hint('q', 'quit'),
        _Hint('R/C/Q', 'all'),
        _Hint('^C', 'exit'),
      ],
    );
  }
}

class _Hint extends StatelessComponent {
  const _Hint(this.keys, this.description);

  final String keys;
  final String description;

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
        Text(' $description   ', style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
