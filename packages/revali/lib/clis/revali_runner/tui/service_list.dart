import 'package:nocterm/nocterm.dart';
import 'package:revali/clis/revali_runner/tui/service_style.dart';
import 'package:revali/services/service_session.dart';

/// The roster at the top of the TUI: one row per service, always all of them.
///
/// A crashed service keeps its row. Dropping it would read as the whole fleet
/// going down, and a crash is nearly always a compile error the developer is
/// about to fix — the row is where they look to see it come back.
class ServiceList extends StatelessComponent {
  const ServiceList({
    required this.sessions,
    required this.focusedIndex,
    super.key,
  });

  final List<ServiceSession> sessions;

  /// Which row carries the marker, and whose lines the log pane below shows.
  final int focusedIndex;

  @override
  Component build(BuildContext context) {
    var nameWidth = 0;
    for (final session in sessions) {
      if (session.label.length > nameWidth) {
        nameWidth = session.label.length;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, session) in sessions.indexed)
          ServiceRow(
            session: session,
            index: index,
            focused: index == focusedIndex,
            nameWidth: nameWidth,
          ),
      ],
    );
  }
}

/// One service's line in [ServiceList].
///
/// Listens to its own session rather than leaving the whole screen to rebuild
/// from the top: a fleet of ten all talking at once is ten notifications a
/// frame, and only the row that changed has anything new to draw.
class ServiceRow extends StatelessComponent {
  const ServiceRow({
    required this.session,
    required this.index,
    required this.focused,
    required this.nameWidth,
    super.key,
  });

  final ServiceSession session;

  /// Position in the fleet, which is what [serviceColor] keys off.
  final int index;

  final bool focused;

  /// The width of the widest label, so the columns line up down the list.
  final int nameWidth;

  @override
  Component build(BuildContext context) {
    final color = serviceColor(index);

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final spinner = spinnerFrame(session);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(focused ? '▸ ' : '  ', style: TextStyle(color: color)),
            Text(
              // The label, not the name: two packages in one repo can both be
              // called `hello`, and a list you select rows in has to name each
              // row distinctly. Where names are unique the two are the same
              // string.
              session.label.padRight(nameWidth + 3),
              style: TextStyle(
                color: color,
                fontWeight: focused ? FontWeight.bold : null,
              ),
            ),
            Text(
              // The assigned port. Ports go out in discovery order, which is
              // alphabetical, so which service got the base port is not
              // something worth making anyone work out.
              ':${session.port}'.padRight(8),
            ),
            Text(
              stateLabel(session.state).padRight(11),
              style: TextStyle(color: stateColor(session.state)),
            ),
            if (spinner != null) Text(spinner, style: TextStyle(color: color)),
          ],
        );
      },
    );
  }
}
