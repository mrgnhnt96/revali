import 'dart:collection';

import 'package:nocterm/nocterm.dart';
import 'package:revali/services/service_plan.dart';

/// Where a service is in its life, as far as its own output has said so.
///
/// Deliberately derived from what the child prints rather than from a
/// side-channel: `revali up` starts the same `revali dev` a developer would
/// start by hand, and a status protocol between them would be one more thing
/// to keep in step with the thing it describes.
enum ServiceState {
  /// Spawned, and has not yet said anything that places it further along.
  starting,

  /// A build or retrieve step is in flight.
  generating,

  /// Announced an address it is listening on.
  serving,

  /// Exited non-zero. Usually a compile error, and usually about to be fixed.
  crashed,

  /// Exited zero.
  stopped,
}

/// One line of a service's output, and which stream it came from.
class ServiceLogLine {
  const ServiceLogLine(this.text, {required this.isError});

  final String text;

  /// Whether it arrived on stderr. A pane colours by this; nothing else in
  /// the model reads it, because a child writing progress to stderr is
  /// ordinary and does not mean anything went wrong.
  final bool isError;

  @override
  bool operator ==(Object other) =>
      other is ServiceLogLine && other.text == text && other.isError == isError;

  @override
  int get hashCode => Object.hash(text, isError);

  @override
  String toString() => isError ? 'err: $text' : 'out: $text';
}

/// Everything the TUI draws for one service.
///
/// A [ChangeNotifier] because the pane rebuilds from it: the process feeds
/// [ingest] as bytes arrive, and the render loop reads [lines] and [state].
class ServiceSession extends ChangeNotifier {
  ServiceSession(this.plan, {this.maxLines = defaultMaxLines})
    : assert(maxLines > 0, 'a session with no room for a line shows nothing');

  /// How many settled lines are kept per service.
  ///
  /// Far enough back to hold a full stack trace and the build that preceded
  /// it, which is as far as anyone scrolls before switching to the log file;
  /// small enough that a fleet of ten idles in well under a megabyte.
  static const defaultMaxLines = 500;

  final ServicePlan plan;

  /// The cap on retained lines. Oldest are evicted first.
  final int maxLines;

  String get label => plan.label;
  String get name => plan.service.name;
  int get port => plan.port;

  final _settled = ListQueue<ServiceLogLine>();
  final _stdout = _Stream(isError: false);
  final _stderr = _Stream(isError: true);

  ServiceState _state = ServiceState.starting;
  ServiceState get state => _state;

  int? _exitCode;

  /// The code the process exited with, or null while it is still running.
  int? get exitCode => _exitCode;

  /// What the pane draws: the settled lines, then whatever each stream is
  /// part way through drawing.
  ///
  /// A transient frame is *last* on purpose — it is the line the child is
  /// still painting, and the next frame replaces it in place.
  List<ServiceLogLine> get lines => [
    ..._settled,
    if (_stdout.transient case final frame?) frame,
    if (_stderr.transient case final frame?) frame,
  ];

  /// Feeds one write from the child's stdout or stderr.
  ///
  /// Chunks arrive one write at a time and split wherever the pipe felt like
  /// splitting them, so a line can straddle any number of them. The tail of a
  /// chunk is held until a newline terminates it, per stream — splicing a
  /// half-written stdout line onto the next stderr chunk would corrupt both.
  ///
  /// Unlike [prefixLines], which writes into a shared append-only stream and
  /// so has to drop a frame that has not resolved, a pane owns its region and
  /// can redraw in place. An unresolved frame is kept as the transient last
  /// line and the next frame replaces it: one `⠋ Retrieving…` animating,
  /// rather than twenty stacked.
  void ingest(String chunk, {required bool isError}) {
    if (chunk.isEmpty) return;

    final stream = isError ? _stderr : _stdout;
    final segments = (stream.pending + chunk).split('\n');

    // The last segment has no newline after it yet, so the child may still be
    // drawing it.
    stream.pending = collapseRedraws(segments.removeLast());

    for (final segment in segments) {
      final frame = lastFrame(segment);
      if (frame.isEmpty) continue;

      if (isUnfinished(frame)) {
        // A spinner frame that ended in a newline anyway. Still unresolved,
        // so it stays replaceable.
        stream.transient = ServiceLogLine(frame, isError: isError);
      } else {
        stream.transient = null;
        _settle(ServiceLogLine(frame, isError: isError));
      }

      _note(frame);
    }

    if (lastFrame(stream.pending) case final tail when tail.isNotEmpty) {
      stream.transient = ServiceLogLine(tail, isError: isError);
      _note(tail);
    }

    notifyListeners();
  }

  /// Records that the process is gone.
  ///
  /// The session stays in the list either way. A crashed service is nearly
  /// always a compile error the developer is about to fix, and dropping its
  /// pane would read as the whole fleet going down.
  void markExited(int code) {
    _exitCode = code;
    _state = code == 0 ? ServiceState.stopped : ServiceState.crashed;

    _flush(_stdout);
    _flush(_stderr);

    notifyListeners();
  }

  void _settle(ServiceLogLine line) {
    _settled.addLast(line);

    while (_settled.length > maxLines) {
      _settled.removeFirst();
    }
  }

  /// Reads one frame for what it says about where the service is.
  void _note(String frame) {
    // Output can still drain after the process is gone. It says nothing about
    // a service that no longer exists, and must not walk `crashed` back.
    if (_exitCode != null) return;

    if (frame.contains(_servingMarker)) {
      _state = ServiceState.serving;
    } else if (isUnfinished(frame)) {
      // A spinner is a step in flight, by definition. After `serving` this
      // means a reload is rebuilding, which is worth showing as such — the
      // child re-announces its address when it comes back up.
      _state = ServiceState.generating;
    }
  }

  /// Settles what a stream was mid-way through drawing when the child died.
  void _flush(_Stream stream) {
    final frame = lastFrame(stream.pending);

    // A spinner frame will never be redrawn now, and leaving a half-drawn
    // `⠋ Retrieving…` as the last thing in the pane reads as still working.
    // Anything else is real output the child never got to terminate, and on
    // a crash that unterminated line is often the error itself.
    if (frame.isNotEmpty && !isUnfinished(frame)) {
      _settle(ServiceLogLine(frame, isError: stream.isError));
    }

    stream
      ..pending = ''
      ..transient = null;
  }
}

/// Per-stream draw state: the unterminated tail, and the frame it renders to.
class _Stream {
  _Stream({required this.isError});

  final bool isError;
  String pending = '';
  ServiceLogLine? transient;
}

/// What the server prints once it is listening, from `AppConfig`.
///
/// Matched anywhere in the line rather than at its start: the child hands it
/// to `logger.success`, which wraps it in colour, so by the time it reaches
/// this side it no longer begins with the `S`.
const _servingMarker = 'Serving at ';
