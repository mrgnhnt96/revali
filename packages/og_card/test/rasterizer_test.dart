import 'package:og_card/og_card.dart';
import 'package:test/test.dart';

/// Alpha of the pixel at ([x], [y]).
int alphaAt(OgCanvas canvas, int x, int y) =>
    canvas.pixels[(y * canvas.width + x) * 4 + 3];

/// Red channel of the pixel at ([x], [y]).
int redAt(OgCanvas canvas, int x, int y) =>
    canvas.pixels[(y * canvas.width + x) * 4];

void main() {
  group('coverage', () {
    test('a rect covers its interior fully and leaves outside untouched', () {
      final canvas = OgCanvas(
        width: 20,
        height: 20,
      )..fillRect(const Rect(5, 5, 15, 15), const SolidPaint(Color(255, 0, 0)));

      expect(alphaAt(canvas, 10, 10), 255, reason: 'interior');
      expect(alphaAt(canvas, 2, 2), 0, reason: 'outside');
      expect(alphaAt(canvas, 17, 10), 0, reason: 'right of the edge');
    });

    test('a half-covered pixel gets roughly half alpha', () {
      final canvas = OgCanvas(width: 10, height: 10)
        ..fillRect(const Rect(0, 0, 5.5, 10), const SolidPaint(Color(0, 0, 0)));

      // Column 5 is covered from x=5.0 to x=5.5.
      expect(alphaAt(canvas, 5, 5), closeTo(128, 12));
      expect(alphaAt(canvas, 4, 5), 255);
      expect(alphaAt(canvas, 6, 5), 0);
    });
  });

  group('fill rules', () {
    /// A square with a counter wound the opposite way, as a glyph would be.
    VectorPath ringWithHole() => VectorPath()
      ..moveTo(0, 0)
      ..lineTo(20, 0)
      ..lineTo(20, 20)
      ..lineTo(0, 20)
      ..close()
      ..moveTo(5, 15)
      ..lineTo(15, 15)
      ..lineTo(15, 5)
      ..lineTo(5, 5)
      ..close();

    test('non-zero leaves a hole where the counter runs the other way', () {
      final canvas = OgCanvas(width: 20, height: 20)
        ..fillPath(ringWithHole(), const SolidPaint(Color(0, 0, 0)));

      expect(alphaAt(canvas, 10, 10), 0, reason: 'counter should be a hole');
      expect(alphaAt(canvas, 2, 10), 255, reason: 'ring body');
    });

    test('same-direction sub-paths union rather than cancel', () {
      // Both wound the same way, so non-zero fills the overlap once.
      final path = VectorPath()
        ..addRect(const Rect(0, 0, 12, 20))
        ..addRect(const Rect(8, 0, 20, 20));

      final canvas = OgCanvas(width: 20, height: 20)
        ..fillPath(path, const SolidPaint(Color(0, 0, 0)));

      expect(alphaAt(canvas, 10, 10), 255, reason: 'overlap stays filled');
    });

    test('even-odd punches a hole through the overlap', () {
      final path = VectorPath()
        ..addRect(const Rect(0, 0, 12, 20))
        ..addRect(const Rect(8, 0, 20, 20));

      final canvas = OgCanvas(width: 20, height: 20)
        ..fillPath(
          path,
          const SolidPaint(Color(0, 0, 0)),
          rule: FillRule.evenOdd,
        );

      expect(alphaAt(canvas, 10, 10), 0);
      expect(alphaAt(canvas, 2, 10), 255);
    });
  });

  group('paint', () {
    test('a gradient moves with the shape it fills', () {
      // Red at x=0 through blue at x=10, but drawn shifted 10 to the right.
      final paint = LinearGradientPaint(
        from: const Offset(0, 0),
        to: const Offset(10, 0),
        stops: const [
          ColorStop(0, Color(255, 0, 0)),
          ColorStop(1, Color(0, 0, 255)),
        ],
      );

      final canvas = OgCanvas(width: 20, height: 4)
        ..fillPath(
          VectorPath()..addRect(const Rect(0, 0, 10, 4)),
          paint,
          transform: const Matrix.translate(10, 0),
        );

      // If the ramp had stayed pinned to the device it would read blue here.
      expect(
        redAt(canvas, 10, 2),
        greaterThan(200),
        reason: 'gradient start should travel with the rect',
      );
      expect(redAt(canvas, 19, 2), lessThan(60));
    });

    test('opacity scales coverage', () {
      final canvas = OgCanvas(width: 10, height: 10)
        ..fillRect(
          const Rect(0, 0, 10, 10),
          const SolidPaint(Color(0, 0, 0), opacity: 0.5),
        );

      expect(alphaAt(canvas, 5, 5), closeTo(128, 2));
    });
  });

  group('stroke', () {
    test('round-capped stroke is solid along its length, not seamed', () {
      final line = VectorPath()
        ..moveTo(5, 20)
        ..lineTo(35, 20);

      final canvas = OgCanvas(width: 40, height: 40)
        ..fillPath(strokeToPath(line, 10), const SolidPaint(Color(0, 0, 0)));

      // Every sample along the centre line must be fully covered; a capsule
      // wound the wrong way would cancel and leave gaps at the joins.
      for (var x = 6; x < 34; x++) {
        expect(alphaAt(canvas, x, 20), 255, reason: 'gap at x=$x');
      }
      expect(alphaAt(canvas, 20, 30), 0, reason: 'outside the stroke width');
    });

    test('a bend stays solid through the join', () {
      final bend = VectorPath()
        ..moveTo(10, 10)
        ..lineTo(30, 10)
        ..lineTo(30, 30);

      final canvas = OgCanvas(width: 40, height: 40)
        ..fillPath(strokeToPath(bend, 8), const SolidPaint(Color(0, 0, 0)));

      expect(alphaAt(canvas, 30, 10), 255, reason: 'the corner itself');
      expect(alphaAt(canvas, 29, 11), 255);
    });
  });

  test('png encodes at the requested size', () {
    final canvas = OgCanvas(width: 32, height: 16)
      ..fillRect(const Rect(0, 0, 32, 16), const SolidPaint(Color(1, 2, 3)));
    final png = canvas.toPng();

    // PNG signature, then IHDR width/height as big-endian uint32s.
    expect(png.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
    expect(png[16] << 24 | png[17] << 16 | png[18] << 8 | png[19], 32);
    expect(png[20] << 24 | png[21] << 16 | png[22] << 8 | png[23], 16);
  });
}
