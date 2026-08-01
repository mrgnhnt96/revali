import 'dart:convert';
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:revali_construct/revali_construct.dart';

/// Stable identity for a set of constructs (ignores absolute package paths).
String constructSetFingerprint(
  List<ConstructYaml> constructs, {
  String? sdkVersion,
}) {
  final parts = <String>[
    for (final yaml in constructs)
      [
        yaml.packageName,
        yaml.packageUri,
        for (final c in yaml.constructs)
          '${c.name}:${c.method}:${c.isServer}:${c.isBuild}:${c.optIn}',
      ].join(';'),
  ]..sort();

  final payload = '${parts.join('|')}|${sdkVersion ?? io.Platform.version}';
  // FNV-1a 64-bit — stable across isolates, no crypto dependency.
  // Use BigInt so the offset/prime are exact (avoid_js_rounded_ints).
  var hash = BigInt.parse('cbf29ce484222325', radix: 16);
  final prime = BigInt.parse('100000001b3', radix: 16);
  final mask = (BigInt.one << 64) - BigInt.one;
  for (final unit in utf8.encode(payload)) {
    hash ^= BigInt.from(unit);
    hash = (hash * prime) & mask;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}

/// Resolves a shared kernel cache directory for [projectRoot].
///
/// Prefer `REVALI_KERNEL_CACHE`, then `test_suite/.revali_kernel_cache` when
/// under the monorepo test suite, else `<project>/.dart_tool/revali_kernels`.
Directory resolveKernelCacheDir(FileSystem fs, Directory projectRoot) {
  final env = io.Platform.environment['REVALI_KERNEL_CACHE'];
  if (env != null && env.isNotEmpty) {
    return fs.directory(env);
  }

  var dir = projectRoot;
  while (true) {
    if (dir.basename == 'test_suite' &&
        dir.childDirectory('constructs').existsSync()) {
      return dir.childDirectory('.revali_kernel_cache');
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      break;
    }
    dir = parent;
  }

  return projectRoot
      .childDirectory('.dart_tool')
      .childDirectory('revali_kernels');
}

/// Returns true when each output exists and is at least as new as every file
/// under [inputDirs] (dart sources) and [extraFiles].
bool outputsAreFresh({
  required FileSystem fs,
  required List<File> outputs,
  required List<Directory> inputDirs,
  List<File> extraFiles = const [],
}) {
  DateTime? oldestOutput;
  for (final output in outputs) {
    if (!output.existsSync()) {
      return false;
    }
    final modified = output.lastModifiedSync();
    if (oldestOutput == null || modified.isBefore(oldestOutput)) {
      oldestOutput = modified;
    }
  }
  if (oldestOutput == null) {
    return false;
  }

  bool newerThanOutput(File file) {
    try {
      return file.lastModifiedSync().isAfter(oldestOutput!);
    } catch (_) {
      return false;
    }
  }

  for (final file in extraFiles) {
    if (file.existsSync() && newerThanOutput(file)) {
      return false;
    }
  }

  for (final dir in inputDirs) {
    if (!dir.existsSync()) continue;
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;
      if (newerThanOutput(entity)) {
        return false;
      }
    }
  }

  return true;
}
