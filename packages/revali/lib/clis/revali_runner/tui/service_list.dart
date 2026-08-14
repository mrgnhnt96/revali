import 'package:nocterm/nocterm.dart';
import 'package:revali/clis/revali_runner/tui/service_style.dart';
import 'package:revali/services/service_session.dart';

/// How many roster rows are on screen at once, however big the fleet is.
///
/// Three, because the log pane underneath is the reason `revali up` exists and
/// the roster is only the way you choose what it shows. On the 80x24 terminal
/// the TUI is drawn for, the borders, divider and footer already spend six
/// rows; a roster that grew with the fleet would have ten services leaving the
/// output four lines to live in. Three is also the smallest window that still
/// shows a neighbour either side of the focused row, so `↑`/`↓` moves against
/// visible context rather than into a blank.
const kVisibleServiceRows = 3;

/// The roster at the top of the TUI: one row per service, capped at
/// [kVisibleServiceRows] rows and scrolled to keep the focused one on screen.
///
/// Only the VIEW is capped. Selection is over the whole fleet — `↑`/`↓` and
/// `1`-`9` reach a service that is scrolled out of sight, and reaching it
/// brings it into view.
///
/// A crashed service keeps its row. Dropping it would read as the whole fleet
/// going down, and a crash is nearly always a compile error the developer is
/// about to fix — the row is where they look to see it come back.
class ServiceList extends StatelessComponent {
  const ServiceList({
    required this.sessions,
    required this.focusedIndex,
    this.onSelect,
    super.key,
  });

  final List<ServiceSession> sessions;

  /// Which row carries the marker, and whose lines the log pane below shows.
  final int focusedIndex;

  /// Called with the fleet index of a clicked row.
  ///
  /// The index into [sessions], not into the visible window. Which row is which
  /// service is settled by the loop that builds them — the same loop that
  /// already knows [windowStart] — so a scrolled roster cannot select the wrong
  /// one, and there is no second place that would have to be kept in step.
  final void Function(int index)? onSelect;

  /// The first row of the visible window.
  ///
  /// Derived from [focusedIndex] rather than tracked as scroll state, which is
  /// what makes "the focused row is visible" an invariant of the render
  /// instead of a post-condition of a scroll that has to have happened. There
  /// is no ordering, no attachment and no frame delay that can strand the
  /// selection off-screen: a window that did not contain it is not reachable.
  ///
  /// The focused row is centred where it can be, and pinned at the ends, so
  /// walking off the bottom does not leave the marker stuck to the last line.
  ///
  /// nocterm's `ListView` + `AutoScrollController` was tried first and does not
  /// hold that invariant: rows in a three-tall `SizedBox` open on the *bottom*
  /// of the list, so a nine-service fleet renders `golf, hotel, india` with the
  /// marker on `alpha`, off-screen, before any key is pressed.
  /// `ensureIndexVisible` cannot save it — nothing has changed focus yet, so it
  /// has not been called.
  int get windowStart {
    final overflow = sessions.length - kVisibleServiceRows;
    if (overflow <= 0) return 0;

    return (focusedIndex - kVisibleServiceRows ~/ 2).clamp(0, overflow);
  }

  @override
  Component build(BuildContext context) {
    // Measured over the whole fleet, not the window, so the columns do not
    // jump sideways as rows scroll past.
    var nameWidth = 0;
    for (final session in sessions) {
      if (session.label.length > nameWidth) {
        nameWidth = session.label.length;
      }
    }

    final start = windowStart;
    final end = (start + kVisibleServiceRows).clamp(0, sessions.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = start; index < end; index++)
          if (onSelect case final onSelect?)
            // Wrapped rather than given an `onTap` of its own, so a row built
            // without a handler is the same widget it always was.
            GestureDetector(
              onTap: () => onSelect(index),
              child: ServiceRow(
                session: sessions[index],
                index: index,
                focused: index == focusedIndex,
                nameWidth: nameWidth,
              ),
            )
          else
            ServiceRow(
              session: sessions[index],
              index: index,
              focused: index == focusedIndex,
              nameWidth: nameWidth,
            ),
        if (sessions.length > kVisibleServiceRows)
          RosterScrollHint(
            start: start,
            end: end,
            total: sessions.length,
          ),
      ],
    );
  }
}

/// The line under a roster that does not fit, naming the window it is showing.
///
/// A range and a total rather than a scrollbar or bare `▲`/`▼` markers. All
/// three say "there is more"; only the range also says *how much* more and
/// *where you are in it* — and this list is selected by number, so the reader
/// whose `1`-`9` press is about to jump somewhere off-screen is told which
/// positions are under their eyes and which are not. A one-column scrollbar
/// beside three rows is close to invisible, and arrows alone leave "3 of 4" and
/// "3 of 40" looking identical.
class RosterScrollHint extends StatelessComponent {
  const RosterScrollHint({
    required this.start,
    required this.end,
    required this.total,
    super.key,
  });

  /// First visible row, zero-based; [end] is exclusive.
  final int start;
  final int end;

  /// Services in the whole fleet.
  final int total;

  @override
  Component build(BuildContext context) {
    // Positions, not indices: the roster is selected with `1`-`9`, so the
    // numbers here have to be the ones on the keys.
    final above = start > 0;
    final below = end < total;

    return Text(
      '  ${above ? '▲' : ' '}${below ? '▼' : ' '} '
      'showing ${start + 1}-$end of $total services',
      style: const TextStyle(color: Colors.grey),
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
