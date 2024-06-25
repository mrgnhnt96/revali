import 'dart:isolate';

import 'package:file/file.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:zora_gen_core/zora_gen_core.dart';

class ConstructsHandler {
  ConstructsHandler({
    required this.fs,
    required this.initialDirectory,
  });

  final FileSystem fs;
  final String initialDirectory;

  Directory? __root;
  Future<Directory> get root async {
    if (__root case final root?) {
      return root;
    }

    File? file;
    Directory? directory = fs.directory(initialDirectory);
    while (file == null && directory != null) {
      final pubspec = directory.childFile('pubspec.yaml');

      if (await pubspec.exists()) {
        file = pubspec;
        break;
      }

      directory = directory.parent;
    }

    if ((file == null || !await file.exists()) || directory == null) {
      // TODO(mrgnhnt): throw a custom exception
      throw Exception('pubspec.yaml not found');
    }

    return __root = directory;
  }

  List<ConstructYaml>? __constructs;
  Future<List<ConstructYaml>> constructs(Directory root) async {
    if (__constructs case final constructs?) {
      return constructs;
    }

    final pubspec = root.childFile('pubspec.yaml');

    final pubspecYaml = loadYaml(await pubspec.readAsString());

    final devDependencies = pubspecYaml['dev_dependencies'] as YamlMap?;

    final zoraConstructs = <ConstructYaml>[];

    for (final key in devDependencies?.keys ?? []) {
      final packageUri = 'package:$key/';
      final uri = Uri.parse(packageUri);

      final package = await Isolate.resolvePackageUri(uri);

      if (package == null) {
        continue;
      }

      final packageDir = fs.directory(package);
      final construct = packageDir.parent.childFile('construct.yaml');

      if (!construct.existsSync()) {
        continue;
      }

      final constructContent = await construct.readAsString();

      final constructYaml = loadYaml(constructContent) as YamlMap;

      final json = {...constructYaml.value};
      json['package_path'] = packageDir.parent.path;
      json['package_uri'] = packageUri;

      zoraConstructs.add(ConstructYaml.fromJson(json));
    }

    await checkConstructs(zoraConstructs);

    return __constructs = zoraConstructs;
  }

  Future<void> checkConstructs(Iterable<ConstructYaml> constructs) async {
    bool hasRouter = false;
    for (final construct in constructs) {
      for (final config in construct.constructs) {
        if (config.isRouter) {
          if (hasRouter) {
            throw Exception('Only one router is allowed');
          }

          hasRouter = true;
        }
        final path = p.join(construct.packagePath, 'lib', config.path);
        final file = fs.file(path);
        if (!await file.exists()) {
          throw Exception('Construct not found for ${config.name}');
        }

        print(config.name);
      }
    }

    if (!hasRouter) {
      // The router isn't found because the developer hasn't
      // added a zora router to the project
      throw Exception('Router not found');
    }
  }
}
