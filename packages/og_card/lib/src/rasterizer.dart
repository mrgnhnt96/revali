import 'dart:typed_data';

import 'package:og_card/src/vector_path.dart';

/// One edge of a flattened contour, normalised to point downward.
///
/// [winding] remembers which way the original edge ran, which is what the
/// non-zero fill rule needs once the edges have been sorted by Y.
class _Edge {
  _Edge(this.x0, this.y0, this.x1, this.y1, this.winding)
    : dxdy = (x1 - x0) / (y1 - y0);

  final double x0;
  final double y0;
  final double x1;
  final double y1;
  final int winding;
  final double dxdy;

  double xAt(double y) => x0 + (y - y0) * dxdy;
}

/// Computes per-pixel coverage for filled paths.
///
/// Anti-aliasing comes from sampling several sub-scanlines per pixel row and
/// accumulating exact horizontal span coverage on each. That is a good
/// trade for text: vertical stem edges — where the eye is least forgiving —
/// get exact coverage rather than a quantised approximation, and only
/// near-horizontal edges pay for the sub-sampling.
class Rasterizer {
  Rasterizer({this.subSamples = 5});

  /// Sub-scanlines per pixel row. Five is the point where further samples
  /// stop being visible on type at these sizes.
  final int subSamples;

  /// Fills [path] and hands each covered pixel to [plot] as
  /// `(x, y, coverage)` with coverage in 0..1.
  ///
  /// Coverage is emitted one row at a time, so callers can blend without
  /// allocating a full-canvas buffer per path.
  void fill(
    VectorPath path,
    int width,
    int height,
    FillRule rule,
    void Function(int x, int y, double coverage) plot,
  ) {
    final edges = _buildEdges(path);
    if (edges.isEmpty) return;

    // Only the rows the path actually touches are worth walking.
    var minY = height.toDouble();
    var maxY = 0.0;
    for (final e in edges) {
      if (e.y0 < minY) minY = e.y0;
      if (e.y1 > maxY) maxY = e.y1;
    }
    var rowStart = minY.floor();
    var rowEnd = maxY.ceil();
    if (rowStart < 0) rowStart = 0;
    if (rowEnd > height) rowEnd = height;
    if (rowStart >= rowEnd) return;

    edges.sort((a, b) => a.y0.compareTo(b.y0));

    final coverage = Float64List(width);
    final active = <_Edge>[];
    final crossings = <_Crossing>[];
    var next = 0;
    final step = 1.0 / subSamples;
    final weight = 1.0 / subSamples;

    // Edges starting above the clipped region still have to enter the active
    // list, or a shape clipped by the top of the canvas loses its interior.
    while (next < edges.length && edges[next].y0 < rowStart) {
      if (edges[next].y1 > rowStart) active.add(edges[next]);
      next++;
    }

    for (var row = rowStart; row < rowEnd; row++) {
      coverage.fillRange(0, width, 0);
      var touched = false;

      for (var s = 0; s < subSamples; s++) {
        final y = row + (s + 0.5) * step;

        while (next < edges.length && edges[next].y0 <= y) {
          active.add(edges[next]);
          next++;
        }
        active.removeWhere((e) => e.y1 <= y);
        if (active.isEmpty) continue;

        crossings.clear();
        for (final e in active) {
          if (y >= e.y0 && y < e.y1) {
            crossings.add(_Crossing(e.xAt(y), e.winding));
          }
        }
        if (crossings.length < 2) continue;
        crossings.sort((a, b) => a.x.compareTo(b.x));

        var count = 0;
        for (var i = 0; i < crossings.length - 1; i++) {
          count += crossings[i].winding;
          final inside = rule == FillRule.nonZero ? count != 0 : count.isOdd;
          if (!inside) continue;
          if (_span(
            coverage,
            crossings[i].x,
            crossings[i + 1].x,
            width,
            weight,
          )) {
            touched = true;
          }
        }
      }

      if (!touched) continue;
      for (var x = 0; x < width; x++) {
        final c = coverage[x];
        if (c > 0.0005) plot(x, row, c > 1 ? 1 : c);
      }
    }
  }

  /// Adds [weight] of coverage across `[xStart, xEnd)`, giving the two end
  /// pixels only the fraction they are actually covered by.
  bool _span(
    Float64List coverage,
    double xStart,
    double xEnd,
    int width,
    double weight,
  ) {
    var x0 = xStart;
    var x1 = xEnd;
    if (x1 <= 0 || x0 >= width || x1 <= x0) return false;
    if (x0 < 0) x0 = 0;
    if (x1 > width) x1 = width.toDouble();

    final first = x0.floor();
    final last = (x1 - 1e-9).floor();

    if (first == last) {
      coverage[first] += (x1 - x0) * weight;
      return true;
    }

    coverage[first] += (first + 1 - x0) * weight;
    for (var x = first + 1; x < last; x++) {
      coverage[x] += weight;
    }
    coverage[last] += (x1 - last) * weight;
    return true;
  }

  List<_Edge> _buildEdges(VectorPath path) {
    final edges = <_Edge>[];
    for (final contour in path.contours) {
      if (contour.length < 3) continue;
      for (var i = 0; i < contour.length; i++) {
        final a = contour[i];
        // The closing segment is implicit, so the last point joins the first.
        final b = contour[(i + 1) % contour.length];
        if (a.dy == b.dy) continue; // horizontal edges never cross a scanline
        if (a.dy < b.dy) {
          edges.add(_Edge(a.dx, a.dy, b.dx, b.dy, 1));
        } else {
          edges.add(_Edge(b.dx, b.dy, a.dx, a.dy, -1));
        }
      }
    }
    return edges;
  }
}

class _Crossing {
  const _Crossing(this.x, this.winding);
  final double x;
  final int winding;
}
