import 'dart:convert';
import 'dart:isolate';

import 'package:file/file.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:zora_gen/extensions/directory_extensions.dart';
import 'package:zora_gen_core/zora_gen_core.dart';

class ConstructsHandler {
  ConstructsHandler({required this.fs});

  final FileSystem fs;

  List<ConstructYaml>? __constructs;

  static const String constructYamlFileName = 'construct.yaml';

  /// Gets the [ConstructYaml]s based on the dependencies of the project requesting
  /// zora_gen
  Future<List<ConstructYaml>> constructDepsFrom(Directory root) async {
    if (__constructs case final constructs?) {
      return constructs;
    }

    final pubspec = root.childFile('pubspec.yaml');

    final pubspecYaml = loadYaml(await pubspec.readAsString());

    final devDependencies = pubspecYaml['dev_dependencies'] as YamlMap?;

    final zoraConstructs = <ConstructYaml>[];

    final packageJsonFile = await root.getDartToolFile('package_config.json');
    if (!await packageJsonFile.exists()) {
      throw Exception('Failed to find package.json, run `dart pub get`');
    }

    final packageJson = jsonDecode(await packageJsonFile.readAsString()) as Map;
    final packages = <String, String>{};
    for (final package in packageJson['packages']) {
      final packageUri = package['packageUri'] as String;
      final name = package['name'] as String;

      packages[name] = packageUri;
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

      zoraConstructs.add(ConstructYaml.fromJson(json));
    }

    await checkConstructs(zoraConstructs);

    return __constructs = zoraConstructs;
  }

  /// Asserts the config for all constructs
  ///
  /// - Contains only 1 config where [ConstructConfig.isRouter] is true
  Future<void> checkConstructs(Iterable<ConstructYaml> constructs) async {
    bool hasRouter = false;
    for (final construct in constructs) {
      for (final config in construct.constructs) {
        if (config.isRouter) {
          if (hasRouter) {
            // TODO(mrgnhnt): throw a custom exception
            throw Exception('Only one router is allowed');
          }

          hasRouter = true;
        }
        final path = p.join(construct.packagePath, 'lib', config.path);
        final file = fs.file(path);
        if (!await file.exists()) {
          // TODO(mrgnhnt): throw a custom exception
          throw Exception('Construct not found for ${config.name}');
        }

        print(config.name);
      }
    }

    if (!hasRouter) {
      // The router isn't found because the developer hasn't
      // added a zora router to the project
      // TODO(mrgnhnt): throw a custom exception
      throw Exception('Router not found');
    }
  }
}
