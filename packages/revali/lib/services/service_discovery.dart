import 'package:file/file.dart';
import 'package:path/path.dart' as p;

/// One Revali service found in a repository.
class RevaliService {
  const RevaliService({
    required this.name,
    required this.directory,
    required this.relativePath,
  });

  /// The package name from `pubspec.yaml`.
  final String name;

  final Directory directory;

  /// Where the service sits relative to the repository root — what a
  /// `docker-compose.yaml` at the root needs as a build context.
  final String relativePath;

  /// Whether `revali build` has produced a Dockerfile for this service.
  bool get hasDockerfile => directory
      .childDirectory('.revali')
      .childDirectory('build')
      .childFile('Dockerfile')
      .existsSync();

  @override
  String toString() => '$name ($relativePath)';
}

/// Finds every Revali service in a repository.
///
/// A repo with five services is five packages today, each run and built on its
/// own. Everything that wants to treat them as one system — running them
/// together, generating a compose file — needs to know what "them" is first,
/// which is what this answers.
class ServiceDiscovery {
  const ServiceDiscovery();

  /// Directories that never contain a service and are expensive to walk.
  static const _skipped = {
    '.revali',
    '.dart_tool',
    '.git',
    'build',
    'node_modules',
  };

  /// Services under [root], ordered by path so output is stable between runs.
  List<RevaliService> find(Directory root) {
    final services = <RevaliService>[];

    _walk(root, root, services);
    services.sort((a, b) => a.relativePath.compareTo(b.relativePath));

    return services;
  }

  void _walk(Directory dir, Directory root, List<RevaliService> found) {
    if (_isService(dir)) {
      if (_serviceAt(dir, root) case final service?) {
        found.add(service);
      }

      // A service does not contain another service, and walking into it only
      // risks matching generated output.
      return;
    }

    final List<FileSystemEntity> children;
    try {
      children = dir.listSync();
    } catch (_) {
      // An unreadable directory is not worth failing discovery over.
      return;
    }

    for (final child in children.whereType<Directory>()) {
      final name = p.basename(child.path);

      if (_skipped.contains(name) || name.startsWith('.')) {
        continue;
      }

      _walk(child, root, found);
    }
  }

  /// A Revali service is a package with a `routes/` directory that depends on
  /// the framework.
  ///
  /// The dependency check matters: `routes/` on its own is a common enough
  /// directory name that a docs folder or a frontend router would otherwise be
  /// reported as a service.
  bool _isService(Directory dir) {
    final pubspec = dir.childFile('pubspec.yaml');

    if (!pubspec.existsSync() || !dir.childDirectory('routes').existsSync()) {
      return false;
    }

    final content = pubspec.readAsStringSync();

    return content.contains('revali_router') || content.contains('revali:');
  }

  RevaliService? _serviceAt(Directory dir, Directory root) {
    final name = _packageName(dir.childFile('pubspec.yaml'));

    if (name == null) {
      return null;
    }

    final relative = p.relative(dir.path, from: root.path);

    return RevaliService(
      name: name,
      directory: dir,
      relativePath: relative == '.' ? '.' : relative,
    );
  }

  /// Reads `name:` without a YAML parser — it is the first top-level key in
  /// every pubspec, and pulling in a parser for one line is not worth it.
  String? _packageName(File pubspec) {
    for (final line in pubspec.readAsLinesSync()) {
      if (!line.startsWith('name:')) {
        continue;
      }

      final value = line.substring('name:'.length).trim();

      return value.isEmpty ? null : value;
    }

    return null;
  }
}
