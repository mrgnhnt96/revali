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
        part.basename,
        part.getContent(this),
      ),
    );
  }

  String getContent() {
    final partDirectives =
        parts.map((part) => "part '${part.basename}';").join('\n');

    // inject part directives after all import statements
    final importIndex = content.lastIndexOf('import');
    final importEndIndex = content.indexOf(';', importIndex);
    final importStatements = content.substring(0, importEndIndex + 1);

    final contentWithoutImports = content.substring(importEndIndex + 1);

    return '''
$importStatements
$partDirectives
$contentWithoutImports''';
  }
}
