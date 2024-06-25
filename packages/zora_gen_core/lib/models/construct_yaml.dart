import 'package:json_annotation/json_annotation.dart';

import 'construct_config.dart';

part 'construct_yaml.g.dart';

@JsonSerializable()
class ConstructYaml {
  const ConstructYaml({
    required this.constructs,
    required this.packagePath,
    required this.packageUri,
  });

  static ConstructYaml fromJson(Map json) => _$ConstructYamlFromJson(json);

  Map<String, dynamic> toJson() => _$ConstructYamlToJson(this);

  final List<ConstructConfig> constructs;
  final String packagePath;
  final String packageUri;
}
