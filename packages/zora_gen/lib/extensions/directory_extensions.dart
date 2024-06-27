import 'package:file/file.dart';

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

    // TODO(mrgnhnt): Search for routes dir
    return root.childDirectory('routes');
  }

  /// retrieves the dartTool directory,
  /// the directory may _NOT_ exist
  Future<Directory> getDartTool() async {
    final root = await getRoot();

    if (root == null) {
      throw Exception('Failed to find project root');
    }

    return root.childDirectory('.dart_tool');
  }

  /// The utilities directory within the .dart_tool directory
  /// specifically used with Zora
  ///
  /// The directory may _NOT_ exist
  Future<Directory> getInternalZora() async {
    final dartTool = await getDartTool();

    return dartTool.childDirectory('zora');
  }

  /// retrieves the file within [getInternalZora] dir
  ///
  /// Should be 1 level deep only
  ///
  /// The file may _NOT_ exist
  Future<File> getInternalZoraFile(String basename) async {
    final zora = await getInternalZora();

    return zora.childFile(basename);
  }

  /// The directory within the root directory
  /// specifically used for Zora
  ///
  /// The directory may _NOT_ exist
  Future<Directory> getZora() async {
    final root = await getRoot();

    if (root == null) {
      throw Exception('Failed to find project root');
    }

    return root.childDirectory('.zora');
  }

  /// retrieves the file within [getZora] dir
  ///
  /// Should be 1 level deep only
  ///
  /// The file may _NOT_ exist
  Future<File> getZoraFile(String basename) async {
    final zora = await getZora();

    return zora.childFile(basename);
  }
}
