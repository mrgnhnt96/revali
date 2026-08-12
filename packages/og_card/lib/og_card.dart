/// Generate Open Graph social card images as PNG, in pure Dart.
///
/// No native binaries, no Python, no Flutter: text is outlined from a font
/// with `glyph_path`, filled by an anti-aliasing scanline rasterizer, and
/// encoded with `package:image`.
library;

export 'src/canvas.dart';
export 'src/geometry.dart';
export 'src/paint.dart';
export 'src/rasterizer.dart' show Rasterizer;
export 'src/stroke.dart';
export 'src/text.dart';
export 'src/vector_path.dart';
