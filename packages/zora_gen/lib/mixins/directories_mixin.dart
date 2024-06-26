import 'package:file/file.dart';
import 'package:zora_gen/extensions/directory_extensions.dart';

mixin DirectoriesMixin {
  FileSystem get fs;

  final _roots = <String, Directory>{};
  Future<Directory> rootOf(String path) async {
    if (_roots[path] case final root?) {
      return root;
    }

    final root = await fs.directory(path).getRoot();

    if (root == null) {
      // TODO(mrgnhnt): throw a custom exception
      throw Exception('Failed to find root of project');
    }

    return _roots[path] = root;
  }
}
