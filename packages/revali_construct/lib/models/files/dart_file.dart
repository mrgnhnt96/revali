import 'package:path/path.dart' as p;
import 'package:revali_construct/models/files/part_file.dart';

class DartFile {
  DartFile({
    required this.basename,
    required this.content,
    List<PartFile> parts = const [],
  }) : parts = parts.map((e) {
          if (e.path.isEmpty) {
            throw Exception('Part file path cannot be empty.');
          }

          for (final partPath in e.path) {
            if (partPath.isEmpty) {
              throw Exception('Part file path cannot contain empty parts.');
            }

            if (partPath.contains(RegExp(r'\\|\/|\.\\|\.{2,}|^\.'))) {
              throw Exception('Part file path cannot contain relative paths.');
            }
          }

          if (!e.path.last.endsWith('.dart')) {
            throw Exception('Part file path must end with .dart.');
          }

          return e;
        }).toList();

  final String basename;
  final String content;
  final List<PartFile> parts;

  Iterable<MapEntry<String, String>> getPartContent() {
    return parts.map(
      (part) => MapEntry(
        p.joinAll(part.path),
        part.getContent(this),
      ),
    );
  }

  String getContent() {
    final partDirectives =
        parts.map((part) => "part '${p.joinAll(part.path)}';").join('\n');

    // inject part directives after all import statements
    final importIndex = content.lastIndexOf('import');
    String importStatements = '';
    String contentWithoutImports = content;
    if (importIndex != -1) {
      final importEndIndex = content.indexOf(';', importIndex);
      importStatements = content.substring(0, importEndIndex + 1);

      contentWithoutImports = content.substring(importEndIndex + 1);
    }

    return '''
$importStatements

$partDirectives
$contentWithoutImports'''
        .trim();
  }
}
