import 'package:nocterm/nocterm.dart';
import 'package:revali/clis/revali_runner/tui/service_style.dart';
import 'package:revali/services/ansi.dart';
import 'package:revali/services/service_session.dart';

/// The focused service's output, and nothing else's.
///
/// The pane owns its region, so an unresolved spinner frame can be redrawn in
/// place instead of being dropped — one `⠋ Retrieving…` animating rather than
/// twenty stacked. That is the whole reason a service gets a pane rather than
/// a share of one append-only stream.
///
/// There is no `name | ` prefix on these lines. The pane already belongs to
/// one service, so the prefix would repeat on every line what the rail down
/// the left says once.
///
/// Lines arrive as the child wrote them, escape sequences and all — the session
/// stores what it was sent — so this is where they are read. Colour is turned
/// into styled spans; everything else is dropped. Painting the raw text instead
/// is what put `[2J[0;0H` on the screen as characters.
class ServiceLog extends StatelessComponent {
  const ServiceLog({required this.session, required this.index, super.key});

  final ServiceSession session;

  /// Position in the fleet, so the rail matches the row above.
  final int index;

  @override
  Component build(BuildContext context) {
    final color = serviceColor(index);

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final lines = session.lines;
          final height = constraints.maxHeight.floor();

          // The tail. A pane shows what just happened, and the newest line is
          // the one being painted right now; scrolling further back than the
          // pane is high is what the log file is for.
          final visible = height <= 0
              ? const <ServiceLogLine>[]
              : lines.length <= height
              ? lines
              : lines.sublist(lines.length - height);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final line in visible)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('│ ', style: TextStyle(color: color)),
                    RichText(
                      text: TextSpan(
                        children: [
                          for (final span in parseAnsi(line.text))
                            TextSpan(
                              text: span.text,
                              style: _styleFor(span, isError: line.isError),
                            ),
                        ],
                      ),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

/// How one run of a child's output is painted.
///
/// The child's own colour wins wherever it chose one. That is the whole point
/// of asking it for colour: `mason_logger` already says which part of a line is
/// the result and which is the elapsed time, and re-deciding here would throw
/// that away and paint the line back to one flat colour.
///
/// The stderr grey is therefore a *fallback*, for the runs the child left
/// default. It is grey and not red because a child writing progress to stderr
/// is ordinary and does not mean anything went wrong — red would lie about most
/// of what lands here.
///
/// SGR 2 has no counterpart in nocterm's [TextStyle], so a dim run with no
/// colour of its own is drawn grey: the one thing dim reliably means is
/// "quieter than the rest of this line", and grey is the nearest this pane can
/// say. A dim run that *does* carry a colour keeps it — a dim red is still red,
/// and dropping the red to say "dim" loses the louder half.
TextStyle _styleFor(AnsiSpan span, {required bool isError}) {
  final color = switch (span.color) {
    final code? => colorForSgr(code),
    _ => null,
  };

  return TextStyle(
    color: color ?? (span.dim || isError ? Colors.grey : null),
    fontWeight: span.bold ? FontWeight.bold : null,
  );
}
