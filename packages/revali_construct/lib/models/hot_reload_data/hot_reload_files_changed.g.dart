// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hot_reload_files_changed.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HotReloadFilesChanged _$HotReloadFilesChangedFromJson(Map json) =>
    HotReloadFilesChanged(
      files: (json['files'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$HotReloadFilesChangedToJson(
        HotReloadFilesChanged instance) =>
    <String, dynamic>{
      'files': instance.files,
      'type': _$HotReloadTypeEnumMap[instance.type]!,
    };

const _$HotReloadTypeEnumMap = {
  HotReloadType.filesChanged: 'filesChanged',
  HotReloadType.revaliStarted: 'revaliStarted',
  HotReloadType.hotReloadEnabled: 'hotReloadEnabled',
};
