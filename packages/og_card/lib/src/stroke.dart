import 'dart:math' as math;

import 'package:og_card/src/geometry.dart';
import 'package:og_card/src/vector_path.dart';

/// Converts a path into the outline of a stroke along it, with round caps and
/// round joins.
///
/// The outline is the union of one capsule per segment. Every capsule is wound
/// the same direction, so filling the result with [FillRule.nonZero] unions
/// them — overlaps accumulate winding rather than cancelling, and the round
/// joins fall out of consecutive capsules sharing an end cap. That is why this
/// result must not be filled even-odd, where the overlaps would punch holes.
///
/// Only round caps and joins are produced. Mitre and bevel joins would need a
/// real offsetting pass; nothing here needs them yet.
VectorPath strokeToPath(
  VectorPath source,
  double width, {
  int capSegments = 24,
}) {
  final radius = width / 2;
  final out = VectorPath();
  if (radius <= 0) return out;

  for (final contour in source.contours) {
    if (contour.isEmpty) continue;

    if (contour.length == 1) {
      _addCircle(out, contour.first, radius, capSegments);
      continue;
    }

    for (var i = 0; i < contour.length - 1; i++) {
      final a = contour[i];
      final b = contour[i + 1];
      final dx = b.dx - a.dx;
      final dy = b.dy - a.dy;
      final len = math.sqrt(dx * dx + dy * dy);
      if (len == 0) continue;

      // The quad running alongside the segment, offset by the radius.
      final nx = -dy / len * radius;
      final ny = dx / len * radius;
      out
        ..moveTo(a.dx + nx, a.dy + ny)
        ..lineTo(b.dx + nx, b.dy + ny)
        ..lineTo(b.dx - nx, b.dy - ny)
        ..lineTo(a.dx - nx, a.dy - ny)
        ..close();
    }

    // A disc at every vertex gives both the end caps and the joins.
    for (final p in contour) {
      _addCircle(out, p, radius, capSegments);
    }
  }

  // The quads inherit their orientation from the direction of the segment they
  // follow, so they do not all agree with each other or with the discs. Under
  // non-zero winding two overlapping shapes of opposite orientation cancel and
  // punch a hole, which shows up as seams at every joint -- so force them all
  // to wind the same way before returning.
  _normaliseWinding(out);
  return out;
}

/// Reverses any contour that runs opposite to the majority, so that
/// overlapping shapes accumulate winding instead of cancelling.
void _normaliseWinding(VectorPath path) {
  for (final contour in path.contours) {
    if (contour.length < 3) continue;
    if (_signedArea(contour) < 0) {
      final reversed = contour.reversed.toList();
      contour
        ..clear()
        ..addAll(reversed);
    }
  }
}

double _signedArea(List<Offset> contour) {
  var sum = 0.0;
  for (var i = 0; i < contour.length; i++) {
    final a = contour[i];
    final b = contour[(i + 1) % contour.length];
    sum += a.dx * b.dy - b.dx * a.dy;
  }
  return sum / 2;
}

void _addCircle(VectorPath path, Offset centre, double radius, int segments) {
  path.moveTo(centre.dx + radius, centre.dy);
  for (var i = 1; i <= segments; i++) {
    final a = 2 * math.pi * i / segments;
    path.lineTo(
      centre.dx + radius * math.cos(a),
      centre.dy + radius * math.sin(a),
    );
  }
  path.close();
}
