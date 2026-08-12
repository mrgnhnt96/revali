import 'dart:typed_data';

import 'package:glyph_path/glyph_path.dart' as gp;

import 'package:og_card/src/geometry.dart';
import 'package:og_card/src/vector_path.dart';

/// A single font, loaded once and reused for every string it sets.
///
/// Parsing is the expensive part, so hold onto a [TypeFace] rather than
/// constructing one per call.
class TypeFace {
  TypeFace._(this._font, this.capHeight, this.unitsPerEm);

  /// Loads a TrueType or OpenType font from its bytes.
  ///
  /// Variable fonts are not interpolated — a variable file renders at its
  /// default instance, which is rarely the weight you meant. Pass a static
  /// instance of the weight you want.
  factory TypeFace.fromBytes(Uint8List bytes) {
    final font = gp.Font.parse(bytes);
    return TypeFace._(
      font,
      _capHeightFromOs2(bytes)?.toDouble() ?? _measuredCapHeight(font),
      font.unitsPerEm,
    );
  }

  final gp.Font _font;

  /// The designer's cap height in font units. Sizing type by this rather than
  /// by em size is what keeps a layout stable across two different families.
  final double capHeight;

  final double unitsPerEm;

  /// Outlines [text] with its baseline at the origin and Y growing downward.
  ///
  /// [capHeight] is the height of a flat capital in user units, not the em
  /// size. [tracking] is extra letter spacing as a fraction of the cap height.
  TextRun outline(
    String text, {
    required double capHeight,
    double tracking = 0,
    bool kerning = true,
  }) {
    if (text.isEmpty) {
      return TextRun._(VectorPath(), 0, null);
    }

    final size = capHeight * unitsPerEm / this.capHeight;
    final result = _font.generateGlyphPaths(
      text,
      fontSize: size,
      kerning: kerning,
    );

    final path = VectorPath();
    var advance = 0.0;
    double? minX;
    double? minY;
    double? maxX;
    double? maxY;
    var index = 0;

    for (final glyph in result.glyphs) {
      // glyph_path positions each glyph itself, but tracking has to be folded
      // in on top, so shift by the spacing accumulated before this glyph.
      final shift = tracking * capHeight * index;
      final dx = glyph.positionX + shift;

      for (final contour in glyph.contours) {
        var first = true;
        for (final cmd in contour.commands) {
          switch (cmd) {
            case gp.MoveTo(:final x, :final y):
              // Font space is Y-up; negate to land in our Y-down space.
              path.moveTo(dx + x, -y);
              first = false;
            case gp.LineTo(:final x, :final y):
              if (first) {
                path.moveTo(dx + x, -y);
                first = false;
              } else {
                path.lineTo(dx + x, -y);
              }
            case gp.QuadTo(
              :final controlX,
              :final controlY,
              :final x,
              :final y,
            ):
              path.quadraticTo(dx + controlX, -controlY, dx + x, -y);
            case gp.CubicTo(
              :final control1X,
              :final control1Y,
              :final control2X,
              :final control2Y,
              :final x,
              :final y,
            ):
              path.cubicTo(
                dx + control1X,
                -control1Y,
                dx + control2X,
                -control2Y,
                dx + x,
                -y,
              );
            case gp.ClosePath():
              path.close();
          }
        }
        path.close();
      }

      final b = glyph.bounds;
      final gx0 = dx + b.minX;
      final gx1 = dx + b.maxX;
      minX = (minX == null || gx0 < minX) ? gx0 : minX;
      maxX = (maxX == null || gx1 > maxX) ? gx1 : maxX;
      // bounds are Y-up, so the flip swaps which extreme is which
      minY = (minY == null || -b.maxY < minY) ? -b.maxY : minY;
      maxY = (maxY == null || -b.minY > maxY) ? -b.minY : maxY;

      // Tracking counts after the last glyph too, matching CSS letter-spacing.
      // Leaving it off makes [advance] a whole space too short, which shows up
      // as creeping drift once several runs are chained into one line.
      advance = dx + glyph.advanceWidth + tracking * capHeight;
      index++;
    }

    final ink = minX == null ? null : Rect(minX, minY!, maxX!, maxY!);
    return TextRun._(path, advance, ink);
  }

  /// `OS/2.sCapHeight`, which glyph_path does not expose.
  ///
  /// Reading it matters: measuring a capital's outline instead picks up the
  /// overshoot on round letters and any hinting slack, which drifts about 1%
  /// from the value the designer set — enough to shift a layout.
  static int? _capHeightFromOs2(Uint8List bytes) {
    if (bytes.length < 12) return null;
    final data = ByteData.sublistView(bytes);
    final numTables = data.getUint16(4);
    for (var i = 0; i < numTables; i++) {
      final record = 12 + 16 * i;
      if (record + 16 > bytes.length) return null;
      final tag = String.fromCharCodes(bytes.sublist(record, record + 4));
      if (tag != 'OS/2') continue;
      final offset = data.getUint32(record + 8);
      if (offset + 90 > bytes.length) return null;
      if (data.getUint16(offset) < 2) return null; // sCapHeight added in v2
      final value = data.getInt16(offset + 88);
      return value > 0 ? value : null;
    }
    return null;
  }

  /// Fallback for fonts whose OS/2 table predates `sCapHeight`: measure the
  /// `H`, which is flat-topped and so carries no overshoot.
  static double _measuredCapHeight(gp.Font font) {
    final probe = font.generateGlyphPaths('H', fontSize: font.unitsPerEm);
    if (probe.glyphs.isEmpty) return font.unitsPerEm * 0.7;
    final b = probe.glyphs.first.bounds;
    return b.maxY - b.minY;
  }
}

/// Outlined text, positioned with its baseline at y = 0.
class TextRun {
  const TextRun._(this.path, this.advance, this.inkBounds);

  /// The glyph outlines, ready to fill.
  final VectorPath path;

  /// Where the next run should start, if you are chaining coloured spans.
  final double advance;

  /// The tight box the ink actually occupies, or `null` for empty text.
  ///
  /// Use this rather than [advance] to align a block optically — the first
  /// glyph's left side bearing is whitespace, and lining up on it leaves text
  /// looking indented.
  final Rect? inkBounds;
}
