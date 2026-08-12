import 'dart:math';

/// A point in user space. Y grows downward, as in SVG and image buffers.
class Offset {
  const Offset(this.dx, this.dy);

  final double dx;
  final double dy;

  Offset operator +(Offset other) => Offset(dx + other.dx, dy + other.dy);
  Offset operator -(Offset other) => Offset(dx - other.dx, dy - other.dy);
  Offset operator *(double factor) => Offset(dx * factor, dy * factor);

  @override
  String toString() =>
      'Offset(${dx.toStringAsFixed(2)}, '
      '${dy.toStringAsFixed(2)})';
}

/// An axis-aligned rectangle.
class Rect {
  const Rect(this.left, this.top, this.right, this.bottom);

  const Rect.fromLTWH(this.left, this.top, double width, double height)
    : right = left + width,
      bottom = top + height;

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;

  @override
  String toString() => 'Rect($left, $top, $right, $bottom)';
}

/// A 2D affine transform, stored as the six meaningful values of
///
///     | a c e |
///     | b d f |
///     | 0 0 1 |
///
/// which is the same order SVG's `matrix(a b c d e f)` uses.
class Matrix {
  const Matrix(this.a, this.b, this.c, this.d, this.e, this.f);

  const Matrix.identity() : this(1, 0, 0, 1, 0, 0);

  const Matrix.translate(double tx, double ty) : this(1, 0, 0, 1, tx, ty);

  const Matrix.scale(double sx, double sy) : this(sx, 0, 0, sy, 0, 0);

  final double a;
  final double b;
  final double c;
  final double d;
  final double e;
  final double f;

  Offset apply(Offset p) =>
      Offset(a * p.dx + c * p.dy + e, b * p.dx + d * p.dy + f);

  /// `this` followed by [other] — i.e. `other * this` in column-vector order,
  /// so `Matrix.translate(...).then(Matrix.scale(...))` scales about the
  /// translated origin, matching how nested SVG `transform` attributes read.
  Matrix then(Matrix other) => Matrix(
    other.a * a + other.c * b,
    other.b * a + other.d * b,
    other.a * c + other.c * d,
    other.b * c + other.d * d,
    other.a * e + other.c * f + other.e,
    other.b * e + other.d * f + other.f,
  );

  /// The largest scale factor this transform applies, used to pick a curve
  /// flattening tolerance in user space that stays sub-pixel in device space.
  double get maxScale {
    final sx = sqrt(a * a + b * b);
    final sy = sqrt(c * c + d * d);
    return sx > sy ? sx : sy;
  }
}
