import 'dart:isolate';

import 'package:file/file.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart' as yaml;
import 'package:zora_gen_core/zora_gen_core.dart';

class EntrypointGenerator {
  const EntrypointGenerator({
    required this.initialDirectory,
    required this.fs,
  });

  final String initialDirectory;
  final FileSystem fs;

  Future<void> generate() async {
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
      throw Exception('pubspec.yaml not found');
    }

    final content = await file.readAsString();

    final pubspecYaml = yaml.loadYaml(content);

    final devDependencies = pubspecYaml['dev_dependencies'] as yaml.YamlMap?;

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

      final constructYaml = yaml.loadYaml(constructContent) as yaml.YamlMap;

      final json = {...constructYaml.value};
      json['package_path'] = packageDir.parent.path;
      json['package_uri'] = packageUri;

      zoraConstructs.add(ConstructYaml.fromJson(json));
    }

    bool hasRouter = false;

    // TODO(mrgnhnt96): generate the entrypoint file
    for (final construct in zoraConstructs) {
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

    final zoraDir = directory.childDirectory('.zora');

    await zoraDir.create();

    final entrypointFile = zoraDir.childFile('entrypoint.dart');

    if (await entrypointFile.exists()) {
      await entrypointFile.delete();
    }

    await entrypointFile.create();

    final entrypointContent = '''
void main() {
  print('Hello, World!');
}''';

    await entrypointFile.writeAsString(entrypointContent);
  }
}
