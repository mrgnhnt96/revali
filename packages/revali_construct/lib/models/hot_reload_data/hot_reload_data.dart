import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:revali_construct/models/hot_reload_data/hot_reload_files_changed.dart';

part 'hot_reload_data.g.dart';

@JsonSerializable()
class HotReloadData extends Equatable {
  const HotReloadData({required this.type});

  factory HotReloadData.fromJson(Map<dynamic, dynamic> json) {
    final base = _$HotReloadDataFromJson(json);

    switch (base.type) {
      case HotReloadType.filesChanged:
        return HotReloadFilesChanged.fromJson(json);
      case HotReloadType.revaliStarted:
      case HotReloadType.hotReloadEnabled:
        return base;
    }
  }

  final HotReloadType type;

  Map<String, dynamic> toJson() => _$HotReloadDataToJson(this);

  @override
  List<Object?> get props => [type];
}

enum HotReloadType {
  filesChanged,
  revaliStarted,
  hotReloadEnabled;

  bool get isHotReloadEnabled => this == hotReloadEnabled;
  bool get isRevaliStarted => this == revaliStarted;
  bool get isFilesChanged => this == filesChanged;
}
