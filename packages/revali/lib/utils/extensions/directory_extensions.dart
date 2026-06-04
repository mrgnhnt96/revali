import 'package:file/file.dart';
import 'package:path/path.dart' as p;
import 'package:revali/utils/package_config_resolution.dart';

extension DirectoryX on Directory {
  Future<Directory?> getRoot() async {
    File? file;
    Directory? directory = this;
    while (file == null && directory != null) {
      final pubspec = directory.childFile('pubspec.yaml');

      if (pubspec.existsSync()) {
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
  Future<File> getPackageConfig() => resolvePackageConfigFile(this);

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

  /// A directory within the `lib` directory that
  /// contains the revali components
  ///
  /// This directory will trigger a re-generation of the
  /// code when a file is added, removed, or modified
  Future<Directory> getComponents() async {
    final root = await getRoot();

    if (root == null) {
      throw Exception('Failed to find project root');
    }

    return root.childDirectory('lib').childDirectory('components');
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

  Stream<Directory> getConstructs() async* {
    final revali = await getRevali();

    if (!revali.existsSync()) {
      return;
    }

    final dirs = revali.listSync().whereType<Directory>();

    for (final dir in dirs) {
      if (dir.basename == 'server') continue;
      if (dir.basename == 'build') continue;

      yield dir;
    }
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
    return _sanitizedChild(basename, childFile);
  }

  Directory sanitizedChildDirectory(String basename) {
    return _sanitizedChild(basename, childDirectory);
  }

  T _sanitizedChild<T>(String basename, T Function(String relative) create) {
    final normalizedBase = p.normalize(path);
    final absolute = p.normalize(p.join(normalizedBase, basename));
    final segments = p.split(absolute)
      ..removeWhere((segment) => segment == '..' || segment == '.');
    final sanitized = p.joinAll(segments);
    final relative = p.relative(sanitized, from: normalizedBase);

    return create(relative);
  }
}
