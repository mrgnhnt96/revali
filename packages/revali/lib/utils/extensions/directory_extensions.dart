import 'dart:convert';

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
  Future<File> getPackageConfig() async {
    final dartTool = await getDartTool();

    final packageConfig = dartTool.childFile('package_config.json');

    if (await packageConfig.exists()) {
      return packageConfig;
    }

    final workspaceRef =
        dartTool.childFile(p.join('pub', 'workspace_ref.json'));

    if (!await workspaceRef.exists()) {
      throw Exception('Failed to find package config or workspace_ref');
    }

    final workspaceRefJson =
        jsonDecode(await workspaceRef.readAsString()) as Map;
    final workspaceRoot = switch (workspaceRefJson['workspaceRoot']) {
      final String workspaceRoot =>
        workspaceRoot.replaceAll(RegExp('${p.separator}..' r'$'), ''),
      final other => throw Exception('Invalid workspace root: $other'),
    };

    // clean up path, the workspaceRoot is usually a path relative and is '../../../'

    final workspace =
        fileSystem.directory(p.normalize(p.join(dartTool.path, workspaceRoot)));

    return workspace
        .childDirectory('.dart_tool')
        .childFile('package_config.json');
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

    if (!await revali.exists()) {
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
    final segments = p.absolute(path, p.normalize(basename)).split(p.separator)
      ..removeWhere((element) => element == '..');

    final relative =
        p.relative('${p.separator}${p.joinAll(segments)}', from: path);

    return childFile(relative);
  }

  Directory sanitizedChildDirectory(String basename) {
    final segments = p.absolute(path, p.normalize(basename)).split(p.separator)
      ..removeWhere((element) => element == '..');

    final relative =
        p.relative('${p.separator}${p.joinAll(segments)}', from: path);

    return childDirectory(relative);
  }
}
