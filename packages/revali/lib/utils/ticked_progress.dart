import 'dart:async';
import 'dart:io' as io;
import 'dart:isolate';
import 'dart:math' as math;

import 'package:mason_logger/mason_logger.dart';

/// A progress line whose spinner is driven from a **sidecar isolate**.
///
/// `mason_logger`'s own [Progress] animates with a `Timer.periodic` on the
/// isolate that created it. Generation saturates that isolate — `RoutesHandler
/// .parse` resolves every unit through the analyzer synchronously between
/// awaits — so the timer never fires and the line stops on whatever frame it
/// last drew. The work is progressing; the only thing that stalled is the
/// thing telling the user so.
///
/// Moving the timer off that isolate is the whole point: the sidecar is doing
/// nothing but painting, so it keeps painting no matter what main is stuck in.
///
/// Ported from `TickedProgress` in Morgan's `import_ozempic`, written for this
/// same symptom. Adapted in two places, both load-bearing here and not there:
///
/// * the non-animated fallback reproduces `mason_logger`'s output byte for
///   byte rather than printing a plain line — see [_paintStatic];
/// * whether to animate and whether to emit ANSI are separate questions, so a
///   caller can animate onto a pipe without pretending it is a terminal.
///
/// One caveat the sidecar buys: main and the sidecar write to the same
/// `stdout` without a lock, so anything main prints *during* a step (only
/// `logger.detail`, under `--verbose`) can interleave with a frame. On a
/// terminal the next frame repaints over it.
class TickedProgress {
  /// Starts a progress line reading `message`.
  ///
  /// [animate] decides whether the sidecar runs. It defaults to
  /// [progressCanAnimate], and exists as a parameter for the seam described
  /// there.
  TickedProgress(
    this._message, {
    Level level = Level.info,
    bool? animate,
    Duration tickInterval = const Duration(milliseconds: 80),
  }) : _quiet = level.index > Level.info.index,
       _animate = animate ?? progressCanAnimate() {
    _stopwatch.start();

    if (!_animate) {
      _paintStatic();
      return;
    }

    // Deliberately not awaited. The sidecar starts ticking on its own; the
    // handle is only wanted for shutdown, and awaiting here would make the
    // first frame wait on an isolate spawn.
    unawaited(_spawn(tickInterval));
  }

  final Stopwatch _stopwatch = Stopwatch();

  /// Commands issued before the sidecar's port arrives.
  ///
  /// A step that completes faster than an isolate spawns is ordinary — a
  /// cached kernel makes `Generating server code` almost instant — and its
  /// `complete` must not be lost.
  final List<List<Object>> _pending = [];

  final bool _quiet;
  final bool _animate;

  String _message;
  SendPort? _commands;
  Isolate? _isolate;
  bool _closed = false;

  /// Repaints with a new message, without advancing the spinner frame.
  ///
  /// The frame belongs to the ticker: a step that reports sub-steps quickly
  /// would otherwise spin far faster than the work it describes.
  void update(String message) {
    if (_closed) return;
    _message = message;

    if (!_animate) return;

    _send([_SpinnerCommand.update, message]);
  }

  /// Ends the line with a `✓`.
  void complete([String? message]) => _finish(success: true, message: message);

  /// Ends the line with a `✗`.
  void fail([String? message]) => _finish(success: false, message: message);

  /// Ends the line and erases it.
  void cancel() {
    if (_closed) return;
    _closed = true;
    _stopwatch.stop();
    _shutdown();
    _write(_clearLine);
  }

  void _finish({required bool success, String? message}) {
    if (_closed) return;
    _closed = true;
    _stopwatch.stop();

    final text = message ?? _message;

    // Before the final line, never after: a main isolate that is still busy
    // cannot stop the sidecar painting a frame over the completion.
    _shutdown();

    final mark = success ? lightGreen.wrap('✓') : red.wrap('✗');
    _write('$_enableWrap$_clearLine$mark $text $_time\n');
  }

  /// The one frame a non-animated line ever draws.
  ///
  /// Identical to what `mason_logger` writes when `stdout` is not a terminal,
  /// down to the absent newline — and that matters beyond taste. `revali up`
  /// reads its children's frames off their stdout, and
  /// `isUnfinished` in `service_plan.dart` decides a service is
  /// generating by finding a braille glyph at the head of an unterminated
  /// line. A plain `Generating server code...` would leave every service stuck
  /// on `starting`, and settle as a permanent line in the pane.
  void _paintStatic() {
    _write('${lightGreen.wrap(_frames.first)} $_message$_trailing');
  }

  void _send(List<Object> command) {
    final port = _commands;

    if (port == null) {
      _pending.add(command);
    } else {
      port.send(command);
    }
  }

  void _shutdown() {
    _commands?.send([_SpinnerCommand.stop]);

    // Immediate, not the default: a sidecar that is only asked to stop keeps
    // its timer until it next reads its port, which is one frame too late.
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _commands = null;
    _pending.clear();
  }

  Future<void> _spawn(Duration tickInterval) async {
    final ready = ReceivePort();

    try {
      // The message goes in as a spawn argument rather than over the port, so
      // the sidecar draws its first frame without waiting on a handshake that
      // main may be too busy to complete.
      final spawned = Isolate.spawn(
        _spinnerMain,
        <Object>[
          ready.sendPort,
          _message,
          tickInterval.inMilliseconds,
          _quiet,
          io.stdout.hasTerminal,
        ],
        debugName: 'ticked-progress',
      );

      unawaited(
        spawned.then((isolate) {
          _isolate = isolate;

          if (_closed) isolate.kill(priority: Isolate.immediate);
        }),
      );

      final commands = await ready.first as SendPort;
      ready.close();

      if (_closed) {
        _isolate?.kill(priority: Isolate.immediate);
        return;
      }

      _commands = commands;

      for (final command in _pending) {
        commands.send(command);
      }
      _pending.clear();
    } catch (_) {
      // An isolate that will not spawn is not worth failing the build over.
      // One static frame is what `mason_logger` would have given us anyway.
      ready.close();

      if (!_closed) _paintStatic();
    }
  }

  void _write(String message) {
    if (_quiet) return;

    io.stdout.write(message);
  }

  String get _clearLine => _clearLineFor(io.stdout.hasTerminal);
  String get _enableWrap => io.stdout.hasTerminal ? _enableLineWrap : '';

  String get _time => _timeFor(_stopwatch);

  /// Sidecar entry point. Owns the timer, and nothing else.
  static void _spinnerMain(List<Object> args) {
    final ready = args[0] as SendPort;
    var message = args[1] as String;
    final intervalMs = args[2] as int;
    final quiet = args[3] as bool;
    final hasTerminal = args[4] as bool;

    final commands = ReceivePort();
    ready.send(commands.sendPort);

    var frame = 0;
    var stopped = false;
    final stopwatch = Stopwatch()..start();

    String clamped() {
      // A pipe has no width to ask for, and neither does a terminal we were
      // told to animate onto without one.
      final columns = hasTerminal ? io.stdout.terminalColumns : 80;
      final width = math.max(columns - _padding, _padding);

      return message.length > width ? message.substring(0, width) : message;
    }

    void paint({required bool advance}) {
      if (stopped || quiet) return;

      if (advance) frame++;

      final glyph = lightGreen.wrap(_frames[frame % _frames.length]);
      final disableWrap = hasTerminal ? _disableLineWrap : '';

      io.stdout.write(
        '$disableWrap${_clearLineFor(hasTerminal)}$glyph '
        '${clamped()}$_trailing ${_timeFor(stopwatch)}',
      );
    }

    paint(advance: false);

    final ticker = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) => paint(advance: true),
    );

    commands.listen((raw) {
      final command = raw as List<Object>;

      switch (command.first) {
        case _SpinnerCommand.update:
          message = command[1] as String;
          paint(advance: false);
        case _SpinnerCommand.stop:
          stopped = true;
          ticker.cancel();
          commands.close();
      }
    });
  }
}

/// Whether progress lines may animate.
///
/// **Seam.** Today this is `stdout.hasTerminal`, which is also what
/// `mason_logger` uses, so a piped child draws one static frame and nothing
/// moves. That is correct for CI, and it is what `revali up` already sees.
///
/// A sibling change is landing a handshake that tells a `revali dev` child to
/// emit ANSI even though its stdout is a pipe, because `ansiOutputEnabled` is
/// false there and `wrap()` becomes a no-op. When it lands, the decision made
/// here should follow that same signal rather than `hasTerminal` alone — a
/// child told to dress its output for a terminal should animate it too. It has
/// not landed on this base (`UpCommand._start` passes only `PORT`), so naming
/// its mechanism here would be a guess.
///
/// Note the two questions are kept apart on purpose: [TickedProgress] takes
/// `animate` separately from whether it emits ANSI, so forcing animation onto
/// a pipe does not also force escape codes onto one.
bool progressCanAnimate() => io.stdout.hasTerminal;

/// The braille cells `mason_logger` cycles through.
///
/// The same ten, in the same order, as `ProgressAnimation._defaultFrames` —
/// which is private — and the same set `service_plan.dart` matches on to tell
/// an unfinished frame from a finished one.
const _frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];

/// `mason_logger`'s `ProgressOptions.trailing` default.
const _trailing = '...';

/// `mason_logger`'s `Progress._padding`.
const _padding = 15;

const _disableLineWrap = '\x1b[?7l';
const _enableLineWrap = '\x1b[?7h';
const _eraseLine = '\x1b[2K';
const _carriageReturn = '\r';

/// Erase the line if we can, and otherwise just return to column 0.
///
/// A bare carriage return is what `mason_logger` falls back to, and what
/// `lastFrame` in `service_plan.dart` splits on.
String _clearLineFor(bool hasTerminal) =>
    hasTerminal ? '$_eraseLine$_carriageReturn' : _carriageReturn;

/// `mason_logger`'s elapsed-time suffix, formatted the same way.
String _timeFor(Stopwatch stopwatch) {
  final elapsed = stopwatch.elapsed.inMilliseconds;
  final inMilliseconds = elapsed < 100;
  final value = inMilliseconds ? elapsed : elapsed / 1000;
  final formatted = inMilliseconds
      ? '${value}ms'
      : '${value.toStringAsFixed(1)}s';

  return '${darkGray.wrap('($formatted)')}';
}

abstract final class _SpinnerCommand {
  static const update = 'u';
  static const stop = 's';
}
