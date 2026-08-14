import 'dart:io' as io;

/// The environment variable `revali up` sets on a service it is drawing a pane
/// for, and `revali dev` reads to turn its colour back on.
///
/// An internal handshake between the two commands, not public API: nothing
/// outside this repository should set it and its name may change.
///
/// It exists because a child's stdout under `revali up` is a *pipe*, and
/// `ansiOutputEnabled` — which is what `mason_logger` colours through — is
/// false on a pipe. Without a nudge the child emits plain text and there is no
/// colour left for the pane to render, however well it renders.
///
/// Set only where a pane is actually being drawn. The flat prefixed path is a
/// pipe on purpose — that is what CI reads — and colouring it would be a
/// regression, so the parent decides and the child only obeys.
const kForceAnsiEnvVar = 'REVALI_FORCE_ANSI';

/// Whether the parent asked this process to dress its output for a terminal.
///
/// The child half of the handshake, read in one place so the two things that
/// depend on it cannot come to disagree: `runRevali` turns `mason_logger`'s
/// colour on, and `progressCanAnimate` lets a progress line animate. They stay
/// separate questions — a caller may animate onto a pipe without emitting
/// colour, and the pane is why: it redraws frames in place whether or not they
/// are coloured — but they are asked of the same signal, because the signal is
/// one statement: *something is rendering my output as a terminal would*.
///
/// [environment] exists for tests. Anything real should let it default.
bool ansiForcedByParent([Map<String, String>? environment]) =>
    (environment ?? io.Platform.environment)[kForceAnsiEnvVar] == '1';

/// The screen clear a child writes when it redraws from the top.
///
/// `revali dev` writes it from `_wipeOrDivide` — `print('\x1B[2J\x1B[0;0H')`,
/// `vm_service_handler.dart` — on a reload and when the user presses `c`.
///
/// Unlike every other non-SGR sequence here it is *obeyed* rather than
/// dropped: `ServiceSession.ingest` empties that service's buffer when it
/// arrives. Dropping it silently is what made `c` look broken — the child
/// cleared its screen, and the pane kept every line it had.
///
/// The cursor-home that follows it (`ESC[0;0H`) keeps being dropped, and
/// should: a pane owns a region it redraws top-down and never addresses a
/// cursor inside, so there is no position for it to mean anything about.
const kClearScreen = '\x1B[2J';

/// A run of text that shares one SGR state.
///
/// Deliberately expressed in SGR numbers and flags rather than in a renderer's
/// colour type: the parser lives in the model layer, where a service's output
/// is stored raw, and the mapping to whatever is painting belongs to whatever
/// is painting.
class AnsiSpan {
  const AnsiSpan(this.text, {this.color, this.bold = false, this.dim = false});

  /// The visible characters. Never contains an escape sequence.
  final String text;

  /// The foreground SGR number in effect — 30-37 or 90-97 — or null for the
  /// terminal's default.
  final int? color;

  final bool bold;

  /// SGR 2. Kept separate from [color] because it is a modifier: a dim red is
  /// still red, and a renderer with no dim of its own needs to know which of
  /// the two it is dropping.
  final bool dim;

  @override
  bool operator ==(Object other) =>
      other is AnsiSpan &&
      other.text == text &&
      other.color == color &&
      other.bold == bold &&
      other.dim == dim;

  @override
  int get hashCode => Object.hash(text, color, bold, dim);

  @override
  String toString() => 'AnsiSpan($text, color: $color, bold: $bold, dim: $dim)';
}

/// Splits [text] into runs of visible characters, each carrying the SGR state
/// that was in effect when it was written.
///
/// Every escape sequence that is *not* SGR is dropped. A child writes plenty of
/// them — `mason_logger`'s own `Progress` brackets each frame with `ESC[?7l`
/// and `ESC[2K`, and `revali dev` clears the screen with `ESC[2J ESC[0;0H` —
/// and they are instructions to a terminal, addressed to a screen the child
/// believes it owns. A pane inside another program's frame is not that screen,
/// so printing them is why `[2J[0;0H` shows up as characters.
///
/// Dropping them is the answer for all but one. [kClearScreen] says something
/// a pane *can* act on, and by the time text reaches here it already has:
/// `ServiceSession.ingest` acts on it and hands this only what survived. So a
/// `ESC[2J` seen here is one nothing claimed, and dropping it is right.
///
/// Adjacent runs with the same state are merged, so a line the child wrapped
/// in a redundant reset does not become two spans that render identically.
List<AnsiSpan> parseAnsi(String text) {
  final spans = <AnsiSpan>[];
  final buffer = StringBuffer();

  int? color;
  var bold = false;
  var dim = false;

  void flush() {
    if (buffer.isEmpty) return;

    // Merged rather than appended when the state has not moved: two spans that
    // paint the same are one span that paints the same, and a renderer given
    // the second has to decide all over again what to do with it.
    if (spans.isNotEmpty &&
        spans.last.color == color &&
        spans.last.bold == bold &&
        spans.last.dim == dim) {
      final merged = spans.removeLast();
      spans.add(
        AnsiSpan('${merged.text}$buffer', color: color, bold: bold, dim: dim),
      );
    } else {
      spans.add(AnsiSpan('$buffer', color: color, bold: bold, dim: dim));
    }

    buffer.clear();
  }

  var index = 0;
  while (index < text.length) {
    if (text.codeUnitAt(index) != _esc) {
      buffer.writeCharCode(text.codeUnitAt(index));
      index++;
      continue;
    }

    final sequence = _sequenceAt(text, index);
    if (sequence == null) {
      // A trailing `ESC` with nothing after it: the chunk split mid-sequence.
      // Dropped rather than printed — the rest of it is in the next chunk and
      // a lone escape byte is not a character anyone meant to see.
      break;
    }

    // The state changes *between* runs, so what came before it keeps the old
    // one.
    if (_sgrParameters(text, sequence) case final parameters?) {
      flush();

      for (final parameter in parameters) {
        switch (parameter) {
          case 0:
            color = null;
            bold = false;
            dim = false;
          case 1:
            bold = true;
          case 2:
            dim = true;
          case 22:
            bold = false;
            dim = false;
          case 39:
            color = null;
          case >= 30 && <= 37:
          case >= 90 && <= 97:
            color = parameter;
        }
      }
    }

    index = sequence.end;
  }

  flush();

  return spans;
}

/// [text] with every escape sequence removed, leaving only what a reader sees.
///
/// Built on [parseAnsi] rather than on a second regular expression, so there is
/// one answer to "where does this sequence end" and the stripper cannot come to
/// disagree with the renderer about it.
String stripAnsi(String text) {
  if (!text.contains(_escString)) return text;

  return parseAnsi(text).map((span) => span.text).join();
}

const _esc = 0x1b;
const _escString = '\x1B';

/// Where an escape sequence ends, and where its parameters began.
class _Sequence {
  const _Sequence({
    required this.end,
    required this.parametersStart,
    required this.finalByte,
    required this.isCsi,
  });

  /// One past the sequence's last character.
  final int end;

  final int parametersStart;
  final String finalByte;

  /// Whether it opened with `ESC[`. Only a CSI sequence can be SGR.
  final bool isCsi;
}

/// Reads the escape sequence at [start], or null if [text] ends mid-sequence.
_Sequence? _sequenceAt(String text, int start) {
  final next = start + 1;
  if (next >= text.length) return null;

  final introducer = text[next];

  if (introducer == '[') {
    // CSI: parameter bytes, then intermediate bytes, then one final byte in
    // 0x40-0x7E. The private-marker forms (`ESC[?7l`) are parameter bytes as
    // far as this scan is concerned, which is what makes them terminate here
    // rather than run to the end of the line.
    var index = next + 1;
    while (index < text.length) {
      final unit = text.codeUnitAt(index);
      if (unit >= 0x40 && unit <= 0x7e) {
        return _Sequence(
          end: index + 1,
          parametersStart: next + 1,
          finalByte: text[index],
          isCsi: true,
        );
      }
      index++;
    }

    return null;
  }

  if (introducer == ']') {
    // OSC: runs until BEL or the ST pair `ESC\`. Nothing here emits one, but
    // an unterminated scan would swallow the rest of the line if something
    // did.
    var index = next + 1;
    while (index < text.length) {
      if (text.codeUnitAt(index) == 0x07) {
        return _Sequence(
          end: index + 1,
          parametersStart: next + 1,
          finalByte: '',
          isCsi: false,
        );
      }
      if (text.codeUnitAt(index) == _esc &&
          index + 1 < text.length &&
          text[index + 1] == r'\') {
        return _Sequence(
          end: index + 2,
          parametersStart: next + 1,
          finalByte: '',
          isCsi: false,
        );
      }
      index++;
    }

    return null;
  }

  // A two-character escape — `ESC c`, `ESC 7`. Nothing to read out of it.
  return _Sequence(
    end: next + 1,
    parametersStart: next,
    finalByte: introducer,
    isCsi: false,
  );
}

/// The numeric parameters of [sequence] if it is an SGR sequence, else null.
///
/// A bare `ESC[m` means `ESC[0m`, and so does an empty parameter inside a
/// longer one — which is why an unparsable parameter reads as 0 rather than
/// being skipped.
List<int>? _sgrParameters(String text, _Sequence sequence) {
  if (!sequence.isCsi || sequence.finalByte != 'm') return null;

  final raw = text.substring(sequence.parametersStart, sequence.end - 1);

  // A private-marker SGR (`ESC[?m`) is not one this understands, and reading
  // its parameters as colours would invent a colour nobody asked for.
  if (raw.startsWith('?') || raw.startsWith('<') || raw.startsWith('=')) {
    return null;
  }

  if (raw.isEmpty) return const [0];

  return [for (final part in raw.split(';')) int.tryParse(part) ?? 0];
}
