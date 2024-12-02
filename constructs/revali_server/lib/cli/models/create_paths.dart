import 'package:json_annotation/json_annotation.dart';

part 'create_paths.g.dart';

@JsonSerializable()
class CreatePaths {
  const CreatePaths({
    this.controller = 'controllers',
    this.app = 'apps',
  });

  factory CreatePaths.fromJson(Map<String, dynamic> json) =>
      _$CreatePathsFromJson(json);

  final String controller;
  final String app;

  Map<String, dynamic> toJson() => _$CreatePathsToJson(this);
}
