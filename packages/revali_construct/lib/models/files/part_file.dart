import 'package:path/path.dart' as p;
import 'package:revali_construct/models/files/dart_file.dart';

final class PartFile extends DartFile {
  PartFile({
    required this.path,
    required super.content,
  })  : assert(path.isNotEmpty, 'Path cannot be empty.'),
        assert(!path.last.endsWith('.dart'), 'Path must not end with .dart.'),
        super(
          basename: p.joinAll(path),
        );

  final List<String> path;

  DartFile? parent;

  @override
  String get content {
    final parent = this.parent;

    if (parent == null) {
      throw Exception('Part files must have a parent.');
    }

    final content = super.content;
    if (content.contains(RegExp("^import '"))) {
      throw Exception('Part files cannot contain import statements.');
    }

    final sanitizedPath = p.split(
      p.joinAll(
        [
          ...[...path]..remove('lib'),
        ].skip(1),
      ),
    );

    final partsToParent = [
      for (final _ in sanitizedPath) '..',
      ...p.split(parent.fileName),
    ]..remove('lib');

    final parentPath = p.joinAll(partsToParent);

    return '''
part of '$parentPath';

$content''';
  }
}
