import 'package:json_annotation/json_annotation.dart';

part 'create_paths.g.dart';

@JsonSerializable()
class CreatePaths {
  const CreatePaths({
    this.controller = 'controllers',
  });

  factory CreatePaths.fromJson(Map<String, dynamic> json) =>
      _$CreatePathsFromJson(json);

  final String controller;

  Map<String, dynamic> toJson() => _$CreatePathsToJson(this);
}
