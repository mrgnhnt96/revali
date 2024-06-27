import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zora_construct/models/construct_options.dart';

part 'construct_config.g.dart';

@JsonSerializable()
class ConstructConfig extends Equatable {
  const ConstructConfig({
    required this.name,
    required this.path,
    required this.method,
    this.options = const ConstructOptions.empty(),
    this.isRouter = false,
  });

  static ConstructConfig fromJson(Map json) => _$ConstructConfigFromJson(json);

  final String name;
  final String path;
  final String method;
  final ConstructOptions options;
  final bool isRouter;

  Map<String, dynamic> toJson() => _$ConstructConfigToJson(this);

  @override
  List<Object?> get props => [
        name,
        path,
        method,
        options,
        isRouter,
      ];
}