import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:revali_construct/revali_construct.dart';

part 'revali_yaml.g.dart';

@JsonSerializable()
class RevaliYaml extends Equatable {
  const RevaliYaml({
    required this.constructs,
  });
  const RevaliYaml.none() : constructs = const [];

  factory RevaliYaml.fromJson(Map<String, dynamic> json) =>
      _$RevaliYamlFromJson(json);

  @JsonKey(defaultValue: [])
  final List<RevaliConstructConfig> constructs;

  Map<String, dynamic> toJson() => _$RevaliYamlToJson(this);

  RevaliConstructConfig configFor(ConstructMaker maker) {
    final defaultConfig = RevaliConstructConfig(name: maker.name);

    final constructsByName = <String, List<RevaliConstructConfig>>{};
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
      'Try adding the `package` key to identify '
      'the different constructs',
    );
  }

  @override
  List<Object?> get props => [
        constructs,
      ];
}
