import 'package:json_annotation/json_annotation.dart';
import 'package:revali_server/cli/models/create_paths.dart';

part 'cli_config.g.dart';

@JsonSerializable()
class CliConfig {
  CliConfig({
    CreatePaths? createPaths,
  }) : createPaths = createPaths ?? CreatePaths();

  factory CliConfig.fromJson(Map<dynamic, dynamic> json) =>
      _$CliConfigFromJson(json);

  final CreatePaths createPaths;

  Map<String, dynamic> toJson() => _$CliConfigToJson(this);
}
