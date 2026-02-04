import 'dart:convert';
import 'dart:math';

import 'package:file/file.dart';
import 'package:glob/glob.dart';
import 'package:platform/platform.dart';
import 'package:revali/ast/find/interfaces/find.dart';
import 'package:revali/utils/type_def/start_process.dart';

class FindImpl implements Find {
  const FindImpl({
    required this.platform,
    required this.fs,
    required this.startProcess,
  });

  final FileSystem fs;
  final Platform platform;
  final StartProcess startProcess;

  static const _ignoreDirs = [
    '.git',
    'node_modules',
    'build',
    'dist',
    'out',
    'ios',
    'android',
    'windows',
    'macos',
    'linux',
    'web',
    'assets',
  ];

  @override
  Future<List<String>> file(
    String name, {
    required String workingDirectory,
    List<String> ignoreDirs = const [],
    DateTime? lastModified,
  }) {
    switch (platform) {
      case Platform(isLinux: true):
      case Platform(isMacOS: true):
        return _findLinux(
          name,
          workingDirectory: workingDirectory,
          file: true,
          ignoreDirs: ignoreDirs,
          lastModified: lastModified,
        );
      case Platform(isWindows: true):
        return _findWindows(
          name,
          workingDirectory: workingDirectory,
          ignoreDirs: ignoreDirs,
          lastModified: lastModified,
        );
      default:
        throw UnsupportedError(
          'Unsupported platform: ${platform.operatingSystem}',
        );
    }
  }

  Future<List<String>> _findLinux(
    String name, {
    required String workingDirectory,
    required bool file,
    List<String> ignoreDirs = const [],
    DateTime? lastModified,
  }) async {
    final ignore = <String>[
      for (final (index, dir) in _ignoreDirs.followedBy(ignoreDirs).indexed)
        [if (index != 0) '-o', '-path', '*/$dir'].join(' '),
    ];

    final type = file ? 'f' : 'd';
    final lastModifiedArg = switch (lastModified) {
      final DateTime date =>
        '-mmin -${max(DateTime.now().difference(date).inMinutes, 1)}',
      null => '',
    };

    final script =
        "find $workingDirectory \\( ${ignore.join(' ')} \\) -prune -o -name '$name' -type $type $lastModifiedArg -print";

    final result = await startProcess('bash', ['-c', script]);
    final stdout = await result.stdout.transform(utf8.decoder).join();
    return stdout.split('\n').where((e) => e.isNotEmpty).toList();
  }

  Future<List<String>> _findWindows(
    String name, {
    required String workingDirectory,
    List<String> ignoreDirs = const [],
    DateTime? lastModified,
  }) async {
    final files = Glob(
      fs.path.join(workingDirectory, '**', name),
      recursive: true,
    ).listFileSystemSync(fs, followLinks: false);

    // Filter by lastModified if provided
    if (lastModified != null) {
      final cutoffTime = lastModified;
      return files
          .where(
            (file) =>
                file.statSync().modified.isAfter(cutoffTime) ||
                file.statSync().modified.isAtSameMomentAs(cutoffTime),
          )
          .map((e) => e.path)
          .toList();
    }

    return files.map((e) => e.path).toList();
  }

  @override
  Future<List<String>> filesInDirectory(
    String directory, {
    required String workingDirectory,
    List<String> ignoreDirs = const [],
    bool recursive = true,
    DateTime? lastModified,
  }) async {
    final directories = switch (recursive) {
      false => [fs.path.join(workingDirectory, directory)],
      true => switch (platform) {
        Platform(isLinux: true) || Platform(isMacOS: true) => await _findLinux(
          directory,
          workingDirectory: workingDirectory,
          file: false,
          ignoreDirs: ignoreDirs,
          lastModified: lastModified,
        ),
        Platform(isWindows: true) => await _findWindowsDirectory(
          directory,
          workingDirectory: workingDirectory,
          ignoreDirs: ignoreDirs,
          lastModified: lastModified,
        ),
        _ => throw UnsupportedError(
          'Unsupported platform: ${platform.operatingSystem}',
        ),
      },
    };

    final futures = <Future<List<String>>>[];

    for (final directory in directories) {
      futures.add(
        file(
          '*',
          workingDirectory: directory,
          ignoreDirs: ignoreDirs,
          lastModified: lastModified,
        ),
      );
    }

    final results = await Future.wait(futures);
    return results.expand((e) => e).toList();
  }

  Future<List<String>> _findWindowsDirectory(
    String directory, {
    required String workingDirectory,
    List<String> ignoreDirs = const [],
    DateTime? lastModified,
  }) async {
    final directories = Glob(
      fs.path.join(workingDirectory, '**', directory),
      recursive: true,
    ).listFileSystemSync(fs, followLinks: false).whereType<Directory>();

    return directories.map((e) => e.path).toList();
  }
}
