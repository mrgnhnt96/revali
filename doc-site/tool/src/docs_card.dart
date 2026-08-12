/// The docs.revali.dev social card: the mark, an eyebrow, and the page's own
/// title poured in at render time.
library;

import 'dart:typed_data';

import 'package:og_card/og_card.dart';

import 'brand.dart';

const cardWidth = 1600;
const cardHeight = 675;

/// Left edge shared by every text block on the card.
const _left = 490.0;

/// Where the title may run to before it has to wrap. Leaves the wing motif on
/// the right edge clear.
const _titleRight = 1390.0;

const _titleCap = 72.0;
const _lineHeight = 104.0;

/// Bumped whenever the artwork or layout changes, so cached cards from an
/// older design are treated as stale even though their titles have not moved.
const templateVersion = 1;

/// Renders one card for a page called [title].
Uint8List renderDocsCard({required String title, required TypeFace bold, required TypeFace semi}) {
  final canvas = OgCanvas(width: cardWidth, height: cardHeight)
    ..fillRect(
      const Rect(0, 0, 1600, 675),
      LinearGradientPaint(
        from: const Offset(0, 0),
        to: const Offset(1600, 675),
        stops: const [
          ColorStop(0, Color(0xff, 0xff, 0xff)),
          ColorStop(0.55, Color(0xf4, 0xf6, 0xfe)),
          ColorStop(1, Color(0xe6, 0xea, 0xfb)),
        ],
      ),
    )
    // Rotate, then scale, then translate: the reverse of how SVG lists them,
    // since each transform applies to the one before it.
    ..fillPath(
      wing(),
      const SolidPaint(indigo, opacity: 0.09),
      transform: rotate(
        -8,
        const Offset(60, 90),
      ).then(const Matrix.scale(4.2, 4.2)).then(const Matrix.translate(1180, -120)),
    );

  final markAt = const Matrix.scale(1.6, 1.6).then(const Matrix.translate(104, 169.6));
  canvas
    ..fillPath(
      wing(),
      LinearGradientPaint(
        from: const Offset(20, 10),
        to: const Offset(120, 170),
        stops: const [
          ColorStop(0, Color(0xfb, 0xbf, 0x24)),
          ColorStop(0.5, Color(0xf5, 0x9e, 0x0b)),
          ColorStop(1, Color(0xd9, 0x77, 0x06)),
        ],
      ),
      transform: markAt,
    )
    ..fillPath(
      markLetter(),
      LinearGradientPaint(
        from: const Offset(100, 50),
        to: const Offset(190, 210),
        stops: const [ColorStop(0, Color(0x7a, 0x8d, 0xf0)), ColorStop(1, Color(0x4e, 0x5f, 0xc6))],
      ),
      transform: markAt,
    );

  _draw(canvas, semi, 'REVALI DOCS', cap: 26, baseline: 210, color: indigo, tracking: 0.14);

  final lines = _wrap(bold, title, _titleCap, _titleRight - _left);
  // A wrapped title starts higher so the block stays optically centred.
  var baseline = lines.length > 1 ? 330.0 : 372.0;
  for (final line in lines) {
    _draw(canvas, bold, line, cap: _titleCap, baseline: baseline, color: ink);
    baseline += _lineHeight;
  }

  _draw(
    canvas,
    semi,
    'docs.revali.dev',
    cap: 34,
    baseline: lines.length > 1 ? 545 : 500,
    color: muted,
  );

  return canvas.toPng();
}

void _draw(
  OgCanvas canvas,
  TypeFace face,
  String text, {
  required double cap,
  required double baseline,
  required Color color,
  double tracking = 0,
}) {
  final run = face.outline(text, capHeight: cap, tracking: tracking);
  final ink = run.inkBounds;
  if (ink == null) return;
  canvas.fillPath(
    run.path,
    SolidPaint(color),
    // Align on the ink, not the advance: the first glyph's side bearing is
    // whitespace, and lining up on it leaves every block looking indented.
    transform: Matrix.translate(_left - ink.left, baseline),
  );
}

/// Greedy word wrap. A page title is whatever someone wrote in the front
/// matter, so the only safe assumption is that one will eventually be too long.
///
/// A single word wider than [maxWidth] is left to overflow rather than being
/// broken mid-word -- a hyphenated `Configura-` reads worse than a long line,
/// and [_titleRight] already leaves margin for it.
List<String> _wrap(TypeFace face, String text, double cap, double maxWidth) {
  final lines = <String>[];
  var current = '';
  for (final word in text.split(RegExp(r'\s+'))) {
    if (word.isEmpty) continue;
    final candidate = current.isEmpty ? word : '$current $word';
    if (current.isEmpty || face.outline(candidate, capHeight: cap).advance <= maxWidth) {
      current = candidate;
    } else {
      lines.add(current);
      current = word;
    }
  }
  if (current.isNotEmpty) lines.add(current);
  // Three lines would collide with the domain; the layout is built for two.
  if (lines.length > 2) {
    return [lines[0], '${lines[1]}…'];
  }
  return lines;
}
