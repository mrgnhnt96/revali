import 'package:path/path.dart' as p;
import 'package:zora_construct/models/files/part_file.dart';

class DartFile {
  const DartFile({
    required this.basename,
    required this.content,
    this.parts = const [],
  });

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
