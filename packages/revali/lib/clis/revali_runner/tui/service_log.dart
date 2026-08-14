import 'package:nocterm/nocterm.dart';
import 'package:revali/clis/revali_runner/tui/service_style.dart';
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
                    Text(
                      line.text,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        // Distinguishable, not alarming. A child writing
                        // progress to stderr is ordinary and does not mean
                        // anything went wrong, so red would lie about most of
                        // what lands here.
                        color: line.isError ? Colors.grey : null,
                      ),
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
