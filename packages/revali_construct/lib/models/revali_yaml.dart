import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:revali_construct/revali_construct.dart';

part 'revali_yaml.g.dart';

@JsonSerializable()
class revaliYaml extends Equatable {
  const revaliYaml({
    required this.constructs,
  });
  const revaliYaml.none() : constructs = const [];

  factory revaliYaml.fromJson(Map<String, dynamic> json) =>
      _$revaliYamlFromJson(json);

  @JsonKey(defaultValue: const [])
  final List<revaliConstructConfig> constructs;

  Map<String, dynamic> toJson() => _$revaliYamlToJson(this);

  revaliConstructConfig configFor(ConstructMaker maker) {
    final defaultConfig = revaliConstructConfig(name: maker.name);

    final constructsByName = <String, List<revaliConstructConfig>>{};
    for (final construct in constructs) {
      (constructsByName[construct.name] ??= []).add(construct);
    }

    final configs = constructsByName[maker.name];

    if (configs == null) {
      return defaultConfig;
    }

    if (configs.length == 1) {
      return configs.first;
    }

    final configsByPackage = {
      for (final config in configs) config.package: config,
    };

    if (configsByPackage[maker.package] case final config?) {
      return config;
    }

    throw Exception(
      'Multiple configs with the same name. '
      'Try adding the `package` key to identify'
      'the different constructs',
    );
  }

  @override
  List<Object?> get props => [
        constructs,
      ];
}
