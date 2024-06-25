import 'package:json_annotation/json_annotation.dart';
import 'package:zora_gen_core/models/construct_options.dart';

part 'construct_config.g.dart';

@JsonSerializable()
class ConstructConfig {
  const ConstructConfig({
    required this.name,
    required this.path,
    required this.method,
    this.options = const ConstructOptions.empty(),
  });

  static ConstructConfig fromJson(Map json) => _$ConstructConfigFromJson(json);

  final String name;
  final String path;
  final String method;
  final ConstructOptions options;

  Map<String, dynamic> toJson() => _$ConstructConfigToJson(this);
}
