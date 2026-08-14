import 'package:mason_logger/mason_logger.dart' show AnsiCode;
import 'package:nocterm/nocterm.dart';
import 'package:revali/services/ansi.dart';
import 'package:revali/services/service_plan.dart';
import 'package:revali/services/service_session.dart';

/// The colour the service at [index] is drawn in, everywhere it appears.
///
/// Bridged from [colorFor] rather than kept as a second palette here: the
/// prefixed output stream and these panes have to agree on which colour
/// `billing` is, and two lists in two files drift apart the moment one of them
/// gains a service.
///
/// [colorFor] answers in `mason_logger`'s [AnsiCode], which nocterm cannot
/// paint with, so the SGR number is what carries across. That number is the
/// stable part of an [AnsiCode] — the palette it resolves to is the terminal's
/// business, on both sides.
Color serviceColor(int index) =>
    colorForSgr(colorFor(index).code) ?? Colors.white;

/// The colour SGR foreground number [code] names, or null if it is not one
/// this maps.
///
/// The second caller of [_byAnsiCode], and the reason it covers the bright
/// range as well as the standard one: a service's own colour only ever comes
/// from [colorFor], but a *line* of a child's output can carry any foreground
/// the child felt like using, and `mason_logger` reaches for the bright ones
/// constantly — `lightGreen` is 92 and `darkGray` is 90, which between them are
/// most of what a progress line is made of.
Color? colorForSgr(int code) => _byAnsiCode[code];

/// Foreground SGR codes: the standard eight, then the bright eight.
///
/// One table, because the roster and the log pane have to agree on what `32`
/// looks like — and because a service drawn in one green beside its own output
/// drawn in another reads as two different services.
const _byAnsiCode = {
  30: Colors.black,
  31: Colors.red,
  32: Colors.green,
  33: Colors.yellow,
  34: Colors.blue,
  35: Colors.magenta,
  36: Colors.cyan,
  37: Colors.white,
  90: Colors.brightBlack,
  91: Colors.brightRed,
  92: Colors.brightGreen,
  93: Colors.brightYellow,
  94: Colors.brightBlue,
  95: Colors.brightMagenta,
  96: Colors.brightCyan,
  97: Colors.brightWhite,
};

/// The word shown in a row's state column.
///
/// [ServiceState.failed] is the one that does not reuse its own name. Beside
/// `crashed` the word "failed" says nothing a developer can act on — the two
/// look interchangeable in a column, and the whole point of the state is that
/// they are not. `needs fix` says which of the two this is and what to do
/// about it, in the nine characters the column already reserves.
String stateLabel(ServiceState state) => switch (state) {
  ServiceState.starting => 'starting',
  ServiceState.generating => 'generating',
  ServiceState.serving => 'serving',
  ServiceState.failed => 'needs fix',
  ServiceState.crashed => 'crashed',
  ServiceState.stopped => 'stopped',
};

/// The colour of a row's state column.
///
/// Only [ServiceState.crashed] and [ServiceState.failed] are loud. A fleet
/// with one service still building is the ordinary case, and colouring every
/// in-flight state leaves nothing left over for the states a developer has to
/// act on.
///
/// [ServiceState.failed] is as loud as [ServiceState.crashed] because it costs
/// the same to ignore. It is quieter than a crash in every other way — the
/// pane keeps scrolling, the spinner keeps turning, the process is still
/// there — which is exactly why the row has to carry the weight instead. A
/// crash announces itself; a service sitting on a taken port does not, and it
/// is the one thing on the screen that will not resolve on its own.
Color stateColor(ServiceState state) => switch (state) {
  ServiceState.serving => Colors.green,
  ServiceState.failed || ServiceState.crashed => Colors.red,
  ServiceState.stopped => Colors.grey,
  ServiceState.starting || ServiceState.generating => Colors.yellow,
};

/// The spinner glyph the child is painting right now, or null if it is not
/// painting one.
///
/// Read off the session's own last line rather than animated on this side: the
/// child owns the animation, and a second timer here would tick out of step
/// with the thing it claims to be reporting. It moves when the child's output
/// moves, which is the only honest cadence available.
///
/// Stripped before the glyph is taken, for the same reason [isUnfinished]
/// strips: a coloured frame begins with the escape byte, and slicing the first
/// character off the raw string would put that byte in the roster instead of
/// the spinner.
String? spinnerFrame(ServiceSession session) {
  final lines = session.lines;
  if (lines.isEmpty) return null;

  final visible = stripAnsi(lines.last.text).trim();

  return isUnfinished(visible) ? visible.substring(0, 1) : null;
}
