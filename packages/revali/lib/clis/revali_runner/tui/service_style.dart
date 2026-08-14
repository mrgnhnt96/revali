import 'package:mason_logger/mason_logger.dart' show AnsiCode;
import 'package:nocterm/nocterm.dart';
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
    _byAnsiCode[colorFor(index).code] ?? Colors.white;

/// Standard foreground SGR codes, which is all [colorFor] ever returns.
const _byAnsiCode = {
  30: Colors.black,
  31: Colors.red,
  32: Colors.green,
  33: Colors.yellow,
  34: Colors.blue,
  35: Colors.magenta,
  36: Colors.cyan,
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
String? spinnerFrame(ServiceSession session) {
  final lines = session.lines;
  if (lines.isEmpty) return null;

  final last = lines.last.text;

  return isUnfinished(last) ? last.substring(0, 1) : null;
}
