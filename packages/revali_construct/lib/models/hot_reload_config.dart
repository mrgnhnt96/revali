import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'hot_reload_config.g.dart';

@JsonSerializable()
class HotReloadConfig extends Equatable {
  const HotReloadConfig({List<String>? exclude})
    : exclude = exclude ?? const [];

  factory HotReloadConfig.fromJson(Map<String, dynamic> json) =>
      _$HotReloadConfigFromJson(json);

  /// Paths to exclude from hot reload. Can be absolute or relative to
  /// the location of revali.yaml. Directories exclude all files within.
  @JsonKey(defaultValue: [])
  final List<String> exclude;

  Map<String, dynamic> toJson() => _$HotReloadConfigToJson(this);

  @override
  List<Object?> get props => [exclude];
}
