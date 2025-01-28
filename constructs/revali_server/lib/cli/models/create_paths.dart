import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as p;

part 'create_paths.g.dart';

@JsonSerializable()
class CreatePaths {
  CreatePaths({
    String? controller,
    String? app,
    String? pipe,
  })  : controller = _assert(controller, p.join('routes', 'controllers')),
        app = _assert(app, p.join('routes', 'apps')),
        pipe = _assert(pipe, p.join('lib', 'components', 'pipes'));

  factory CreatePaths.fromJson(Map<String, dynamic> json) =>
      _$CreatePathsFromJson(json);

  static String _assert(String? value, String fallback) {
    return switch (value) {
      final String v when v.trim().isNotEmpty => v.trim(),
      _ => fallback,
    };
  }

  final String controller;
  final String app;
  @JsonKey(fromJson: _multiString)
  final String pipe;

  Map<String, dynamic> toJson() => _$CreatePathsToJson(this);

  // dynamic is used to by pass the generated code check
  static dynamic _multiString(dynamic value) {
    return switch (value) {
      List<String>() => p.joinAll(value),
      List() => p.joinAll(value.map((e) => '$e')),
      String() => value,
      _ => null,
    };
  }
}
