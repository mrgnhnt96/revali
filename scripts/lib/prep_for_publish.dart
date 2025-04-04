// ignore_for_file: avoid_print, avoid_dynamic_calls

import 'dart:io';

import 'package:change_case/change_case.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:intl/intl.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

final currentFile = File(Platform.script.toFilePath());
final root = currentFile.parent.parent.parent.path; // scripts/lib/file.dart

final date = DateFormat('MM.dd.yy').format(DateTime.now());

final logger = Logger();

void main() async {
  // check if git is clean
  if (!File(p.join(root, 'FAILED_PUSH.md')).existsSync()) {
    final gitStatus = await Process.run(
      'git',
      ['status', '--porcelain'],
      workingDirectory: root,
    );

    if (gitStatus.exitCode != 0) {
      logger.err('Git is not clean! Push your changes first.');
      exit(1);
    }
  }

  final packagesProgress = logger.progress('Finding packages');
  final packages = findPackages();
  packagesProgress.complete('Found ${packages.length} packages');

  for (final package in packages) {
    writeLicense(package);
  }
  logger.info('Updated LICENSE files');

  final changelogProgress = logger.progress('Getting CHANGELOG');
  final latestChangelog = getChangelog();
  changelogProgress.complete('Got CHANGELOG');

  final changesProgress = logger.progress('Checking for changes');
  final changedPackages = checkForChanges(packages, latestChangelog).toList();
  changesProgress
      .complete('Found ${changedPackages.length} Packages to update');

  for (final (package, _) in changedPackages) {
    logger.info('  - ${package.name}');
  }
  if (changedPackages.isNotEmpty) {
    logger.write('\n');
  }

  for (final (package, changelog) in changedPackages) {
    logger.info('Updating ${package.name}');
    // make changes atomically
    final changesToPerform = <void Function()>[
      updatePubspec(
        {
          for (final package in packages)
            (package, latestChangelog[package.name]!),
        },
        package,
        changelog,
      ),
      updateChangeLog(package, changelog),
    ];

    for (final change in changesToPerform) {
      change();
    }

    logger.info('---');
  }

  final failedProgress = logger.progress('Checking for failed publishes');
  final failedPackages = findFailedPublishes(packages);
  failedProgress.complete('Found ${failedPackages.length} failed publishes');

  final packagesToPublish = {
    for (final pkg in failedPackages) pkg.name: pkg,
    for (final (pkg, _) in changedPackages) pkg.name: pkg,
  }.values.toList();

  final successPublishes = <Package>[];

  if (packagesToPublish.isEmpty) {
    logger.info('No packages to publish');
  } else {
    logger.info('Publishing ${packagesToPublish.length} packages');

    for (final package in packagesToPublish) {
      logger.info('  - ${package.name}');
      final success = await publish(package);

      if (success) {
        successPublishes.add(package);
      }
    }

    logger
      ..info('Published ${successPublishes.length} packages')
      ..info('Pushing all changes');

    // add all changes to git
    await Process.run(
      'git',
      ['add', '.'],
      workingDirectory: root,
    );
  }
  await commitChanges(successPublishes);

  await pushChanges(successPublishes);

  final failedRelease = logger.progress('Checking for failed releases');
  final failedReleases = findFailedReleases(packages);
  failedRelease.complete('Found ${failedReleases.length} failed releases');

  final packagesToRelease = failedReleases.followedBy([
    for (final (package, _) in changedPackages) package,
  ]);

  if (packagesToRelease.isEmpty) {
    logger.info('No packages to release');
    return;
  }

  for (final package in packagesToRelease) {
    final changeLogEntry = latestChangelog[package.name]!;

    await createRelease(package, changeLogEntry);
  }

  try {
    // push all tags
    await Process.run(
      'git',
      [
        'push',
        'origin',
        'HEAD',
        '--tags',
        '--no-verify',
      ],
      workingDirectory: root,
    );
  } catch (e) {
    print('Failed to push: $e');
  }
}

Future<void> createRelease(Package package, ChangeLogEntry changelog) async {
  final failedReleaseFile = package.failedRelease;

  if (failedReleaseFile.existsSync()) {
    failedReleaseFile.deleteSync();
  }
//  create release
  final process = await Process.run(
    'gh',
    [
      'release',
      'create',
      '${package.name.toNoCase().toParamCase()}-${changelog.version}',
      '-t',
      '${package.name.toNoCase().toTitleCase()} v${changelog.version}',
      '-n',
      changelog.changes,
    ],
    workingDirectory: package.root,
  );

  if (process.exitCode == 0) {
    logger.info('Created release for ${package.name}');
  } else {
    if (process.stderr.toString().contains('already exists')) {
      logger.info(
        'Release already exists for ${package.name} (${changelog.version})',
      );
    } else {
      createFailedRelease([package], process);
      logger.err('Failed to create release for ${package.name}');
    }
  }
}

Future<void> pushChanges(List<Package> packages) async {
  final failedPushFile = File(p.join(root, 'FAILED_PUSH.md'));

  if (failedPushFile.existsSync()) {
    failedPushFile.deleteSync();
  }

  // push all changes
  final push = await Process.run(
    'git',
    ['push', 'origin', 'HEAD', '--no-verify'],
    workingDirectory: root,
  );

  if (push.exitCode != 0) {
    // create failed push file
    failedPushFile
      ..createSync()
      ..writeAsStringSync('''
# Failed to push changes

## Error
${push.stderr}

## Output
${push.stdout}
''');

    createFailedRelease(packages, push);
    return;
  }
}

Future<void> commitChanges(List<Package> packages) async {
  final failedCommitFile = File(p.join(root, 'FAILED_COMMIT.md'));

  if (failedCommitFile.existsSync()) {
    failedCommitFile.deleteSync();
  }

  // commit all changes
  final commit = await Process.run(
    'git',
    [
      'commit',
      '-m',
      '"Publish Packages | $date"',
      '--no-verify',
    ],
    workingDirectory: root,
  );

  final output = commit.stdout.toString();

  if (output.contains('up to date')) {
    return;
  }

  if (commit.exitCode != 0) {
    // create failed commit file
    failedCommitFile
      ..createSync()
      ..writeAsStringSync('''
# Failed to commit changes

## Error
${commit.stderr}

## Output
${commit.stdout}
''');
    createFailedRelease(packages, commit);
    return;
  }
}

Future<bool> publish(Package package) async {
  final failedPublishFile = package.failedPublish;

  if (failedPublishFile.existsSync()) {
    failedPublishFile.deleteSync();
  }

  final process = await Process.run(
    'dart',
    ['pub', 'publish', '--force'],
    workingDirectory: package.root,
  );

  if (process.exitCode == 0) {
    logger.info('    Published');
    return true;
  }

  // make failed publish file to retry
  package.failedPublish
    ..createSync()
    ..writeAsStringSync('''
# Failed to publish ${package.name}

## Error
${process.stderr}

## Output
${process.stdout}
''');

  logger.err('Failed to publish ${package.name}');

  return false;
}

Iterable<Package> findFailedPublishes(Iterable<Package> packages) sync* {
  for (final package in packages) {
    final failedPublishFile = package.failedPublish;

    if (failedPublishFile.existsSync()) {
      yield package;
    }
  }
}

void createFailedRelease(Iterable<Package> packages, ProcessResult result) {
  for (final package in packages) {
    package.failedRelease
      ..createSync()
      ..writeAsStringSync('''
# Failed to create release for ${package.name}

Version: ${package.version}

## Error
${result.stderr}

## Output
${result.stdout}
''');
  }
}

Iterable<Package> findFailedReleases(Iterable<Package> packages) sync* {
  for (final package in packages) {
    final failedPublishFile = package.failedRelease;

    if (failedPublishFile.existsSync()) {
      yield package;
    }
  }
}

void writeLicense(Package package) {
  final licenseFile = package.license;

  if (!licenseFile.existsSync()) {
    licenseFile.writeAsStringSync('''
MIT License

Copyright (c) ${DateTime.now().year} MRGNHNT, LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
''');
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

  final pubspecFile = package.pubspec;

  final content = pubspecFile.readAsStringSync().replaceFirst(
        RegExp('version: .+'),
        'version: ${changelog.version}',
      );

  final yaml = YamlEditor(content);

  yaml['version'] = changelog.version;

  for (final key in [
    'dependencies',
    'dev_dependencies',
    'dependency_overrides',
  ]) {
    if (yaml[key] case final YamlMap deps) {
      for (final MapEntry(key: name) in deps.entries) {
        final newVersion = newVersions[name];

        if (newVersion == null) continue;

        yaml.update([key, name], '^$newVersion');
      }
    }
  }

  return () => pubspecFile.writeAsStringSync(yaml.toString());
}

extension _YamlEditorX on YamlEditor {
  void operator []=(dynamic key, dynamic newValue) {
    return switch (key) {
      String() => update([key], newValue),
      List<String>() => update(key, newValue),
      _ => throw StateError('Expected a string or list of strings.'),
    };
  }

  YamlNode? operator [](dynamic key) {
    try {
      return switch (key) {
        String() => parseAt([key]),
        List<String>() => parseAt(key),
        _ => throw StateError('Expected a string or list of strings.'),
      };
    } catch (_) {
      return null;
    }
  }
}

void Function() updateChangeLog(Package package, ChangeLogEntry changelog) {
  logger.info('  - ChangeLog');

  const intro = '# CHANGELOG';

  final changelogFile = package.changelog;

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
  const ignoreDirectories = {'examples', '.revali'};

  final pubspecGlob = Glob('**/pubspec.yaml');

  for (final entity in pubspecGlob.listSync(
    root: root,
    followLinks: false,
  )) {
    if (entity is! File) {
      continue;
    }

    final content = loadYaml(File(entity.path).readAsStringSync()) as YamlMap;

    if (ignorePackages.contains(content['name'])) continue;

    if (content['publish_to'] case 'none') continue;

    if (p.split(entity.parent.path).any(ignoreDirectories.contains)) continue;

    yield Package(
      name: content['name'] as String,
      version: content['version'] as String? ?? '-1',
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

  File get pubspec => File(p.join(root, 'pubspec.yaml'));

  File get failedPublish => File(p.join(root, 'FAILED_PUBLISH.md'));
  File get failedRelease => File(p.join(root, 'FAILED_RELEASE.md'));

  File get license => File(p.join(root, 'LICENSE'));

  File get changelog => File(p.join(root, 'CHANGELOG.md'));
}
