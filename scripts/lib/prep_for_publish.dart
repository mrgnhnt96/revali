// ignore_for_file: avoid_print, avoid_dynamic_calls

import 'dart:io';

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
}

void writeLicense(Package package) {
  final licenseFile = File(p.join(package.root, 'LICENSE'));

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

  final pubspecFile = File(p.join(package.root, 'pubspec.yaml'));

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

    final content = loadYaml(File(entity.path).readAsStringSync()) as YamlMap;

    if (ignorePackages.contains(content['name'])) continue;

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
}
