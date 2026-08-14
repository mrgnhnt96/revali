import 'dart:collection';

import 'package:nocterm/nocterm.dart';
import 'package:revali/services/ansi.dart';
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

  /// The server inside `revali dev` is down, but `revali dev` itself is not.
  ///
  /// Distinct from [crashed], and not a synonym for it: `revali dev` stays up
  /// on purpose when its server process dies so the developer can fix the
  /// cause and press `r`. A port collision lands here — nothing has exited, so
  /// [ServiceSession.markExited] never fires, and without this the row keeps
  /// whatever it said before, which is [generating].
  ///
  /// Recoverable, and the reason the distinction earns its keep: a reload from
  /// here reaches [serving] again.
  failed,

  /// Exited non-zero. Usually a compile error, and usually about to be fixed.
  ///
  /// The `revali dev` process itself is gone. Unlike [failed], nothing on this
  /// side will bring it back.
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

  /// How many settled lines are kept per service — the pane's **scrollback
  /// depth**, since the oldest line reachable by scrolling is the oldest line
  /// still kept.
  ///
  /// This was an invisible default until the pane could scroll, and 500 is
  /// deliberately left where it was. A full Dart stack trace runs well under a
  /// hundred lines, so 500 holds one whole with the build that preceded it —
  /// which is as far as anyone reads before switching to the log file. Raising
  /// it trades a real cost for depth nobody reaches: the cap is per service and
  /// `revali up` runs the whole fleet, so it multiplies by ten, and [lines]
  /// copies the entire buffer on every rebuild — which is once per chunk of
  /// child output, for every service at once.
  ///
  /// A service that scrolls to the very top and keeps printing will have lines
  /// evicted out from under it; [_settle] keeps the view stationary while that
  /// happens rather than letting it drift.
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

  /// Index into [lines] of the pane's top visible row, or null while the pane
  /// is following the live end.
  ///
  /// Null is the whole stick/unstick rule rather than a flag beside it: a pane
  /// with no anchor renders the tail, so new output keeps it pinned to the
  /// newest line; a pane with one renders from that index, so new output lands
  /// below the view and does not move it. There is no third state, and no way
  /// to be both following and frozen.
  ///
  /// Anchored to the **top** of the window rather than measured back from the
  /// end, because the end is the noisy side. A transient spinner frame appears
  /// and disappears from the tail of [lines] between rebuilds, and every
  /// settle appends there; all of that would have to be subtracted back out of
  /// a distance-from-the-end. From the top, a settle changes nothing and only
  /// eviction moves the anchor — which is one place, [_settle].
  ///
  /// Lives on the session, not the screen, for three reasons. Switching
  /// services keeps each pane's position for free, because it is the same
  /// object. [_clearScreen] can reset it at the one place a clear actually
  /// happens, which catches the child clearing its own screen on reload and
  /// not just the `c` key. And it is meaningless without the buffer it indexes
  /// into, so the two stay together and are clamped against each other.
  int? _scrollTop;

  /// Where the pane's top visible row is, or null while it follows the tail.
  int? get scrollTop => _scrollTop;

  /// Whether the pane is following the live end.
  bool get isLive => _scrollTop == null;

  /// Moves the view by [delta] rows, freezing it away from the live end.
  ///
  /// [viewport] is how many rows the pane can draw, which only the pane knows.
  /// Scrolling back down to the last row re-sticks rather than stopping one
  /// short: a user who scrolls down to the newest line has said they want the
  /// newest line, and leaving them frozen there would silently stop showing
  /// output while looking exactly like a pane that is following it.
  void scrollBy(int delta, {required int viewport}) {
    if (viewport <= 0) return;

    final total = lines.length;
    final maxTop = total - viewport;

    // Nothing is off-screen, so there is nowhere to go and no way to be
    // anywhere but live.
    if (maxTop <= 0) {
      if (_scrollTop != null) {
        _scrollTop = null;
        notifyListeners();
      }

      return;
    }

    final next = (_scrollTop ?? maxTop) + delta;
    final clamped = next.clamp(0, maxTop);

    // Landing on the last window means the newest line is on screen, which is
    // what following the tail means.
    final resolved = clamped >= maxTop ? null : clamped;
    if (resolved == _scrollTop) return;

    _scrollTop = resolved;
    notifyListeners();
  }

  /// Snaps the pane back to the newest line and re-sticks it there.
  void scrollToLive() {
    if (_scrollTop == null) return;

    _scrollTop = null;
    notifyListeners();
  }

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
    var text = stream.pending + chunk;

    // The one terminal instruction a pane can honour, and the reason `c` used
    // to do nothing: the child cleared its own screen and this side dropped
    // the sequence with the rest of the escapes, so the pane kept every line.
    //
    // The *last* one, because a chunk carrying two clears has already had
    // whatever was between them wiped. Everything before it goes; everything
    // after it is output the child wrote onto the screen it just cleared, and
    // falls through to be ingested normally.
    if (text.lastIndexOf(kClearScreen) case final at when at != -1) {
      text = text.substring(at + kClearScreen.length);
      _clearScreen();
    }

    final segments = text.split('\n');

    // The last segment has no newline after it yet, so the child may still be
    // drawing it.
    stream.pending = collapseRedraws(segments.removeLast());

    for (final segment in segments) {
      final frame = lastFrame(segment);
      if (isBlank(frame)) continue;

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

    if (lastFrame(stream.pending) case final tail when !isBlank(tail)) {
      stream.transient = ServiceLogLine(tail, isError: isError);
      _note(tail);
    }

    notifyListeners();
  }

  /// Empties the pane, because the screen the child was drawing on is gone.
  ///
  /// Only what is *shown* — the settled lines and each stream's current frame.
  /// A stream's unterminated `pending` is deliberately left alone: it is the
  /// line that stream is part way through writing, and dropping half of it
  /// would splice the rest onto nothing when the next chunk lands. It is off
  /// the screen until then, which is all a clear ever promised.
  void _clearScreen() {
    _settled.clear();
    _stdout.transient = null;
    _stderr.transient = null;

    // A scroll position into a buffer that no longer exists points at nothing,
    // and a pane holding one after a clear draws blank — which reads as the
    // service having died rather than as the screen having been wiped.
    //
    // Here rather than on the `c` keypress because this is where a clear
    // actually happens: `c` is only *asked* for, by writing to the child, and
    // the child clears its own screen on reload without being asked at all.
    _scrollTop = null;
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

      // Every line before the view just shifted up by one, so the anchor has
      // to follow or the view slides forward a line per eviction — a pane
      // scrolled to the top of a busy service would crawl toward the end
      // without anyone touching it. At zero the view is already against the
      // oldest line kept, and what falls off is genuinely gone.
      if (_scrollTop case final top? when top > 0) {
        _scrollTop = top - 1;
      }
    }
  }

  /// Reads one frame for what it says about where the service is.
  void _note(String frame) {
    // Output can still drain after the process is gone. It says nothing about
    // a service that no longer exists, and must not walk `crashed` back.
    if (_exitCode != null) return;

    if (frame.contains(_servingMarker)) {
      // The only way out of `failed`, and it has to stay that way: a service
      // that reached `failed` and then came back up must not be left there.
      _state = ServiceState.serving;
    } else if (_failureMarkers.any(frame.contains)) {
      _state = ServiceState.failed;
    } else if (isUnfinished(frame) && _state != ServiceState.failed) {
      // A spinner is a step in flight, by definition. After `serving` this
      // means a reload is rebuilding, which is worth showing as such — the
      // child re-announces its address when it comes back up.
      //
      // Not from `failed`, though. The progress the child was showing when the
      // bind failed is never completed — `revali dev` only completes it on the
      // server announcing itself — so it keeps animating for as long as the
      // service stays broken. Letting a frame walk `failed` back would restore
      // the exact `generating`-forever this state exists to replace, and the
      // spinner of a genuine reload is indistinguishable from it here.
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

/// What the child prints when its server is down and it is waiting for a fix.
///
/// Matched anywhere in the line, for the same reason [_servingMarker] is, and
/// for two more: the handler hands these to `logger.err` and `logger.warn`,
/// which prefix (`[WARN] `) as well as colour; and the stderr and stdout of the
/// dead server are replayed indented by two spaces. Nothing here survives an
/// anchor at the start of the line.
///
/// Any one of the three is enough — they are the same failure seen from
/// different places, and the transcript can be cut short at any of them.
const _failureMarkers = [
  // The generated server could not get its socket, from `ServerFileMaker`.
  // A port already in use is the everyday cause.
  'Failed to bind server:',

  // `VmServiceHandler`, on the server process exiting non-zero. If hot reload
  // is off this is followed by `revali dev` stopping too, and [markExited]
  // takes the state on to `crashed` — which is right, and why this one is not
  // sufficient on its own to mean "still recoverable".
  'Server process terminated unexpectedly with exit code:',

  // The same handler, when hot reload is on. The clearest of the three: it
  // says outright that the wrapper is alive and the next move is the
  // developer's.
  'Dev server is still running',
];
