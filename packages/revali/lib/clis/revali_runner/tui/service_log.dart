import 'package:nocterm/nocterm.dart';
import 'package:revali/clis/revali_runner/tui/service_style.dart';
import 'package:revali/services/ansi.dart';
import 'package:revali/services/log_links.dart';
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
///
/// The pane follows the live end until it is scrolled off it, and then holds
/// still — see [ServiceSession.scrollTop]. Which of the two it is doing is
/// always on screen: a pane that has stopped following says so on its last row,
/// because a silently frozen pane and a hung service look identical.
class ServiceLog extends StatelessComponent {
  const ServiceLog({
    required this.session,
    required this.index,
    required this.height,
    this.onOpenUrl,
    super.key,
  });

  final ServiceSession session;

  /// Position in the fleet, so the rail matches the row above.
  final int index;

  /// Called with the URL of a clicked link, already launchable.
  ///
  /// Null makes every link inert — and it also stops them being underlined,
  /// because a screen that advertises a click nothing is listening for is worse
  /// than one that advertises nothing.
  final void Function(String url)? onOpenUrl;

  /// Rows this pane may draw into, measured by the screen above it.
  ///
  /// Passed in rather than measured here so that the height the keys scroll by
  /// and the height this draws are the same number. A pane that paged by one
  /// viewport and drew a different one would drift by a line per press.
  final int height;

  /// Rows of *output* a pane this tall can show.
  ///
  /// One less once the pane has stopped following, because the last row goes
  /// to saying so. Only taken while scrolled off the end, so the ordinary case
  /// gives up nothing.
  static int viewportFor(int height, {required bool isLive}) =>
      isLive ? height : height - 1;

  @override
  Component build(BuildContext context) {
    final color = serviceColor(index);

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final lines = session.lines;
        final top = session.scrollTop;
        final viewport = viewportFor(height, isLive: top == null);

        final List<ServiceLogLine> visible;
        int below;

        if (viewport <= 0) {
          visible = const [];
          below = 0;
        } else if (top == null) {
          // The tail. A pane shows what just happened, and the newest line is
          // the one being painted right now.
          visible = lines.length <= viewport
              ? lines
              : lines.sublist(lines.length - viewport);
          below = 0;
        } else {
          // Clamped on the way out rather than trusted: the buffer shrinks
          // under an anchor whenever a service is cleared or its lines are
          // evicted, and a stale index must not throw a range error at paint
          // time.
          final maxTop = (lines.length - viewport).clamp(0, lines.length);
          final start = top.clamp(0, maxTop);
          final end = (start + viewport).clamp(0, lines.length);

          visible = lines.sublist(start, end);
          below = lines.length - end;
        }

        return MouseRegion(
          // `onHover`, not `onEnter`: nocterm fires `onEnter` as well, but only
          // on the first event to land in the region, so handling both would
          // scroll twice for one notch and only ever on the first notch — the
          // kind of bug that reads as a flaky mouse. There is no `onScroll` or
          // `onWheel` on `MouseRegion`; a wheel notch arrives as an ordinary
          // mouse event carrying [MouseButton.wheelUp] or
          // [MouseButton.wheelDown].
          //
          // Wrapping the pane rather than the screen is what makes a wheel over
          // the roster leave this alone: nocterm hit-tests by position, so the
          // region under the pointer is the one that hears it.
          onHover: _onMouse,
          // The region has to fill the pane, or a wheel notch over the empty
          // space below a short log would fall through to nothing.
          child: SizedBox.expand(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final line in visible)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('│ ', style: TextStyle(color: color)),
                      ..._runsOf(line),
                    ],
                  ),
                if (top != null) _NotLive(below: below, color: color),
              ],
            ),
          ),
        );
      },
    );
  }

  /// One line, as the widgets that draw it: the dead runs and the clickable
  /// ones, side by side and in order.
  ///
  /// A clickable run gets its own [GestureDetector] rather than the whole line
  /// getting one and the column being worked out afterwards. That is what makes
  /// "resolve the click against what is CURRENTLY VISIBLE" true by construction
  /// instead of by arithmetic: nocterm hit-tests by position against the
  /// rendered tree, so the widget that hears a tap *is* the run under the
  /// pointer. Scrolled up, cleared, or with a `── redraw ──` rule in the middle
  /// of the buffer, there is no index to be off by — and a tap in the gap
  /// between two runs reaches neither of them.
  ///
  /// Splitting a line across several widgets was measured against drawing it as
  /// one `RichText` before it was relied on: the cell rows come out identical,
  /// including for a line wider than the terminal. The text and the column
  /// alignment are the contract here, so nothing about a link may change them —
  /// which is also why the only mark a link carries is an underline. It is a
  /// cell attribute, so it takes no columns, where a `[…]` or a trailing icon
  /// would shift every route path in the table sideways from the one above it.
  List<Component> _runsOf(ServiceLogLine line) {
    final spans = parseAnsi(line.text);
    final plain = spans.map((span) => span.text).join();

    // No handler means nothing to open, so nothing is marked as openable.
    final links = onOpenUrl == null
        ? const <LogLink>[]
        : findLinks(plain, baseUrl: session.baseUrl);

    if (links.isEmpty) {
      return [_run(spans, isError: line.isError)];
    }

    final runs = <Component>[];
    var cursor = 0;

    void emit(int end, {LogLink? link}) {
      if (end <= cursor) return;

      final run = _run(
        _slice(spans, cursor, end),
        isError: line.isError,
        isLink: link != null,
      );

      runs.add(
        link == null
            ? run
            : GestureDetector(
                onTap: () => onOpenUrl?.call(link.url),
                child: run,
              ),
      );

      cursor = end;
    }

    for (final link in links) {
      emit(link.start);
      emit(link.end, link: link);
    }
    emit(plain.length);

    return runs;
  }

  /// One run of a line, drawn exactly as it would be drawn on its own.
  Component _run(
    List<AnsiSpan> spans, {
    required bool isError,
    bool isLink = false,
  }) {
    return RichText(
      text: TextSpan(
        children: [
          for (final span in spans)
            TextSpan(
              text: span.text,
              style: _styleFor(span, isError: isError, isLink: isLink),
            ),
        ],
      ),
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
    );
  }

  void _onMouse(MouseEvent event) {
    final delta = switch (event.button) {
      MouseButton.wheelUp => -kWheelLines,
      MouseButton.wheelDown => kWheelLines,
      _ => 0,
    };

    if (delta == 0) return;

    session.scrollBy(
      delta,
      viewport: viewportFor(height, isLive: session.isLive),
    );
  }
}

/// How far one notch of the wheel moves the pane.
///
/// Three rows is what a terminal scrolls per notch by convention, and it is
/// what makes the wheel feel like the wheel rather than like the arrow keys.
const kWheelLines = 3;

/// The last row of a pane that has stopped following its service.
///
/// It says how much is below rather than just that something is, because the
/// number is what tells a developer whether they are one line from the end or
/// four hundred — and it is the difference between a pane that looks stuck and
/// one that is plainly parked.
class _NotLive extends StatelessComponent {
  const _NotLive({required this.below, required this.color});

  final int below;
  final Color color;

  @override
  Component build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('│ ', style: TextStyle(color: color)),
        // Always "N more", never a bare "paused": the number is the whole
        // point, and a second wording would be one more thing for a reader to
        // tell apart at a glance.
        Text(
          '↓ $below more',
          style: const TextStyle(
            color: Colors.black,
            backgroundColor: Colors.yellow,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Named so the way back is on screen next to the thing telling you you
        // need it, rather than only in the legend at the foot of the screen.
        const Text('  g live', style: TextStyle(color: Colors.grey)),
      ],
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
/// [isLink] adds an underline and nothing else.
///
/// The child's colour is left exactly where it was — a route table is colour
/// coded by method and the `Serving at` line is green, and repainting either to
/// say "clickable" would take away the thing the colour was already saying.
/// Underline is the one mark that adds a channel rather than spending one, and
/// it costs no columns.
TextStyle _styleFor(
  AnsiSpan span, {
  required bool isError,
  bool isLink = false,
}) {
  final color = switch (span.color) {
    final code? => colorForSgr(code),
    _ => null,
  };

  return TextStyle(
    color: color ?? (span.dim || isError ? Colors.grey : null),
    fontWeight: span.bold ? FontWeight.bold : null,
    decoration: isLink ? TextDecoration.underline : null,
  );
}

/// The part of [spans] covering `[start, end)` of the text they spell out.
///
/// A link range is found over the joined plain text, so it pays no attention to
/// where one SGR run stops and the next starts and may cut through the middle
/// of one. Each piece keeps the style of the span it came from, which is what
/// makes a link that straddles a colour change still render in both colours.
List<AnsiSpan> _slice(List<AnsiSpan> spans, int start, int end) {
  final sliced = <AnsiSpan>[];
  var offset = 0;

  for (final span in spans) {
    final spanStart = offset;
    final spanEnd = offset + span.text.length;
    offset = spanEnd;

    final from = spanStart < start ? start : spanStart;
    final to = spanEnd > end ? end : spanEnd;
    if (to <= from) continue;

    sliced.add(
      AnsiSpan(
        span.text.substring(from - spanStart, to - spanStart),
        color: span.color,
        bold: span.bold,
        dim: span.dim,
      ),
    );
  }

  return sliced;
}
