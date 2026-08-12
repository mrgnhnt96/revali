import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'package:og_card/src/geometry.dart';
import 'package:og_card/src/paint.dart';
import 'package:og_card/src/rasterizer.dart';
import 'package:og_card/src/vector_path.dart';

/// An RGBA drawing surface that fills paths and encodes itself as PNG.
///
/// Everything is straight (non-premultiplied) RGBA, blended source-over.
class OgCanvas {
  OgCanvas({
    required this.width,
    required this.height,
    Color background = Color.transparent,
    int subSamples = 5,
  }) : _pixels = Uint8List(width * height * 4),
       _rasterizer = Rasterizer(subSamples: subSamples) {
    if (background.a != 0) {
      for (var i = 0; i < width * height; i++) {
        final o = i * 4;
        _pixels[o] = background.r;
        _pixels[o + 1] = background.g;
        _pixels[o + 2] = background.b;
        _pixels[o + 3] = background.a;
      }
    }
  }

  final int width;
  final int height;
  final Uint8List _pixels;
  final Rasterizer _rasterizer;

  /// Fills [path] with [paint], mapping it through [transform] first.
  void fillPath(
    VectorPath path,
    Paint paint, {
    Matrix transform = const Matrix.identity(),
    FillRule rule = FillRule.nonZero,
  }) {
    final device = path.transformed(transform);
    final devicePaint = paint.transformed(transform);
    _rasterizer.fill(device, width, height, rule, (x, y, coverage) {
      final c = devicePaint.colorAt(x + 0.5, y + 0.5);
      _blend(x, y, c, coverage * devicePaint.opacity);
    });
  }

  void fillRect(Rect rect, Paint paint) {
    fillPath(VectorPath()..addRect(rect), paint);
  }

  void _blend(int x, int y, Color src, double alpha) {
    final a = alpha * (src.a / 255.0);
    if (a <= 0) return;
    final o = (y * width + x) * 4;

    if (a >= 1.0) {
      _pixels[o] = src.r;
      _pixels[o + 1] = src.g;
      _pixels[o + 2] = src.b;
      _pixels[o + 3] = 255;
      return;
    }

    final dstA = _pixels[o + 3] / 255.0;
    final outA = a + dstA * (1 - a);
    if (outA <= 0) {
      _pixels[o + 3] = 0;
      return;
    }
    // Straight-alpha source-over: composite in premultiplied space, then
    // divide back out so the stored buffer stays non-premultiplied.
    _pixels[o] = _channel(src.r, _pixels[o], a, dstA, outA);
    _pixels[o + 1] = _channel(src.g, _pixels[o + 1], a, dstA, outA);
    _pixels[o + 2] = _channel(src.b, _pixels[o + 2], a, dstA, outA);
    _pixels[o + 3] = (outA * 255).round().clamp(0, 255);
  }

  static int _channel(int src, int dst, double a, double dstA, double outA) {
    final v = (src * a + dst * dstA * (1 - a)) / outA;
    return v.round().clamp(0, 255);
  }

  /// The raw RGBA bytes, row-major, four bytes per pixel.
  Uint8List get pixels => _pixels;

  /// Encodes the surface as a PNG.
  ///
  /// [level] is zlib's 0..9; the default trades a little size for the speed
  /// that matters when a build renders a card per page.
  Uint8List toPng({int level = 6}) {
    final image = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: _pixels.buffer,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );
    return img.encodePng(image, level: level);
  }
}
