// Rebuilds the Revali social card entirely in Dart.
//
// Doubles as the rasterizer's fidelity check: tool/compare.sh diffs this
// output against rsvg-convert's render of the equivalent SVG.
import 'dart:io';
import 'dart:math' as math;

import 'package:og_card/og_card.dart';

final ink = Color.hex('#1f2937');
final indigo = Color.hex('#4e5fc6');
final amber = Color.hex('#d97706');

/// The wing: three feathers, each bounded by a tight arc out to the tip and a
/// shallow one back.
VectorPath wing() {
  final p = VectorPath();
  _feather(p, const Offset(110, 82), const Offset(30, 14));
  _feather(p, const Offset(108, 112), const Offset(10, 54));
  _feather(p, const Offset(108, 142), const Offset(16, 110));
  return p;
}

void _feather(VectorPath p, Offset from, Offset to) {
  p.moveTo(from.dx, from.dy);
  _arcTo(p, from, to, 64, sweep: true);
  _arcTo(p, to, from, 200, sweep: false);
  p.close();
}

/// Appends a circular arc, matching SVG's `A r r 0 largeArc sweep x y`.
///
/// Two circles of radius [r] pass through both endpoints, and each offers a
/// short way round and a long way round. Rather than deriving which is wanted
/// from the flags, both centres are tried and the one whose sweep actually
/// spans more than half a turn iff [largeArc] is kept -- the flags then mean
/// what the spec says they mean, with no sign conventions to get backwards.
void _arcTo(
  VectorPath p,
  Offset from,
  Offset to,
  double r, {
  required bool sweep,
  bool largeArc = false,
  int segments = 64,
}) {
  final dx = to.dx - from.dx;
  final dy = to.dy - from.dy;
  final d = math.sqrt(dx * dx + dy * dy);
  if (d == 0 || d > 2 * r) {
    p.lineTo(to.dx, to.dy);
    return;
  }

  final mx = (from.dx + to.dx) / 2;
  final my = (from.dy + to.dy) / 2;
  final h = math.sqrt(r * r - d * d / 4);
  final px = -dy / d * h;
  final py = dx / d * h;

  for (final centre in [Offset(mx + px, my + py), Offset(mx - px, my - py)]) {
    final a0 = math.atan2(from.dy - centre.dy, from.dx - centre.dx);
    final a1 = math.atan2(to.dy - centre.dy, to.dx - centre.dx);

    // Y grows downward, so an increasing angle sweeps the way SVG calls
    // positive -- which is what sweep=1 asks for.
    var delta = sweep ? a1 - a0 : a0 - a1;
    while (delta < 0) {
      delta += 2 * math.pi;
    }
    if ((delta > math.pi) != largeArc) continue;

    final direction = sweep ? 1.0 : -1.0;
    for (var i = 1; i <= segments; i++) {
      final a = a0 + direction * delta * (i / segments);
      p.lineTo(centre.dx + r * math.cos(a), centre.dy + r * math.sin(a));
    }
    return;
  }

  p.lineTo(to.dx, to.dy);
}

/// The stroked `R` of the mark, as a fillable outline.
VectorPath markLetter() {
  final bowl = VectorPath()
    ..moveTo(100, 198)
    ..lineTo(100, 66)
    ..lineTo(140, 66);
  _arcTo(bowl, const Offset(140, 66), const Offset(140, 142), 38, sweep: true);
  bowl.lineTo(100, 142);

  final leg = VectorPath()
    ..moveTo(126, 144)
    ..lineTo(184, 198);

  return strokeToPath(bowl, 32)..addPath(strokeToPath(leg, 32));
}

Future<void> main() async {
  final fontDir = '${Directory.current.path}/../../../doc-site/tool/fonts';
  final bold = TypeFace.fromBytes(
    File('$fontDir/Nunito-Bold.ttf').readAsBytesSync(),
  );
  final semi = TypeFace.fromBytes(
    File('$fontDir/Nunito-SemiBold.ttf').readAsBytesSync(),
  );

  final sw = Stopwatch()..start();
  final canvas = OgCanvas(width: 1600, height: 675);

  canvas
    ..fillRect(
      const Rect(0, 0, 1600, 675),
      LinearGradientPaint(
        from: const Offset(0, 0),
        to: const Offset(1600, 675),
        stops: [
          ColorStop(0, Color.hex('#ffffff')),
          ColorStop(0.55, Color.hex('#f4f6fe')),
          ColorStop(1, Color.hex('#e6eafb')),
        ],
      ),
    )
    // Background motif: rotate first, then scale, then translate -- the
    // reverse of how SVG lists them, since each applies to the one before it.
    ..fillPath(
      wing(),
      SolidPaint(indigo, opacity: 0.09),
      transform: _rotateAbout(-8, const Offset(60, 90))
          .then(const Matrix.scale(4.2, 4.2))
          .then(const Matrix.translate(1180, -120)),
    );

  final markAt = const Matrix.scale(
    1.6,
    1.6,
  ).then(const Matrix.translate(104, 169.6));
  canvas
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

  final word = bold.outline('Revali', capHeight: 104);
  const tagCap = 55.0;
  canvas.fillPath(
    word.path,
    SolidPaint(ink),
    transform: Matrix.translate(490.0 - word.inkBounds!.left, 272.5),
  );

  final tagDx = 490.0 - semi.outline('B', capHeight: tagCap).inkBounds!.left;
  final lines = <(double, List<(String, Color)>)>[
    (427, [('Build ', ink), ('APIs', indigo), (' Faster', ink)]),
    (523, [('Code Less, Deliver ', ink), ('More', amber)]),
  ];
  for (final (baseline, spans) in lines) {
    var x = 0.0;
    for (final (text, color) in spans) {
      final run = semi.outline(text, capHeight: tagCap, tracking: -0.005);
      canvas.fillPath(
        run.path,
        SolidPaint(color),
        transform: Matrix.translate(tagDx + x, baseline),
      );
      x += run.advance;
    }
  }

  sw.stop();
  File('revali_card.png').writeAsBytesSync(canvas.toPng());
  stdout.writeln('rendered 1600x675 in ${sw.elapsedMilliseconds}ms');
}

Matrix _rotateAbout(double degrees, Offset centre) {
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
