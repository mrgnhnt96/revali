// Four candidate treatments for the docs.revali.dev card.
//
// Variant D is the one that matters for where this is going: the page title is
// poured in at render time, so it needs measuring and wrapping rather than a
// fixed string.
import 'dart:io';
import 'dart:math' as math;

import 'package:og_card/og_card.dart';

import 'revali_card.dart' show markLetter, wing;

final ink = Color.hex('#1f2937');
final muted = Color.hex('#6b7280');
final indigo = Color.hex('#4e5fc6');
final amber = Color.hex('#d97706');

const width = 1600.0;
const height = 675.0;
const left = 490.0;

late final TypeFace bold;
late final TypeFace semi;

/// Everything shared by all four: the wash, the motif and the mark.
OgCanvas newCard() {
  final canvas = OgCanvas(width: width.toInt(), height: height.toInt())
    ..fillRect(
      const Rect(0, 0, width, height),
      LinearGradientPaint(
        from: const Offset(0, 0),
        to: const Offset(width, height),
        stops: [
          ColorStop(0, Color.hex('#ffffff')),
          ColorStop(0.55, Color.hex('#f4f6fe')),
          ColorStop(1, Color.hex('#e6eafb')),
        ],
      ),
    )
    ..fillPath(
      wing(),
      SolidPaint(indigo, opacity: 0.09),
      transform: _rotate(-8, const Offset(60, 90))
          .then(const Matrix.scale(4.2, 4.2))
          .then(const Matrix.translate(1180, -120)),
    );

  final markAt =
      const Matrix.scale(1.6, 1.6).then(const Matrix.translate(104, 169.6));
  return canvas
    ..fillPath(
      wing(),
      LinearGradientPaint(
        from: const Offset(20, 10),
        to: const Offset(120, 170),
        stops: [
          ColorStop(0, Color.hex('#fbbf24')),
          ColorStop(0.5, Color.hex('#f59e0b')),
          ColorStop(1, Color.hex('#d97706')),
        ],
      ),
      transform: markAt,
    )
    ..fillPath(
      markLetter(),
      LinearGradientPaint(
        from: const Offset(100, 50),
        to: const Offset(190, 210),
        stops: [
          ColorStop(0, Color.hex('#7a8df0')),
          ColorStop(1, Color.hex('#4e5fc6')),
        ],
      ),
      transform: markAt,
    );
}

void write(OgCanvas canvas, String name) {
  File('docs_$name.png').writeAsBytesSync(canvas.toPng());
  stdout.writeln('docs_$name.png');
}

/// Draws [text] with its ink left edge at [left].
double draw(
  OgCanvas canvas,
  TypeFace face,
  String text, {
  required double cap,
  required double baseline,
  required Color color,
  double x = left,
  double tracking = 0,
}) {
  final run = face.outline(text, capHeight: cap, tracking: tracking);
  if (run.inkBounds == null) return x;
  canvas.fillPath(
    run.path,
    SolidPaint(color),
    transform: Matrix.translate(x - run.inkBounds!.left, baseline),
  );
  return x + run.advance;
}

/// Greedy word wrap. A dynamic card takes whatever title the page has, so the
/// only safe assumption is that it will eventually be too long for one line.
List<String> wrap(TypeFace face, String text, double cap, double maxWidth) {
  final words = text.split(' ');
  final lines = <String>[];
  var current = '';
  for (final word in words) {
    final candidate = current.isEmpty ? word : '$current $word';
    if (face.outline(candidate, capHeight: cap).advance <= maxWidth ||
        current.isEmpty) {
      current = candidate;
    } else {
      lines.add(current);
      current = word;
    }
  }
  if (current.isNotEmpty) lines.add(current);
  return lines;
}

/// A small uppercase label, letter-spaced the way an eyebrow wants to be.
void eyebrow(OgCanvas canvas, String text, double baseline, Color color) {
  draw(
    canvas,
    semi,
    text.toUpperCase(),
    cap: 26,
    baseline: baseline,
    color: color,
    tracking: 0.14,
  );
}

void main() {
  final dir = '${Directory.current.path}/../../../doc-site/tool/fonts';
  bold = TypeFace.fromBytes(File('$dir/Nunito-Bold.ttf').readAsBytesSync());
  semi = TypeFace.fromBytes(File('$dir/Nunito-SemiBold.ttf').readAsBytesSync());

  // A: the marketing card's rhythm, with docs copy.
  final a = newCard();
  draw(a, bold, 'Revali', cap: 104, baseline: 272.5, color: ink);
  draw(a, semi, 'Documentation', cap: 55, baseline: 427, color: ink);
  var x = draw(a, semi, 'Guides, CLI, and ', cap: 55, baseline: 523, color: ink);
  draw(a, semi, 'Constructs', cap: 55, baseline: 523, color: indigo, x: x);
  write(a, 'a_two_line');

  // B: one word, and a lot of air. Defers to the per-page title above it.
  final b = newCard();
  draw(b, bold, 'Revali', cap: 104, baseline: 330, color: ink);
  draw(b, semi, 'Documentation', cap: 48, baseline: 440, color: muted);
  write(b, 'b_understated');

  // C: the section named as a label rather than as a sentence.
  final c = newCard();
  eyebrow(c, 'Documentation', 214, indigo);
  draw(c, bold, 'Revali', cap: 104, baseline: 350, color: ink);
  x = draw(c, semi, 'Build APIs ', cap: 46, baseline: 452, color: muted);
  draw(c, semi, 'faster', cap: 46, baseline: 452, color: amber, x: x);
  write(c, 'c_eyebrow');

  // D: what a per-page card looks like. Title is measured and wrapped, so it
  // survives whatever the page is called.
  for (final (slug, title) in [
    ('short', 'Hot Reload'),
    ('long', 'Create Your First Endpoint'),
  ]) {
    final d = newCard();
    eyebrow(d, 'Revali Docs', 210, indigo);
    const cap = 72.0;
    final lines = wrap(bold, title, cap, width - left - 210);
    // Two lines take the block upward so it stays optically centred.
    var baseline = lines.length > 1 ? 330.0 : 372.0;
    for (final line in lines) {
      draw(d, bold, line, cap: cap, baseline: baseline, color: ink);
      baseline += 104;
    }
    draw(
      d,
      semi,
      'docs.revali.dev',
      cap: 34,
      baseline: lines.length > 1 ? 545 : 500,
      color: muted,
    );
    write(d, 'd_perpage_$slug');
  }
}

Matrix _rotate(double degrees, Offset centre) {
  final r = degrees * math.pi / 180;
  final c = math.cos(r);
  final s = math.sin(r);
  return Matrix(
    c,
    s,
    -s,
    c,
    centre.dx - c * centre.dx + s * centre.dy,
    centre.dy - s * centre.dx - c * centre.dy,
  );
}
