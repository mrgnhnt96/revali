import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:revali_construct/revali_construct.dart';

part 'revali_construct_config.g.dart';

@JsonSerializable()
class RevaliConstructConfig extends Equatable {
  const RevaliConstructConfig({
    required this.name,
    this.enabled = true,
    this.package,
    this.options = const {},
  });

  factory RevaliConstructConfig.fromJson(Map<String, dynamic> json) =>
      _$revaliConstructConfigFromJson(json);

  final String name;
  final String? package;
  final bool enabled;
  final Map<String, dynamic> options;

  ConstructOptions get constructOptions => ConstructOptions(options);

  Map<String, dynamic> toJson() => _$revaliConstructConfigToJson(this);

  @override
  List<Object?> get props => [
        name,
        package,
        enabled,
        options,
      ];
}
