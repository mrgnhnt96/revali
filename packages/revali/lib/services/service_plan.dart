import 'package:mason_logger/mason_logger.dart';
import 'package:revali/services/ansi.dart';
import 'package:revali/services/service_discovery.dart';

/// One service, with everything the runner needs to start it.
class ServicePlan {
  const ServicePlan({
    required this.service,
    required this.port,
    required this.label,
  });

  final RevaliService service;

  /// The port handed to the process as `PORT`.
  final int port;

  /// What its output lines are prefixed with. Unique across the fleet.
  final String label;
}

/// Thrown when `--only` names something that is not there.
///
/// Silently running a subset of what was asked for is worse than refusing:
/// a typo would otherwise look like a service that starts and does nothing.
class UnknownServiceException implements Exception {
  const UnknownServiceException(this.names, this.available);

  final List<String> names;
  final List<String> available;

  @override
  String toString() =>
      'No such service: ${names.join(', ')}.\n'
      'Available: ${available.join(', ')}';
}

/// Decides what to run and on which ports.
///
/// Separated from the process handling so the decisions — selection, port
/// assignment, label uniqueness — are testable without starting anything.
List<ServicePlan> planServices(
  List<RevaliService> services, {
  int basePort = 8080,
  List<String> only = const [],
}) {
  final selected = _select(services, only);
  final labels = _labelsFor(selected);

  return [
    for (final (index, service) in selected.indexed)
      ServicePlan(
        service: service,
        port: basePort + index,
        label: labels[index],
      ),
  ];
}

List<RevaliService> _select(List<RevaliService> services, List<String> only) {
  if (only.isEmpty) {
    return services;
  }

  final wanted = only.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
  final selected = services
      .where((s) => wanted.contains(s.name) || wanted.contains(s.relativePath))
      .toList();

  final matched = {
    for (final service in selected) ...[service.name, service.relativePath],
  };
  final missing = wanted.where((name) => !matched.contains(name)).toList();

  if (missing.isNotEmpty) {
    throw UnknownServiceException(
      missing,
      services.map((s) => s.name).toList(),
    );
  }

  return selected;
}

/// Labels for [services], one per entry and all distinct.
///
/// Package names are not unique across a repository — several examples can
/// legitimately be called `hello` — and two identical prefixes in a merged
/// output stream is worse than a long one, because there is then no way to
/// tell which process a line came from.
List<String> _labelsFor(List<RevaliService> services) {
  final counts = <String, int>{};
  for (final service in services) {
    counts[service.name] = (counts[service.name] ?? 0) + 1;
  }

  return [
    for (final service in services)
      if (counts[service.name] == 1) service.name else service.relativePath,
  ];
}

/// Prefixes every non-blank line of [chunk] with [label].
///
/// [label] arrives already padded and coloured — ANSI escapes count toward
/// string length, so padding here would misalign every prefix.
///
/// Returns the lines rather than printing them, so the caller decides where
/// they go and a test can look at them.
List<String> prefixLines(String chunk, String label) {
  return [
    for (final line in chunk.split('\n'))
      if (lastFrame(line) case final frame
          when frame.isNotEmpty && !isUnfinished(frame))
        '$label | $frame',
  ];
}

/// Whether this frame is a progress indicator that has not resolved yet.
///
/// Frames arrive one write at a time, so collapsing *within* a chunk is not
/// enough: the first frame of a spinner lands in its own chunk and would be
/// printed, leaving a stray `⠋ Generating…` above every `✓ Generated…`. With
/// several services interleaved that is most of the output.
///
/// A frame still wearing a spinner glyph is unfinished by definition — the
/// same line is about to be redrawn, and the redraw ends in `✓` or `✗`, which
/// is the part worth keeping. Anything a child prints that does *not* animate
/// passes through untouched.
///
/// The glyph is looked for in the frame's *visible* text. A child that colours
/// its output writes `ESC[92m⠋ESC[0m Retrieving…`, whose first code unit is the
/// escape byte and not the glyph — so testing the raw string would stop
/// matching the moment colour was turned on, and would do it silently: every
/// frame becomes a settled line, the spinner column in the roster empties, and
/// nothing anywhere reports an error. [stripAnsi] is what keeps this test about
/// what the child drew rather than about how it drew it.
///
/// Public so a renderer that owns its own region — a per-service pane, which
/// can redraw in place rather than only appending — can hold an unfinished
/// frame instead of dropping it. A second copy of this test would drift from
/// this one.
bool isUnfinished(String frame) {
  final visible = stripAnsi(frame).trim();

  return visible.isNotEmpty && _spinnerGlyphs.contains(visible.codeUnitAt(0));
}

/// The braille cells `mason_logger` cycles through while a task runs.
const _spinnerGlyphs = {
  0x280b,
  0x2819,
  0x2839,
  0x2838,
  0x283c,
  0x2834,
  0x2826,
  0x2827,
  0x2807,
  0x280f,
};

/// The final state of a line that redrew itself in place.
///
/// A child process animates progress by returning to column 0 with a bare
/// `\r` and painting over what it wrote. Left in the stream that would
/// overwrite the prefix saying which service the line came from, so it cannot
/// simply be passed through — but treating `\r` as a line break is the other
/// extreme: every frame of the animation becomes a permanent line, and
/// starting two services turns a single spinner into a wall of
/// `⠋ Retrieving…`, `⠙ Retrieving…`, `✓ Retrieved`.
///
/// A carriage return means *replace what I just drew*. So only the text after
/// the last one survives, which is that line's finished state.
String lastFrame(String line) {
  final text = _withoutLineEnding(line);
  final lastReturn = text.lastIndexOf('\r');

  return (lastReturn == -1 ? text : text.substring(lastReturn + 1)).trim();
}

/// [line] with everything an earlier redraw already painted over discarded.
///
/// The same rule as [lastFrame], but it keeps the carriage return and the
/// surrounding whitespace, so the result can be fed back in as the still
/// unterminated tail of a line that is being drawn right now.
///
/// A caller buffering a partial line needs this: a spinner running for the
/// length of a build writes a frame every 80ms and never a newline, so a tail
/// kept verbatim grows for as long as the step takes, to hold frames that
/// were painted over seconds ago.
String collapseRedraws(String line) {
  final cut = _withoutLineEnding(line).lastIndexOf('\r');

  // `cut == 0` is already collapsed; re-slicing it would be a no-op.
  return cut <= 0 ? line : line.substring(cut);
}

/// [line] without a *trailing* carriage return.
///
/// That one is the other half of a CRLF line ending, not a redraw. Treating
/// it as one would discard the whole line on Windows. It is written once,
/// here, because two copies of this rule would drift apart.
String _withoutLineEnding(String line) =>
    line.endsWith('\r') ? line.substring(0, line.length - 1) : line;

/// A stable colour per service, so a given prefix keeps its colour for the
/// life of the run.
AnsiCode colorFor(int index) {
  const palette = [cyan, green, yellow, magenta, blue, red];

  return palette[index % palette.length];
}
