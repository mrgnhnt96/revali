import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zora_gen_core/models/zora_construct_config.dart';

part 'zora_yaml.g.dart';

@JsonSerializable()
class ZoraYaml extends Equatable {
  const ZoraYaml({
    required this.constructs,
  });

  factory ZoraYaml.fromJson(Map<String, dynamic> json) =>
      _$ZoraYamlFromJson(json);

  final List<ZoraConstructConfig> constructs;

  Map<String, dynamic> toJson() => _$ZoraYamlToJson(this);

  @override
  List<Object?> get props => [
        constructs,
      ];
}
