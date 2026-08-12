import 'package:og_card/src/geometry.dart';

/// How overlapping sub-paths decide what counts as inside.
enum FillRule {
  /// SVG's default. A point is inside when the signed crossing count is not
  /// zero, so a counter wound opposite to its outer contour becomes a hole.
  /// This is what font outlines rely on.
  nonZero,

  /// A point is inside when the crossing count is odd, regardless of
  /// direction.
  evenOdd,
}

/// A closed shape built from lines and Bézier segments.
///
/// A path holds one or more sub-paths. Each [moveTo] starts a new one, and
/// every sub-path is treated as closed when filled — an unclosed sub-path is
/// implicitly closed back to its start, which matches SVG fill behaviour.
class VectorPath {
  final List<List<Offset>> _contours = <List<Offset>>[];
  List<Offset>? _current;
  Offset _cursor = const Offset(0, 0);
  Offset _start = const Offset(0, 0);

  /// The flattened contours. Curves have already been subdivided into line
  /// segments by the time they land here.
  List<List<Offset>> get contours => _contours;

  bool get isEmpty => _contours.every((c) => c.length < 3);

  /// How finely curves are subdivided, in user-space units. Anything below
  /// about a quarter of a device pixel is invisible after anti-aliasing.
  double flatness = 0.2;

  void moveTo(double x, double y) {
    _cursor = Offset(x, y);
    _start = _cursor;
    _current = <Offset>[_cursor];
    _contours.add(_current!);
  }

  void lineTo(double x, double y) {
    _current ??= _startImplicit();
    _cursor = Offset(x, y);
    _current!.add(_cursor);
  }

  void quadraticTo(double cx, double cy, double x, double y) {
    _current ??= _startImplicit();
    final p0 = _cursor;
    final p1 = Offset(cx, cy);
    final p2 = Offset(x, y);
    final steps = _quadSteps(p0, p1, p2);
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      final u = 1 - t;
      _current!.add(
        Offset(
          u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx,
          u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy,
        ),
      );
    }
    _cursor = p2;
  }

  void cubicTo(
    double c1x,
    double c1y,
    double c2x,
    double c2y,
    double x,
    double y,
  ) {
    _current ??= _startImplicit();
    final p0 = _cursor;
    final p1 = Offset(c1x, c1y);
    final p2 = Offset(c2x, c2y);
    final p3 = Offset(x, y);
    final steps = _cubicSteps(p0, p1, p2, p3);
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      final u = 1 - t;
      final uu = u * u;
      final tt = t * t;
      _current!.add(
        Offset(
          uu * u * p0.dx +
              3 * uu * t * p1.dx +
              3 * u * tt * p2.dx +
              tt * t * p3.dx,
          uu * u * p0.dy +
              3 * uu * t * p1.dy +
              3 * u * tt * p2.dy +
              tt * t * p3.dy,
        ),
      );
    }
    _cursor = p3;
  }

  void close() {
    if (_current != null && _current!.isNotEmpty) {
      _current!.add(_start);
    }
    _cursor = _start;
    _current = null;
  }

  void addRect(Rect r) {
    moveTo(r.left, r.top);
    lineTo(r.right, r.top);
    lineTo(r.right, r.bottom);
    lineTo(r.left, r.bottom);
    close();
  }

  /// Appends [other]'s contours, mapped through [matrix].
  void addPath(VectorPath other, [Matrix matrix = const Matrix.identity()]) {
    for (final contour in other._contours) {
      if (contour.length < 2) continue;
      _contours.add(<Offset>[for (final p in contour) matrix.apply(p)]);
    }
    _current = null;
  }

  /// A copy with every point mapped through [matrix].
  VectorPath transformed(Matrix matrix) {
    return VectorPath()
      ..flatness = flatness
      ..addPath(this, matrix);
  }

  /// The tight bounding box of the flattened points, or `null` when empty.
  Rect? get bounds {
    double? minX;
    double? minY;
    double? maxX;
    double? maxY;
    for (final contour in _contours) {
      for (final p in contour) {
        minX = (minX == null || p.dx < minX) ? p.dx : minX;
        minY = (minY == null || p.dy < minY) ? p.dy : minY;
        maxX = (maxX == null || p.dx > maxX) ? p.dx : maxX;
        maxY = (maxY == null || p.dy > maxY) ? p.dy : maxY;
      }
    }
    if (minX == null) return null;
    return Rect(minX, minY!, maxX!, maxY!);
  }

  List<Offset> _startImplicit() {
    final c = <Offset>[_cursor];
    _contours.add(c);
    return c;
  }

  /// Subdivision counts come from the control polygon's deviation from a
  /// straight line, which bounds the true curve error and costs no square
  /// roots per segment.
  int _quadSteps(Offset p0, Offset p1, Offset p2) {
    final dx = p0.dx - 2 * p1.dx + p2.dx;
    final dy = p0.dy - 2 * p1.dy + p2.dy;
    return _stepsFor(dx * dx + dy * dy);
  }

  int _cubicSteps(Offset p0, Offset p1, Offset p2, Offset p3) {
    final ax = p0.dx - 2 * p1.dx + p2.dx;
    final ay = p0.dy - 2 * p1.dy + p2.dy;
    final bx = p1.dx - 2 * p2.dx + p3.dx;
    final by = p1.dy - 2 * p2.dy + p3.dy;
    final dev = (ax * ax + ay * ay) > (bx * bx + by * by)
        ? (ax * ax + ay * ay)
        : (bx * bx + by * by);
    return _stepsFor(dev);
  }

  int _stepsFor(double squaredDeviation) {
    if (squaredDeviation <= 0) return 1;
    // steps ~ sqrt(deviation / flatness); one Newton-free approximation via
    // repeated doubling keeps this cheap and always errs toward more segments.
    var steps = 1;
    while (steps < 64 &&
        squaredDeviation / (steps * steps * steps * steps) >
            flatness * flatness) {
      steps *= 2;
    }
    return steps;
  }
}
