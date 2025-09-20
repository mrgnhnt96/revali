import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:revali_construct/models/hot_reload_data/hot_reload_data.dart';

part 'hot_reload_files_changed.g.dart';

@JsonSerializable()
class HotReloadFilesChanged extends Equatable implements HotReloadData {
  const HotReloadFilesChanged({required this.files});

  factory HotReloadFilesChanged.fromJson(Map<dynamic, dynamic> json) =>
      _$HotReloadFilesChangedFromJson(json);

  final List<String> files;
  @override
  @JsonKey(includeToJson: true)
  HotReloadType get type => HotReloadType.filesChanged;

  @override
  Map<String, dynamic> toJson() => _$HotReloadFilesChangedToJson(this);

  @override
  List<Object?> get props => [type, files];
}
