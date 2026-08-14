import 'package:nocterm/nocterm.dart';
import 'package:revali/clis/revali_runner/tui/service_style.dart';
import 'package:revali/services/service_session.dart';

/// What the screen says it is doing while the fleet drains.
///
/// A sentence rather than a word because the thing it has to answer is "is
/// this hung?". `revali up` sends every child a SIGTERM and each one drains
/// through its own graceful path, which takes as long as that service's
/// in-flight work takes — seconds, on a fleet with real drain delays. For the
/// whole of it the keys do nothing and the roster barely moves, and there is
/// nothing about that a developer can tell apart from a wedge.
const kShutdownMessage = 'Cleaning up resources, this will take but a moment';

/// What the screen says about the way out.
///
/// The escape hatch has to be *on* the screen that makes you want it. A child
/// that ignores SIGTERM never exits, so without this line the only remaining
/// move is the one nobody should have to guess at.
const kShutdownEscapeHint = '^C again to stop waiting';

/// The word a row carries while its service is still going down.
const kDrainingLabel = 'draining';

/// The whole screen, once `revali up` has asked the fleet to stop.
///
/// It replaces the roster and log pane rather than being appended to them, for
/// the reason the message exists at all: the ordinary screen offers `r`, `c`,
/// `q` and a log that has stopped moving, and every one of those is now a lie.
///
/// Presentation only, like the rest of `tui/`. It reads the same
/// [ServiceSession]s the roster reads and calls nothing back out — the stopping
/// is already under way by the time this is on screen, and a view that could
/// affect it would be a second place shutdown lives.
class ShutdownView extends StatelessComponent {
  const ShutdownView({required this.sessions, super.key});

  /// Every service in the fleet, in the order they were planned — the same
  /// order, and the same colours, the roster used a moment ago. A list that
  /// reordered itself on the way to this screen would make the reader find
  /// their service again at the worst moment to have to.
  final List<ServiceSession> sessions;

  @override
  Component build(BuildContext context) {
    // Measured over the whole fleet so the state column lines up, exactly as
    // the roster measures it.
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
        const Text(''),
        const Text('  $kShutdownMessage'),
        const Text(''),
        for (final (index, session) in sessions.indexed)
          ShutdownRow(session: session, index: index, nameWidth: nameWidth),
        const Text(''),
        const Text(
          '  $kShutdownEscapeHint',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}

/// One service's line on the shutdown screen.
///
/// Listens to its own session, which is the whole point of the row: a screen
/// that said "cleaning up" over a frozen list would be the same hang with a
/// caption on it. The states arrive the same way they always did — the child
/// exits, [ServiceSession.markExited] fires — so what moves here is the real
/// drain, not an animation standing in for one.
class ShutdownRow extends StatelessComponent {
  const ShutdownRow({
    required this.session,
    required this.index,
    required this.nameWidth,
    super.key,
  });

  final ServiceSession session;

  /// Position in the fleet, which is what [serviceColor] keys off — so a
  /// service is the same colour here as it was in the roster.
  final int index;

  /// The width of the widest label, so the state column does not stagger.
  final int nameWidth;

  @override
  Component build(BuildContext context) {
    final color = serviceColor(index);

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              // The label, not the name, for the reason the roster uses it:
              // two packages in one repo can both be called `hello`.
              '    ${session.label.padRight(nameWidth + 3)}',
              style: TextStyle(color: color),
            ),
            Text(
              shutdownStateLabel(session.state),
              style: TextStyle(color: shutdownStateColor(session.state)),
            ),
          ],
        );
      },
    );
  }
}

/// The word [state] gets while the fleet is draining.
///
/// Only a service that is actually on its way down reads as [kDrainingLabel].
/// A [ServiceState.crashed] one exited before the signal was ever sent, and a
/// [ServiceState.failed] one has had no server since it could not take its
/// port — calling either "draining" would claim `revali up` is waiting on
/// something it is not, and would hide the compile error that is the reason
/// the developer is quitting.
///
/// Everything else defers to [stateLabel], so `stopped` and `crashed` read the
/// same on this screen as they did on the roster.
String shutdownStateLabel(ServiceState state) => switch (state) {
  ServiceState.starting ||
  ServiceState.generating ||
  ServiceState.serving => kDrainingLabel,
  ServiceState.failed ||
  ServiceState.crashed ||
  ServiceState.stopped => stateLabel(state),
};

/// The colour of [state]'s word on the shutdown screen.
///
/// Draining is yellow — the same in-flight colour the roster gives `starting`
/// and `generating`, which is what it is. Notably *not* [stateColor]'s answer:
/// a service that was `serving` a moment ago is still green there, and a green
/// row on a screen that says it is shutting down reads as one that has not
/// been asked to.
Color shutdownStateColor(ServiceState state) => switch (state) {
  ServiceState.starting ||
  ServiceState.generating ||
  ServiceState.serving => Colors.yellow,
  ServiceState.failed ||
  ServiceState.crashed ||
  ServiceState.stopped => stateColor(state),
};
