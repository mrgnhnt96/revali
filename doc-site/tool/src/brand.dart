/// The Revali brand artwork, as vector paths the rasterizer can fill.
///
/// This is the same geometry as `web/images/logo.svg`. It is duplicated here as
/// code rather than parsed from the SVG because a parser would be a far larger
/// dependency than the eleven curves it would read -- but that does mean the
/// two have to be changed together.
library;

import 'dart:math' as math;

import 'package:og_card/og_card.dart';

const ink = Color(0x1f, 0x29, 0x37);
const muted = Color(0x6b, 0x72, 0x80);
const indigo = Color(0x4e, 0x5f, 0xc6);
const amber = Color(0xd9, 0x77, 0x06);

/// The three feathers of the wing.
VectorPath wing() {
  final path = VectorPath();
  _feather(path, const Offset(110, 82), const Offset(30, 14));
  _feather(path, const Offset(108, 112), const Offset(10, 54));
  _feather(path, const Offset(108, 142), const Offset(16, 110));
  return path;
}

void _feather(VectorPath path, Offset from, Offset to) {
  path.moveTo(from.dx, from.dy);
  arcTo(path, from, to, 64, sweep: true);
  arcTo(path, to, from, 200, sweep: false);
  path.close();
}

/// The mark's `R`, stroked at 32 units with round caps and joins.
VectorPath markLetter() {
  final bowl = VectorPath()
    ..moveTo(100, 198)
    ..lineTo(100, 66)
    ..lineTo(140, 66);
  arcTo(bowl, const Offset(140, 66), const Offset(140, 142), 38, sweep: true);
  bowl.lineTo(100, 142);

  final leg = VectorPath()
    ..moveTo(126, 144)
    ..lineTo(184, 198);

  return strokeToPath(bowl, 32)..addPath(strokeToPath(leg, 32));
}

/// Appends a circular arc, matching SVG's `A r r 0 largeArc sweep x y`.
///
/// Two circles of radius [r] pass through both endpoints, and each offers a
/// short way round and a long way round. Both centres are tried and the one
/// whose sweep spans more than half a turn iff [largeArc] is kept, so the flags
/// mean what the spec says with no sign conventions to get backwards.
void arcTo(
  VectorPath path,
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
    path.lineTo(to.dx, to.dy);
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
    // positive, which is what sweep=1 asks for.
    var delta = sweep ? a1 - a0 : a0 - a1;
    while (delta < 0) {
      delta += 2 * math.pi;
    }
    if ((delta > math.pi) != largeArc) continue;

    final direction = sweep ? 1.0 : -1.0;
    for (var i = 1; i <= segments; i++) {
      final a = a0 + direction * delta * (i / segments);
      path.lineTo(centre.dx + r * math.cos(a), centre.dy + r * math.sin(a));
    }
    return;
  }

  path.lineTo(to.dx, to.dy);
}

Matrix rotate(double degrees, Offset centre) {
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
