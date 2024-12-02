import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:revali_server/cli/models/cli_config.dart';
import 'package:yaml/yaml.dart';

mixin CreateCommandMixin {
  FileSystem get fs;
  Logger get logger;

  String? get root {
    var directory = fs.currentDirectory.absolute;

    while (directory.path != p.separator) {
      final file = directory.childFile('pubspec.yaml');

      if (file.existsSync()) {
        return directory.path;
      }

      directory = directory.parent;
    }

    return null;
  }

  CliConfig get config {
    final root = this.root;

    logger.detail('Looking for revali.yaml');

    if (root == null) {
      return const CliConfig();
    }

    final file = fs.file(p.join(root, 'revali.yaml'));

    if (!file.existsSync()) {
      logger.detail('Failed to find revali.yaml');
      return const CliConfig();
    }

    final content = file.readAsStringSync();

    final yaml = loadYaml(content) as Map;

    if (yaml['revali_server'] case final Map<dynamic, dynamic> config) {
      logger.detail('Found revali.yaml');
      return CliConfig.fromJson(config);
    }

    logger.detail('No revali_server config found in revali.yaml');

    return const CliConfig();
  }
}
