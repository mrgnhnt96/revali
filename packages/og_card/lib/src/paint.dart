import 'package:og_card/src/geometry.dart';

/// A straight (non-premultiplied) 8-bit RGBA colour.
class Color {
  const Color(this.r, this.g, this.b, [this.a = 255]);

  /// Parses `#rgb`, `#rrggbb` or `#rrggbbaa`. The leading `#` is optional.
  factory Color.hex(String value, {int alpha = 255}) {
    var s = value.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 3) {
      s = '${s[0]}${s[0]}${s[1]}${s[1]}${s[2]}${s[2]}';
    }
    if (s.length != 6 && s.length != 8) {
      throw FormatException('not a hex colour: $value');
    }
    final v = int.parse(s, radix: 16);
    if (s.length == 6) {
      return Color((v >> 16) & 0xff, (v >> 8) & 0xff, v & 0xff, alpha);
    }
    return Color((v >> 24) & 0xff, (v >> 16) & 0xff, (v >> 8) & 0xff, v & 0xff);
  }

  final int r;
  final int g;
  final int b;
  final int a;

  Color withOpacity(double opacity) =>
      Color(r, g, b, (a * opacity).round().clamp(0, 255));

  static const transparent = Color(0, 0, 0, 0);
}

/// One stop in a gradient ramp.
class ColorStop {
  const ColorStop(this.offset, this.color);

  /// Position along the gradient, 0..1.
  final double offset;
  final Color color;
}

/// Something that can answer "what colour is this pixel".
abstract class Paint {
  const Paint();

  /// The colour at a point, in whatever space the paint was defined in.
  Color colorAt(double x, double y);

  /// A uniform multiplier applied on top of the returned colour's own alpha.
  double get opacity;

  /// The same paint expressed in the space [matrix] maps into.
  ///
  /// A gradient's coordinates live in the same user space as the shape it
  /// fills, so whatever transform moves the shape has to move the gradient
  /// with it -- otherwise the ramp stays pinned to the device pixels and
  /// slides across the artwork. This mirrors SVG's `userSpaceOnUse`.
  Paint transformed(Matrix matrix);
}

/// A single flat colour.
class SolidPaint extends Paint {
  const SolidPaint(this.color, {this.opacity = 1.0});

  final Color color;

  @override
  final double opacity;

  @override
  Color colorAt(double x, double y) => color;

  @override
  Paint transformed(Matrix matrix) => this;
}

/// A linear gradient between two points in user space, matching SVG's
/// `gradientUnits="userSpaceOnUse"`.
class LinearGradientPaint extends Paint {
  LinearGradientPaint({
    required this.from,
    required this.to,
    required this.stops,
    this.opacity = 1.0,
  }) : assert(stops.length >= 2, 'a gradient needs at least two stops'),
       _dx = to.dx - from.dx,
       _dy = to.dy - from.dy {
    final lenSq = _dx * _dx + _dy * _dy;
    _invLenSq = lenSq == 0 ? 0 : 1 / lenSq;
  }

  final Offset from;
  final Offset to;
  final List<ColorStop> stops;

  @override
  final double opacity;

  final double _dx;
  final double _dy;
  late final double _invLenSq;

  @override
  Color colorAt(double x, double y) {
    final t = (((x - from.dx) * _dx + (y - from.dy) * _dy) * _invLenSq).clamp(
      0.0,
      1.0,
    );

    if (t <= stops.first.offset) return stops.first.color;
    if (t >= stops.last.offset) return stops.last.color;

    for (var i = 0; i < stops.length - 1; i++) {
      final lo = stops[i];
      final hi = stops[i + 1];
      if (t < lo.offset || t > hi.offset) continue;
      final span = hi.offset - lo.offset;
      final k = span <= 0 ? 0.0 : (t - lo.offset) / span;
      return Color(
        _mix(lo.color.r, hi.color.r, k),
        _mix(lo.color.g, hi.color.g, k),
        _mix(lo.color.b, hi.color.b, k),
        _mix(lo.color.a, hi.color.a, k),
      );
    }
    return stops.last.color;
  }

  static int _mix(int a, int b, double t) => (a + (b - a) * t).round();

  @override
  Paint transformed(Matrix matrix) => LinearGradientPaint(
    from: matrix.apply(from),
    to: matrix.apply(to),
    stops: stops,
    opacity: opacity,
  );
}
