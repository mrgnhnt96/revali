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
String stateLabel(ServiceState state) => switch (state) {
  ServiceState.starting => 'starting',
  ServiceState.generating => 'generating',
  ServiceState.serving => 'serving',
  ServiceState.crashed => 'crashed',
  ServiceState.stopped => 'stopped',
};

/// The colour of a row's state column.
///
/// Only [ServiceState.crashed] is loud. A fleet with one service still
/// building is the ordinary case, and colouring every in-flight state leaves
/// nothing left over for the one state a developer has to act on.
Color stateColor(ServiceState state) => switch (state) {
  ServiceState.serving => Colors.green,
  ServiceState.crashed => Colors.red,
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
