import 'package:file/file.dart';
import 'package:path/path.dart' as p;

extension DirectoryX on Directory {
  Future<Directory?> getRoot() async {
    File? file;
    Directory? directory = this;
    while (file == null && directory != null) {
      final pubspec = directory.childFile('pubspec.yaml');

      if (await pubspec.exists()) {
        file = pubspec;
        break;
      }

      directory = directory.parent;
    }

    if (file == null) {
      return null;
    }

    return directory;
  }

  Future<Directory?> getRoutes() async {
    final root = await getRoot();

    if (root == null) {
      throw Exception('Failed to find project root');
    }

    return root.childDirectory('routes');
  }

  /// retrieves the .dart_tool directory,
  /// the directory may _NOT_ exist
  Future<Directory> getDartTool() async {
    final root = await getRoot();

    if (root == null) {
      throw Exception('Failed to find project root');
    }

    return root.childDirectory('.dart_tool');
  }

  /// Retrieves a file within the .dart_tool directory
  /// the file may _NOT_ exist
  Future<File> getDartToolFile(String basename) async {
    final dartTool = await getDartTool();

    return dartTool.childFile(basename);
  }

  /// The utilities directory within the .dart_tool directory
  /// specifically used with revali
  ///
  /// The directory may _NOT_ exist
  Future<Directory> getInternalRevali() async {
    final dartTool = await getDartTool();

    return dartTool.childDirectory('revali');
  }

  /// retrieves the file within [getInternalRevali] dir
  ///
  /// Should be 1 level deep only
  ///
  /// The file may _NOT_ exist
  Future<File> getInternalRevaliFile(String basename) async {
    final revali = await getInternalRevali();

    return revali.childFile(basename);
  }

  Future<Directory> getPublic() async {
    final root = await getRoot();

    if (root == null) {
      throw Exception('Failed to find project root');
    }

    return root.childDirectory('public');
  }

  Future<Directory> getServer() async {
    final root = await getRevali();

    return root.childDirectory('server');
  }

  Future<Directory> getBuild() async {
    final root = await getRevali();

    return root.childDirectory('build');
  }

  /// The directory within the root directory
  /// specifically used for revali
  ///
  /// The directory may _NOT_ exist
  Future<Directory> getRevali() async {
    final root = await getRoot();

    if (root == null) {
      throw Exception('Failed to find project root');
    }

    return root.childDirectory('.revali');
  }

  /// retrieves the file within [getRevali] dir
  ///
  /// Should be 1 level deep only
  ///
  /// The file may _NOT_ exist
  Future<File> getRevaliFile(String basename) async {
    final revali = await getRevali();
    final normalized = p.normalize(p.join(revali.path, basename));
    final relative = p.relative(normalized, from: revali.path);

    return revali.childFile(relative);
  }

  File sanitizedChildFile(String basename) {
    final normalized = p.normalize(p.join(path, basename));
    final relative = p.relative(normalized, from: path);

    return childFile(relative);
  }

  Directory sanitizedChildDirectory(String basename) {
    final normalized = p.normalize(p.join(path, basename));
    final relative = p.relative(normalized, from: path);

    return childDirectory(relative);
  }
}
