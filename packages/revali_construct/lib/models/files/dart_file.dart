import 'package:path/path.dart' as p;
import 'package:revali_construct/models/files/any_file.dart';
import 'package:revali_construct/models/files/part_file.dart';

class DartFile extends AnyFile {
  DartFile({
    required super.basename,
    required super.content,
    super.segments,
    List<PartFile> parts = const [],
  }) : parts = parts.map((e) {
         if (e.path.isEmpty) {
           throw AssertionError('Part file path cannot be empty.');
         }

         for (final partPath in e.path) {
           if (partPath.isEmpty) {
             throw AssertionError('Part file path cannot contain empty parts.');
           }

           if (partPath.contains(RegExp(r'\\|\/|\.\\|\.{2,}|^\.'))) {
             throw AssertionError(
               'Part file path cannot contain relative paths.',
             );
           }
         }

         if (e.path.last.endsWith('.dart')) {
           throw AssertionError('Part file path must not end with .dart.');
         }

         return e;
       }).toList(),
       assert(
         parts.toSet().length == parts.length,
         'Part files must be unique within a Dart file.',
       ),
       super(extension: 'dart') {
    for (final part in parts) {
      part.parent = this;
    }
  }

  final List<PartFile> parts;

  @override
  List<AnyFile> get subFiles => parts;

  @override
  String get content {
    final content = super.content;

    final partDirectives = parts.map((part) {
      final pathParts = p.split(part.fileName)..remove('lib');

      return "part '${p.joinAll(pathParts)}';";
    }).toList()..sort();

    final partString = partDirectives.join('\n');

    // inject part directives after all import statements
    final directiveIndex = switch (content.contains('export')) {
      true => content.lastIndexOf('export'),
      false => content.lastIndexOf('import'),
    };
    var directiveStatements = '';
    var contentWithoutDirectives = content;

    if (directiveIndex != -1) {
      final directiveEndIndex = content.indexOf(';', directiveIndex);
      directiveStatements = content.substring(0, directiveEndIndex + 1);

      contentWithoutDirectives = content.substring(directiveEndIndex + 1);
    }

    final trimmed =
        '''
$directiveStatements

$partString
$contentWithoutDirectives'''
            .trim();

    return '$trimmed\n';
  }
}
