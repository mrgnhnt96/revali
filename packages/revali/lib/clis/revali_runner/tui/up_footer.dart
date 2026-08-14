import 'package:nocterm/nocterm.dart';

/// The key legend along the bottom.
///
/// Spells out the shifted forms rather than leaving them to be discovered:
/// `R`/`C`/`Q` act on the whole fleet, and a developer who reaches for one by
/// accident restarts every service they have running.
class UpFooter extends StatelessComponent {
  const UpFooter({super.key});

  @override
  Component build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Hint('↑↓', 'select'),
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
