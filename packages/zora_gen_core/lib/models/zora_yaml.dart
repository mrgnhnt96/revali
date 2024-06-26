import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zora_gen_core/zora_gen_core.dart';

part 'zora_yaml.g.dart';

@JsonSerializable()
class ZoraYaml extends Equatable {
  const ZoraYaml({
    required this.constructs,
  });
  const ZoraYaml.none() : constructs = const [];

  factory ZoraYaml.fromJson(Map<String, dynamic> json) =>
      _$ZoraYamlFromJson(json);

  @JsonKey(defaultValue: const [])
  final List<ZoraConstructConfig> constructs;

  Map<String, dynamic> toJson() => _$ZoraYamlToJson(this);

  ZoraConstructConfig configFor(ConstructMaker maker) {
    final defaultConfig = ZoraConstructConfig(name: maker.name);

    final constructsByName = <String, List<ZoraConstructConfig>>{};
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
