// ignore_for_file: avoid_print

import 'dart:io';

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:intl/intl.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

final currentFile = File(Platform.script.toFilePath());
final root = currentFile.parent.parent.parent.path; // scripts/lib/file.dart

final date = DateFormat('MM.dd.yy').format(DateTime.now());

final logger = Logger();

void main() async {
  final packagesProgress = logger.progress('Finding packages');
  final packages = findPackages();
  packagesProgress.complete('Found ${packages.length} packages');

  final changelogProgress = logger.progress('Getting CHANGELOG');
  final latestChangelog = getChangelog();
  changelogProgress.complete('Got CHANGELOG');

  final changesProgress = logger.progress('Checking for changes');
  final changedPackages = checkForChanges(packages, latestChangelog);
  changesProgress
      .complete('Found ${changedPackages.length} Packages to update');

  for (final (package, _) in changedPackages) {
    logger.info('  - ${package.name}');
  }
  logger.write('\n');

  for (final (package, changelog) in changedPackages) {
    logger.info('Updating ${package.name}');
    // make changes atomically
    final changesToPerform = <void Function()>[
      updatePubspec(
        changedPackages,
        package,
        changelog,
      ),
      updateChangeLog(package, changelog),
    ];

    for (final change in changesToPerform) {
      change();
    }

    logger.info('---');
    break;
  }
}

void Function() updatePubspec(
  Iterable<(Package, ChangeLogEntry)> packages,
  Package package,
  ChangeLogEntry changelog,
) {
  logger.info('  - `pubspec.yaml` dependencies & version');
  final newVersions = {
    for (final (package, changelog) in packages)
      package.name: changelog.version,
  };

  final pubspecFile = File(p.join(package.root, 'pubspec.yaml'));

  final content = pubspecFile.readAsStringSync().replaceFirst(
        RegExp('version: .+'),
        'version: ${changelog.version}',
      );

  final pubspec = Pubspec.parse(content);

  final dependencies = pubspec.dependencies;

  final updatedDependencies = <String, Dependency>{};

  for (final MapEntry(key: name) in dependencies.entries) {
    final newVersion = newVersions[name];

    if (newVersion == null) continue;

    updatedDependencies[name] = HostedDependency(
      version: VersionConstraint.parse('^$newVersion'),
    );
  }

  pubspec.dependencies.addAll(updatedDependencies);

  return () => pubspecFile.writeAsStringSync(pubspec.toYaml());
}

extension _PubspecX on Pubspec {
  String toYaml() {
    final funding =
        this.funding ?? [Uri.parse('https://github.com/sponsors/mrgnhnt96')];
    final topics = this.topics ?? ['revali', 'api', 'backend', 'server'];

    final issueTracker = this.issueTracker ??
        Uri.parse('https://github.com/mrgnhnt96/revali/issues');
    final documentation = this.documentation ?? Uri.parse('https://revali.dev');

    if (description == null) {
      throw ArgumentError('Description is required in pubspec: $name');
    }

    if (repository == null) {
      throw ArgumentError('Repository is required in pubspec: $name');
    }

    final environment = this.environment ??
        {
          'sdk': VersionConstraint.parse('>=3.2.6 <4.0.0'),
        };

    final buffer = StringBuffer()
      ..writeln('name: $name')
      ..writeln('version: $version')
      ..writeln('description: $description')
      ..writeln('repository: $repository')
      ..writeln('issue_tracker: $issueTracker')
      ..writeln('documentation: $documentation')
      ..writeln('funding:')
      ..writeln('    - ${funding.join('\n    - ')}')
      ..writeln('topics:')
      ..write('    - ${topics.join('\n    - ')}')
      ..writeln('\n')
      ..writeln('environment:');
    for (final entry in environment.entries) {
      buffer.writeln("    ${entry.key}: '${entry.value}'");
    }

    if (dependencies.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('dependencies:');
      writeDependencies(buffer, dependencies);
    }

    if (devDependencies.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('dev_dependencies:');
      writeDependencies(buffer, dependencies);
    }

    if (dependencyOverrides.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('dependency_overrides:');
      writeDependencies(buffer, dependencies);
    }

    return buffer.toString();
  }
}

void writeDependencies(
  StringBuffer buffer,
  Map<String, Dependency> dependencies,
) {
  final packages = dependencies.keys.toList()..sort();
  for (final package in packages) {
    final dep = dependencies[package]!;

    final version = switch (dep) {
      HostedDependency() => dep.version.toString(),
      SdkDependency() => '\n      sdk: ${dep.sdk}',
      GitDependency() => '\n      git: ${dep.url}',
      PathDependency() => '\n      path: ${dep.path}',
      _ => throw StateError('There is a bug in pubspec_parse.'),
    };

    buffer.writeln('    $package: $version');
  }
}

void Function() updateChangeLog(Package package, ChangeLogEntry changelog) {
  logger.info('  - ChangeLog');

  const intro = '# CHANGELOG';

  final changelogFile = File(p.join(package.root, 'CHANGELOG.md'));

  if (!changelogFile.existsSync()) {
    changelogFile
      ..createSync(recursive: true)
      ..writeAsStringSync('# CHANGELOG\n\n');
  }

  final content =
      changelogFile.readAsStringSync().replaceFirst(intro, '').trim();

  final newContent = '''
$intro

## ${changelog.version} | $date

${changelog.changes}

$content'''
      .trim();

  return () => changelogFile.writeAsStringSync('$newContent\n');
}

Iterable<(Package, ChangeLogEntry)> checkForChanges(
  Iterable<Package> packages,
  ChangeLog latestChangelog,
) sync* {
  for (final package in packages) {
    final changelog = latestChangelog[package.name];

    if (changelog == null) {
      print('ERROR: No ChangeLog entry found for ${package.name}');
      exit(1);
    }

    if (changelog.version != package.version) {
      yield (package, changelog);
    }
  }
}

ChangeLog getChangelog() {
  final changelogFile = File(p.join(root, 'LATEST_CHANGELOG.md'));

  final content = changelogFile.readAsStringSync();

  final entries = <ChangeLogEntry>[];

  final lines = content.split('\n');

  var currentEntry = ChangeLogEntry();

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];

    if (line.trimLeft().startsWith('<!--')) continue;

    if (line.trim().isEmpty && !currentEntry.gettingChanges) {
      continue;
    }

    if (line.startsWith('# ')) {
      if (currentEntry.isValid) {
        entries.add(currentEntry);
      }

      currentEntry = ChangeLogEntry();

      final name = line.substring(2).trim();

      currentEntry.package = name;
      continue;
    }

    if (line.startsWith('## ')) {
      final version = line.substring(3).trim();

      currentEntry.version = version;
      continue;
    }

    currentEntry.changesBuffer.writeln(line);
  }

  if (currentEntry.isValid) {
    entries.add(currentEntry);
  }

  return ChangeLog(entries);
}

class ChangeLog {
  ChangeLog(this.entries);

  final Iterable<ChangeLogEntry> entries;

  late final _map = {
    for (final entry in entries) entry.package: entry,
  };

  ChangeLogEntry? operator [](String package) {
    return _map[package];
  }
}

class ChangeLogEntry {
  ChangeLogEntry();

  String? package;
  String? version;
  String get changes => changesBuffer.toString().trim();

  final changesBuffer = StringBuffer();

  bool get isValid {
    return package != null && version != null && changes.isNotEmpty;
  }

  bool get gettingChanges {
    return package != null && version != null;
  }
}

Iterable<Package> findPackages() sync* {
  const ignorePackages = {'scripts'};
  const ignoreDirectories = {'examples'};

  final pubspecGlob = Glob('**/pubspec.yaml');

  for (final entity in pubspecGlob.listSync(
    root: root,
    followLinks: false,
  )) {
    if (entity is! File) {
      continue;
    }

    final content = Pubspec.parse(File(entity.path).readAsStringSync());

    if (ignorePackages.contains(content.name)) continue;

    if (p.split(entity.parent.path).any(ignoreDirectories.contains)) continue;

    yield Package(
      name: content.name,
      version: content.version?.canonicalizedVersion ?? '-1',
      root: entity.parent.path,
    );
  }
}

class Package {
  const Package({
    required this.name,
    required this.version,
    required this.root,
  });

  final String name;
  final String version;
  final String root;
}
