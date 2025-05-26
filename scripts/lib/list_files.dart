import 'package:file/local.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

void main() {
  const workspace = '/Users/morgan/Documents/develop.nosync/revali';

  final paths = Glob(p.join(workspace, '**.dart'), recursive: true)
      .listFileSystemSync(const LocalFileSystem());

  print('Length: ${paths.length}');

  final nonDotRevali = <String>[];
  final dotRevaliPattern =
      Glob(p.join(workspace, '**', '.revali', '**'), recursive: true);
  for (final file in paths) {
    if (dotRevaliPattern.matches(file.path)) {
      continue;
    }

    nonDotRevali.add(file.path);
  }

  print('Non .revali: ${nonDotRevali.length}');
}
