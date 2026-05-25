import 'package:path/path.dart' as p;

/// Converts a `file:` URI from analyzer element metadata into a relative
/// import path safe to embed in generated Dart source on all platforms.
///
/// Windows file paths use backslashes; when written into Dart string literals,
/// sequences like `\r` in `\routes` become carriage returns and break compilation.
String fileUriToRelativeImportPath(String uri) {
  final filePath = Uri.parse(uri).toFilePath();
  return p.relative(filePath).replaceAll(r'\', '/');
}
