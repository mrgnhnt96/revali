import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zora_construct/zora_construct.dart';

part 'zora_construct_config.g.dart';

@JsonSerializable()
class ZoraConstructConfig extends Equatable {
  const ZoraConstructConfig({
    required this.name,
    this.enabled = true,
    this.package,
    this.options = const {},
  });

  factory ZoraConstructConfig.fromJson(Map<String, dynamic> json) =>
      _$ZoraConstructConfigFromJson(json);

  final String name;
  final String? package;
  final bool enabled;
  final Map<String, dynamic> options;

  ConstructOptions get constructOptions => ConstructOptions(options);

  Map<String, dynamic> toJson() => _$ZoraConstructConfigToJson(this);

  @override
  List<Object?> get props => [
        name,
        package,
        enabled,
        options,
      ];
}
