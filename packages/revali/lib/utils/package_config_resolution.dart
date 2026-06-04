import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;

Future<Directory?> _findProjectRoot(Directory directory) async {
  var current = directory;
  while (true) {
    if (current.childFile('pubspec.yaml').existsSync()) {
      return current;
    }

    final parent = current.parent;
    if (parent.path == current.path) {
      return null;
    }
    current = parent;
  }
}

/// Finds the nearest `.dart_tool/package_config.json` by walking up from the
/// project root of [directory].
Future<String?> findPackageConfigPath(Directory directory) async {
  final root = await _findProjectRoot(directory);
  if (root == null) {
    return null;
  }

  var searchDirectory = io.Directory(root.path);
  if (!searchDirectory.isAbsolute) {
    searchDirectory = searchDirectory.absolute;
  }
  if (!searchDirectory.existsSync()) {
    return null;
  }

  while (true) {
    final configFile = io.File(
      p.join(searchDirectory.path, '.dart_tool', 'package_config.json'),
    );
    if (configFile.existsSync()) {
      return configFile.path;
    }

    final parent = searchDirectory.parent;
    if (parent.path == searchDirectory.path) {
      break;
    }
    searchDirectory = parent;
  }

  return null;
}

/// Resolves the package config file for [directory].
///
/// Returns the local project config path when no config can be found.
Future<File> resolvePackageConfigFile(Directory directory) async {
  final root = await _findProjectRoot(directory);
  final dartTool = (root ?? directory).childDirectory('.dart_tool');
  final localConfig = dartTool.childFile('package_config.json');
  final resolvedPath = await findPackageConfigPath(directory);

  if (resolvedPath != null) {
    return directory.fileSystem.file(resolvedPath);
  }

  return localConfig;
}

/// Loads the package configuration for [directory], if one exists.
Future<PackageConfig?> loadProjectPackageConfig(Directory directory) async {
  final configPath = await findPackageConfigPath(directory);
  if (configPath == null) {
    return null;
  }

  return loadPackageConfig(io.File(configPath));
}

/// Returns the package URI root path relative to the package root directory.
String relativePackageUri(Package package) {
  final rootPath = package.root.toFilePath();
  final packageUriRootPath = package.packageUriRoot.toFilePath();
  final relative = p.relative(packageUriRootPath, from: rootPath);

  return p.normalize(relative).endsWith(p.separator)
      ? p.normalize(relative)
      : '${p.normalize(relative)}${p.separator}';
}
