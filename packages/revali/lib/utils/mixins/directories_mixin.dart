import 'package:file/file.dart';
import 'package:revali/utils/extensions/directory_extensions.dart';

mixin DirectoriesMixin {
  FileSystem get fs;

  Future<Directory> rootOf(String path) async {
    final root = await fs.directory(path).getRoot();

    if (root == null) {
      // TODO(mrgnhnt): throw a custom exception
      throw Exception('Failed to find root of project');
    }

    return root;
  }
}
