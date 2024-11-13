import 'dart:convert';
import 'dart:isolate';

import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:revali/utils/extensions/directory_extensions.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:yaml/yaml.dart';

class ConstructsHandler {
  ConstructsHandler({
    required this.fs,
    required this.logger,
  });

  final FileSystem fs;
  final Logger logger;

  List<ConstructYaml>? __constructs;

  static const String constructYamlFileName = 'construct.yaml';

  /// Gets the [ConstructYaml]s based on the dependencies
  /// of the project requesting revali
  Future<List<ConstructYaml>> constructDepsFrom(Directory root) async {
    if (__constructs case final constructs?) {
      return constructs;
    }

    final pubspec = root.childFile('pubspec.yaml');

    final pubspecYaml = loadYaml(await pubspec.readAsString()) as YamlMap;

    final devDependencies = pubspecYaml['dev_dependencies'] as YamlMap?;

    final revaliConstructs = <ConstructYaml>[];

    final packageJsonFile = await root.getDartToolFile('package_config.json');
    if (!await packageJsonFile.exists()) {
      throw Exception('Failed to find package.json, run `dart pub get`');
    }

    final packageJson = jsonDecode(await packageJsonFile.readAsString()) as Map;
    final packages = <String, String>{};

    if (packageJson['packages']
        case final List<Map<String, dynamic>> rawPackages) {
      for (final package in rawPackages) {
        if (package
            case {
              'packageUri': final String packageUri,
              'name': final String name
            }) {
          packages[name] = packageUri;
        }
      }
    }

    for (final key in devDependencies?.keys ?? []) {
      final packageUri = 'package:$key/';
      final uri = Uri.parse(packageUri);

      final package = await Isolate.resolvePackageUri(uri);

      if (package == null) {
        continue;
      }

      final packageDir = fs.directory(package);
      final construct = packageDir.parent.childFile(constructYamlFileName);

      if (!construct.existsSync()) {
        continue;
      }

      final packageRootUri = packages[key] ?? '__unknown_version__';

      final constructContent = await construct.readAsString();
      final constructYaml = loadYaml(constructContent) as YamlMap;

      final json = {...constructYaml.value};
      json['package_path'] = packageDir.parent.path;
      json['package_uri'] = packageUri;
      json['package_name'] = key;
      json['package_root_uri'] = packageRootUri;

      revaliConstructs.add(ConstructYaml.fromJson(json));
    }

    await checkConstructs(revaliConstructs);

    return __constructs = revaliConstructs;
  }

  /// Asserts the config for all constructs
  ///
  /// - Contains only 1 config where [ConstructConfig.isServer] is true
  Future<void> checkConstructs(Iterable<ConstructYaml> constructs) async {
    for (final construct in constructs) {
      for (final config in construct.constructs) {
        final path = p.join(construct.packagePath, 'lib', config.path);
        final file = fs.file(path);
        if (!await file.exists()) {
          logger.err(
            'Failed to find the entrypoint for construct ${config.name}',
          );
          throw Exception(
            'Failed to find the entrypoint for construct ${config.name}',
          );
        }

        logger.detail('Construct: ${config.name}');
      }
    }
  }
}
