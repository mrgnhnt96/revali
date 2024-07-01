import 'package:path/path.dart' as p;
import 'package:revali_construct/models/files/dart_file.dart';

final class PartFile {
  PartFile({
    required this.path,
    required this.content,
  })  : assert(path.isNotEmpty, 'Path cannot be empty.'),
        assert(path.last.endsWith('.dart'), 'Path must end with .dart.');

  final List<String> path;
  final String content;

  String getContent(DartFile parent) {
    if (content.contains(RegExp("^import '"))) {
      throw Exception('Part files cannot contain import statements.');
    }

    final partsToParent = [
      for (final _ in path.skip(1)) '..',
      parent.basename,
    ];

    final parentPath = p.joinAll(partsToParent);

    return '''
part of '$parentPath';

$content''';
  }
}
